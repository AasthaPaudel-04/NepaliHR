// src/controllers/departmentController.js
const pool = require('../config/database');

// ── GET all departments
const getDepartments = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT d.*,
              COUNT(jr.id)::int AS role_count
       FROM departments d
       LEFT JOIN job_roles jr ON jr.department_id = d.id AND jr.is_active = true
       GROUP BY d.id
       ORDER BY d.name ASC`
    );
    res.json({ data: result.rows });
  } catch (err) {
    console.error('getDepartments error:', err);
    res.status(500).json({ error: 'Server error' });
  }
};

// ── CREATE department
const createDepartment = async (req, res) => {
  try {
    const { name, description } = req.body;
    if (!name || name.trim() === '') {
      return res.status(400).json({ error: 'Department name is required' });
    }
    const result = await pool.query(
      `INSERT INTO departments (name, description)
       VALUES ($1, $2) RETURNING *`,
      [name.trim(), description || null]
    );
    res.status(201).json({ message: 'Department created', data: result.rows[0] });
  } catch (err) {
    if (err.code === '23505') {
      return res.status(409).json({ error: 'Department name already exists' });
    }
    console.error('createDepartment error:', err);
    res.status(500).json({ error: 'Server error' });
  }
};

// ── UPDATE department
const updateDepartment = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, description, is_active } = req.body;
    const result = await pool.query(
      `UPDATE departments SET
         name        = COALESCE($1, name),
         description = COALESCE($2, description),
         is_active   = COALESCE($3, is_active),
         updated_at  = CURRENT_TIMESTAMP
       WHERE id = $4
       RETURNING *`,
      [name ? name.trim() : null, description, is_active, id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Department not found' });
    }
    res.json({ message: 'Department updated', data: result.rows[0] });
  } catch (err) {
    if (err.code === '23505') {
      return res.status(409).json({ error: 'Department name already exists' });
    }
    console.error('updateDepartment error:', err);
    res.status(500).json({ error: 'Server error' });
  }
};

// ── DELETE department
const deleteDepartment = async (req, res) => {
  try {
    const { id } = req.params;
    const empCheck = await pool.query(
      'SELECT COUNT(*)::int AS cnt FROM employees WHERE department_id = $1', [id]
    );
    if (empCheck.rows[0].cnt > 0) {
      return res.status(400).json({
        error: `Cannot delete: ${empCheck.rows[0].cnt} employee(s) are assigned to this department`
      });
    }
    const result = await pool.query(
      'DELETE FROM departments WHERE id = $1 RETURNING id', [id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Department not found' });
    }
    res.json({ message: 'Department deleted' });
  } catch (err) {
    console.error('deleteDepartment error:', err);
    res.status(500).json({ error: 'Server error' });
  }
};

module.exports = { getDepartments, createDepartment, updateDepartment, deleteDepartment };