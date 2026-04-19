const pool = require('../config/database');

// ── Internal helper — called by other controllers ─────────────────────────
// Usage:  const { createNotification } = require('./notificationController');
//         await createNotification({ companyId, recipientId, senderId, type, title, body, referenceId, referenceType });
const createNotification = async ({
  companyId = 1, recipientId, senderId = null,
  type, title, body, referenceId = null, referenceType = null,
}) => {
  if (!recipientId || !type || !title || !body) return;
  await pool.query(
    `INSERT INTO notifications
       (company_id, recipient_id, sender_id, type, title, body, reference_id, reference_type)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
    [companyId, recipientId, senderId, type, title, body, referenceId, referenceType],
  );
};

// ── Internal helper — notify all admins in a company ─────────────────────
const notifyAdmins = async ({
  companyId = 1, senderId = null,
  type, title, body, referenceId = null, referenceType = null,
}) => {
  const admins = await pool.query(
    `SELECT id FROM employees
     WHERE role = 'admin' AND status = 'active' AND company_id = $1`,
    [companyId],
  );
  for (const admin of admins.rows) {
    if (admin.id === senderId) continue; // don't notify the sender
    await createNotification({
      companyId, recipientId: admin.id, senderId,
      type, title, body, referenceId, referenceType,
    });
  }
};

// ── GET /notifications ─────────────────────────────────────────────────────
const getNotifications = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT n.*,
              sender.full_name AS sender_name
       FROM notifications n
       LEFT JOIN employees sender ON sender.id = n.sender_id
       WHERE n.recipient_id = $1
       ORDER BY n.created_at DESC
       LIMIT 100`,
      [req.user.id],
    );
    res.json({ data: result.rows });
  } catch (error) {
    console.error('Get notifications error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// ── GET /notifications/unread-count ───────────────────────────────────────
const getUnreadCount = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT COUNT(*) FROM notifications
       WHERE recipient_id = $1 AND is_read = FALSE`,
      [req.user.id],
    );
    res.json({ count: parseInt(result.rows[0].count) });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
};

// ── PUT /notifications/:id/read ────────────────────────────────────────────
const markRead = async (req, res) => {
  try {
    await pool.query(
      `UPDATE notifications SET is_read = TRUE
       WHERE id = $1 AND recipient_id = $2`,
      [req.params.id, req.user.id],
    );
    res.json({ message: 'Marked as read' });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
};

// ── PUT /notifications/read-all ────────────────────────────────────────────
const markAllRead = async (req, res) => {
  try {
    await pool.query(
      `UPDATE notifications SET is_read = TRUE WHERE recipient_id = $1`,
      [req.user.id],
    );
    res.json({ message: 'All marked as read' });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
};

module.exports = {
  createNotification,
  notifyAdmins,
  getNotifications,
  getUnreadCount,
  markRead,
  markAllRead,
};
