import axios from 'axios';

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'http://localhost:3000',
  timeout: 30000,
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('auth_token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

api.interceptors.response.use(
  (res) => res,
  (err) => {
    if (err.response?.status === 401) {
      localStorage.removeItem('auth_token');
      window.location.href = '/login';
    }
    return Promise.reject(err);
  }
);

export default api;

// Auth
export const login = (data) => api.post('/auth/login', data);

// Dashboard
export const getKpis = () => api.get('/dashboard/kpis');

// Trabajadores
export const getTrabajadores = (params) => api.get('/trabajadores', { params });
export const createTrabajador = (data) => api.post('/trabajadores', data);
export const updateTrabajador = (id, data) => api.put(`/trabajadores/${id}`, data);
export const getTrabajadorResumen = (id) => api.get(`/trabajadores/${id}/resumen`);

// Lotes
export const getLotes = (params) => api.get('/lotes', { params });
export const createLote = (data) => api.post('/lotes', data);
export const updateLote = (id, data) => api.put(`/lotes/${id}`, data);

// Cosecha
export const getCosechas = (params) => api.get('/cosecha', { params });

// Fertilizacion
export const getFertilizaciones = (params) => api.get('/fertilizacion', { params });

// Ausencias
export const getAusencias = (params) => api.get('/ausencias', { params });
export const createAusencia = (data) => api.post('/ausencias', data);

// Tarifas (simple — used by payment engine)
export const getTarifas = () => api.get('/tarifas');
export const createTarifa = (data) => api.post('/tarifas', data);

// Tarifas laboral (full catalog)
export const getTarifasLaboral = (params) => api.get('/tarifas-laboral', { params });
export const getTarifasLaboralHistorico = (fecha) => api.get('/tarifas-laboral/historico', { params: { fecha } });
export const getTarifasLaboralAreas = () => api.get('/tarifas-laboral/areas');
export const updateTarifaLaboral = (id, data) => api.put(`/tarifas-laboral/${id}`, data);

// Incentivos
export const getIncentivos = () => api.get('/incentivos');
export const createIncentivo = (data) => api.post('/incentivos', data);
export const updateIncentivo = (id, data) => api.put(`/incentivos/${id}`, data);

// Liquidacion
export const calcularLiquidacion = (data) => api.post('/liquidacion/calcular', data);
export const saveLiquidacion = (data) => api.post('/liquidacion', data);
export const getLiquidaciones = (params) => api.get('/liquidacion', { params });
export const updateLiquidacionEstado = (id, data) => api.put(`/liquidacion/${id}/estado`, data);
export const exportLibraCSV = (params) =>
  api.get('/liquidacion/export/csv', { params, responseType: 'blob' });
