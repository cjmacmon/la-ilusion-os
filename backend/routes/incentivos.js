const express = require('express');
const router = express.Router();
const pool = require('../db/pool');
const { requireAuth, requireRole } = require('../middleware/auth');

// GET /incentivos
router.get('/', requireAuth, async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM incentivo ORDER BY tipo, umbral');
    res.json({ success: true, data: result.rows });
  } catch (err) {
    console.error('[incentivos/GET]', err.message);
    res.status(500).json({ success: false, error: 'Error del servidor' });
  }
});

// POST /incentivos
router.post('/', requireAuth, requireRole('admin'), async (req, res) => {
  const { nombre, tipo, umbral, monto_bono, descripcion } = req.body;
  if (!nombre || !tipo || umbral === undefined || !monto_bono) {
    return res.status(400).json({ success: false, error: 'nombre, tipo, umbral y monto_bono son requeridos' });
  }
  try {
    const result = await pool.query(
      `INSERT INTO incentivo (nombre, tipo, umbral, monto_bono, descripcion, activo)
       VALUES ($1,$2,$3,$4,$5,TRUE) RETURNING *`,
      [nombre, tipo, umbral, monto_bono, descripcion || null]
    );
    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) {
    console.error('[incentivos/POST]', err.message);
    res.status(500).json({ success: false, error: 'Error del servidor' });
  }
});

// PUT /incentivos/:id
router.put('/:id', requireAuth, requireRole('admin'), async (req, res) => {
  const { id } = req.params;
  const { nombre, tipo, umbral, monto_bono, activo, descripcion } = req.body;
  const sets = [];
  const params = [];

  if (nombre !== undefined)    { sets.push(`nombre = $${params.length+1}`);    params.push(nombre);    }
  if (tipo !== undefined)      { sets.push(`tipo = $${params.length+1}`);      params.push(tipo);      }
  if (umbral !== undefined)    { sets.push(`umbral = $${params.length+1}`);    params.push(umbral);    }
  if (monto_bono !== undefined){ sets.push(`monto_bono = $${params.length+1}`);params.push(monto_bono);}
  if (activo !== undefined)    { sets.push(`activo = $${params.length+1}`);    params.push(activo);    }
  if (descripcion !== undefined){ sets.push(`descripcion = $${params.length+1}`);params.push(descripcion);}

  if (!sets.length) return res.status(400).json({ success: false, error: 'Sin campos para actualizar' });
  try {
    params.push(id);
    const result = await pool.query(
      `UPDATE incentivo SET ${sets.join(', ')} WHERE incentivo_id = $${params.length} RETURNING *`,
      params
    );
    if (!result.rows.length) return res.status(404).json({ success: false, error: 'Incentivo no encontrado' });
    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    console.error('[incentivos/PUT]', err.message);
    res.status(500).json({ success: false, error: 'Error del servidor' });
  }
});

module.exports = router;
