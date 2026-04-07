require('dotenv').config();
const pool = require('./config/database');

async function migrate() {
    const client = await pool.connect();
    try {
        await client.query('BEGIN');

        // Create volunteer_ratings table
        await client.query(`
            CREATE TABLE IF NOT EXISTS volunteer_ratings (
                id SERIAL PRIMARY KEY,
                booking_id INTEGER REFERENCES bookings(id) ON DELETE CASCADE,
                guardian_id INTEGER REFERENCES guardian_users(id) ON DELETE CASCADE,
                volunteer_id INTEGER REFERENCES volunteer_users(id) ON DELETE CASCADE,
                rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
                review TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(booking_id, guardian_id)
            )
        `);
        console.log('✅ volunteer_ratings table created');

        // Create notification_reads table for read/unread tracking
        await client.query(`
            CREATE TABLE IF NOT EXISTS notification_reads (
                id SERIAL PRIMARY KEY,
                guardian_id INTEGER REFERENCES guardian_users(id) ON DELETE CASCADE,
                booking_id INTEGER REFERENCES bookings(id) ON DELETE CASCADE,
                read_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(guardian_id, booking_id)
            )
        `);
        console.log('✅ notification_reads table created');

        // Add updated_at column to guardian_users if not exists
        await client.query(`
            ALTER TABLE guardian_users 
            ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        `);
        console.log('✅ updated_at column added to guardian_users');

        // Add indexes
        await client.query(`
            CREATE INDEX IF NOT EXISTS idx_ratings_volunteer ON volunteer_ratings(volunteer_id);
            CREATE INDEX IF NOT EXISTS idx_ratings_booking ON volunteer_ratings(booking_id);
            CREATE INDEX IF NOT EXISTS idx_notif_reads_guardian ON notification_reads(guardian_id);
        `);
        console.log('✅ Indexes created');

        await client.query('COMMIT');
        console.log('\n🎉 Improvements migration completed successfully!');
    } catch (error) {
        await client.query('ROLLBACK');
        console.error('❌ Migration failed:', error.message);
    } finally {
        client.release();
        await pool.end();
    }
}

migrate();
