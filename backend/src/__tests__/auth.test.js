const request = require('supertest');
const app = require('../server');
const { pool } = require('../config/database');

describe('Authentication Endpoints', () => {
  afterAll(async () => {
    await pool.end();
  });

  // Cleanup helper - delete test users after each test
  const cleanupUser = async (email) => {
    try {
      await pool.execute('DELETE FROM users WHERE email = ?', [email]);
    } catch (e) {
      // Ignore cleanup errors
    }
  };

  describe('POST /api/auth/register', () => {
    it('should register a new user with valid credentials', async () => {
      const uniqueEmail = `test${Date.now()}@example.com`;
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          email: uniqueEmail,
          password: 'Test123456'
        });
      
      expect(res.statusCode).toBe(201);
      expect(res.body).toHaveProperty('token');
      expect(res.body).toHaveProperty('user');
      expect(res.body.user.email).toBe(uniqueEmail);
      expect(res.body.user.isAnonymous).toBe(0);
      
      // Cleanup
      await cleanupUser(uniqueEmail);
    });

    it('should reject registration with weak password', async () => {
      const uniqueEmail = `weak${Date.now()}@example.com`;
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          email: uniqueEmail,
          password: 'weak'
        });
      
      expect(res.statusCode).toBe(400);
      expect(res.body).toHaveProperty('error');
      
      // Cleanup (in case validation passed)
      await cleanupUser(uniqueEmail);
    });

    it('should reject registration with invalid email', async () => {
      const uniqueEmail = `invalid${Date.now()}@example.com`;
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          email: 'invalid-email',
          password: 'Test123456'
        });
      
      expect(res.statusCode).toBe(400);
      expect(res.body).toHaveProperty('error');
      
      await cleanupUser(uniqueEmail);
    });

    it('should reject duplicate email registration', async () => {
      const email = `duplicate${Date.now()}@example.com`;
      
      // First registration
      await request(app)
        .post('/api/auth/register')
        .send({
          email: email,
          password: 'Test123456'
        });
      
      // Duplicate registration
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          email: email,
          password: 'Test123456'
        });
      
      expect(res.statusCode).toBe(409);
      expect(res.body).toHaveProperty('error');
      
      // Cleanup
      await cleanupUser(email);
    });
  });

  describe('POST /api/auth/login', () => {
    const testEmail = `login${Date.now()}@example.com`;
    const testPassword = 'Test123456';

    beforeAll(async () => {
      // Create test user
      await request(app)
        .post('/api/auth/register')
        .send({
          email: testEmail,
          password: testPassword
        });
    });

    afterAll(async () => {
      // Cleanup test user
      await cleanupUser(testEmail);
    });

    it('should login with valid credentials', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({
          email: testEmail,
          password: testPassword
        });
      
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('token');
      expect(res.body).toHaveProperty('user');
      expect(res.body.user.email).toBe(testEmail);
    });

    it('should reject login with wrong password', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({
          email: testEmail,
          password: 'WrongPassword123'
        });
      
      expect(res.statusCode).toBe(401);
      expect(res.body).toHaveProperty('error');
    });

    it('should reject login with non-existent email', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'nonexistent@example.com',
          password: 'Test123456'
        });
      
      expect(res.statusCode).toBe(401);
      expect(res.body).toHaveProperty('error');
    });

    it('should reject login with missing credentials', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({});
      
      expect(res.statusCode).toBe(400);
      expect(res.body).toHaveProperty('error');
    });
  });

  describe('POST /api/auth/anonymous', () => {
    it('should create anonymous user successfully', async () => {
      const res = await request(app)
        .post('/api/auth/anonymous');
      
      expect(res.statusCode).toBe(201);
      expect(res.body).toHaveProperty('token');
      expect(res.body).toHaveProperty('user');
      expect(res.body.user.isAnonymous).toBe(1);
      expect(res.body.user.email).toMatch(/^anonymous_\d+@motorbike-parking\.app$/);
      
      // Cleanup
      await cleanupUser(res.body.user.email);
    });

    it('should create unique anonymous users', async () => {
      const res1 = await request(app).post('/api/auth/anonymous');
      const res2 = await request(app).post('/api/auth/anonymous');
      
      expect(res1.body.user.id).not.toBe(res2.body.user.id);
      expect(res1.body.user.email).not.toBe(res2.body.user.email);
      
      // Cleanup
      await cleanupUser(res1.body.user.email);
      await cleanupUser(res2.body.user.email);
    });
  });

  describe('GET /api/auth/me', () => {
    let authToken;
    let authEmail;

    beforeAll(async () => {
      const res = await request(app).post('/api/auth/anonymous');
      authToken = res.body.token;
      authEmail = res.body.user.email;
    });

    afterAll(async () => {
      await cleanupUser(authEmail);
    });

    it('should return user info with valid token', async () => {
      const res = await request(app)
        .get('/api/auth/me')
        .set('Authorization', `Bearer ${authToken}`);
      
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('user');
    });

    it('should reject request without token', async () => {
      const res = await request(app)
        .get('/api/auth/me');
      
      expect(res.statusCode).toBe(401);
    });

    it('should reject request with invalid token', async () => {
      const res = await request(app)
        .get('/api/auth/me')
        .set('Authorization', 'Bearer invalid_token');
      
      expect(res.statusCode).toBe(401);
    });
  });
});
