#!/usr/bin/env node

/**
 * Generate bcrypt hash for test password
 * 
 * Usage from project root:
 *   node -e "const bcrypt = require('./backend/node_modules/bcrypt'); bcrypt.hash('TestPassword123', 10, (err, hash) => { if (err) { console.error(err); process.exit(1); } console.log('Hash:', hash); });"
 * 
 * Or run this file from backend directory:
 *   cd backend && node -e "const bcrypt = require('bcrypt'); bcrypt.hash('TestPassword123', 10, (err, hash) => { if (err) { console.error(err); process.exit(1); } console.log('Generated hash:'); console.log(hash); console.log(''); console.log('Copy this hash to setup_test_data.sql'); });"
 */

const path = require('path');
const bcryptPath = path.join(__dirname, '..', 'backend', 'node_modules', 'bcrypt');

let bcrypt;
try {
  bcrypt = require(bcryptPath);
} catch (e) {
  console.error('Error: bcrypt module not found at:', bcryptPath);
  console.error('');
  console.error('Please run from backend directory:');
  console.error('  cd backend');
  console.error('  node -e "const bcrypt = require(\'bcrypt\'); bcrypt.hash(\'TestPassword123\', 10, (err, hash) => { if (err) { console.error(err); process.exit(1); } console.log(\'Hash:\', hash); });"');
  process.exit(1);
}

const password = 'TestPassword123';
const saltRounds = 10;

console.log('Generating bcrypt hash for test password...');
console.log('Password:', password);
console.log('');

bcrypt.hash(password, saltRounds, (err, hash) => {
  if (err) {
    console.error('Error generating hash:', err);
    process.exit(1);
  }

  console.log('Generated hash:');
  console.log(hash);
  console.log('');
  console.log('Copy this hash to setup_test_data.sql');
  console.log('Replace the placeholder hash in the INSERT INTO users statement');
  console.log('');
  
  // Verify the hash works
  bcrypt.compare(password, hash, (err, result) => {
    if (err) {
      console.error('Error verifying hash:', err);
      process.exit(1);
    }
    
    if (result) {
      console.log('✓ Hash verified successfully');
    } else {
      console.log('✗ Hash verification failed');
      process.exit(1);
    }
  });
});

