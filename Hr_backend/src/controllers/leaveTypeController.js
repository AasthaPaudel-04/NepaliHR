const pool = require('../config/database');
 
const getLeaveTypes = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT * FROM leave_types WHERE is_active = true ORDER BY name`
    );
    res.json({ data: result.rows });
  } catch (err) {
    console.error('getLeaveTypes error:', err);
    res.status(500).json({ error: 'Server error' });
  }
};
 
const getAllLeaveTypes = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT * FROM leave_types ORDER BY name`
    );
    res.json({ data: result.rows });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
};
 
const createLeaveType = async (req, res) => {
  try {
    const { name, code, days_allowed = 12, icon = 'event' } = req.body;
    if (!name || !code) {
      return res.status(400).json({ error: 'name and code are required' });
    }
    const result = await pool.query(
      `INSERT INTO leave_types (name, code, icon, days_allowed)
       VALUES ($1, $2, $3, $4) RETURNING *`,
      [name.trim(), code.trim().toLowerCase().replace(/\s+/g, '_'), icon, days_allowed]
    );
    res.status(201).json({ message: 'Leave type created', data: result.rows[0] });
  } catch (err) {
    if (err.code === '23505') {
      return res.status(409).json({ error: 'Leave type code already exists' });
    }
    res.status(500).json({ error: 'Server error' });
  }
};
 
const updateLeaveType = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, days_allowed, icon, is_active } = req.body;
    const result = await pool.query(
      `UPDATE leave_types SET
         name         = COALESCE($1, name),
         days_allowed = COALESCE($2, days_allowed),
         icon         = COALESCE($3, icon),
         is_active    = COALESCE($4, is_active)
       WHERE id = $5 RETURNING *`,
      [name, days_allowed, icon, is_active, id]
    );
    if (!result.rows.length) return res.status(404).json({ error: 'Not found' });
    res.json({ message: 'Leave type updated', data: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
};
 
const deleteLeaveType = async (req, res) => {
  try {
    const { id } = req.params;
    // Check if any leave requests use this type
    const lt = await pool.query('SELECT code FROM leave_types WHERE id = $1', [id]);
    if (!lt.rows.length) return res.status(404).json({ error: 'Not found' });
    const used = await pool.query(
      'SELECT COUNT(*)::int AS cnt FROM leave_requests WHERE leave_type = $1',
      [lt.rows[0].code]
    );
    if (used.rows[0].cnt > 0) {
      return res.status(400).json({
        error: `Cannot delete: ${used.rows[0].cnt} leave request(s) use this type. Deactivate instead.`
      });
    }
    await pool.query('DELETE FROM leave_types WHERE id = $1', [id]);
    res.json({ message: 'Leave type deleted' });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
};
 
module.exports = { getLeaveTypes, getAllLeaveTypes, createLeaveType, updateLeaveType, deleteLeaveType };