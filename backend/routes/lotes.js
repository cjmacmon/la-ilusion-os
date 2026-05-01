const express = require('express');
const router = express.Router();
const pool = require('../db/pool');
const { requireAuth, requireRole } = require('../middleware/auth');

// GET /lotes
router.get('/', requireAuth, async (req, res) => {
  const { zona } = req.query;
  try {
    const result = zona
      ? await pool.query('SELECT * FROM lote WHERE zona = $1 ORDER BY cod_lote', [zona])
      : await pool.query('SELECT * FROM lote ORDER BY zona, cod_lote');
    res.json({ success: true, data: result.rows });
  } catch (err) {
    console.error('[lotes/GET]', err.message);
    res.status(500).json({ success: false, error: 'Error del servidor' });
  }
});

// POST /lotes
router.post('/', requireAuth, requireRole('admin'), async (req, res) => {
  const { cod_lote, nombre, zona, hectareas, numero_palmas, peso_promedio_kg, anio_siembra } = req.body;
  if (!cod_lote || !nombre || !zona) {
    return res.status(400).json({ success: false, error: 'cod_lote, nombre y zona son requeridos' });
  }
  try {
    const result = await pool.query(
      `INSERT INTO lote (cod_lote, nombre, zona, hectareas, numero_palmas, peso_promedio_kg, anio_siembra)
       VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *`,
      [cod_lote, nombre, zona, hectareas || null, numero_palmas || null, peso_promedio_kg || null, anio_siembra || null]
    );
    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) {
    if (err.code === '23505') return res.status(409).json({ success: false, error: 'cod_lote ya existe' });
    console.error('[lotes/POST]', err.message);
    res.status(500).json({ success: false, error: 'Error del servidor' });
  }
});

// PUT /lotes/:id
router.put('/:id', requireAuth, requireRole('admin'), async (req, res) => {
  const { id } = req.params;
  const { nombre, zona, hectareas, numero_palmas, peso_promedio_kg, anio_siembra } = req.body;
  try {
    const sets = [];
    const params = [];
    if (nombre !== undefined)          { sets.push(`nombre = $${params.length+1}`);          params.push(nombre); }
    if (zona !== undefined)            { sets.push(`zona = $${params.length+1}`);            params.push(zona); }
    if (hectareas !== undefined)       { sets.push(`hectareas = $${params.length+1}`);       params.push(hectareas); }
    if (numero_palmas !== undefined)   { sets.push(`numero_palmas = $${params.length+1}`);   params.push(numero_palmas); }
    if (peso_promedio_kg !== undefined){ sets.push(`peso_promedio_kg = $${params.length+1}`);params.push(peso_promedio_kg); }
    if (anio_siembra !== undefined)    { sets.push(`anio_siembra = $${params.length+1}`);    params.push(anio_siembra); }

    if (!sets.length) return res.status(400).json({ success: false, error: 'Sin campos para actualizar' });

    params.push(id);
    const result = await pool.query(
      `UPDATE lote SET ${sets.join(', ')} WHERE lote_id = $${params.length} RETURNING *`,
      params
    );
    if (!result.rows.length) return res.status(404).json({ success: false, error: 'Lote no encontrado' });
    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    console.error('[lotes/PUT]', err.message);
    res.status(500).json({ success: false, error: 'Error del servidor' });
  }
});

module.exports = router;
