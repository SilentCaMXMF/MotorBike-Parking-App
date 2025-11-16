# Motorbike Parking API

REST API for the Motorbike Parking App built with Node.js + Express.

## Features

- ✅ User authentication (register, login, anonymous)
- ✅ JWT token-based authorization
- ✅ Parking zone management
- ✅ User report submission
- ✅ Nearby parking zone search
- ✅ Rate limiting
- ✅ Input validation
- ✅ Error handling
- ✅ Security headers (Helmet)
- ✅ CORS support

## Prerequisites

- Node.js >= 18.0.0
- npm >= 9.0.0
- MariaDB/MySQL database (configured in Phase 1)

## Installation

```bash
# Install dependencies
npm install

# Copy environment file
cp .env.example .env

# Edit .env with your configuration
nano .env
```

## Configuration

Edit `.env` file with your settings:

```env
# Server
NODE_ENV=development
PORT=3000

# Database (from Phase 1)
DB_HOST=192.168.1.67
DB_PORT=3306
DB_NAME=motorbike_parking_app
DB_USER=motorbike_app
DB_PASSWORD=your_password_here

# JWT
JWT_SECRET=your_secret_here
JWT_EXPIRES_IN=7d

# Admin User Setup
ADMIN_EMAIL=admin@example.com
ADMIN_PASSWORD=SecureAdminPassword123!
```

### Admin User Setup

The backend requires an admin user for managing parking zones. Follow these steps to set up admin access securely:

#### Step 1: Configure Admin Credentials

1. **Set Environment Variables**:
   ```bash
   # Edit your .env file
   nano .env
   ```

2. **Add Admin Credentials**:
   ```env
   ADMIN_EMAIL=admin@example.com
   ADMIN_PASSWORD=SecureAdminPassword123!
   ```

#### Step 2: Create Admin User

Run the admin creation script:

```bash
# Create admin user with environment variables
node create-admin.js

# Or specify credentials directly (NOT RECOMMENDED for production)
node create-admin.js --email=admin@example.com --password=SecureAdminPassword123!
```

#### Step 3: Verify Admin Creation

The script will confirm successful creation and provide login instructions.

### Security Requirements

