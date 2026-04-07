const express = require('express');
const router = express.Router();
const pool = require('../config/database');

// Get notifications for a guardian (booking status changes for linked elderly)
router.get('/:guardianId', async (req, res) => {
    try {
        const { guardianId } = req.params;
        const { since, type } = req.query; // type: 'emergency', 'booking', 'all'

        let query = `
            SELECT
                b.id as booking_id,
                b.status,
                b.service_type,
                b.is_emergency,
                b.booking_time,
                b.updated_at,
                e.full_name as elderly_name,
                e.id as elderly_id,
                v.full_name as volunteer_name,
                v.phone_number as volunteer_phone,
                CASE WHEN nr.id IS NOT NULL THEN true ELSE false END as is_read
            FROM bookings b
            JOIN elderly_users e ON b.elderly_id = e.id
            JOIN volunteer_users v ON b.volunteer_id = v.id
            JOIN guardian_elderly_links gel ON gel.elderly_id = e.id
            LEFT JOIN notification_reads nr ON nr.booking_id = b.id AND nr.guardian_id = gel.guardian_id
            WHERE gel.guardian_id = $1
        `;
        const values = [guardianId];
        let paramIndex = 2;

        if (since) {
            query += ` AND b.booking_time >= $${paramIndex}`;
            values.push(since);
            paramIndex++;
        }

        if (type === 'emergency') {
            query += ` AND b.is_emergency = true`;
        } else if (type === 'booking') {
            query += ` AND (b.is_emergency = false OR b.is_emergency IS NULL)`;
        }

        query += ` ORDER BY b.booking_time DESC LIMIT 50`;

        const result = await pool.query(query, values);

        res.json({
            success: true,
            notifications: result.rows,
            count: result.rows.length
        });
    } catch (error) {
        console.error('Fetch notifications error:', error);
        res.status(500).json({ success: false, message: 'Failed to fetch notifications' });
    }
});

// Get unread count (bookings in last 24 hours that haven't been read)
router.get('/count/:guardianId', async (req, res) => {
    try {
        const { guardianId } = req.params;

        const query = `
            SELECT COUNT(*) as count
            FROM bookings b
            JOIN guardian_elderly_links gel ON gel.elderly_id = b.elderly_id
            LEFT JOIN notification_reads nr ON nr.booking_id = b.id AND nr.guardian_id = gel.guardian_id
            WHERE gel.guardian_id = $1
            AND b.booking_time >= NOW() - INTERVAL '24 hours'
            AND nr.id IS NULL
        `;
        const result = await pool.query(query, [guardianId]);

        res.json({
            success: true,
            count: parseInt(result.rows[0].count)
        });
    } catch (error) {
        console.error('Notification count error:', error);
        res.status(500).json({ success: false, count: 0 });
    }
});

// Mark notification as read
router.post('/mark-read', async (req, res) => {
    try {
        const { guardianId, bookingId } = req.body;

        if (!guardianId || !bookingId) {
            return res.status(400).json({
                success: false,
                message: 'Guardian ID and Booking ID are required'
            });
        }

        await pool.query(
            `INSERT INTO notification_reads (guardian_id, booking_id) 
             VALUES ($1, $2) ON CONFLICT (guardian_id, booking_id) DO NOTHING`,
            [guardianId, bookingId]
        );

        res.json({ success: true, message: 'Notification marked as read' });
    } catch (error) {
        console.error('Mark read error:', error);
        res.status(500).json({ success: false, message: 'Failed to mark as read' });
    }
});

// Mark all notifications as read
router.post('/mark-all-read', async (req, res) => {
    try {
        const { guardianId } = req.body;

        if (!guardianId) {
            return res.status(400).json({
                success: false,
                message: 'Guardian ID is required'
            });
        }

        // Get all unread booking IDs for this guardian
        const unread = await pool.query(`
            SELECT b.id as booking_id
            FROM bookings b
            JOIN guardian_elderly_links gel ON gel.elderly_id = b.elderly_id
            LEFT JOIN notification_reads nr ON nr.booking_id = b.id AND nr.guardian_id = gel.guardian_id
            WHERE gel.guardian_id = $1 AND nr.id IS NULL
        `, [guardianId]);

        for (const row of unread.rows) {
            await pool.query(
                `INSERT INTO notification_reads (guardian_id, booking_id) 
                 VALUES ($1, $2) ON CONFLICT (guardian_id, booking_id) DO NOTHING`,
                [guardianId, row.booking_id]
            );
        }

        res.json({
            success: true,
            message: 'All notifications marked as read',
            count: unread.rows.length
        });
    } catch (error) {
        console.error('Mark all read error:', error);
        res.status(500).json({ success: false, message: 'Failed to mark all as read' });
    }
});

module.exports = router;
