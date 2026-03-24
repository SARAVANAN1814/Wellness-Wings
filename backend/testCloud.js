const https = require('https');

const data = JSON.stringify({
  fullName: 'TestFriend',
  gender: 'Male',
  email: 'testfriend99@gmail.com',
  password: 'test123456',
  phoneNumber: '7777777777',
  address: 'Test Address Chennai'
});

const options = {
  hostname: 'wellness-wings.onrender.com',
  port: 443,
  path: '/api/elderly/register',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(data)
  }
};

const req = https.request(options, (res) => {
  let body = '';
  res.on('data', chunk => body += chunk);
  res.on('end', () => {
    console.log('STATUS:', res.statusCode);
    console.log('BODY:', body);
  });
});

req.on('error', (e) => console.error('ERROR:', e.message));
req.write(data);
req.end();
