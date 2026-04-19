const pool = require('../config/database');
const { createNotification, notifyAdmins } = require('./notificationController');

// ── Apply for leave (Employee / Manager) ──────────────────────────────────
const applyLeave = async (req, res) => {
  try {
    const employeeId = req.user.id;
    const { leave_type, start_date, end_date, reason } = req.body;

    if (!leave_type || !start_date || !end_date) {
      return res.status(400).json({
        error: 'Leave type, start date, and end date are required',
      });
    }

    const startDate = new Date(start_date);
    const endDate   = new Date(end_date);
    const today     = new Date();
    today.setHours(0, 0, 0, 0);

    if (startDate < today) {
      return res.status(400).json({ error: 'Start date cannot be in the past' });
    }
    if (endDate < startDate) {
      return res.status(400).json({ error: 'End date cannot be before start date' });
    }

    const totalDays =
      Math.ceil((endDate.getTime() - startDate.getTime()) / (1000 * 3600 * 24)) + 1;

    // Validate leave type against DB (not hardcoded)
    const typeCheck = await pool.query(
      'SELECT * FROM leave_types WHERE code = $1',
      [leave_type],
    );
    if (typeCheck.rows.length === 0) {
      return res.status(400).json({ error: `Invalid leave type: ${leave_type}` });
    }

    const currentYear = new Date().getFullYear();

    // Get or create leave balance
    let balResult = await pool.query(
      'SELECT * FROM leave_balances WHERE employee_id = $1 AND year = $2',
      [employeeId, currentYear],
    );
    if (balResult.rows.length === 0) {
      const created = await pool.query(
        'INSERT INTO leave_balances (employee_id, year) VALUES ($1, $2) RETURNING *',
        [employeeId, currentYear],
      );
      balResult = { rows: [created.rows[0]] };
    }
    const balance = balResult.rows[0];

    // Check balance for standard types
    const balMap = {
      casual: 'casual_leave_balance',
      sick:   'sick_leave_balance',
      annual: 'annual_leave_balance',
    };
    const balField = balMap[leave_type];
    if (balField && balance[balField] !== undefined && balance[balField] < totalDays) {
      return res.status(400).json({
        error: `Insufficient ${leave_type} leave balance. Available: ${balance[balField]} days, Requested: ${totalDays} days`,
      });
    }

    // Check for overlapping requests
    const overlap = await pool.query(
      `SELECT id FROM leave_requests
       WHERE employee_id = $1
         AND status IN ('pending', 'approved')
         AND (
           (start_date <= $2 AND end_date >= $2) OR
           (start_date <= $3 AND end_date >= $3) OR
           (start_date >= $2 AND end_date <= $3)
         )`,
      [employeeId, start_date, end_date],
    );
    if (overlap.rows.length > 0) {
      return res.status(400).json({
        error: 'You already have a leave request for overlapping dates',
      });
    }

    // FIX 2: INSERT first so we have the ID for the notification
    const result = await pool.query(
      `INSERT INTO leave_requests
         (employee_id, leave_type, start_date, end_date, total_days, reason, status)
       VALUES ($1, $2, $3, $4, $5, $6, 'pending')
       RETURNING *`,
      [employeeId, leave_type, start_date, end_date, totalDays, reason],
    );
    const newLeave = result.rows[0];

    // FIX 5: Notify admins AFTER insert, in try/catch
    try {
      const empRow = await pool.query(
        'SELECT full_name FROM employees WHERE id = $1',
        [employeeId],
      );
      const empName = empRow.rows[0]?.full_name || 'An employee';
      await notifyAdmins({
        companyId:     req.user.company_id || 1,
        senderId:      req.user.id,
        type:          'leave_request',
        title:         'New leave request',
        body:          `${empName} applied for ${leave_type} leave from ${start_date} to ${end_date}.`,
        referenceId:   newLeave.id,
        referenceType: 'leave',
      });
    } catch (notifErr) {
      console.error('Notification error (non-fatal):', notifErr);
    }

    res.status(201).json({
      message: 'Leave request submitted successfully',
      leave_request: newLeave,
    });
  } catch (error) {
    console.error('Apply leave error:', error);
    res.status(500).json({ error: 'Server error while applying for leave' });
  }
};

