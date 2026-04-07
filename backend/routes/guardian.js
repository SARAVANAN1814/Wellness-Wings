const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const pool = require('../config/database');

// Guardian Registration
router.post('/register', async (req, res) => {
    try {
        const { fullName, email, phoneNumber, password, relation } = req.body;

        if (!fullName || !email || !phoneNumber || !password) {
            return res.status(400).json({
                success: false,
                message: 'Full name, email, phone number, and password are required'
            });
        }

        const saltRounds = 10;
        const passwordHash = await bcrypt.hash(password, saltRounds);

        const query = `
            INSERT INTO guardian_users (full_name, email, phone_number, password_hash, relation)
            VALUES ($1, $2, $3, $4, $5)
            RETURNING id, full_name, email, phone_number, relation, created_at
        `;
        const values = [fullName.trim(), email.trim().toLowerCase(), phoneNumber.trim(), passwordHash, relation || null];

        const result = await pool.query(query, values);
        res.status(201).json({
            success: true,
            message: 'Registration successful',
            user: result.rows[0]
        });
    } catch (error) {
        console.error('Guardian registration error:', error);
        if (error.constraint === 'guardian_users_email_key') {
            return res.status(400).json({ success: false, message: 'Email already registered' });
        }
        res.status(500).json({ success: false, message: 'Registration failed due to server error' });
    }
});

// Guardian Login
router.post('/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({
                success: false,
                message: 'Email and password are required'
            });
        }

        const query = 'SELECT * FROM guardian_users WHERE email = $1';
        const result = await pool.query(query, [email.trim().toLowerCase()]);

        if (result.rows.length === 0) {
            return res.status(401).json({
                success: false,
                message: 'No user found, please register first'
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

        delete user.password_hash;
        res.json({
            success: true,
            message: 'Login successful',
            user: user
        });
    } catch (error) {
        console.error('Guardian login error:', error);
        res.status(500).json({ success: false, message: 'Login failed. Please try again.' });
    }
});

// Get Guardian Profile
router.get('/profile/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const query = 'SELECT id, full_name, email, phone_number, relation, created_at FROM guardian_users WHERE id = $1';
        const result = await pool.query(query, [id]);

        if (result.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Guardian not found' });
        }

        res.json({ success: true, user: result.rows[0] });
    } catch (error) {
        console.error('Guardian profile error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

// Update Guardian Profile
router.put('/profile/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const { fullName, email, phoneNumber, relation } = req.body;

        if (!fullName || !email || !phoneNumber) {
            return res.status(400).json({
                success: false,
                message: 'Full name, email, and phone number are required'
            });
        }

        const query = `
            UPDATE guardian_users 
            SET full_name = $1, email = $2, phone_number = $3, relation = $4, updated_at = CURRENT_TIMESTAMP
            WHERE id = $5
            RETURNING id, full_name, email, phone_number, relation, created_at, updated_at
        `;
        const values = [fullName.trim(), email.trim().toLowerCase(), phoneNumber.trim(), relation || null, id];
        const result = await pool.query(query, values);

        if (result.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Guardian not found' });
        }

        res.json({
            success: true,
            message: 'Profile updated successfully',
            user: result.rows[0]
        });
    } catch (error) {
        console.error('Guardian profile update error:', error);
        if (error.constraint === 'guardian_users_email_key') {
            return res.status(400).json({ success: false, message: 'Email already in use' });
        }
        res.status(500).json({ success: false, message: 'Failed to update profile' });
    }
});

// Change Guardian Password
router.put('/change-password/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const { currentPassword, newPassword } = req.body;

        if (!currentPassword || !newPassword) {
            return res.status(400).json({
                success: false,
                message: 'Current password and new password are required'
            });
        }

        if (newPassword.length < 6) {
            return res.status(400).json({
                success: false,
                message: 'New password must be at least 6 characters'
            });
        }

        const user = await pool.query('SELECT password_hash FROM guardian_users WHERE id = $1', [id]);
        if (user.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Guardian not found' });
        }

        const validPassword = await bcrypt.compare(currentPassword, user.rows[0].password_hash);
        if (!validPassword) {
            return res.status(401).json({ success: false, message: 'Current password is incorrect' });
        }

        const newHash = await bcrypt.hash(newPassword, 10);
        await pool.query('UPDATE guardian_users SET password_hash = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2', [newHash, id]);

        res.json({ success: true, message: 'Password changed successfully' });
    } catch (error) {
        console.error('Change password error:', error);
        res.status(500).json({ success: false, message: 'Failed to change password' });
    }
});

