const express = require('express');
const {
  getJobRoles, createJobRole, updateJobRole, deleteJobRole, assignEmployeeRole
} = require('../controllers/jobRoleController');
const { authenticateToken } = require('../middleware/auth');
const { checkRole } = require('../middleware/roleCheck');
const router = express.Router();

router.use(authenticateToken);
router.get('/', getJobRoles);
router.post('/', checkRole(['admin']), createJobRole);
router.put('/:id', checkRole(['admin']), updateJobRole);
router.delete('/:id', checkRole(['admin']), deleteJobRole);
router.post('/assign-employee', checkRole(['admin', 'manager']), assignEmployeeRole);
module.exports = router;
