import { useState, useEffect, useMemo } from 'react';
import {
  getTarifasLaboral,
  getTarifasLaboralHistorico,
  getTarifasLaboralAreas,
  updateTarifaLaboral,
} from '../services/api';

// ─── helpers ──────────────────────────────────────────────────────────────────

const COP = (n) => {
  if (n == null) return '—';
  const num = parseFloat(n);
  if (Number.isInteger(num))
    return new Intl.NumberFormat('es-CO', { style: 'currency', currency: 'COP', maximumFractionDigits: 0 }).format(num);
  return new Intl.NumberFormat('es-CO', { style: 'currency', currency: 'COP', minimumFractionDigits: 2, maximumFractionDigits: 4 }).format(num);
};

const fmtDate = (d) => d ? new Date(d).toLocaleDateString('es-CO') : '—';

const AREA_META = {
  Cosecha:        { icon: '🌴', color: '#166534', bg: '#dcfce7', label: 'Cosecha' },
  Fertilizacion:  { icon: '🌱', color: '#065f46', bg: '#d1fae5', label: 'Fertilización' },
  Mantenimiento:  { icon: '🔧', color: '#92400e', bg: '#fef3c7', label: 'Mantenimiento' },
  LABORAL:        { icon: '👷', color: '#7c2d12', bg: '#ffedd5', label: 'Laboral' },
  Cablevia:       { icon: '🔗', color: '#1e3a5f', bg: '#dbeafe', label: 'Cablevia' },
  Cercas:         { icon: '🔒', color: '#4a1d96', bg: '#ede9fe', label: 'Cercas' },
  Drenajes:       { icon: '💧', color: '#0c4a6e', bg: '#e0f2fe', label: 'Drenajes' },
  Sanidad:        { icon: '🛡️', color: '#7f1d1d', bg: '#fee2e2', label: 'Sanidad' },
};

const getAreaMeta = (area) =>
  AREA_META[area] ?? { icon: '📋', color: '#374151', bg: '#f3f4f6', label: area };

// Group tariffs by actividad, then by a subgroup key (tipo / ubicacion / tipo_palma)
function groupTarifas(rows) {
  const byActividad = {};
  for (const row of rows) {
    const act = row.actividad;
    if (!byActividad[act]) byActividad[act] = [];
    byActividad[act].push(row);
  }
  return byActividad;
}

// Build a human-readable subtitle for a tariff row
function rowSubtitle(row) {
  const parts = [];
  if (row.tipo) parts.push(row.tipo);
  if (row.tipo_palma) parts.push(row.tipo_palma);
  if (row.producto) parts.push(row.producto);
  if (row.cable) parts.push(`Cable ${row.cable}`);
  if (row.propiedad_equipo) parts.push(`Equipo ${row.propiedad_equipo}`);
  if (row.ubicacion) parts.push(row.ubicacion.replace('_', ' '));
  if (row.rango && row.unidad_rango) parts.push(`${row.rango} ${row.unidad_rango}`);
  return parts.join(' · ') || row.descripcion_labor || '';
}

// ─── edit modal ───────────────────────────────────────────────────────────────

