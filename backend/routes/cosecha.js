const express = require('express');
const router = express.Router();
const pool = require('../db/pool');
const { requireAuth } = require('../middleware/auth');

// GET /cosecha
router.get('/', requireAuth, async (req, res) => {
  const { trabajador_id, lote_id, fecha_inicio, fecha_fin, sync_status } = req.query;
  const conditions = [];
  const params = [];

  if (trabajador_id) { conditions.push(`c.trabajador_id = $${params.length+1}`); params.push(trabajador_id); }
  if (lote_id)       { conditions.push(`c.lote_id = $${params.length+1}`);        params.push(lote_id);       }
  if (fecha_inicio)  { conditions.push(`c.fecha_corte >= $${params.length+1}`);   params.push(fecha_inicio);  }
  if (fecha_fin)     { conditions.push(`c.fecha_corte <= $${params.length+1}`);   params.push(fecha_fin);     }
  if (sync_status)   { conditions.push(`c.sync_status = $${params.length+1}`);    params.push(sync_status);   }

  const where = conditions.length ? 'WHERE ' + conditions.join(' AND ') : '';
  try {
    const result = await pool.query(
      `SELECT c.*, t.nombre_completo, l.nombre AS lote_nombre, l.zona
       FROM cosecha c
       JOIN trabajador t ON t.trabajador_id = c.trabajador_id
       JOIN lote l ON l.lote_id = c.lote_id
       ${where}
       ORDER BY c.fecha_corte DESC, c.fecha_creacion DESC
       LIMIT 500`,
      params
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    console.error('[cosecha/GET]', err.message);
    res.status(500).json({ success: false, error: 'Error del servidor' });
  }
});

// POST /cosecha — single record
router.post('/', requireAuth, async (req, res) => {
  const {
    cosecha_id, trabajador_id, cod_cosechero, lote_id, ticket_extractora,
    fecha_corte, tipo_cosecha, metodo_recoleccion, total_racimos,
    peso_extractora_sin_recolector, total_racimos_recolector,
    peso_extractora_recolector, observaciones, created_offline, device_id
  } = req.body;

  if (!cosecha_id || !trabajador_id || !lote_id || !fecha_corte || !tipo_cosecha) {
    return res.status(400).json({ success: false, error: 'Campos requeridos faltantes' });
  }
  try {
    const result = await pool.query(
      `INSERT INTO cosecha (
         cosecha_id, trabajador_id, cod_cosechero, lote_id, ticket_extractora,
         fecha_corte, tipo_cosecha, metodo_recoleccion, total_racimos,
         peso_extractora_sin_recolector, total_racimos_recolector,
         peso_extractora_recolector, observaciones, sync_status, created_offline, device_id
       ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,'synced',$14,$15)
       RETURNING *`,
      [
        cosecha_id, trabajador_id, cod_cosechero, lote_id, ticket_extractora || null,
        fecha_corte, tipo_cosecha, metodo_recoleccion || 'NO_APLICA', total_racimos || 0,
        peso_extractora_sin_recolector || 0, total_racimos_recolector || null,
        peso_extractora_recolector || null, observaciones || null,
        created_offline || false, device_id || null
      ]
    );
    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) {
    if (err.code === '23505') return res.status(409).json({ success: false, error: 'cosecha_id ya existe' });
    console.error('[cosecha/POST]', err.message);
    res.status(500).json({ success: false, error: 'Error del servidor' });
  }
});

// POST /cosecha/sync — batch upsert from Android
router.post('/sync', requireAuth, async (req, res) => {
  const { records } = req.body;
  if (!Array.isArray(records) || records.length === 0) {
    return res.status(400).json({ success: false, error: 'records[] requerido' });
  }

  const cod = req.user.cod_cosechero;
  let synced = 0;
  let duplicates = 0;
  const errors = [];

  for (const r of records) {
    try {
      const result = await pool.query(
        `INSERT INTO cosecha (
           cosecha_id, trabajador_id, cod_cosechero, lote_id, ticket_extractora,
           fecha_corte, tipo_cosecha, metodo_recoleccion, total_racimos,
           peso_extractora_sin_recolector, total_racimos_recolector,
           peso_extractora_recolector, observaciones, sync_status, created_offline, device_id
         ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,'synced',$14,$15)
         ON CONFLICT (cosecha_id) DO NOTHING`,
        [
          r.cosecha_id, r.trabajador_id, r.cod_cosechero, r.lote_id, r.ticket_extractora || null,
          r.fecha_corte, r.tipo_cosecha, r.metodo_recoleccion || 'NO_APLICA', r.total_racimos || 0,
          r.peso_extractora_sin_recolector || 0, r.total_racimos_recolector || null,
          r.peso_extractora_recolector || null, r.observaciones || null,
          r.created_offline || true, r.device_id || null
        ]
      );
      if (result.rowCount === 0) duplicates++;
      else synced++;
    } catch (err) {
      errors.push({ cosecha_id: r.cosecha_id, error: err.message });
    }
  }

  console.log(`[cosecha/sync] worker=${cod} received=${records.length} inserted=${synced} duplicates=${duplicates}`);
  res.json({ success: true, data: { synced, duplicates, errors } });
});

module.exports = router;
