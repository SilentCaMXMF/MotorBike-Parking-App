#!/bin/bash

# Test API Fix - Logcat Monitor
# Date: November 17, 2025
# Purpose: Monitor logcat for API response parsing after backend fix

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="scripts/logcat_api_fix_test_${TIMESTAMP}.txt"

echo "=========================================="
echo "API Fix Test - Logcat Monitor"
echo "=========================================="
echo "Timestamp: $(date)"
echo "Log file: $LOG_FILE"
echo ""
echo "INSTRUCTIONS:"
echo "1. Make sure backend server is running on 192.168.1.67:3000"
echo "2. Open the app on your device"
echo "3. Wait for map to load (or press retry)"
echo "4. Press Ctrl+C when done"
echo ""
echo "WHAT TO LOOK FOR:"
echo "✅ SUCCESS: 'Successfully parsed X parking zones'"
echo "❌ FAILURE: 'Invalid response format: expected list'"
echo ""
echo "Starting logcat in 3 seconds..."
sleep 3

# Clear logcat buffer
adb logcat -c

echo "Monitoring logcat... (Press Ctrl+C to stop)"
echo ""

# Monitor logcat with filters for our app
adb logcat -v time \
  | grep --line-buffered "MotorbikeParking" \
  | tee "$LOG_FILE"
