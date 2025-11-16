const request = require('supertest');
const app = require('../server');
const { pool } = require('../config/database');

describe('Reports and Parking Endpoints', () => {
  let authToken;
  let testUserId;
  let testSpotId;

  beforeAll(async () => {
    // Create test user and get token
    const authRes = await request(app).post('/api/auth/anonymous');
    authToken = authRes.body.token;
    testUserId = authRes.body.user.id;

    // Get a real parking zone ID
    const parkingRes = await request(app)
      .get('/api/parking/nearby')
      .query({ lat: 38.7223, lng: -9.1393, radius: 5000, limit: 1 });
    
    if (parkingRes.body.zones && parkingRes.body.zones.length > 0) {
      testSpotId = parkingRes.body.zones[0].id;
    }
  });

  afterAll(async () => {
    await pool.end();
  });

  describe('POST /api/reports', () => {
    it('should create a new report with authentication', async () => {
      if (!testSpotId) {
        console.log('Skipping test: No parking zones available');
        return;
      }

      const res = await request(app)
        .post('/api/reports')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          spotId: testSpotId,
          reportedCount: 5,
          userLatitude: 38.7223,
          userLongitude: -9.1393
        });
      
      expect(res.statusCode).toBe(201);
      expect(res.body).toHaveProperty('message');
      expect(res.body).toHaveProperty('report');
      expect(res.body.report.spot_id).toBe(testSpotId);
    });

    it('should reject unauthenticated report creation', async () => {
      const res = await request(app)
        .post('/api/reports')
        .send({
          spotId: testSpotId,
          reportedCount: 5
        });
      
      expect(res.statusCode).toBe(401);
    });

    it('should reject report with invalid spotId', async () => {
      const res = await request(app)
        .post('/api/reports')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          spotId: 'invalid-uuid',
          reportedCount: 5
        });
      
      expect(res.statusCode).toBe(400);
    });

    it('should reject report with missing required fields', async () => {
      const res = await request(app)
        .post('/api/reports')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          spotId: testSpotId
          // Missing reportedCount
        });
      
      expect(res.statusCode).toBe(400);
    });
  });

  describe('GET /api/reports', () => {
    beforeAll(async () => {
      // Create a test report
      if (testSpotId) {
        await request(app)
          .post('/api/reports')
          .set('Authorization', `Bearer ${authToken}`)
          .send({
            spotId: testSpotId,
            reportedCount: 3,
            userLatitude: 38.7223,
            userLongitude: -9.1393
          });
      }
    });

    it('should get reports for a specific zone', async () => {
      if (!testSpotId) {
        console.log('Skipping test: No parking zones available');
        return;
      }

      const res = await request(app)
        .get('/api/reports')
        .query({ spotId: testSpotId });
      
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('reports');
      expect(res.body).toHaveProperty('count');
      expect(Array.isArray(res.body.reports)).toBe(true);
    });

    it('should reject request without spotId', async () => {
      const res = await request(app)
        .get('/api/reports');
      
      expect(res.statusCode).toBe(400);
      expect(res.body).toHaveProperty('error');
    });

    it('should filter reports by time window', async () => {
      if (!testSpotId) {
        console.log('Skipping test: No parking zones available');
        return;
      }

      const res = await request(app)
        .get('/api/reports')
        .query({ spotId: testSpotId, hours: 1 });
      
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('reports');
    });
  });

  describe('GET /api/reports/me', () => {
    it('should get current user report history', async () => {
      const res = await request(app)
        .get('/api/reports/me')
        .set('Authorization', `Bearer ${authToken}`);
      
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('reports');
      expect(res.body).toHaveProperty('count');
      expect(Array.isArray(res.body.reports)).toBe(true);
    });

    it('should reject unauthenticated request', async () => {
      const res = await request(app)
        .get('/api/reports/me');
      
      expect(res.statusCode).toBe(401);
    });

    it('should support pagination', async () => {
      const res = await request(app)
        .get('/api/reports/me')
        .set('Authorization', `Bearer ${authToken}`)
        .query({ limit: 10, offset: 0 });
      
      expect(res.statusCode).toBe(200);
      expect(res.body.reports.length).toBeLessThanOrEqual(10);
    });
  });

  describe('GET /api/parking/nearby', () => {
    it('should return nearby parking zones', async () => {
      const res = await request(app)
        .get('/api/parking/nearby')
        .query({
          lat: 38.7223,
          lng: -9.1393,
          radius: 1000
        });
      
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('zones');
      expect(res.body).toHaveProperty('count');
      expect(Array.isArray(res.body.zones)).toBe(true);
    });

    it('should reject request without coordinates', async () => {
      const res = await request(app)
        .get('/api/parking/nearby')
        .query({ radius: 1000 });
      
      expect(res.statusCode).toBe(400);
    });

    it('should limit results based on limit parameter', async () => {
      const res = await request(app)
        .get('/api/parking/nearby')
        .query({
          lat: 38.7223,
          lng: -9.1393,
          radius: 5000,
          limit: 5
        });
      
      expect(res.statusCode).toBe(200);
      expect(res.body.zones.length).toBeLessThanOrEqual(5);
    });

    it('should calculate distance for each zone', async () => {
      const res = await request(app)
        .get('/api/parking/nearby')
        .query({
          lat: 38.7223,
          lng: -9.1393,
          radius: 5000
        });
      
      expect(res.statusCode).toBe(200);
      if (res.body.zones.length > 0) {
        expect(res.body.zones[0]).toHaveProperty('distance_km');
      }
    });
  });

  describe('GET /api/parking/:id', () => {
    it('should get specific parking zone details', async () => {
      if (!testSpotId) {
        console.log('Skipping test: No parking zones available');
        return;
      }

      const res = await request(app)
        .get(`/api/parking/${testSpotId}`);
      
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('zone');
      expect(res.body.zone.id).toBe(testSpotId);
    });

    it('should return 404 for non-existent zone', async () => {
      const fakeId = '00000000-0000-0000-0000-000000000000';
      const res = await request(app)
        .get(`/api/parking/${fakeId}`);
      
      expect(res.statusCode).toBe(404);
    });
  });
});
