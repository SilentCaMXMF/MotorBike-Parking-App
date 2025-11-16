const express = require('express');
const router = express.Router();
const multer = require('multer');
const reportController = require('../controllers/reportController');
const { validate, schemas } = require('../middleware/validation');
const { authenticateToken } = require('../middleware/auth');

// Configure multer for image uploads
const upload = multer({
  dest: process.env.UPLOAD_DIR || './uploads',
  limits: { 
    fileSize: parseInt(process.env.MAX_FILE_SIZE_MB || 5) * 1024 * 1024 
  },
  fileFilter: (req, file, cb) => {
    // Only allow image files
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'), false);
    }
  }
});

// Report creation and retrieval routes
router.post('/', 
  authenticateToken, 
  validate(schemas.createReport), 
  reportController.createReport
);

router.get('/', reportController.getZoneReports);
router.get('/me', authenticateToken, reportController.getMyReports);

// Image upload route
router.post('/:reportId/images',
  authenticateToken,
  upload.single('image'),
  reportController.uploadImage
);

module.exports = router;
