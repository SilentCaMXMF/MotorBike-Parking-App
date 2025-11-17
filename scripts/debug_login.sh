#!/bin/bash

# Login Debugging Script for Motorbike Parking App
# This script captures logs relevant to authentication and login

LOG_FILE="login_debug_$(date +%Y%m%d_%H%M%S).txt"

echo "=== Login Debugging Session ==="
echo "Starting log capture..."
echo ""
echo "Instructions:"
echo "1. This script is now capturing logs"
echo "2. Open the app on your device"
echo "3. Try to login with your credentials"
echo "4. Press Ctrl+C when done to stop logging"
echo ""
echo "Logs will be saved to: $LOG_FILE"
echo "=========================================="
echo ""

# Clear old logs
adb logcat -c

# Capture logs and filter out system noise
# We grep for relevant patterns instead of using logcat filters
adb logcat | grep -E "flutter|MotorbikeParking|DartVM|motorbikeparking|auth|login|Network|HTTP" | tee "$LOG_FILE"
