const https = require('https');

// Use a real publicly accessible small receipt-like image for testing
const testImageUrl = 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/47/PNG_transparency_demonstration_1.png/280px-PNG_transparency_demonstration_1.png';

const body = JSON.stringify({
  fileUrl: testImageUrl,
  mimeType: 'image/png'
});

const SUPABASE_HOST = (process.env.SUPABASE_HOST || process.env.SUPABASE_URL || '')
  .replace(/^https?:\/\//, '')
  .replace(/\/$/, '');
const SUPABASE_KEY = process.env.SUPABASE_KEY;

if (!SUPABASE_HOST || !SUPABASE_KEY) {
  console.error('Set SUPABASE_URL or SUPABASE_HOST, plus SUPABASE_KEY.');
  process.exit(1);
}

const options = {
  hostname: SUPABASE_HOST,
  path: '/functions/v1/analyze-receipt',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${SUPABASE_KEY}`,
    'Content-Length': Buffer.byteLength(body)
  }
};

console.log('Testing deployed Edge Function...');
const req = https.request(options, (res) => {
  let data = '';
  res.on('data', c => data += c);
  res.on('end', () => {
    console.log('STATUS:', res.statusCode);
    try {
      const json = JSON.parse(data);
      if (json.error) {
        console.log('FUNCTION ERROR:', json.error);
      } else {
        console.log('SUCCESS! Result:', JSON.stringify(json, null, 2).substring(0, 300));
      }
    } catch(e) {
      console.log('RAW:', data.substring(0, 300));
    }
  });
});
req.on('error', e => console.log('ERROR:', e.message));
req.write(body);
req.end();
