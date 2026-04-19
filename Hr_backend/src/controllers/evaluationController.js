// controllers/evaluationController.js
const pool = require('../config/database');
const { createNotification, notifyAdmins } = require('./notificationController');

// Helper: compute cycle display status from DB fields
function computeCycleStatus(cycle) {
  const today = new Date();
  const end   = new Date(cycle.end_date);
  const start = new Date(cycle.start_date);
  if (!cycle.is_initiated) return 'draft';
  if (today < start)       return 'pending';
  if (today > end)         return 'closed';
  return 'active';
}

// ── GET /evaluations/my-evaluations
const getMyPendingEvaluations = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT ev.*,
              ec.cycle_name, ec.start_date, ec.end_date,
              e.full_name AS employee_name, e.employee_code,
              e.role AS employee_role,
              evaluator.full_name AS evaluator_name,
              jr.name AS job_role_name,
              d.name AS department_name
       FROM evaluations ev
       JOIN evaluation_cycles ec ON ec.id = ev.cycle_id
       JOIN employees e ON e.id = ev.employee_id
       LEFT JOIN employees evaluator ON evaluator.id = ev.evaluator_id
       LEFT JOIN employee_job_roles ejr ON ejr.employee_id = ev.employee_id
       LEFT JOIN job_roles jr ON jr.id = ejr.job_role_id
       LEFT JOIN departments d ON d.id = jr.department_id
       WHERE ev.evaluator_id = $1
         AND ev.status = 'pending'
         AND ec.is_initiated = TRUE
         AND CURRENT_DATE <= ec.end_date
       ORDER BY ec.end_date ASC`,
      [req.user.id]
    );
    res.json({ data: result.rows });
  } catch (err) {
    console.error('Get my evaluations error:', err);
    res.status(500).json({ error: 'Server error' });
  }
};

// ── GET /evaluations/form/:evaluation_id
const getEvaluationForm = async (req, res) => {
  try {
    const { evaluation_id } = req.params;

    const evResult = await pool.query(
      `SELECT ev.*, ec.cycle_name,
              e.full_name AS employee_name, e.role AS employee_role
       FROM evaluations ev
       JOIN evaluation_cycles ec ON ec.id = ev.cycle_id
       JOIN employees e ON e.id = ev.employee_id
       WHERE ev.id = $1 AND ev.evaluator_id = $2`,
      [evaluation_id, req.user.id]
    );
    if (!evResult.rows.length) {
      return res.status(404).json({ error: 'Evaluation not found or not assigned to you' });
    }
    const ev = evResult.rows[0];

    // Get employee's job role
    const roleResult = await pool.query(
      `SELECT job_role_id FROM employee_job_roles
       WHERE employee_id = $1 ORDER BY assigned_at DESC LIMIT 1`,
      [ev.employee_id]
    );
    const jobRoleId = roleResult.rows[0]?.job_role_id;

    // Determine target_role from employee's system role
    const targetRole = ev.employee_role === 'manager' ? 'manager' : 'employee';

    // Fetch KPIs scoped to evaluator_type + target_role
    let kpis = [];
    if (jobRoleId) {
      const kpiResult = await pool.query(
        `SELECT DISTINCT k.*
         FROM kpis k
         JOIN kpi_role_assignments kra ON kra.kpi_id = k.id
         WHERE kra.job_role_id = $1
           AND k.is_active = TRUE
           AND (kra.evaluator_type = 'all' OR kra.evaluator_type = $2)
           AND (kra.target_role = 'all' OR kra.target_role = $3)
         ORDER BY k.weightage DESC`,
        [jobRoleId, ev.evaluator_type, targetRole]
      );
      kpis = kpiResult.rows;
    }

    // Existing scores (for resuming a partial submission)
    const scoresResult = await pool.query(
      `SELECT * FROM kpi_scores WHERE evaluation_id = $1`,
      [evaluation_id]
    );
    const existingScores = {};
    for (const s of scoresResult.rows) {
      existingScores[s.kpi_id] = s;
    }

    res.json({ data: { evaluation: ev, kpis, existing_scores: existingScores } });
  } catch (err) {
    console.error('Get evaluation form error:', err);
    res.status(500).json({ error: 'Server error' });
  }
};

// ── POST /evaluations/submit/:evaluation_id
const submitEvaluation = async (req, res) => {
  try {
    const { evaluation_id } = req.params;
    const { scores } = req.body; // [{ kpi_id, achieved_value, rating, notes }]

    const evResult = await pool.query(
      `SELECT ev.*, e.full_name AS employee_name
       FROM evaluations ev
       JOIN employees e ON e.id = ev.employee_id
       WHERE ev.id = $1 AND ev.evaluator_id = $2`,
      [evaluation_id, req.user.id]
    );
    if (!evResult.rows.length) {
      return res.status(404).json({ error: 'Evaluation not found' });
    }
    const ev = evResult.rows[0];
    if (ev.status === 'submitted') {
      return res.status(400).json({ error: 'Already submitted' });
    }

    // Upsert scores into kpi_scores table
    for (const s of scores) {
      await pool.query(
        `INSERT INTO kpi_scores (evaluation_id, kpi_id, achieved_value, rating, notes)
         VALUES ($1, $2, $3, $4, $5)
         ON CONFLICT (evaluation_id, kpi_id)
         DO UPDATE SET achieved_value = $3, rating = $4, notes = $5`,
        [evaluation_id, s.kpi_id, s.achieved_value, s.rating, s.notes]
      );
    }

    // Mark submitted
    await pool.query(
      `UPDATE evaluations SET status = 'submitted', submitted_at = NOW() WHERE id = $1`,
      [evaluation_id]
    );

    // Notify employee (non-fatal)
    try {
      await createNotification({
        companyId: req.user.company_id || 1,
        recipientId: ev.employee_id,
        senderId: req.user.id,
        type: 'evaluation_submitted',
        title: 'Evaluation submitted',
        body: `${ev.evaluator_type.charAt(0).toUpperCase() + ev.evaluator_type.slice(1)} evaluation has been submitted for you.`,
        referenceId: ev.cycle_id,
        referenceType: 'evaluation',
      });
    } catch (notifErr) {
      console.error('Notification error (non-fatal):', notifErr);
    }

    res.json({ message: 'Evaluation submitted successfully' });
  } catch (err) {
    console.error('Submit evaluation error:', err);
    res.status(500).json({ error: 'Server error' });
  }
};

// ── POST /evaluations/cycle/:cycle_id/initiate
// Named initiateCycleEvaluations to match evaluationRoutes.js import
const initiateCycleEvaluations = async (req, res) => {
  try {
    const { cycle_id } = req.params;

    const cycleResult = await pool.query(
      `SELECT * FROM evaluation_cycles WHERE id = $1 AND company_id = $2`,
      [cycle_id, req.user.company_id || 1]
    );
    if (!cycleResult.rows.length) {
      return res.status(404).json({ error: 'Cycle not found' });
    }
    const cycle = cycleResult.rows[0];
    if (cycle.is_initiated) {
      return res.status(400).json({ error: 'Cycle already initiated' });
    }

    const employees = await pool.query(
      `SELECT e.id, e.role, ejr.job_role_id
       FROM employees e
       LEFT JOIN employee_job_roles ejr ON ejr.employee_id = e.id
       WHERE e.status = 'active' AND e.company_id = $1`,
      [req.user.company_id || 1]
    );

    let created = 0, skipped = 0;
    const evalTypes = ['self', 'peer', 'manager', 'hr'];

    for (const emp of employees.rows) {
      for (const evalType of evalTypes) {
        let evaluatorId = null;

        if (evalType === 'self') {
          evaluatorId = emp.id;
        } else if (evalType === 'peer') {
          evaluatorId = null; // assigned later via assign-peer
        } else if (evalType === 'manager') {
          if (emp.role === 'manager') {
            // skip - managers don't get a manager evaluation
            skipped++;
            continue;
          }
          const mgr = await pool.query(
            `SELECT e2.id FROM employees e2
             JOIN employee_job_roles ejr2 ON ejr2.employee_id = e2.id
             JOIN job_roles jr ON jr.id = ejr2.job_role_id
             WHERE jr.department_id = (
               SELECT jr2.department_id FROM job_roles jr2
               WHERE jr2.id = $1 LIMIT 1
             ) AND e2.role = 'manager' AND e2.status = 'active'
             LIMIT 1`,
            [emp.job_role_id || 0]
          );
          evaluatorId = mgr.rows[0]?.id || null;
        } else if (evalType === 'hr') {
          const admin = await pool.query(
            `SELECT id FROM employees
             WHERE role = 'admin' AND status = 'active' AND company_id = $1 LIMIT 1`,
            [req.user.company_id || 1]
          );
          evaluatorId = admin.rows[0]?.id || null;
        }

        // Skip if already exists
        const existing = await pool.query(
          `SELECT id FROM evaluations
           WHERE cycle_id = $1 AND employee_id = $2 AND evaluator_type = $3`,
          [cycle_id, emp.id, evalType]
        );
        if (existing.rows.length) { skipped++; continue; }

        await pool.query(
          `INSERT INTO evaluations (cycle_id, employee_id, evaluator_id, evaluator_type, status)
           VALUES ($1, $2, $3, $4, 'pending')`,
          [cycle_id, emp.id, evaluatorId, evalType]
        );
        created++;

        // Notify assigned evaluator
        if (evaluatorId) {
          try {
            await createNotification({
              companyId: req.user.company_id || 1,
              recipientId: evaluatorId,
              senderId: req.user.id,
              type: 'evaluation_assigned',
              title: 'Evaluation assigned',
              body: `You have a ${evalType} evaluation to complete for the "${cycle.cycle_name}" cycle.`,
              referenceId: parseInt(cycle_id),
              referenceType: 'evaluation',
            });
          } catch (notifErr) {
            console.error('Notification error (non-fatal):', notifErr);
          }
        }
      }
    }

    // Mark cycle as initiated
    await pool.query(
      `UPDATE evaluation_cycles SET is_initiated = TRUE WHERE id = $1`,
      [cycle_id]
    );

    res.json({ message: 'Cycle initiated successfully', created, skipped });
  } catch (err) {
    console.error('Initiate cycle error:', err);
    res.status(500).json({ error: 'Server error' });
  }
};

// ── POST /evaluations/assign-peer
const assignPeerEvaluator = async (req, res) => {
  try {
    const { cycle_id, employee_id, peer_id } = req.body;

    const result = await pool.query(
      `UPDATE evaluations SET evaluator_id = $1
       WHERE cycle_id = $2 AND employee_id = $3 AND evaluator_type = 'peer'
       RETURNING *`,
      [peer_id, cycle_id, employee_id]
    );
    if (!result.rows.length) {
      return res.status(404).json({
        error: 'Peer evaluation record not found. Initiate the cycle first.',
      });
    }

    // Notify the peer (non-fatal)
    try {
      const empRow  = await pool.query(`SELECT full_name FROM employees WHERE id = $1`, [employee_id]);
      const cycleRow = await pool.query(`SELECT cycle_name FROM evaluation_cycles WHERE id = $1`, [cycle_id]);
      await createNotification({
        companyId: req.user.company_id || 1,
        recipientId: peer_id,
        senderId: req.user.id,
        type: 'evaluation_assigned',
        title: 'Peer evaluation assigned',
        body: `You have been assigned to evaluate ${empRow.rows[0]?.full_name} in "${cycleRow.rows[0]?.cycle_name}".`,
        referenceId: parseInt(cycle_id),
        referenceType: 'evaluation',
      });
    } catch (notifErr) {
      console.error('Notification error (non-fatal):', notifErr);
    }

    res.json({ message: 'Peer evaluator assigned', data: result.rows[0] });
  } catch (err) {
    console.error('Assign peer error:', err);
    res.status(500).json({ error: 'Server error' });
  }
};

// ── GET /evaluations/cycle-status/:cycle_id
const getCycleEvaluationStatus = async (req, res) => {
  try {
    const { cycle_id } = req.params;

    const cycleResult = await pool.query(
      `SELECT * FROM evaluation_cycles WHERE id = $1 AND company_id = $2`,
      [cycle_id, req.user.company_id || 1]
    );
    if (!cycleResult.rows.length) {
      return res.status(404).json({ error: 'Cycle not found' });
    }
    const cycle = cycleResult.rows[0];
    const computedStatus = computeCycleStatus(cycle);

    const result = await pool.query(
      `SELECT ev.id, ev.evaluator_type, ev.status, ev.submitted_at,
              e.full_name AS employee_name, e.employee_code,
              evaluator.full_name AS evaluator_name,
              jr.name AS job_role_name
       FROM evaluations ev
       JOIN employees e ON e.id = ev.employee_id
       LEFT JOIN employees evaluator ON evaluator.id = ev.evaluator_id
       LEFT JOIN employee_job_roles ejr ON ejr.employee_id = ev.employee_id
       LEFT JOIN job_roles jr ON jr.id = ejr.job_role_id
       WHERE ev.cycle_id = $1
       ORDER BY e.full_name, ev.evaluator_type`,
      [cycle_id]
    );

    // Group by employee
    const grouped = {};
    for (const row of result.rows) {
      const key = row.employee_code || row.employee_name;
      if (!grouped[key]) {
        grouped[key] = {
          employee_name: row.employee_name,
          employee_code: row.employee_code,
          job_role_name: row.job_role_name,
          evaluations: [],
        };
      }
      grouped[key].evaluations.push({
        id: row.id,
        evaluator_type: row.evaluator_type,
        status: row.status,
        evaluator_name: row.evaluator_name,
        submitted_at: row.submitted_at,
      });
    }

    res.json({
      cycle: { ...cycle, computed_status: computedStatus },
      data: Object.values(grouped),
    });
  } catch (err) {
    console.error('Cycle evaluation status error:', err);
    res.status(500).json({ error: 'Server error' });
  }
};

// ── GET /evaluations/results/:cycle_id
const getPerformanceResults = async (req, res) => {
  try {
    const { cycle_id } = req.params;
    const result = await pool.query(
      `SELECT pr.*,
              e.full_name, e.employee_code,
              jr.name AS job_role_name,
              d.name AS department_name,
              ec.cycle_name
       FROM performance_results pr
       JOIN employees e ON e.id = pr.employee_id
       LEFT JOIN employee_job_roles ejr ON ejr.employee_id = pr.employee_id
       LEFT JOIN job_roles jr ON jr.id = ejr.job_role_id
       LEFT JOIN departments d ON d.id = jr.department_id
       JOIN evaluation_cycles ec ON ec.id = pr.cycle_id
       WHERE pr.cycle_id = $1
       ORDER BY pr.final_score DESC`,
      [cycle_id]
    );
    res.json({ data: result.rows });
  } catch (err) {
    console.error('Get results error:', err);
    res.status(500).json({ error: 'Server error' });
  }
};

// ── GET /evaluations/my-result/:cycle_id
const getMyPerformanceResult = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT pr.*, ec.cycle_name, ec.self_weight, ec.peer_weight,
              ec.manager_weight, ec.hr_weight
       FROM performance_results pr
       JOIN evaluation_cycles ec ON ec.id = pr.cycle_id
       WHERE pr.cycle_id = $1 AND pr.employee_id = $2`,
      [req.params.cycle_id, req.user.id]
    );
    if (!result.rows.length) {
      return res.status(404).json({ error: 'Result not available yet' });
    }
    res.json({ data: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
};

// ── POST /evaluations/feedback/:evaluation_id
// Named saveFeedback to match evaluationRoutes.js import
const saveFeedback = async (req, res) => {
  try {
    const { evaluation_id } = req.params;
    const { feedback_text } = req.body;

    // Check if evaluation_feedback table exists and upsert
    const result = await pool.query(
      `INSERT INTO evaluation_feedback (evaluation_id, feedback_text, created_by)
       VALUES ($1, $2, $3)
       ON CONFLICT (evaluation_id)
       DO UPDATE SET feedback_text = $2, updated_at = NOW()
       RETURNING *`,
      [evaluation_id, feedback_text, req.user.id]
    );
    res.json({ message: 'Feedback saved', data: result.rows[0] });
  } catch (err) {
    console.error('Save feedback error:', err);
    res.status(500).json({ error: 'Server error' });
  }
};

// ── PUT /evaluations/development/:cycle_id/:employee_id
const setDevelopmentPlan = async (req, res) => {
  try {
    const { cycle_id, employee_id } = req.params;
    const { development_action, dev_notes } = req.body;

    const result = await pool.query(
      `UPDATE performance_results
       SET development_action = $1, dev_notes = $2
       WHERE cycle_id = $3 AND employee_id = $4
       RETURNING *`,
      [development_action, dev_notes, cycle_id, employee_id]
    );
    if (!result.rows.length) {
      return res.status(404).json({ error: 'Performance result not found' });
    }

    // Notify employee (non-fatal)
    try {
      await createNotification({
        companyId: req.user.company_id || 1,
        recipientId: parseInt(employee_id),
        senderId: req.user.id,
        type: 'development_plan',
        title: 'Development plan updated',
        body: 'Your manager has added a development plan for you.',
        referenceId: parseInt(cycle_id),
        referenceType: 'evaluation',
      });
    } catch (notifErr) {
      console.error('Notification error (non-fatal):', notifErr);
    }

    res.json({ message: 'Development plan set', data: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
};

module.exports = {
  getMyPendingEvaluations,
  getEvaluationForm,
  submitEvaluation,
  initiateCycleEvaluations, 
  assignPeerEvaluator,
  getCycleEvaluationStatus,
  getPerformanceResults,
  getMyPerformanceResult,
  saveFeedback,               
  setDevelopmentPlan,
};