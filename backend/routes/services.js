const express = require('express');
const Joi = require('joi');
const { servicesDB } = require('../database');
const { authenticate, optionalAuth } = require('../middleware/auth');
const { allowRoles, ROLES } = require('../middleware/rbac');

const router = express.Router();

const serviceSchema = Joi.object({
  title: Joi.string().min(3).max(200).required(),
  category: Joi.string().required(),
  description: Joi.string().min(10).max(2000).required(),
  price: Joi.string().required(),
  location: Joi.string().required(),
  image: Joi.string().optional(),
  contact_phone: Joi.string().optional(),
  contact_whatsapp: Joi.string().optional(),
});

router.get('/', optionalAuth, async (req, res) => {
  try {
    const { query, category, provider_id, location, page = 1, limit = 20 } = req.query;
    let filter = {};
    if (category && category !== 'All') filter.category = category;
    if (provider_id) filter.provider_id = provider_id;
    if (location) filter.location = new RegExp(location, 'i');
    if (query) {
      const searchRegex = new RegExp(query, 'i');
      filter.$or = [
        { title: searchRegex },
        { provider: searchRegex },
        { description: searchRegex },
      ];
    }
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const services = await servicesDB.find(filter).skip(skip).limit(parseInt(limit));
    const total = await servicesDB.count(filter);
    res.status(200).json({ services, total, page: parseInt(page) });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.get('/:id', optionalAuth, async (req, res) => {
  try {
    const service = await servicesDB.findOne({ _id: req.params.id });
    if (!service) return res.status(404).json({ message: 'Service not found' });
    res.status(200).json(service);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.post('/', authenticate, allowRoles(ROLES.PROVIDER), async (req, res) => {
  try {
    const { error, value } = serviceSchema.validate(req.body);
    if (error) return res.status(400).json({ message: error.details[0].message });

    const newService = {
      ...value,
      provider_id: req.user.id,
      provider: req.user.name,
      rating: 0,
      reviewsCount: 0,
      verified: req.user.is_verified,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    const saved = await servicesDB.insert(newService);
    res.status(201).json(saved);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.put('/:id', authenticate, allowRoles(ROLES.PROVIDER), async (req, res) => {
  try {
    const service = await servicesDB.findOne({ _id: req.params.id });
    if (!service) return res.status(404).json({ message: 'Service not found' });
    if (service.provider_id !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'You can only edit your own services' });
    }

    const { error, value } = serviceSchema.validate(req.body);
    if (error) return res.status(400).json({ message: error.details[0].message });

    const updates = { ...value, updated_at: new Date().toISOString() };
    await servicesDB.update({ _id: req.params.id }, { $set: updates });
    const updated = await servicesDB.findOne({ _id: req.params.id });
    res.status(200).json(updated);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.delete('/:id', authenticate, async (req, res) => {
  try {
    const service = await servicesDB.findOne({ _id: req.params.id });
    if (!service) return res.status(404).json({ message: 'Service not found' });
    if (service.provider_id !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Unauthorized' });
    }
    await servicesDB.remove({ _id: req.params.id });
    res.status(200).json({ message: 'Service deleted' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.get('/categories/list', async (req, res) => {
  try {
    const services = await servicesDB.find({});
    const categories = [...new Set(services.map(s => s.category))];
    res.status(200).json(categories);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
