# Phase 2 Backend Completion - Step-by-Step TODO

**Goal**: Complete the remaining 5% of Phase 2 Backend API  
**Estimated Time**: 4-6 hours  
**Priority**: HIGH

---

## 📋 Overview

Phase 2 is 95% complete. The remaining work consists of:

1. **Image upload endpoints** (3 tasks) - 60% of remaining work
2. **API unit tests** (2 tasks) - 40% of remaining work

---

## 🎯 TASK 1: Implement Image Upload Endpoints

### 1.1 Add Image Upload Route to Reports

**File**: `backend/src/routes/reports.js`  
**Estimated Time**: 30 minutes

**Steps**:

- [ ] Add POST route `/api/reports/:reportId/images`
- [ ] Use `multer` middleware for file upload (already installed)
- [ ] Add authentication middleware
- [ ] Add file validation (image types, size limits)
- [ ] Call controller method

**Code Template**:

```javascript
const multer = require("multer");
const upload = multer({
  dest: process.env.UPLOAD_DIR || "./uploads",
  limits: {
    fileSize: parseInt(process.env.MAX_FILE_SIZE_MB || 5) * 1024 * 1024,
  },
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith("image/")) {
      cb(null, true);
    } else {
      cb(new Error("Only image files are allowed"), false);
    }
  },
});

router.post(
  "/:reportId/images",
  authenticateToken,
  upload.single("image"),
  reportController.uploadImage
);
```

**Verification**:

- [ ] Route appears in server startup logs
- [ ] Postman/curl test with valid image succeeds
- [ ] Invalid file type returns error

---

### 1.2 Create Image Upload Controller

**File**: `backend/src/controllers/reportController.js`  
**Estimated Time**: 45 minutes

**Steps**:

- [ ] Add `uploadImage` method to reportController
- [ ] Validate reportId exists and belongs to user
- [ ] Save file to disk/storage
- [ ] Generate image URL
- [ ] Insert image record into database
- [ ] Return image URL in response

**Code Template**:

```javascript
const uploadImage = async (req, res, next) => {
  try {
    const { reportId } = req.params;
    const userId = req.user.id;
    const file = req.file;

    if (!file) {
      return res.status(400).json({ error: "No image file provided" });
    }

    // Verify report exists and belongs to user
    const [reports] = await pool.query(
      "SELECT id FROM user_reports WHERE id = ? AND user_id = ?",
      [reportId, userId]
    );

    if (reports.length === 0) {
      return res
        .status(404)
        .json({ error: "Report not found or unauthorized" });
    }

    // Generate image URL (adjust based on your storage strategy)
    const imageUrl = `/uploads/${file.filename}`;

    // Insert image record
    const [result] = await pool.query(
      "INSERT INTO report_images (id, report_id, image_url, uploaded_at) VALUES (UUID(), ?, ?, NOW())",
      [reportId, imageUrl]
    );

    res.status(201).json({
      message: "Image uploaded successfully",
      imageUrl: imageUrl,
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  // ... existing exports
  uploadImage,
};
```

**Verification**:

- [ ] Image file saved to uploads directory
- [ ] Database record created in report_images table
- [ ] Response includes valid image URL
- [ ] Unauthorized access returns 404

---

### 1.3 Add Static File Serving for Uploaded Images

**File**: `backend/src/server.js`  
**Estimated Time**: 15 minutes

**Steps**:

- [ ] Add express.static middleware for uploads directory
- [ ] Ensure uploads directory exists
- [ ] Test image access via URL

**Code Template**:

```javascript
const path = require("path");
const fs = require("fs");

// Create uploads directory if it doesn't exist
const uploadsDir = process.env.UPLOAD_DIR || "./uploads";
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

// Serve uploaded images
app.use("/uploads", express.static(uploadsDir));
```

**Verification**:

- [ ] Uploads directory created automatically
- [ ] Images accessible via http://localhost:3000/uploads/filename
- [ ] 404 for non-existent images

---

## 🧪 TASK 2: Add API Unit Tests

### 2.1 Create Authentication Tests

**File**: `backend/src/__tests__/auth.test.js` (create new)  
**Estimated Time**: 45 minutes

**Steps**:

- [ ] Create test file
- [ ] Set up test database connection
- [ ] Write tests for register endpoint
- [ ] Write tests for login endpoint
- [ ] Write tests for anonymous login endpoint
- [ ] Test JWT token validation

**Code Template**:

