const express = require('express');
const router = express.Router();
const pool = require('../db/pool');
const { requireAuth, requireRole } = require('../middleware/auth');

// GET /tarifas — current active rates
router.get('/', requireAuth, async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT * FROM tarifa WHERE activa = TRUE ORDER BY tipo_labor, zona`
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    console.error('[tarifas/GET]', err.message);
    res.status(500).json({ success: false, error: 'Error del servidor' });
  }
});

// POST /tarifas — create new rate (deactivates previous for same tipo_labor + zona)
router.post('/', requireAuth, requireRole('admin'), async (req, res) => {
  const { tipo_labor, zona, precio_por_kg, precio_por_unidad, fecha_inicio } = req.body;
  if (!tipo_labor || !fecha_inicio) {
    return res.status(400).json({ success: false, error: 'tipo_labor y fecha_inicio son requeridos' });
  }
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Deactivate previous rate for same tipo_labor + zona combo
    const zonaCondition = zona ? `AND (zona = $3 OR zona IS NULL)` : `AND zona IS NULL`;
    const deactivateParams = zona ? [tipo_labor, new Date(), zona] : [tipo_labor, new Date()];
    await client.query(
      `UPDATE tarifa SET activa = FALSE, fecha_fin = $2
       WHERE tipo_labor = $1 AND activa = TRUE ${zonaCondition}`,
      deactivateParams
    );

    const insertParams = [tipo_labor, zona || null, precio_por_kg || null, precio_por_unidad || null, fecha_inicio];
    const result = await client.query(
      `INSERT INTO tarifa (tipo_labor, zona, precio_por_kg, precio_por_unidad, fecha_inicio, activa)
       VALUES ($1,$2,$3,$4,$5,TRUE) RETURNING *`,
      insertParams
    );

    await client.query('COMMIT');
    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('[tarifas/POST]', err.message);
    res.status(500).json({ success: false, error: 'Error del servidor' });
  } finally {
    client.release();
  }
});

module.exports = router;
