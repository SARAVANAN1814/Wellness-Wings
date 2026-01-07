const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const pool = require('../config/database');

// Volunteer Registration
router.post('/register', async (req, res) => {
    try {
        const {
            full_name,
            gender,
            email,
            phone_number,
            password,
            has_experience,
            experience_details,
            id_card_path,
            profile_picture,
            place,
            state,
            country,
            price_per_hour,
            interview_answers
        } = req.body;

        // Log the request body for debugging
        console.log('Request body:', req.body);

        // Validate required fields
        if (!full_name || !gender || !email || !phone_number || !password || !place || !state || !country || price_per_hour === undefined) {
            return res.status(400).json({
                success: false,
                message: 'All required fields must be filled'
            });
        }

        // Hash password
        const saltRounds = 10;
        const password_hash = await bcrypt.hash(password, saltRounds);

        // Handle profile picture
        let profile_picture_data = null;
        if (profile_picture) {
            // Store the base64 string directly in the database
            profile_picture_data = profile_picture;
        }

        const query = `
            INSERT INTO volunteer_users 
            (full_name, gender, email, phone_number, password_hash, 
            has_experience, experience_details, id_card_path, 
            profile_picture, place, state, country, 
            price_per_hour, interview_answers) 
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14) 
            RETURNING *`;

        const values = [
            full_name,
            gender,
            email.toLowerCase(),
            phone_number,
            password_hash,
            has_experience,
            experience_details || null,
            id_card_path || null,
            profile_picture_data,
            place,
            state,
            country,
            price_per_hour,
            interview_answers ? JSON.stringify(interview_answers) : null
        ];

        const result = await pool.query(query, values);
        const user = result.rows[0];
        delete user.password_hash;

        res.status(201).json({
            success: true,
            message: 'Registration successful',
            user: user
        });

    } catch (error) {
        console.error('Registration error:', error);

        if (error.code === '23505') {
            if (error.detail?.includes('phone_number')) {
                return res.status(400).json({
                    success: false,
                    message: 'Phone number already registered'
                });
            }
            if (error.detail?.includes('email')) {
                return res.status(400).json({
                    success: false,
                    message: 'Email already registered'
                });
            }
        }

        res.status(500).json({
            success: false,
            message: 'Registration failed. Please try again later.'
        });
    }
});

// Volunteer Login
router.post('/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        // Validate input
        if (!email || !password) {
            return res.status(400).json({
                success: false,
                message: 'Email and password are required'
            });
        }

        // Check if volunteer exists with this email
        const query = 'SELECT * FROM volunteer_users WHERE email = $1';
        const result = await pool.query(query, [email.toLowerCase()]);

        if (result.rows.length === 0) {
            return res.status(401).json({
                success: false,
                message: 'Invalid email or password'
            });
        }

        const user = result.rows[0];
        const validPassword = await bcrypt.compare(password, user.password_hash);

        if (!validPassword) {
            return res.status(401).json({
                success: false,
                message: 'Invalid email or password'
            });
        }

        // Remove sensitive data before sending response
        delete user.password_hash;

        res.json({
            success: true,
            message: 'Login successful',
            user: {
                id: user.id,
                full_name: user.full_name,
                gender: user.gender,
                email: user.email,
                phone_number: user.phone_number,
                has_experience: user.has_experience,
                experience_details: user.experience_details,
                id_card_path: user.id_card_path,
                profile_picture: user.profile_picture,
                place: user.place,
                state: user.state,
                country: user.country,
                price_per_hour: user.price_per_hour,
                interview_answers: user.interview_answers
            }
        });

    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({
            success: false,
            message: 'Login failed. Please try again.'
        });
    }
});

// Get Volunteer Profile
router.get('/profile/:id', async (req, res) => {
    try {
        const { id } = req.params;

        const query = 'SELECT * FROM volunteer_users WHERE volunteer_id = $1';
        const result = await pool.query(query, [id]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Volunteer not found'
            });
        }

        const volunteer = result.rows[0];
        delete volunteer.password_hash;

        res.json({
            success: true,
            volunteer: volunteer
        });

    } catch (error) {
        console.error('Profile fetch error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch volunteer profile'
        });
    }
});