function EditModal({ row, onClose, onSaved }) {
  const [value, setValue] = useState(String(parseFloat(row.tarifa)));
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  const handleSave = async () => {
    if (!value || isNaN(parseFloat(value))) { setError('Ingresa un valor válido'); return; }
    setSaving(true);
    try {
      await updateTarifaLaboral(row.id, { tarifa: parseFloat(value) });
      onSaved();
    } catch {
      setError('Error al guardar. Intenta de nuevo.');
    }
    setSaving(false);
  };

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center"
      style={{ background: 'rgba(0,0,0,0.45)', backdropFilter: 'blur(2px)' }}
      onClick={(e) => e.target === e.currentTarget && onClose()}
    >
      <div
        className="bg-white rounded-2xl shadow-2xl p-7 w-full max-w-md"
        style={{ fontFamily: "'DM Sans', sans-serif" }}
      >
        <div className="mb-1 text-xs font-bold tracking-widest text-gray-400 uppercase">
          {row.codigo_tarifa}
        </div>
        <h3 className="text-lg font-bold text-gray-900 mb-1">
          {row.actividad}
          {row.tipo ? <span className="font-normal text-gray-500"> — {row.tipo}</span> : null}
        </h3>
        <p className="text-sm text-gray-500 mb-6">{rowSubtitle(row)}</p>

        <div className="mb-5">
          <label className="block text-xs font-semibold text-gray-600 mb-2 uppercase tracking-wide">
            Nueva tarifa (COP / {row.unidad_tarifa})
          </label>
          <div className="relative">
            <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-sm font-bold">$</span>
            <input
              type="number"
              step="0.01"
              value={value}
              onChange={(e) => { setValue(e.target.value); setError(''); }}
              className="w-full border-2 border-gray-200 rounded-xl pl-7 pr-4 py-3 text-lg font-bold
                         focus:outline-none focus:border-green-600 transition-colors"
              autoFocus
            />
          </div>
          <p className="text-xs text-gray-400 mt-1.5">
            Valor actual: {COP(row.tarifa)} / {row.unidad_tarifa}
          </p>
          {error && <p className="text-xs text-red-500 mt-1">{error}</p>}
        </div>

        <div className="bg-amber-50 border border-amber-200 rounded-xl p-3 mb-6 text-xs text-amber-700">
          <strong>Historial preservado:</strong> La tarifa anterior quedará registrada con fecha de cierre.
        </div>

        <div className="flex gap-3">
          <button
            onClick={handleSave}
            disabled={saving}
            className="flex-1 py-3 rounded-xl font-bold text-white text-sm transition-opacity
                       disabled:opacity-50"
            style={{ background: '#1B4332' }}
          >
            {saving ? 'Guardando...' : 'Guardar nueva tarifa'}
          </button>
          <button
            onClick={onClose}
            className="px-5 py-3 rounded-xl border-2 border-gray-200 text-gray-600 text-sm font-semibold hover:border-gray-300 transition-colors"
          >
            Cancelar
          </button>
        </div>
      </div>
    </div>
  );
}

// ─── tariff table for a selected area ─────────────────────────────────────────

function TarifaTable({ rows, isHistoric, onEdit }) {
  const grouped = useMemo(() => groupTarifas(rows), [rows]);
  const meta = getAreaMeta(rows[0]?.area);

  return (
    <div className="space-y-6">
      {Object.entries(grouped).map(([actividad, items]) => (
        <div key={actividad} className="rounded-2xl border border-gray-100 overflow-hidden shadow-sm">
          {/* Actividad header */}
          <div
            className="px-5 py-3 flex items-center justify-between"
            style={{ background: meta.bg }}
          >
            <span className="font-bold text-sm" style={{ color: meta.color }}>
              {actividad}
            </span>
            <span
              className="text-xs font-semibold px-2 py-0.5 rounded-full"
              style={{ background: meta.color, color: '#fff', opacity: 0.85 }}
            >
              {items.length} tarifa{items.length !== 1 ? 's' : ''}
            </span>
          </div>

          {/* Rows */}
          <table className="w-full text-sm">
            <colgroup>
              <col style={{ width: '38%' }} />
              <col style={{ width: '20%' }} />
              <col style={{ width: '18%' }} />
              <col style={{ width: '14%' }} />
              {!isHistoric && <col style={{ width: '10%' }} />}
            </colgroup>
            <thead className="bg-gray-50 border-b border-gray-100">
              <tr>
                <th className="px-4 py-2.5 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">Detalle</th>
                <th className="px-4 py-2.5 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">Código</th>
                <th className="px-4 py-2.5 text-right text-xs font-semibold text-gray-500 uppercase tracking-wide">Tarifa</th>
                <th className="px-4 py-2.5 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">Unidad</th>
                {!isHistoric && <th className="px-4 py-2.5" />}
              </tr>
            </thead>
            <tbody>
              {items.map((row, i) => (
                <tr
                  key={row.id}
                  className={`border-t border-gray-50 transition-colors ${!isHistoric ? 'hover:bg-gray-50/70' : ''}`}
                  style={{ background: i % 2 === 0 ? '#fff' : '#fafafa' }}
                >
                  <td className="px-4 py-3">
                    <div className="text-gray-800 font-medium leading-snug">{rowSubtitle(row) || '—'}</div>
                    {row.descripcion_labor && (
                      <div className="text-xs text-gray-400 mt-0.5">{row.descripcion_labor}</div>
                    )}
                  </td>
                  <td className="px-4 py-3">
                    <span
                      className="inline-block px-2 py-0.5 rounded text-xs font-mono font-bold"
                      style={{ background: meta.bg, color: meta.color }}
                    >
                      {row.codigo_tarifa || '—'}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-right font-bold" style={{ color: '#1B4332' }}>
                    {COP(row.tarifa)}
                  </td>
                  <td className="px-4 py-3 text-xs text-gray-500 font-medium">
                    {row.unidad_tarifa}
                  </td>
                  {!isHistoric && (
                    <td className="px-4 py-3 text-right">
                      <button
                        onClick={() => onEdit(row)}
                        className="text-xs font-semibold px-3 py-1 rounded-lg border transition-colors hover:border-green-600 hover:text-green-700"
                        style={{ color: '#1B4332', borderColor: '#d1d5db' }}
                      >
                        Editar
                      </button>
                    </td>
                  )}
                </tr>
              ))}
            </tbody>
          </table>

          {/* Footer: vigencia */}
          {isHistoric && items[0]?.fecha_inicio && (
            <div className="px-5 py-2 bg-gray-50 border-t border-gray-100 text-xs text-gray-400">
              Vigente desde {fmtDate(items[0].fecha_inicio)}
              {items[0].fecha_fin ? ` hasta ${fmtDate(items[0].fecha_fin)}` : ' · sin fecha de cierre'}
            </div>
          )}
        </div>
      ))}
    </div>
  );
}

