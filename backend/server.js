require('dotenv').config();
const http = require('http');
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');

const { seedDemoUsers, seedServices, usersDB, chatsDB } = require('./database');
const { authenticate } = require('./middleware/auth');

const authRoutes = require('./routes/auth');
const adminRoutes = require('./routes/admin');
const serviceRoutes = require('./routes/services');
const bookingRoutes = require('./routes/bookings');
const reviewRoutes = require('./routes/reviews');
const chatRoutes = require('./routes/chats');
const notificationRoutes = require('./routes/notifications');
const providerRoutes = require('./routes/providers');
const userRoutes = require('./routes/users');

const app = express();
const server = http.createServer(app);
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'your_secret_key_here';
const allowedOrigins = (process.env.CORS_ORIGIN || process.env.FLUTTER_WEB_ORIGIN || '*')
  .split(',')
  .map((origin) => origin.trim())
  .filter(Boolean);

const io = new Server(server, {
  cors: {
    origin: allowedOrigins.includes('*') ? true : allowedOrigins,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: true,
  },
});

app.set('io', io);
app.set('trust proxy', 1);

seedDemoUsers()
  .then(() => seedServices())
  .catch((error) => console.error('Failed to seed demo data', error));

app.use(helmet({ crossOriginResourcePolicy: false }));
app.use(morgan('dev'));
app.use(rateLimit({
  windowMs: 10 * 60 * 1000,
  limit: 100,
  standardHeaders: true,
  legacyHeaders: false,
}));
app.use(cors({
  origin(origin, callback) {
    if (!origin || allowedOrigins.includes('*') || allowedOrigins.includes(origin)) {
      return callback(null, true);
    }
    return callback(new Error('CORS blocked'));
  },
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
}));
app.use((req, res, next) => {
  res.setHeader('Access-Control-Expose-Headers', 'Authorization');
  next();
});
app.use(express.json({ limit: '10mb' }));

app.use('/api/auth', authRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/services', serviceRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/reviews', reviewRoutes);
app.use('/api/chats', chatRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/providers', providerRoutes);
app.use('/api/users', userRoutes);

app.get('/api/health', (req, res) => {
  res.status(200).json({ status: 'OK', version: '3.0.0' });
});

app.use('/api', (req, res) => {
  res.status(404).json({ message: `Route not found: ${req.method} ${req.originalUrl}` });
});

app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ message: 'Internal server error' });
});

io.use(async (socket, next) => {
  try {
    const token =
      socket.handshake.auth?.token ||
      (socket.handshake.headers.authorization || '').replace(/^Bearer\s+/i, '');
    if (!token) {
      return next(new Error('Unauthorized'));
    }

    const decoded = jwt.verify(token, JWT_SECRET);
    const user = await usersDB.findOne({ _id: decoded.userId });
    if (!user) {
      return next(new Error('Unauthorized'));
    }

    socket.user = {
      id: user._id,
      name: user.name,
      role: user.role,
    };
    return next();
  } catch (error) {
    return next(new Error('Unauthorized'));
  }
});

io.on('connection', async (socket) => {
  const userRoom = `user_${socket.user.id}`;
  socket.join(userRoom);

  try {
    const chats = await chatsDB.find({
      $or: [{ customer_id: socket.user.id }, { provider_id: socket.user.id }],
    });
    chats.forEach((chat) => socket.join(chat._id));
  } catch (error) {
    console.error('Failed to join user chats', error);
  }

  socket.on('join_chat', async (chatId) => {
    const chat = await chatsDB.findOne({ _id: chatId });
    if (chat && (chat.customer_id === socket.user.id || chat.provider_id === socket.user.id)) {
      socket.join(chatId);
    }
  });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`LocalConnect backend running on port ${PORT}`);
});

module.exports = { app, server, io };
