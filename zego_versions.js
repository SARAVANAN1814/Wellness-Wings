const https = require('https');
https.get('https://pub.dev/api/packages/zego_uikit_prebuilt_call', (res) => {
  let body = '';
  res.on('data', chunk => body += chunk);
  res.on('end', () => {
    let data = JSON.parse(body);
    console.log("PREBUILT VERSIONS:", data.versions.slice(-10).map(v => v.version).join(", "));
  });
});
https.get('https://pub.dev/api/packages/zego_uikit_signaling_plugin', (res) => {
  let body = '';
  res.on('data', chunk => body += chunk);
  res.on('end', () => {
    let data = JSON.parse(body);
    console.log("SIGNALING VERSIONS:", data.versions.slice(-10).map(v => v.version).join(", "));
  });
});