#### Password Requirements
- Minimum 8 characters
- At least 1 uppercase letter
- At least 1 lowercase letter
- At least 1 number
- At least 1 special character (!@#$%^&*)

#### Email Requirements
- Valid email format
- Recommended to use domain-specific email for production

#### Security Best Practices

1. **Environment Variables**:
   - Never commit `.env` to version control
   - Use strong, unique passwords
   - Consider using password managers for credential storage

2. **Admin Account Security**:
   - Use a dedicated admin email address
   - Enable 2FA on the admin email account
   - Change passwords regularly
   - Limit admin access to trusted personnel

3. **Production Deployment**:
   - Use HTTPS for all API communications
   - Set `NODE_ENV=production` in production
   - Use environment variable management systems
   - Regularly rotate JWT secrets

### Example Scenarios

#### Development Setup
```env
ADMIN_EMAIL=dev-admin@localhost
ADMIN_PASSWORD=DevAdmin123!
```

#### Production Setup
```env
ADMIN_EMAIL=admin@yourcompany.com
ADMIN_PASSWORD=Pr0dAdmin$ecur3P@ss2024!
```

### Troubleshooting

#### Common Issues

1. **"Admin user already exists"**:
   ```bash
   # Check existing admin
   node -e "
   const db = require('./src/config/database');
   db.query('SELECT email FROM users WHERE is_admin = true', (err, results) => {
     if (err) console.error(err);
     else console.log('Existing admins:', results);
     process.exit(0);
   });
   "
   ```

2. **"Database connection failed"**:
   - Verify database credentials in `.env`
   - Ensure database server is running
   - Check network connectivity

3. **"Invalid email format"**:
   - Ensure email follows standard format
   - Check for typos in email address

4. **"Password too weak"**:
   - Ensure password meets all requirements
   - Use password generator if needed

#### Error Recovery

If admin creation fails, you can manually reset:

```sql
-- Connect to your database
-- Remove existing admin (if any)
DELETE FROM users WHERE is_admin = true;

-- Then re-run the admin creation script
node create-admin.js
```

#### Verification Commands

```bash
# Test admin login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"SecureAdminPassword123!"}'

# Check admin status
curl -X GET http://localhost:3000/api/auth/me \
  -H "Authorization: Bearer <admin_token>"
```

## Running

```bash
# Development mode (with auto-reload)
npm run dev

# Production mode
npm start

# Run tests
npm test
```

## API Endpoints

### Authentication

#### Register User

```http
POST /api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "Password123"
}
```

#### Login

```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "Password123"
}
```

#### Anonymous Login

```http
POST /api/auth/anonymous
```

#### Get Current User

```http
GET /api/auth/me
Authorization: Bearer <token>
```

### Parking Zones

#### Get Nearby Zones

```http
GET /api/parking/nearby?lat=38.7223&lng=-9.1393&radius=5&limit=50
```

#### Get Specific Zone

```http
GET /api/parking/:id
```

#### Create Zone (Admin)

```http
POST /api/parking
Authorization: Bearer <admin_token>
Content-Type: application/json

{
  "googlePlacesId": "ChIJD7...",
  "latitude": 38.7223,
  "longitude": -9.1393,
  "totalCapacity": 10
}
```

#### Update Zone (Admin)

```http
PUT /api/parking/:id
Authorization: Bearer <admin_token>
Content-Type: application/json

{
  "totalCapacity": 15
}
```

### Reports

#### Create Report

```http
POST /api/reports
Authorization: Bearer <token>
Content-Type: application/json

{
  "spotId": "uuid-here",
  "reportedCount": 5,
  "userLatitude": 38.7223,
  "userLongitude": -9.1393
}
```

#### Get Zone Reports

```http
GET /api/reports?spotId=uuid-here&hours=24
```

#### Get My Reports

```http
GET /api/reports/me?limit=50&offset=0
Authorization: Bearer <token>
```

## Response Format

### Success Response

```json
{
  "message": "Success message",
  "data": { ... }
}
```

### Error Response

```json
{
  "error": "Error message",
  "details": [ ... ]
}
```

## Status Codes

- `200` - Success
- `201` - Created
- `400` - Bad Request (validation error)
- `401` - Unauthorized (no token or invalid token)
- `403` - Forbidden (insufficient permissions)
- `404` - Not Found
- `409` - Conflict (duplicate resource)
- `429` - Too Many Requests (rate limit exceeded)
- `500` - Internal Server Error

## Security

### Built-in Security Features
- Passwords hashed with bcrypt (cost factor 12)
- JWT tokens for authentication with expiration
- Rate limiting (100 requests per 15 minutes per IP)
- Helmet for security headers
- Input validation with Joi
- SQL injection protection (parameterized queries)
- CORS configuration for cross-origin requests

### Admin Security Guidelines

#### Credential Management
- **Never hardcode credentials** in source code
- **Use environment variables** for all sensitive data
- **Rotate passwords regularly** (recommended every 90 days)
- **Use password managers** for storing admin credentials
- **Implement principle of least privilege** for admin access

#### Environment Security
```bash
# Secure .env file permissions
chmod 600 .env

# Verify file is not tracked by git
git status --ignored | grep .env
```

#### Production Security Checklist
- [ ] Set `NODE_ENV=production`
- [ ] Use HTTPS with valid SSL certificates
- [ ] Configure firewall rules
- [ ] Enable database connection encryption
- [ ] Set up monitoring and alerting
- [ ] Regular security updates
- [ ] Backup and recovery procedures

#### Monitoring and Auditing
- Monitor failed login attempts
- Log admin actions for audit trails
- Set up alerts for suspicious activities
- Regular security scans and penetration testing

### Incident Response

If admin credentials are compromised:
1. Immediately change admin password
2. Rotate JWT secret
3. Review admin activity logs
4. Invalidate all active tokens
5. Notify security team
6. Document the incident

## Project Structure

```
backend/
├── src/
│   ├── config/
│   │   └── database.js          # Database connection
│   ├── controllers/
│   │   ├── authController.js    # Authentication logic
│   │   ├── parkingController.js # Parking zone logic
│   │   └── reportController.js  # Report logic
│   ├── middleware/
│   │   ├── auth.js              # JWT authentication
│   │   ├── validation.js        # Input validation
│   │   └── errorHandler.js      # Error handling
│   ├── routes/
│   │   ├── auth.js              # Auth routes
│   │   ├── parking.js           # Parking routes
│   │   └── reports.js           # Report routes
│   └── server.js                # Main server file
├── .env                         # Environment variables (gitignored)
├── .env.example                 # Environment template
├── create-admin.js              # Admin user creation script
├── package.json                 # Dependencies
└── README.md                    # This file
```

## Testing

```bash
# Run all tests
npm test

# Run with coverage
npm test -- --coverage
```

## Deployment

See Phase 5 of MIGRATION_TODO_LIST.md for deployment instructions.

## Quick Reference

### Admin Setup Commands
```bash
# 1. Configure environment
cp .env.example .env
nano .env  # Add ADMIN_EMAIL and ADMIN_PASSWORD

# 2. Create admin user
node create-admin.js

# 3. Test admin login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"your-admin-email","password":"your-admin-password"}'
```

### Environment Variables Summary
```env
# Required for all environments
NODE_ENV=development|production
PORT=3000
DB_HOST=your-db-host
DB_PORT=3306
DB_NAME=motorbike_parking_app
DB_USER=your-db-user
DB_PASSWORD=your-db-password
JWT_SECRET=your-jwt-secret
JWT_EXPIRES_IN=7d

# Required for admin setup
ADMIN_EMAIL=admin@example.com
ADMIN_PASSWORD=SecureAdminPassword123!
```

### Common Admin Tasks
- **Create parking zone**: `POST /api/parking` (requires admin token)
- **Update parking zone**: `PUT /api/parking/:id` (requires admin token)
- **View all reports**: `GET /api/reports` (requires admin token)
- **Check admin status**: `GET /api/auth/me` (with admin token)

## License

MIT
