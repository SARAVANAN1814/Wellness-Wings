const pool = require('./config/database');

const runMigration = async () => {
    try {
        await pool.query(`
            CREATE TABLE IF NOT EXISTS guardian_users (
                id SERIAL PRIMARY KEY,
                full_name VARCHAR(255) NOT NULL,
                email VARCHAR(255) UNIQUE NOT NULL,
                phone_number VARCHAR(20) NOT NULL,
                password_hash TEXT NOT NULL,
                relation VARCHAR(100),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );

            CREATE TABLE IF NOT EXISTS guardian_elderly_links (
                id SERIAL PRIMARY KEY,
                guardian_id INT REFERENCES guardian_users(id) ON DELETE CASCADE,
                elderly_id INT REFERENCES elderly_users(id) ON DELETE CASCADE,
                linked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(guardian_id, elderly_id)
            );

            CREATE TABLE IF NOT EXISTS volunteer_ratings (
                id SERIAL PRIMARY KEY,
                booking_id INT REFERENCES bookings(id) ON DELETE CASCADE,
                guardian_id INT REFERENCES guardian_users(id) ON DELETE CASCADE,
                volunteer_id INT REFERENCES volunteer_users(id) ON DELETE CASCADE,
                rating INT CHECK (rating >= 1 AND rating <= 5),
                review TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(booking_id, guardian_id)
            );

            CREATE TABLE IF NOT EXISTS guardian_notifications (
                id SERIAL PRIMARY KEY,
                guardian_id INT REFERENCES guardian_users(id) ON DELETE CASCADE,
                booking_id INT REFERENCES bookings(id) ON DELETE CASCADE,
                type VARCHAR(50),
                message TEXT,
                is_read BOOLEAN DEFAULT false,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                elderly_name VARCHAR(255),
                volunteer_name VARCHAR(255),
                service_type VARCHAR(100),
                status VARCHAR(50),
                is_emergency BOOLEAN DEFAULT false
            );
        `);
        console.log("Guardian tables created successfully!");
        process.exit(0);
    } catch (e) {
        console.error("Migration failed", e);
        process.exit(1);
    }
};

runMigration();
