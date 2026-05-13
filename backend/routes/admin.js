const express = require('express');
const bcrypt = require('bcryptjs');
const Joi = require('joi');
const { usersDB, servicesDB, bookingsDB, reviewsDB, auditLogsDB } = require('../database');
const { authenticate } = require('../middleware/auth');
const { allowRoles, ROLES } = require('../middleware/rbac');

const router = express.Router();

router.use(authenticate);
router.use(allowRoles(ROLES.ADMIN));

const logAction = async (adminId, action, targetId, details) => {
  try {
    await auditLogsDB.insert({
      admin_id: adminId,
      action,
      target_id: targetId,
      details,
      timestamp: new Date().toISOString(),
    });
  } catch (err) {
    console.error('Failed to log action:', err);
  }
};

router.get('/logs', async (req, res) => {
  try {
    const logs = await auditLogsDB.find({}).sort({ timestamp: -1 }).limit(50);
    res.status(200).json(logs);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.get('/users', async (req, res) => {
  try {
    const { role, page = 1, limit = 20, search } = req.query;
    let query = {};
    if (role) query.role = role;
    if (search) {
      query.$or = [
        { name: new RegExp(search, 'i') },
        { email: new RegExp(search, 'i') },
      ];
    }
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const users = await usersDB.find(query).skip(skip).limit(parseInt(limit));
    const total = await usersDB.count(query);
    
    const sanitized = users.map(u => ({
      id: u._id,
      name: u.name,
      email: u.email,
      phone: u.phone,
      role: u.role,
      is_verified: u.is_verified,
      is_active: u.is_active,
      created_at: u.created_at,
    }));

    res.status(200).json({ users: sanitized, total, page: parseInt(page) });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.put('/users/:id/role', async (req, res) => {
  try {
    const { role } = req.body;
    if (!['admin', 'provider', 'customer'].includes(role)) {
      return res.status(400).json({ message: 'Invalid role' });
    }
    await usersDB.update({ _id: req.params.id }, { $set: { role, updated_at: new Date().toISOString() } });
    res.status(200).json({ message: 'Role updated' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.put('/users/:id/verify', async (req, res) => {
  try {
    const { is_verified } = req.body;
    await usersDB.update({ _id: req.params.id }, { $set: { is_verified: !!is_verified, updated_at: new Date().toISOString() } });
    await logAction(req.user.id, 'VERIFY_USER', req.params.id, { is_verified: !!is_verified });
    res.status(200).json({ message: 'Verification status updated' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.put('/users/:id/ban', async (req, res) => {
  try {
    const targetUser = await usersDB.findOne({ _id: req.params.id });
    if (!targetUser) return res.status(404).json({ message: 'User not found' });
    if (targetUser.role === 'admin') {
      return res.status(403).json({ message: 'Cannot ban another admin' });
    }
    const newStatus = targetUser.is_active === false ? true : false;
    await usersDB.update({ _id: req.params.id }, { $set: { is_active: newStatus, updated_at: new Date().toISOString() } });
    await logAction(req.user.id, newStatus ? 'UNBAN_USER' : 'BAN_USER', req.params.id, { email: targetUser.email });
    res.status(200).json({ message: `User ${newStatus ? 'unbanned' : 'banned'}`, is_active: newStatus });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.get('/providers/pending', async (req, res) => {
  try {
    const providers = await usersDB.find({ role: 'provider', is_verified: false, is_active: true });
    const sanitized = providers.map(u => ({
      id: u._id,
      name: u.name,
      email: u.email,
      phone: u.phone,
      created_at: u.created_at,
    }));
    res.status(200).json(sanitized);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.get('/analytics', async (req, res) => {
  try {
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
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.delete('/users/:id', async (req, res) => {
  try {
    const targetUser = await usersDB.findOne({ _id: req.params.id });
    if (!targetUser) return res.status(404).json({ message: 'User not found' });
    if (targetUser.role === 'admin') {
      return res.status(403).json({ message: 'Cannot delete admin users' });
    }
    await usersDB.remove({ _id: req.params.id });
    await logAction(req.user.id, 'DELETE_USER', req.params.id, { name: targetUser.name, email: targetUser.email });
    res.status(200).json({ message: 'User deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.get('/services', async (req, res) => {
  try {
    const { search, category } = req.query;
    let query = {};
    if (category) query.category = category;
    if (search) {
      query.$or = [
        { title: new RegExp(search, 'i') },
        { provider: new RegExp(search, 'i') },
      ];
    }
    const services = await servicesDB.find(query).sort({ created_at: -1 });
    res.status(200).json(services);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.get('/bookings', async (req, res) => {
  try {
    const { status } = req.query;
    let query = {};
    if (status) query.status = status;
    const bookings = await bookingsDB.find(query).sort({ created_at: -1 });
    res.status(200).json(bookings);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.put('/bookings/:id/status', async (req, res) => {
  try {
    const { status } = req.body;
    const validStatuses = ['pending', 'confirmed', 'in_progress', 'completed', 'cancelled'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ message: 'Invalid status' });
    }
    await bookingsDB.update({ _id: req.params.id }, { $set: { status, updated_at: new Date().toISOString() } });
    const updated = await bookingsDB.findOne({ _id: req.params.id });
    await logAction(req.user.id, 'UPDATE_BOOKING_STATUS', req.params.id, { status });
    res.status(200).json(updated);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.delete('/services/:id', async (req, res) => {
  try {
    const service = await servicesDB.findOne({ _id: req.params.id });
    if (!service) return res.status(404).json({ message: 'Service not found' });
    await servicesDB.remove({ _id: req.params.id });
    await logAction(req.user.id, 'DELETE_SERVICE', req.params.id, { title: service.title });
    res.status(200).json({ message: 'Service deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
