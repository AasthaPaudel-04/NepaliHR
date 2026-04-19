const pool = require('../config/database');

// ─── Get all shifts (Admin/Manager) ──────────────────────────────────────────
const getAllShifts = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT s.*, 
              COUNT(es.id) FILTER (WHERE es.is_active = true) AS assigned_count
       FROM shifts s
       LEFT JOIN employee_shifts es ON es.shift_id = s.id
       WHERE s.company_id = $1
       GROUP BY s.id
       ORDER BY s.created_at DESC`,
      [req.user.company_id || 1]
    );
    res.json({ data: result.rows });
  } catch (error) {
    console.error('Get shifts error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// ─── Create shift ─────────────────────────────────────────────────────────────
const createShift = async (req, res) => {
  try {
    const { shift_name, start_time, end_time, grace_period_minutes = 15 } = req.body;

    if (!shift_name || !start_time || !end_time) {
      return res.status(400).json({ error: 'shift_name, start_time, end_time are required' });
    }

    const result = await pool.query(
      `INSERT INTO shifts (company_id, shift_name, start_time, end_time, grace_period_minutes, is_active)
       VALUES ($1, $2, $3, $4, $5, true)
       RETURNING *`,
      [req.user.company_id || 1, shift_name, start_time, end_time, grace_period_minutes]
    );

    res.status(201).json({ message: 'Shift created', data: result.rows[0] });
  } catch (error) {
    console.error('Create shift error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// ─── Update shift ─────────────────────────────────────────────────────────────
const updateShift = async (req, res) => {
  try {
    const { id } = req.params;
    const { shift_name, start_time, end_time, grace_period_minutes, is_active } = req.body;

    const result = await pool.query(
      `UPDATE shifts SET
         shift_name = COALESCE($1, shift_name),
         start_time = COALESCE($2, start_time),
         end_time = COALESCE($3, end_time),
         grace_period_minutes = COALESCE($4, grace_period_minutes),
         is_active = COALESCE($5, is_active)
       WHERE id = $6 AND company_id = $7
       RETURNING *`,
      [shift_name, start_time, end_time, grace_period_minutes, is_active, id, req.user.company_id || 1]
    );

    if (result.rows.length === 0) return res.status(404).json({ error: 'Shift not found' });
    res.json({ message: 'Shift updated', data: result.rows[0] });
  } catch (error) {
    console.error('Update shift error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// ─── Delete shift ─────────────────────────────────────────────────────────────
const deleteShift = async (req, res) => {
  try {
    const { id } = req.params;

    // Check if any employee is using this shift
    const assigned = await pool.query(
      'SELECT COUNT(*) FROM employee_shifts WHERE shift_id = $1 AND is_active = true',
      [id]
    );
    if (parseInt(assigned.rows[0].count) > 0) {
      return res.status(400).json({ error: 'Cannot delete shift with active employees assigned' });
    }

    await pool.query('DELETE FROM shifts WHERE id = $1', [id]);
    res.json({ message: 'Shift deleted' });
  } catch (error) {
    console.error('Delete shift error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// ─── Assign shift to employee ─────────────────────────────────────────────────
const assignShift = async (req, res) => {
  try {
    const { employee_id, shift_id, effective_from, effective_to } = req.body;

    if (!employee_id || !shift_id || !effective_from) {
      return res.status(400).json({ error: 'employee_id, shift_id, effective_from required' });
    }

    // Deactivate current shift assignment
    await pool.query(
      'UPDATE employee_shifts SET is_active = false WHERE employee_id = $1 AND is_active = true',
      [employee_id]
    );

    const result = await pool.query(
      `INSERT INTO employee_shifts (employee_id, shift_id, effective_from, effective_to, is_active)
       VALUES ($1, $2, $3, $4, true)
       RETURNING *`,
      [employee_id, shift_id, effective_from, effective_to || null]
    );

    res.status(201).json({ message: 'Shift assigned successfully', data: result.rows[0] });
  } catch (error) {
    console.error('Assign shift error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// ─── Get employees with their current shifts ──────────────────────────────────
const getEmployeeShifts = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT e.id AS employee_id, e.full_name, e.employee_code, e.department, e.position,
              s.id AS shift_id, s.shift_name, s.start_time, s.end_time, s.grace_period_minutes,
              es.effective_from, es.effective_to, es.is_active AS shift_active
       FROM employees e
       LEFT JOIN employee_shifts es ON es.employee_id = e.id AND es.is_active = true
       LEFT JOIN shifts s ON s.id = es.shift_id
       WHERE e.status = 'active'
       ORDER BY e.full_name ASC`
    );
    res.json({ data: result.rows });
  } catch (error) {
    console.error('Get employee shifts error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// ─── Get my shift (employee) ──────────────────────────────────────────────────
const getMyShift = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT s.*, es.effective_from, es.effective_to
       FROM employee_shifts es
       JOIN shifts s ON s.id = es.shift_id
       WHERE es.employee_id = $1 AND es.is_active = true
       LIMIT 1`,
      [req.user.id]
    );

    if (result.rows.length === 0) {
      return res.json({ data: null, message: 'No shift assigned' });
    }
    res.json({ data: result.rows[0] });
  } catch (error) {
    console.error('Get my shift error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

module.exports = {
  getAllShifts,
  createShift,
  updateShift,
  deleteShift,
  assignShift,
  getEmployeeShifts,
  getMyShift,
};