#!/bin/bash

# Quick restart script for the backend server
# This matches your existing setup

echo "Killing any existing node processes..."
pkill -9 node 2>/dev/null

echo "Waiting for processes to stop..."
sleep 2

echo "Starting server from ~/motorbike_app..."
cd ~/motorbike_app && nohup node src/server.js > server.log 2>&1 &

echo "Waiting for server to start..."
sleep 3

echo ""
echo "✅ Server restarted!"
echo ""
echo "Testing API endpoint..."
curl -s "http://192.168.1.67:3000/api/parking/nearby?lat=38.7214&lng=-9.1350&radius=5&limit=1" | jq '.' 2>/dev/null || curl -s "http://192.168.1.67:3000/api/parking/nearby?lat=38.7214&lng=-9.1350&radius=5&limit=1"

echo ""
echo "Check for 'data' key in response above (not 'zones')"
