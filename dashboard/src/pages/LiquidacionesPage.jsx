import { useState, useEffect } from 'react';
import { getTrabajadores, calcularLiquidacion, saveLiquidacion, getLiquidaciones, updateLiquidacionEstado } from '../services/api';

const COP = (n) =>
  new Intl.NumberFormat('es-CO', { style: 'currency', currency: 'COP', maximumFractionDigits: 0 }).format(n ?? 0);

const estadoColor = {
  pendiente: 'bg-yellow-100 text-yellow-700',
  aprobada:  'bg-blue-100 text-blue-700',
  pagada:    'bg-green-100 text-green-700',
};

export default function LiquidacionesPage() {
  const [trabajadores, setTrabajadores] = useState([]);
  const [liquidaciones, setLiquidaciones] = useState([]);
  const [form, setForm] = useState({ trabajador_id: '', periodo_inicio: '', periodo_fin: '' });
  const [preview, setPreview] = useState(null);
  const [calculating, setCalculating] = useState(false);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    getTrabajadores().then((r) => setTrabajadores(r.data.data));
    fetchLiquidaciones();
  }, []);

  const fetchLiquidaciones = () =>
    getLiquidaciones().then((r) => setLiquidaciones(r.data.data));

  const handleCalcular = async () => {
    if (!form.trabajador_id || !form.periodo_inicio || !form.periodo_fin) {
      alert('Completa todos los campos');
      return;
    }
    setCalculating(true);
    setPreview(null);
    try {
      const res = await calcularLiquidacion(form);
      setPreview(res.data.data);
    } catch { alert('Error calculando liquidación'); }
    setCalculating(false);
  };

  const handleSave = async () => {
    if (!preview) return;
    setSaving(true);
    try {
      await saveLiquidacion({
        trabajador_id: preview.trabajador.trabajador_id,
        periodo_inicio: preview.periodo_inicio,
        periodo_fin: preview.periodo_fin,
        dias_trabajados: preview.dias_trabajados,
        dias_ausencia_injustificada: preview.dias_ausencia_injustificada,
        total_racimos: preview.total_racimos,
        total_kg: preview.total_kg,
        monto_cosecha: preview.monto_cosecha,
        monto_fertilizacion: preview.monto_fertilizacion,
        monto_bonos: preview.monto_bonos,
        deducciones: preview.deducciones,
        total_pagar: preview.total_pagar,
      });
      await fetchLiquidaciones();
      setPreview(null);
      alert('Liquidación guardada');
    } catch { alert('Error guardando'); }
    setSaving(false);
  };

  const handleEstado = async (id, estado) => {
    await updateLiquidacionEstado(id, { estado, fecha_pago: estado === 'pagada' ? new Date().toISOString().slice(0,10) : null });
    fetchLiquidaciones();
  };

  return (
    <div className="p-6 max-w-5xl mx-auto space-y-6">
      <h1 className="text-2xl font-bold text-primary">Liquidaciones</h1>

      {/* Calculator */}
      <div className="bg-white rounded-2xl shadow-md p-5 space-y-4">
        <h2 className="font-bold text-lg text-primary">Nueva liquidación</h2>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <div>
            <label className="block text-sm font-medium mb-1">Trabajador</label>
            <select
              value={form.trabajador_id}
              onChange={(e) => setForm((f) => ({ ...f, trabajador_id: e.target.value }))}
              className="w-full border rounded-lg px-3 py-2"
            >
              <option value="">Seleccionar...</option>
              {trabajadores.map((t) => (
                <option key={t.trabajador_id} value={t.trabajador_id}>
                  {t.nombre_completo} ({t.cod_cosechero})
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">Inicio período</label>
            <input
              type="date"
              value={form.periodo_inicio}
              onChange={(e) => setForm((f) => ({ ...f, periodo_inicio: e.target.value }))}
              className="w-full border rounded-lg px-3 py-2"
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">Fin período</label>
            <input
              type="date"
              value={form.periodo_fin}
              onChange={(e) => setForm((f) => ({ ...f, periodo_fin: e.target.value }))}
              className="w-full border rounded-lg px-3 py-2"
            />
          </div>
        </div>
        <button
          onClick={handleCalcular}
          disabled={calculating}
          className="bg-primary text-white px-6 py-2 rounded-xl font-bold hover:bg-primary-light transition-colors disabled:opacity-50"
        >
          {calculating ? 'Calculando...' : 'Calcular liquidación'}
        </button>

        {/* Preview */}
        {preview && (
          <div className="border border-primary/20 rounded-xl p-4 space-y-3 bg-primary/5">
            <h3 className="font-bold text-primary">{preview.trabajador.nombre_completo}</h3>
            <div className="grid grid-cols-2 sm:grid-cols-3 gap-3 text-sm">
              <div className="bg-white rounded-lg p-3">
                <div className="text-gray-500">Días trabajados</div>
                <div className="text-xl font-bold text-primary">{preview.dias_trabajados}</div>
              </div>
              <div className="bg-white rounded-lg p-3">
                <div className="text-gray-500">Total racimos</div>
                <div className="text-xl font-bold text-primary">{preview.total_racimos}</div>
              </div>
              <div className="bg-white rounded-lg p-3">
                <div className="text-gray-500">Total kg</div>
                <div className="text-xl font-bold text-primary">{preview.total_kg}</div>
              </div>
            </div>
            <div className="bg-white rounded-lg p-4 space-y-2 text-sm">
              <div className="flex justify-between"><span>Cosecha</span><span className="font-bold">{COP(preview.monto_cosecha)}</span></div>
              <div className="flex justify-between"><span>Fertilización</span><span className="font-bold">{COP(preview.monto_fertilizacion)}</span></div>
              <div className="flex justify-between text-green-700"><span>Bonos</span><span className="font-bold">+ {COP(preview.monto_bonos)}</span></div>
              <div className="flex justify-between text-red-600"><span>Deducciones</span><span className="font-bold">- {COP(preview.deducciones)}</span></div>
              <hr />
              <div className="flex justify-between text-primary font-bold text-lg">
                <span>TOTAL A PAGAR</span><span>{COP(preview.total_pagar)}</span>
              </div>
            </div>
            <div className="flex gap-3">
              <button onClick={handleSave} disabled={saving} className="flex-1 bg-primary text-white py-2 rounded-xl font-bold">
                {saving ? 'Guardando...' : 'Guardar liquidación'}
              </button>
              <button onClick={() => setPreview(null)} className="border border-gray-300 px-4 py-2 rounded-xl">Cancelar</button>
            </div>
          </div>
        )}
      </div>

      {/* List */}
      <div className="bg-white rounded-2xl shadow-md overflow-hidden">
        <div className="px-5 py-4 border-b">
          <h2 className="font-bold text-lg text-primary">Historial de liquidaciones</h2>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="bg-primary/5 text-primary font-semibold">
              <tr>
                <th className="px-4 py-3 text-left">Trabajador</th>
                <th className="px-4 py-3 text-left">Período</th>
                <th className="px-4 py-3 text-right">Total a pagar</th>
                <th className="px-4 py-3 text-center">Estado</th>
                <th className="px-4 py-3 text-center">Acciones</th>
              </tr>
            </thead>
            <tbody>
              {liquidaciones.map((l) => (
                <tr key={l.liquidacion_id} className="border-t hover:bg-primary/5">
                  <td className="px-4 py-3">{l.nombre_completo}<br/><span className="text-xs text-gray-500">{l.cod_cosechero}</span></td>
                  <td className="px-4 py-3 text-xs">
                    {new Date(l.periodo_inicio).toLocaleDateString('es-CO')} —{' '}
                    {new Date(l.periodo_fin).toLocaleDateString('es-CO')}
                  </td>
                  <td className="px-4 py-3 text-right font-bold text-primary">{COP(l.total_pagar)}</td>
                  <td className="px-4 py-3 text-center">
                    <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${estadoColor[l.estado]}`}>
                      {l.estado}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-center">
                    {l.estado === 'pendiente' && (
                      <button onClick={() => handleEstado(l.liquidacion_id, 'aprobada')}
                        className="text-blue-600 hover:underline text-xs mr-2">Aprobar</button>
                    )}
                    {l.estado === 'aprobada' && (
                      <button onClick={() => handleEstado(l.liquidacion_id, 'pagada')}
                        className="text-green-600 hover:underline text-xs">Marcar pagada</button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
