const express = require('express');
const {
  getAllShifts,
  createShift,
  updateShift,
  deleteShift,
  assignShift,
  getEmployeeShifts,
  getMyShift,
} = require('../controllers/shiftController');
const { authenticateToken } = require('../middleware/auth');
const { checkRole } = require('../middleware/roleCheck');

const router = express.Router();

router.use(authenticateToken);

// ── Employee routes ────────────────────────────────────────────────────────────
router.get('/my-shift', getMyShift);

// ── Admin / Manager routes ─────────────────────────────────────────────────────
router.get('/', checkRole(['admin', 'manager']), getAllShifts);
router.post('/', checkRole(['admin', 'manager']), createShift);
router.put('/:id', checkRole(['admin', 'manager']), updateShift);
router.delete('/:id', checkRole(['admin']), deleteShift);
router.post('/assign', checkRole(['admin', 'manager']), assignShift);
router.get('/employee-shifts', checkRole(['admin', 'manager']), getEmployeeShifts);

module.exports = router;