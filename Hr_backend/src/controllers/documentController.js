const pool = require('../config/database');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// ─── Multer storage config ─────────────────────────────────────────────────────
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = path.join(__dirname, '../../uploads/documents');
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
    const ext = path.extname(file.originalname).toLowerCase();
    cb(null, `doc-${req.user.id}-${uniqueSuffix}${ext}`);
  },
});

// Only check file extension (Windows sends wrong MIME types)
const fileFilter = (req, file, cb) => {
  const allowedExtensions = ['.pdf', '.jpg', '.jpeg', '.png', '.doc', '.docx'];
  const ext = path.extname(file.originalname).toLowerCase();
  if (allowedExtensions.includes(ext)) {
    cb(null, true);
  } else {
    cb(new Error('Only PDF, JPG, PNG, DOC, DOCX files are allowed'));
  }
};

const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB
  fileFilter,
});

// ─── Upload document ──────────────────────────────────────────────────────────
const uploadDocument = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }

    const { document_type = 'other', document_name, employee_id } = req.body;

    const targetEmployeeId = (req.user.role !== 'employee' && employee_id)
      ? employee_id
      : req.user.id;

    const fileUrl = `/uploads/documents/${req.file.filename}`;
    const fileName = document_name || req.file.originalname;

    const result = await pool.query(
      `INSERT INTO documents (employee_id, document_type, document_name, file_url, file_size, uploaded_by)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [targetEmployeeId, document_type, fileName, fileUrl, req.file.size, req.user.id]
    );

    res.status(201).json({ message: 'Document uploaded successfully', data: result.rows[0] });
  } catch (error) {
    console.error('Upload document error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// ─── Get my documents ─────────────────────────────────────────────────────────
const getMyDocuments = async (req, res) => {
  try {
    const { document_type } = req.query;
    let query = `
      SELECT d.*, uploader.full_name AS uploaded_by_name
      FROM documents d
      LEFT JOIN employees uploader ON uploader.id = d.uploaded_by
      WHERE d.employee_id = $1
    `;
    const params = [req.user.id];

    if (document_type) {
      params.push(document_type);
      query += ` AND d.document_type = $${params.length}`;
    }
    query += ' ORDER BY d.uploaded_at DESC';

    const result = await pool.query(query, params);
    res.json({ data: result.rows });
  } catch (error) {
    console.error('Get my documents error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// ─── Get all documents (Admin/Manager) ────────────────────────────────────────
const getAllDocuments = async (req, res) => {
  try {
    const { employee_id, document_type } = req.query;
    let query = `
      SELECT d.*, e.full_name AS employee_name, e.employee_code,
             uploader.full_name AS uploaded_by_name
      FROM documents d
      JOIN employees e ON e.id = d.employee_id
      LEFT JOIN employees uploader ON uploader.id = d.uploaded_by
      WHERE 1=1
    `;
    const params = [];

    if (employee_id) { params.push(employee_id); query += ` AND d.employee_id = $${params.length}`; }
    if (document_type) { params.push(document_type); query += ` AND d.document_type = $${params.length}`; }
    query += ' ORDER BY d.uploaded_at DESC';

    const result = await pool.query(query, params);
    res.json({ data: result.rows });
  } catch (error) {
    console.error('Get all documents error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// ─── Delete document ──────────────────────────────────────────────────────────
const deleteDocument = async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query('SELECT * FROM documents WHERE id = $1', [id]);
    if (result.rows.length === 0) return res.status(404).json({ error: 'Document not found' });

    const doc = result.rows[0];
    if (req.user.role === 'employee' && doc.employee_id !== req.user.id) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const filePath = path.join(__dirname, '../..', doc.file_url);
    if (fs.existsSync(filePath)) fs.unlinkSync(filePath);

    await pool.query('DELETE FROM documents WHERE id = $1', [id]);
    res.json({ message: 'Document deleted' });
  } catch (error) {
    console.error('Delete document error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

module.exports = { upload, uploadDocument, getMyDocuments, getAllDocuments, deleteDocument };