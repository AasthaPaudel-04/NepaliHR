const express = require('express');
const {
  getKPIs, getKPIsForRole, createKPI, updateKPI, deleteKPI, assignKPIToRoles
} = require('../controllers/kpiController');
const { authenticateToken } = require('../middleware/auth');
const { checkRole } = require('../middleware/roleCheck');
const router = express.Router();

router.use(authenticateToken);
router.get('/', getKPIs);
router.get('/role/:role_id', getKPIsForRole);
router.post('/', checkRole(['admin']), createKPI);
router.put('/:id', checkRole(['admin']), updateKPI);
router.delete('/:id', checkRole(['admin']), deleteKPI);
router.post('/assign-roles', checkRole(['admin']), assignKPIToRoles);
module.exports = router;
