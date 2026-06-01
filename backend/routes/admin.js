const express = require('express');
const { usersDB, servicesDB, bookingsDB, reviewsDB, auditLogsDB } = require('../database');
const { authenticate } = require('../middleware/auth');
const { allowRoles, ROLES } = require('../middleware/rbac');
const { createAuditLog, sanitizeBooking, sanitizeService } = require('../utils/appHelpers');

const router = express.Router();

router.use(authenticate);
router.use(allowRoles(ROLES.ADMIN));

router.get('/stats', async (req, res) => {
  try {
    const totalUsers = await usersDB.count({});
    const totalProviders = await usersDB.count({ role: 'provider' });
    const totalCustomers = await usersDB.count({ role: 'customer' });
    const totalBookings = await bookingsDB.count({});
    const totalServices = await servicesDB.count({});
    const completedBookings = await bookingsDB.find({ status: 'completed' });
    const revenueEst = completedBookings.length * 500;

    res.status(200).json({
      totalUsers,
      totalProviders,
      totalCustomers,
      totalBookings,
      totalServices,
      revenueEst,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.get('/analytics', async (req, res) => {
  const totalUsers = await usersDB.count({});
  const totalProviders = await usersDB.count({ role: 'provider' });
  const totalCustomers = await usersDB.count({ role: 'customer' });
  const totalServices = await servicesDB.count({});
  const totalBookings = await bookingsDB.count({});
  const verifiedProviders = await usersDB.count({ role: 'provider', is_verified: true });
  res.status(200).json({
    total_users: totalUsers,
    total_providers: totalProviders,
    total_customers: totalCustomers,
    total_services: totalServices,
    total_bookings: totalBookings,
    verified_providers: verifiedProviders,
  });
});

router.get('/users', async (req, res) => {
  try {
    const { role, page = 1, limit = 20, search } = req.query;
    const query = {};
    if (role && role !== 'All') {
      query.role = role.toLowerCase();
    }
    if (search) {
      query.$or = [
        { name: new RegExp(search, 'i') },
        { email: new RegExp(search, 'i') },
      ];
    }

    const skip = (parseInt(page, 10) - 1) * parseInt(limit, 10);
    const users = await usersDB.find(query).sort({ created_at: -1 }).skip(skip).limit(parseInt(limit, 10));
    const total = await usersDB.count(query);

    res.status(200).json({
      users: users.map((user) => ({
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        is_verified: !!user.is_verified,
        is_active: user.is_active !== false,
        created_at: user.created_at,
      })),
      total,
      page: parseInt(page, 10),
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.patch('/users/:id/role', async (req, res) => {
  try {
    const { role } = req.body;
    if (!['admin', 'provider', 'customer'].includes(role)) {
      return res.status(400).json({ message: 'Invalid role' });
    }
    await usersDB.update(
      { _id: req.params.id },
      { $set: { role, updated_at: new Date().toISOString() } }
    );
    await createAuditLog({
      adminId: req.user.id,
      action: 'UPDATE_ROLE',
      targetId: req.params.id,
      details: { role },
    });
    res.status(200).json({ message: 'Role updated' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.put('/users/:id/verify', async (req, res) => {
  try {
    const user = await usersDB.findOne({ _id: req.params.id });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    if (user.role !== 'provider') {
      return res.status(400).json({ message: 'Only providers can be verified' });
    }
    const verified = req.body.is_verified !== undefined ? !!req.body.is_verified : true;
    await usersDB.update(
      { _id: req.params.id },
      { $set: { is_verified: verified, updated_at: new Date().toISOString() } }
    );
    await createAuditLog({
      adminId: req.user.id,
      action: verified ? 'VERIFY_PROVIDER' : 'UNVERIFY_PROVIDER',
      targetId: req.params.id,
      details: { verified },
    });
    res.status(200).json({ message: `Provider ${verified ? 'verified' : 'unverified'}` });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.patch('/users/:id/ban', async (req, res) => {
  try {
    const user = await usersDB.findOne({ _id: req.params.id });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    if (user.role === 'admin') {
      return res.status(403).json({ message: 'Cannot ban another admin' });
    }

    const nextStatus = !(user.is_active !== false);
    await usersDB.update(
      { _id: req.params.id },
      { $set: { is_active: nextStatus, updated_at: new Date().toISOString() } }
    );
    await createAuditLog({
      adminId: req.user.id,
      action: nextStatus ? 'UNBAN_USER' : 'BAN_USER',
      targetId: req.params.id,
      details: { email: user.email },
    });

    res.status(200).json({ message: `User ${nextStatus ? 'unbanned' : 'banned'}`, is_active: nextStatus });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.delete('/users/:id', async (req, res) => {
  try {
    const user = await usersDB.findOne({ _id: req.params.id });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    if (user.role === 'admin') {
      return res.status(403).json({ message: 'Cannot delete admin users' });
    }
    await usersDB.remove({ _id: req.params.id });
    await createAuditLog({
      adminId: req.user.id,
      action: 'DELETE_USER',
      targetId: req.params.id,
      details: { name: user.name, email: user.email },
    });
    res.status(200).json({ message: 'User deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.get('/pending-providers', async (req, res) => {
  try {
    const providers = await usersDB.find({ role: 'provider', is_verified: false, is_active: true }).sort({ created_at: -1 });
    res.status(200).json(
      providers.map((provider) => ({
        id: provider._id,
        name: provider.name,
        email: provider.email,
        phone: provider.phone,
        created_at: provider.created_at,
        is_verified: !!provider.is_verified,
      }))
    );
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.get('/providers/pending', async (req, res) => {
  try {
    const providers = await usersDB.find({ role: 'provider', is_verified: false, is_active: true }).sort({ created_at: -1 });
    res.status(200).json(
      providers.map((provider) => ({
        id: provider._id,
        name: provider.name,
        email: provider.email,
        phone: provider.phone,
        created_at: provider.created_at,
        is_verified: !!provider.is_verified,
      }))
    );
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.get('/logs', async (req, res) => {
  try {
    const { action, page = 1, limit = 50 } = req.query;
    const query = {};
    if (action) {
      query.action = action;
    }
    const skip = (parseInt(page, 10) - 1) * parseInt(limit, 10);
    const logs = await auditLogsDB.find(query).sort({ timestamp: -1 }).skip(skip).limit(parseInt(limit, 10));
    const total = await auditLogsDB.count(query);
    res.status(200).json({ logs, total, page: parseInt(page, 10) });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.get('/services', async (req, res) => {
  try {
    const { search, category } = req.query;
    const query = {};
    if (category && category !== 'All') {
      query.category = category;
    }
    if (search) {
      query.$or = [
        { title: new RegExp(search, 'i') },
        { provider: new RegExp(search, 'i') },
      ];
    }
    const services = await servicesDB.find(query).sort({ created_at: -1 });
    res.status(200).json(services.map(sanitizeService));
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.delete('/services/:id', async (req, res) => {
  try {
    const service = await servicesDB.findOne({ _id: req.params.id });
    if (!service) {
      return res.status(404).json({ message: 'Service not found' });
    }
    await servicesDB.remove({ _id: req.params.id });
    await createAuditLog({
      adminId: req.user.id,
      action: 'DELETE_SERVICE',
      targetId: req.params.id,
      details: { title: service.title },
    });
    res.status(200).json({ message: 'Service deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.get('/bookings', async (req, res) => {
  try {
    const { status } = req.query;
    const query = {};
    if (status && status !== 'All') {
      query.status = status;
    }
    const bookings = await bookingsDB.find(query).sort({ created_at: -1 });
    res.status(200).json(await Promise.all(bookings.map((booking) => sanitizeBooking(booking))));
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.patch('/bookings/:id/status', async (req, res) => {
  try {
    const { status } = req.body;
    const validStatuses = ['pending', 'confirmed', 'in_progress', 'completed', 'cancelled'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ message: 'Invalid status' });
    }
    await bookingsDB.update(
      { _id: req.params.id },
      { $set: { status, updated_at: new Date().toISOString() } }
    );
    const updated = await bookingsDB.findOne({ _id: req.params.id });
    await createAuditLog({
      adminId: req.user.id,
      action: 'UPDATE_BOOKING_STATUS',
      targetId: req.params.id,
      details: { status },
    });
    res.status(200).json(await sanitizeBooking(updated));
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