// ─── main page ────────────────────────────────────────────────────────────────

export default function TarifasPage() {
  const [mode, setMode] = useState('vigentes'); // 'vigentes' | 'historico'
  const [areas, setAreas] = useState([]);
  const [selectedArea, setSelectedArea] = useState(null);
  const [tarifas, setTarifas] = useState([]);
  const [loading, setLoading] = useState(true);
  const [editRow, setEditRow] = useState(null);
  const [historicDate, setHistoricDate] = useState(
    new Date().toISOString().slice(0, 10)
  );
  const [historicData, setHistoricData] = useState([]);
  const [loadingHistoric, setLoadingHistoric] = useState(false);

  // Load areas + all active tariffs on mount
  useEffect(() => {
    setLoading(true);
    Promise.all([getTarifasLaboralAreas(), getTarifasLaboral()])
      .then(([areasRes, tarifasRes]) => {
        const areaList = areasRes.data.data;
        setAreas(areaList);
        setTarifas(tarifasRes.data.data);
        if (areaList.length > 0 && !selectedArea) setSelectedArea(areaList[0].area);
      })
      .finally(() => setLoading(false));
  }, []);

  // Load historic data when date changes (in historic mode)
  useEffect(() => {
    if (mode !== 'historico') return;
    setLoadingHistoric(true);
    getTarifasLaboralHistorico(historicDate)
      .then((r) => setHistoricData(r.data.data))
      .finally(() => setLoadingHistoric(false));
  }, [mode, historicDate]);

  const reload = () => {
    Promise.all([getTarifasLaboralAreas(), getTarifasLaboral()]).then(
      ([areasRes, tarifasRes]) => {
        setAreas(areasRes.data.data);
        setTarifas(tarifasRes.data.data);
      }
    );
  };

  const activeRows = useMemo(() => {
    const source = mode === 'historico' ? historicData : tarifas;
    return source.filter((r) => r.area === selectedArea);
  }, [mode, tarifas, historicData, selectedArea]);

  const totalTarifas = tarifas.length;

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-gray-400 text-sm animate-pulse">Cargando catálogo de tarifas…</div>
      </div>
    );
  }

  return (
    <div
      className="min-h-screen"
      style={{ background: '#f8f7f4', fontFamily: "'DM Sans', sans-serif" }}
    >
      {/* Page header */}
      <div
        className="border-b border-gray-200"
        style={{ background: '#fff' }}
      >
        <div className="max-w-7xl mx-auto px-6 py-5 flex flex-col sm:flex-row sm:items-end gap-4 justify-between">
          <div>
            <p className="text-xs font-bold tracking-widest text-gray-400 uppercase mb-1">
              Hacienda La Ilusión
            </p>
            <h1
              className="text-2xl font-bold text-gray-900"
              style={{ fontFamily: "'Playfair Display', serif", letterSpacing: '-0.02em' }}
            >
              Catálogo de Tarifas
            </h1>
            <p className="text-sm text-gray-500 mt-1">
              {totalTarifas} tarifas activas · {areas.length} áreas de trabajo
            </p>
          </div>

          {/* Mode toggle */}
          <div
            className="flex rounded-xl border border-gray-200 overflow-hidden self-start sm:self-auto"
            style={{ background: '#f3f4f6' }}
          >
            {['vigentes', 'historico'].map((m) => (
              <button
                key={m}
                onClick={() => setMode(m)}
                className="px-5 py-2.5 text-sm font-semibold transition-all"
                style={
                  mode === m
                    ? { background: '#1B4332', color: '#fff', borderRadius: '10px' }
                    : { color: '#6b7280' }
                }
              >
                {m === 'vigentes' ? '✓ Vigentes' : '📅 Histórico'}
              </button>
            ))}
          </div>
        </div>

        {/* Historic date bar */}
        {mode === 'historico' && (
          <div
            className="border-t border-amber-100 px-6 py-3 flex items-center gap-4"
            style={{ background: '#fffbeb' }}
          >
            <span className="text-sm text-amber-700 font-semibold">Consultar tarifas vigentes al:</span>
            <input
              type="date"
              value={historicDate}
              max={new Date().toISOString().slice(0, 10)}
              onChange={(e) => setHistoricDate(e.target.value)}
              className="border border-amber-300 rounded-lg px-3 py-1.5 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-amber-400"
            />
            {loadingHistoric && (
              <span className="text-xs text-amber-500 animate-pulse">Cargando…</span>
            )}
            {!loadingHistoric && (
              <span className="text-xs text-amber-600 font-medium">
                {historicData.length} tarifa{historicData.length !== 1 ? 's' : ''} activa{historicData.length !== 1 ? 's' : ''} en esa fecha
              </span>
            )}
          </div>
        )}
      </div>

      {/* Body */}
      <div className="max-w-7xl mx-auto px-6 py-6 flex gap-6">
        {/* Left sidebar — area nav */}
        <aside className="hidden md:flex flex-col gap-1.5 w-52 shrink-0">
          <p className="text-xs font-bold tracking-widest text-gray-400 uppercase px-2 mb-2">
            Áreas
          </p>
          {areas.map(({ area, total }) => {
            const meta = getAreaMeta(area);
            const isActive = area === selectedArea;
            return (
              <button
                key={area}
                onClick={() => setSelectedArea(area)}
                className="flex items-center gap-3 px-3 py-2.5 rounded-xl text-left transition-all w-full group"
                style={
                  isActive
                    ? { background: meta.bg, border: `1.5px solid ${meta.color}20` }
                    : { background: 'transparent', border: '1.5px solid transparent' }
                }
              >
                <span className="text-base leading-none">{meta.icon}</span>
                <div className="flex-1 min-w-0">
                  <div
                    className="text-sm font-semibold truncate"
                    style={{ color: isActive ? meta.color : '#374151' }}
                  >
                    {meta.label}
                  </div>
                </div>
                <span
                  className="text-xs font-bold tabular-nums px-1.5 py-0.5 rounded-md"
                  style={
                    isActive
                      ? { background: meta.color, color: '#fff' }
                      : { background: '#e5e7eb', color: '#6b7280' }
                  }
                >
                  {total}
                </span>
              </button>
            );
          })}
        </aside>

        {/* Mobile area selector */}
        <div className="md:hidden w-full mb-4">
          <select
            value={selectedArea || ''}
            onChange={(e) => setSelectedArea(e.target.value)}
            className="w-full border-2 border-gray-200 rounded-xl px-4 py-2.5 text-sm font-semibold focus:outline-none focus:border-green-600"
          >
            {areas.map(({ area, total }) => (
              <option key={area} value={area}>
                {getAreaMeta(area).icon} {getAreaMeta(area).label} ({total})
              </option>
            ))}
          </select>
        </div>

        {/* Main content */}
        <main className="flex-1 min-w-0">
          {selectedArea && (
            <div className="mb-4 flex items-center gap-3">
              <span className="text-2xl">{getAreaMeta(selectedArea).icon}</span>
              <div>
                <h2
                  className="text-lg font-bold"
                  style={{ color: getAreaMeta(selectedArea).color, fontFamily: "'Playfair Display', serif" }}
                >
                  {getAreaMeta(selectedArea).label}
                </h2>
                {mode === 'historico' && (
                  <p className="text-xs text-amber-600 font-medium">
                    Vista histórica — {new Date(historicDate + 'T12:00:00').toLocaleDateString('es-CO', { dateStyle: 'long' })}
                  </p>
                )}
              </div>
            </div>
          )}

          {activeRows.length === 0 ? (
            <div className="flex flex-col items-center justify-center h-48 text-center">
              <div className="text-4xl mb-3">
                {mode === 'historico' ? '📅' : '📋'}
              </div>
              <p className="text-gray-500 font-medium">
                {mode === 'historico'
                  ? 'No hay tarifas registradas para esa fecha en esta área'
                  : 'No hay tarifas activas en esta área'}
              </p>
            </div>
          ) : (
            <TarifaTable
              rows={activeRows}
              isHistoric={mode === 'historico'}
              onEdit={(row) => setEditRow(row)}
            />
          )}
        </main>
      </div>

      {/* Edit modal */}
      {editRow && (
        <EditModal
          row={editRow}
          onClose={() => setEditRow(null)}
          onSaved={() => {
            setEditRow(null);
            reload();
          }}
        />
      )}
    </div>
  );
}
