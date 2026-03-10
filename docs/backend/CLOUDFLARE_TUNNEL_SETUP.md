# Cloudflare Tunnel Setup Guide

**Project:** Motorbike Parking App
**Date:** March 10, 2026
**Backend URL:** https://homelab-backendpi.pedroocalado.eu

---

## Current Tunnel Status (Updated: 2026-03-10)

| Property | Value |
|----------|-------|
| **Tunnel Name** | homelab-backendpi |
| **Tunnel ID** | afaa1920-a76e-4073-bfd4-9bfc0fe24769 |
| **Domain** | homelab-backendpi.pedroocalado.eu |
| **Status** | ✅ Online |
| **Protocol** | QUIC (UDP) |
| **Local Service** | http://localhost:3000 |

### Current CORS Configuration

```
CORS_ORIGIN=http://localhost:3000,http://localhost:8080,http://localhost:4200,https://homelab-backendpi.pedroocalado.eu,https://motorbike-web.vercel.app
```

---

## Overview

This guide documents the Cloudflare Tunnel setup for exposing the Motorbike Parking App backend to the internet without requiring firewall port forwarding.

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                        🌐 INTERNET                        │
│                                                             │
│    pedroocalado.eu ──┬──> homelab-backendpi.pedroocalado.eu (CNAME)
│                      │
│                      └──> traffic → Cloudflare → Tunnel → Backend (localhost:3000)
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                   🏠 HOMELAB BACKENDPI                   │
│                     192.168.1.67                          │
│                                                             │
│   ┌─────────────────────────────────────────┐            │
│   │   Cloudflared Tunnel (afaa1920-a76e-4073-bfd4-9bfc0fe24769) │
│   │              -> localhost:3000 (Node.js API)            │
│   │                                                             │
│   │   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐   │
│   │   │ API Server   │   │ DB (MariaDB) │   │ PM2 Manager │   │
│   │   │ Port: 3000   │   │ Port: 3306   │   │ Port: 0     │   │
│   │   └─────────────┘   └─────────────┘   └─────────────┘   │
│   └─────────────────────────────────────────┘            │
└─────────────────────────────────────────────────────────┘
```

---

## Tunnel Configuration

### Tunnel Details

| Property | Value |
|----------|-------|
| **Tunnel Name** | homelab-backendpi |
| **Tunnel ID** | afaa1920-a76e-4073-bfd4-9bfc0fe24769 |
| **Account Tag** | 5e4bbe6af2095d5656bc3bda4c0d0e97 |
| **Cloudflare Account** | pedroocalado.eu |
| **Local Service** | http://localhost:3000 |
| **Protocol** | QUIC (UDP) |

### Credentials File

**Location:** `~/.cloudflared/afaa1920-a76e-4073-bfd4-9bfc0fe24769.json`

```json
{
  "AccountTag": "5e4bbe6af2095d5656bc3bda4c0d0e97",
  "TunnelID": "afaa1920-a76e-4073-bfd4-9bfc0fe24769",
  "TunnelName": "homelab-backendpi",
  "TunnelSecret": "<secret-from-file>"
}
```

### Config File

**Location:** `~/.cloudflared/config.yml`

```yaml
tunnel: afaa1920-a76e-4073-bfd4-9bfc0fe24769
credentials-file: /home/pedroocalado/.cloudflared/afaa1920-a76e-4073-bfd4-9bfc0fe24769.json

ingress:
  - hostname: homelab-backendpi.pedroocalado.eu
    service: http://localhost:3000
  - service: http_status:404
```

---

## Setup Instructions

### Step 1: Install cloudflared

```bash
# Check if installed
cloudflared --version

# Install on Linux/ARM
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64
sudo mv cloudflared-linux-arm64 /usr/local/bin/cloudflared
sudo chmod +x /usr/local/bin/cloudflared
```

### Step 2: Login to Cloudflare

```bash
cloudflared login
```

- Browser will open for OAuth authentication
- Grant permissions to access Cloudflare account
- Certificate saved to: `~/.cloudflared/cert.pem`

### Step 3: Verify Tunnel Exists

```bash
cloudflared tunnel list
```

Expected output:
```
ID                                   NAME              CREATED
afaa1920-a76e-4073-bfd4-9bfc0fe24769 homelab-backendpi 2026-03-10T21:48:51Z
```

### Step 4: Create DNS Record

```bash
cloudflared tunnel route dns --overwrite-dns afaa1920-a76e-4073-bfd4-9bfc0fe24769 homelab-backendpi.pedroocalado.eu
```

This creates a CNAME record: `homelab-backendpi.pedroocalado.eu` → `afaa1920-a76e-4073-bfd4-9bfc0fe24769.cfargotunnel.com`

### Step 5: Run the Tunnel

**Option A: Manual Run (for testing)**
```bash
cd ~
cloudflared tunnel run homelab-backendpi
```

**Option B: Run with PM2 (production)**
```bash
# Create systemd service or use PM2
pm2 start cloudflared --name "homelab-backendpi" -- tunnel run homelab-backendpi
```

**Option C: Run as systemd service**
```bash
sudo nano /etc/systemd/system/cloudflared.service
```

Add:
```ini
[Unit]
Description=Cloudflare Tunnel for Motorbike Backend
After=network.target

