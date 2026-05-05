const https = require('https');

const SUPABASE_HOST = (process.env.SUPABASE_HOST || process.env.SUPABASE_URL || '')
  .replace(/^https?:\/\//, '')
  .replace(/\/$/, '');
const API_KEY = process.env.SUPABASE_KEY;

if (!SUPABASE_HOST || !API_KEY) {
  console.error('Set SUPABASE_URL or SUPABASE_HOST, plus SUPABASE_KEY.');
  process.exit(1);
}

const options = {
  hostname: SUPABASE_HOST,
  path: '/rest/v1/reservations?start_date=lt.2026-04-01&select=*&order=start_date.asc&limit=100',
  method: 'GET',
  headers: {
    'apikey': API_KEY,
    'Authorization': `Bearer ${API_KEY}`,
    'Content-Type': 'application/json'
  }
};

console.log('Querying reservations before 2026-04-01...\n');

const req = https.request(options, (res) => {
  let data = '';
  console.log('Status:', res.statusCode);
  
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    try {
      const records = JSON.parse(data);
      
      if (Array.isArray(records) && records.length > 0) {
        console.log(`✓ Total records before 2026-04-01: ${records.length}\n`);
        
        // 提取日期
        const dates = records.map(r => ({
          code: r.code,
          start_date: r.start_date,
          end_date: r.end_date,
          unit_name: r.unit_name
        }));
        
        // 统计
        const startDates = records.map(r => new Date(r.start_date));
        const endDates = records.map(r => new Date(r.end_date));
        const earliest = new Date(Math.min(...startDates));
        const latest = new Date(Math.max(...endDates));
        
        // 统计月份
        const monthsSet = new Set();
        records.forEach(r => {
          const d = new Date(r.start_date);
          monthsSet.add(`${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}`);
        });
        
        console.log(`📅 Date range: ${earliest.toISOString().split('T')[0]} to ${latest.toISOString().split('T')[0]}`);
        console.log(`📊 Months involved: ${monthsSet.size}`);
        console.log(`📍 Months: ${Array.from(monthsSet).sort().join(', ')}\n`);
        
        console.log('📋 First 10 records:');
        console.log('Code\tStart Date\tEnd Date\tUnit');
        console.log('─'.repeat(80));
        dates.slice(0, 10).forEach(r => {
          console.log(`${r.code}\t${r.start_date}\t${r.end_date}\t${r.unit_name}`);
        });
        
        if (records.length > 10) {
          console.log(`\n... and ${records.length - 10} more records`);
        }
      } else {
        console.log('No records found before 2026-04-01');
      }
    } catch(e) {
      console.log('Error parsing response:', e.message);
      console.log('Raw response:', data.substring(0, 500));
    }
  });
});

req.on('error', e => console.log('Request error:', e.message));
req.end();
