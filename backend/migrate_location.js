const pool = require('./config/database');

async function migrateLocation() {
  const client = await pool.connect();
  try {
    console.log("Starting location migration...");
    await client.query('BEGIN');

    // Add latitude and longitude to elderly_users
    await client.query(`
      ALTER TABLE elderly_users 
      ADD COLUMN IF NOT EXISTS latitude DECIMAL(10, 8),
      ADD COLUMN IF NOT EXISTS longitude DECIMAL(11, 8)
    `);

    // Add latitude and longitude to volunteer_users
    await client.query(`
      ALTER TABLE volunteer_users 
      ADD COLUMN IF NOT EXISTS latitude DECIMAL(10, 8),
      ADD COLUMN IF NOT EXISTS longitude DECIMAL(11, 8)
    `);

    await client.query('COMMIT');
    console.log("Location migration completed successfully!");
  } catch (error) {
    await client.query('ROLLBACK');
    console.error("Location migration failed:", error);
  } finally {
    client.release();
    process.exit();
  }
}

migrateLocation();
