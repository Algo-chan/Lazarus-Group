const express = require('express');
const Joi = require('joi');
const { bookingsDB, servicesDB, usersDB } = require('../database');
const { authenticate } = require('../middleware/auth');
const { allowRoles, ROLES } = require('../middleware/rbac');
const {
  nowIso,
  sanitizeBooking,
  emitNotification,
} = require('../utils/appHelpers');

const router = express.Router();

const bookingSchema = Joi.object({
  serviceId: Joi.string().required(),
  date: Joi.string().required(),
  timeSlot: Joi.string().valid('Morning', 'Afternoon', 'Evening').required(),
  notes: Joi.string().allow('').max(1000).optional(),
});

const statusSchema = Joi.object({
  status: Joi.string().valid('pending', 'confirmed', 'in_progress', 'completed', 'cancelled').optional(),
  action: Joi.string().valid('confirm', 'start', 'complete', 'cancel').optional(),
}).xor('status', 'action');

const resolveStatus = (body) => {
  if (body.status) return body.status;
  switch (body.action) {
    case 'confirm':
      return 'confirmed';
    case 'start':
      return 'in_progress';
    case 'complete':
      return 'completed';
    case 'cancel':
      return 'cancelled';
    default:
      return null;
  }
};

router.use(authenticate);

router.get('/', allowRoles(ROLES.ADMIN), async (req, res) => {
  try {
    const bookings = await bookingsDB.find({}).sort({ created_at: -1 });
    const sanitized = await Promise.all(bookings.map((booking) => sanitizeBooking(booking)));
    res.status(200).json(sanitized);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.post('/', allowRoles(ROLES.CUSTOMER), async (req, res) => {
  try {
    const { error, value } = bookingSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ message: error.details[0].message });
    }

    const service = await servicesDB.findOne({ _id: value.serviceId });
    if (!service) {
      return res.status(404).json({ message: 'Service not found' });
    }

    const providerId = service.provider_id;
    const provider = providerId ? await usersDB.findOne({ _id: providerId }) : null;
    const booking = await bookingsDB.insert({
      service_id: service._id,
      service_title: service.title,
      provider_id: providerId ?? null,
      provider_name: provider?.name ?? service.provider ?? '',
      customer_id: req.user.id,
      customer_name: req.user.name,
      date: value.date,
      timeSlot: value.timeSlot,
      notes: value.notes ?? '',
      description: value.notes ?? '',
      status: 'pending',
      created_at: nowIso(),
      updated_at: nowIso(),
    });

    const io = req.app.get('io');
    if (providerId && io) {
      io.to(`user_${providerId}`).emit('new_booking', booking);
      await emitNotification(io, {
        userId: providerId,
        type: 'new_booking',
        message: `New booking request for ${service.title}`,
        relatedId: booking._id,
      });
    }

    const sanitized = await sanitizeBooking(booking);
    res.status(201).json(sanitized);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.get('/my', async (req, res) => {
  try {
    const query =
      req.user.role === 'provider'
        ? { provider_id: req.user.id }
        : req.user.role === 'customer'
          ? { customer_id: req.user.id }
          : {};

    const bookings = await bookingsDB.find(query).sort({ created_at: -1 });
    const sanitized = await Promise.all(bookings.map((booking) => sanitizeBooking(booking)));
    res.status(200).json(sanitized);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.get('/provider', allowRoles(ROLES.PROVIDER), async (req, res) => {
  try {
    const bookings = await bookingsDB.find({ provider_id: req.user.id }).sort({ created_at: -1 });
    const sanitized = await Promise.all(bookings.map((booking) => sanitizeBooking(booking)));
    res.status(200).json(sanitized);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.patch('/:id/status', async (req, res) => {
  try {
    const { error, value } = statusSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ message: error.details[0].message });
    }

    const booking = await bookingsDB.findOne({ _id: req.params.id });
    if (!booking) {
      return res.status(404).json({ message: 'Booking not found' });
    }

    const nextStatus = resolveStatus(value);
    if (!nextStatus) {
      return res.status(400).json({ message: 'Invalid status transition' });
    }

    const isOwnerCustomer = booking.customer_id === req.user.id;
    const isOwnerProvider = booking.provider_id === req.user.id;
    const isAdmin = req.user.role === 'admin';

    if (!isAdmin && !isOwnerCustomer && !isOwnerProvider) {
      return res.status(403).json({ message: 'Access denied' });
    }

    if (req.user.role === 'customer') {
      if (nextStatus !== 'cancelled') {
        return res.status(403).json({ message: 'Customers can only cancel bookings' });
      }
      if (booking.status !== 'pending') {
        return res.status(400).json({ message: 'Only pending bookings can be cancelled' });
      }
    }

    if (req.user.role === 'provider' && !isOwnerProvider && !isAdmin) {
      return res.status(403).json({ message: 'Access denied' });
    }

    const allowedByProvider = ['confirmed', 'in_progress', 'completed'];
    if (req.user.role === 'provider' && !allowedByProvider.includes(nextStatus) && !isAdmin) {
      return res.status(403).json({ message: 'Providers cannot set that status' });
    }

    await bookingsDB.update(
      { _id: booking._id },
      { $set: { status: nextStatus, updated_at: nowIso() } }
    );
    const updated = await bookingsDB.findOne({ _id: booking._id });
    const io = req.app.get('io');
    const recipientId = req.user.role === 'customer' ? booking.provider_id : booking.customer_id;
    if (recipientId && io) {
      io.to(`user_${recipientId}`).emit('booking_status', {
        bookingId: booking._id,
        status: nextStatus,
      });
      await emitNotification(io, {
        userId: recipientId,
        type: 'booking_status_change',
        message: `Booking status updated to ${nextStatus.replace('_', ' ')}`,
        relatedId: booking._id,
      });
    }

    res.status(200).json(await sanitizeBooking(updated));
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.delete('/:id', allowRoles(ROLES.CUSTOMER), async (req, res) => {
  try {
    const booking = await bookingsDB.findOne({ _id: req.params.id });
    if (!booking) {
      return res.status(404).json({ message: 'Booking not found' });
    }
    if (booking.customer_id !== req.user.id) {
      return res.status(403).json({ message: 'Access denied' });
    }
    if (booking.status !== 'pending') {
      return res.status(400).json({ message: 'Only pending bookings can be cancelled' });
    }

    await bookingsDB.update(
      { _id: booking._id },
      { $set: { status: 'cancelled', updated_at: nowIso() } }
    );

    const io = req.app.get('io');
    if (booking.provider_id && io) {
      io.to(`user_${booking.provider_id}`).emit('booking_status', {
        bookingId: booking._id,
        status: 'cancelled',
      });
      await emitNotification(io, {
        userId: booking.provider_id,
        type: 'booking_status_change',
        message: `Booking cancelled by customer`,
        relatedId: booking._id,
      });
    }

    res.status(200).json({ message: 'Booking cancelled' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const booking = await bookingsDB.findOne({ _id: req.params.id });
    if (!booking) {
      return res.status(404).json({ message: 'Booking not found' });
    }
    if (
      booking.customer_id !== req.user.id &&
      booking.provider_id !== req.user.id &&
      req.user.role !== 'admin'
    ) {
      return res.status(403).json({ message: 'Access denied' });
    }

    res.status(200).json(await sanitizeBooking(booking));
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
