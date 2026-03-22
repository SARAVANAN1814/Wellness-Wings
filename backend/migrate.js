const pool = require('./config/database');

async function migrate() {
  try {
    console.log("Starting migration...");
    
    await pool.query(`ALTER TABLE volunteer_users ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'pending'`);
    await pool.query(`ALTER TABLE volunteer_users ADD COLUMN IF NOT EXISTS rating NUMERIC(3,2) DEFAULT 5.00`);
    await pool.query(`ALTER TABLE volunteer_users ADD COLUMN IF NOT EXISTS total_ratings INTEGER DEFAULT 0`);
    
    // For development, approve existing test volunteers so the app doesn't break
    await pool.query(`UPDATE volunteer_users SET status = 'approved' WHERE status = 'pending'`);
    
    console.log("Migration completed successfully!");
  } catch (error) {
    console.error("Migration failed:", error);
  } finally {
    process.exit();
  }
}

migrate();
