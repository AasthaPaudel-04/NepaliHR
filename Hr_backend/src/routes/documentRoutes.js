const express = require('express');
const {
  upload,
  uploadDocument,
  getMyDocuments,
  getAllDocuments,
  deleteDocument,
} = require('../controllers/documentController');
const { authenticateToken } = require('../middleware/auth');
const { checkRole } = require('../middleware/roleCheck');

const router = express.Router();

router.use(authenticateToken);

// ── Employee routes ────────────────────────────────────────────────────────────
router.get('/my-documents', getMyDocuments);
router.post('/upload', upload.single('file'), uploadDocument);
router.delete('/:id', deleteDocument);

// ── Admin / Manager routes ─────────────────────────────────────────────────────
router.get('/all', checkRole(['admin', 'manager']), getAllDocuments);

module.exports = router;