// Update Volunteer Profile
router.put('/profile/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const {
            fullName,
            gender,
            phoneNumber,
            hasExperience,
            experienceDetails,
            idCardPath
        } = req.body;

        const query = `
            UPDATE volunteer_users
            SET 
                full_name = COALESCE($1, full_name),
                gender = COALESCE($2, gender),
                phone_number = COALESCE($3, phone_number),
                has_experience = COALESCE($4, has_experience),
                experience_details = COALESCE($5, experience_details),
                id_card_path = COALESCE($6, id_card_path),
                updated_at = CURRENT_TIMESTAMP
            WHERE volunteer_id = $7
            RETURNING *
        `;

        const values = [
            fullName,
            gender,
            phoneNumber,
            hasExperience,
            experienceDetails,
            idCardPath,
            id
        ];

        const result = await pool.query(query, values);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Volunteer not found'
            });
        }

        const updatedVolunteer = result.rows[0];
        delete updatedVolunteer.password_hash;

        res.json({
            success: true,
            message: 'Profile updated successfully',
            volunteer: updatedVolunteer
        });

    } catch (error) {
        console.error('Profile update error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to update volunteer profile'
        });
    }
});

// Delete Volunteer Account
router.delete('/profile/:id', async (req, res) => {
    try {
        const { id } = req.params;

        const query = 'DELETE FROM volunteer_users WHERE volunteer_id = $1 RETURNING *';
        const result = await pool.query(query, [id]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Volunteer not found'
            });
        }

        res.json({
            success: true,
            message: 'Account deleted successfully'
        });

    } catch (error) {
        console.error('Account deletion error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to delete volunteer account'
        });
    }
});

// Get All Volunteers (for admin purposes)
router.get('/all', async (req, res) => {
    try {
        const query = 'SELECT volunteer_id, full_name, gender, phone_number, has_experience FROM volunteer_users';
        const result = await pool.query(query);

        res.json({
            success: true,
            volunteers: result.rows
        });

    } catch (error) {
        console.error('Fetch all volunteers error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch volunteers'
        });
    }
});

// Get Volunteer Services
router.get('/services/:volunteerId', async (req, res) => {
    try {
        const { volunteerId } = req.params;
        
        const query = 'SELECT service_type, is_available FROM volunteer_services WHERE volunteer_id = $1';
        const result = await pool.query(query, [volunteerId]);

        res.json({
            success: true,
            services: result.rows
        });

    } catch (error) {
        console.error('Error fetching volunteer services:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch services'
        });
    }
});

// Update Volunteer Services
router.post('/services/:volunteerId', async (req, res) => {
    const client = await pool.connect();
    try {
        const { volunteerId } = req.params;
        const { services } = req.body;

        console.log('Received volunteerId:', volunteerId);
        console.log('Received services:', services);

        // First verify the volunteer exists
        const volunteerCheck = await client.query(
            'SELECT id FROM volunteer_users WHERE id = $1',
            [volunteerId]
        );

        if (volunteerCheck.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Volunteer not found'
            });
        }

        // Begin transaction
        await client.query('BEGIN');

        // Delete existing services
        await client.query(
            'DELETE FROM volunteer_services WHERE volunteer_id = $1',
            [volunteerId]
        );

        // Insert new services
        const insertQuery = `
            INSERT INTO volunteer_services 
            (volunteer_id, service_type, is_available) 
            VALUES ($1, $2, $3)
        `;

        for (const service of services) {
            await client.query(insertQuery, [
                parseInt(volunteerId),
                service.service_type,
                service.is_available
            ]);
        }

        await client.query('COMMIT');

        res.json({
            success: true,
            message: 'Services updated successfully'
        });

    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Error updating volunteer services:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to update services: ' + error.message
        });
    } finally {
        client.release();
    }
});

