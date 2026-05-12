const express = require('express');
const bcrypt = require('bcryptjs');
const Joi = require('joi');
const { usersDB, bookingsDB, reviewsDB } = require('../database');
const { authenticate, generateToken, generateRefreshToken } = require('../middleware/auth');

const router = express.Router();

const signupSchema = Joi.object({
  name: Joi.string().min(2).max(100).required(),
  email: Joi.string().email().required(),
  phone: Joi.string().pattern(/^\+?[\d\s-]{7,15}$/).optional(),
  password: Joi.string().min(6).max(128).required(),
  role: Joi.string().valid('customer', 'provider').default('customer'),
});

const loginSchema = Joi.object({
  email: Joi.string().email().required(),
  password: Joi.string().required(),
});

router.post('/signup', async (req, res) => {
  try {
    const { error, value } = signupSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ message: error.details[0].message });
    }

    const { name, email, phone, password, role } = value;

    const existingUser = await usersDB.findOne({ email });
    if (existingUser) {
      return res.status(409).json({ message: 'Email already registered' });
    }

    const hashedPassword = await bcrypt.hash(password, 12);
    const newUser = {
      name,
      email,
      phone: phone || null,
      password_hash: hashedPassword,
      role,
      profile_image: null,
      is_verified: false,
      is_active: true,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    const savedUser = await usersDB.insert(newUser);
    const token = generateToken(savedUser._id);
    const refreshToken = generateRefreshToken(savedUser._id);

    res.status(201).json({
      token,
      refresh_token: refreshToken,
      user: {
        id: savedUser._id,
        name: savedUser.name,
        email: savedUser.email,
        phone: savedUser.phone,
        role: savedUser.role,
        profile_image: savedUser.profile_image,
        is_verified: savedUser.is_verified,
      },
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.post('/login', async (req, res) => {
  try {
    const { error, value } = loginSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ message: error.details[0].message });
    }

    const { email, password } = value;

    const user = await usersDB.findOne({ email });
    if (!user) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    if (!user.is_active) {
      return res.status(403).json({ message: 'Account has been deactivated' });
    }

    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    const token = generateToken(user._id);
    const refreshToken = generateRefreshToken(user._id);

    res.status(200).json({
      token,
      refresh_token: refreshToken,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        profile_image: user.profile_image,
        is_verified: user.is_verified,
      },
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.get('/me', authenticate, async (req, res) => {
  try {
    const user = await usersDB.findOne({ _id: req.user.id });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    let stats = {};
    if (user.role === 'provider') {
      const services = await (require('../database').servicesDB).find({ provider_id: user._id });
      const totalBookings = await bookingsDB.count({ provider_id: user._id });
      const avgRating = await reviewsDB.findOne({ provider_id: user._id });
      stats = {
        total_services: services.length,
        total_bookings: totalBookings,
        avg_rating: avgRating ? avgRating.rating : 0,
      };
    } else if (user.role === 'customer') {
      const totalBookings = await bookingsDB.count({ customer_id: user._id });
      stats = { total_bookings: totalBookings };
    }

    res.status(200).json({
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        profile_image: user.profile_image,
        is_verified: user.is_verified,
        created_at: user.created_at,
      },
      stats,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.put('/profile', authenticate, async (req, res) => {
  try {
    const { name, phone, profile_image } = req.body;
    const updates = { updated_at: new Date().toISOString() };
    if (name) updates.name = name;
    if (phone !== undefined) updates.phone = phone;
    if (profile_image !== undefined) updates.profile_image = profile_image;

    await usersDB.update({ _id: req.user.id }, { $set: updates });
    const updated = await usersDB.findOne({ _id: req.user.id });

    res.status(200).json({
      user: {
        id: updated._id,
        name: updated.name,
        email: updated.email,
        phone: updated.phone,
        role: updated.role,
        profile_image: updated.profile_image,
        is_verified: updated.is_verified,
      },
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
