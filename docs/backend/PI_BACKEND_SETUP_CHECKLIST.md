# Backend Setup Checklist for Pi

**Date:** 2026-03-03

---

## 0. IMPORTANT: Document All Changes

**After any restart or configuration change, record the following in this document:**

1. **Cloudflare Tunnel URL** - Check if it changed
2. **New Vercel deployment URLs** - If frontend was redeployed
3. **CORS_ORIGIN changes** - Any new domains added
4. **Database changes** - Schema or data modifications
5. **Any errors encountered** - And how they were resolved

**Where to document:**
- Edit this file (`docs/backend/PI_BACKEND_SETUP_CHECKLIST.md`)
- Commit changes: `git add . && git commit -m "docs: update backend config"`
- Push: `git push origin main`

**Why:** The frontend team needs to know the current API URL and any new allowed domains for CORS.

---

## CURRENT CONFIGURATION (Last Updated: 2026-03-10)

### Cloudflare Tunnel URL (Fixed Domain)
```
https://homelab-backendpi.pedroocalado.eu
```

**Note:** This is a permanent domain - it does NOT change on restart.

### Vercel Frontend URLs
| Environment | URL |
|------------|-----|
| Production | https://motorbike-web.vercel.app |
| Preview (test) | https://motorbike-pfygtbflv-silentcamxmfs-projects.vercel.app |

### CORS_ORIGIN (in backend/.env)
```
http://localhost:3000,http://localhost:8080,http://localhost:4200,https://homelab-backendpi.pedroocalado.eu,https://motorbike-web.vercel.app
```

**Note:** Update CORS_ORIGIN whenever the tunnel URL changes.

### Database Configuration
| Setting | Value |
|---------|-------|
| Host | 127.0.0.1 |
| Port | 3306 |
| Database | motorbike_parking_app |
| User | motorbike_app |

### Backend Process
| Service | Name | Status |
|---------|------|--------|
| API | motorbike-parking-api | online |
| Tunnel | cloudflared | online |

### Backend Changes Implemented
- ✅ snake_case to camelCase transformation for all API responses
- ✅ Rate limiter disabled in test mode
- ✅ JWT authentication returns 401 for invalid tokens
- ✅ 27/29 tests passing (93%)

---

## 1. Verify Backend is Running

```bash
pm2 status
```

Expected output: `motorbike-parking-api` should show "online" status.

If not running:
```bash
cd ~/motorbike_app/backend
pm2 start ecosystem.config.js
```

---

## 2. Verify Cloudflare Tunnel

```bash
pm2 logs cloudflared --lines 15
```

Expected: Look for `https://*.trycloudflare.com` in the output.

**Get current URL:**
```bash
pm2 logs cloudflared --lines 5 | grep trycloudflare
```

**IMPORTANT: If URL changed, record it:**
- Update this document with the new URL
- Notify frontend team
- Update CORS_ORIGIN in .env if needed
- Commit and push changes

---

## 3. Verify CORS Configuration

Check the `.env` file has the correct CORS_ORIGIN:

```bash
cat ~/motorbike_app/backend/.env | grep CORS_ORIGIN
```

**Required value (update with current URLs):**
```
CORS_ORIGIN=http://localhost:3000,http://localhost:8080,http://localhost:4200,https://homelab-backendpi.pedroocalado.eu,https://motorbike-web.vercel.app
```

If missing or incorrect, edit the file:

```bash
nano ~/motorbike_app/backend/.env
```

Add or update the line (use current Vercel/tunnel URLs):
```
CORS_ORIGIN=http://localhost:3000,http://localhost:8080,http://localhost:4200,https://homelab-backendpi.pedroocalado.eu,https://motorbike-web.vercel.app
```

**IMPORTANT: Restart backend after ANY changes to .env file:**
```bash
pm2 restart motorbike-parking-api
```

**Verify restart completed:**
```bash
pm2 logs motorbike-parking-api --lines 5 --nostream
```

---

## 4. Test CORS Headers

