const express = require('express');
const bcrypt = require('bcryptjs');
const Joi = require('joi');
const { usersDB, servicesDB, bookingsDB, reviewsDB } = require('../database');
const { authenticate } = require('../middleware/auth');
const { allowRoles, ROLES } = require('../middleware/rbac');

const router = express.Router();

router.use(authenticate);
router.use(allowRoles(ROLES.ADMIN));

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
    res.status(200).json({ message: 'User deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
