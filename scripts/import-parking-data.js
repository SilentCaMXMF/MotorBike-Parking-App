#!/usr/bin/env node

/**
 * Google Places API - Parking Data Import Script
 * Fetches motorcycle/bike parking locations in Lisbon and imports to database
 */

const https = require('https');
const mysql = require('../backend/node_modules/mysql2/promise');
require('../backend/node_modules/dotenv/lib/main').config({ path: './backend/.env' });

const GOOGLE_API_KEY = process.env.GOOGLE_MAPS_API_KEY;
const LISBON_CENTER = { lat: 38.7223, lng: -9.1393 };
const SEARCH_RADIUS = 5000; // 5km radius

// Search queries to try
const SEARCH_QUERIES = [
  'motorcycle parking',
  'motorbike parking',
  'bike parking',
  'two wheeler parking',
  'moto estacionamento'
];

/**
 * Make HTTPS request to Google Places API
 */
function makeRequest(url) {
  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          reject(e);
        }
      });
    }).on('error', reject);
  });
}

/**
 * Search for places using Google Places API
 */
async function searchPlaces(query) {
  const url = `https://maps.googleapis.com/maps/api/place/textsearch/json?` +
    `query=${encodeURIComponent(query + ' Lisbon Portugal')}&` +
    `location=${LISBON_CENTER.lat},${LISBON_CENTER.lng}&` +
    `radius=${SEARCH_RADIUS}&` +
    `key=${GOOGLE_API_KEY}`;

  console.log(`\n🔍 Searching: "${query}"...`);
  
  try {
    const response = await makeRequest(url);
    
    if (response.status === 'OK') {
      console.log(`   ✓ Found ${response.results.length} results`);
      return response.results;
    } else if (response.status === 'ZERO_RESULTS') {
      console.log(`   ℹ No results found`);
      return [];
    } else {
      console.error(`   ✗ Error: ${response.status} - ${response.error_message || 'Unknown error'}`);
      return [];
    }
  } catch (error) {
    console.error(`   ✗ Request failed:`, error.message);
    return [];
  }
}

/**
 * Get place details
 */
async function getPlaceDetails(placeId) {
  const url = `https://maps.googleapis.com/maps/api/place/details/json?` +
    `place_id=${placeId}&` +
    `fields=name,formatted_address,geometry,types,rating,user_ratings_total&` +
    `key=${GOOGLE_API_KEY}`;

  try {
    const response = await makeRequest(url);
    if (response.status === 'OK') {
      return response.result;
    }
    return null;
  } catch (error) {
    console.error(`   ✗ Failed to get details for ${placeId}:`, error.message);
    return null;
  }
}

/**
 * Estimate parking capacity based on place type and ratings
 */
function estimateCapacity(place) {
  // Default capacity based on place type
  let capacity = 10;
  
  // Adjust based on ratings (more popular = likely larger)
  if (place.user_ratings_total) {
    if (place.user_ratings_total > 100) capacity = 20;
    if (place.user_ratings_total > 500) capacity = 30;
  }
  
  // Adjust based on place types
  if (place.types) {
    if (place.types.includes('parking')) capacity += 5;
    if (place.types.includes('establishment')) capacity += 3;
  }
  
  return Math.min(capacity, 50); // Cap at 50
}

/**
 * Import places to database
 */
async function importToDatabase(places) {
  console.log(`\n📊 Importing ${places.length} unique locations to database...`);
  
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    ssl: false
  });

  let imported = 0;
  let skipped = 0;
  let errors = 0;

  for (const place of places) {
    try {
      const capacity = estimateCapacity(place);
      
      await connection.execute(
        `INSERT INTO parking_zones 
         (id, google_places_id, latitude, longitude, total_capacity, current_occupancy, confidence_score, is_active) 
         VALUES (UUID(), ?, ?, ?, ?, 0, 0.0, TRUE)`,
        [
          place.place_id,
          place.geometry.location.lat,
          place.geometry.location.lng,
          capacity
        ]
      );
      
      console.log(`   ✓ Imported: ${place.name} (${capacity} spots)`);
      imported++;
      
    } catch (error) {
      if (error.code === 'ER_DUP_ENTRY') {
        console.log(`   ⊘ Skipped: ${place.name} (already exists)`);
        skipped++;
      } else {
        console.error(`   ✗ Error importing ${place.name}:`, error.message);
        errors++;
      }
    }
  }

  await connection.end();

  console.log(`\n📈 Import Summary:`);
  console.log(`   ✓ Imported: ${imported}`);
  console.log(`   ⊘ Skipped: ${skipped}`);
  console.log(`   ✗ Errors: ${errors}`);
  console.log(`   📍 Total: ${places.length}`);
}

/**
 * Main execution
 */
async function main() {
  console.log('╔════════════════════════════════════════════════════╗');
  console.log('║   Google Places - Parking Data Import             ║');
  console.log('╚════════════════════════════════════════════════════╝');
  
  if (!GOOGLE_API_KEY) {
    console.error('\n✗ Error: GOOGLE_MAPS_API_KEY not found in .env file');
    process.exit(1);
  }

  console.log(`\n📍 Search Area: Lisbon, Portugal`);
  console.log(`   Center: ${LISBON_CENTER.lat}, ${LISBON_CENTER.lng}`);
  console.log(`   Radius: ${SEARCH_RADIUS}m`);

  // Collect all places from different searches
  const allPlaces = new Map(); // Use Map to deduplicate by place_id

  for (const query of SEARCH_QUERIES) {
    const results = await searchPlaces(query);
    
    for (const place of results) {
      if (!allPlaces.has(place.place_id)) {
        allPlaces.set(place.place_id, place);
      }
    }
    
    // Small delay to avoid rate limiting
    await new Promise(resolve => setTimeout(resolve, 1000));
  }

  const uniquePlaces = Array.from(allPlaces.values());
  
  console.log(`\n✓ Found ${uniquePlaces.length} unique parking locations`);

  if (uniquePlaces.length === 0) {
    console.log('\n⚠ No parking locations found. Try different search terms or check your API key.');
    process.exit(0);
  }

  // Show preview
  console.log(`\n📋 Preview of locations found:`);
  uniquePlaces.slice(0, 5).forEach((place, i) => {
    console.log(`   ${i + 1}. ${place.name}`);
    console.log(`      ${place.formatted_address || 'No address'}`);
    console.log(`      Lat: ${place.geometry.location.lat}, Lng: ${place.geometry.location.lng}`);
  });
  
  if (uniquePlaces.length > 5) {
    console.log(`   ... and ${uniquePlaces.length - 5} more`);
  }

  // Import to database
  await importToDatabase(uniquePlaces);

  console.log(`\n✅ Import complete!`);
  console.log(`\nYou can now view these locations in your app or via:`);
  console.log(`   curl "http://localhost:3000/api/parking/nearby?lat=38.7223&lng=-9.1393&radius=10"`);
}

// Run the script
main().catch(error => {
  console.error('\n✗ Fatal error:', error);
  process.exit(1);
});
