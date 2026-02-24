# Motorbike Parking App

A Flutter application for finding and reporting motorbike parking availability in real-time.

## Features

- Find nearby parking zones on an interactive map
- Report parking availability
- View parking zone details and confidence scores
- User authentication (email + anonymous)
- Real-time occupancy updates based on user reports
- Cross-platform: iOS, Android, and Web

## Tech Stack

- **Frontend**: Flutter 3.24+ (Mobile + Web)
- **Backend**: Node.js + Express
- **Database**: MariaDB/MySQL
- **Maps**: Google Maps Flutter

## Project Structure

```
├── lib/                    # Flutter app source code
├── backend/               # Node.js API server
│   ├── src/
│   │   ├── controllers/   # Route handlers
│   │   ├── middleware/   # Auth, validation
│   │   ├── routes/       # API routes
│   │   └── config/       # Database config
│   └── package.json
├── schema.sql             # Database schema
├── web/                  # Web build output
└── pubspec.yaml          # Flutter dependencies
```

## Getting Started

### Prerequisites

- Flutter SDK 3.24+
- Node.js 18+
- MariaDB/MySQL

### Backend Setup

```bash
cd backend
npm install

# Copy environment file
cp .env.example .env

# Edit .env with your database credentials
nano .env

# Run the server
npm run dev
```

### Flutter App Setup

```bash
# Install dependencies
flutter pub get

# Run in debug mode
flutter run

# Build for web
flutter build web --release
```

### Database Setup

```bash
# Create database and user
mysql -u root -p < schema.sql

# Create app user
mysql -u root -p
CREATE USER 'motorbike_app'@'localhost' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON motorbike_parking_app.* TO 'motorbike_app'@'localhost';
FLUSH PRIVILEGES;
```

## Environment Variables

### Backend (.env)

```env
NODE_ENV=development
PORT=3000
DB_HOST=localhost
DB_PORT=3306
DB_NAME=motorbike_parking_app
DB_USER=motorbike_app
DB_PASSWORD=your_password
JWT_SECRET=your_secret_key
JWT_EXPIRES_IN=7d
```

### Flutter (.env)

```env
DEV_API_BASE_URL=http://localhost:3000
PROD_API_BASE_URL=https://your-production-url.com
ENVIRONMENT=development
```

## Remote Access

### Cloudflare Tunnel (Recommended)

For accessing the backend from anywhere without port forwarding:

```bash
# On your server/Pi
cloudflared tunnel --url http://localhost:3000
```

This provides a URL like `https://xxx.trycloudflare.com`

### Deployment

1. Build the Flutter web app: `flutter build web --release`
2. Serve the `build/web` folder statically
3. Update API URLs to point to your server

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /api/auth/register | Register new user |
| POST | /api/auth/login | User login |
| POST | /api/auth/anonymous | Anonymous login |
| GET | /api/auth/me | Get current user |
| GET | /api/parking/nearby | Get nearby parking zones |
| GET | /api/parking/:id | Get parking zone details |
| POST | /api/reports | Submit parking report |
| GET | /api/reports/me | Get user's reports |

## License

MIT
