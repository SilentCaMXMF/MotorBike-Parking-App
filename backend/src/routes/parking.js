const express = require('express');
const router = express.Router();
const parkingController = require('../controllers/parkingController');
const { validate, schemas } = require('../middleware/validation');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

// Public routes (with optional auth)
router.get('/nearby', parkingController.getNearbyZones);
router.get('/:id', parkingController.getZone);

// Admin routes
router.post('/', 
  authenticateToken, 
  requireAdmin, 
  validate(schemas.createZone), 
  parkingController.createZone
);

router.put('/:id', 
  authenticateToken, 
  requireAdmin, 
  validate(schemas.updateZone), 
  parkingController.updateZone
);

module.exports = router;
