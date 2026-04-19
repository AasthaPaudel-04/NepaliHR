const pool = require('../config/database');

// Helper function for IP to integer conversion (CIDR support)
function ipToInt(ip) {
  return ip.split('.').reduce((int, oct) => (int << 8) + parseInt(oct), 0) >>> 0;
}

// Clock In
const clockIn = async (req, res) => {
  try {
    const { device_id, ip_address } = req.body;
    const employee_id = req.user.id;
    const today = new Date().toISOString().split('T')[0];
    
    console.log('Received IP:', ip_address);
    console.log('Checking against allowed IPs...');

    // 1. Validate IP Address
    const ipCheck = await pool.query(
      'SELECT * FROM allowed_ips WHERE is_active = true'
    );

    if (ipCheck.rows.length === 0) {
      return res.status(403).json({ 
        error: 'Clock in failed: No IPs authorized. Please contact HR.' 
      });
    }

    // Check if IP matches any allowed IP (including CIDR ranges)
    const isAuthorized = ipCheck.rows.some(row => {
      const allowedIp = row.ip_address;
      
      // Exact match
      if (allowedIp === ip_address) {
        return true;
      }
      
      // CIDR range match (e.g., 192.168.0.0/24)
      if (allowedIp.includes('/')) {
        const [network, bits] = allowedIp.split('/');
        const mask = -1 << (32 - parseInt(bits));
        const networkInt = ipToInt(network);
        const ipInt = ipToInt(ip_address);
        return (networkInt & mask) === (ipInt & mask);
      }
      
      return false;
    });

    if (!isAuthorized) {
      console.log('IP not authorized:', ip_address);
      console.log('Allowed IPs:', ipCheck.rows.map(r => r.ip_address));
      return res.status(403).json({ 
        error: 'Clock in failed: IP address not authorized. Please contact HR.' 
      });
    }

    console.log('✅ IP authorized!');

    // 2. Check/Register Device
    const deviceCheck = await pool.query(
      'SELECT * FROM registered_devices WHERE employee_id = $1 AND device_id = $2',
      [employee_id, device_id]
    );

    if (deviceCheck.rows.length === 0) {
      const deviceCount = await pool.query(
        'SELECT COUNT(*) as count FROM registered_devices WHERE employee_id = $1 AND is_active = true',
        [employee_id]
      );

      if (parseInt(deviceCount.rows[0].count) >= 2) {
        return res.status(403).json({ 
          error: 'Maximum 2 devices allowed. Please remove a device first.' 
        });
      }

      await pool.query(
        `INSERT INTO registered_devices (employee_id, device_id, device_name, last_used_at)
         VALUES ($1, $2, $3, NOW())`,
        [employee_id, device_id, 'Mobile Device']
      );
      console.log('📱 New device registered');
    } else if (!deviceCheck.rows[0].is_active) {
      return res.status(403).json({ 
        error: 'Device is not active. Please contact HR.' 
      });
    } else {
      await pool.query(
        'UPDATE registered_devices SET last_used_at = NOW() WHERE employee_id = $1 AND device_id = $2',
        [employee_id, device_id]
      );
    }

    // 3. Check if already clocked in today
    const existingAttendance = await pool.query(
      'SELECT * FROM attendance WHERE employee_id = $1 AND date = $2',
      [employee_id, today]
    );

    if (existingAttendance.rows.length > 0 && existingAttendance.rows[0].check_in_time) {
      return res.status(400).json({ 
        error: 'Already clocked in today',
        attendance: existingAttendance.rows[0]
      });
    }

    // 4. Get employee's current shift
    const shiftQuery = await pool.query(
      `SELECT s.* 
       FROM shifts s
       JOIN employee_shifts es ON s.id = es.shift_id
       WHERE es.employee_id = $1 
       AND es.is_active = true
       AND (es.effective_to IS NULL OR es.effective_to >= CURRENT_DATE)
       ORDER BY es.effective_from DESC
       LIMIT 1`,
      [employee_id]
    );

    if (shiftQuery.rows.length === 0) {
      return res.status(400).json({ 
        error: 'No shift assigned. Please contact HR.' 
      });
    }

    const shift = shiftQuery.rows[0];
    const currentTime = new Date();
    const shiftStart = new Date(`${today} ${shift.start_time}`);
    const graceEndTime = new Date(shiftStart.getTime() + shift.grace_period_minutes * 60000);

    // 5. Determine status
    let status = 'Present';
    if (currentTime > graceEndTime) {
      status = 'Late';
    }

    // 6. Insert attendance record
    const result = await pool.query(
      `INSERT INTO attendance 
       (employee_id, date, check_in_time, check_in_ip, check_in_device_id, status)
       VALUES ($1, $2, NOW() AT TIME ZONE 'Asia/Kathmandu', $3, $4, $5)
       RETURNING *`,
      [employee_id, today, ip_address, device_id, status]
    );

    console.log('✅ Clock in successful!');

    res.json({
      message: `Clocked in successfully - ${status}`,
      attendance: result.rows[0],
      shift: {
        name: shift.shift_name,
        start_time: shift.start_time,
        end_time: shift.end_time
      }
    });

  } catch (error) {
    console.error('Clock in error:', error);
    res.status(500).json({ error: 'Server error during clock in' });
  }
};

