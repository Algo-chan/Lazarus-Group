const jwt = require('jsonwebtoken');
const { usersDB } = require('../database');

const JWT_SECRET = process.env.JWT_SECRET || 'your_secret_key_here';

const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ message: 'No token provided' });
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, JWT_SECRET);
    
    const user = await usersDB.findOne({ _id: decoded.userId });
    if (!user) {
      return res.status(401).json({ message: 'User not found' });
    }

    req.user = {
      id: user._id,
      name: user.name,
      email: user.email,
      role: user.role,
      is_verified: user.is_verified || false,
      profile_image: user.profile_image || null,
      phone: user.phone || null,
    };

    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ message: 'Token expired', code: 'TOKEN_EXPIRED' });
    }
    return res.status(401).json({ message: 'Invalid token' });
  }
};

const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.split(' ')[1];
      const decoded = jwt.verify(token, JWT_SECRET);
      const user = await usersDB.findOne({ _id: decoded.userId });
      if (user) {
        req.user = {
          id: user._id,
          name: user.name,
          email: user.email,
          role: user.role,
          is_verified: user.is_verified || false,
        };
      }
    }
  } catch (_) {}
  next();
};

const generateToken = (userId, expiresIn = '7d') => {
  return jwt.sign({ userId }, JWT_SECRET, { expiresIn });
};

const generateRefreshToken = (userId) => {
  return jwt.sign({ userId, type: 'refresh' }, JWT_SECRET, { expiresIn: '30d' });
};

module.exports = { authenticate, optionalAuth, generateToken, generateRefreshToken };
