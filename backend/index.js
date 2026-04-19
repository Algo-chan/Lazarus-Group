require('dotenv').config();
const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const cors = require('cors');
const morgan = require('morgan');
const { usersDB, servicesDB, seedServices } = require('./database');

const app = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'your_secret_key_here';

// Initialize Database Seeding
seedServices().catch(console.error);

// Middleware
app.use(morgan('dev'));
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json());

// --- Authentication ---

// Sign Up
app.post('/api/auth/signup', async (req, res) => {
  try {
    const { name, email, password } = req.body;
    if (!name || !email || !password) {
      return res.status(400).json({ message: 'Missing fields' });
    }

    const existingUser = await usersDB.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ message: 'User already exists' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const newUser = {
      name,
      email,
      password: hashedPassword,
      createdAt: new Date().toISOString()
    };

    const savedUser = await usersDB.insert(newUser);
    const token = jwt.sign({ userId: savedUser._id }, JWT_SECRET, { expiresIn: '1h' });
    
    res.status(201).json({ token, user: { id: savedUser._id, name, email } });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Login
app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ message: 'Missing fields' });
    }

    const user = await usersDB.findOne({ email });
    if (!user) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    const token = jwt.sign({ userId: user._id }, JWT_SECRET, { expiresIn: '1h' });
    res.status(200).json({ token, user: { id: user._id, name: user.name, email } });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// --- Services API ---

// Get All Services or Search
app.get('/api/services', async (req, res) => {
  try {
    const { query, category } = req.query;
    let filter = {};

    if (category && category !== 'All') {
      filter.category = category;
    }

    if (query) {
      // Basic regex search for title or provider
      const searchRegex = new RegExp(query, 'i');
      filter.$or = [
        { title: searchRegex },
        { provider: searchRegex },
        { description: searchRegex }
      ];
    }

    const services = await servicesDB.find(filter);
    res.status(200).json(services);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Get Categories
app.get('/api/categories', async (req, res) => {
  try {
    const services = await servicesDB.find({});
    const categories = ['All', ...new Set(services.map(s => s.category))];
    res.status(200).json(categories);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Health check
app.get('/api/health', (req, res) => {
  res.status(200).json({ status: 'OK' });
});

// Start Server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Professional Backend running on port ${PORT}`);
});
