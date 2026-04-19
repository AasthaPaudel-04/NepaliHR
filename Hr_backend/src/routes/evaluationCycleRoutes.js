const express = require('express');
const {
  getCycles, getCycleById, createCycle, updateCycle
} = require('../controllers/evaluationCycleController');
const { authenticateToken } = require('../middleware/auth');
const { checkRole } = require('../middleware/roleCheck');
const router = express.Router();

router.use(authenticateToken);
router.get('/', getCycles);
router.get('/:id', getCycleById);
router.post('/', checkRole(['admin']), createCycle);
router.put('/:id', checkRole(['admin']), updateCycle);
module.exports = router;

