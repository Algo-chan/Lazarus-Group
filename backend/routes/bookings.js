const express = require('express');
const Joi = require('joi');
const { bookingsDB, servicesDB } = require('../database');
const { authenticate } = require('../middleware/auth');
const { allowRoles, ROLES } = require('../middleware/rbac');

const router = express.Router();

const bookingSchema = Joi.object({
  service_id: Joi.string().required(),
  provider_id: Joi.string().required(),
  description: Joi.string().max(1000).optional(),
  scheduled_date: Joi.string().isoDate().optional(),
  address: Joi.string().max(500).optional(),
});

router.use(authenticate);

router.post('/', allowRoles(ROLES.CUSTOMER), async (req, res) => {
  try {
    const { error, value } = bookingSchema.validate(req.body);
    if (error) return res.status(400).json({ message: error.details[0].message });

    const service = await servicesDB.findOne({ _id: value.service_id });
    if (!service) return res.status(404).json({ message: 'Service not found' });

    const booking = {
      ...value,
      customer_id: req.user.id,
      customer_name: req.user.name,
      status: 'pending',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    const saved = await bookingsDB.insert(booking);
    res.status(201).json(saved);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.get('/my', async (req, res) => {
  try {
    let query = {};
    if (req.user.role === 'customer') {
      query.customer_id = req.user.id;
    } else if (req.user.role === 'provider') {
      query.provider_id = req.user.id;
    } else if (req.user.role === 'admin') {
    }
    const bookings = await bookingsDB.find(query);
    res.status(200).json(bookings);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.put('/:id/status', async (req, res) => {
  try {
    const { status } = req.body;
    const validStatuses = ['pending', 'confirmed', 'in_progress', 'completed', 'cancelled'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ message: 'Invalid status' });
    }

    const booking = await bookingsDB.findOne({ _id: req.params.id });
    if (!booking) return res.status(404).json({ message: 'Booking not found' });

    if (req.user.role === 'customer' && status !== 'cancelled') {
      return res.status(403).json({ message: 'Customers can only cancel bookings' });
    }
    if (req.user.role === 'customer' && booking.customer_id !== req.user.id) {
      return res.status(403).json({ message: 'Not your booking' });
    }
    if (req.user.role === 'provider' && booking.provider_id !== req.user.id) {
      return res.status(403).json({ message: 'Not your booking' });
    }

    await bookingsDB.update({ _id: req.params.id }, { $set: { status, updated_at: new Date().toISOString() } });
    const updated = await bookingsDB.findOne({ _id: req.params.id });
    res.status(200).json(updated);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const booking = await bookingsDB.findOne({ _id: req.params.id });
    if (!booking) return res.status(404).json({ message: 'Booking not found' });
    if (booking.customer_id !== req.user.id && booking.provider_id !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Access denied' });
    }
    res.status(200).json(booking);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
