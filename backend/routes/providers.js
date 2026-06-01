const express = require('express');
const { usersDB, servicesDB, reviewsDB } = require('../database');
const { sanitizeService, sanitizeUser } = require('../utils/appHelpers');

const router = express.Router();

router.get('/:id', async (req, res) => {
  try {
    const provider = await usersDB.findOne({ _id: req.params.id, role: 'provider' });
    if (!provider) {
      return res.status(404).json({ message: 'Provider not found' });
    }

    const services = await servicesDB.find({ provider_id: provider._id }).sort({ created_at: -1 });
    const reviews = await reviewsDB.find({ provider_id: provider._id });
    const avgRating = reviews.length
      ? reviews.reduce((sum, review) => sum + Number(review.rating || 0), 0) / reviews.length
      : 0;

    res.status(200).json({
      provider: sanitizeUser(provider),
      joinDate: provider.created_at,
      verified: !!provider.is_verified,
      avgRating: Number(avgRating.toFixed(2)),
      reviewCount: reviews.length,
      services: services.map(sanitizeService),
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
