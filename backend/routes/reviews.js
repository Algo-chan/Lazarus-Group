const express = require('express');
const Joi = require('joi');
const { reviewsDB, bookingsDB } = require('../database');
const { authenticate } = require('../middleware/auth');
const { allowRoles, ROLES } = require('../middleware/rbac');

const router = express.Router();

const reviewSchema = Joi.object({
  service_id: Joi.string().required(),
  provider_id: Joi.string().required(),
  rating: Joi.number().min(1).max(5).required(),
  comment: Joi.string().max(1000).optional(),
});

router.get('/service/:serviceId', async (req, res) => {
  try {
    const reviews = await reviewsDB.find({ service_id: req.params.serviceId });
    res.status(200).json(reviews);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.get('/provider/:providerId', async (req, res) => {
  try {
    const reviews = await reviewsDB.find({ provider_id: req.params.providerId });
    const avgResult = await reviewsDB.find({ provider_id: req.params.providerId });
    const avgRating = avgResult.length > 0
      ? avgResult.reduce((sum, r) => sum + r.rating, 0) / avgResult.length
      : 0;
    res.status(200).json({ reviews, avg_rating: Math.round(avgRating * 10) / 10, total: reviews.length });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.post('/', authenticate, allowRoles(ROLES.CUSTOMER), async (req, res) => {
  try {
    const { error, value } = reviewSchema.validate(req.body);
    if (error) return res.status(400).json({ message: error.details[0].message });

    const existing = await reviewsDB.findOne({ service_id: value.service_id, customer_id: req.user.id });
    if (existing) {
      return res.status(409).json({ message: 'You have already reviewed this service' });
    }

    const review = {
      ...value,
      customer_id: req.user.id,
      customer_name: req.user.name,
      created_at: new Date().toISOString(),
    };

    const saved = await reviewsDB.insert(review);
    res.status(201).json(saved);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.delete('/:id', authenticate, async (req, res) => {
  try {
    const review = await reviewsDB.findOne({ _id: req.params.id });
    if (!review) return res.status(404).json({ message: 'Review not found' });
    if (review.customer_id !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Unauthorized' });
    }
    await reviewsDB.remove({ _id: req.params.id });
    res.status(200).json({ message: 'Review deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
