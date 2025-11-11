const { pool } = require('../config/database');

/**
 * Get nearby parking zones
 */
const getNearbyZones = async (req, res, next) => {
  try {
    const { lat, lng, radius = 5, limit = 50 } = req.query;

    if (!lat || !lng) {
      return res.status(400).json({ 
        error: 'Latitude and longitude are required' 
      });
    }

    // Call stored procedure
    const [zones] = await pool.execute(
      'CALL GetNearbyParkingZones(?, ?, ?, ?)',
      [parseFloat(lat), parseFloat(lng), parseFloat(radius), parseInt(limit)]
    );

    res.json({
      zones: zones[0], // First result set from procedure
      count: zones[0].length
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get specific parking zone
 */
const getZone = async (req, res, next) => {
  try {
    const { id } = req.params;

    const [zones] = await pool.execute(
      'SELECT * FROM parking_zone_availability WHERE id = ?',
      [id]
    );

    if (zones.length === 0) {
      return res.status(404).json({ error: 'Parking zone not found' });
    }

    res.json({ zone: zones[0] });
  } catch (error) {
    next(error);
  }
};

/**
 * Create parking zone (admin only)
 */
const createZone = async (req, res, next) => {
  try {
    const { googlePlacesId, latitude, longitude, totalCapacity } = req.body;

    const [result] = await pool.execute(
      `INSERT INTO parking_zones 
       (id, google_places_id, latitude, longitude, total_capacity, current_occupancy, confidence_score) 
       VALUES (UUID(), ?, ?, ?, ?, 0, 0.0)`,
      [googlePlacesId || null, latitude, longitude, totalCapacity]
    );

    // Get created zone
    const [zones] = await pool.execute(
      'SELECT * FROM parking_zones WHERE id = LAST_INSERT_ID()'
    );

    res.status(201).json({
      message: 'Parking zone created',
      zone: zones[0]
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Update parking zone (admin only)
 */
const updateZone = async (req, res, next) => {
  try {
    const { id } = req.params;
    const updates = req.body;

    // Build dynamic update query
    const fields = [];
    const values = [];

    if (updates.googlePlacesId !== undefined) {
      fields.push('google_places_id = ?');
      values.push(updates.googlePlacesId);
    }
    if (updates.latitude !== undefined) {
      fields.push('latitude = ?');
      values.push(updates.latitude);
    }
    if (updates.longitude !== undefined) {
      fields.push('longitude = ?');
      values.push(updates.longitude);
    }
    if (updates.totalCapacity !== undefined) {
      fields.push('total_capacity = ?');
      values.push(updates.totalCapacity);
    }

    if (fields.length === 0) {
      return res.status(400).json({ error: 'No fields to update' });
    }

    values.push(id);

    await pool.execute(
      `UPDATE parking_zones SET ${fields.join(', ')} WHERE id = ?`,
      values
    );

    // Get updated zone
    const [zones] = await pool.execute(
      'SELECT * FROM parking_zones WHERE id = ?',
      [id]
    );

    if (zones.length === 0) {
      return res.status(404).json({ error: 'Parking zone not found' });
    }

    res.json({
      message: 'Parking zone updated',
      zone: zones[0]
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getNearbyZones,
  getZone,
  createZone,
  updateZone
};
