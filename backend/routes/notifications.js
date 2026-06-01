const express = require('express');
const { notificationsDB } = require('../database');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

router.use(authenticate);

router.get('/', async (req, res) => {
  try {
    const notifications = await notificationsDB
      .find({ userId: req.user.id })
      .sort({ read: 1, createdAt: -1 });
    res.status(200).json(notifications);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.get('/unread-count', async (req, res) => {
  try {
    const unreadCount = await notificationsDB.count({ userId: req.user.id, read: false });
    res.status(200).json({ unreadCount });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.patch('/read-all', async (req, res) => {
  try {
    await notificationsDB.update(
      { userId: req.user.id, read: false },
      { $set: { read: true } },
      { multi: true }
    );
    res.status(200).json({ message: 'All notifications marked as read' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
