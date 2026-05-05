const https = require('https');
const key = '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';

// Simulate a water bill text to verify the AI understands price vs usage
const body = JSON.stringify({
  model: 'google/gemma-3-12b-it:free',
  messages: [{
    role: 'user',
    content: [
      { type: 'text', text: `You are an expert receipt/invoice analyzer. Analyze this receipt or invoice image and extract the following information in JSON format.

IMPORTANT RULES:
- All prices/amounts are in Malaysian Ringgit (RM)
- Return ONLY valid JSON, no markdown, no code blocks, no explanation
- If you cannot read certain fields, use reasonable defaults
- For the category field, you MUST choose exactly one from this list: ["Utilities","Maintenance & Repair","Housekeeping & Cleaning","Laundry","Daily Products","Hospitality Items","Electrical & Unit Setup","Office Expenses","Employee Welfare","Outsource Cleaning Staff","Unit Renovation","Other"]
- If the receipt date is not visible, use empty string for date

CRITICAL - PRICE vs USAGE/QUANTITY:
- "price" field MUST be a MONETARY VALUE in RM (e.g. 45.80, 12.50) — this is what was CHARGED/PAID
- NEVER put usage units (kWh, m3, litres, units) into the "price" field
- NEVER put meter readings into the "price" field
- For utility bills (TNB/electricity, Syabas/water, gas): look for "Amount Due", "Jumlah Perlu Dibayar", "Total Payable", or "Amaun" — that is the price
- "qty" is the quantity/number of units purchased (use 1 if unclear)
- "total" is the final total amount in RM that was paid/charged

EXAMPLES of what NOT to do:
- Water bill shows "Usage: 15 m3" and "Amount: RM 8.50" → price = 8.50 (NOT 15)
- Electric bill shows "234 kWh" and "RM 98.40" → price = 98.40 (NOT 234)

Return this exact JSON structure:
{"items":[{"name":"item description","qty":1,"price":12.50}],"category":"one of the allowed categories","total":45.80,"date":"YYYY-MM-DD","summary":"brief 1-line summary"}

This is a water bill (not an image, simulate analysis):
SYABAS Water Bill
Account: 1234567
Usage: 18 m3
Water Charges: RM 7.20
Sewerage: RM 3.60
Amount Due: RM 10.80
Due Date: 2026-03-15` },
      { type: 'image_url', image_url: { url: 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/wAARCAABAAEDASIAAhEBAxEB/8QAFAABAAAAAAAAAAAAAAAAAAAACf/EABQQAQAAAAAAAAAAAAAAAAAAAAD/xAAUAQEAAAAAAAAAAAAAAAAAAAAA/8QAFBEBAAAAAAAAAAAAAAAAAAAAAP/aAAwDAQACEQMRAD8AJQAB/9k=' } }
    ]
  }],
  max_tokens: 300,
  temperature: 0.1
});

const options = {
  hostname: 'openrouter.ai',
  path: '/api/v1/chat/completions',
  method: 'POST',
  headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + key, 'HTTP-Referer': 'https://skwogboredsczcyhlqgn.supabase.co', 'Content-Length': Buffer.byteLength(body) }
};

console.log('Testing water bill: usage=18 m3, amount=RM 10.80 — price should be 10.80, NOT 18...');
const req = https.request(options, (res) => {
  let data = '';
  res.on('data', c => data += c);
  res.on('end', () => {
    const json = JSON.parse(data);
    const reply = json.choices?.[0]?.message?.content || '';
    const clean = reply.replace(/```json\s*/g,'').replace(/```\s*/g,'').trim();
    try {
      const parsed = JSON.parse(clean);
      const price = parsed.items?.[0]?.price;
      const total = parsed.total;
      console.log('price:', price, total === 10.80 || price === 10.80 ? '✓ CORRECT (10.80)' : '✗ WRONG (expected 10.80, got ' + price + ')');
      console.log('total:', total);
      console.log('category:', parsed.category);
      console.log('summary:', parsed.summary);
    } catch(e) {
      console.log('RAW reply:', reply.substring(0, 300));
    }
  });
});
req.on('error', e => console.log('ERROR:', e.message));
req.write(body);
req.end();