// Clock Out
const clockOut = async (req, res) => {
  try {
    const { device_id, ip_address } = req.body;
    const employee_id = req.user.id;
    const today = new Date().toISOString().split('T')[0];

    const attendance = await pool.query(
      'SELECT * FROM attendance WHERE employee_id = $1 AND date = $2',
      [employee_id, today]
    );

    if (attendance.rows.length === 0 || !attendance.rows[0].check_in_time) {
      return res.status(400).json({ 
        error: 'No clock in record found for today' 
      });
    }

    if (attendance.rows[0].check_out_time) {
      return res.status(400).json({ 
        error: 'Already clocked out today',
        attendance: attendance.rows[0]
      });
    }

    const result = await pool.query(
      `UPDATE attendance 
       SET check_out_time = NOW() AT TIME ZONE 'Asia/Kathmandu',
           check_out_ip = $1,
           check_out_device_id = $2,
           total_hours = EXTRACT(EPOCH FROM (NOW() AT TIME ZONE 'Asia/Kathmandu' - check_in_time)) / 3600
       WHERE employee_id = $3 AND date = $4
       RETURNING *`,
      [ip_address, device_id, employee_id, today]
    );

    const updatedAttendance = result.rows[0];

    if (updatedAttendance.total_hours < 4 && updatedAttendance.status !== 'WFH') {
      await pool.query(
        'UPDATE attendance SET status = $1 WHERE id = $2',
        ['Half Day', updatedAttendance.id]
      );
      updatedAttendance.status = 'Half Day';
    }

    res.json({
      message: 'Clocked out successfully',
      attendance: updatedAttendance,
      total_hours: Math.round(updatedAttendance.total_hours * 100) / 100
    });

  } catch (error) {
    console.error('Clock out error:', error);
    res.status(500).json({ error: 'Server error during clock out' });
  }
};

