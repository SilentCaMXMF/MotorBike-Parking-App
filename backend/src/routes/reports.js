const express = require('express');
const router = express.Router();
const reportController = require('../controllers/reportController');
const { validate, schemas } = require('../middleware/validation');
const { authenticateToken } = require('../middleware/auth');

// All report routes require authentication
router.post('/', 
  authenticateToken, 
  validate(schemas.createReport), 
  reportController.createReport
);

router.get('/', reportController.getZoneReports);
router.get('/me', authenticateToken, reportController.getMyReports);

module.exports = router;
