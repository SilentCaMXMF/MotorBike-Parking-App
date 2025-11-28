#!/bin/bash

# Quick Nginx Validation
# Simple validation of Nginx reverse proxy functionality

set -e

echo "=== Quick Nginx Validation ==="

DOMAIN="motorbike.local"
PASSED=0
TOTAL=0

# Function to count test
test_result() {
    local name="$1"
    local result="$2"
    local details="$3"
    
    TOTAL=$((TOTAL + 1))
    
    if [ "$result" = "PASS" ]; then
        PASSED=$((PASSED + 1))
        echo "✅ $name: $details"
    else
        echo "❌ $name: $details"
    fi
}

echo "Running validation tests..."

# Test 1: HTTP to HTTPS redirect
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://$DOMAIN" || echo "000")
if [ "$HTTP_STATUS" = "301" ]; then
    test_result "HTTP Redirect" "PASS" "Returns 301"
else
    test_result "HTTP Redirect" "FAIL" "Returns $HTTP_STATUS"
fi

# Test 2: HTTPS access
HTTPS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN" --insecure || echo "000")
if [ "$HTTPS_STATUS" = "200" ]; then
    test_result "HTTPS Access" "PASS" "Returns 200"
else
    test_result "HTTPS Access" "FAIL" "Returns $HTTPS_STATUS"
fi

# Test 3: Backend health
HEALTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN/nginx-health" --insecure || echo "000")
if [ "$HEALTH_STATUS" = "200" ]; then
    test_result "Health Endpoint" "PASS" "Returns 200"
else
    test_result "Health Endpoint" "FAIL" "Returns $HEALTH_STATUS"
fi

# Test 4: Security headers
HEADERS=$(curl -s -I "https://$DOMAIN" --insecure 2>/dev/null || echo "")
if echo "$HEADERS" | grep -qi "strict-transport-security"; then
    test_result "HSTS Header" "PASS" "Present"
else
    test_result "HSTS Header" "FAIL" "Missing"
fi

# Test 5: SSL certificate
if [ -f "/etc/ssl/certs/motorbike.crt" ]; then
    EXPIRY=$(openssl x509 -in /etc/ssl/certs/motorbike.crt -noout -enddate | cut -d= -f2)
    EPOCH_EXPIRY=$(date -d "$EXPIRY" +%s)
    EPOCH_NOW=$(date +%s)
    DAYS_LEFT=$(( ($EPOCH_EXPIRY - $EPOCH_NOW) / 86400 ))
    
    if [ $DAYS_LEFT -gt 0 ]; then
        test_result "SSL Certificate" "PASS" "Valid for $DAYS_LEFT days"
    else
        test_result "SSL Certificate" "FAIL" "Expired"
    fi
else
    test_result "SSL Certificate" "FAIL" "Not found"
fi

# Test 6: Nginx status
if systemctl is-active --quiet nginx; then
    test_result "Nginx Service" "PASS" "Running"
else
    test_result "Nginx Service" "FAIL" "Not running"
fi

# Test 7: Backend connectivity
BACKEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:3000/health" || echo "000")
if [ "$BACKEND_STATUS" = "200" ]; then
    test_result "Backend Service" "PASS" "Running"
else
    test_result "Backend Service" "FAIL" "Not accessible"
fi

# Test 8: Prometheus monitoring
if curl -s "http://localhost:9090/api/v1/status/config" >/dev/null 2>&1; then
    test_result "Prometheus" "PASS" "Running"
else
    test_result "Prometheus" "FAIL" "Not accessible"
fi

# Test 9: Node exporter
if curl -s "http://localhost:9100/metrics" >/dev/null 2>&1; then
    test_result "Node Exporter" "PASS" "Running"
else
    test_result "Node Exporter" "FAIL" "Not accessible"
fi

# Test 10: Log files
if [ -f "/var/log/nginx/access.log" ]; then
    LOG_SIZE=$(wc -l < /var/log/nginx/access.log 2>/dev/null || echo "0")
    if [ "$LOG_SIZE" -gt 0 ]; then
        test_result "Log Files" "PASS" "Being written"
    else
        test_result "Log Files" "FAIL" "Empty"
    fi
else
    test_result "Log Files" "FAIL" "Not created"
fi

echo ""
echo "=== Validation Summary ==="
echo "Total Tests: $TOTAL"
echo "Passed: $PASSED"
echo "Failed: $((TOTAL - PASSED))"
echo "Success Rate: $(( PASSED * 100 / TOTAL ))%"

if [ $PASSED -eq $TOTAL ]; then
    echo ""
    echo "🎉 All tests passed! Nginx reverse proxy is fully functional."
    exit 0
elif [ $PASSED -ge $((TOTAL - 1)) ]; then
    echo ""
    echo "✅ Most tests passed! System is operational."
    exit 0
else
    echo ""
    echo "⚠️  Several tests failed. Review results above."
    exit 1
fi