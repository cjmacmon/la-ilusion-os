import { useState, useEffect } from 'react';
import { getIncentivos, createIncentivo, updateIncentivo } from '../services/api';

const COP = (n) =>
  new Intl.NumberFormat('es-CO', { style: 'currency', currency: 'COP', maximumFractionDigits: 0 }).format(n ?? 0);

const tipoLabel = {
  dias_trabajados: 'Días trabajados',
  racimos_semana: 'Racimos / semana',
  racimos_quincena: 'Racimos / quincena',
};

export default function IncentivosPage() {
  const [incentivos, setIncentivos] = useState([]);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({ nombre: '', tipo: 'dias_trabajados', umbral: '', monto_bono: '', descripcion: '' });
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    getIncentivos().then((r) => setIncentivos(r.data.data));
  }, []);

  const refresh = () => getIncentivos().then((r) => setIncentivos(r.data.data));

  const handleCreate = async () => {
    if (!form.nombre || !form.umbral || !form.monto_bono) {
      alert('Completa todos los campos requeridos');
      return;
    }
    setSaving(true);
    try {
      await createIncentivo({ ...form, umbral: parseFloat(form.umbral), monto_bono: parseFloat(form.monto_bono) });
      await refresh();
      setShowForm(false);
      setForm({ nombre: '', tipo: 'dias_trabajados', umbral: '', monto_bono: '', descripcion: '' });
    } catch { alert('Error creando incentivo'); }
    setSaving(false);
  };

  const toggle = async (id, activo) => {
    await updateIncentivo(id, { activo: !activo });
    refresh();
  };

  return (
    <div className="p-6 max-w-3xl mx-auto space-y-5">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-primary">Incentivos</h1>
        <button
          onClick={() => setShowForm((v) => !v)}
          className="bg-primary text-white px-4 py-2 rounded-xl font-bold hover:bg-primary-light transition-colors"
        >
          + Nuevo incentivo
        </button>
      </div>

      {showForm && (
        <div className="bg-white rounded-2xl shadow-md p-5 space-y-4 border border-primary/20">
          <h2 className="font-bold text-primary">Nuevo incentivo</h2>
          <div>
            <label className="block text-sm font-medium mb-1">Nombre *</label>
            <input
              value={form.nombre}
              onChange={(e) => setForm((f) => ({ ...f, nombre: e.target.value }))}
              className="w-full border rounded-lg px-3 py-2"
              placeholder="Bono asistencia perfecta"
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium mb-1">Tipo *</label>
              <select
                value={form.tipo}
                onChange={(e) => setForm((f) => ({ ...f, tipo: e.target.value }))}
                className="w-full border rounded-lg px-3 py-2"
              >
                {Object.entries(tipoLabel).map(([v, l]) => <option key={v} value={v}>{l}</option>)}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium mb-1">Umbral *</label>
              <input
                type="number"
                value={form.umbral}
                onChange={(e) => setForm((f) => ({ ...f, umbral: e.target.value }))}
                className="w-full border rounded-lg px-3 py-2"
                placeholder="14"
              />
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">Monto bono (COP) *</label>
            <input
              type="number"
              value={form.monto_bono}
              onChange={(e) => setForm((f) => ({ ...f, monto_bono: e.target.value }))}
              className="w-full border rounded-lg px-3 py-2"
              placeholder="50000"
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">Descripción</label>
            <textarea
              value={form.descripcion}
              onChange={(e) => setForm((f) => ({ ...f, descripcion: e.target.value }))}
              className="w-full border rounded-lg px-3 py-2"
              rows={2}
            />
          </div>
          <div className="flex gap-3">
            <button onClick={handleCreate} disabled={saving}
              className="flex-1 bg-primary text-white py-2 rounded-xl font-bold">
              {saving ? 'Guardando...' : 'Crear incentivo'}
            </button>
            <button onClick={() => setShowForm(false)} className="border border-gray-300 px-4 py-2 rounded-xl">
              Cancelar
            </button>
          </div>
        </div>
      )}

      <div className="space-y-3">
        {incentivos.map((inc) => (
          <div
            key={inc.incentivo_id}
            className={`bg-white rounded-2xl shadow-md p-5 border-l-4 ${inc.activo ? 'border-accent' : 'border-gray-300'}`}
          >
            <div className="flex items-start justify-between">
              <div>
                <h3 className="font-bold text-lg text-primary">{inc.nombre}</h3>
                <span className="text-sm text-gray-500">
                  {tipoLabel[inc.tipo]} ≥ {inc.umbral}
                </span>
                {inc.descripcion && <p className="text-sm text-gray-600 mt-1">{inc.descripcion}</p>}
              </div>
              <div className="text-right">
                <div className="text-xl font-bold text-accent">{COP(inc.monto_bono)}</div>
                <button
                  onClick={() => toggle(inc.incentivo_id, inc.activo)}
                  className={`text-xs mt-1 px-2 py-0.5 rounded-full font-medium ${
                    inc.activo ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'
                  }`}
                >
                  {inc.activo ? 'Activo' : 'Inactivo'} — clic para cambiar
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