// Link Guardian to Elderly (by elderly phone number)
router.post('/link-elderly', async (req, res) => {
    try {
        const { guardianId, elderlyPhone } = req.body;

        if (!guardianId || !elderlyPhone) {
            return res.status(400).json({
                success: false,
                message: 'Guardian ID and elderly phone number are required'
            });
        }

        // Find elderly by phone number
        const elderlyResult = await pool.query(
            'SELECT id, full_name, phone_number FROM elderly_users WHERE phone_number = $1',
            [elderlyPhone.trim()]
        );

        if (elderlyResult.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'No elderly user found with this phone number. Please ask them to register first.'
            });
        }

        const elderly = elderlyResult.rows[0];

        // Create the link
        const linkQuery = `
            INSERT INTO guardian_elderly_links (guardian_id, elderly_id)
            VALUES ($1, $2)
            RETURNING id, guardian_id, elderly_id, linked_at
        `;
        const linkResult = await pool.query(linkQuery, [guardianId, elderly.id]);

        res.status(201).json({
            success: true,
            message: `Successfully linked to ${elderly.full_name}`,
            link: linkResult.rows[0],
            elderly: elderly
        });
    } catch (error) {
        console.error('Link elderly error:', error);
        if (error.constraint === 'guardian_elderly_links_guardian_id_elderly_id_key') {
            return res.status(400).json({
                success: false,
                message: 'This elderly person is already linked to your account'
            });
        }
        res.status(500).json({ success: false, message: 'Failed to link elderly' });
    }
});

// Unlink Guardian from Elderly
router.delete('/unlink-elderly', async (req, res) => {
    try {
        const { guardianId, elderlyId } = req.body;

        if (!guardianId || !elderlyId) {
            return res.status(400).json({
                success: false,
                message: 'Guardian ID and Elderly ID are required'
            });
        }

        const result = await pool.query(
            'DELETE FROM guardian_elderly_links WHERE guardian_id = $1 AND elderly_id = $2 RETURNING id',
            [guardianId, elderlyId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Link not found'
            });
        }

        res.json({
            success: true,
            message: 'Elderly person unlinked successfully'
        });
    } catch (error) {
        console.error('Unlink elderly error:', error);
        res.status(500).json({ success: false, message: 'Failed to unlink elderly' });
    }
});

// Get all linked elderly for a guardian
router.get('/linked-elderly/:guardianId', async (req, res) => {
    try {
        const { guardianId } = req.params;

        const query = `
            SELECT e.id, e.full_name, e.phone_number, e.address, e.gender,
                   e.latitude, e.longitude,
                   gel.linked_at
            FROM guardian_elderly_links gel
            JOIN elderly_users e ON gel.elderly_id = e.id
            WHERE gel.guardian_id = $1
            ORDER BY gel.linked_at DESC
        `;
        const result = await pool.query(query, [guardianId]);

        res.json({
            success: true,
            elderly: result.rows
        });
    } catch (error) {
        console.error('Fetch linked elderly error:', error);
        res.status(500).json({ success: false, message: 'Failed to fetch linked elderly' });
    }
});

// Get bookings for a specific elderly (for guardian view) with optional filters
router.get('/elderly-bookings/:elderlyId', async (req, res) => {
    try {
        const { elderlyId } = req.params;
        const { guardianId, status, serviceType } = req.query;

        // Verify this guardian is linked to this elderly
        if (guardianId) {
            const linkCheck = await pool.query(
                'SELECT id FROM guardian_elderly_links WHERE guardian_id = $1 AND elderly_id = $2',
                [guardianId, elderlyId]
            );
            if (linkCheck.rows.length === 0) {
                return res.status(403).json({
                    success: false,
                    message: 'You are not linked to this elderly person'
                });
            }
        }

        let query = `
            SELECT
                b.id as booking_id,
                b.volunteer_id,
                b.booking_time,
                b.status,
                b.service_type,
                b.description,
                b.is_emergency,
                v.full_name as volunteer_name,
                v.phone_number as volunteer_phone,
                v.place as volunteer_location,
                COALESCE(vr.rating, 0) as rating,
                vr.review
            FROM bookings b
            JOIN volunteer_users v ON b.volunteer_id = v.id
            LEFT JOIN volunteer_ratings vr ON vr.booking_id = b.id
            WHERE b.elderly_id = $1
        `;
        const values = [elderlyId];
        let paramIndex = 2;

        if (status && status !== 'all') {
            query += ` AND LOWER(b.status) = $${paramIndex}`;
            values.push(status.toLowerCase());
            paramIndex++;
        }

        if (serviceType) {
            query += ` AND LOWER(b.service_type) LIKE $${paramIndex}`;
            values.push(`%${serviceType.toLowerCase()}%`);
            paramIndex++;
        }

        query += ` ORDER BY b.booking_time DESC`;

        const result = await pool.query(query, values);

        // Get stats
        const statsQuery = `
            SELECT 
                COUNT(*) FILTER (WHERE LOWER(status) = 'pending' OR LOWER(status) = 'in_progress') as active,
                COUNT(*) FILTER (WHERE LOWER(status) = 'completed') as completed,
                COUNT(*) FILTER (WHERE LOWER(status) = 'cancelled') as cancelled,
                COUNT(*) as total
            FROM bookings WHERE elderly_id = $1
        `;
        const statsResult = await pool.query(statsQuery, [elderlyId]);

        res.json({
            success: true,
            bookings: result.rows,
            stats: statsResult.rows[0]
        });
    } catch (error) {
        console.error('Fetch elderly bookings error:', error);
        res.status(500).json({ success: false, message: 'Failed to fetch bookings' });
    }
});

