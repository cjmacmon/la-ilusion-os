export default function KPICard({ title, value, subtitle, icon, color = 'primary' }) {
  const colors = {
    primary: 'bg-primary text-white',
    accent:  'bg-accent text-white',
    green:   'bg-green-600 text-white',
    orange:  'bg-orange-500 text-white',
  };

  return (
    <div className={`rounded-2xl p-5 shadow-md ${colors[color]}`}>
      <div className="flex items-center justify-between mb-2">
        <span className="text-sm font-medium opacity-80">{title}</span>
        {icon && <span className="text-2xl">{icon}</span>}
      </div>
      <div className="text-3xl font-bold">{value}</div>
      {subtitle && <div className="text-sm opacity-70 mt-1">{subtitle}</div>}
    </div>
  );
}
