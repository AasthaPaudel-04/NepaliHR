// src/routes/evaluationRoutes.js
const express = require('express');
const {
  getMyPendingEvaluations,
  getCycleEvaluationStatus,
  getEvaluationForm,
  submitEvaluation,
  getPerformanceResults,
  getMyPerformanceResult,
  saveFeedback,
  setDevelopmentPlan,
  initiateCycleEvaluations,
  assignPeerEvaluator,
} = require('../controllers/evaluationController');
const { authenticateToken } = require('../middleware/auth');
const { checkRole } = require('../middleware/roleCheck');

const router = express.Router();
router.use(authenticateToken);

// ── All authenticated employees ─────────────────────────────
router.get('/my-evaluations',         getMyPendingEvaluations);
router.get('/form/:evaluation_id',    getEvaluationForm);
router.post('/submit/:evaluation_id', submitEvaluation);
router.get('/my-result/:cycle_id',    getMyPerformanceResult);

// ── Manager / HR (admin) ────────────────────────────────────
router.post('/feedback/:evaluation_id',
  checkRole(['admin', 'manager']), saveFeedback);

// ── Admin only ──────────────────────────────────────────────
router.get('/cycle-status/:cycle_id',
  checkRole(['admin', 'manager']), getCycleEvaluationStatus);
router.get('/results/:cycle_id',
  checkRole(['admin', 'manager']), getPerformanceResults);
router.post('/cycle/:cycle_id/initiate',
  checkRole(['admin']), initiateCycleEvaluations);
router.post('/assign-peer',
  checkRole(['admin', 'manager']), assignPeerEvaluator);
router.put('/development/:cycle_id/:employee_id',
  checkRole(['admin']), setDevelopmentPlan);

module.exports = router;