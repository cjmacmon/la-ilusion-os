const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const pool = require('../db/pool');
const { requireAuth, requireRole } = require('../middleware/auth');

// GET /trabajadores
router.get('/', requireAuth, async (req, res) => {
  const { zona, rol, activo } = req.query;
  const conditions = [];
  const params = [];

  if (zona) { conditions.push(`zona = $${params.length + 1}`); params.push(zona); }
  if (rol)  { conditions.push(`rol = $${params.length + 1}`);  params.push(rol);  }
  if (activo !== undefined) { conditions.push(`activo = $${params.length + 1}`); params.push(activo === 'true'); }

  const where = conditions.length ? 'WHERE ' + conditions.join(' AND ') : '';
  try {
    const result = await pool.query(
      `SELECT trabajador_id, cod_cosechero, cedula, nombre_completo, telefono,
              rol, zona, activo, fecha_ingreso
       FROM trabajador ${where} ORDER BY nombre_completo`,
      params
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    console.error('[trabajadores/GET]', err.message);
    res.status(500).json({ success: false, error: 'Error del servidor' });
  }
});

// POST /trabajadores
router.post('/', requireAuth, requireRole('admin'), async (req, res) => {
  const { cod_cosechero, cedula, nombre_completo, telefono, pin, password, rol, zona, fecha_ingreso } = req.body;
  if (!cod_cosechero || !cedula || !nombre_completo || !pin || !rol) {
    return res.status(400).json({ success: false, error: 'Campos requeridos faltantes' });
  }
  try {
    const password_hash = password ? await bcrypt.hash(password, 10) : null;
    const result = await pool.query(
      `INSERT INTO trabajador (cod_cosechero, cedula, nombre_completo, telefono, pin, password_hash, rol, zona, fecha_ingreso)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
       RETURNING trabajador_id, cod_cosechero, cedula, nombre_completo, rol, zona, activo, fecha_ingreso`,
      [cod_cosechero, cedula, nombre_completo, telefono || null, pin, password_hash, rol, zona || null, fecha_ingreso || new Date()]
    );
    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) {
    if (err.code === '23505') return res.status(409).json({ success: false, error: 'cod_cosechero o cédula ya existen' });
    console.error('[trabajadores/POST]', err.message);
    res.status(500).json({ success: false, error: 'Error del servidor' });
  }
});

// PUT /trabajadores/:id
router.put('/:id', requireAuth, requireRole('admin', 'supervisor'), async (req, res) => {
  const { id } = req.params;
  const { nombre_completo, telefono, pin, password, rol, zona, activo } = req.body;
  try {
    const sets = [];
    const params = [];

    if (nombre_completo !== undefined) { sets.push(`nombre_completo = $${params.length + 1}`); params.push(nombre_completo); }
    if (telefono !== undefined)        { sets.push(`telefono = $${params.length + 1}`);        params.push(telefono);        }
    if (pin !== undefined)             { sets.push(`pin = $${params.length + 1}`);             params.push(pin);             }
    if (rol !== undefined)             { sets.push(`rol = $${params.length + 1}`);             params.push(rol);             }
    if (zona !== undefined)            { sets.push(`zona = $${params.length + 1}`);            params.push(zona);            }
    if (activo !== undefined)          { sets.push(`activo = $${params.length + 1}`);          params.push(activo);          }
    if (password)                      {
      const hash = await bcrypt.hash(password, 10);
      sets.push(`password_hash = $${params.length + 1}`);
      params.push(hash);
    }

    if (!sets.length) return res.status(400).json({ success: false, error: 'Sin campos para actualizar' });

    params.push(id);
    const result = await pool.query(
      `UPDATE trabajador SET ${sets.join(', ')} WHERE trabajador_id = $${params.length}
       RETURNING trabajador_id, cod_cosechero, nombre_completo, rol, zona, activo`,
      params
    );
    if (!result.rows.length) return res.status(404).json({ success: false, error: 'Trabajador no encontrado' });
    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    console.error('[trabajadores/PUT]', err.message);
    res.status(500).json({ success: false, error: 'Error del servidor' });
  }
});

// GET /trabajadores/:id/resumen — earnings summary for gamification
router.get('/:id/resumen', requireAuth, async (req, res) => {
  const { id } = req.params;
  const now = new Date();
  // Quincena: 1–15 or 16–end of month (Bogota approx)
  const day = now.getDate();
  const periodoInicio = new Date(now.getFullYear(), now.getMonth(), day <= 15 ? 1 : 16);
  const periodoFin = day <= 15
    ? new Date(now.getFullYear(), now.getMonth(), 15)
    : new Date(now.getFullYear(), now.getMonth() + 1, 0);

  try {
    const trabajadorRes = await pool.query(
      'SELECT trabajador_id, cod_cosechero, nombre_completo, rol, zona FROM trabajador WHERE trabajador_id = $1',
      [id]
    );
    if (!trabajadorRes.rows.length) return res.status(404).json({ success: false, error: 'Trabajador no encontrado' });

    const cosechaRes = await pool.query(
      `SELECT COALESCE(SUM(total_racimos),0) AS total_racimos,
              COALESCE(SUM(peso_extractora_sin_recolector),0) AS total_kg
       FROM cosecha
       WHERE trabajador_id = $1 AND fecha_corte BETWEEN $2 AND $3`,
      [id, periodoInicio, periodoFin]
    );

    const diasRes = await pool.query(
      `SELECT COUNT(DISTINCT fecha_corte) AS dias_trabajados
       FROM cosecha WHERE trabajador_id = $1 AND fecha_corte BETWEEN $2 AND $3`,
      [id, periodoInicio, periodoFin]
    );

    res.json({
      success: true,
      data: {
        trabajador: trabajadorRes.rows[0],
        quincena: { inicio: periodoInicio, fin: periodoFin },
        total_racimos: parseInt(cosechaRes.rows[0].total_racimos),
        total_kg: parseFloat(cosechaRes.rows[0].total_kg),
        dias_trabajados: parseInt(diasRes.rows[0].dias_trabajados),
      },
    });
  } catch (err) {
    console.error('[trabajadores/resumen]', err.message);
    res.status(500).json({ success: false, error: 'Error del servidor' });
  }
});

module.exports = router;
