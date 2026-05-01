const express = require('express');
const router = express.Router();
const pool = require('../db/pool');
const { requireAuth, requireRole } = require('../middleware/auth');

// GET /tarifas-laboral — all active tariffs, optional ?area=
router.get('/', requireAuth, async (req, res) => {
  try {
    const { area } = req.query;
    const params = [];
    let where = 'WHERE activa = TRUE';
    if (area) { params.push(area); where += ` AND area = $${params.length}`; }
    const result = await pool.query(
      `SELECT * FROM tarifa_laboral ${where}
       ORDER BY area, actividad, ubicacion NULLS FIRST, rango NULLS FIRST`,
      params
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    console.error('[tarifas-laboral/GET]', err.message);
    res.status(500).json({ success: false, error: 'Error del servidor' });
  }
});

// GET /tarifas-laboral/areas — distinct areas with count
router.get('/areas', requireAuth, async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT area, COUNT(*) AS total
       FROM tarifa_laboral WHERE activa = TRUE
       GROUP BY area ORDER BY area`
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, error: 'Error del servidor' });
  }
});

// GET /tarifas-laboral/historico?fecha=YYYY-MM-DD — snapshot for a date
router.get('/historico', requireAuth, async (req, res) => {
  const { fecha } = req.query;
  if (!fecha) return res.status(400).json({ success: false, error: 'fecha requerida' });
  try {
    const result = await pool.query(
      `SELECT * FROM tarifa_laboral
       WHERE fecha_inicio <= $1 AND (fecha_fin IS NULL OR fecha_fin >= $1)
       ORDER BY area, actividad, ubicacion NULLS FIRST, rango NULLS FIRST`,
      [fecha]
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    console.error('[tarifas-laboral/historico]', err.message);
    res.status(500).json({ success: false, error: 'Error del servidor' });
  }
});

// PUT /tarifas-laboral/:id — update tarifa (creates versioned history)
router.put('/:id', requireAuth, requireRole('admin'), async (req, res) => {
  const { id } = req.params;
  const { tarifa, descripcion_labor, notas } = req.body;
  if (!tarifa) return res.status(400).json({ success: false, error: 'tarifa requerida' });

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const current = await client.query(
      'SELECT * FROM tarifa_laboral WHERE id = $1 AND activa = TRUE', [id]
    );
    if (current.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ success: false, error: 'Tarifa no encontrada' });
    }
    const old = current.rows[0];

    // Deactivate old
    await client.query(
      `UPDATE tarifa_laboral SET activa = FALSE, fecha_fin = CURRENT_DATE WHERE id = $1`, [id]
    );

    // Insert new version (inherits all fields from old, updates tarifa)
    const result = await client.query(
      `INSERT INTO tarifa_laboral
        (codigo_tarifa, area, actividad, tipo, metodo_evacuacion, cable, propiedad_equipo,
         tipo_palma, producto, ubicacion, rango, unidad_rango, unidad_tarifa,
         tarifa, descripcion_labor, notas, fecha_inicio, activa)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,CURRENT_DATE,TRUE)
       RETURNING *`,
      [
        old.codigo_tarifa, old.area, old.actividad, old.tipo, old.metodo_evacuacion,
        old.cable, old.propiedad_equipo, old.tipo_palma, old.producto, old.ubicacion,
        old.rango, old.unidad_rango, old.unidad_tarifa,
        parseFloat(tarifa),
        descripcion_labor ?? old.descripcion_labor,
        notas ?? old.notas,
      ]
    );

    await client.query('COMMIT');
    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('[tarifas-laboral/PUT]', err.message);
    res.status(500).json({ success: false, error: 'Error del servidor' });
  } finally {
    client.release();
  }
});

module.exports = router;
