const express = require('express');
const router = express.Router();
const pool = require('../db/pool');
const { requireAuth } = require('../middleware/auth');

// GET /fertilizacion
router.get('/', requireAuth, async (req, res) => {
  const { trabajador_id, lote_id, fecha_inicio, fecha_fin } = req.query;
  const conditions = [];
  const params = [];

  if (trabajador_id) { conditions.push(`f.trabajador_id = $${params.length+1}`); params.push(trabajador_id); }
  if (lote_id)       { conditions.push(`f.lote_id = $${params.length+1}`);        params.push(lote_id);       }
  if (fecha_inicio)  { conditions.push(`f.fecha >= $${params.length+1}`);         params.push(fecha_inicio);  }
  if (fecha_fin)     { conditions.push(`f.fecha <= $${params.length+1}`);         params.push(fecha_fin);     }

  const where = conditions.length ? 'WHERE ' + conditions.join(' AND ') : '';
  try {
    const result = await pool.query(
      `SELECT f.*, t.nombre_completo, l.nombre AS lote_nombre, l.zona
       FROM fertilizacion f
       JOIN trabajador t ON t.trabajador_id = f.trabajador_id
       JOIN lote l ON l.lote_id = f.lote_id
       ${where}
       ORDER BY f.fecha DESC, f.fecha_creacion DESC
       LIMIT 500`,
      params
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    console.error('[fertilizacion/GET]', err.message);
    res.status(500).json({ success: false, error: 'Error del servidor' });
  }
});

// POST /fertilizacion/sync — batch upsert from Android
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
      const total_aplicado = (r.palmas_fertilizadas || 0) * (r.dosis_por_palma || 0);
      const result = await pool.query(
        `INSERT INTO fertilizacion (
           fertilizacion_id, trabajador_id, lote_id, fecha,
           palmas_fertilizadas, dosis_por_palma, total_aplicado,
           observaciones, sync_status, device_id
         ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,'synced',$9)
         ON CONFLICT (fertilizacion_id) DO NOTHING`,
        [
          r.fertilizacion_id, r.trabajador_id, r.lote_id, r.fecha,
          r.palmas_fertilizadas || 0, r.dosis_por_palma || 0,
          r.total_aplicado || total_aplicado,
          r.observaciones || null, r.device_id || null
        ]
      );
      if (result.rowCount === 0) duplicates++;
      else synced++;
    } catch (err) {
      errors.push({ fertilizacion_id: r.fertilizacion_id, error: err.message });
    }
  }

  console.log(`[fertilizacion/sync] worker=${cod} received=${records.length} inserted=${synced} duplicates=${duplicates}`);
  res.json({ success: true, data: { synced, duplicates, errors } });
});

module.exports = router;
