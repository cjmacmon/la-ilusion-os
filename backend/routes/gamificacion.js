const express = require('express');
const router = express.Router();
const pool = require('../db/pool');
const { requireAuth } = require('../middleware/auth');

// GET /gamificacion/:cod_cosechero/hoy
router.get('/:cod_cosechero/hoy', requireAuth, async (req, res) => {
  const { cod_cosechero } = req.params;

  try {
    const trabajadorRes = await pool.query(
      'SELECT * FROM trabajador WHERE cod_cosechero = $1 AND activo = TRUE',
      [cod_cosechero]
    );
    if (!trabajadorRes.rows.length) {
      return res.status(404).json({ success: false, error: 'Trabajador no encontrado' });
    }
    const t = trabajadorRes.rows[0];

    const today = new Date().toISOString().slice(0, 10);
    const now = new Date();
    const day = now.getDate();
    const periodoInicio = new Date(now.getFullYear(), now.getMonth(), day <= 15 ? 1 : 16)
      .toISOString().slice(0, 10);
    const weekAgo = new Date(Date.now() - 7 * 864e5).toISOString().slice(0, 10);

    const [
      hoyRes, quinRes, diasRes, tarifasRes, incentivosRes, leaderboardRes
    ] = await Promise.all([
      // Today's harvest
      pool.query(
        `SELECT COALESCE(SUM(c.total_racimos),0) AS racimos_hoy,
                COALESCE(SUM(c.peso_extractora_sin_recolector),0) AS kg_hoy
         FROM cosecha c WHERE c.trabajador_id = $1 AND c.fecha_corte = $2`,
        [t.trabajador_id, today]
      ),
      // Quincena totals
      pool.query(
        `SELECT COALESCE(SUM(c.total_racimos),0) AS racimos_quincena,
                COALESCE(SUM(c.peso_extractora_sin_recolector),0) AS kg_quincena
         FROM cosecha c WHERE c.trabajador_id = $1 AND c.fecha_corte >= $2`,
        [t.trabajador_id, periodoInicio]
      ),
      // Dias trabajados quincena
      pool.query(
        `SELECT COUNT(DISTINCT fecha_corte) AS dias FROM cosecha
         WHERE trabajador_id = $1 AND fecha_corte >= $2`,
        [t.trabajador_id, periodoInicio]
      ),
      // Active tarifas for worker's zona
      pool.query(
        `SELECT tipo_labor, precio_por_kg, precio_por_unidad FROM tarifa
         WHERE activa = TRUE AND (zona = $1 OR zona IS NULL)
         ORDER BY zona NULLS LAST`,
        [t.zona]
      ),
      // Active incentivos
      pool.query('SELECT * FROM incentivo WHERE activo = TRUE ORDER BY umbral'),
      // Leaderboard: top 7 by racimos this week
      pool.query(
        `SELECT t2.nombre_completo, t2.cod_cosechero,
                COALESCE(SUM(c2.total_racimos),0) AS racimos_semana
         FROM trabajador t2
         LEFT JOIN cosecha c2 ON c2.trabajador_id = t2.trabajador_id
           AND c2.fecha_corte BETWEEN $1 AND $2
         WHERE t2.rol IN ('cosechador','recolector') AND t2.activo = TRUE
         GROUP BY t2.trabajador_id, t2.nombre_completo, t2.cod_cosechero
         ORDER BY racimos_semana DESC`,
        [weekAgo, today]
      ),
    ]);

    const racimos_hoy = parseInt(hoyRes.rows[0].racimos_hoy);
    const kg_hoy = parseFloat(hoyRes.rows[0].kg_hoy);
    const racimos_quincena = parseInt(quinRes.rows[0].racimos_quincena);
    const dias_trabajados_quincena = parseInt(diasRes.rows[0].dias);

    // Estimate today's earnings from local tarifas
    const tarifaMap = {};
    for (const row of tarifasRes.rows) {
      if (!tarifaMap[row.tipo_labor]) tarifaMap[row.tipo_labor] = row;
    }
    const precioKg = tarifaMap['cosecha_recolector']
      ? parseFloat(tarifaMap['cosecha_recolector'].precio_por_kg || 0)
      : (tarifaMap['cosecha_mecanizada']
        ? parseFloat(tarifaMap['cosecha_mecanizada'].precio_por_kg || 0)
        : 0);
    const ganancias_hoy_cop = Math.round(kg_hoy * precioKg);

    // Quincena earnings (simplified — full engine in /liquidacion/calcular)
    const ganancias_quincena_cop = Math.round(parseFloat(quinRes.rows[0].kg_quincena) * precioKg);

    // Next milestone bono
    let proximo_bono = null;
    for (const inc of incentivosRes.rows) {
      if (inc.tipo === 'dias_trabajados') {
        const progreso = Math.min(dias_trabajados_quincena, parseFloat(inc.umbral));
        if (dias_trabajados_quincena < parseFloat(inc.umbral)) {
          proximo_bono = {
            nombre: inc.nombre,
            umbral: parseFloat(inc.umbral),
            progreso,
            monto_cop: parseFloat(inc.monto_bono),
            tipo: inc.tipo,
          };
          break;
        }
      } else if (inc.tipo === 'racimos_quincena') {
        const progreso = Math.min(racimos_quincena, parseFloat(inc.umbral));
        if (racimos_quincena < parseFloat(inc.umbral)) {
          proximo_bono = proximo_bono || {
            nombre: inc.nombre,
            umbral: parseFloat(inc.umbral),
            progreso,
            monto_cop: parseFloat(inc.monto_bono),
            tipo: inc.tipo,
          };
        }
      }
    }

    // Leaderboard: top 7 only, find worker's position in full list
    const allRanked = leaderboardRes.rows.map((r, i) => ({ ...r, posicion: i + 1 }));
    const top7 = allRanked.slice(0, 7).map(r => ({
      nombre: r.nombre_completo,
      racimos_semana: parseInt(r.racimos_semana),
      posicion: r.posicion,
      es_yo: r.cod_cosechero === cod_cosechero,
    }));
    const miRanking = allRanked.find(r => r.cod_cosechero === cod_cosechero);
    const posicion_leaderboard = miRanking ? miRanking.posicion : null;

    res.json({
      success: true,
      data: {
        racimos_hoy,
        kg_hoy,
        ganancias_hoy_cop,
        ganancias_quincena_cop,
        dias_trabajados_quincena,
        racimos_quincena,
        proximo_bono,
        posicion_leaderboard,
        leaderboard_top7: top7,
      },
    });
  } catch (err) {
    console.error('[gamificacion/hoy]', err.message);
    res.status(500).json({ success: false, error: 'Error del servidor' });
  }
});

module.exports = router;
