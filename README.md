# Motorbike Parking App

A Flutter application for finding and reporting motorbike parking availability in real-time.

## Live Demo

| Service | URL |
|--------|-----|
| **Web App** | https://web-smoky-chi-34.vercel.app |
| **Backend API** | https://delaware-compromise-someone-cheapest.trycloudflare.com |

> **Note**: The backend URL changes when the Cloudflare tunnel restarts. For production, use a permanent domain.

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
- **Hosting**: Vercel (Web), Raspberry Pi (Backend)

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

## Architecture

The app uses a **client-server** architecture with separate hosting for frontend and backend:

```
┌─────────────────────────────┐     ┌─────────────────────────────┐
│      Flutter Web App        │     │     Raspberry Pi Backend    │
│       (Vercel)              │     │     (Node.js + MariaDB)     │
│                             │     │                             │
│  https://web-xxx.vercel.app │────▶│  localhost:3000             │
└─────────────────────────────┘     └──────────────┬──────────────┘
                                                   │
                                                   ▼
                                    ┌─────────────────────────────┐
                                    │    Cloudflare Tunnel        │
                                    │    (Public API Access)      │
                                    │                             │
                                    │  https://xxx.trycloudflare.com
                                    └─────────────────────────────┘
```

### Hosting Components

| Service | Purpose | Technology |
|---------|---------|------------|
| **Vercel** | Flutter web frontend hosting | Static web hosting (auto-deploys from GitHub) |
| **Cloudflare Tunnel** | Backend API exposure | Tunnel from Raspberry Pi to public URL |
| **Raspberry Pi** | Backend server | Node.js + Express + MariaDB + PM2 |

### Why Both Are Needed

- **Vercel** hosts the compiled Flutter web app (static HTML/JS/CSS)
- **Cloudflare Tunnel** exposes the Node.js backend API to the internet without port forwarding

> **Note**: The Cloudflare URL is temporary and changes each time the tunnel restarts. For production, purchase a domain and configure a permanent tunnel.

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
GOOGLE_MAPS_API_KEY=<your-google-maps-api-key>
```

> Get a Google Maps API key from [Google Cloud Console](https://console.cloud.google.com/). Enable "Maps JavaScript API" and optionally "Places API".

## Remote Access

### Cloudflare Tunnel (Recommended)

For accessing the backend from anywhere without port forwarding:

```bash
# On your server/Pi
cloudflared tunnel --url http://localhost:3000
```

This provides a URL like `https://xxx.trycloudflare.com`

### Deployment

#### Web (Vercel)

```bash
# Build the web app
flutter build web --release

# Deploy to Vercel
cd build/web
vercel deploy --prod --yes
```

#### Backend (Raspberry Pi)

```bash
# Install dependencies
cd backend
npm install

# Run with PM2
pm2 start src/server.js --name motorbike-api
pm2 save
```

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
