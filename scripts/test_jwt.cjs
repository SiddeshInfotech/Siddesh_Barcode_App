const crypto = require('crypto');

function base64Url(str) {
  return Buffer.from(str)
    .toString('base64')
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');
}

const secret = '9a4f2c8d3b7a1e5f8g0h2i4j6k8l0m2n4o6p8q0r2s4t6u8v0w2x4y6z8a0b2c4d';

const header = { alg: 'HS256', typ: 'JWT' };
const payload = {
  iss: 'supabase',
  ref: 'rcdbqpmmtyioqxrzsdeg',
  role: 'anon',
  iat: Math.floor(Date.now() / 1000),
  exp: Math.floor(Date.now() / 1000) + (365 * 24 * 60 * 60)
};

const encodedHeader = base64Url(JSON.stringify(header));
const encodedPayload = base64Url(JSON.stringify(payload));
const signature = base64Url(
  crypto.createHmac('sha256', secret)
    .update(`${encodedHeader}.${encodedPayload}`)
    .digest()
);

const token = `${encodedHeader}.${encodedPayload}.${signature}`;
console.log('Generated Anon JWT Token:');
console.log(token);

async function testSupabaseRest() {
  try {
    const res = await fetch('https://rcdbqpmmtyioqxrzsdeg.supabase.co/rest/v1/product_barcodes?select=*&limit=1', {
      headers: {
        'apikey': token,
        'Authorization': `Bearer ${token}`
      }
    });
    console.log('Supabase REST Status:', res.status);
    const body = await res.text();
    console.log('Supabase REST Body:', body);
  } catch (err) {
    console.error('Error:', err);
  }
}

testSupabaseRest();
