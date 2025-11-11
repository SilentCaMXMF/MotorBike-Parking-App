/**
 * Global error handling middleware
 */
const errorHandler = (err, req, res, next) => {
  console.error('Error:', err);

  // Default error
  let status = err.status || 500;
  let message = err.message || 'Internal server error';

  // MySQL errors
  if (err.code === 'ER_DUP_ENTRY') {
    status = 409;
    message = 'Resource already exists';
  } else if (err.code === 'ER_NO_REFERENCED_ROW_2') {
    status = 404;
    message = 'Referenced resource not found';
  }

  // JWT errors
  if (err.name === 'JsonWebTokenError') {
    status = 401;
    message = 'Invalid token';
  } else if (err.name === 'TokenExpiredError') {
    status = 401;
    message = 'Token expired';
  }

  // Multer errors (file upload)
  if (err.name === 'MulterError') {
    status = 400;
    if (err.code === 'LIMIT_FILE_SIZE') {
      message = `File too large. Maximum size is ${process.env.MAX_FILE_SIZE_MB}MB`;
    } else {
      message = 'File upload error';
    }
  }

  res.status(status).json({
    error: message,
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
};

/**
 * 404 handler
 */
const notFound = (req, res) => {
  res.status(404).json({
    error: 'Route not found',
    path: req.originalUrl
  });
};

module.exports = { errorHandler, notFound };