// ── Get my leave requests (Employee / Manager) ────────────────────────────
const getMyLeaveRequests = async (req, res) => {
  try {
    const { status } = req.query;
    let query = `
      SELECT lr.*, e.full_name AS approved_by_name
      FROM leave_requests lr
      LEFT JOIN employees e ON lr.approved_by = e.id
      WHERE lr.employee_id = $1
    `;
    const params = [req.user.id];
    if (status) { query += ' AND lr.status = $2'; params.push(status); }
    query += ' ORDER BY lr.created_at DESC';
    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (error) {
    console.error('Get my leave requests error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// ── Get my leave balance (Employee / Manager) ─────────────────────────────
const getMyLeaveBalance = async (req, res) => {
  try {
    const currentYear = new Date().getFullYear();
    let result = await pool.query(
      'SELECT * FROM leave_balances WHERE employee_id = $1 AND year = $2',
      [req.user.id, currentYear],
    );
    if (result.rows.length === 0) {
      const created = await pool.query(
        'INSERT INTO leave_balances (employee_id, year) VALUES ($1, $2) RETURNING *',
        [req.user.id, currentYear],
      );
      return res.json(created.rows[0]);
    }
    res.json(result.rows[0]);
  } catch (error) {
    console.error('Get leave balance error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// ── Get pending leave requests (Manager / Admin) ──────────────────────────
const getPendingLeaveRequests = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT lr.*, e.full_name, e.employee_code, e.position, e.department
       FROM leave_requests lr
       JOIN employees e ON lr.employee_id = e.id
       WHERE lr.status = 'pending'
       ORDER BY lr.created_at DESC`,
    );
    res.json(result.rows);
  } catch (error) {
    console.error('Get pending requests error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// ── Get all leave requests (Manager / Admin) ──────────────────────────────
const getAllLeaveRequests = async (req, res) => {
  try {
    const { status, employee_id } = req.query;
    let query = `
      SELECT lr.*, e.full_name, e.employee_code, e.position, e.department,
             approver.full_name AS approved_by_name
      FROM leave_requests lr
      JOIN employees e ON lr.employee_id = e.id
      LEFT JOIN employees approver ON lr.approved_by = approver.id
      WHERE 1=1
    `;
    const params = [];
    let pc = 1;
    if (status)      { query += ` AND lr.status = $${pc++}`;      params.push(status); }
    if (employee_id) { query += ` AND lr.employee_id = $${pc++}`; params.push(employee_id); }
    query += ' ORDER BY lr.created_at DESC';
    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (error) {
    console.error('Get all leave requests error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// ── Approve leave (Manager / Admin) ──────────────────────────────────────
const approveLeave = async (req, res) => {
  try {
    const { id }     = req.params;
    const approverId = req.user.id;

    const leaveCheck = await pool.query(
      'SELECT * FROM leave_requests WHERE id = $1',
      [id],
    );
    if (leaveCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Leave request not found' });
    }
    // FIX 3: use leaveRequest (not leaveRecord)
    const leaveRequest = leaveCheck.rows[0];
    if (leaveRequest.status !== 'pending') {
      return res.status(400).json({
        error: `Leave request is already ${leaveRequest.status}`,
      });
    }

    await pool.query('BEGIN');
    try {
      // Update status
      await pool.query(
        `UPDATE leave_requests
         SET status = 'approved', approved_by = $1, approved_at = NOW()
         WHERE id = $2`,
        [approverId, id],
      );

      // Deduct balance for standard types
      const balMap = {
        casual: 'casual_leave_balance',
        sick:   'sick_leave_balance',
        annual: 'annual_leave_balance',
      };
      const balField = balMap[leaveRequest.leave_type];
      if (balField) {
        const yr = new Date().getFullYear();
        await pool.query(
          `UPDATE leave_balances
           SET ${balField} = ${balField} - $1, updated_at = NOW()
           WHERE employee_id = $2 AND year = $3`,
          [leaveRequest.total_days, leaveRequest.employee_id, yr],
        );
      }

      // Mark attendance as 'leave' for each date in range
      const start = new Date(leaveRequest.start_date);
      const end   = new Date(leaveRequest.end_date);
      for (const d = new Date(start); d <= end; d.setDate(d.getDate() + 1)) {
        const dateStr = d.toISOString().split('T')[0];
        await pool.query(
          `INSERT INTO attendance (employee_id, date, status)
           VALUES ($1, $2, 'leave')
           ON CONFLICT (employee_id, date) DO UPDATE SET status = 'leave'`,
          [leaveRequest.employee_id, dateStr],
        );
      }

      await pool.query('COMMIT');
    } catch (err) {
      await pool.query('ROLLBACK');
      throw err;
    }

    // FIX 5: Notify employee after successful commit, non-fatal
    try {
      await createNotification({
        companyId:     req.user.company_id || 1,
        recipientId:   leaveRequest.employee_id,
        senderId:      req.user.id,
        type:          'leave_approved',
        title:         'Leave approved ✅',
        body:          `Your ${leaveRequest.leave_type} leave from ${leaveRequest.start_date} to ${leaveRequest.end_date} has been approved.`,
        referenceId:   parseInt(id),
        referenceType: 'leave',
      });
    } catch (notifErr) {
      console.error('Notification error (non-fatal):', notifErr);
    }

    res.json({ message: 'Leave request approved successfully', leave_request_id: id });
  } catch (error) {
    console.error('Approve leave error:', error);
    res.status(500).json({ error: 'Server error while approving leave' });
  }
};

// ── Reject leave (Manager / Admin) ───────────────────────────────────────
const rejectLeave = async (req, res) => {
  try {
    const { id }              = req.params;
    const { rejection_reason } = req.body;
    const approverId          = req.user.id;

    const leaveCheck = await pool.query(
      'SELECT * FROM leave_requests WHERE id = $1',
      [id],
    );
    if (leaveCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Leave request not found' });
    }
    // FIX 4: use leaveRequest (not leaveRecord)
    const leaveRequest = leaveCheck.rows[0];
    if (leaveRequest.status !== 'pending') {
      return res.status(400).json({
        error: `Leave request is already ${leaveRequest.status}`,
      });
    }

    await pool.query(
      `UPDATE leave_requests
       SET status = 'rejected', approved_by = $1, approved_at = NOW(),
           rejection_reason = $2
       WHERE id = $3`,
      [approverId, rejection_reason, id],
    );

    // FIX 5: Notify employee, non-fatal
    try {
      await createNotification({
        companyId:     req.user.company_id || 1,
        recipientId:   leaveRequest.employee_id,
        senderId:      req.user.id,
        type:          'leave_rejected',
        title:         'Leave rejected ❌',
        body:          `Your ${leaveRequest.leave_type} leave request was rejected.${rejection_reason ? ` Reason: ${rejection_reason}` : ''}`,
        referenceId:   parseInt(id),
        referenceType: 'leave',
      });
    } catch (notifErr) {
      console.error('Notification error (non-fatal):', notifErr);
    }

    res.json({ message: 'Leave request rejected', leave_request_id: id });
  } catch (error) {
    console.error('Reject leave error:', error);
    res.status(500).json({ error: 'Server error while rejecting leave' });
  }
};

// ── Cancel leave (Employee) ───────────────────────────────────────────────
const cancelLeaveRequest = async (req, res) => {
  try {
    const { id }     = req.params;
    const employeeId = req.user.id;

    const leaveCheck = await pool.query(
      'SELECT * FROM leave_requests WHERE id = $1 AND employee_id = $2',
      [id, employeeId],
    );
    if (leaveCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Leave request not found' });
    }
    if (leaveCheck.rows[0].status !== 'pending') {
      return res.status(400).json({
        error: 'Only pending leave requests can be cancelled',
      });
    }

    await pool.query(
      "UPDATE leave_requests SET status = 'cancelled' WHERE id = $1",
      [id],
    );
    res.json({ message: 'Leave request cancelled', leave_request_id: id });
  } catch (error) {
    console.error('Cancel leave error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// ── Get leave types ────────────────────────────────────────────────────────
const getLeaveTypes = async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM leave_types WHERE company_id = $1 ORDER BY id',
      [req.user.company_id || 1],
    );
    res.json({ data: result.rows });
  } catch (error) {
    console.error('Get leave types error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// ── Create leave type (Admin) ─────────────────────────────────────────────
const createLeaveType = async (req, res) => {
  try {
    const { name, code, days_allowed = 15, icon } = req.body;
    if (!name || !code) {
      return res.status(400).json({ error: 'name and code are required' });
    }
    const result = await pool.query(
      `INSERT INTO leave_types (company_id, name, code, days_allowed, icon)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [req.user.company_id || 1, name, code, days_allowed, icon],
    );
    res.status(201).json({ message: 'Leave type created', data: result.rows[0] });
  } catch (error) {
    if (error.code === '23505') {
      return res.status(400).json({ error: 'Leave type code already exists' });
    }
    console.error('Create leave type error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// ── Update leave type (Admin) ─────────────────────────────────────────────
const updateLeaveType = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, days_allowed, icon } = req.body;
    const result = await pool.query(
      `UPDATE leave_types SET name = COALESCE($1, name),
       days_allowed = COALESCE($2, days_allowed), icon = COALESCE($3, icon)
       WHERE id = $4 AND company_id = $5 RETURNING *`,
      [name, days_allowed, icon, id, req.user.company_id || 1],
    );
    if (!result.rows.length) {
      return res.status(404).json({ error: 'Leave type not found' });
    }
    res.json({ message: 'Leave type updated', data: result.rows[0] });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
};

// ── Delete leave type (Admin) ─────────────────────────────────────────────
const deleteLeaveType = async (req, res) => {
  try {
    const result = await pool.query(
      'DELETE FROM leave_types WHERE id = $1 AND company_id = $2 RETURNING id',
      [req.params.id, req.user.company_id || 1],
    );
    if (!result.rows.length) {
      return res.status(404).json({ error: 'Leave type not found' });
    }
    res.json({ message: 'Leave type deleted' });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
};

module.exports = {
  applyLeave,
  getMyLeaveRequests,
  getMyLeaveBalance,
  getPendingLeaveRequests,
  getAllLeaveRequests,
  approveLeave,
  rejectLeave,
  cancelLeaveRequest,
  getLeaveTypes,
  createLeaveType,
  updateLeaveType,
  deleteLeaveType,
};
