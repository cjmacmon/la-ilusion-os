import { useState, useCallback } from 'react';
import {
  BarChart, Bar, LineChart, Line, XAxis, YAxis, Tooltip,
  ResponsiveContainer, CartesianGrid, Legend,
} from 'recharts';
import { getKpis } from '../services/api';
import { usePolling } from '../hooks/usePolling';
import KPICard from '../components/KPICard';
import ChartCard from '../components/ChartCard';

const COP = (n) =>
  new Intl.NumberFormat('es-CO', { style: 'currency', currency: 'COP', maximumFractionDigits: 0 }).format(n);
const NUM = (n) => new Intl.NumberFormat('es-CO').format(n);

export default function DashboardPage() {
  const [kpis, setKpis] = useState(null);
  const [error, setError] = useState(null);
  const [lastUpdate, setLastUpdate] = useState(null);

  const fetchKpis = useCallback(async () => {
    try {
      const res = await getKpis();
      setKpis(res.data.data);
      setLastUpdate(new Date());
      setError(null);
    } catch {
      setError('Error cargando KPIs');
    }
  }, []);

  usePolling(fetchKpis, 60000);

  if (error) return <div className="p-6 text-red-600">{error}</div>;
  if (!kpis) return <div className="p-6 text-gray-500">Cargando...</div>;

  const zonaColors = ['#1B4332', '#2D6A4F', '#D4A017', '#F59E0B'];

  return (
    <div className="p-6 space-y-6 max-w-7xl mx-auto">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-primary">Dashboard Principal</h1>
        {lastUpdate && (
          <span className="text-sm text-gray-500">
            Actualizado: {lastUpdate.toLocaleTimeString('es-CO')}
          </span>
        )}
      </div>

      {/* KPI Row */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <KPICard
          title="Racimos hoy"
          value={NUM(kpis.racimos_hoy)}
          subtitle={`${NUM(kpis.racimos_semana)} esta semana`}
          icon="🍇"
          color="primary"
        />
        <KPICard
          title="Kg hoy"
          value={`${NUM(Math.round(kpis.kg_hoy))} kg`}
          subtitle={`${NUM(Math.round(kpis.kg_semana))} kg esta semana`}
          icon="⚖️"
          color="green"
        />
        <KPICard
          title="Trabajadores activos"
          value={kpis.trabajadores_activos_hoy}
          subtitle="hoy en campo"
          icon="👷"
          color="accent"
        />
        <KPICard
          title="Pagos pendientes"
          value={COP(kpis.pagos_pendientes_cop)}
          subtitle="por aprobar"
          icon="💰"
          color="orange"
        />
      </div>

      {/* Charts row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <ChartCard title="Producción por zona (últimos 7 días)">
          <ResponsiveContainer width="100%" height={220}>
            <BarChart data={kpis.produccion_por_zona}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="zona" tickFormatter={(v) => `Zona ${v}`} />
              <YAxis />
              <Tooltip formatter={(v, n) => [NUM(v), n === 'racimos' ? 'Racimos' : 'Kg']} />
              <Legend />
              <Bar dataKey="racimos" fill="#1B4332" name="Racimos" radius={[4,4,0,0]} />
              <Bar dataKey="kg" fill="#D4A017" name="Kg" radius={[4,4,0,0]} />
            </BarChart>
          </ResponsiveContainer>
        </ChartCard>

        <ChartCard title="Top 7 cosechadores esta semana">
          <ResponsiveContainer width="100%" height={220}>
            <BarChart
              data={kpis.top_trabajadores_semana}
              layout="vertical"
              margin={{ left: 20 }}
            >
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis type="number" />
              <YAxis
                type="category"
                dataKey="nombre_completo"
                width={120}
                tick={{ fontSize: 12 }}
              />
              <Tooltip formatter={(v) => [NUM(v), 'Racimos']} />
              <Bar dataKey="racimos_semana" fill="#1B4332" name="Racimos" radius={[0,4,4,0]} />
            </BarChart>
          </ResponsiveContainer>
        </ChartCard>
      </div>

      {/* Pending sync alert */}
      {kpis.registros_pendientes_sync > 0 && (
        <div className="bg-yellow-50 border border-yellow-300 rounded-xl p-4 flex items-center gap-3">
          <span className="text-2xl">⚠️</span>
          <div>
            <div className="font-bold text-yellow-800">
              {NUM(kpis.registros_pendientes_sync)} registros pendientes de sincronización
            </div>
            <div className="text-yellow-700 text-sm">
              Hay dispositivos de campo con datos sin sincronizar
            </div>
          </div>
        </div>
      )}

      {/* Producción por zona table */}
      <div className="bg-white rounded-2xl shadow-md overflow-hidden">
        <div className="px-5 py-4 border-b">
          <h3 className="font-bold text-primary text-lg">Producción por zona — últimos 7 días</h3>
        </div>
        <table className="w-full text-sm">
          <thead className="bg-primary/5 text-primary font-semibold">
            <tr>
              <th className="px-4 py-3 text-left">Zona</th>
              <th className="px-4 py-3 text-right">Racimos</th>
              <th className="px-4 py-3 text-right">Peso (kg)</th>
            </tr>
          </thead>
          <tbody>
            {kpis.produccion_por_zona.map((z, i) => (
              <tr key={z.zona} className={i % 2 === 0 ? 'bg-white' : 'bg-primary/5'}>
                <td className="px-4 py-2.5 font-medium">Zona {z.zona}</td>
                <td className="px-4 py-2.5 text-right">{NUM(z.racimos)}</td>
                <td className="px-4 py-2.5 text-right">{NUM(Math.round(z.kg))}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