```javascript
const request = require("supertest");
const app = require("../server");
const { pool } = require("../config/database");

describe("Authentication Endpoints", () => {
  afterAll(async () => {
    await pool.end();
  });

  describe("POST /api/auth/register", () => {
    it("should register a new user", async () => {
      const res = await request(app)
        .post("/api/auth/register")
        .send({
          email: `test${Date.now()}@example.com`,
          password: "Test123456",
        });

      expect(res.statusCode).toBe(201);
      expect(res.body).toHaveProperty("token");
      expect(res.body).toHaveProperty("user");
    });

    it("should reject weak passwords", async () => {
      const res = await request(app).post("/api/auth/register").send({
        email: "test@example.com",
        password: "weak",
      });

      expect(res.statusCode).toBe(400);
    });
  });

  describe("POST /api/auth/login", () => {
    it("should login existing user", async () => {
      // Test implementation
    });

    it("should reject invalid credentials", async () => {
      // Test implementation
    });
  });

  describe("POST /api/auth/anonymous", () => {
    it("should create anonymous user", async () => {
      const res = await request(app).post("/api/auth/anonymous");

      expect(res.statusCode).toBe(201);
      expect(res.body).toHaveProperty("token");
      expect(res.body.user.isAnonymous).toBe(1);
    });
  });
});
```

**Verification**:

- [ ] Run `npm test` - all auth tests pass
- [ ] Test coverage for register, login, anonymous
- [ ] Edge cases covered (weak passwords, duplicates, etc.)

---

### 2.2 Create Reports & Parking Tests

**File**: `backend/src/__tests__/reports.test.js` (create new)  
**Estimated Time**: 45 minutes

**Steps**:

- [ ] Create test file
- [ ] Write tests for create report endpoint
- [ ] Write tests for get reports endpoint
- [ ] Write tests for parking zone endpoints
- [ ] Test authentication requirements

**Code Template**:

```javascript
const request = require("supertest");
const app = require("../server");
const { pool } = require("../config/database");

describe("Reports Endpoints", () => {
  let authToken;
  let testUserId;

  beforeAll(async () => {
    // Create test user and get token
    const res = await request(app).post("/api/auth/anonymous");
    authToken = res.body.token;
    testUserId = res.body.user.id;
  });

  afterAll(async () => {
    await pool.end();
  });

  describe("POST /api/reports", () => {
    it("should create a new report", async () => {
      const res = await request(app)
        .post("/api/reports")
        .set("Authorization", `Bearer ${authToken}`)
        .send({
          spotId: "test-spot-id",
          status: "available",
          availableSpots: 5,
          notes: "Test report",
        });

      expect(res.statusCode).toBe(201);
      expect(res.body).toHaveProperty("reportId");
    });

    it("should reject unauthenticated requests", async () => {
      const res = await request(app).post("/api/reports").send({
        spotId: "test-spot-id",
        status: "available",
      });

      expect(res.statusCode).toBe(401);
    });
  });

  describe("GET /api/reports", () => {
    it("should get reports for a zone", async () => {
      // Test implementation
    });
  });

  describe("GET /api/parking/nearby", () => {
    it("should return nearby parking zones", async () => {
      const res = await request(app).get("/api/parking/nearby").query({
        latitude: 38.7223,
        longitude: -9.1393,
        radius: 1000,
      });

      expect(res.statusCode).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
    });
  });
});
```

**Verification**:

- [ ] Run `npm test` - all report tests pass
- [ ] Authentication properly tested
- [ ] Database operations verified

---

## ✅ Completion Checklist

### Code Complete

- [ ] Image upload route added
- [ ] Image upload controller implemented
- [ ] Static file serving configured
- [ ] Authentication tests written
- [ ] Reports tests written

### Testing Complete

- [ ] All unit tests pass (`npm test`)
- [ ] Manual testing with Postman/curl
- [ ] Image upload tested with real files
- [ ] Error cases tested (invalid files, unauthorized, etc.)

### Documentation Complete

- [ ] Update backend/README.md with image upload endpoint
- [ ] Add API documentation for image upload
- [ ] Document test running instructions

### Deployment Ready

- [ ] Uploads directory created on server
- [ ] Environment variables documented
- [ ] File size limits configured
- [ ] Image types validated

---

## 🚀 Quick Start Commands

```bash
# Run all tests
npm test

# Run tests with coverage
npm test -- --coverage

# Test specific file
npm test auth.test.js

# Start server for manual testing
npm run dev

# Test image upload with curl
curl -X POST http://localhost:3000/api/reports/REPORT_ID/images \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "image=@/path/to/image.jpg"
```

---

## 📝 Notes

- **multer** package is already installed (check package.json)
- **supertest** and **jest** are already installed for testing
- Database schema already has `report_images` table
- File storage is local for now (can upgrade to S3/cloud later)
- Max file size default is 5MB (configurable via env)

---

## 🎯 Success Criteria

Phase 2 is complete when:

1. ✅ Image upload endpoint working and tested
2. ✅ All unit tests passing
3. ✅ Documentation updated
4. ✅ Manual testing successful
5. ✅ Code committed and pushed

**Estimated Total Time**: 4-6 hours  
**Priority**: Complete before moving to Phase 3 polish

---

_This TODO list is your guide to completing Phase 2. Check off items as you complete them!_
