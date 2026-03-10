const bcrypt = require('bcrypt');
const mysql = require('mysql2/promise');
const readline = require('readline');
require('dotenv').config();

// Password validation function
function validatePassword(password) {
  if (!password || password.length < 8) {
    return { valid: false, message: 'Password must be at least 8 characters long' };
  }
  if (!/[A-Z]/.test(password)) {
    return { valid: false, message: 'Password must contain at least one uppercase letter' };
  }
  if (!/[a-z]/.test(password)) {
    return { valid: false, message: 'Password must contain at least one lowercase letter' };
  }
  if (!/[0-9]/.test(password)) {
    return { valid: false, message: 'Password must contain at least one number' };
  }
  return { valid: true, message: 'Password is valid' };
}

// Interactive password input function
function getPasswordInteractively() {
  return new Promise((resolve) => {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });

    console.log('Please enter admin password:');
    console.log('Requirements: 8+ characters, uppercase, lowercase, and numbers');
    
    rl.question('Password: ', (password) => {
      rl.close();
      resolve(password);
    });
  });
}

async function getAdminCredentials() {
  let email = process.env.ADMIN_EMAIL;
  let password = process.env.ADMIN_PASSWORD;

  // If email not provided, use default
  if (!email) {
    email = 'superuser@motorbike-parking.app';
    console.log('⚠ ADMIN_EMAIL not set, using default: superuser@motorbike-parking.app');
  }

  // If password not provided, get it interactively
  if (!password) {
    console.log('⚠ ADMIN_PASSWORD not set in environment variables');
    password = await getPasswordInteractively();
  }

  return { email, password };
}

async function createAdmin() {
  try {
    // Validate database connection parameters
    const requiredDbParams = ['DB_HOST', 'DB_PORT', 'DB_USER', 'DB_PASSWORD', 'DB_NAME'];
    const missingDbParams = requiredDbParams.filter(param => !process.env[param]);
    
    if (missingDbParams.length > 0) {
      console.error('✗ Missing required database environment variables:');
      missingDbParams.forEach(param => console.error(`  - ${param}`));
      process.exit(1);
    }

    // Get admin credentials
    const { email, password } = await getAdminCredentials();

    // Validate password
    const passwordValidation = validatePassword(password);
    if (!passwordValidation.valid) {
      console.error(`✗ Password validation failed: ${passwordValidation.message}`);
      process.exit(1);
    }

    console.log('Creating admin user...');
    
    // Hash password
    const passwordHash = await bcrypt.hash(password, 10);
    
    // Connect to database
    const connection = await mysql.createConnection({
      host: process.env.DB_HOST,
      port: process.env.DB_PORT,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME,
      ssl: false
    });

    // Create admin user
    const [result] = await connection.execute(
      `INSERT INTO users (id, email, password_hash, is_anonymous, is_admin, is_active) 
       VALUES (UUID(), ?, ?, FALSE, TRUE, TRUE)`,
      [email, passwordHash]
    );

    // Get created user
    const [users] = await connection.execute(
      'SELECT id, email, is_admin, is_active, created_at FROM users WHERE email = ?',
      [email]
    );

    console.log('✓ Admin user created successfully!');
    console.log('');
    console.log('Admin Credentials:');
    console.log(`  Email: ${email}`);
    console.log('  Password: [REDACTED]');
    console.log('  Is Admin: true');
    console.log('');
    console.log('User Details:');
    console.log(users[0]);

    await connection.end();
  } catch (error) {
    if (error.code === 'ER_DUP_ENTRY') {
      console.log('⚠ Admin user already exists!');
      console.log('');
      console.log('Admin Credentials:');
      const email = process.env.ADMIN_EMAIL || 'superuser@motorbike-parking.app';
      console.log(`  Email: ${email}`);
      console.log('  Password: [REDACTED]');
    } else {
      console.error('✗ Error creating admin user:', error.message);
      if (error.code) {
        console.error(`  Error Code: ${error.code}`);
      }
      process.exit(1);
    }
  }
}

createAdmin();
