const bcrypt = require('bcrypt');
const mysql = require('mysql2/promise');
require('dotenv').config();

async function createAdmin() {
  try {
    // Hash password
    const passwordHash = await bcrypt.hash('AldegundeS', 10);
    
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
       VALUES (UUID(), 'superuser@motorbike-parking.app', ?, FALSE, TRUE, TRUE)`,
      [passwordHash]
    );

    // Get created user
    const [users] = await connection.execute(
      'SELECT id, email, is_admin, is_active, created_at FROM users WHERE email = ?',
      ['superuser@motorbike-parking.app']
    );

    console.log('✓ Admin user created successfully!');
    console.log('');
    console.log('Admin Credentials:');
    console.log('  Email: superuser@motorbike-parking.app');
    console.log('  Password: AldegundeS');
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
      console.log('  Email: superuser@motorbike-parking.app');
      console.log('  Password: AldegundeS');
    } else {
      console.error('✗ Error creating admin user:', error);
      process.exit(1);
    }
  }
}

createAdmin();
