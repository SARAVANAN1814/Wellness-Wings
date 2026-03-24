const express = require('express');
const cors = require('cors');
const elderlyRoutes = require('./routes/elderly');
const volunteerRoutes = require('./routes/volunteer');
const adminRoutes = require('./routes/admin');

const app = express();

app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

// Debug middleware to log requests
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
  next();
});

app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// Health check endpoint to test DB connection
const pool = require('./config/database');
app.get('/api/health', async (req, res) => {
  try {
    const result = await pool.query('SELECT NOW()');
    res.json({ success: true, db: 'connected', time: result.rows[0].now, env: process.env.DATABASE_URL ? 'cloud' : 'local' });
  } catch (e) {
    res.status(500).json({ success: false, db: 'disconnected', error: e.message });
  }
});

app.use('/api/elderly', elderlyRoutes);
app.use('/api/volunteer', volunteerRoutes);
app.use('/api/admin', adminRoutes);

app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found'
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
}); 
