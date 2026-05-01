const express = require('express');
const router = express.Router();
const pool = require('../db/pool');
const { requireAuth, requireRole } = require('../middleware/auth');

// GET /dashboard/kpis
router.get('/kpis', requireAuth, requireRole('admin', 'supervisor'), async (req, res) => {
  try {
    const today = new Date().toISOString().slice(0, 10);
    const weekAgo = new Date(Date.now() - 7 * 864e5).toISOString().slice(0, 10);

    const [racimosHoy, racimosWeek, trabajadoresHoy, pagosPendientes, produccionZona, topTrabajadores, pendientesSync] =
      await Promise.all([
        // Racimos + kg hoy
        pool.query(
          `SELECT COALESCE(SUM(total_racimos),0) AS racimos_hoy,
                  COALESCE(SUM(peso_extractora_sin_recolector),0) AS kg_hoy
           FROM cosecha WHERE fecha_corte = $1`,
          [today]
        ),
        // Racimos semana
        pool.query(
          `SELECT COALESCE(SUM(total_racimos),0) AS racimos_semana,
                  COALESCE(SUM(peso_extractora_sin_recolector),0) AS kg_semana
           FROM cosecha WHERE fecha_corte BETWEEN $1 AND $2`,
          [weekAgo, today]
        ),
        // Trabajadores activos hoy
        pool.query(
          `SELECT COUNT(DISTINCT trabajador_id) AS trabajadores_activos_hoy
           FROM cosecha WHERE fecha_corte = $1`,
          [today]
        ),
        // Pagos pendientes
        pool.query(
          `SELECT COALESCE(SUM(total_pagar),0) AS pagos_pendientes_cop
           FROM liquidacion WHERE estado = 'pendiente'`
        ),
        // Producción por zona (últimos 7 días)
        pool.query(
          `SELECT l.zona,
                  COALESCE(SUM(c.total_racimos),0) AS racimos,
                  COALESCE(SUM(c.peso_extractora_sin_recolector),0) AS kg
           FROM cosecha c
           JOIN lote l ON l.lote_id = c.lote_id
           WHERE c.fecha_corte BETWEEN $1 AND $2
           GROUP BY l.zona ORDER BY l.zona`,
          [weekAgo, today]
        ),
        // Top 7 trabajadores esta semana
        pool.query(
          `SELECT t.nombre_completo, t.cod_cosechero,
                  COALESCE(SUM(c.total_racimos),0) AS racimos_semana
           FROM trabajador t
           LEFT JOIN cosecha c ON c.trabajador_id = t.trabajador_id
             AND c.fecha_corte BETWEEN $1 AND $2
           WHERE t.rol IN ('cosechador','recolector')
           GROUP BY t.trabajador_id, t.nombre_completo, t.cod_cosechero
           ORDER BY racimos_semana DESC
           LIMIT 7`,
          [weekAgo, today]
        ),
        // Registros pendientes sync
        pool.query(
          `SELECT
             (SELECT COUNT(*) FROM cosecha WHERE sync_status = 'pending') +
             (SELECT COUNT(*) FROM fertilizacion WHERE sync_status = 'pending') AS total_pending`
        ),
      ]);

    res.json({
      success: true,
      data: {
        racimos_hoy: parseInt(racimosHoy.rows[0].racimos_hoy),
        kg_hoy: parseFloat(racimosHoy.rows[0].kg_hoy),
        racimos_semana: parseInt(racimosWeek.rows[0].racimos_semana),
        kg_semana: parseFloat(racimosWeek.rows[0].kg_semana),
        trabajadores_activos_hoy: parseInt(trabajadoresHoy.rows[0].trabajadores_activos_hoy),
        pagos_pendientes_cop: parseFloat(pagosPendientes.rows[0].pagos_pendientes_cop),
        produccion_por_zona: produccionZona.rows,
        top_trabajadores_semana: topTrabajadores.rows.map((r, i) => ({ ...r, posicion: i + 1 })),
        registros_pendientes_sync: parseInt(pendientesSync.rows[0].total_pending),
      },
    });
  } catch (err) {
    console.error('[dashboard/kpis]', err.message);
    res.status(500).json({ success: false, error: 'Error del servidor' });
  }
});

module.exports = router;
