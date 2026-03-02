# Motorbike Parking App - Backend SWOT Analysis

**Document Version:** 1.0  
**Date:** 2026-03-01  
**Scope:** Backend API (Node.js/Express) on Raspberry Pi 4  

---

## Executive Summary

This document provides a comprehensive SWOT (Strengths, Weaknesses, Opportunities, Threats) analysis of the Motorbike Parking App backend implementation. The backend is a Node.js/Express API running on a Raspberry Pi 4 (192.168.1.67) with MariaDB database.

**Infrastructure Status:**
- **Server:** Raspberry Pi 4 ("pivpn") @ 192.168.1.67:3000
- **Database:** MariaDB 10.11.14 @ 192.168.1.67:3306
- **Process Manager:** PM2 (motorbike-parking-api online, uptime: 2 days)
- **External Access:** Cloudflare Tunnel (trycloudflare.com)

---

## 1. Architecture Overview

### Technology Stack

| Component | Technology | Version |
|-----------|------------|---------|
| Runtime | Node.js | Latest (via nvm) |
| Framework | Express.js | ^4.x |
| Database | MariaDB | 10.11.14 |
| Authentication | JWT (jsonwebtoken) | - |
| Password Hashing | bcrypt | - |
| Validation | Joi | - |
| Security | Helmet, CORS, express-rate-limit | - |
| Process Manager | PM2 | - |

### Project Structure

```
~/motorbike_app/backend/src/
├── config/
│   └── database.js          # MariaDB connection pool
├── controllers/
│   ├── authController.js    # Login/register/logout
│   ├── parkingController.js # Zone CRUD
│   └── reportController.js # Report submission
├── middleware/
│   ├── auth.js             # JWT verification
│   ├── errorHandler.js     # Error handling
│   └── validation.js        # Joi schemas
├── routes/
│   ├── auth.js             # /api/auth/*
│   ├── parking.js          # /api/parking/*
│   └── reports.js          # /api/reports/*
└── server.js               # Express app entry
```

### API Endpoints

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | /api/auth/register | Public | Register new user |
| POST | /api/auth/login | Public | User login |
| POST | /api/auth/anonymous | Public | Guest login |
| GET | /api/auth/me | JWT | Get current user |
| POST | /api/auth/logout | JWT | Logout |
| GET | /api/parking/nearby | Public | Get nearby zones |
| GET | /api/parking/:id | Public | Get zone details |
| POST | /api/parking | Admin | Create zone |
| PUT | /api/parking/:id | Admin | Update zone |
| POST | /api/reports | JWT | Submit report |
| GET | /api/reports/zone/:spotId | JWT | Get zone reports |
| GET | /api/reports/my | JWT | User's reports |
| POST | /api/reports/:reportId/images | JWT | Upload image |

---

## 2. SWOT Analysis

### 2.1 STRENGTHS

#### Architecture & Code Quality
- **Clean MVC Architecture**: Well-organized folder structure with clear separation of concerns (controllers, routes, middleware)
- **Modular Design**: Each component is focused and reusable
- **Centralized Error Handling**: Dedicated errorHandler middleware with consistent error responses

#### Security Implementation
- **JWT Authentication**: Stateless token-based auth with 7-day expiry
- **Password Security**: bcrypt hashing with salt rounds (cost factor 10)
- **Role-Based Access Control**: Admin middleware (`requireAdmin`) protects admin endpoints
- **Input Validation**: Joi validation schemas on all user inputs
- **Security Headers**: Helmet middleware for HTTP security headers
- **Rate Limiting**: express-rate-limit configured (100 requests/15 min)

#### Database Design
- **Parameterized Queries**: No SQL injection vulnerabilities
- **Stored Procedures**: GetNearbyParkingZones, CreateUserReport for complex operations
- **Database Triggers**: Auto-update occupancy on report insert/delete
- **Proper Indexing**: Indexes on foreign keys and frequently queried columns
- **Foreign Key Constraints**: Data integrity enforced at DB level

#### Operations & DevOps
- **PM2 Process Management**: Auto-restart on failure, process monitoring
- **Health Check Endpoint**: `/health` returns server status
- **Cloudflare Tunnel**: External access without port forwarding
- **Backup Automation**: Daily database backups via backup_db.sh
- **Logging**: Morgan for HTTP request logging (dev: dev format, prod: combined)

#### Authentication Features
- **3 Login Types**: Email/password registration, login, and anonymous guest access
- **Token Payload**: Contains id, email, isAnonymous, isAdmin for authorization
- **Optional Auth Middleware**: Allows mixed public/protected endpoints

---

