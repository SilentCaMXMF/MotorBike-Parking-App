const { pool } = require('../config/database');

/**
 * Create user report
 */
const createReport = async (req, res, next) => {
  try {
    const { spotId, reportedCount, userLatitude, userLongitude } = req.body;
    const userId = req.user.id;

    // Call stored procedure
    const [result] = await pool.execute(
      'CALL CreateUserReport(?, ?, ?, ?, ?)',
      [spotId, userId, reportedCount, userLatitude || null, userLongitude || null]
    );

    const reportId = result[0][0].report_id;

    // Get created report
    const [reports] = await pool.execute(
      'SELECT * FROM user_reports WHERE id = ?',
      [reportId]
    );

    res.status(201).json({
      message: 'Report created successfully',
      report: reports[0]
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get reports for a specific zone
 */
const getZoneReports = async (req, res, next) => {
  try {
    const { spotId } = req.query;
    const { hours = 24 } = req.query;

    if (!spotId) {
      return res.status(400).json({ error: 'spotId is required' });
    }

    const [reports] = await pool.execute(
      `SELECT ur.*, u.email, u.is_anonymous 
       FROM user_reports ur
       JOIN users u ON ur.user_id = u.id
       WHERE ur.spot_id = ? 
       AND ur.timestamp >= DATE_SUB(NOW(), INTERVAL ? HOUR)
       ORDER BY ur.timestamp DESC`,
      [spotId, parseInt(hours)]
    );

    res.json({
      reports,
      count: reports.length
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get current user's report history
 */
const getMyReports = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { limit = 50, offset = 0 } = req.query;

    const [reports] = await pool.execute(
      `SELECT ur.*, pz.latitude as spot_latitude, pz.longitude as spot_longitude,
              pz.total_capacity, pz.current_occupancy
       FROM user_reports ur
       JOIN parking_zones pz ON ur.spot_id = pz.id
       WHERE ur.user_id = ?
       ORDER BY ur.timestamp DESC
       LIMIT ? OFFSET ?`,
      [userId, parseInt(limit), parseInt(offset)]
    );

    res.json({
      reports,
      count: reports.length
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  createReport,
  getZoneReports,
  getMyReports
};
