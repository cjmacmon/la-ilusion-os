import React from 'react';
import ReactDOM from 'react-dom/client';
import { BrowserRouter, Routes, Route, Navigate, Outlet } from 'react-router-dom';
import './index.css';
import { AuthProvider, useAuth } from './context/AuthContext';
import Navbar from './components/Navbar';
import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import CosechasPage from './pages/CosechasPage';
import TrabajadoresPage from './pages/TrabajadoresPage';
import LiquidacionesPage from './pages/LiquidacionesPage';
import IncentivosPage from './pages/IncentivosPage';
import ConfiguracionPage from './pages/ConfiguracionPage';
import TarifasPage from './pages/TarifasPage';

function ProtectedLayout() {
  const { user } = useAuth();
  if (!user) return <Navigate to="/login" replace />;
  return (
    <>
      <Navbar />
      <main>
        <Outlet />
      </main>
    </>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          <Route element={<ProtectedLayout />}>
            <Route path="/"              element={<DashboardPage />} />
            <Route path="/cosechas"      element={<CosechasPage />} />
            <Route path="/trabajadores"  element={<TrabajadoresPage />} />
            <Route path="/liquidaciones" element={<LiquidacionesPage />} />
            <Route path="/incentivos"    element={<IncentivosPage />} />
            <Route path="/tarifas"        element={<TarifasPage />} />
            <Route path="/configuracion" element={<ConfiguracionPage />} />
          </Route>
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  </React.StrictMode>
);