[Service]
Type=simple
User=pedroocalado
WorkingDirectory=/home/pedroocalado
ExecStart=/usr/local/bin/cloudflared tunnel run homelab-backendpi
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl daemon-reload
sudo systemctl enable cloudflared
sudo systemctl start cloudflared
```

---

## Connection Status

### Check Tunnel Status

```bash
# List all tunnels
cloudflared tunnel list

# Get tunnel info
cloudflared tunnel info homelab-backendpi

# Monitor connections
cloudflared tunnel info homelab-backendpi --loglevel debug
```

### Expected Active Connections

After successful startup, you should see multiple connections across different Cloudflare data centers:

```
CONNECTOR ID                         CREATED              ARCHITECTURE VERSION  EDGE
c4dff337-6f73-438a-a6b1-134ca5594249 2026-03-10T16:14:57Z linux_arm64  2026.2.0 2xlis01, 2xlis05
```

Common edge locations: `2xlis01`, `2xlis05`, `2xlis07`, `2xlis11`

### Test Connectivity

```bash
# Test health endpoint
curl https://homelab-backendpi.pedroocalado.eu/health

# Test API
curl https://homelab-backendpi.pedroocalado.eu/api/users
```

---

## Environment Configuration

### Backend (.env)

```env
PORT=3000
NODE_ENV=development
CORS_ORIGIN=http://localhost:3000,http://localhost:8080,http://localhost:4200,https://homelab-backendpi.pedroocalado.eu,https://motorbike-web.vercel.app

DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=motorbike_parking_app
DB_USER=motorbike_app
DB_PASSWORD=2LXC8uW0wF7VIAycGa7l
DB_SSL=false

JWT_SECRET=41855b544528ff2616ab67bf25f99c5244a296dab8bfb6547750c7a03fa90cc6
JWT_EXPIRES_IN=7d
```

### Frontend (.env)

```env
# API URL (must match backend tunnel URL)
DEV_API_BASE_URL=https://homelab-backendpi.pedroocalado.eu
PROD_API_BASE_URL=https://homelab-backendpi.pedroocalado.eu

# API Timeout
API_TIMEOUT=30000
```

### Flutter Environment

Update `lib/config/environment.dart`:

```dart
static String get apiBaseUrl {
  switch (_currentEnvironment) {
    case EnvironmentType.development:
      return dotenv.env['DEV_API_BASE_URL'] ?? 'http://localhost:3000';
    case EnvironmentType.staging:
      return dotenv.env['STAGING_API_BASE_URL'] ?? 'http://staging.example.com';
    case EnvironmentType.production:
      return dotenv.env['PROD_API_BASE_URL'] ?? 'http://192.168.1.67:3000';
  }
}
```

---

## Troubleshooting

### Tunnel Won't Start

**Problem:** Process dies immediately after starting

**Solutions:**
1. Check credentials file exists and is valid JSON
2. Verify tunnel ID matches credentials
3. Check file permissions: `chmod 600 ~/.cloudflared/credentials-homelab.json`
4. Run with debug logging: `cloudflared tunnel run homelab-backendpi --loglevel debug`

**Common Errors:**
- `"invalid JSON when parsing credentials file"` → Check credentials file path and format
- `"cannot find a valid certificate"` → Run `cloudflared login` to get cert.pem
- `"connection terminated"` → Network connectivity issues, check firewall

### No Active Connections

**Problem:** Tunnel starts but shows 0 connections

**Solutions:**
1. Wait 30 seconds - connections may take time to establish
2. Check network connectivity: `ping cloudflare.com`
3. Verify DNS record exists: `dig homelab-backendpi.pedroocalado.eu CNAME`
4. Clean up stale connections: `cloudflared tunnel cleanup homelab-backendpi`
5. Restart tunnel: `pm2 restart homelab-backendpi`

### DNS Not Resolving

**Problem:** Domain returns 530 error

**Solutions:**
1. Check DNS propagation: `dig @1.1.1.1 homelab-backendpi.pedroocalado.eu`
2. Verify CNAME record points to tunnel ID: `afaa1920-a76e-4073-bfd4-9bfc0fe24769.cfargotunnel.com`
3. Check Cloudflare dashboard for DNS settings
4. Regenerate DNS record: `cloudflared tunnel route dns --overwrite-dns afaa1920-a76e-4073-bfd4-9bfc0fe24769 homelab-backendpi.pedroocalado.eu`

### API Not Responding

**Problem:** Tunnel connects but API returns errors

**Solutions:**
1. Check backend is running: `pm2 status`
2. Test local API: `curl http://localhost:3000/health`
3. Check backend logs: `pm2 logs motorbike-api`
4. Verify port 3000 is listening: `lsof -i :3000`
5. Check CORS settings in backend

