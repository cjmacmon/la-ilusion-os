import { Link, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

const links = [
  { to: '/',             label: 'Dashboard'    },
  { to: '/cosechas',     label: 'Cosechas'     },
  { to: '/trabajadores', label: 'Trabajadores' },
  { to: '/liquidaciones',label: 'Liquidaciones'},
  { to: '/incentivos',   label: 'Incentivos'   },
  { to: '/tarifas',       label: 'Tarifas'       },
  { to: '/configuracion',label: 'Configuración'},
];

export default function Navbar() {
  const { user, logout } = useAuth();
  const { pathname } = useLocation();

  return (
    <nav className="bg-primary text-white shadow-lg">
      <div className="max-w-7xl mx-auto px-4 py-3 flex items-center justify-between flex-wrap gap-2">
        <div className="flex items-center gap-2">
          <span className="text-2xl">🌴</span>
          <span className="font-bold text-lg hidden sm:block">Hacienda La Ilusión</span>
        </div>
        <div className="flex flex-wrap gap-1">
          {links.map((l) => (
            <Link
              key={l.to}
              to={l.to}
              className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                pathname === l.to
                  ? 'bg-accent text-white'
                  : 'text-white/80 hover:bg-white/10'
              }`}
            >
              {l.label}
            </Link>
          ))}
        </div>
        <div className="flex items-center gap-3">
          {user && (
            <span className="text-sm text-white/70">
              {user.nombre_completo} · {user.rol?.toUpperCase()}
            </span>
          )}
          <button
            onClick={logout}
            className="text-white/70 hover:text-white text-sm underline"
          >
            Salir
          </button>
        </div>
      </div>
    </nav>
  );
}
