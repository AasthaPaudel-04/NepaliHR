// src/controllers/jobRoleController.js
const pool = require('../config/database');

// ── GET all job roles
const getJobRoles = async (req, res) => {
  try {
    const { department_id } = req.query;
    let query = `
      SELECT jr.*,
             d.name AS department_name,
             COUNT(DISTINCT e.id)::int   AS employee_count,
             COUNT(DISTINCT kra.kpi_id)::int AS kpi_count
      FROM job_roles jr
      JOIN departments d ON d.id = jr.department_id
      LEFT JOIN employees e   ON e.job_role_id = jr.id AND e.status = 'active'
      LEFT JOIN kpi_role_assignments kra ON kra.job_role_id = jr.id
      WHERE 1=1`;
    const params = [];
    if (department_id) {
      params.push(department_id);
      query += ` AND jr.department_id = $${params.length}`;
    }
    query += ' GROUP BY jr.id, d.name ORDER BY d.name, jr.name';
    const result = await pool.query(query, params);
    res.json({ data: result.rows });
  } catch (err) {
    console.error('getJobRoles error:', err);
    res.status(500).json({ error: 'Server error' });
  }
};

// ── CREATE job role
const createJobRole = async (req, res) => {
  try {
    const { name, description, department_id } = req.body;
    if (!name || !department_id) {
      return res.status(400).json({ error: 'name and department_id are required' });
    }
    const result = await pool.query(
      `INSERT INTO job_roles (department_id, name, description)
       VALUES ($1, $2, $3) RETURNING *`,
      [department_id, name.trim(), description || null]
    );
    res.status(201).json({ message: 'Job role created', data: result.rows[0] });
  } catch (err) {
    if (err.code === '23505') {
      return res.status(409).json({ error: 'Role name already exists in this department' });
    }
    console.error('createJobRole error:', err);
    res.status(500).json({ error: 'Server error' });
  }
};

// ── UPDATE job role
const updateJobRole = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, description, department_id, is_active } = req.body;
    const result = await pool.query(
      `UPDATE job_roles SET
         name          = COALESCE($1, name),
         description   = COALESCE($2, description),
         department_id = COALESCE($3, department_id),
         is_active     = COALESCE($4, is_active),
         updated_at    = CURRENT_TIMESTAMP
       WHERE id = $5
       RETURNING *`,
      [name ? name.trim() : null, description, department_id, is_active, id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Job role not found' });
    }
    res.json({ message: 'Job role updated', data: result.rows[0] });
  } catch (err) {
    if (err.code === '23505') {
      return res.status(409).json({ error: 'Role name already exists in this department' });
    }
    console.error('updateJobRole error:', err);
    res.status(500).json({ error: 'Server error' });
  }
};

// ── DELETE job role
const deleteJobRole = async (req, res) => {
  try {
    const { id } = req.params;
    const empCheck = await pool.query(
      'SELECT COUNT(*)::int AS cnt FROM employees WHERE job_role_id = $1', [id]
    );
    if (empCheck.rows[0].cnt > 0) {
      return res.status(400).json({
        error: `Cannot delete: ${empCheck.rows[0].cnt} employee(s) are assigned to this role`
      });
    }
    const result = await pool.query(
      'DELETE FROM job_roles WHERE id = $1 RETURNING id', [id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Job role not found' });
    }
    res.json({ message: 'Job role deleted' });
  } catch (err) {
    console.error('deleteJobRole error:', err);
    res.status(500).json({ error: 'Server error' });
  }
};

// ── Assign employee to a job role + department
const assignEmployeeRole = async (req, res) => {
  try {
    const { employee_id, job_role_id, department_id } = req.body;
    if (!employee_id || !job_role_id || !department_id) {
      return res.status(400).json({ error: 'employee_id, job_role_id, department_id are required' });
    }
    const result = await pool.query(
      `UPDATE employees
       SET job_role_id = $1, department_id = $2
       WHERE id = $3
       RETURNING id, full_name, job_role_id, department_id`,
      [job_role_id, department_id, employee_id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Employee not found' });
    }
    res.json({ message: 'Employee role assigned', data: result.rows[0] });
  } catch (err) {
    console.error('assignEmployeeRole error:', err);
    res.status(500).json({ error: 'Server error' });
  }
};

module.exports = { getJobRoles, createJobRole, updateJobRole, deleteJobRole, assignEmployeeRole };