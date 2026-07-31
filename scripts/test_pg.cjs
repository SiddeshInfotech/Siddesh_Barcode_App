const postgres = require('postgres');
const crypto = require('crypto');

const sql = postgres('postgresql://postgres.rcdbqpmmtyioqxrzsdeg:hAOZTxxIfDACay9B@aws-1-ap-northeast-2.pooler.supabase.com:5432/postgres', {
  ssl: { rejectUnauthorized: false },
  onnotice: (notice) => {
    console.log(`[NOTICE LOG] ${notice.message}`);
  }
});

async function runTest() {
  const startTime = Date.now();
  console.log('Connecting to Supabase PostgreSQL...');

  const testBarcode = 'VERIFY-TEST-' + Math.floor(100000 + Math.random() * 900000);
  const testTxn = crypto.randomUUID();

  // Ensure a test product and barcode exist
  const pRes = await sql`SELECT id FROM public.products LIMIT 1`;
  let productId;
  if (pRes.length === 0) {
    const newP = await sql`INSERT INTO public.products (name, sku_barcode, price) VALUES ('Test Item', ${testBarcode}, 99.99) RETURNING id`;
    productId = newP[0].id;
  } else {
    productId = pRes[0].id;
  }

  const bcRes = await sql`
    INSERT INTO public.product_barcodes (product_id, code, status, symbology)
    VALUES (${productId}, ${testBarcode}, 'GENERATED', 'CODE128')
    RETURNING id, code, status;
  `;
  console.log('Initial Barcode Row:', bcRes[0]);

  // Execute scan_receive RPC
  console.log('\nExecuting public.scan_receive RPC...');
  const rpcStart = Date.now();
  const res = await sql`
    SELECT public.scan_receive(${testBarcode}, ${testTxn}::uuid, 'CAMERA'::public.scan_source) as res;
  `;
  const rpcDuration = Date.now() - rpcStart;

  console.log(`\n================================================================`);
  console.log(`RPC EXECUTION COMPLETED IN ${rpcDuration} ms!`);
  console.log(`================================================================`);
  console.log('Returned Result Payload:\n', JSON.stringify(res[0].res, null, 2));

  // Query database state to confirm updates
  const scanCheck = await sql`SELECT * FROM public.barcode_scans WHERE client_txn_id = ${testTxn}::uuid`;
  console.log('\nbarcode_scans row inserted:', scanCheck[0]);

  const ledgerCheck = await sql`SELECT * FROM public.stock_ledger WHERE id = ${res[0].res.ledger_id}::uuid`;
  console.log('stock_ledger row inserted:', ledgerCheck[0]);

  const bcCheck = await sql`SELECT status FROM public.product_barcodes WHERE code = ${testBarcode}`;
  console.log('Final product_barcodes.status:', bcCheck[0].status);

  await sql.end();
}

runTest().catch(err => console.error('Error:', err));
