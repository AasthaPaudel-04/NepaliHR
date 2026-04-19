const express = require('express');
const {
  getDepartments, createDepartment, updateDepartment, deleteDepartment
} = require('../controllers/departmentController');
const { authenticateToken } = require('../middleware/auth');
const { checkRole } = require('../middleware/roleCheck');
const router = express.Router();

router.use(authenticateToken);
router.get('/', getDepartments);                                      // all authenticated
router.post('/', checkRole(['admin']), createDepartment);
router.put('/:id', checkRole(['admin']), updateDepartment);
router.delete('/:id', checkRole(['admin']), deleteDepartment);

module.exports = router;





