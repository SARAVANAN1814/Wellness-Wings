const pool = require('./backend/config/database');
const createTable = async () => {
    try {
        await pool.query(`
            CREATE TABLE IF NOT EXISTS guardian_notifications (
                id SERIAL PRIMARY KEY,
                guardian_id INT REFERENCES guardian_users(id) ON DELETE CASCADE,
                booking_id INT REFERENCES bookings(id) ON DELETE CASCADE,
                elderly_name VARCHAR(255),
                volunteer_name VARCHAR(255),
                service_type VARCHAR(100),
                status VARCHAR(50),
                is_emergency BOOLEAN DEFAULT false,
                is_read BOOLEAN DEFAULT false,
                booking_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        `);
        console.log('guardian_notifications table created or already exists.');
        process.exit(0);
    } catch (e) {
        console.error(e);
        process.exit(1);
    }
};
createTable();
