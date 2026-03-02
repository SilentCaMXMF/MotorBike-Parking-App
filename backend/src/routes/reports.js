const express = require('express');
const router = express.Router();
const reportController = require('../controllers/reportController');
const { validate, schemas } = require('../middleware/validation');
const { authenticateToken } = require('../middleware/auth');
const upload = require('../middleware/upload');

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