// Get Available Volunteers
router.get('/available', async (req, res) => {
    try {
        const { service_type, emergency } = req.query;
        
        let query = `
            SELECT DISTINCT ON (v.id)
                v.*,
                vs.is_available,
                vs.service_type
            FROM volunteer_users v
            INNER JOIN volunteer_services vs ON v.id = vs.volunteer_id
            WHERE vs.service_type = $1 
            AND vs.is_available = true
        `;

        const params = [service_type];

        if (emergency === 'true') {
            query += ` AND v.id NOT IN (
                SELECT volunteer_id 
                FROM volunteer_services 
                WHERE service_type = 'Hospital Visit' 
                AND is_available = false
            )`;
        }

        query += ` ORDER BY v.id, v.full_name ASC`;

        const result = await pool.query(query, params);

        res.json({
            success: true,
            volunteers: result.rows.map(volunteer => ({
                ...volunteer,
                password_hash: undefined
            }))
        });

    } catch (error) {
        console.error('Error fetching available volunteers:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch volunteers'
        });
    }
});

// Get Volunteer Bookings
router.get('/bookings/:volunteerId', async (req, res) => {
    try {
        const { volunteerId } = req.params;
        
        const query = `
            SELECT 
                b.id as booking_id,
                b.booking_time,
                b.status,
                b.service_type,
                b.description,
                b.is_emergency,
                e.full_name as elderly_name,
                e.phone_number as elderly_phone,
                e.address
            FROM bookings b
            JOIN elderly_users e ON b.elderly_id = e.id
            WHERE b.volunteer_id = $1
            ORDER BY b.booking_time DESC
        `;
        
        console.log('Fetching bookings for volunteer:', volunteerId); // For debugging
        
        const result = await pool.query(query, [volunteerId]);
        
        console.log('Query result:', result.rows); // For debugging

        res.json({
            success: true,
            bookings: result.rows.map(booking => ({
                ...booking,
                booking_time: booking.booking_time.toISOString(),
            }))
        });

    } catch (error) {
        console.error('Error fetching volunteer bookings:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch bookings',
            error: error.message
        });
    }
});

// Create Booking
router.post('/bookings', async (req, res) => {
    try {
        console.log('Received booking request:', req.body);

        const {
            volunteer_id,
            elderly_id,
            service_type,
            description,
            is_emergency
        } = req.body;

        // Validate required fields
        if (!volunteer_id || !elderly_id || !service_type) {
            console.log('Missing required fields:', { volunteer_id, elderly_id, service_type });
            return res.status(400).json({
                success: false,
                message: 'Missing required fields'
            });
        }

        // Create the booking record with booking_time
        const bookingQuery = `
            INSERT INTO bookings (
                volunteer_id,
                elderly_id,
                service_type,
                description,
                is_emergency,
                status,
                booking_time
            ) VALUES ($1, $2, $3, $4, $5, $6, CURRENT_TIMESTAMP)
            RETURNING id, booking_time, status
        `;

        const bookingValues = [
            parseInt(volunteer_id),
            parseInt(elderly_id),
            service_type,
            description || '',
            Boolean(is_emergency),
            'pending'
        ];

        console.log('Executing query with values:', bookingValues);

        const bookingResult = await pool.query(bookingQuery, bookingValues);
        
        console.log('Booking created:', bookingResult.rows[0]);

        res.status(201).json({
            success: true,
            message: 'Booking created successfully',
            booking: bookingResult.rows[0]
        });

    } catch (error) {
        console.error('Error creating booking:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to create booking: ' + error.message,
            error: error.stack
        });
    }
});

router.put('/bookings/:id/status', async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;

        const updateQuery = `
            UPDATE bookings 
            SET status = $1, 
                completed_at = CASE 
                    WHEN $1 = 'completed' THEN CURRENT_TIMESTAMP 
                    ELSE completed_at 
                END
            WHERE id = $2 
            RETURNING *
        `;

        const result = await pool.query(updateQuery, [status, id]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Booking not found'
            });
        }

        res.json({
            success: true,
            message: 'Booking status updated successfully',
            booking: result.rows[0]
        });

    } catch (error) {
        console.error('Error updating booking status:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to update booking status',
            error: error.message
        });
    }
});

module.exports = router; 
