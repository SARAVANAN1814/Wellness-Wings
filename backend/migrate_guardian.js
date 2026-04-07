require('dotenv').config();
const pool = require('./config/database');

async function migrate() {
    const client = await pool.connect();
    try {
        await client.query('BEGIN');

        // Create guardian_users table
        await client.query(`
            CREATE TABLE IF NOT EXISTS guardian_users (
                id SERIAL PRIMARY KEY,
                full_name VARCHAR(100) NOT NULL,
                email VARCHAR(100) UNIQUE NOT NULL,
                phone_number VARCHAR(20) NOT NULL,
                password_hash VARCHAR(255) NOT NULL,
                relation VARCHAR(50),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        `);
        console.log('✅ guardian_users table created');

        // Create guardian_elderly_links table
        await client.query(`
            CREATE TABLE IF NOT EXISTS guardian_elderly_links (
                id SERIAL PRIMARY KEY,
                guardian_id INTEGER REFERENCES guardian_users(id) ON DELETE CASCADE,
                elderly_id INTEGER REFERENCES elderly_users(id) ON DELETE CASCADE,
                linked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(guardian_id, elderly_id)
            )
        `);
        console.log('✅ guardian_elderly_links table created');

        // Add indexes
        await client.query(`
            CREATE INDEX IF NOT EXISTS idx_guardian_links_guardian ON guardian_elderly_links(guardian_id);
            CREATE INDEX IF NOT EXISTS idx_guardian_links_elderly ON guardian_elderly_links(elderly_id);
        `);
        console.log('✅ Indexes created');

        await client.query('COMMIT');
        console.log('\n🎉 Guardian migration completed successfully!');
    } catch (error) {
        await client.query('ROLLBACK');
        console.error('❌ Migration failed:', error.message);
    } finally {
        client.release();
        await pool.end();
    }
}

migrate();
