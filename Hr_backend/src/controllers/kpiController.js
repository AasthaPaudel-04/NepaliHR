const pool = require('../config/database');

// ── GET /kpis  (all KPIs, admin view)
const getKPIs = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT k.*,
              e.full_name AS created_by_name,
              COALESCE(
                json_agg(
                  json_build_object(
                    'job_role_id', kra.job_role_id,
                    'job_role_name', jr.name,
                    'evaluator_type', kra.evaluator_type,
                    'target_role', kra.target_role
                  )
                ) FILTER (WHERE kra.job_role_id IS NOT NULL),
                '[]'
              ) AS assigned_roles
       FROM kpis k
       LEFT JOIN employees e ON e.id = k.created_by
       LEFT JOIN kpi_role_assignments kra ON kra.kpi_id = k.id
       LEFT JOIN job_roles jr ON jr.id = kra.job_role_id
       WHERE k.company_id = $1
       GROUP BY k.id, e.full_name
       ORDER BY k.name`,
      [req.user.company_id || 1]
    );
    res.json({ data: result.rows });
  } catch (err) {
    console.error('Get KPIs error:', err);
    res.status(500).json({ error: 'Server error' });
  }
};

// ── GET /kpis/role/:roleId?evaluator_type=self&target_role=employee
// Used by evaluation form to fetch the right KPIs for a given context
const getKPIsForRole = async (req, res) => {
  try {
    const { roleId } = req.params;
    const { evaluator_type = 'all', target_role = 'all' } = req.query;

    // Fetch KPIs assigned to this role that match evaluator_type and target_role
    // Logic: include KPIs where assignment is 'all' OR matches the specific type
    const result = await pool.query(
      `SELECT DISTINCT k.*
       FROM kpis k
       JOIN kpi_role_assignments kra ON kra.kpi_id = k.id
       WHERE kra.job_role_id = $1
         AND k.is_active = TRUE
         AND (
           kra.evaluator_type = 'all'
           OR kra.evaluator_type = $2
         )
         AND (
           kra.target_role = 'all'
           OR kra.target_role = $3
         )
       ORDER BY k.weightage DESC`,
      [roleId, evaluator_type, target_role]
    );
    res.json({ data: result.rows });
  } catch (err) {
    console.error('Get KPIs for role error:', err);
    res.status(500).json({ error: 'Server error' });
  }
};

// ── POST /kpis
const createKPI = async (req, res) => {
  try {
    const {
      name, description, kpi_type, target_value,
      weightage, evaluator_type = 'all', target_role = 'all',
    } = req.body;
    if (!name || !kpi_type || weightage === undefined) {
      return res.status(400).json({ error: 'name, kpi_type and weightage are required' });
    }
    const validEvalTypes = ['all', 'self', 'peer', 'manager', 'hr'];
    const validTargetRoles = ['all', 'employee', 'manager'];
    if (!validEvalTypes.includes(evaluator_type))
      return res.status(400).json({ error: 'Invalid evaluator_type' });
    if (!validTargetRoles.includes(target_role))
      return res.status(400).json({ error: 'Invalid target_role' });

    const result = await pool.query(
      `INSERT INTO kpis
         (company_id, name, description, kpi_type, target_value, weightage, evaluator_type, target_role, created_by)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
       RETURNING *`,
      [req.user.company_id || 1, name, description, kpi_type, target_value, weightage,
       evaluator_type, target_role, req.user.id]
    );
    res.status(201).json({ message: 'KPI created', data: result.rows[0] });
  } catch (err) {
    console.error('Create KPI error:', err);
    res.status(500).json({ error: 'Server error' });
  }
};

// ── PUT /kpis/:id
const updateKPI = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, description, kpi_type, target_value, weightage, is_active, evaluator_type, target_role } = req.body;
    const result = await pool.query(
      `UPDATE kpis SET
         name = COALESCE($1, name),
         description = COALESCE($2, description),
         kpi_type = COALESCE($3, kpi_type),
         target_value = COALESCE($4, target_value),
         weightage = COALESCE($5, weightage),
         is_active = COALESCE($6, is_active),
         evaluator_type = COALESCE($7, evaluator_type),
         target_role = COALESCE($8, target_role)
       WHERE id = $9 AND company_id = $10
       RETURNING *`,
      [name, description, kpi_type, target_value, weightage, is_active,
       evaluator_type, target_role, id, req.user.company_id || 1]
    );
    if (!result.rows.length) return res.status(404).json({ error: 'KPI not found' });
    res.json({ message: 'KPI updated', data: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
};

// ── DELETE /kpis/:id
const deleteKPI = async (req, res) => {
  try {
    const result = await pool.query(
      `DELETE FROM kpis WHERE id=$1 AND company_id=$2 RETURNING id`,
      [req.params.id, req.user.company_id || 1]
    );
    if (!result.rows.length) return res.status(404).json({ error: 'KPI not found' });
    res.json({ message: 'KPI deleted' });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
};

// ── POST /kpis/assign-roles  (rich assignment with evaluator_type + target_role)
const assignKPIToRoles = async (req, res) => {
  try {
    const { kpi_id, assignments } = req.body;
    // assignments: [{ job_role_id, evaluator_type, target_role }]
    if (!kpi_id || !Array.isArray(assignments)) {
      return res.status(400).json({ error: 'kpi_id and assignments[] required' });
    }

    // Delete existing assignments for this KPI
    await pool.query(`DELETE FROM kpi_role_assignments WHERE kpi_id=$1`, [kpi_id]);

    // Insert new assignments
    for (const a of assignments) {
      const et = a.evaluator_type || 'all';
      const tr = a.target_role || 'all';
      await pool.query(
        `INSERT INTO kpi_role_assignments (kpi_id, job_role_id, evaluator_type, target_role)
         VALUES ($1,$2,$3,$4) ON CONFLICT DO NOTHING`,
        [kpi_id, a.job_role_id, et, tr]
      );
    }

    res.json({ message: `KPI assigned to ${assignments.length} role(s)` });
  } catch (err) {
    console.error('Assign KPI roles error:', err);
    res.status(500).json({ error: 'Server error' });
  }
};

module.exports = { getKPIs, getKPIsForRole, createKPI, updateKPI, deleteKPI, assignKPIToRoles };