// Get Today's Attendance Status
const getTodayAttendance = async (req, res) => {
  try {
    const employee_id = req.user.id;
    const today = new Date().toISOString().split('T')[0];

    const result = await pool.query(
      `SELECT a.*, 
              s.shift_name, s.start_time, s.end_time,
              e.full_name, e.employee_code
       FROM attendance a
       LEFT JOIN employee_shifts es ON a.employee_id = es.employee_id AND es.is_active = true
       LEFT JOIN shifts s ON es.shift_id = s.id
       LEFT JOIN employees e ON a.employee_id = e.id
       WHERE a.employee_id = $1 AND a.date = $2`,
      [employee_id, today]
    );

    if (result.rows.length === 0) {
      const shiftInfo = await pool.query(
        `SELECT s.shift_name, s.start_time, s.end_time
         FROM shifts s
         JOIN employee_shifts es ON s.id = es.shift_id
         WHERE es.employee_id = $1 AND es.is_active = true
         LIMIT 1`,
        [employee_id]
      );

      return res.json({
        hasClocked: false,
        shift: shiftInfo.rows[0] || null
      });
    }

    res.json({
      hasClocked: true,
      attendance: result.rows[0]
    });

  } catch (error) {
    console.error('Get today attendance error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Get Monthly Attendance History
const getMonthlyAttendance = async (req, res) => {
  try {
    const employee_id = req.user.id;
    const { month, year } = req.query;

    const currentDate = new Date();
    const targetMonth = month || (currentDate.getMonth() + 1);
    const targetYear = year || currentDate.getFullYear();

    const result = await pool.query(
      `SELECT a.*, s.shift_name, s.start_time, s.end_time
       FROM attendance a
       LEFT JOIN employee_shifts es ON a.employee_id = es.employee_id AND es.is_active = true
       LEFT JOIN shifts s ON es.shift_id = s.id
       WHERE a.employee_id = $1
       AND EXTRACT(MONTH FROM a.date) = $2
       AND EXTRACT(YEAR FROM a.date) = $3
       ORDER BY a.date DESC`,
      [employee_id, targetMonth, targetYear]
    );

    res.json({
      month: targetMonth,
      year: targetYear,
      attendance: result.rows
    });

  } catch (error) {
    console.error('Get monthly attendance error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Get Attendance Summary
const getAttendanceSummary = async (req, res) => {
  try {
    const employee_id = req.user.id;
    const { month, year } = req.query;

    const currentDate = new Date();
    const targetMonth = month || (currentDate.getMonth() + 1);
    const targetYear = year || currentDate.getFullYear();

    const result = await pool.query(
      `SELECT 
         COUNT(*) as total_days,
         COUNT(CASE WHEN status = 'Present' THEN 1 END) as present_days,
         COUNT(CASE WHEN status = 'Late' THEN 1 END) as late_days,
         COUNT(CASE WHEN status = 'Half Day' THEN 1 END) as half_days,
         COUNT(CASE WHEN status = 'Absent' THEN 1 END) as absent_days,
         COUNT(CASE WHEN status = 'WFH' THEN 1 END) as wfh_days,
         ROUND(AVG(total_hours), 2) as avg_hours,
         ROUND(SUM(total_hours), 2) as total_hours_worked
       FROM attendance
       WHERE employee_id = $1
       AND EXTRACT(MONTH FROM date) = $2
       AND EXTRACT(YEAR FROM date) = $3`,
      [employee_id, targetMonth, targetYear]
    );

    res.json({
      month: targetMonth,
      year: targetYear,
      summary: result.rows[0]
    });

  } catch (error) {
    console.error('Get attendance summary error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Get Team Attendance (For Managers)
const getTeamAttendance = async (req, res) => {
  try {
    const { date } = req.query;
    const targetDate = date || new Date().toISOString().split('T')[0];

    const result = await pool.query(
      `SELECT 
         e.id, e.employee_code, e.full_name, e.department, e.position,
         a.check_in_time, a.check_out_time, a.status, a.total_hours,
         s.shift_name, s.start_time
       FROM employees e
       LEFT JOIN attendance a ON e.id = a.employee_id AND a.date = $1
       LEFT JOIN employee_shifts es ON e.id = es.employee_id AND es.is_active = true
       LEFT JOIN shifts s ON es.shift_id = s.id
       WHERE e.status = 'active'
       ORDER BY e.full_name`,
      [targetDate]
    );

    res.json({
      date: targetDate,
      team: result.rows
    });

  } catch (error) {
    console.error('Get team attendance error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Get Registered Devices
const getMyDevices = async (req, res) => {
  try {
    const employee_id = req.user.id;

    const result = await pool.query(
      `SELECT id, device_id, device_name, is_active, registered_at, last_used_at
       FROM registered_devices
       WHERE employee_id = $1
       ORDER BY registered_at DESC`,
      [employee_id]
    );

    res.json({
      devices: result.rows,
      maxDevices: 2
    });

  } catch (error) {
    console.error('Get devices error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Remove Device
const removeDevice = async (req, res) => {
  try {
    const employee_id = req.user.id;
    const { device_id } = req.params;

    const result = await pool.query(
      'DELETE FROM registered_devices WHERE employee_id = $1 AND id = $2 RETURNING *',
      [employee_id, device_id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Device not found' });
    }

    res.json({
      message: 'Device removed successfully',
      device: result.rows[0]
    });

  } catch (error) {
    console.error('Remove device error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

const getAllEmployeesToday = async (req, res) => {
  try {
    const { date } = req.query;
    const targetDate = date || new Date().toISOString().split('T')[0];

    // Get all active employees + their attendance for the date
    const result = await pool.query(
      `SELECT
         e.id AS employee_id,
         e.employee_code,
         e.full_name,
         e.department,
         e.position,
         e.role,
         a.id AS attendance_id,
         a.check_in_time,
         a.check_out_time,
         a.status,
         a.total_hours,
         s.shift_name,
         s.start_time AS shift_start,
         s.end_time AS shift_end
       FROM employees e
       LEFT JOIN attendance a ON a.employee_id = e.id AND a.date = $1
       LEFT JOIN employee_shifts es ON es.employee_id = e.id AND es.is_active = true
       LEFT JOIN shifts s ON s.id = es.shift_id
       WHERE e.status = 'active' AND e.company_id = $2
       ORDER BY e.full_name`,
      [targetDate, req.user.company_id || 1]
    );

    // Mark absent for employees with no attendance record today
    const enriched = result.rows.map(row => ({
      ...row,
      status: row.status || (new Date(targetDate) < new Date() ? 'Absent' : 'Not clocked in'),
    }));

    res.json({ date: targetDate, data: enriched });
  } catch (err) {
    console.error('Get all employees today error:', err);
    res.status(500).json({ error: 'Server error' });
  }
};

const getMonthlyAttendanceAdmin = async (req, res) => {
  try {
    const { employee_id, month, year } = req.query;
    const now = new Date();
    const m = month || (now.getMonth() + 1);
    const y = year || now.getFullYear();

    let query = `
      SELECT a.*, e.full_name, e.employee_code,
             s.shift_name, s.start_time, s.end_time
      FROM attendance a
      JOIN employees e ON e.id = a.employee_id
      LEFT JOIN employee_shifts es ON es.employee_id = a.employee_id AND es.is_active = true
      LEFT JOIN shifts s ON s.id = es.shift_id
      WHERE e.company_id = $1
        AND EXTRACT(MONTH FROM a.date) = $2
        AND EXTRACT(YEAR FROM a.date) = $3
    `;
    const params = [req.user.company_id || 1, m, y];
    if (employee_id) {
      params.push(employee_id);
      query += ` AND a.employee_id = $${params.length}`;
    }
    query += ' ORDER BY a.date DESC, e.full_name';

    const result = await pool.query(query, params);
    res.json({ month: m, year: y, data: result.rows });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
};


module.exports = {
  clockIn,
  clockOut,
  getTodayAttendance,
  getMonthlyAttendance,
  getAttendanceSummary,
  getTeamAttendance,
  getMyDevices,
  removeDevice,
  getMonthlyAttendanceAdmin,
  getAllEmployeesToday
};
