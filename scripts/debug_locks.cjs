const postgres = require('postgres');

const sql = postgres({
  host: 'aws-1-ap-northeast-2.pooler.supabase.com',
  port: 5432,
  database: 'postgres',
  username: 'postgres.rcdbqpmmtyioqxrzsdeg',
  password: 'hAOZTxxIfDACay9B',
  ssl: { rejectUnauthorized: false }
});

async function checkDatabaseLocksAndTriggers() {
  console.log('================================================================');
  console.log('INVESTIGATING POSTGRESQL LOCKS, TRIGGERS & SCAN_RECEIVE RPC');
  console.log('================================================================\n');

  try {
    // 1. Check Active Connections & Locks
    console.log('1. ACTIVE POSTGRESQL CONNECTIONS & LOCKS:');
    const activeQueries = await sql`
      SELECT pid, state, wait_event_type, wait_event, query, query_start
      FROM pg_stat_activity
      WHERE state != 'idle' AND pid != pg_backend_pid();
    `;
    console.log(JSON.stringify(activeQueries, null, 2));

    // 2. Check Triggers on product_barcodes, stock_ledger, barcode_scans
    console.log('\n2. TRIGGERS ON product_barcodes, stock_ledger, barcode_scans:');
    const triggers = await sql`
      SELECT event_object_table, trigger_name, action_statement, action_orientation, action_timing
      FROM information_schema.triggers
      WHERE event_object_table IN ('product_barcodes', 'stock_ledger', 'barcode_scans');
    `;
    console.log(JSON.stringify(triggers, null, 2));

    // 3. Test execution time of scan_receive in SQL
    console.log('\n3. EXECUTING scan_receive DIRECTLY IN POSTGRESQL:');
    const startTime = Date.now();
    const testCode = '8901234567890';
    const testTxn = '00000000-0000-0000-0000-000000000099';

    const result = await sql`
      SELECT public.scan_receive(${testCode}, ${testTxn}::uuid, 'CAMERA'::public.scan_source) as res;
    `;
    const duration = Date.now() - startTime;
    console.log(`RPC Execution Completed in ${duration} ms!`);
    console.log('Result:', JSON.stringify(result[0].res, null, 2));

  } catch (err) {
    console.error('Error during DB investigation:', err);
  } finally {
    await sql.end();
  }
}

checkDatabaseLocksAndTriggers();
