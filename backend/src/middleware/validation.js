const Joi = require('joi');

/**
 * Validation middleware factory
 */
const validate = (schema) => {
  return (req, res, next) => {
    const { error } = schema.validate(req.body, { abortEarly: false });
    
    if (error) {
      const errors = error.details.map(detail => ({
        field: detail.path.join('.'),
        message: detail.message
      }));
      
      return res.status(400).json({
        error: 'Validation failed',
        details: errors
      });
    }
    
    next();
  };
};

/**
 * Validation schemas
 */
const schemas = {
  // User registration
  register: Joi.object({
    email: Joi.string().email().required(),
    password: Joi.string().min(6).required()
      .pattern(/[A-Z]/).message('Password must contain at least one uppercase letter')
      .pattern(/[0-9]/).message('Password must contain at least one number')
  }),

  // User login
  login: Joi.object({
    email: Joi.string().email().required(),
    password: Joi.string().required()
  }),

  // Create parking zone
  createZone: Joi.object({
    googlePlacesId: Joi.string().allow(null, ''),
    latitude: Joi.number().min(-90).max(90).required(),
    longitude: Joi.number().min(-180).max(180).required(),
    totalCapacity: Joi.number().integer().min(1).required()
  }),

  // Update parking zone
  updateZone: Joi.object({
    googlePlacesId: Joi.string().allow(null, ''),
    latitude: Joi.number().min(-90).max(90),
    longitude: Joi.number().min(-180).max(180),
    totalCapacity: Joi.number().integer().min(1)
  }).min(1),

  // Create user report
  createReport: Joi.object({
    spotId: Joi.string().uuid().required(),
    reportedCount: Joi.number().integer().min(0).required(),
    userLatitude: Joi.number().min(-90).max(90).allow(null),
    userLongitude: Joi.number().min(-180).max(180).allow(null)
  })
};

module.exports = { validate, schemas };