After restart, test from the Pi:

```bash
curl -I -X OPTIONS https://homelab-backendpi.pedroocalado.eu/api/parking/nearby \
  -H "Origin: https://motorbike-web.vercel.app" \
  -H "Access-Control-Request-Method: GET"
```

Expected: Should see `Access-Control-Allow-Origin: https://motorbike-web.vercel.app`

If you get `500 Internal Server Error` with `"CORS not allowed for this origin"`, the backend hasn't been restarted yet. Run:
```bash
pm2 restart motorbike-parking-api
```

Then test again.

---

## 5. Test API Endpoints

After restart, test all endpoints:

```bash
# Test anonymous login (requires CORS to work)
curl -X POST https://homelab-backendpi.pedroocalado.eu/api/auth/anonymous

# Test parking zones (near Lisbon)
curl "https://homelab-backendpi.pedroocalado.eu/api/parking/nearby?lat=38.72&lng=-9.14&radius=10"
```

If CORS error appears, run:
```bash
pm2 restart motorbike-parking-api
```

---

## 6. Troubleshooting

### CORS still not working?

1. Check current CORS_ORIGIN value:
```bash
cat ~/motorbike_app/backend/.env | grep CORS_ORIGIN
```

2. Restart the backend:
```bash
pm2 restart motorbike-parking-api
```

3. Wait 5 seconds, then test:
```bash
curl -I -X OPTIONS https://homelab-backendpi.pedroocalado.eu/api/parking/nearby \
  -H "Origin: https://motorbike-web.vercel.app" \
  -H "Access-Control-Request-Method: GET"
```

4. Check for error message:
```bash
curl -I -X OPTIONS https://homelab-backendpi.pedroocalado.eu/api/parking/nearby \
  -H "Origin: https://motorbike-web.vercel.app" \
  -H "Access-Control-Request-Method: GET"
```

If response contains `"CORS not allowed for this origin"`, the .env file was not saved or backend wasn't restarted.

### Backend not responding?

1. Check status:
```bash
pm2 status
```

2. Check logs:
```bash
pm2 logs motorbike-parking-api --lines 20
```

3. Restart if needed:
```bash
pm2 restart motorbike-parking-api
```

---

## Fixed Cloudflare Tunnel (Production)

### The Solution
We now use a permanent Cloudflare Tunnel with a fixed domain:
- **Domain:** `homelab-backendpi.pedroocalado.eu`
- **Tunnel ID:** `b6722b94-9a7a-4d22-a7cb-57d4b4b56fa9`
- **URL does NOT change** on restart

### Current Status
| Service | Status |
|---------|--------|
| Backend API (localhost:3000) | ✅ Always working |
| Database | ✅ Always connected |
| Cloudflare Tunnel | ✅ Stable - fixed domain |

### Tunnel Management

Check tunnel status:
```bash
pm2 status
cloudflared tunnel info homelab-backendpi
```

Restart tunnel:
```bash
pm2 restart homelab-backendpi
```

---

## 7. Update Frontend .env (if URL changed)

If Cloudflare URL changed, update `.env` in the Flutter project and redeploy to Vercel:

**On local machine:**
```bash
# Edit .env file
nano .env

# Rebuild web
flutter build web --release

# Deploy to Vercel
cd build/web
vercel --prod
```

---

## Quick Reference Commands

| Action | Command |
|--------|---------|
| Check status | `pm2 status` |
| View logs | `pm2 logs` |
| Restart API | `pm2 restart motorbike-parking-api` |
| Restart tunnel | `pm2 restart homelab-backendpi` |
| Tunnel info | `cloudflared tunnel info homelab-backendpi` |
| Test local API | `curl http://localhost:3000/health` |
| Test tunnel API | `curl https://homelab-backendpi.pedroocalado.eu/health` |

---

## For Frontend Team

**Backend URL:** `https://homelab-backendpi.pedroocalado.eu`

This is a **fixed domain** - it does NOT change on restart.
