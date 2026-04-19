const express = require('express');
const {
  createAnnouncement,
  getAnnouncements,
  getRecentCount,
  getAnnouncementById,
  updateAnnouncement,
  deleteAnnouncement,
} = require('../controllers/announcementController');
const { authenticateToken } = require('../middleware/auth');
const { checkRole } = require('../middleware/roleCheck');

const router = express.Router();

router.use(authenticateToken);

// ── All employees ──────────────────────────────────────────────────────────────
router.get('/', getAnnouncements);
router.get('/recent-count', getRecentCount);
router.get('/:id', getAnnouncementById);

// ── Admin / Manager ────────────────────────────────────────────────────────────
router.post('/', checkRole(['admin', 'manager']), createAnnouncement);
router.put('/:id', checkRole(['admin', 'manager']), updateAnnouncement);
router.delete('/:id', checkRole(['admin']), deleteAnnouncement);

module.exports = router;