const express = require('express');
const { register, login, getCurrentUser, getAllEmployees } = require('../controllers/authController');
const { authenticateToken } = require('../middleware/auth');
const { checkRole } = require('../middleware/roleCheck');
const router = express.Router();
 
// Public routes
router.post('/register', register);
router.post('/login', login);
 
// Protected routes
router.get('/me', authenticateToken, getCurrentUser);
router.get('/employees', authenticateToken, checkRole(['admin', 'manager']), getAllEmployees);
 
module.exports = router;