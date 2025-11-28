#!/bin/bash

# Quick scenario test runner
# Usage: ./scripts/run_scenario_test.sh <scenario_number> <scenario_name>

SCENARIO_NUM=$1
SCENARIO_NAME=$2
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="debug_sessions/scenario${SCENARIO_NUM}_${SCENARIO_NAME}_${TIMESTAMP}.log"

if [ -z "$SCENARIO_NUM" ] || [ -z "$SCENARIO_NAME" ]; then
    echo "Usage: $0 <scenario_number> <scenario_name>"
    echo "Example: $0 1 airplane_mode"
    exit 1
fi

echo "========================================="
echo "Testing Scenario $SCENARIO_NUM: $SCENARIO_NAME"
echo "========================================="
echo ""
echo "Log file: $LOG_FILE"
echo ""
echo "Starting logcat capture..."

# Start logcat in background
adb logcat | grep -E "MotorbikeParking|flutter|SqlService|ApiService|connectivity" > "$LOG_FILE" &
LOGCAT_PID=$!

echo "Logcat PID: $LOGCAT_PID"
echo ""
echo "Perform your test now..."
echo "Press Enter when done to stop logging"
read

# Stop logcat
kill $LOGCAT_PID 2>/dev/null
wait $LOGCAT_PID 2>/dev/null

echo ""
echo "Log capture stopped"
echo "Log saved to: $LOG_FILE"
echo ""
echo "Quick analysis:"
echo "---------------"
echo "Error count:"
grep -i "error" "$LOG_FILE" | wc -l
echo ""
echo "Recent errors:"
grep -i "error" "$LOG_FILE" | tail -5
echo ""
