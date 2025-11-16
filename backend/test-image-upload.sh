#!/bin/bash

# Test script for image upload endpoint
# Usage: ./test-image-upload.sh

API_URL="http://192.168.1.67:3000"

echo "=== Testing Image Upload Endpoint ==="
echo ""

# Step 1: Create anonymous user and get token
echo "1. Creating anonymous user..."
AUTH_RESPONSE=$(curl -s -X POST "$API_URL/api/auth/anonymous")
TOKEN=$(echo $AUTH_RESPONSE | grep -o '"token":"[^"]*' | cut -d'"' -f4)
USER_ID=$(echo $AUTH_RESPONSE | grep -o '"id":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
    echo "❌ Failed to get authentication token"
    echo "Response: $AUTH_RESPONSE"
    exit 1
fi

echo "✅ Got token: ${TOKEN:0:20}..."
echo ""

# Step 2: Get a real parking zone ID
echo "2. Getting parking zones..."
ZONES_RESPONSE=$(curl -s "$API_URL/api/parking/nearby?latitude=38.7223&longitude=-9.1393&radius=5000")
SPOT_ID=$(echo $ZONES_RESPONSE | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)

if [ -z "$SPOT_ID" ]; then
    echo "❌ No parking zones found, using a valid UUID format"
    SPOT_ID="550e8400-e29b-41d4-a716-446655440000"
fi

echo "✅ Using spot ID: $SPOT_ID"
echo ""

# Step 3: Create a test report
echo "3. Creating test report..."
REPORT_RESPONSE=$(curl -s -X POST "$API_URL/api/reports" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"spotId\": \"$SPOT_ID\",
    \"reportedCount\": 5,
    \"userLatitude\": 38.7223,
    \"userLongitude\": -9.1393
  }")

REPORT_ID=$(echo $REPORT_RESPONSE | grep -o '"id":"[^"]*' | cut -d'"' -f4)

if [ -z "$REPORT_ID" ]; then
    echo "❌ Failed to create report"
    echo "Response: $REPORT_RESPONSE"
    exit 1
fi

echo "✅ Created report: $REPORT_ID"
echo ""

# Step 4: Create a test image file
echo "4. Creating test image..."
TEST_IMAGE="/tmp/test-parking-image.jpg"

# Create a simple 1x1 pixel JPEG (base64 encoded minimal JPEG)
echo "/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCwAA8A/9k=" | base64 -d > $TEST_IMAGE

if [ ! -f "$TEST_IMAGE" ]; then
    echo "❌ Failed to create test image"
    exit 1
fi

echo "✅ Created test image: $TEST_IMAGE"
echo ""

# Step 5: Upload image to report
echo "5. Uploading image to report..."
UPLOAD_RESPONSE=$(curl -s -X POST "$API_URL/api/reports/$REPORT_ID/images" \
  -H "Authorization: Bearer $TOKEN" \
  -F "image=@$TEST_IMAGE")

IMAGE_URL=$(echo $UPLOAD_RESPONSE | grep -o '"imageUrl":"[^"]*' | cut -d'"' -f4)

if [ -z "$IMAGE_URL" ]; then
    echo "❌ Failed to upload image"
    echo "Response: $UPLOAD_RESPONSE"
    exit 1
fi

echo "✅ Image uploaded successfully!"
echo "   Image URL: $IMAGE_URL"
echo ""

# Step 6: Verify image is accessible
echo "6. Verifying image is accessible..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL$IMAGE_URL")

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Image is accessible (HTTP $HTTP_CODE)"
else
    echo "❌ Image not accessible (HTTP $HTTP_CODE)"
    exit 1
fi

echo ""
echo "=== All Tests Passed! ==="
echo ""
echo "Summary:"
echo "  - User ID: $USER_ID"
echo "  - Report ID: $REPORT_ID"
echo "  - Image URL: $API_URL$IMAGE_URL"
echo ""

# Cleanup
rm -f $TEST_IMAGE