// Cancel a booking
router.put('/cancel-booking/:bookingId', async (req, res) => {
    try {
        const { bookingId } = req.params;
        const { guardianId, reason } = req.body;

        // Verify booking exists and is cancellable
        const bookingCheck = await pool.query(
            `SELECT b.id, b.status, b.elderly_id 
             FROM bookings b 
             JOIN guardian_elderly_links gel ON gel.elderly_id = b.elderly_id 
             WHERE b.id = $1 AND gel.guardian_id = $2`,
            [bookingId, guardianId]
        );

        if (bookingCheck.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Booking not found or you do not have permission'
            });
        }

        const booking = bookingCheck.rows[0];
        if (booking.status.toLowerCase() === 'completed' || booking.status.toLowerCase() === 'cancelled') {
            return res.status(400).json({
                success: false,
                message: `Cannot cancel a ${booking.status} booking`
            });
        }

        const result = await pool.query(
            `UPDATE bookings SET status = 'cancelled', description = COALESCE(description, '') || $1 
             WHERE id = $2 RETURNING *`,
            [reason ? ` | Cancelled by guardian: ${reason}` : ' | Cancelled by guardian', bookingId]
        );

        res.json({
            success: true,
            message: 'Booking cancelled successfully',
            booking: result.rows[0]
        });
    } catch (error) {
        console.error('Cancel booking error:', error);
        res.status(500).json({ success: false, message: 'Failed to cancel booking' });
    }
});

// Rate a volunteer (after booking is completed)
router.post('/rate-volunteer', async (req, res) => {
    try {
        const { bookingId, guardianId, volunteerId, rating, review } = req.body;

        if (!bookingId || !guardianId || !volunteerId || !rating) {
            return res.status(400).json({
                success: false,
                message: 'Booking ID, Guardian ID, Volunteer ID, and rating are required'
            });
        }

        if (rating < 1 || rating > 5) {
            return res.status(400).json({
                success: false,
                message: 'Rating must be between 1 and 5'
            });
        }

        // Verify booking is completed
        const bookingCheck = await pool.query(
            'SELECT id, status FROM bookings WHERE id = $1',
            [bookingId]
        );

        if (bookingCheck.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Booking not found' });
        }

        if (bookingCheck.rows[0].status.toLowerCase() !== 'completed') {
            return res.status(400).json({
                success: false,
                message: 'Can only rate completed bookings'
            });
        }

        const result = await pool.query(
            `INSERT INTO volunteer_ratings (booking_id, guardian_id, volunteer_id, rating, review)
             VALUES ($1, $2, $3, $4, $5)
             ON CONFLICT (booking_id, guardian_id) DO UPDATE SET rating = $4, review = $5
             RETURNING *`,
            [bookingId, guardianId, volunteerId, rating, review || null]
        );

        res.json({
            success: true,
            message: 'Rating submitted successfully',
            rating: result.rows[0]
        });
    } catch (error) {
        console.error('Rate volunteer error:', error);
        res.status(500).json({ success: false, message: 'Failed to submit rating' });
    }
});

