const mysql = require('mysql2/promise');

async function cleanup() {
  const connection = await mysql.createConnection({
    host: '127.0.0.1',
    user: 'motorbike_app',
    password: '2LXC8uW0wF7VIAycGa7l',
    database: 'motorbike_parking_app'
  });

  console.log('=== Anonymous User Cleanup ===\n');

  const [before] = await connection.execute(
    'SELECT COUNT(*) as count FROM users WHERE is_anonymous = 1'
  );
  console.log(`Anonymous users before: ${before[0].count}`);

  const [result] = await connection.execute(
    `DELETE FROM users 
     WHERE is_anonymous = 1 
     AND created_at < DATE_SUB(NOW(), INTERVAL 7 DAY)
     AND id NOT IN (
       SELECT DISTINCT user_id FROM user_reports 
       WHERE timestamp > DATE_SUB(NOW(), INTERVAL 7 DAY)
     )`
  );
  
  console.log(`Deleted: ${result.affectedRows} anonymous users`);

  const [after] = await connection.execute(
    'SELECT COUNT(*) as count FROM users WHERE is_anonymous = 1'
  );
  console.log(`Anonymous users after: ${after[0].count}`);

  const [remaining] = await connection.execute(
    `SELECT DATE(created_at) as date, COUNT(*) as count 
     FROM users WHERE is_anonymous = 1 
     GROUP BY DATE(created_at) ORDER BY date DESC LIMIT 10`
  );
  console.log('\nRemaining anonymous users by date:');
  remaining.forEach(r => console.log(`  ${r.date}: ${r.count}`));

  await connection.end();
  console.log('\n✓ Cleanup complete');
}

cleanup().catch(console.error);
