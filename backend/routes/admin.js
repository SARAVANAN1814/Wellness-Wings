const express = require('express');
const router = express.Router();
const pool = require('../config/database');

// Get all pending volunteers
router.get('/pending-volunteers', async (req, res) => {
    try {
        const query = `
            SELECT id, full_name, email, phone_number, gender, 
                   place, state, country, price_per_hour, has_experience, 
                   experience_details, id_card_path, profile_picture,
                   interview_answers, created_at, status, verification_id, id_type
            FROM volunteer_users 
            WHERE status = 'pending'
            ORDER BY created_at DESC
        `;
        const result = await pool.query(query);

        res.json({
            success: true,
            volunteers: result.rows
        });
    } catch (error) {
        console.error('Error fetching pending volunteers:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch pending volunteers'
        });
    }
});

// Approve volunteer
router.put('/approve-volunteer/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const query = `
            UPDATE volunteer_users 
            SET status = 'approved' 
            WHERE id = $1 
            RETURNING id, full_name, email, status
        `;
        const result = await pool.query(query, [id]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Volunteer not found'
            });
        }

        res.json({
            success: true,
            message: 'Volunteer approved successfully',
            volunteer: result.rows[0]
        });
    } catch (error) {
        console.error('Error approving volunteer:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to approve volunteer'
        });
    }
});

// Reject volunteer
router.put('/reject-volunteer/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const query = `
            UPDATE volunteer_users 
            SET status = 'rejected' 
            WHERE id = $1 
            RETURNING id, full_name, email, status
        `;
        const result = await pool.query(query, [id]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Volunteer not found'
            });
        }

        res.json({
            success: true,
            message: 'Volunteer rejected successfully',
            volunteer: result.rows[0]
        });
    } catch (error) {
        console.error('Error rejecting volunteer:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to reject volunteer'
        });
    }
});

module.exports = router;