### 2.2 WEAKNESSES

#### Security Issues
- **Permissive CORS**: `origin: '*'` allows requests from any domain
  - Risk: Cross-site request forgery, data exposure
  - Fix: Restrict to known origins

- **No Token Revocation**: Logout is client-side only (JWT is stateless)
  - Risk: Stolen tokens remain valid until expiry
  - Fix: Implement token blacklist or refresh tokens

- **Exposed Secrets**: .env file contains plaintext credentials
  - Risk: Credential theft if server compromised
  - Current: JWT_SECRET, DB_PASSWORD, GOOGLE_MAPS_API_KEY in plain text

- **Weak JWT Secret**: `MotorbikeParking2025SecretKey!ChangeInProduction`
  - Risk: Predictable, should be randomly generated 256-bit key

- **No HTTPS**: Running on plain HTTP internally
  - Risk: Man-in-the-middle attacks on local network

- **No Auth Rate Limiting**: Login endpoint has no special rate limit
  - Risk: Brute force attacks on /api/auth/login

#### Code Quality
- **Debug Logs in Production**: console.log statements in parkingController.js
  ```javascript
  console.log('[DEBUG] Sending response with DATA key - VERSION 2');
  console.log('[DEBUG] Response structure:', { hasData: true, count: zones[0].length });
  ```

- **No Admin UI**: No frontend interface for admin tasks
  - Impact: Must use direct DB/API calls for zone/user management

- **Anonymous User Accumulation**: New row created on every guest login
  - Impact: Table grows indefinitely with no cleanup

- **No Pagination**: Report endpoints return all matching rows
  - Impact: Performance degradation with large datasets

#### Error Handling & Resilience
- **No Retry Logic**: Database connection failures crash server immediately
  - Fix: Implement connection retry with exponential backoff

- **Unhandled Promise Rejections**: Process exits on unhandled rejections
  ```javascript
  process.on('unhandledRejection', (err) => {
    console.error('Unhandled Promise Rejection:', err);
    process.exit(1);
  });
  ```

- **No Circuit Breaker**: No protection against cascade failures

#### Maintenance
- **Dependencies**: node_modules may have known vulnerabilities
- **No CI/CD**: Manual deployment process
- **Code Location**: Backend on Pi, not in main project repo

---

### 2.3 OPPORTUNITIES

#### Features to Implement
- **Admin Dashboard**: Web UI for managing parking zones and viewing reports
- **Token Refresh**: Implement refresh token rotation for better security
- **Social Login**: Google/Facebook OAuth integration
- **Push Notifications**: Alert users when parking becomes available
- **Analytics Dashboard**: Heat maps of parking demand, usage statistics

#### Infrastructure Improvements
- **HTTPS/TLS**: Add Nginx reverse proxy with SSL termination
- **Redis Cache**: For session storage and rate limiting
- **Monitoring**: Add Sentry, Datadog, or similar error tracking
- **Load Balancing**: For future scalability (if needed)

#### Data & Analytics
- **City API Integration**: Import parking data from municipal sources
- **Machine Learning**: Predict availability based on time/day patterns
- **Historical Analysis**: Trend reporting for urban planning

#### Security Hardening
- **Environment Variables**: Move secrets to secure environment management
- **API Keys Rotation**: Automate rotation of API keys
- **Audit Logging**: Log all admin actions

---

### 2.4 THREATS

#### Security Threats
- **Credential Exposure**: .env contains real secrets (Google API key, DB password)
- **Brute Force Attack**: Login endpoint vulnerable without rate limiting
- **SQL Injection Risk**: Dynamic query building in parkingController.updateZone()
  ```javascript
  // Potential SQL injection if not properly validated
  await pool.execute(
    `UPDATE parking_zones SET ${fields.join(', ')} WHERE id = ?`,
    values
  );
  ```
- **Unrestricted File Upload**: No file type validation on image uploads
- **CORS Exploitation**: Permissive CORS allows cross-site data theft

#### Infrastructure Threats
- **Single Point of Failure**: No redundancy if Pi fails
- **Unlimited Backups**: 20+ backup files accumulating (disk space)
- **Resource Constraints**: Limited CPU/memory on Raspberry Pi
- **No DDOS Protection**: Cloudflare tunnel provides basic protection only
- **Network Instability**: Home network dependencies

#### Maintenance Threats
- **Dependency Vulnerabilities**: Outdated packages may have CVEs
- **Knowledge Silo**: Only one person knows the system
- **No Disaster Recovery Plan**: Backup exists but no restore testing
- **Documentation Gaps**: AGENTS.md exists but may be outdated

---

## 3. Risk Assessment

