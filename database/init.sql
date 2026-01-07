CREATE TABLE elderly_users (
    id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    gender VARCHAR(20) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    address TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE bookings (
    id SERIAL PRIMARY KEY,
    volunteer_id INTEGER REFERENCES volunteer_users(id),
    elderly_id INTEGER REFERENCES elderly_users(id),
    service_type VARCHAR(100) NOT NULL,
    description TEXT,
    is_emergency BOOLEAN DEFAULT false,
    status VARCHAR(20) DEFAULT 'pending',
    booking_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Add indexes for better query performance
CREATE INDEX idx_bookings_volunteer_id ON bookings(volunteer_id);
CREATE INDEX idx_bookings_elderly_id ON bookings(elderly_id);
CREATE INDEX idx_bookings_status ON bookings(status);

-- Check and update the bookings table structure
ALTER TABLE bookings 
ALTER COLUMN volunteer_id TYPE INTEGER,
ALTER COLUMN elderly_id TYPE INTEGER,
ALTER COLUMN is_emergency TYPE BOOLEAN USING is_emergency::boolean,
ALTER COLUMN booking_date SET DEFAULT CURRENT_TIMESTAMP;

-- Add any missing columns if needed
ALTER TABLE bookings 
ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'pending',
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;