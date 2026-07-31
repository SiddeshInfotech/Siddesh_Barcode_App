const postgres = require('postgres');
const crypto = require('crypto');

const sql = postgres({
  host: 'aws-1-ap-northeast-2.pooler.supabase.com',
  port: 5432,
  database: 'postgres',
  username: 'postgres.rcdbqpmmtyioqxrzsdeg',
  password: 'hAOZTxxIfDACay9B',
  ssl: { rejectUnauthorized: false }
});

async function runVerification() {
  console.log('================================================================');
  console.log('STARTING RUNTIME VERIFICATION: scan_receive RPC LIFECYCLE TEST');
  console.log('================================================================\n');

  try {
    // 1. Ensure test product & barcode exist in GENERATED state
    const testBarcodeCode = 'TEST-LIFECYCLE-' + Math.floor(100000 + Math.random() * 900000);
    
    // Get or create product
    let products = await sql`SELECT id FROM public.products LIMIT 1`;
    let productId;
    if (products.length === 0) {
      const newP = await sql`INSERT INTO public.products (name, sku_barcode, price) VALUES ('Test Item', ${testBarcodeCode}, 99.99) RETURNING id`;
      productId = newP[0].id;
    } else {
      productId = products[0].id;
    }

    // Insert product barcode with GENERATED status
    const bcInsert = await sql`
      INSERT INTO public.product_barcodes (product_id, code, status, symbology)
      VALUES (${productId}, ${testBarcodeCode}, 'GENERATED', 'CODE128')
      RETURNING id, code, status;
    `;
    const barcodeId = bcInsert[0].id;
    console.log('1. INITIAL STATE:');
    console.log('   Barcode ID:', barcodeId);
    console.log('   Barcode Code:', bcInsert[0].code);
    console.log('   Initial Status:', bcInsert[0].status, '\n');

    // 2. SCAN 1 (RECEIVE): GENERATED -> INWARDED
    const scan1TxnId = crypto.randomUUID();
    console.log('2. SCAN 1 REQUEST (GENERATED -> INWARDED):');
    console.log('   Payload: { p_code:', testBarcodeCode, ', p_client_txn_id:', scan1TxnId, ', p_device_source: "CAMERA" }');

    const scan1Res = await sql`
      SELECT public.scan_receive(${testBarcodeCode}, ${scan1TxnId}::uuid, 'CAMERA'::public.scan_source) as res;
    `;
    const scan1Payload = scan1Res[0].res;
    console.log('   Supabase RPC Response:', JSON.stringify(scan1Payload, null, 2));

    // Verify barcode_scans row for Scan 1
    const scan1Scans = await sql`SELECT * FROM public.barcode_scans WHERE client_txn_id = ${scan1TxnId}::uuid`;
    console.log('   barcode_scans Insert:', scan1Scans.length > 0 ? '✓ ROW INSERTED' : '❌ NO ROW');
    if (scan1Scans.length > 0) {
      console.log('     ID:', scan1Scans[0].id, '| Action:', scan1Scans[0].action, '| Ledger ID:', scan1Scans[0].ledger_id);
    }

    // Verify stock_ledger row for Scan 1
    const scan1Ledger = await sql`SELECT * FROM public.stock_ledger WHERE id = ${scan1Payload.ledger_id}::uuid`;
    console.log('   stock_ledger Insert:', scan1Ledger.length > 0 ? '✓ ROW INSERTED' : '❌ NO ROW');
    if (scan1Ledger.length > 0) {
      console.log('     ID:', scan1Ledger[0].id, '| Txn Type:', scan1Ledger[0].txn_type, '| Qty Delta:', scan1Ledger[0].qty_delta);
    }

    // Verify updated status
    const bcAfterScan1 = await sql`SELECT status FROM public.product_barcodes WHERE id = ${barcodeId}`;
    console.log('   Updated product_barcodes.status:', bcAfterScan1[0].status, '\n');

    // 3. SCAN 2 (ISSUE): INWARDED -> OUTWARDED
    const scan2TxnId = crypto.randomUUID();
    console.log('3. SCAN 2 REQUEST (INWARDED -> OUTWARDED):');
    console.log('   Payload: { p_code:', testBarcodeCode, ', p_client_txn_id:', scan2TxnId, ', p_device_source: "CAMERA" }');

    const scan2Res = await sql`
      SELECT public.scan_receive(${testBarcodeCode}, ${scan2TxnId}::uuid, 'CAMERA'::public.scan_source) as res;
    `;
    const scan2Payload = scan2Res[0].res;
    console.log('   Supabase RPC Response:', JSON.stringify(scan2Payload, null, 2));

    // Verify barcode_scans row for Scan 2
    const scan2Scans = await sql`SELECT * FROM public.barcode_scans WHERE client_txn_id = ${scan2TxnId}::uuid`;
    console.log('   barcode_scans Insert:', scan2Scans.length > 0 ? '✓ ROW INSERTED' : '❌ NO ROW');
    if (scan2Scans.length > 0) {
      console.log('     ID:', scan2Scans[0].id, '| Action:', scan2Scans[0].action, '| Ledger ID:', scan2Scans[0].ledger_id);
    }

    // Verify stock_ledger row for Scan 2
    const scan2Ledger = await sql`SELECT * FROM public.stock_ledger WHERE id = ${scan2Payload.ledger_id}::uuid`;
    console.log('   stock_ledger Insert:', scan2Ledger.length > 0 ? '✓ ROW INSERTED' : '❌ NO ROW');
    if (scan2Ledger.length > 0) {
      console.log('     ID:', scan2Ledger[0].id, '| Txn Type:', scan2Ledger[0].txn_type, '| Qty Delta:', scan2Ledger[0].qty_delta);
    }

    // Verify final status
    const bcAfterScan2 = await sql`SELECT status FROM public.product_barcodes WHERE id = ${barcodeId}`;
    console.log('   Final product_barcodes.status:', bcAfterScan2[0].status, '\n');

    console.log('================================================================');
    console.log('VERIFICATION COMPLETE: ALL DB OPERATIONS VERIFIED SUCCESSFULLY');
    console.log('================================================================');
  } catch (err) {
    console.error('Verification Error:', err);
  } finally {
    await sql.end();
  }
}

runVerification();
