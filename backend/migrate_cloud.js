const pool = require('./config/database');

async function migrateCloud() {
  const client = await pool.connect();
  try {
    console.log("Starting full cloud database initialization...");
    await client.query('BEGIN');

    // 1. Elderly Users
    await client.query(`
      CREATE TABLE IF NOT EXISTS elderly_users (
        id SERIAL PRIMARY KEY,
        full_name VARCHAR(100) NOT NULL,
        gender VARCHAR(20) NOT NULL,
        email VARCHAR(100) NOT NULL UNIQUE,
        phone_number VARCHAR(20) NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        address TEXT NOT NULL,
        latitude DOUBLE PRECISION,
        longitude DOUBLE PRECISION,
        created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `);
    console.log("- Created elderly_users table");

    // 2. Volunteer Users
    await client.query('CREATE SEQUENCE IF NOT EXISTS volunteer_users_volunteer_id_seq;');
    await client.query(`
      CREATE TABLE IF NOT EXISTS volunteer_users (
        id SERIAL PRIMARY KEY,
        volunteer_id VARCHAR(10) DEFAULT nextval('volunteer_users_volunteer_id_seq')::text UNIQUE,
        full_name VARCHAR(100) NOT NULL,
        gender VARCHAR(20) NOT NULL,
        email VARCHAR(255) UNIQUE,
        phone_number VARCHAR(20) NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        has_experience BOOLEAN NOT NULL DEFAULT false,
        experience_details TEXT,
        id_card_path TEXT,
        profile_picture TEXT,
        place VARCHAR(255),
        state VARCHAR(255),
        country VARCHAR(255),
        price_per_hour NUMERIC,
        interview_answers TEXT,
        verification_id VARCHAR(100),
        id_type VARCHAR(50),
        status VARCHAR(50) DEFAULT 'pending',
        rating NUMERIC DEFAULT 5.00,
        total_ratings INTEGER DEFAULT 0,
        latitude DOUBLE PRECISION,
        longitude DOUBLE PRECISION,
        created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `);
    console.log("- Created volunteer_users table");

    // 3. Volunteer Services
    await client.query(`
      CREATE TABLE IF NOT EXISTS volunteer_services (
        volunteer_id INTEGER NOT NULL REFERENCES volunteer_users(id) ON DELETE CASCADE,
        service_type VARCHAR(50) NOT NULL,
        is_available BOOLEAN DEFAULT false,
        updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (volunteer_id, service_type)
      );
    `);
    console.log("- Created volunteer_services table");

    // 4. Bookings
    await client.query(`
      CREATE TABLE IF NOT EXISTS bookings (
        id SERIAL PRIMARY KEY,
        volunteer_id INTEGER REFERENCES volunteer_users(id) ON DELETE CASCADE,
        elderly_id INTEGER REFERENCES elderly_users(id) ON DELETE CASCADE,
        service_type VARCHAR(100) NOT NULL,
        description TEXT,
        is_emergency BOOLEAN DEFAULT false,
        status VARCHAR(20) DEFAULT 'pending',
        booking_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        completed_at TIMESTAMP WITH TIME ZONE
      );
    `);
    console.log("- Created bookings table");

    await client.query('COMMIT');
    console.log("Cloud Database Initialization Completed Successfully!");
  } catch (error) {
    await client.query('ROLLBACK');
    console.error("Initialization Failed:", error);
  } finally {
    client.release();
    process.exit(0);
  }
}

migrateCloud();
