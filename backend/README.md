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

- Passwords hashed with bcrypt
- JWT tokens for authentication
- Rate limiting (100 requests per 15 minutes)
- Helmet for security headers
- Input validation with Joi
- SQL injection protection (parameterized queries)

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

## License

MIT
