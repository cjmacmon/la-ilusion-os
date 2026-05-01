const express = require('express');
const router = express.Router();
const pool = require('../db/pool');
const { requireAuth, requireRole } = require('../middleware/auth');

// POST /ausencias — supervisor only
router.post('/', requireAuth, requireRole('supervisor', 'admin'), async (req, res) => {
  const { trabajador_id, fecha, justificada, motivo } = req.body;
  if (!trabajador_id || !fecha) {
    return res.status(400).json({ success: false, error: 'trabajador_id y fecha son requeridos' });
  }
  try {
    const result = await pool.query(
      `INSERT INTO ausencia (trabajador_id, fecha, justificada, motivo, registrado_por)
       VALUES ($1,$2,$3,$4,$5)
       ON CONFLICT (trabajador_id, fecha) DO UPDATE
         SET justificada = $3, motivo = $4, registrado_por = $5
       RETURNING *`,
      [trabajador_id, fecha, justificada || false, motivo || null, req.user.cod_cosechero]
    );
    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) {
    console.error('[ausencias/POST]', err.message);
    res.status(500).json({ success: false, error: 'Error del servidor' });
  }
});

// GET /ausencias
router.get('/', requireAuth, requireRole('supervisor', 'admin'), async (req, res) => {
  const { trabajador_id, fecha_inicio, fecha_fin } = req.query;
  const conditions = [];
  const params = [];

  if (trabajador_id) { conditions.push(`a.trabajador_id = $${params.length+1}`); params.push(trabajador_id); }
  if (fecha_inicio)  { conditions.push(`a.fecha >= $${params.length+1}`);         params.push(fecha_inicio);  }
  if (fecha_fin)     { conditions.push(`a.fecha <= $${params.length+1}`);         params.push(fecha_fin);     }

  const where = conditions.length ? 'WHERE ' + conditions.join(' AND ') : '';
  try {
    const result = await pool.query(
      `SELECT a.*, t.nombre_completo, t.cod_cosechero
       FROM ausencia a
       JOIN trabajador t ON t.trabajador_id = a.trabajador_id
       ${where}
       ORDER BY a.fecha DESC`,
      params
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    console.error('[ausencias/GET]', err.message);
    res.status(500).json({ success: false, error: 'Error del servidor' });
  }
});

module.exports = router;
