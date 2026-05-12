require('dotenv').config();
const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const { seedServices } = require('./database');

const authRoutes = require('./routes/auth');
const adminRoutes = require('./routes/admin');
const serviceRoutes = require('./routes/services');
const bookingRoutes = require('./routes/bookings');
const reviewRoutes = require('./routes/reviews');

const app = express();
const PORT = process.env.PORT || 3000;

seedServices().catch(console.error);

app.use(morgan('dev'));
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));
app.use(express.json({ limit: '10mb' }));

app.use('/api/auth', authRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/services', serviceRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/reviews', reviewRoutes);

app.get('/api/health', (req, res) => {
  res.status(200).json({ status: 'OK', version: '2.0.0' });
});

app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ message: 'Internal server error' });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`RBAC Backend running on port ${PORT}`);
});
