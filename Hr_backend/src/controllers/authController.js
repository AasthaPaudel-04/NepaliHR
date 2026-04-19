const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const pool = require('../config/database');

// Register new employee
const register = async (req, res) => {
  try {
    const {
      company_id,
      employee_code,
      full_name,
      email,
      password,
      phone,
      position,
      department,
      join_date,
      role,
      basic_salary,
      date_of_birth
    } = req.body;

    // Validate required fields
    if (!employee_code || !full_name || !email || !password || !join_date) {
      return res.status(400).json({ 
        error: 'Employee code, name, email, password, and join date are required' 
      });
    }

    // Check if email already exists
    const emailCheck = await pool.query(
      'SELECT id FROM employees WHERE email = $1',
      [email]
    );

    if (emailCheck.rows.length > 0) {
      return res.status(400).json({ error: 'Email already registered' });
    }

    // Check if employee code already exists
    const codeCheck = await pool.query(
      'SELECT id FROM employees WHERE employee_code = $1',
      [employee_code]
    );

    if (codeCheck.rows.length > 0) {
      return res.status(400).json({ error: 'Employee code already exists' });
    }

    // Hash password
    const password_hash = await bcrypt.hash(password, 10);

    // Insert new employee
    const result = await pool.query(
      `INSERT INTO employees 
       (company_id, employee_code, full_name, email, password_hash, phone, position, department, date_of_birth, join_date, basic_salary, role, status)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
       RETURNING id, employee_code, full_name, email, phone, position, department, date_of_birth, join_date, basic_salary, role, status`,
      [company_id || 1, employee_code, full_name, email, password_hash, phone, position, department, date_of_birth, join_date, basic_salary, role || 'employee', 'active']
    );

    res.status(201).json({
      message: 'Employee registered successfully',
      employee: result.rows[0]
    });

  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({ error: 'Server error during registration' });
  }
};

// Login
const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Validate input
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    // Find employee by email
    const result = await pool.query(
      'SELECT * FROM employees WHERE email = $1',
      [email]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const employee = result.rows[0];

    // Check if account is active
    if (employee.status !== 'active') {
      return res.status(403).json({ error: 'Account is inactive' });
    }

    // Verify password
    const validPassword = await bcrypt.compare(password, employee.password_hash);
    
    if (!validPassword) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    // Generate JWT token
    const token = jwt.sign(
      { 
        id: employee.id, 
        email: employee.email, 
        role: employee.role 
      },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    // Return success response
    res.json({
      message: 'Login successful',
      token: token,
      employee: {
        id: employee.id,
        employee_code: employee.employee_code,
        full_name: employee.full_name,
        email: employee.email,
        phone: employee.phone,
        position: employee.position,
        department: employee.department,
        date_of_birth: employee.date_of_birth,
        join_date: employee.join_date,
        basic_salary: employee.basic_salary,
        role: employee.role,
        status: employee.status
      }
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Server error during login' });
  }
};

// Get current user info
const getCurrentUser = async (req, res) => {
  try {
    const userId = req.user.id; // From auth middleware

    const result = await pool.query(
      `SELECT id, employee_code, full_name, email, phone, position, 
              department, date_of_birth, join_date, basic_salary, role, status
       FROM employees WHERE id = $1`,
      [userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json(result.rows[0]);

  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Get all employees (Admin/Manager only)
const getAllEmployees = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT
         e.id, e.employee_code, e.full_name, e.email,
         e.position, e.department, e.role, e.status,
         e.job_role_id, e.department_id,
         jr.name  AS job_role_name,
         d.name   AS department_name
       FROM employees e
       LEFT JOIN job_roles jr  ON jr.id = e.job_role_id
       LEFT JOIN departments d ON d.id = e.department_id
       WHERE e.status = 'active'
       ORDER BY e.full_name ASC`
    );
    res.json({ data: result.rows });
  } catch (error) {
    console.error('getAllEmployees error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

module.exports = { register, login, getCurrentUser, getAllEmployees };