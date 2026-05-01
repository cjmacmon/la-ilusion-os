import { useState, useEffect, useCallback } from 'react';
import { getCosechas, exportLibraCSV } from '../services/api';
import DataTable from '../components/DataTable';
import { saveAs } from 'file-saver';

const DATE = (s) => s ? new Date(s).toLocaleDateString('es-CO') : '—';
const NUM = (n) => new Intl.NumberFormat('es-CO').format(n ?? 0);

export default function CosechasPage() {
  const [cosechas, setCosechas] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filters, setFilters] = useState({ fecha_inicio: '', fecha_fin: '' });
  const [exporting, setExporting] = useState(false);

  const fetch = useCallback(async () => {
    setLoading(true);
    try {
      const params = {};
      if (filters.fecha_inicio) params.fecha_inicio = filters.fecha_inicio;
      if (filters.fecha_fin)    params.fecha_fin    = filters.fecha_fin;
      const res = await getCosechas(params);
      setCosechas(res.data.data);
    } catch {}
    setLoading(false);
  }, [filters]);

  useEffect(() => { fetch(); }, [fetch]);

  const handleExport = async () => {
    if (!filters.fecha_inicio || !filters.fecha_fin) {
      alert('Selecciona un rango de fechas para exportar');
      return;
    }
    setExporting(true);
    try {
      const res = await exportLibraCSV({ fecha_inicio: filters.fecha_inicio, fecha_fin: filters.fecha_fin });
      const blob = new Blob([res.data], { type: 'text/csv;charset=utf-8;' });
      saveAs(blob, `libra_${filters.fecha_inicio}_${filters.fecha_fin}.csv`);
    } catch { alert('Error exportando'); }
    setExporting(false);
  };

  const columns = [
    { accessorKey: 'fecha_corte',                    header: 'Fecha corte',   cell: (i) => DATE(i.getValue()) },
    { accessorKey: 'ticket_extractora',              header: 'Ticket',        cell: (i) => i.getValue() || '—' },
    { accessorKey: 'nombre_completo',                header: 'Cosechero' },
    { accessorKey: 'cod_cosechero',                  header: 'Código' },
    { accessorKey: 'lote_nombre',                    header: 'Lote' },
    { accessorKey: 'zona',                           header: 'Zona',          cell: (i) => `Zona ${i.getValue()}` },
    { accessorKey: 'tipo_cosecha',                   header: 'Tipo',          cell: (i) => i.getValue() === 'RECOLECTOR_DE_RACIMOS' ? 'Recolector' : 'Mecanizada' },
    { accessorKey: 'total_racimos',                  header: 'Racimos',       cell: (i) => NUM(i.getValue()) },
    { accessorKey: 'peso_extractora_sin_recolector', header: 'Peso (kg)',     cell: (i) => NUM(i.getValue()) },
    {
      accessorKey: 'sync_status',
      header: 'Estado',
      cell: (i) => (
        <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${
          i.getValue() === 'synced' ? 'bg-green-100 text-green-700' : 'bg-yellow-100 text-yellow-700'
        }`}>
          {i.getValue() === 'synced' ? 'Sincronizado' : 'Pendiente'}
        </span>
      ),
    },
  ];

  return (
    <div className="p-6 space-y-5 max-w-7xl mx-auto">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-2xl font-bold text-primary">Cosechas</h1>
        <button
          onClick={handleExport}
          disabled={exporting}
          className="bg-accent text-white px-4 py-2 rounded-xl font-bold hover:bg-accent-light transition-colors disabled:opacity-50 flex items-center gap-2"
        >
          {exporting ? '⏳' : '📥'} Exportar Libra CSV
        </button>
      </div>

      {/* Filters */}
      <div className="bg-white rounded-xl shadow-sm p-4 flex flex-wrap gap-4 items-end">
        <div>
          <label className="block text-sm font-medium text-gray-600 mb-1">Desde</label>
          <input
            type="date"
            value={filters.fecha_inicio}
            onChange={(e) => setFilters((f) => ({ ...f, fecha_inicio: e.target.value }))}
            className="border rounded-lg px-3 py-2"
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-600 mb-1">Hasta</label>
          <input
            type="date"
            value={filters.fecha_fin}
            onChange={(e) => setFilters((f) => ({ ...f, fecha_fin: e.target.value }))}
            className="border rounded-lg px-3 py-2"
          />
        </div>
        <button
          onClick={fetch}
          className="bg-primary text-white px-4 py-2 rounded-lg font-medium hover:bg-primary-light transition-colors"
        >
          Filtrar
        </button>
      </div>

      {loading ? (
        <div className="text-center py-12 text-gray-500">Cargando...</div>
      ) : (
        <DataTable columns={columns} data={cosechas} pageSize={25} />
      )}
    </div>
  );
}
