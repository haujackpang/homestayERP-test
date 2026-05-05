const https = require('https');

const SUPABASE_HOST = (process.env.SUPABASE_HOST || process.env.SUPABASE_URL || '')
  .replace(/^https?:\/\//, '')
  .replace(/\/$/, '');
const API_KEY = process.env.SUPABASE_KEY;

if (!SUPABASE_HOST || !API_KEY) {
  console.error('Set SUPABASE_URL or SUPABASE_HOST, plus SUPABASE_KEY.');
  process.exit(1);
}

// 先查询总数和日期范围
const options = {
  hostname: SUPABASE_HOST,
  path: '/rest/v1/reservations?select=count&count=exact',
  method: 'GET',
  headers: {
    'apikey': API_KEY,
    'Authorization': `Bearer ${API_KEY}`,
    'Content-Type': 'application/json'
  }
};

console.log('Getting total count...\n');

const req = https.request(options, (res) => {
  let data = '';
  
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    try {
      const count = res.headers['content-range']?.split('/')[1] || 'unknown';
      console.log(`Total records in reservations: ${count}`);
      
      // 获取日期范围
      const options2 = {
        hostname: SUPABASE_HOST,
        path: '/rest/v1/reservations?select=start_date&order=start_date.asc&limit=1',
        method: 'GET',
        headers: {
          'apikey': API_KEY,
          'Authorization': `Bearer ${API_KEY}`
        }
      };
      
      const req2 = https.request(options2, (res2) => {
        let data2 = '';
        res2.on('data', chunk => data2 += chunk);
        res2.on('end', () => {
          const records = JSON.parse(data2);
          if(records.length > 0) {
            console.log(`Earliest start_date: ${records[0].start_date}`);
          }
          
          // 获取最晚日期
          const options3 = {
            hostname: SUPABASE_HOST,
            path: '/rest/v1/reservations?select=end_date&order=end_date.desc&limit=1',
            method: 'GET',
            headers: {
              'apikey': API_KEY,
              'Authorization': `Bearer ${API_KEY}`
            }
          };
          
          const req3 = https.request(options3, (res3) => {
            let data3 = '';
            res3.on('data', chunk => data3 += chunk);
            res3.on('end', () => {
              const records = JSON.parse(data3);
              if(records.length > 0) {
                console.log(`Latest end_date: ${records[0].end_date}`);
              }
              
              // 查询 4 月 1 日之后的数据
              const options4 = {
                hostname: SUPABASE_HOST,
                path: '/rest/v1/reservations?start_date=gte.2026-04-01&select=start_date,end_date,code,unit_name&order=start_date.asc&limit=10',
                method: 'GET',
                headers: {
                  'apikey': API_KEY,
                  'Authorization': `Bearer ${API_KEY}`
                }
              };
              
              const req4 = https.request(options4, (res4) => {
                let data4 = '';
                res4.on('data', chunk => data4 += chunk);
                res4.on('end', () => {
                  const records = JSON.parse(data4);
                  console.log(`\n📅 Records on/after 2026-04-01: ${records.length}`);
                  if(records.length > 0) {
                    console.log('\nSample records:');
                    console.log('Code\tStart Date\tEnd Date');
                    records.slice(0, 10).forEach(r => {
                      console.log(`${r.code}\t${r.start_date}\t${r.end_date}`);
                    });
                  }
                });
              });
              req4.end();
            });
          });
          req3.end();
        });
      });
      req2.end();
    } catch(e) {
      console.log('Error:', e.message);
    }
  });
});

req.end();
