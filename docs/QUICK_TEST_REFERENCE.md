# Quick Test Reference - Debug Logging

## One-Command Test Setup

```bash
# Build, install, and start logging (all in one)
flutter build apk --debug && \
adb install -r build/app/outputs/flutter-apk/app-debug.apk && \
adb logcat -c && \
echo "Ready! Now launch the app and login..." && \
adb logcat -v time | grep -E "MotorbikeParking|flutter"
```

## Manual Steps (if needed)

```bash
# 1. Build APK
flutter build apk --debug

# 2. Install on device
adb install -r build/app/outputs/flutter-apk/app-debug.apk

# 3. Clear logs
adb logcat -c

# 4. Start capture
adb logcat -v time | grep -E "MotorbikeParking|flutter" | tee debug_session.log
```

## Test Actions on Device

1. Launch app
2. Login
3. Wait for map
4. Observe zones
5. Wait 30+ seconds

## Expected Log Pattern

```
MapScreen: initState
  ↓
Location permission
  ↓
Current location obtained
  ↓
Starting initial fetch
  ↓
ApiService: fetchParkingZones
  ↓
Response status: 200
  ↓
Received X zones
  ↓
Creating markers
  ↓
Setting up polling timer
  ↓
[30s later] Polling zones
```

## Quick Checks

✅ All log points present?  
✅ No errors in logs?  
✅ Zones appear on map?  
✅ Polling every 30s?

## Save Results

```bash
# Stop capture (Ctrl+C), then:
mv debug_session.log "debug_sessions/session_$(date +%Y%m%d_%H%M%S).log"
```

## Troubleshooting

**No logs?**

```bash
adb logcat | grep -i parking
```

**Device not found?**

```bash
adb kill-server && adb start-server && adb devices
```

**App crashes?**

```bash
adb logcat | grep -A 20 "FATAL"
```