| Risk | Severity | Likelihood | Mitigation |
|------|----------|------------|------------|
| Credential exposure | HIGH | MEDIUM | Move secrets to env manager, rotate keys |
| Brute force on login | HIGH | HIGH | Add rate limiting to auth endpoints |
| SQL injection | HIGH | LOW | Use parameterized queries only |
| Anonymous user bloat | MEDIUM | HIGH | Add cleanup job for old anonymous users |
| CORS exploitation | MEDIUM | MEDIUM | Restrict to known origins |
| Database connection failure | MEDIUM | LOW | Add retry logic, health checks |
| Backup disk full | LOW | MEDIUM | Implement backup rotation |

---

## 4. Recommendations

### Critical (Immediate Action)

1. **Restrict CORS**
   ```javascript
   // Change in server.js
   app.use(cors({
     origin: ['https://yourdomain.com', 'https://app.yourdomain.com'],
     credentials: true
   }));
   ```

2. **Add Rate Limiting to Auth**
   ```javascript
   const authLimiter = rateLimit({
     windowMs: 15 * 60 * 1000, // 15 minutes
     max: 5, // 5 attempts
     message: 'Too many login attempts'
   });
   app.use('/api/auth/login', authLimiter);
   ```

3. **Generate Strong JWT_SECRET**
   ```bash
   # Generate 256-bit secret
   node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
   ```

4. **Add Token Blacklist**
   - Implement Redis-based token blacklist
   - Or use short-lived access tokens with refresh tokens

### High Priority

5. **Implement File Type Validation**
   ```javascript
   const fileFilter = (req, file, cb) => {
     const allowedTypes = /jpeg|jpg|png/;
     const extname = allowedTypes.test(path.extname(file.originalname));
     if (extname) return cb(null, true);
     cb(new Error('Only images allowed'));
   };
   ```

6. **Add Pagination to Endpoints**
   - Add `limit` and `offset` parameters to report endpoints

7. **Clean Up Anonymous Users**
   - Schedule job to delete anonymous users inactive for 30+ days

### Medium Priority

8. **Remove Debug Logs**
9. **Set Up Monitoring** (Sentry)
10. **Create Admin UI**
11. **Implement Backup Rotation**

### Low Priority

12. **Add CI/CD Pipeline**
13. **Dependency Updates**
14. **Documentation Updates**

---

## 5. Current Configuration

### Environment Variables

| Variable | Current Value | Status |
|----------|---------------|--------|
| NODE_ENV | development | ⚠️ Should be production |
| PORT | 3000 | ✅ |
| DB_HOST | 192.168.1.67 | ✅ |
| DB_NAME | motorbike_parking_app | ✅ |
| DB_USER | motorbike_app | ✅ |
| JWT_SECRET | (hidden) | ⚠️ Needs rotation |
| CORS_ORIGIN | * | ❌ Needs restriction |
| RATE_LIMIT_MAX_REQUESTS | 100 | ✅ |
| GOOGLE_MAPS_API_KEY | (hidden) | ✅ |

### Running Services (PM2)

| Name | Status | Uptime | CPU | Memory |
|------|--------|--------|-----|--------|
| cloudflared | online | 2 days | 0% | 24.2mb |
| motorbike-parking-api | online | 2 days | 0% | 45.7mb |

---

## 6. Appendix

### Database Schema (Key Tables)

**users**
- id (UUID, PK)
- email (VARCHAR, UNIQUE)
- password_hash (VARCHAR)
- is_anonymous (BOOLEAN)
- is_admin (BOOLEAN)
- is_active (BOOLEAN)
- created_at, updated_at

**parking_zones**
- id (UUID, PK)
- google_places_id (VARCHAR)
- latitude, longitude (DECIMAL)
- total_capacity, current_occupancy (INT)
- confidence_score (DECIMAL)
- is_active (BOOLEAN)

**user_reports**
- id (UUID, PK)
- spot_id (FK → parking_zones)
- user_id (FK → users)
- reported_count (INT)
- timestamp, is_verified

**report_images**
- id (UUID, PK)
- report_id (FK → user_reports)
- image_url, file_path (VARCHAR)

### API Response Format

**Success Response:**
```json
{
  "message": "Success message",
  "data": { ... },
  "count": 1
}
```

**Error Response:**
```json
{
  "error": "Error message"
}
```

**Validation Error:**
```json
{
  "error": "Validation failed",
  "details": [
    { "field": "email", "message": "..." }
  ]
}
```

---

## 7. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-03-01 | opencode | Initial SWOT analysis |

---

*Document generated by opencode AI Assistant*
