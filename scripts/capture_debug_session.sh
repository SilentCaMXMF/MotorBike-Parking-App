#!/bin/bash

# Debug Session Capture Script for Parking Zones Fetch
# Date: $(date +%Y-%m-%d)

SESSION_FILE="DEBUG_SESSION_$(date +%Y-%m-%d_%H-%M-%S).md"

echo "=== Parking Zones Fetch Debug Session ===" | tee "$SESSION_FILE"
echo "Date: $(date)" | tee -a "$SESSION_FILE"
echo "Device: $(adb devices | grep device | head -1)" | tee -a "$SESSION_FILE"
echo "" | tee -a "$SESSION_FILE"

echo "Clearing logcat buffer..." | tee -a "$SESSION_FILE"
adb logcat -c

echo "Starting log capture..." | tee -a "$SESSION_FILE"
echo "Filtering for: MotorbikeParking|flutter" | tee -a "$SESSION_FILE"
echo "" | tee -a "$SESSION_FILE"
echo "## Log Output" | tee -a "$SESSION_FILE"
echo '```' | tee -a "$SESSION_FILE"

# Capture logs with timestamp
adb logcat -v time | grep -E "MotorbikeParking|flutter" | tee -a "$SESSION_FILE"
