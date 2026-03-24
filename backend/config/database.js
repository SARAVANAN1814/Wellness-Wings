const { Pool } = require('pg');

const pool = new Pool(
    process.env.DATABASE_URL
        ? {
              connectionString: process.env.DATABASE_URL,
              ssl: {
                  rejectUnauthorized: false
              }
          }
        : {
              user: 'postgres',
              host: 'localhost',
              database: 'wellness_wings',
              password: '123456789',
              port: 5432,
              timezone: 'UTC'
          }
);

pool.on('error', (err) => {
    console.error('Unexpected error on idle client', err);
    process.exit(-1);
});

module.exports = pool; 