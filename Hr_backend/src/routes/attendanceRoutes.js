// src/routes/attendanceRoutes.js
const express = require('express');
const router = express.Router();
const {
  clockIn,
  clockOut,
  getTodayAttendance,
  getMonthlyAttendance,
  getAttendanceSummary,
  getTeamAttendance,
  getMyDevices,
  removeDevice,
  getAllEmployeesToday,        // NEW - add this to attendanceController.js
  getMonthlyAttendanceAdmin,  // NEW - add this to attendanceController.js
} = require('../controllers/attendanceController');
const { authenticateToken } = require('../middleware/auth');
const { checkRole }         = require('../middleware/roleCheck');

// ── All authenticated employees
router.post('/clock-in',  authenticateToken, clockIn);
router.post('/clock-out', authenticateToken, clockOut);
router.get('/today',      authenticateToken, getTodayAttendance);
router.get('/monthly',    authenticateToken, getMonthlyAttendance);
router.get('/summary',    authenticateToken, getAttendanceSummary);
router.get('/my-devices', authenticateToken, getMyDevices);
router.delete('/devices/:device_id', authenticateToken, removeDevice);

// ── Manager / Admin
router.get('/team',
  authenticateToken, checkRole(['admin', 'manager']), getTeamAttendance);

router.get('/all-today',
  authenticateToken, checkRole(['admin', 'manager']), getAllEmployeesToday);

router.get('/monthly-admin',
  authenticateToken, checkRole(['admin', 'manager']), getMonthlyAttendanceAdmin);

module.exports = router;