const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { pool } = require('../config/database');
const { v4: uuidv4 } = require('uuid');

/**
 * Generate JWT token
 */
const generateToken = (user) => {
  return jwt.sign(
    { 
      id: user.id, 
      email: user.email,
      isAnonymous: user.is_anonymous,
      isAdmin: user.is_admin || false
    },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN }
  );
};

/**
 * Register new user
 */
const register = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    // Hash password
    const passwordHash = await bcrypt.hash(password, 10);

    // Insert user
    const [result] = await pool.execute(
      'INSERT INTO users (id, email, password_hash, is_anonymous) VALUES (UUID(), ?, ?, FALSE)',
      [email, passwordHash]
    );

    // Get created user
    const [users] = await pool.execute(
      'SELECT id, email, is_anonymous, created_at FROM users WHERE email = ?',
      [email]
    );

    const user = users[0];
    const token = generateToken(user);

    res.status(201).json({
      message: 'User registered successfully',
      user: {
        id: user.id,
        email: user.email,
        isAnonymous: user.is_anonymous,
        createdAt: user.created_at
      },
      token
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Login user
 */
const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    // Get user
    const [users] = await pool.execute(
      'SELECT id, email, password_hash, is_anonymous, is_admin, is_active FROM users WHERE email = ?',
      [email]
    );

    if (users.length === 0) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const user = users[0];

    // Check if account is active
    if (!user.is_active) {
      return res.status(403).json({ error: 'Account is disabled' });
    }

    // Verify password
    const validPassword = await bcrypt.compare(password, user.password_hash);
    if (!validPassword) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const token = generateToken(user);

    res.json({
      message: 'Login successful',
      user: {
        id: user.id,
        email: user.email,
        isAnonymous: user.is_anonymous,
        isAdmin: user.is_admin || false
      },
      token
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Anonymous login
 */
const loginAnonymous = async (req, res, next) => {
  try {
    // Create anonymous user
    const anonymousEmail = `anonymous_${Date.now()}@motorbike-parking.app`;
    
    const [result] = await pool.execute(
      'INSERT INTO users (id, email, password_hash, is_anonymous) VALUES (UUID(), ?, NULL, TRUE)',
      [anonymousEmail]
    );

    // Get created user
    const [users] = await pool.execute(
      'SELECT id, email, is_anonymous, created_at FROM users WHERE email = ?',
      [anonymousEmail]
    );

    const user = users[0];
    const token = generateToken(user);

    res.status(201).json({
      message: 'Anonymous user created',
      user: {
        id: user.id,
        email: user.email,
        isAnonymous: user.is_anonymous,
        createdAt: user.created_at
      },
      token
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get current user info
 */
const me = async (req, res, next) => {
  try {
    const [users] = await pool.execute(
      'SELECT id, email, is_anonymous, is_active, created_at FROM users WHERE id = ?',
      [req.user.id]
    );

    if (users.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({ user: users[0] });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  register,
  login,
  loginAnonymous,
  me
};
