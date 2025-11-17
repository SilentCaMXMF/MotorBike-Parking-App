#!/bin/bash

# analyze_logs.sh - Analyze captured logcat logs for common issues
# Usage: ./analyze_logs.sh <log_file>

LOG_FILE=${1:-"logcat.txt"}

if [ ! -f "$LOG_FILE" ]; then
    echo "Error: Log file not found: $LOG_FILE"
    echo "Usage: $0 <log_file>"
    exit 1
fi

echo "=========================================="
echo "Log Analysis Report"
echo "File: $LOG_FILE"
echo "Generated: $(date)"
echo "=========================================="

echo -e "\n=== Flutter Errors ==="
grep -i "E/flutter" "$LOG_FILE" | head -20
ERROR_COUNT=$(grep -c "E/flutter" "$LOG_FILE" 2>/dev/null || echo "0")
echo "Total Flutter errors: $ERROR_COUNT"

echo -e "\n=== Exceptions ==="
grep -i "exception" "$LOG_FILE" | head -20
EXCEPTION_COUNT=$(grep -c -i "exception" "$LOG_FILE" 2>/dev/null || echo "0")
echo "Total exceptions: $EXCEPTION_COUNT"

echo -e "\n=== Fatal Errors ==="
grep -i "fatal" "$LOG_FILE" | head -20
FATAL_COUNT=$(grep -c -i "fatal" "$LOG_FILE" 2>/dev/null || echo "0")
echo "Total fatal errors: $FATAL_COUNT"

echo -e "\n=== Network Errors ==="
grep -i "network\|http\|connection" "$LOG_FILE" | grep -i "error\|fail" | head -20
NETWORK_ERROR_COUNT=$(grep -i "network\|http\|connection" "$LOG_FILE" | grep -c -i "error\|fail" 2>/dev/null || echo "0")
echo "Total network errors: $NETWORK_ERROR_COUNT"

echo -e "\n=== Dart VM Errors ==="
grep "E/DartVM" "$LOG_FILE" | head -20
DARTVM_ERROR_COUNT=$(grep -c "E/DartVM" "$LOG_FILE" 2>/dev/null || echo "0")
echo "Total Dart VM errors: $DARTVM_ERROR_COUNT"

echo -e "\n=== Stack Traces ==="
grep -A 10 "StackTrace" "$LOG_FILE" | head -50

echo -e "\n=== Crash Summary ==="
grep -i "crash\|segfault\|signal" "$LOG_FILE" | head -20
CRASH_COUNT=$(grep -c -i "crash\|segfault\|signal" "$LOG_FILE" 2>/dev/null || echo "0")
echo "Total crashes: $CRASH_COUNT"

echo -e "\n=== Permission Errors ==="
grep -i "permission" "$LOG_FILE" | grep -i "denied\|error" | head -20
PERMISSION_ERROR_COUNT=$(grep -i "permission" "$LOG_FILE" | grep -c -i "denied\|error" 2>/dev/null || echo "0")
echo "Total permission errors: $PERMISSION_ERROR_COUNT"

echo -e "\n=== API/Backend Errors ==="
grep -i "\[Network\]" "$LOG_FILE" | grep -i "error" | head -20
API_ERROR_COUNT=$(grep -i "\[Network\]" "$LOG_FILE" | grep -c -i "error" 2>/dev/null || echo "0")
echo "Total API errors: $API_ERROR_COUNT"

echo -e "\n=========================================="
echo "Summary Statistics"
echo "=========================================="
echo "Flutter Errors:     $ERROR_COUNT"
echo "Exceptions:         $EXCEPTION_COUNT"
echo "Fatal Errors:       $FATAL_COUNT"
echo "Network Errors:     $NETWORK_ERROR_COUNT"
echo "Dart VM Errors:     $DARTVM_ERROR_COUNT"
echo "Crashes:            $CRASH_COUNT"
echo "Permission Errors:  $PERMISSION_ERROR_COUNT"
echo "API Errors:         $API_ERROR_COUNT"
echo "=========================================="

# Exit with error code if critical issues found
if [ "$FATAL_COUNT" -gt 0 ] || [ "$CRASH_COUNT" -gt 0 ]; then
    echo -e "\n⚠️  CRITICAL ISSUES DETECTED"
    exit 1
fi

echo -e "\n✓ Analysis complete"
exit 0
