const pool = require('../db/pool');

const VALOR_DIA_BASE = 50000; // COP — deduction per unjustified absence day

async function getTarifas(zona) {
  const result = await pool.query(
    `SELECT tipo_labor, zona, precio_por_kg, precio_por_unidad
     FROM tarifa
     WHERE activa = TRUE AND (zona = $1 OR zona IS NULL)
     ORDER BY zona NULLS LAST`,
    [zona]
  );
  const map = {};
  for (const row of result.rows) {
    // zona-specific rate wins over generic (zona IS NULL)
    if (!map[row.tipo_labor] || row.zona !== null) {
      map[row.tipo_labor] = row;
    }
  }
  return map;
}

async function calcularLiquidacion(trabajador_id, periodo_inicio, periodo_fin) {
  // Load worker
  const trabajadorRes = await pool.query(
    'SELECT trabajador_id, cod_cosechero, nombre_completo, rol, zona FROM trabajador WHERE trabajador_id = $1',
    [trabajador_id]
  );
  if (!trabajadorRes.rows.length) throw new Error('Trabajador no encontrado');
  const trabajador = trabajadorRes.rows[0];

  const tarifas = await getTarifas(trabajador.zona);

  // ── COSECHA ──────────────────────────────────────────────
  const cosechaRes = await pool.query(
    `SELECT c.*, l.zona AS lote_zona
     FROM cosecha c
     JOIN lote l ON l.lote_id = c.lote_id
     WHERE c.trabajador_id = $1
       AND c.fecha_corte BETWEEN $2 AND $3`,
    [trabajador_id, periodo_inicio, periodo_fin]
  );
  const cosechaRows = cosechaRes.rows;

  let monto_cosecha = 0;
  let total_racimos = 0;
  let total_kg = 0;
  const cosecha_detalle = [];

  for (const c of cosechaRows) {
    const zona = c.lote_zona || trabajador.zona;
    const tarifasZona = await getTarifas(zona);

    let subtotal = 0;
    if (c.tipo_cosecha === 'RECOLECTOR_DE_RACIMOS') {
      const tarifa = tarifasZona['cosecha_recolector'];
      const precio = tarifa ? parseFloat(tarifa.precio_por_kg) : 0;
      const pago_principal = parseFloat(c.peso_extractora_sin_recolector || 0) * precio;
      const pago_recolector = parseFloat(c.peso_extractora_recolector || 0) * precio;
      subtotal = pago_principal + pago_recolector;
    } else {
      const tarifa = tarifasZona['cosecha_mecanizada'];
      const precio = tarifa ? parseFloat(tarifa.precio_por_kg) : 0;
      subtotal = parseFloat(c.peso_extractora_sin_recolector || 0) * precio;
    }

    monto_cosecha += subtotal;
    total_racimos += parseInt(c.total_racimos || 0);
    total_kg += parseFloat(c.peso_extractora_sin_recolector || 0);
    cosecha_detalle.push({
      cosecha_id: c.cosecha_id,
      fecha_corte: c.fecha_corte,
      tipo_cosecha: c.tipo_cosecha,
      total_racimos: c.total_racimos,
      peso_kg: c.peso_extractora_sin_recolector,
      subtotal_cop: Math.round(subtotal),
    });
  }

  // ── FERTILIZACIÓN ─────────────────────────────────────────
  const fertRes = await pool.query(
    `SELECT f.*, l.zona AS lote_zona
     FROM fertilizacion f
     JOIN lote l ON l.lote_id = f.lote_id
     WHERE f.trabajador_id = $1
       AND f.fecha BETWEEN $2 AND $3`,
    [trabajador_id, periodo_inicio, periodo_fin]
  );

  let monto_fertilizacion = 0;
  const fertilizacion_detalle = [];

  for (const f of fertRes.rows) {
    const zona = f.lote_zona || trabajador.zona;
    const tarifasZona = await getTarifas(zona);
    const tarifa = tarifasZona['fertilizacion'];
    const precio = tarifa ? parseFloat(tarifa.precio_por_unidad) : 0;
    const subtotal = parseFloat(f.total_aplicado || 0) * precio;
    monto_fertilizacion += subtotal;
    fertilizacion_detalle.push({
      fertilizacion_id: f.fertilizacion_id,
      fecha: f.fecha,
      palmas: f.palmas_fertilizadas,
      total_aplicado: f.total_aplicado,
      subtotal_cop: Math.round(subtotal),
    });
  }

  // ── DÍAS TRABAJADOS ───────────────────────────────────────
  const diasRes = await pool.query(
    `SELECT COUNT(DISTINCT fecha_corte) AS dias
     FROM cosecha
     WHERE trabajador_id = $1 AND fecha_corte BETWEEN $2 AND $3`,
    [trabajador_id, periodo_inicio, periodo_fin]
  );
  const dias_trabajados = parseInt(diasRes.rows[0].dias || 0);

  // ── AUSENCIAS INJUSTIFICADAS ──────────────────────────────
  const ausenciaRes = await pool.query(
    `SELECT COUNT(*) AS dias_ausencia
     FROM ausencia
     WHERE trabajador_id = $1
       AND fecha BETWEEN $2 AND $3
       AND justificada = FALSE`,
    [trabajador_id, periodo_inicio, periodo_fin]
  );
  const dias_ausencia_injustificada = parseInt(ausenciaRes.rows[0].dias_ausencia || 0);
  const deducciones = dias_ausencia_injustificada * VALOR_DIA_BASE;

  // ── BONOS ─────────────────────────────────────────────────
  const incentivosRes = await pool.query('SELECT * FROM incentivo WHERE activo = TRUE');
  let monto_bonos = 0;
  const bonos_detalle = [];

  for (const inc of incentivosRes.rows) {
    let califica = false;
    if (inc.tipo === 'dias_trabajados' && dias_trabajados >= parseFloat(inc.umbral)) {
      califica = true;
    } else if (inc.tipo === 'racimos_quincena' && total_racimos >= parseFloat(inc.umbral)) {
      califica = true;
    }
    if (califica) {
      monto_bonos += parseFloat(inc.monto_bono);
      bonos_detalle.push({ incentivo_id: inc.incentivo_id, nombre: inc.nombre, monto: inc.monto_bono });
    }
  }

  // ── TOTAL ─────────────────────────────────────────────────
  const total_pagar = monto_cosecha + monto_fertilizacion + monto_bonos - deducciones;

  return {
    trabajador,
    periodo_inicio,
    periodo_fin,
    dias_trabajados,
    dias_ausencia_injustificada,
    total_racimos,
    total_kg: Math.round(total_kg * 100) / 100,
    monto_cosecha: Math.round(monto_cosecha),
    monto_fertilizacion: Math.round(monto_fertilizacion),
    monto_bonos: Math.round(monto_bonos),
    deducciones: Math.round(deducciones),
    total_pagar: Math.round(total_pagar),
    detalle: { cosecha: cosecha_detalle, fertilizacion: fertilizacion_detalle, bonos: bonos_detalle },
  };
}

module.exports = { calcularLiquidacion };
