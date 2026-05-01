const pool = require('../db/pool');

function formatDateCO(date) {
  if (!date) return '';
  const d = new Date(date);
  const day   = String(d.getUTCDate()).padStart(2, '0');
  const month = String(d.getUTCMonth() + 1).padStart(2, '0');
  const year  = d.getUTCFullYear();
  return `${day}/${month}/${year}`;
}

function formatNumberCO(num) {
  if (num === null || num === undefined) return '0,00';
  const [int, dec] = parseFloat(num).toFixed(2).split('.');
  const intFormatted = int.replace(/\B(?=(\d{3})+(?!\d))/g, '.');
  return `${intFormatted},${dec}`;
}

async function exportLibraCSV(fecha_inicio, fecha_fin) {
  const result = await pool.query(
    `SELECT
       c.fecha_creacion,
       c.ticket_extractora,
       c.cod_cosechero,
       t.nombre_completo AS cosechero,
       l.cod_lote,
       l.nombre AS lote,
       l.zona,
       c.tipo_cosecha,
       c.metodo_recoleccion,
       c.total_racimos,
       c.peso_extractora_sin_recolector
     FROM cosecha c
     JOIN trabajador t ON t.trabajador_id = c.trabajador_id
     JOIN lote l ON l.lote_id = c.lote_id
     WHERE c.fecha_corte BETWEEN $1 AND $2
     ORDER BY c.fecha_corte, c.cod_cosechero`,
    [fecha_inicio, fecha_fin]
  );

  const header = [
    'FECHA CREACION',
    'TICKET EXTRACTORA',
    'COD COSECHERO',
    'COSECHERO',
    'COD LOTE',
    'LOTE',
    'ZONA',
    'TIPO COSECHA',
    'METODO_RECOLECCION',
    'TOTAL RACIMOS',
    'PESO EXTRACTORA SIN RECOLECTOR',
  ].join(',');

  const rows = result.rows.map(r => [
    formatDateCO(r.fecha_creacion),
    r.ticket_extractora || '',
    r.cod_cosechero,
    `"${r.cosechero}"`,
    r.cod_lote,
    `"${r.lote}"`,
    r.zona,
    r.tipo_cosecha,
    r.metodo_recoleccion,
    r.total_racimos,
    formatNumberCO(r.peso_extractora_sin_recolector),
  ].join(','));

  return [header, ...rows].join('\r\n');
}

module.exports = { exportLibraCSV };
