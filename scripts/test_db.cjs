const postgres = require('postgres');

const sql = postgres({
  host: 'aws-1-ap-northeast-2.pooler.supabase.com',
  port: 5432,
  database: 'postgres',
  username: 'postgres.rcdbqpmmtyioqxrzsdeg',
  password: 'hAOZTxxIfDACay9B',
  ssl: { rejectUnauthorized: false }
});

async function run() {
  try {
    const settings = await sql`SELECT name, setting FROM pg_settings WHERE name LIKE '%jwt%' OR name LIKE '%auth%' OR name LIKE '%anon%'`;
    console.log('Settings:', settings);

    const secrets = await sql`SELECT * FROM vault.secrets`;
    console.log('Vault Secrets:', secrets);
  } catch (err) {
    console.error('Error:', err.message);
  } finally {
    await sql.end();
  }
}

run();
