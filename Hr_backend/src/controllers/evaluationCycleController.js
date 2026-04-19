// src/controllers/evaluationCycleController.js
const pool = require('../config/database');

// ── GET all cycles
const getCycles = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT ec.*,
              e.full_name AS created_by_name,
              COUNT(DISTINCT ev.employee_id)::int AS evaluated_employee_count
       FROM evaluation_cycles ec
       LEFT JOIN employees e  ON e.id = ec.created_by
       LEFT JOIN evaluations ev ON ev.cycle_id = ec.id
       GROUP BY ec.id, e.full_name
       ORDER BY ec.start_date DESC`
    );
    res.json({ data: result.rows });
  } catch (err) {
    console.error('getCycles error:', err);
    res.status(500).json({ error: 'Server error' });
  }
};

// ── GET single cycle by id
const getCycleById = async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM evaluation_cycles WHERE id = $1', [req.params.id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Cycle not found' });
    }
    res.json({ data: result.rows[0] });
  } catch (err) {
    console.error('getCycleById error:', err);
    res.status(500).json({ error: 'Server error' });
  }
};

// ── CREATE cycle
const createCycle = async (req, res) => {
  try {
    const {
      cycle_name, cycle_type, start_date, end_date,
      self_weight = 10, peer_weight = 20, manager_weight = 50, hr_weight = 20
    } = req.body;

    if (!cycle_name || !cycle_type || !start_date || !end_date) {
      return res.status(400).json({
        error: 'cycle_name, cycle_type, start_date, end_date are required'
      });
    }
    if (!['monthly', 'quarterly'].includes(cycle_type)) {
      return res.status(400).json({ error: 'cycle_type must be monthly or quarterly' });
    }
    const total = parseFloat(self_weight) + parseFloat(peer_weight) +
                  parseFloat(manager_weight) + parseFloat(hr_weight);
    if (Math.round(total) !== 100) {
      return res.status(400).json({
        error: `Evaluator weights must sum to 100. You entered: ${total}`
      });
    }
    if (new Date(start_date) >= new Date(end_date)) {
      return res.status(400).json({ error: 'start_date must be before end_date' });
    }

    const result = await pool.query(
      `INSERT INTO evaluation_cycles
         (cycle_name, cycle_type, start_date, end_date,
          self_weight, peer_weight, manager_weight, hr_weight, created_by)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
       RETURNING *`,
      [cycle_name, cycle_type, start_date, end_date,
       self_weight, peer_weight, manager_weight, hr_weight, req.user.id]
    );
    res.status(201).json({ message: 'Evaluation cycle created', data: result.rows[0] });
  } catch (err) {
    console.error('createCycle error:', err);
    res.status(500).json({ error: 'Server error' });
  }
};

// ── UPDATE cycle
const updateCycle = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      cycle_name, cycle_type, start_date, end_date,
      self_weight, peer_weight, manager_weight, hr_weight, status
    } = req.body;

    if (self_weight !== undefined) {
      const total = [self_weight, peer_weight, manager_weight, hr_weight]
        .reduce((s, v) => s + parseFloat(v || 0), 0);
      if (Math.round(total) !== 100) {
        return res.status(400).json({ error: `Weights must sum to 100. Got: ${total}` });
      }
    }
    const result = await pool.query(
      `UPDATE evaluation_cycles SET
         cycle_name     = COALESCE($1, cycle_name),
         cycle_type     = COALESCE($2, cycle_type),
         start_date     = COALESCE($3, start_date),
         end_date       = COALESCE($4, end_date),
         self_weight    = COALESCE($5, self_weight),
         peer_weight    = COALESCE($6, peer_weight),
         manager_weight = COALESCE($7, manager_weight),
         hr_weight      = COALESCE($8, hr_weight),
         status         = COALESCE($9, status),
         updated_at     = CURRENT_TIMESTAMP
       WHERE id = $10
       RETURNING *`,
      [cycle_name, cycle_type, start_date, end_date,
       self_weight, peer_weight, manager_weight, hr_weight, status, id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Cycle not found' });
    }
    res.json({ message: 'Cycle updated', data: result.rows[0] });
  } catch (err) {
    console.error('updateCycle error:', err);
    res.status(500).json({ error: 'Server error' });
  }
};

module.exports = { getCycles, getCycleById, createCycle, updateCycle };