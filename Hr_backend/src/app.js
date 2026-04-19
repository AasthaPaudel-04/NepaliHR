const express = require('express');
const cors = require('cors');
const path = require('path');
require('dotenv').config();

const authRoutes         = require('./routes/authRoutes');
const leaveRoutes        = require('./routes/leaveRoutes');
const attendanceRoutes   = require('./routes/attendanceRoutes');
const payrollRoutes      = require('./routes/payrollRoutes');
const shiftRoutes        = require('./routes/shiftRoutes');
const documentRoutes     = require('./routes/documentRoutes');
const announcementRoutes = require('./routes/announcementRoutes');

const departmentRoutes       = require('./routes/departmentRoutes');
const jobRoleRoutes          = require('./routes/jobRoleRoutes');
const kpiRoutes              = require('./routes/kpiRoutes');
const evaluationCycleRoutes  = require('./routes/evaluationCycleRoutes');
const evaluationRoutes       = require('./routes/evaluationRoutes');
const notificationRoutes = require('./routes/notificationRoutes');


const app = express();

// ── Middleware ──────────────────────────────────────────────
app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// ── Existing Routes ─────────────────────────────────────────
app.use('/api/auth',          authRoutes);
app.use('/api/leave',         leaveRoutes);
app.use('/api/attendance',    attendanceRoutes);
app.use('/api/payroll',       payrollRoutes);
app.use('/api/shifts',        shiftRoutes);
app.use('/api/documents',     documentRoutes);
app.use('/api/announcements', announcementRoutes);
app.use('/api/departments',        departmentRoutes);
app.use('/api/job-roles',          jobRoleRoutes);
app.use('/api/kpis',               kpiRoutes);
app.use('/api/evaluation-cycles',  evaluationCycleRoutes);
app.use('/api/evaluations',        evaluationRoutes);
app.use('/api/notifications', notificationRoutes);


// ───────────────────────────────────────────────────────────

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', message: 'HR Management API is running', timestamp: new Date().toISOString() });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Error:', err.stack);
  if (err.code === 'LIMIT_FILE_SIZE') {
    return res.status(400).json({ error: 'File too large. Max 10MB allowed.' });
  }
  res.status(500).json({ error: err.message || 'Something went wrong!' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

module.exports = app;
