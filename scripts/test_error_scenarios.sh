#!/bin/bash

# Test Error Scenarios Script
# This script guides through testing various error scenarios for parking zone fetch debugging

set -e

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_DIR="debug_sessions"
LOG_FILE="${LOG_DIR}/error_scenarios_${TIMESTAMP}.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Error Scenario Testing Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "This script will guide you through testing various error scenarios."
echo "Logs will be saved to: $LOG_FILE"
echo ""

# Function to wait for user confirmation
wait_for_user() {
    echo -e "${YELLOW}Press Enter when ready to continue...${NC}"
    read
}

# Function to start logcat capture
start_logcat() {
    local scenario=$1
    echo -e "${GREEN}Starting logcat capture for: $scenario${NC}"
    adb logcat -c
    adb logcat | grep -E "MotorbikeParking|flutter" > "${LOG_DIR}/${scenario}_${TIMESTAMP}.log" &
    LOGCAT_PID=$!
    echo "Logcat PID: $LOGCAT_PID"
    sleep 2
}

# Function to stop logcat capture
stop_logcat() {
    if [ ! -z "$LOGCAT_PID" ]; then
        echo -e "${GREEN}Stopping logcat capture${NC}"
        kill $LOGCAT_PID 2>/dev/null || true
        wait $LOGCAT_PID 2>/dev/null || true
        LOGCAT_PID=""
    fi
}

# Function to check device connection
check_device() {
    if ! adb devices | grep -q "device$"; then
        echo -e "${RED}Error: No device connected${NC}"
        echo "Please connect your device and enable USB debugging"
        exit 1
    fi
    echo -e "${GREEN}Device connected${NC}"
}

# Check device connection
check_device

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Scenario 1: Airplane Mode (Offline)${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Steps:"
echo "1. Enable airplane mode on your device"
echo "2. Launch the app"
echo "3. Try to log in or access the map"
echo ""
echo "Expected behavior:"
echo "- App should detect offline status"
echo "- Should show offline indicator"
echo "- Should display appropriate error message"
echo "- Logs should show connectivity status: offline"
echo ""
wait_for_user

start_logcat "scenario1_airplane_mode"
echo "Perform the test now..."
echo "When done, press Enter to stop logging"
read
stop_logcat

echo -e "${GREEN}Scenario 1 complete. Logs saved.${NC}"
echo ""

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Scenario 2: Invalid/Expired Token${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Steps:"
echo "1. Clear app data: adb shell pm clear com.pedroocalado.motorbikeparking"
echo "2. Or manually log out and modify stored token"
echo "3. Launch the app and try to access map without logging in"
echo ""
echo "Expected behavior:"
echo "- App should detect missing/invalid token"
echo "- Should show 'Authentication required' message"
echo "- Should prompt user to log in again"
echo "- Logs should show: 'Cannot start polling: No authentication token'"
echo ""
wait_for_user

echo "Clearing app data..."
adb shell pm clear com.pedroocalado.motorbikeparking
sleep 2

start_logcat "scenario2_invalid_token"
echo "Launch the app and try to access the map"
echo "When done, press Enter to stop logging"
read
stop_logcat

echo -e "${GREEN}Scenario 2 complete. Logs saved.${NC}"
echo ""

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Scenario 3: Backend 404 Error${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Steps:"
echo "1. Modify backend to return 404 for /api/parking/nearby"
echo "   OR temporarily change the endpoint in sql_service.dart"
echo "2. Rebuild and install the app"
echo "3. Log in and try to load the map"
echo ""
echo "Expected behavior:"
echo "- App should receive 404 response"
echo "- Should show 'Service endpoint not available' error"
echo "- Should display retry button"
echo "- Logs should show: 'Endpoint not found'"
echo ""
echo "Do you want to proceed with this test? (y/n)"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    wait_for_user
    start_logcat "scenario3_404_error"
    echo "Perform the test now..."
    echo "When done, press Enter to stop logging"
    read
    stop_logcat
    echo -e "${GREEN}Scenario 3 complete. Logs saved.${NC}"
else
    echo -e "${YELLOW}Scenario 3 skipped.${NC}"
fi
echo ""

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Scenario 4: Backend 500 Error${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Steps:"
echo "1. Modify backend to return 500 for /api/parking/nearby"
echo "2. Rebuild and install the app"
echo "3. Log in and try to load the map"
echo ""
echo "Expected behavior:"
echo "- App should receive 500 response"
echo "- Should show appropriate error message"
echo "- Should display retry button"
echo "- Logs should show: 'API error'"
echo ""
echo "Do you want to proceed with this test? (y/n)"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    wait_for_user
    start_logcat "scenario4_500_error"
    echo "Perform the test now..."
    echo "When done, press Enter to stop logging"
    read
    stop_logcat
    echo -e "${GREEN}Scenario 4 complete. Logs saved.${NC}"
else
    echo -e "${YELLOW}Scenario 4 skipped.${NC}"
fi
echo ""

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Scenario 5: Network Timeout${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Steps:"
echo "1. Use a network throttling tool or slow connection"
echo "2. Or modify Dio timeout settings to be very short"
echo "3. Launch the app and try to load the map"
echo ""
echo "Expected behavior:"
echo "- App should timeout after configured duration"
echo "- Should show 'Request timed out' error"
echo "- Should display retry button"
echo "- Logs should show: 'Connection timeout'"
echo ""
echo "Do you want to proceed with this test? (y/n)"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    wait_for_user
    start_logcat "scenario5_timeout"
    echo "Perform the test now..."
    echo "When done, press Enter to stop logging"
    read
    stop_logcat
    echo -e "${GREEN}Scenario 5 complete. Logs saved.${NC}"
else
    echo -e "${YELLOW}Scenario 5 skipped.${NC}"
fi
echo ""

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Scenario 6: Retry Button Functionality${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Steps:"
echo "1. Trigger any error scenario (e.g., airplane mode)"
echo "2. Verify error message and retry button appear"
echo "3. Fix the issue (e.g., disable airplane mode)"
echo "4. Tap the retry button"
echo ""
echo "Expected behavior:"
echo "- Retry button should be visible on error"
echo "- Tapping retry should restart polling"
echo "- Should successfully load zones after issue is fixed"
echo "- Logs should show new polling attempt"
echo ""
wait_for_user

start_logcat "scenario6_retry_button"
echo "Perform the test now..."
echo "When done, press Enter to stop logging"
read
stop_logcat

echo -e "${GREEN}Scenario 6 complete. Logs saved.${NC}"
echo ""

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Test Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "All test logs have been saved to: $LOG_DIR"
echo ""
echo "Log files created:"
ls -lh "${LOG_DIR}"/*_${TIMESTAMP}.log 2>/dev/null || echo "No log files found"
echo ""
echo -e "${GREEN}Testing complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Review the log files in $LOG_DIR"
echo "2. Verify each scenario produced expected logs"
echo "3. Document findings in DEBUG_SESSION document"
echo "4. Update task 9 with results"
echo ""
