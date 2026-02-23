require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const { createProxyMiddleware } = require('http-proxy-middleware');
const rateLimit = require('express-rate-limit');
const authMiddleware = require('./middleware/auth');

const app = express();
const PORT = process.env.PORT || 8080;

// Service URLs
const AUTH_SERVICE_URL = process.env.AUTH_SERVICE_URL || 'http://auth-service:8081';
const PRODUCTS_SERVICE_URL = process.env.PRODUCTS_SERVICE_URL || 'http://products-service:8082';
const ORDERS_SERVICE_URL = process.env.ORDERS_SERVICE_URL || 'http://orders-service:8083';

// Security middleware
app.use(helmet());
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  message: { error: 'Too many requests, please try again later.' },
  standardHeaders: true,
  legacyHeaders: false
});
app.use(limiter);

// Stricter rate limit for auth endpoints
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  message: { error: 'Too many authentication attempts, please try again later.' }
});

// Logging
app.use(morgan('combined'));

// Health check (before body parsing)
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', service: 'api-gateway', timestamp: new Date().toISOString() });
});

// ============================================
// PROXY ROUTES - MUST BE BEFORE BODY PARSING
// ============================================

// Auth routes (public) - proxy directly without body parsing
app.use('/api/auth', authLimiter, createProxyMiddleware({
  target: AUTH_SERVICE_URL,
  changeOrigin: true,
  pathRewrite: { '^/api/auth': '/auth' },
  onError: (err, req, res) => {
    console.error('Auth service error:', err);
    res.status(503).json({ error: 'Auth service unavailable' });
  }
}));

// Products routes (public for GET)
app.use('/api/products', createProxyMiddleware({
  target: PRODUCTS_SERVICE_URL,
  changeOrigin: true,
  pathRewrite: { '^/api/products': '/products' },
  onError: (err, req, res) => {
    console.error('Products service error:', err);
    res.status(503).json({ error: 'Products service unavailable' });
  }
}));

// Orders routes - need to check auth header manually for proxy
app.use('/api/orders', (req, res, next) => {
  // Check auth for orders
  const authHeader = req.headers.authorization;
  if (!authHeader) {
    return res.status(401).json({ error: 'No token provided' });
  }
  next();
}, createProxyMiddleware({
  target: ORDERS_SERVICE_URL,
  changeOrigin: true,
  pathRewrite: { '^/api/orders': '/orders' },
  onError: (err, req, res) => {
    console.error('Orders service error:', err);
    res.status(503).json({ error: 'Orders service unavailable' });
  }
}));

// ============================================
// BODY PARSING - AFTER PROXY ROUTES
// ============================================
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Not found' });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Gateway error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

app.listen(PORT, () => {
  console.log(`🚀 API Gateway running on port ${PORT}`);
  console.log(`   Auth Service: ${AUTH_SERVICE_URL}`);
  console.log(`   Products Service: ${PRODUCTS_SERVICE_URL}`);
  console.log(`   Orders Service: ${ORDERS_SERVICE_URL}`);
});

module.exports = app;
