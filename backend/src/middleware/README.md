# Backend Middleware Documentation

## Overview
This document describes all middleware used in the MotorBike Parking App backend.

## Middleware Files

### auth.js
- `authenticateToken` - Verifies JWT token from Authorization header
- `requireAdmin` - Checks if user has admin privileges
- `optionalAuth` - Optional authentication (doesn't fail if no token)
- `blacklistToken` / `isTokenBlacklisted` - Token revocation management

### validation.js
- `validate(schema)` - Factory that returns Joi validation middleware
- Predefined schemas:
  - `schemas.register` - User registration
  - `schemas.login` - User login
  - `schemas.createZone` - Parking zone creation
  - `schemas.updateZone` - Parking zone update
  - `schemas.createReport` - Report creation

### errorHandler.js
- `errorHandler` - Global error handling middleware
- `notFound` - 404 handler for unknown routes
- Handles MySQL, JWT, and Multer errors

### upload.js
- Multer configuration for image uploads
- Storage: Disk storage with timestamp-based unique filenames
- File filter: JPEG, PNG, GIF, WebP only
- Size limit: 5MB

### Rate Limiting (server.js)
- Uses `express-rate-limit`
- Configurable via environment variables:
  - `RATE_LIMIT_WINDOW_MS` (default: 15 minutes)
  - `RATE_LIMIT_MAX_REQUESTS` (default: 100)

## Verification
Last verified: March 1, 2026
- Local and Pi middleware synchronized
- All endpoints functional
