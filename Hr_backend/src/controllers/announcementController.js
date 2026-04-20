const pool = require('../config/database');
const { createNotification } = require('./notificationController');

// Create announcement (Admin/Manager) 
const createAnnouncement = async (req, res) => {
  try {
    const { title, message, priority = 'normal' } = req.body;

    if (!title || !message) {
      return res.status(400).json({ error: 'title and message are required' });
    }

    const validPriorities = ['low', 'normal', 'high', 'urgent'];
    if (!validPriorities.includes(priority)) {
      return res.status(400).json({ error: 'priority must be: low, normal, high, urgent' });
    }

    const result = await pool.query(
      `INSERT INTO announcements (company_id, title, message, priority, created_by)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [req.user.company_id || 1, title, message, priority, req.user.id]
    );

    const announcementId = result.rows[0].id;

    // Fetch with creator name
    const full = await pool.query(
      `SELECT a.*, e.full_name AS created_by_name
       FROM announcements a
       JOIN employees e ON e.id = a.created_by
       WHERE a.id = $1`,
      [announcementId]
    );

    // Create a notification for every employee in the company 
    try {
      const employees = await pool.query(
        `SELECT id FROM employees WHERE company_id = $1 AND is_active = TRUE`,
        [req.user.company_id || 1]
      );

      const priorityLabel = priority === 'urgent' ? '🚨 URGENT: '
                          : priority === 'high'   ? '⚠️ '
                          : '';

      await Promise.all(
        employees.rows.map((emp) =>
          createNotification({
            companyId:     req.user.company_id || 1,
            recipientId:   emp.id,
            senderId:      req.user.id,
            type:          'announcement',
            title:         `${priorityLabel}${title}`,
            body:          message.length > 120 ? message.substring(0, 120) + '…' : message,
            referenceId:   announcementId,
            referenceType: 'announcement',
          })
        )
      );
    } catch (notifErr) {
      console.error('Failed to create announcement notifications:', notifErr);
    }

    res.status(201).json({ message: 'Announcement created', data: full.rows[0] });
  } catch (error) {
    console.error('Create announcement error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// ─── Get all announcements 

const getAnnouncements = async (req, res) => {
  try {
    const { priority, limit = 20, offset = 0 } = req.query;

    let query = `
      SELECT a.*, e.full_name AS created_by_name
      FROM announcements a
      JOIN employees e ON e.id = a.created_by
      WHERE a.company_id = $1
    `;
    const params = [req.user.company_id || 1];

    if (priority) {
      params.push(priority);
      query += ` AND a.priority = $${params.length}`;
    }

    query += ` ORDER BY
      CASE a.priority
        WHEN 'urgent' THEN 1
        WHEN 'high' THEN 2
        WHEN 'normal' THEN 3
        ELSE 4
      END,
      a.created_at DESC
      LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
    params.push(parseInt(limit), parseInt(offset));

    const result = await pool.query(query, params);

    const countResult = await pool.query(
      'SELECT COUNT(*) FROM announcements WHERE company_id = $1',
      [req.user.company_id || 1]
    );

    res.json({
      data: result.rows,
      total: parseInt(countResult.rows[0].count),
    });
  } catch (error) {
    console.error('Get announcements error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};


const getRecentCount = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT COUNT(*) FROM announcements
       WHERE company_id = $1 AND created_at >= NOW() - INTERVAL '7 days'`,
      [req.user.company_id || 1]
    );
    res.json({ count: parseInt(result.rows[0].count) });
  } catch (error) {
    console.error('Get recent count error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};


const getAnnouncementById = async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(
      `SELECT a.*, e.full_name AS created_by_name
       FROM announcements a
       JOIN employees e ON e.id = a.created_by
       WHERE a.id = $1 AND a.company_id = $2`,
      [id, req.user.company_id || 1]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Announcement not found' });
    res.json({ data: result.rows[0] });
  } catch (error) {
    console.error('Get announcement error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Update announcement (Admin/Manager only) 

const updateAnnouncement = async (req, res) => {
  try {
    const { id } = req.params;
    const { title, message, priority } = req.body;
    const result = await pool.query(
      `UPDATE announcements SET
         title = COALESCE($1, title),
         message = COALESCE($2, message),
         priority = COALESCE($3, priority)
       WHERE id = $4 AND company_id = $5
       RETURNING *`,
      [title, message, priority, id, req.user.company_id || 1]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Announcement not found' });
    res.json({ message: 'Announcement updated', data: result.rows[0] });
  } catch (error) {
    console.error('Update announcement error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Delete announcement (Admin only) 

const deleteAnnouncement = async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(
      'DELETE FROM announcements WHERE id = $1 AND company_id = $2 RETURNING id',
      [id, req.user.company_id || 1]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Not found' });
    res.json({ message: 'Announcement deleted' });
  } catch (error) {
    console.error('Delete announcement error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

module.exports = {
  createAnnouncement,
  getAnnouncements,
  getRecentCount,
  getAnnouncementById,
  updateAnnouncement,
  deleteAnnouncement,
};