// Get volunteer average rating
router.get('/volunteer-rating/:volunteerId', async (req, res) => {
    try {
        const { volunteerId } = req.params;
        const result = await pool.query(
            `SELECT COALESCE(AVG(rating), 0) as avg_rating, COUNT(*) as total_ratings 
             FROM volunteer_ratings WHERE volunteer_id = $1`,
            [volunteerId]
        );

        res.json({
            success: true,
            avgRating: parseFloat(result.rows[0].avg_rating).toFixed(1),
            totalRatings: parseInt(result.rows[0].total_ratings)
        });
    } catch (error) {
        console.error('Get volunteer rating error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

// Get guardian dashboard stats
router.get('/dashboard-stats/:guardianId', async (req, res) => {
    try {
        const { guardianId } = req.params;

        const stats = await pool.query(`
            SELECT 
                COUNT(DISTINCT gel.elderly_id) as linked_elderly_count,
                COUNT(DISTINCT b.id) as total_bookings,
                COUNT(DISTINCT b.id) FILTER (WHERE LOWER(b.status) = 'pending' OR LOWER(b.status) = 'in_progress') as active_bookings,
                COUNT(DISTINCT b.id) FILTER (WHERE LOWER(b.status) = 'completed') as completed_bookings,
                COUNT(DISTINCT b.id) FILTER (WHERE b.is_emergency = true) as emergency_bookings,
                COUNT(DISTINCT b.id) FILTER (WHERE b.booking_time >= NOW() - INTERVAL '30 days') as bookings_this_month
            FROM guardian_elderly_links gel
            LEFT JOIN bookings b ON b.elderly_id = gel.elderly_id
            WHERE gel.guardian_id = $1
        `, [guardianId]);

        // Last booking info
        const lastBooking = await pool.query(`
            SELECT b.booking_time, b.service_type, b.status, e.full_name as elderly_name
            FROM bookings b
            JOIN elderly_users e ON b.elderly_id = e.id
            JOIN guardian_elderly_links gel ON gel.elderly_id = e.id
            WHERE gel.guardian_id = $1
            ORDER BY b.booking_time DESC
            LIMIT 1
        `, [guardianId]);

        res.json({
            success: true,
            stats: stats.rows[0],
            lastBooking: lastBooking.rows[0] || null
        });
    } catch (error) {
        console.error('Guardian stats error:', error);
        res.status(500).json({ success: false, message: 'Server error' });
    }
});

// Emergency SOS Booking (auto-selects nearest volunteer)
router.post('/emergency-booking', async (req, res) => {
    try {
        const { guardianId, elderlyId, serviceType } = req.body;

        if (!guardianId || !elderlyId) {
            return res.status(400).json({
                success: false,
                message: 'Guardian ID and Elderly ID are required'
            });
        }

        // Verify guardian is linked to this elderly
        const linkCheck = await pool.query(
            'SELECT id FROM guardian_elderly_links WHERE guardian_id = $1 AND elderly_id = $2',
            [guardianId, elderlyId]
        );
        if (linkCheck.rows.length === 0) {
            return res.status(403).json({
                success: false,
                message: 'You are not linked to this elderly person'
            });
        }

        // Get elderly location
        const elderlyResult = await pool.query(
            'SELECT id, full_name, latitude, longitude, phone_number FROM elderly_users WHERE id = $1',
            [elderlyId]
        );
        const elderly = elderlyResult.rows[0];
        const elderlyLat = parseFloat(elderly.latitude) || 0;
        const elderlyLng = parseFloat(elderly.longitude) || 0;

        // Find nearest available volunteer
        let volunteerQuery;
        let volResult;
        if (elderlyLat && elderlyLng) {
            volunteerQuery = `
                SELECT v.id, v.full_name, v.phone_number, v.place, v.price_per_hour,
                    v.latitude, v.longitude,
                    (6371 * acos(cos(radians($1)) * cos(radians(CAST(v.latitude AS DOUBLE PRECISION)))
                    * cos(radians(CAST(v.longitude AS DOUBLE PRECISION)) - radians($2))
                    + sin(radians($1)) * sin(radians(CAST(v.latitude AS DOUBLE PRECISION))))) AS distance
                FROM volunteer_users v
                WHERE v.status = 'approved'
                AND v.latitude IS NOT NULL AND v.longitude IS NOT NULL
                ORDER BY distance ASC
                LIMIT 1
            `;
            volResult = await pool.query(volunteerQuery, [elderlyLat, elderlyLng]);
        } else {
            volunteerQuery = `
                SELECT v.id, v.full_name, v.phone_number, v.place, v.price_per_hour,
                    v.latitude, v.longitude
                FROM volunteer_users v
                WHERE v.status = 'approved'
                LIMIT 1
            `;
            volResult = await pool.query(volunteerQuery);
        }

        if (volResult.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'No volunteers available right now. Please try again later.'
            });
        }

        const volunteer = volResult.rows[0];

        // Create emergency booking
        const bookingQuery = `
            INSERT INTO bookings (volunteer_id, elderly_id, service_type, description, is_emergency, status)
            VALUES ($1, $2, $3, $4, true, 'pending')
            RETURNING *
        `;
        const bookingResult = await pool.query(bookingQuery, [
            volunteer.id,
            elderlyId,
            serviceType || 'Emergency Assistance',
            `EMERGENCY SOS triggered by guardian (ID: ${guardianId}) for ${elderly.full_name}`
        ]);

        res.status(201).json({
            success: true,
            message: `Emergency booking created! ${volunteer.full_name} has been assigned.`,
            booking: bookingResult.rows[0],
            volunteer: volunteer,
            elderly: elderly
        });
    } catch (error) {
        console.error('Emergency booking error:', error);
        res.status(500).json({ success: false, message: 'Failed to create emergency booking' });
    }
});

module.exports = router;
