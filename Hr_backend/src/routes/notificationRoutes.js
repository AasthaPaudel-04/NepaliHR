const express = require('express');
const {
  getNotifications,
  getUnreadCount,
  markRead,
  markAllRead,
} = require('../controllers/notificationController');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();
router.use(authenticateToken);

router.get('/',            getNotifications);
router.get('/unread-count', getUnreadCount);
router.put('/read-all',    markAllRead);
router.put('/:id/read',    markRead);

module.exports = router;
