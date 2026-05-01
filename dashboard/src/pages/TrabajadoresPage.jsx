import { useState, useEffect } from 'react';
import { getTrabajadores, updateTrabajador, getTrabajadorResumen } from '../services/api';
import DataTable from '../components/DataTable';

const rolColor = {
  cosechador: 'bg-green-100 text-green-700',
  recolector: 'bg-blue-100 text-blue-700',
  fertilizador: 'bg-yellow-100 text-yellow-700',
  supervisor: 'bg-purple-100 text-purple-700',
  admin: 'bg-red-100 text-red-700',
};

const COP = (n) =>
  new Intl.NumberFormat('es-CO', { style: 'currency', currency: 'COP', maximumFractionDigits: 0 }).format(n);

export default function TrabajadoresPage() {
  const [trabajadores, setTrabajadores] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selected, setSelected] = useState(null);
  const [resumen, setResumen] = useState(null);
  const [editMode, setEditMode] = useState(false);
  const [editData, setEditData] = useState({});
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    getTrabajadores().then((r) => {
      setTrabajadores(r.data.data);
      setLoading(false);
    });
  }, []);

  const openWorker = async (w) => {
    setSelected(w);
    setEditData({ zona: w.zona, rol: w.rol, activo: w.activo });
    setEditMode(false);
    try {
      const r = await getTrabajadorResumen(w.trabajador_id);
      setResumen(r.data.data);
    } catch { setResumen(null); }
  };

  const handleSave = async () => {
    setSaving(true);
    try {
      await updateTrabajador(selected.trabajador_id, editData);
      const r = await getTrabajadores();
      setTrabajadores(r.data.data);
      setEditMode(false);
    } catch { alert('Error guardando'); }
    setSaving(false);
  };

  const columns = [
    { accessorKey: 'cod_cosechero', header: 'Código' },
    { accessorKey: 'nombre_completo', header: 'Nombre' },
    {
      accessorKey: 'rol',
      header: 'Rol',
      cell: (i) => (
        <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${rolColor[i.getValue()] || ''}`}>
          {i.getValue()}
        </span>
      ),
    },
    { accessorKey: 'zona', header: 'Zona', cell: (i) => i.getValue() ? `Zona ${i.getValue()}` : '—' },
    {
      accessorKey: 'activo',
      header: 'Estado',
      cell: (i) => (
        <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${i.getValue() ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>
          {i.getValue() ? 'Activo' : 'Inactivo'}
        </span>
      ),
    },
    {
      id: 'acciones',
      header: '',
      cell: ({ row }) => (
        <button
          onClick={() => openWorker(row.original)}
          className="text-primary hover:underline text-sm font-medium"
        >
          Ver perfil →
        </button>
      ),
    },
  ];

  return (
    <div className="p-6 max-w-7xl mx-auto space-y-5">
      <h1 className="text-2xl font-bold text-primary">Trabajadores</h1>

      {loading ? (
        <div className="text-center py-12 text-gray-500">Cargando...</div>
      ) : (
        <DataTable columns={columns} data={trabajadores} />
      )}

      {/* Worker profile modal */}
      {selected && (
        <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-lg max-h-[90vh] overflow-y-auto">
            <div className="p-5 border-b flex items-center justify-between">
              <div>
                <h2 className="text-xl font-bold text-primary">{selected.nombre_completo}</h2>
                <span className="text-sm text-gray-500">{selected.cod_cosechero} · {selected.cedula}</span>
              </div>
              <button onClick={() => setSelected(null)} className="text-gray-400 hover:text-gray-600 text-2xl">✕</button>
            </div>
            <div className="p-5 space-y-4">
              {resumen && (
                <div className="grid grid-cols-3 gap-3">
                  <div className="bg-primary/5 rounded-xl p-3 text-center">
                    <div className="text-2xl font-bold text-primary">{resumen.total_racimos}</div>
                    <div className="text-xs text-gray-500">Racimos quincena</div>
                  </div>
                  <div className="bg-primary/5 rounded-xl p-3 text-center">
                    <div className="text-2xl font-bold text-primary">{Math.round(resumen.total_kg)}</div>
                    <div className="text-xs text-gray-500">Kg quincena</div>
                  </div>
                  <div className="bg-primary/5 rounded-xl p-3 text-center">
                    <div className="text-2xl font-bold text-primary">{resumen.dias_trabajados}</div>
                    <div className="text-xs text-gray-500">Días trabajados</div>
                  </div>
                </div>
              )}

              {editMode ? (
                <div className="space-y-3">
                  <div>
                    <label className="block text-sm font-medium mb-1">Zona</label>
                    <select
                      value={editData.zona || ''}
                      onChange={(e) => setEditData((d) => ({ ...d, zona: parseInt(e.target.value) || null }))}
                      className="w-full border rounded-lg px-3 py-2"
                    >
                      <option value="">Sin zona</option>
                      {[1,2,3,4].map((z) => <option key={z} value={z}>Zona {z}</option>)}
                    </select>
                  </div>
                  <div>
                    <label className="block text-sm font-medium mb-1">Rol</label>
                    <select
                      value={editData.rol || ''}
                      onChange={(e) => setEditData((d) => ({ ...d, rol: e.target.value }))}
                      className="w-full border rounded-lg px-3 py-2"
                    >
                      {['cosechador','recolector','fertilizador','supervisor','admin'].map((r) => (
                        <option key={r} value={r}>{r}</option>
                      ))}
                    </select>
                  </div>
                  <label className="flex items-center gap-2 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={editData.activo ?? true}
                      onChange={(e) => setEditData((d) => ({ ...d, activo: e.target.checked }))}
                    />
                    <span>Activo</span>
                  </label>
                  <div className="flex gap-3">
                    <button
                      onClick={handleSave}
                      disabled={saving}
                      className="flex-1 bg-primary text-white py-2 rounded-xl font-bold"
                    >
                      {saving ? 'Guardando...' : 'Guardar cambios'}
                    </button>
                    <button
                      onClick={() => setEditMode(false)}
                      className="flex-1 border border-gray-300 py-2 rounded-xl"
                    >
                      Cancelar
                    </button>
                  </div>
                </div>
              ) : (
                <button
                  onClick={() => setEditMode(true)}
                  className="w-full border border-primary text-primary py-2 rounded-xl font-medium hover:bg-primary/5"
                >
                  Editar trabajador
                </button>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
