const express = require('express');
const {
  applyLeave,
  getMyLeaveRequests,
  getMyLeaveBalance,
  getPendingLeaveRequests,
  getAllLeaveRequests,
  approveLeave,
  rejectLeave,
  cancelLeaveRequest
} = require('../controllers/leaveController');
const { getLeaveTypes, getAllLeaveTypes, createLeaveType, updateLeaveType, deleteLeaveType } = require('../controllers/leaveTypeController');
const { authenticateToken } = require('../middleware/auth');
const { checkRole } = require('../middleware/roleCheck');

const router = express.Router();

// Employee routes (any authenticated user)
router.post('/request', authenticateToken, applyLeave);
router.get('/my-requests', authenticateToken, getMyLeaveRequests);
router.get('/my-balance', authenticateToken, getMyLeaveBalance);
router.put('/:id/cancel', authenticateToken, cancelLeaveRequest);

// Manager/Admin routes (role-protected)
router.get('/pending', authenticateToken, checkRole(['admin', 'manager']), getPendingLeaveRequests);
router.get('/all', authenticateToken, checkRole(['admin', 'manager']), getAllLeaveRequests);
router.put('/:id/approve', authenticateToken, checkRole(['admin', 'manager']), approveLeave);
router.put('/:id/reject', authenticateToken, checkRole(['admin', 'manager']), rejectLeave);


router.get('/types',        authenticateToken, getLeaveTypes);        // all employees
router.get('/types/all',    authenticateToken, checkRole(['admin','manager']), getAllLeaveTypes);
router.post('/types',       authenticateToken, checkRole(['admin']), createLeaveType);
router.put('/types/:id',    authenticateToken, checkRole(['admin']), updateLeaveType);
router.delete('/types/:id', authenticateToken, checkRole(['admin']), deleteLeaveType);

module.exports = router;