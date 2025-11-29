#!/bin/bash

# Live Logcat Monitor for Production APK Testing
# Captures Flutter app logs with timestamps

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="debug_sessions/live_logcat_${TIMESTAMP}.log"
PACKAGE_NAME="com.example.motorbike_parking_app"

echo "=== Live Logcat Monitor Started ===" | tee "$LOG_FILE"
echo "Timestamp: $(date)" | tee -a "$LOG_FILE"
echo "Device: $(adb devices | grep device | head -1)" | tee -a "$LOG_FILE"
echo "Package: $PACKAGE_NAME" | tee -a "$LOG_FILE"
echo "Log file: $LOG_FILE" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Clear old logs
adb logcat -c

# Monitor with filters for Flutter, errors, and our app
adb logcat -v time \
  flutter:V \
  FlutterActivity:V \
  chromium:V \
  *:E \
  *:W \
  | grep -E "(flutter|$PACKAGE_NAME|ERROR|FATAL|Exception|Error)" \
  | tee -a "$LOG_FILE"
