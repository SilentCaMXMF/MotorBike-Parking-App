const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const path = require('path');
const fs = require('fs');
require('dotenv').config();

const { testConnection } = require('./config/database');
const { errorHandler, notFound } = require('./middleware/errorHandler');

// Import routes
const authRoutes = require('./routes/auth');
const parkingRoutes = require('./routes/parking');
const reportRoutes = require('./routes/reports');

const app = express();

// Trust proxy for rate limiting behind reverse proxy
app.set('trust proxy', 1);

const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());

// CORS - restricted to allowed origins (updated: 2026-03-01)
// Allow origins from env var or use defaults
const getAllowedOrigins = () => {
  const envOrigins = process.env.CORS_ORIGIN?.split(',').filter(o => o.trim()) || [];
  return envOrigins.length > 0 ? envOrigins : [
    'http://localhost:3000',
    'http://localhost:8080', 
    'http://localhost:4200',
  ];
};

app.use(cors({
  origin: (origin, callback) => {
    const allowedOrigins = getAllowedOrigins();
    
    // Allow requests with no origin (mobile apps, curl, Postman)
    if (!origin) {
      return callback(null, true);
    }
    
    // Check if origin is allowed
    if (allowedOrigins.includes(origin)) {
      return callback(null, true);
    }
    
    // Block the request
    callback(new Error('CORS not allowed for this origin'));
  },
  credentials: true,
  optionsSuccessStatus: 200
}));

// General rate limiting (disabled in test mode)
const isTest = process.env.NODE_ENV === 'test';
const generalLimiter = isTest ? (req, res, next) => next() : rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
  message: { error: 'Too many requests from this IP, please try again later.' },
  standardHeaders: true,
  legacyHeaders: false,
});
app.use('/api/', generalLimiter);

// Strict rate limiting for auth endpoints (prevent brute force) - disabled in test mode
const authLimiter = isTest ? (req, res, next) => next() : rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // 5 attempts per IP
  message: { error: 'Too many login attempts. Please try again in 15 minutes.' },
  standardHeaders: true,
  legacyHeaders: false,
});

// Apply stricter limiting to auth routes
app.use('/api/auth/login', authLimiter);
app.use('/api/auth/register', authLimiter);

// Body parsing middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Compression
app.use(compression());

// Logging
if (process.env.NODE_ENV === 'development') {
  app.use(morgan('dev'));
} else {
  app.use(morgan('combined'));
}

// Create uploads directory if it doesn't exist
const uploadsDir = process.env.UPLOAD_DIR || './uploads';
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
  console.log(`✓ Created uploads directory: ${uploadsDir}`);
}

// Serve uploaded images as static files
app.use('/uploads', express.static(uploadsDir));

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV
  });
});

// API routes
app.use('/api/auth', authRoutes);
app.use('/api/parking', parkingRoutes);
app.use('/api/reports', reportRoutes);

// Root route
app.get('/', (req, res) => {
  res.json({
    message: 'Motorbike Parking API',
    version: process.env.API_VERSION || 'v1',
    endpoints: {
      health: '/health',
      auth: '/api/auth',
      parking: '/api/parking',
      reports: '/api/reports'
    }
  });
});

// Error handling
app.use(notFound);
app.use(errorHandler);

// Start server (skip in test mode)
const startServer = async () => {
  if (process.env.NODE_ENV === 'test') {
    console.log('Running in test mode - skipping server start');
    return;
  }
  
  try {
    // Test database connection
    const dbConnected = await testConnection();
    
    if (!dbConnected) {
      console.error('Failed to connect to database. Exiting...');
      process.exit(1);
    }

    app.listen(PORT, '0.0.0.0', () => {
      console.log(`
╔═══════════════════════════════════════════════════╗
║   Motorbike Parking API Server                    ║
╠═══════════════════════════════════════════════════╣
║   Environment: ${process.env.NODE_ENV?.padEnd(30)}║
║   Port: ${PORT.toString().padEnd(38)}║
║   Database: ${process.env.DB_HOST?.padEnd(34)}║
╚═══════════════════════════════════════════════════╝
      `);
      console.log(`Server running at http://0.0.0.0:${PORT}`);
      console.log(`API Documentation: http://localhost:${PORT}/`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
};

// Handle unhandled promise rejections
process.on('unhandledRejection', (err) => {
  console.error('Unhandled Promise Rejection:', err);
  process.exit(1);
});

startServer();

module.exports = app;
