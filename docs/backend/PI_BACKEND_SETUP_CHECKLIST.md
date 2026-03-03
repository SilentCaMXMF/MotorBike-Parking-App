# Backend Setup Checklist for Pi

**Date:** 2026-03-03

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

---

## 3. Verify CORS Configuration

Check the `.env` file has the correct CORS_ORIGIN:

```bash
cat ~/motorbike_app/backend/.env | grep CORS_ORIGIN
```

**Required value (update with current URLs):**
```
CORS_ORIGIN=http://localhost:3000,http://localhost:8080,http://localhost:4200,https://delaware-compromise-someone-cheapest.trycloudflare.com,https://motorbike-web.vercel.app,https://motorbike-pfygtbflv-silentcamxmfs-projects.vercel.app
```

If missing or incorrect, edit the file:

```bash
nano ~/motorbike_app/backend/.env
```

Add or update the line (use current Vercel/tunnel URLs):
```
CORS_ORIGIN=http://localhost:3000,http://localhost:8080,http://localhost:4200,https://delaware-compromise-someone-cheapest.trycloudflare.com,https://motorbike-web.vercel.app,https://motorbike-pfygtbflv-silentcamxmfs-projects.vercel.app
```

**Restart backend after changes:**
```bash
pm2 restart motorbike-parking-api
```

---

## 4. Test CORS Headers

After restart, test from the Pi:

```bash
curl -I -X OPTIONS https://delaware-compromise-someone-cheapest.trycloudflare.com/api/parking/nearby \
  -H "Origin: https://motorbike-pfygtbflv-silentcamxmfs-projects.vercel.app" \
  -H "Access-Control-Request-Method: GET"
```

Expected: Should see `Access-Control-Allow-Origin: https://motorbike-web.vercel.app`

---

## 5. Test API Endpoints

```bash
# Test anonymous login
curl -X POST https://delaware-compromise-someone-cheapest.trycloudflare.com/api/auth/anonymous

# Test parking zones (near Lisbon)
curl "https://delaware-compromise-someone-cheapest.trycloudflare.com/api/parking/nearby?lat=38.72&lng=-9.14&radius=10"
```

---

## 6. Update Frontend .env (if URL changed)

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
| Restart | `pm2 restart motorbike-parking-api` |
| Get tunnel URL | `pm2 logs cloudflared --lines 5 | grep trycloudflare` |
| Test API | `curl https://delaware-compromise-someone-cheapest.trycloudflare.com/api/parking/nearby?lat=38.72&lng=-9.14` |
