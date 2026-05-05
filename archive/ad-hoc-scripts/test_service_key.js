const https = require('https');

const SUPABASE_HOST = (process.env.SUPABASE_HOST || process.env.SUPABASE_URL || '')
  .replace(/^https?:\/\//, '')
  .replace(/\/$/, '');
// 使用 Service Role Key 而不是 Publishable Key
const SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY;

if (!SUPABASE_HOST || !SERVICE_KEY) {
  console.error('Set SUPABASE_URL or SUPABASE_HOST, plus SUPABASE_SERVICE_KEY.');
  process.exit(1);
}

const options = {
  hostname: SUPABASE_HOST,
  path: '/rest/v1/reservations?limit=10',
  method: 'GET',
  headers: {
    'apikey': SERVICE_KEY,
    'Authorization': `Bearer ${SERVICE_KEY}`,
    'Content-Type': 'application/json'
  }
};

console.log('Testing with Service Role Key...\n');

const req = https.request(options, (res) => {
  let data = '';
  
  console.log('Status:', res.statusCode);
  
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    try {
      if (data && data !== '[]') {
        const records = JSON.parse(data);
        console.log(`✓ Got ${records.length} records\n`);

        // 统计日期范围
        const starts = records.map(r => new Date(r.start_date));
        const ends = records.map(r => new Date(r.end_date));
        const earliest = new Date(Math.min(...starts));
        const latest = new Date(Math.max(...ends));
        
        console.log(`📅 Data range: ${earliest.toISOString().split('T')[0]} to ${latest.toISOString().split('T')[0]}`);
        console.log(`\n📋 Sample records:`);
        console.log('Code\t\tStart\t\tEnd\t\tUnit');
        records.slice(0, 5).forEach(r => {
          console.log(`${r.code.padEnd(12)}\t${r.start_date}\t${r.end_date}\t${r.unit_name}`);
        });
        
        // 检查 4 月前的数据
        const beforeApr = records.filter(r => new Date(r.start_date) < new Date('2026-04-01'));
        console.log(`\n🔍 Records before 2026-04-01: ${beforeApr.length}`);
      } else {
        console.log('✗ Empty response - no data in reservations table');
      }
    } catch(e) {
      console.log('Error:', e.message);
      console.log('Raw response (first 200 chars):', data.substring(0, 200));
    }
  });
});

req.on('error', e => console.log('Request error:', e.message));
req.end();
