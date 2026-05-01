import { useState, useEffect } from 'react';
import { getLotes, updateLote, getTarifas, createTarifa, exportLibraCSV } from '../services/api';
import { saveAs } from 'file-saver';

const COP = (n) =>
  new Intl.NumberFormat('es-CO', { style: 'currency', currency: 'COP', maximumFractionDigits: 0 }).format(n ?? 0);

const tipoLabel = {
  cosecha_recolector: 'Cosecha — Recolector ($/kg)',
  cosecha_mecanizada: 'Cosecha — Mecanizada ($/kg)',
  fertilizacion: 'Fertilización ($/unidad)',
};

export default function ConfiguracionPage() {
  const [lotes, setLotes] = useState([]);
  const [tarifas, setTarifas] = useState([]);
  const [editLote, setEditLote] = useState(null);
  const [loteData, setLoteData] = useState({});
  const [savingLote, setSavingLote] = useState(false);
  const [tariffForm, setTariffForm] = useState({
    tipo_labor: 'cosecha_recolector', zona: 1,
    precio_por_kg: '', precio_por_unidad: '', fecha_inicio: new Date().toISOString().slice(0,10)
  });
  const [savingTariff, setSavingTariff] = useState(false);
  const [exportRange, setExportRange] = useState({ inicio: '', fin: '' });
  const [exporting, setExporting] = useState(false);

  useEffect(() => {
    getLotes().then((r) => setLotes(r.data.data));
    getTarifas().then((r) => setTarifas(r.data.data));
  }, []);

  const handleSaveLote = async () => {
    setSavingLote(true);
    try {
      await updateLote(editLote.lote_id, loteData);
      const r = await getLotes();
      setLotes(r.data.data);
      setEditLote(null);
    } catch { alert('Error guardando lote'); }
    setSavingLote(false);
  };

  const handleSaveTariff = async () => {
    setSavingTariff(true);
    try {
      const payload = {
        tipo_labor: tariffForm.tipo_labor,
        zona: tariffForm.zona,
        fecha_inicio: tariffForm.fecha_inicio,
        precio_por_kg: tariffForm.tipo_labor !== 'fertilizacion' ? parseFloat(tariffForm.precio_por_kg) || null : null,
        precio_por_unidad: tariffForm.tipo_labor === 'fertilizacion' ? parseFloat(tariffForm.precio_por_unidad) || null : null,
      };
      await createTarifa(payload);
      const r = await getTarifas();
      setTarifas(r.data.data);
    } catch { alert('Error guardando tarifa'); }
    setSavingTariff(false);
  };

  const handleExport = async () => {
    if (!exportRange.inicio || !exportRange.fin) { alert('Selecciona fechas'); return; }
    setExporting(true);
    try {
      const res = await exportLibraCSV({ fecha_inicio: exportRange.inicio, fecha_fin: exportRange.fin });
      const blob = new Blob([res.data], { type: 'text/csv;charset=utf-8;' });
      saveAs(blob, `libra_${exportRange.inicio}_${exportRange.fin}.csv`);
    } catch { alert('Error exportando'); }
    setExporting(false);
  };

  return (
    <div className="p-6 max-w-4xl mx-auto space-y-8">
      <h1 className="text-2xl font-bold text-primary">Configuración</h1>

      {/* Tarifas */}
      <section className="bg-white rounded-2xl shadow-md p-5 space-y-4">
        <h2 className="font-bold text-lg text-primary">Tarifas activas</h2>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="bg-primary/5 text-primary font-semibold">
              <tr>
                <th className="px-3 py-2 text-left">Tipo</th>
                <th className="px-3 py-2 text-left">Zona</th>
                <th className="px-3 py-2 text-right">Precio/kg</th>
                <th className="px-3 py-2 text-right">Precio/unidad</th>
                <th className="px-3 py-2 text-left">Desde</th>
              </tr>
            </thead>
            <tbody>
              {tarifas.map((t) => (
                <tr key={t.tarifa_id} className="border-t">
                  <td className="px-3 py-2">{tipoLabel[t.tipo_labor] || t.tipo_labor}</td>
                  <td className="px-3 py-2">{t.zona ? `Zona ${t.zona}` : 'Todas'}</td>
                  <td className="px-3 py-2 text-right">{t.precio_por_kg ? COP(t.precio_por_kg) : '—'}</td>
                  <td className="px-3 py-2 text-right">{t.precio_por_unidad ? COP(t.precio_por_unidad) : '—'}</td>
                  <td className="px-3 py-2">{new Date(t.fecha_inicio).toLocaleDateString('es-CO')}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        <div className="border-t pt-4">
          <h3 className="font-semibold mb-3">Nueva tarifa</h3>
          <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
            <div>
              <label className="block text-xs font-medium mb-1">Tipo labor</label>
              <select
                value={tariffForm.tipo_labor}
                onChange={(e) => setTariffForm((f) => ({ ...f, tipo_labor: e.target.value }))}
                className="w-full border rounded-lg px-2 py-1.5 text-sm"
              >
                {Object.entries(tipoLabel).map(([v, l]) => <option key={v} value={v}>{l}</option>)}
              </select>
            </div>
            <div>
              <label className="block text-xs font-medium mb-1">Zona</label>
              <select
                value={tariffForm.zona}
                onChange={(e) => setTariffForm((f) => ({ ...f, zona: parseInt(e.target.value) }))}
                className="w-full border rounded-lg px-2 py-1.5 text-sm"
              >
                {[1,2,3,4].map((z) => <option key={z} value={z}>Zona {z}</option>)}
              </select>
            </div>
            <div>
              <label className="block text-xs font-medium mb-1">
                {tariffForm.tipo_labor === 'fertilizacion' ? 'Precio/unidad' : 'Precio/kg'}
              </label>
              <input
                type="number"
                value={tariffForm.tipo_labor === 'fertilizacion' ? tariffForm.precio_por_unidad : tariffForm.precio_por_kg}
                onChange={(e) => setTariffForm((f) =>
                  tariffForm.tipo_labor === 'fertilizacion'
                    ? { ...f, precio_por_unidad: e.target.value }
                    : { ...f, precio_por_kg: e.target.value }
                )}
                className="w-full border rounded-lg px-2 py-1.5 text-sm"
                placeholder="85"
              />
            </div>
            <div>
              <label className="block text-xs font-medium mb-1">Vigencia desde</label>
              <input
                type="date"
                value={tariffForm.fecha_inicio}
                onChange={(e) => setTariffForm((f) => ({ ...f, fecha_inicio: e.target.value }))}
                className="w-full border rounded-lg px-2 py-1.5 text-sm"
              />
            </div>
            <div className="flex items-end">
              <button
                onClick={handleSaveTariff}
                disabled={savingTariff}
                className="w-full bg-primary text-white py-1.5 rounded-lg text-sm font-bold"
              >
                {savingTariff ? 'Guardando...' : 'Guardar tarifa'}
              </button>
            </div>
          </div>
        </div>
      </section>

      {/* Lotes */}
      <section className="bg-white rounded-2xl shadow-md p-5 space-y-4">
        <h2 className="font-bold text-lg text-primary">Lotes</h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          {lotes.map((l) => (
            <div
              key={l.lote_id}
              className="border rounded-xl p-3 flex items-center justify-between hover:border-primary cursor-pointer"
              onClick={() => { setEditLote(l); setLoteData({ peso_promedio_kg: l.peso_promedio_kg, numero_palmas: l.numero_palmas }); }}
            >
              <div>
                <div className="font-semibold">{l.nombre}</div>
                <div className="text-xs text-gray-500">Zona {l.zona} · {l.numero_palmas} palmas · {l.peso_promedio_kg} kg prom.</div>
              </div>
              <span className="text-primary text-sm">Editar →</span>
            </div>
          ))}
        </div>

        {editLote && (
          <div className="border-t pt-4 space-y-3">
            <h3 className="font-semibold">Editando: {editLote.nombre}</h3>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-xs font-medium mb-1">Peso promedio (kg)</label>
                <input
                  type="number"
                  step="0.1"
                  value={loteData.peso_promedio_kg || ''}
                  onChange={(e) => setLoteData((d) => ({ ...d, peso_promedio_kg: e.target.value }))}
                  className="w-full border rounded-lg px-3 py-2"
                />
              </div>
              <div>
                <label className="block text-xs font-medium mb-1">Número de palmas</label>
                <input
                  type="number"
                  value={loteData.numero_palmas || ''}
                  onChange={(e) => setLoteData((d) => ({ ...d, numero_palmas: e.target.value }))}
                  className="w-full border rounded-lg px-3 py-2"
                />
              </div>
            </div>
            <div className="flex gap-3">
              <button onClick={handleSaveLote} disabled={savingLote}
                className="flex-1 bg-primary text-white py-2 rounded-xl font-bold">
                {savingLote ? 'Guardando...' : 'Guardar'}
              </button>
              <button onClick={() => setEditLote(null)} className="border border-gray-300 px-4 py-2 rounded-xl">
                Cancelar
              </button>
            </div>
          </div>
        )}
      </section>

      {/* Libra CSV export */}
      <section className="bg-white rounded-2xl shadow-md p-5 space-y-4">
        <h2 className="font-bold text-lg text-primary">Exportar a Libra ERP</h2>
        <div className="flex flex-wrap gap-4 items-end">
          <div>
            <label className="block text-sm font-medium mb-1">Desde</label>
            <input type="date" value={exportRange.inicio}
              onChange={(e) => setExportRange((r) => ({ ...r, inicio: e.target.value }))}
              className="border rounded-lg px-3 py-2" />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">Hasta</label>
            <input type="date" value={exportRange.fin}
              onChange={(e) => setExportRange((r) => ({ ...r, fin: e.target.value }))}
              className="border rounded-lg px-3 py-2" />
          </div>
          <button onClick={handleExport} disabled={exporting}
            className="bg-accent text-white px-6 py-2 rounded-xl font-bold hover:bg-accent-light disabled:opacity-50">
            {exporting ? '⏳ Exportando...' : '📥 Descargar CSV Libra'}
          </button>
        </div>
        <p className="text-sm text-gray-500">
          Genera el CSV exactamente como lo requiere Libra ERP, incluyendo formato colombiano de fechas y números.
        </p>
      </section>
    </div>
  );
}
