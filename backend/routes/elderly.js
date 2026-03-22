const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const pool = require('../config/database');

router.post('/register', async (req, res) => {
    try {
        const {
            fullName,
            gender,
            email,
            password,
            phoneNumber,
            address
        } = req.body;

        // Hash password
        const saltRounds = 10;
        const passwordHash = await bcrypt.hash(password, saltRounds);

        // Insert user into database
        const query = `
            INSERT INTO elderly_users (
                full_name,
                gender,
                email,
                password_hash,
                phone_number,
                address
            ) VALUES ($1, $2, $3, $4, $5, $6)
            RETURNING id, full_name, email
        `;

        const values = [
            fullName,
            gender,
            email,
            passwordHash,
            phoneNumber,
            address
        ];

        const result = await pool.query(query, values);

        res.status(201).json({
            success: true,
            message: 'Registration successful',
            user: result.rows[0]
        });

    } catch (error) {
        console.error('Registration error:', error);

        if (error.constraint === 'elderly_users_email_key') {
            return res.status(400).json({
                success: false,
                message: 'Email already registered'
            });
        }

        res.status(500).json({
            success: false,
            message: 'Registration failed due to server error'
        });
    }
});

// Elderly Login
router.post('/login', async (req, res) => {
    try {
        const { phoneNumber, password } = req.body;

        if (!phoneNumber || !password) {
            return res.status(400).json({
                success: false,
                message: 'Phone number and password are required'
            });
        }

        // Query the database using phone_number
        const query = 'SELECT * FROM elderly_users WHERE phone_number = $1';
        const result = await pool.query(query, [phoneNumber]);

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
                message: 'Invalid phone number or password'
            });
        }

        // Remove sensitive data
        delete user.password_hash;

        res.json({
            success: true,
            message: 'Login successful',
            user: user
        });

    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error during login'
        });
    }
});

// GET elderly details route
router.get('/details', async (req, res) => {
    try {
        // For now, we'll get all elderly details without authentication
        // You should implement proper authentication later
        const query = `
            SELECT full_name, phone_number, address
            FROM elderly_users
            LIMIT 1
        `;

        const result = await pool.query(query);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Elderly user not found'
            });
        }

        res.json({
            success: true,
            elderly: result.rows[0]
        });

    } catch (error) {
        console.error('Error fetching elderly details:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch elderly details'
        });
    }
});

// PUT update elderly profile
router.put('/update/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const {
            fullName,
            gender,
            email,
            phoneNumber,
            address
        } = req.body;

        const query = `
            UPDATE elderly_users 
            SET full_name = $1, gender = $2, email = $3, phone_number = $4, address = $5
            WHERE id = $6
            RETURNING id, full_name, gender, email, phone_number, address
        `;
        const values = [fullName, gender, email, phoneNumber, address, id];

        const result = await pool.query(query, values);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'User not found'
            });
        }

        res.json({
            success: true,
            message: 'Profile updated successfully',
            user: result.rows[0]
        });

    } catch (error) {
        console.error('Update error:', error);
        
        if (error.constraint === 'elderly_users_email_key') {
            return res.status(400).json({
                success: false,
                message: 'Email already registered to another account'
            });
        }

        res.status(500).json({
            success: false,
            message: 'Update failed due to server error'
        });
    }
});

// GET elderly profile by ID
router.get('/profile/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const query = 'SELECT * FROM elderly_users WHERE id = $1';
        const result = await pool.query(query, [id]);

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Elderly user not found'
            });
        }

        const user = result.rows[0];
        delete user.password_hash;

        res.json({
            success: true,
            user: user
        });

    } catch (error) {
        console.error('Error fetching elderly profile:', error);
        res.status(500).json({
            success: false,
            message: 'Server error'
        });
    }
});

module.exports = router;
