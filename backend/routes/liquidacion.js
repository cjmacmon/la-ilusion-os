const express = require('express');
const router = express.Router();
const pool = require('../db/pool');
const { requireAuth, requireRole } = require('../middleware/auth');
const { calcularLiquidacion } = require('../services/paymentEngine');
const { exportLibraCSV } = require('../services/libraExport');

// POST /liquidacion/calcular
router.post('/calcular', requireAuth, requireRole('admin', 'supervisor'), async (req, res) => {
  const { trabajador_id, periodo_inicio, periodo_fin } = req.body;
  if (!trabajador_id || !periodo_inicio || !periodo_fin) {
    return res.status(400).json({ success: false, error: 'trabajador_id, periodo_inicio y periodo_fin son requeridos' });
  }
  try {
    const resultado = await calcularLiquidacion(trabajador_id, periodo_inicio, periodo_fin);
    res.json({ success: true, data: resultado });
  } catch (err) {
    console.error('[liquidacion/calcular]', err.message);
    res.status(500).json({ success: false, error: err.message });
  }
});

// POST /liquidacion — save a liquidacion after calculation
router.post('/', requireAuth, requireRole('admin'), async (req, res) => {
  const {
    trabajador_id, periodo_inicio, periodo_fin, dias_trabajados,
    dias_ausencia_injustificada, total_racimos, total_kg,
    monto_cosecha, monto_fertilizacion, monto_bonos, deducciones, total_pagar
  } = req.body;

  if (!trabajador_id || !periodo_inicio || !periodo_fin) {
    return res.status(400).json({ success: false, error: 'Campos requeridos faltantes' });
  }
  try {
    const result = await pool.query(
      `INSERT INTO liquidacion (
         trabajador_id, periodo_inicio, periodo_fin, dias_trabajados,
         dias_ausencia_injustificada, total_racimos, total_kg,
         monto_cosecha, monto_fertilizacion, monto_bonos, deducciones, total_pagar, estado
       ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,'pendiente')
       RETURNING *`,
      [
        trabajador_id, periodo_inicio, periodo_fin, dias_trabajados || 0,
        dias_ausencia_injustificada || 0, total_racimos || 0, total_kg || 0,
        monto_cosecha || 0, monto_fertilizacion || 0, monto_bonos || 0,
        deducciones || 0, total_pagar || 0
      ]
    );
    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) {
    console.error('[liquidacion/POST]', err.message);
    res.status(500).json({ success: false, error: 'Error del servidor' });
  }
});

// GET /liquidacion
router.get('/', requireAuth, requireRole('admin', 'supervisor'), async (req, res) => {
  const { trabajador_id, estado, periodo_inicio, periodo_fin } = req.query;
  const conditions = [];
  const params = [];

  if (trabajador_id) { conditions.push(`liq.trabajador_id = $${params.length+1}`); params.push(trabajador_id); }
  if (estado)        { conditions.push(`liq.estado = $${params.length+1}`);         params.push(estado);        }
  if (periodo_inicio){ conditions.push(`liq.periodo_inicio >= $${params.length+1}`);params.push(periodo_inicio);}
  if (periodo_fin)   { conditions.push(`liq.periodo_fin <= $${params.length+1}`);   params.push(periodo_fin);   }

  const where = conditions.length ? 'WHERE ' + conditions.join(' AND ') : '';
  try {
    const result = await pool.query(
      `SELECT liq.*, t.nombre_completo, t.cod_cosechero, t.zona
       FROM liquidacion liq
       JOIN trabajador t ON t.trabajador_id = liq.trabajador_id
       ${where}
       ORDER BY liq.periodo_fin DESC`,
      params
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    console.error('[liquidacion/GET]', err.message);
    res.status(500).json({ success: false, error: 'Error del servidor' });
  }
});

// PUT /liquidacion/:id/estado
router.put('/:id/estado', requireAuth, requireRole('admin'), async (req, res) => {
  const { id } = req.params;
  const { estado, fecha_pago } = req.body;
  if (!estado || !['pendiente','aprobada','pagada'].includes(estado)) {
    return res.status(400).json({ success: false, error: 'estado inválido' });
  }
  try {
    const result = await pool.query(
      `UPDATE liquidacion SET estado = $1, fecha_pago = $2 WHERE liquidacion_id = $3 RETURNING *`,
      [estado, fecha_pago || null, id]
    );
    if (!result.rows.length) return res.status(404).json({ success: false, error: 'Liquidación no encontrada' });
    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    console.error('[liquidacion/estado]', err.message);
    res.status(500).json({ success: false, error: 'Error del servidor' });
  }
});

// GET /liquidacion/export/csv — Libra format
router.get('/export/csv', requireAuth, requireRole('admin', 'supervisor'), async (req, res) => {
  const { fecha_inicio, fecha_fin } = req.query;
  if (!fecha_inicio || !fecha_fin) {
    return res.status(400).json({ success: false, error: 'fecha_inicio y fecha_fin son requeridos' });
  }
  try {
    const csv = await exportLibraCSV(fecha_inicio, fecha_fin);
    const filename = `libra_export_${fecha_inicio}_${fecha_fin}.csv`;
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
    res.send(csv);
  } catch (err) {
    console.error('[liquidacion/export/csv]', err.message);
    res.status(500).json({ success: false, error: 'Error del servidor' });
  }
});

module.exports = router;
