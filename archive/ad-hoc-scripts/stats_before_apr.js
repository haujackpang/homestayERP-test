const https = require('https');

const SUPABASE_HOST = (process.env.SUPABASE_HOST || process.env.SUPABASE_URL || '')
  .replace(/^https?:\/\//, '')
  .replace(/\/$/, '');
const SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY;

if (!SUPABASE_HOST || !SERVICE_KEY) {
  console.error('Set SUPABASE_URL or SUPABASE_HOST, plus SUPABASE_SERVICE_KEY.');
  process.exit(1);
}

const options = {
  hostname: SUPABASE_HOST,
  path: '/rest/v1/reservations?start_date=lt.2026-04-01&select=*&limit=5000',
  method: 'GET',
  headers: {
    'apikey': SERVICE_KEY,
    'Authorization': `Bearer ${SERVICE_KEY}`,
    'Content-Type': 'application/json'
  }
};

console.log('Fetching all records before 2026-04-01...\n');

const req = https.request(options, (res) => {
  let data = '';
  
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    try {
      const records = JSON.parse(data);
      
      console.log(`✓ Total records before 2026-04-01: ${records.length}\n`);
      
      // 统计
      const starts = records.map(r => new Date(r.start_date));
      const ends = records.map(r => new Date(r.end_date));
      const earliest = new Date(Math.min(...starts));
      const latest = new Date(Math.max(...ends));
      
      // 按月份统计
      const monthMap = {};
      records.forEach(r => {
        const d = new Date(r.start_date);
        const month = `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}`;
        monthMap[month] = (monthMap[month] || 0) + 1;
      });
      
      console.log(`📅 Date range: ${earliest.toISOString().split('T')[0]} to ${latest.toISOString().split('T')[0]}`);
      console.log(`📊 Months covered:`);
      Object.keys(monthMap).sort().forEach(m => {
        console.log(`   ${m}: ${monthMap[m]} records`);
      });
      
      console.log(`\n📍 Unit distribution (top 10):`);
      const unitMap = {};
      records.forEach(r => {
        const u = r.unit_name || 'unmapped';
        unitMap[u] = (unitMap[u] || 0) + 1;
      });
      Object.entries(unitMap)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 10)
        .forEach(([unit, count]) => {
          console.log(`   ${unit || '(unnamed)'}: ${count}`);
        });
      
      console.log(`\n🎯 Booking status distribution:`);
      const statusMap = {};
      records.forEach(r => {
        const s = r.booking_status || 'unknown';
        statusMap[s] = (statusMap[s] || 0) + 1;
      });
      Object.entries(statusMap).forEach(([status, count]) => {
        console.log(`   ${status}: ${count}`);
      });
      
      console.log(`\n💰 Revenue summary:`);
      const totalRental = records.reduce((sum, r) => sum + (r.rental || 0), 0);
      const totalExtra = records.reduce((sum, r) => sum + (r.extra_guest || 0), 0);
      console.log(`   Total rental charges: RM ${totalRental.toFixed(2)}`);
      console.log(`   Total extra guest charges: RM ${totalExtra.toFixed(2)}`);
      console.log(`   Combined: RM ${(totalRental + totalExtra).toFixed(2)}`);
      
      console.log(`\n📋 First 5 records:`);
      console.log('Code\t\t\tStart\t\tEnd\t\tUnit\t\tRental');
      records.slice(0, 5).forEach(r => {
        console.log(`${(r.code || '').padEnd(20).substring(0, 20)}\t${r.start_date}\t${r.end_date}\t${(r.unit_name || 'unmapped').padEnd(10).substring(0, 10)}\tRM ${r.rental || 0}`);
      });
      
    } catch(e) {
      console.log('Error:', e.message);
    }
  });
});

req.on('error', e => console.log('Request error:', e.message));
req.end();
