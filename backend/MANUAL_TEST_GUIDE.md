# Manual Testing Guide - Image Upload

## Prerequisites

- Server running on Raspberry Pi at http://192.168.1.67:3000
- curl or Postman installed

## Option 1: Automated Test Script

```bash
# On your local machine
./backend/test-image-upload.sh
```

This will automatically:

1. Create an anonymous user
2. Create a test report
3. Upload a test image
4. Verify the image is accessible

## Option 2: Manual Testing with curl

### Step 1: Get Authentication Token

```bash
# Create anonymous user
curl -X POST http://192.168.1.67:3000/api/auth/anonymous

# Save the token from response
TOKEN="your_token_here"
```

### Step 2: Create a Test Report

```bash
curl -X POST http://192.168.1.67:3000/api/reports \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "spotId": "test-spot-123",
    "reportedCount": 5,
    "userLatitude": 38.7223,
    "userLongitude": -9.1393
  }'

# Save the report ID from response
REPORT_ID="your_report_id_here"
```

### Step 3: Upload an Image

```bash
# Upload an image file
curl -X POST http://192.168.1.67:3000/api/reports/$REPORT_ID/images \
  -H "Authorization: Bearer $TOKEN" \
  -F "image=@/path/to/your/image.jpg"
```

### Step 4: Verify Image is Accessible

```bash
# Get the imageUrl from the upload response
# Then access it in browser or with curl
curl http://192.168.1.67:3000/uploads/filename.jpg
```

## Option 3: Restart Server on Raspberry Pi

If you need to restart the server manually:

```bash
# SSH into Raspberry Pi
ssh pedroocalado@192.168.1.67

# Stop existing server
pkill -9 node

# Start server
cd ~/motorbike_app
node src/server.js

# Or run in background
nohup node src/server.js > server.log 2>&1 &

# Check logs
tail -f server.log
```

## Expected Results

### Successful Upload Response:

```json
{
  "message": "Image uploaded successfully",
  "imageUrl": "/uploads/abc123.jpg",
  "filename": "abc123.jpg"
}
```

### Error Cases:

**No file provided:**

```json
{
  "error": "No image file provided"
}
```

**Wrong file type:**

```json
{
  "error": "Only image files are allowed"
}
```

**Report not found:**

```json
{
  "error": "Report not found or you do not have permission to add images to this report"
}
```

**Unauthorized:**

```json
{
  "error": "No token provided"
}
```

## Verification Checklist

- [ ] Server starts without errors
- [ ] Uploads directory created automatically
- [ ] Anonymous user creation works
- [ ] Report creation works
- [ ] Image upload succeeds with valid image
- [ ] Image upload fails with non-image file
- [ ] Image upload fails without authentication
- [ ] Image upload fails for non-existent report
- [ ] Uploaded image is accessible via URL
- [ ] Image file exists in uploads directory

## Troubleshooting

### Server won't start

- Check if port 3000 is already in use: `lsof -i :3000`
- Kill existing process: `pkill -9 node`

### Upload fails

- Check file permissions on uploads directory
- Verify multer is installed: `npm list multer`
- Check server logs for errors

### Image not accessible

- Verify static file serving is configured
- Check uploads directory path
- Verify file was actually saved

## Next Steps

After successful testing:

1. ✅ Mark Task 1 as complete
2. Move to Task 2: API Unit Tests
3. Update documentation