### PM2 Caching Old Environment Variables

**Problem:** Backend uses old CORS settings even after updating `.env`

**Symptom:** Logs show old quick tunnel URL in CORS origins

**Root Cause:** PM2 caches environment variables in `~/.pm2/module_conf.json`

**Solution:**
```bash
# Option 1: Clear PM2 cache (recommended)
pm2 kill
rm -f ~/.pm2/module_conf.json ~/.pm2/dump.pm2
pm2 start src/server.js --name 'motorbike-parking-api'

# Option 2: Edit cached config directly
nano ~/.pm2/module_conf.json
# Update CORS_ORIGIN value, then:
pm2 restart motorbike-parking-api
```

### Tunnel Config Not Updating

**Problem:** Tunnel uses old hostname in ingress after config change

**Symptom:** Logs show `api.pedroocalado.eu` instead of `homelab-backendpi.pedroocalado.eu`

**Root Cause:** Cloudflare caches tunnel configuration

**Solution:**
```bash
# Delete and recreate tunnel
pm2 delete homelab-backendpi
cloudflared tunnel delete homelab-backendpi
cloudflared tunnel create homelab-backendpi
# Update config.yml with new tunnel ID
# Recreate DNS record
pm2 start cloudflared --name 'homelab-backendpi' -- tunnel run homelab-backendpi
```

---

## Security

### Best Practices

1. **Keep credentials secure:**
   ```bash
   chmod 600 ~/.cloudflared/credentials-homelab.json
   chmod 600 ~/.cloudflared/cert.pem
   ```

2. **Use HTTPS only** (automatic via Cloudflare)

3. **Enable Cloudflare WAF** for additional protection:
   - Settings → WAF → Custom rules

4. **Regular updates:**
   ```bash
   sudo apt update && sudo apt upgrade cloudflared
   ```

5. **Monitor usage:**
   - Cloudflare dashboard → Zero Trust → Tunnels
   - Check active connections and traffic

### Authentication

The tunnel uses:
- **Tunnel Credentials**: Signed by Cloudflare (stored in credentials.json)
- **Cloudflare Access**: Optional additional authentication layer

To enable Cloudflare Access:
1. Go to Zero Trust → Access → Applications
2. Create application with tunnel destination
3. Configure SSO (Google OAuth, etc.)

---

## Maintenance

### Backup Credentials

```bash
cp ~/.cloudflared/credentials-homelab.json ~/.cloudflared/credentials-homelab.json.backup
cp ~/.cloudflared/config.yml ~/.cloudflared/config.yml.backup
```

### Update Tunnel Configuration

Edit config.yml and reload:
```bash
# If using systemd
sudo systemctl restart cloudflared

# If using PM2
pm2 restart homelab-backendpi

# Manual reload
pkill cloudflared && cloudflared tunnel run homelab-backendpi &
```

### Check Logs

```bash
# PM2 logs
pm2 logs homelab-backendpi

# Systemd logs
sudo journalctl -u cloudflared -f

# Debug output
cloudflared tunnel run homelab-backendpi --loglevel debug
```

---

## References

- [Cloudflare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [Cloudflare Zero Trust](https://developers.cloudflare.com/cloudflare-one/)
- [GitHub - Cloudflare/cloudflared](https://github.com/cloudflare/cloudflared)

---

**Last Updated:** March 10, 2026
**Status:** ✅ Production Active
**Tunnel ID:** afaa1920-a76e-4073-bfd4-9bfc0fe24769
