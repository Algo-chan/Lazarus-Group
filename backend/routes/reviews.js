const express = require('express');
const Joi = require('joi');
const { reviewsDB, bookingsDB, servicesDB, usersDB } = require('../database');
const { authenticate } = require('../middleware/auth');
const { allowRoles, ROLES } = require('../middleware/rbac');
const {
  nowIso,
  sanitizeReview,
  recalculateServiceStats,
  emitNotification,
} = require('../utils/appHelpers');

const router = express.Router();

const reviewSchema = Joi.object({
  rating: Joi.number().min(1).max(5).required(),
  comment: Joi.string().allow('').max(1000).optional(),
});

router.get('/provider/:providerId', async (req, res) => {
  try {
    const reviews = await reviewsDB.find({ provider_id: req.params.providerId }).sort({ created_at: -1 });
    const avgRating = reviews.length
      ? reviews.reduce((sum, review) => sum + Number(review.rating || 0), 0) / reviews.length
      : 0;
    res.status(200).json({
      reviews: await Promise.all(reviews.map((review) => sanitizeReview(review))),
      avgRating: Number(avgRating.toFixed(2)),
      total: reviews.length,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.get('/:serviceId', async (req, res) => {
  try {
    const page = Math.max(parseInt(req.query.page || '1', 10), 1);
    const limit = Math.min(Math.max(parseInt(req.query.limit || '50', 10), 1), 50);
    const skip = (page - 1) * limit;
    const query = { service_id: req.params.serviceId };
    const total = await reviewsDB.count(query);
    const reviews = await reviewsDB.find(query).sort({ created_at: -1 }).skip(skip).limit(limit);

    res.status(200).json({
      reviews: await Promise.all(reviews.map((review) => sanitizeReview(review))),
      total,
      page,
      limit,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.post('/:serviceId', authenticate, allowRoles(ROLES.CUSTOMER), async (req, res) => {
  try {
    const { error, value } = reviewSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ message: error.details[0].message });
    }

    const service = await servicesDB.findOne({ _id: req.params.serviceId });
    if (!service) {
      return res.status(404).json({ message: 'Service not found' });
    }

    const completedBooking = await bookingsDB.findOne({
      service_id: service._id,
      customer_id: req.user.id,
      status: 'completed',
    });
    if (!completedBooking) {
      return res.status(403).json({ message: 'You can only review after a completed booking' });
    }

    const existingReview = await reviewsDB.findOne({
      service_id: service._id,
      customer_id: req.user.id,
    });
    if (existingReview) {
      return res.status(409).json({ message: 'You have already reviewed this service' });
    }

    const review = await reviewsDB.insert({
      service_id: service._id,
      provider_id: service.provider_id ?? null,
      customer_id: req.user.id,
      customer_name: req.user.name,
      rating: Number(value.rating),
      comment: value.comment ?? '',
      created_at: nowIso(),
    });

    const stats = await recalculateServiceStats(service._id);
    const io = req.app.get('io');
    if (service.provider_id && io) {
      io.to(`user_${service.provider_id}`).emit('new_review', await sanitizeReview(review));
      await emitNotification(io, {
        userId: service.provider_id,
        type: 'new_review',
        message: `You received a new review for ${service.title}`,
        relatedId: service._id,
      });
    }

    res.status(201).json({
      review: await sanitizeReview(review),
      avgRating: stats.avgRating,
      reviewCount: stats.reviewCount,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.delete('/:id', authenticate, async (req, res) => {
  try {
    const review = await reviewsDB.findOne({ _id: req.params.id });
    if (!review) {
      return res.status(404).json({ message: 'Review not found' });
    }
    if (review.customer_id !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Unauthorized' });
    }
    await reviewsDB.remove({ _id: req.params.id });
    if (review.service_id) {
      await recalculateServiceStats(review.service_id);
    }
    res.status(200).json({ message: 'Review deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
