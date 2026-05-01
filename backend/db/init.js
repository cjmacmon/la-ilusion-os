const fs = require('fs');
const path = require('path');
const pool = require('./pool');

const ADMIN_CEDULA = '12345678';
const ADMIN_PASSWORD_HASH = '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcg7b3XeKeUxWdeS86E36P4/KFm';

async function initDatabase() {
  const client = await pool.connect();
  try {
    // Check whether the schema has already been applied by testing for the
    // trabajador table.  If it exists we skip schema + seed to stay idempotent.
    const { rows } = await client.query(`
      SELECT 1 FROM information_schema.tables
      WHERE table_schema = 'public' AND table_name = 'trabajador'
    `);

    if (rows.length === 0) {
      console.log('[init] Tables not found — running schema.sql …');
      const schema = fs.readFileSync(path.join(__dirname, 'schema.sql'), 'utf8');
      await client.query(schema);
      console.log('[init] schema.sql applied.');

      console.log('[init] Running seed.sql …');
      const seed = fs.readFileSync(path.join(__dirname, 'seed.sql'), 'utf8');
      await client.query(seed);
      console.log('[init] seed.sql applied.');
    } else {
      console.log('[init] Tables already exist — skipping schema/seed.');
    }

    // Upsert the admin user so the dashboard is always accessible.
    // Uses INSERT … ON CONFLICT to stay idempotent across restarts.
    await client.query(`
      INSERT INTO trabajador
        (cod_cosechero, cedula, nombre_completo, telefono, pin, password_hash, rol, zona, activo, fecha_ingreso)
      VALUES
        ('ADMIN00', $1, 'Administrador Principal', '0000000000', '0000', $2, 'admin', NULL, TRUE, CURRENT_DATE)
      ON CONFLICT (cedula) DO UPDATE
        SET password_hash = EXCLUDED.password_hash,
            rol           = EXCLUDED.rol,
            activo        = TRUE
    `, [ADMIN_CEDULA, ADMIN_PASSWORD_HASH]);

    console.log(`[init] Admin user (cédula ${ADMIN_CEDULA}) ready.`);
  } catch (err) {
    console.error('[init] Database initialisation failed:', err.message);
    throw err;
  } finally {
    client.release();
  }
}

module.exports = initDatabase;
