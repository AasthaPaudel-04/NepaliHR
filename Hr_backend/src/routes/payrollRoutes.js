const express = require('express');
const {
  getSalaryStructure,
  upsertSalaryStructure,
  generatePayroll,
  getMyPayslips,
  getPayslipDetail,
  getAllPayrolls,
  markAsPaid,
  generateBulkPayroll,
} = require('../controllers/payrollController');
const { authenticateToken } = require('../middleware/auth');
const { checkRole } = require('../middleware/roleCheck');

const router = express.Router();

// All routes require authentication
router.use(authenticateToken);

// ── Employee routes ────────────────────────────────────────────────────────────
router.get('/my-payslips', getMyPayslips);
router.get('/payslip/:id', getPayslipDetail);
router.get('/my-salary', getSalaryStructure);

// ── Admin / Manager routes ─────────────────────────────────────────────────────
router.get('/salary/:employeeId', checkRole(['admin', 'manager']), getSalaryStructure);
router.post('/salary', checkRole(['admin']), upsertSalaryStructure);
router.post('/generate', checkRole(['admin', 'manager']), generatePayroll);
router.post('/generate-bulk', checkRole(['admin']), generateBulkPayroll);
router.get('/all', checkRole(['admin', 'manager']), getAllPayrolls);
router.put('/:id/mark-paid', checkRole(['admin']), markAsPaid);

module.exports = router;