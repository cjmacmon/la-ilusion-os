-- Hacienda La Ilusión — Schema PostgreSQL
-- Timezone: America/Bogota

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- TRABAJADOR
-- ============================================================
CREATE TABLE IF NOT EXISTS trabajador (
  trabajador_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cod_cosechero   VARCHAR(20) UNIQUE NOT NULL,
  cedula          VARCHAR(20) UNIQUE NOT NULL,
  nombre_completo VARCHAR(150) NOT NULL,
  telefono        VARCHAR(20),
  pin             VARCHAR(4) NOT NULL,
  password_hash   VARCHAR(255),
  rol             VARCHAR(30) NOT NULL CHECK (rol IN ('cosechador','recolector','fertilizador','supervisor','admin')),
  zona            SMALLINT CHECK (zona BETWEEN 1 AND 4),
  activo          BOOLEAN NOT NULL DEFAULT TRUE,
  fecha_ingreso   DATE NOT NULL DEFAULT CURRENT_DATE
);

-- ============================================================
-- LOTE
-- ============================================================
CREATE TABLE IF NOT EXISTS lote (
  lote_id           SERIAL PRIMARY KEY,
  cod_lote          VARCHAR(20) UNIQUE NOT NULL,
  nombre            VARCHAR(100) NOT NULL,
  zona              SMALLINT NOT NULL CHECK (zona BETWEEN 1 AND 4),
  hectareas         NUMERIC(8,2),
  numero_palmas     INTEGER,
  peso_promedio_kg  NUMERIC(6,2),
  anio_siembra      SMALLINT
);

-- ============================================================
-- COSECHA
-- ============================================================
CREATE TABLE IF NOT EXISTS cosecha (
  cosecha_id                        UUID PRIMARY KEY,
  trabajador_id                     UUID NOT NULL REFERENCES trabajador(trabajador_id),
  cod_cosechero                     VARCHAR(20) NOT NULL,
  lote_id                           INTEGER NOT NULL REFERENCES lote(lote_id),
  ticket_extractora                 VARCHAR(50),
  fecha_corte                       DATE NOT NULL,
  fecha_creacion                    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  tipo_cosecha                      VARCHAR(30) NOT NULL CHECK (tipo_cosecha IN ('RECOLECTOR_DE_RACIMOS','MECANIZADA')),
  metodo_recoleccion                VARCHAR(20) NOT NULL DEFAULT 'NO_APLICA' CHECK (metodo_recoleccion IN ('CON_TIJERA','NO_APLICA')),
  total_racimos                     INTEGER NOT NULL DEFAULT 0,
  peso_extractora_sin_recolector    NUMERIC(10,2) NOT NULL DEFAULT 0,
  total_racimos_recolector          INTEGER,
  peso_extractora_recolector        NUMERIC(10,2),
  observaciones                     TEXT,
  sync_status                       VARCHAR(10) NOT NULL DEFAULT 'synced' CHECK (sync_status IN ('pending','synced')),
  created_offline                   BOOLEAN NOT NULL DEFAULT FALSE,
  device_id                         VARCHAR(100)
);

-- ============================================================
-- FERTILIZACION
-- ============================================================
CREATE TABLE IF NOT EXISTS fertilizacion (
  fertilizacion_id    UUID PRIMARY KEY,
  trabajador_id       UUID NOT NULL REFERENCES trabajador(trabajador_id),
  lote_id             INTEGER NOT NULL REFERENCES lote(lote_id),
  fecha               DATE NOT NULL,
  palmas_fertilizadas INTEGER NOT NULL DEFAULT 0,
  dosis_por_palma     NUMERIC(8,3) NOT NULL DEFAULT 0,
  total_aplicado      NUMERIC(10,3) NOT NULL DEFAULT 0,
  observaciones       TEXT,
  sync_status         VARCHAR(10) NOT NULL DEFAULT 'synced' CHECK (sync_status IN ('pending','synced')),
  device_id           VARCHAR(100),
  fecha_creacion      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- AUSENCIA
-- ============================================================
CREATE TABLE IF NOT EXISTS ausencia (
  ausencia_id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trabajador_id     UUID NOT NULL REFERENCES trabajador(trabajador_id),
  fecha             DATE NOT NULL,
  justificada       BOOLEAN NOT NULL DEFAULT FALSE,
  motivo            TEXT,
  registrado_por    VARCHAR(20) NOT NULL,
  fecha_creacion    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(trabajador_id, fecha)
);

-- ============================================================
-- TARIFA
-- ============================================================
CREATE TABLE IF NOT EXISTS tarifa (
  tarifa_id       SERIAL PRIMARY KEY,
  tipo_labor      VARCHAR(30) NOT NULL CHECK (tipo_labor IN ('cosecha_recolector','cosecha_mecanizada','fertilizacion')),
  zona            SMALLINT CHECK (zona BETWEEN 1 AND 4),
  precio_por_kg   NUMERIC(10,2),
  precio_por_unidad NUMERIC(10,2),
  fecha_inicio    DATE NOT NULL,
  fecha_fin       DATE,
  activa          BOOLEAN NOT NULL DEFAULT TRUE
);

-- ============================================================
-- INCENTIVO
-- ============================================================
CREATE TABLE IF NOT EXISTS incentivo (
  incentivo_id  SERIAL PRIMARY KEY,
  nombre        VARCHAR(150) NOT NULL,
  tipo          VARCHAR(30) NOT NULL CHECK (tipo IN ('dias_trabajados','racimos_semana','racimos_quincena')),
  umbral        NUMERIC(10,2) NOT NULL,
  monto_bono    NUMERIC(12,2) NOT NULL,
  activo        BOOLEAN NOT NULL DEFAULT TRUE,
  descripcion   TEXT
);

-- ============================================================
-- LIQUIDACION
-- ============================================================
CREATE TABLE IF NOT EXISTS liquidacion (
  liquidacion_id              SERIAL PRIMARY KEY,
  trabajador_id               UUID NOT NULL REFERENCES trabajador(trabajador_id),
  periodo_inicio              DATE NOT NULL,
  periodo_fin                 DATE NOT NULL,
  dias_trabajados             INTEGER NOT NULL DEFAULT 0,
  dias_ausencia_injustificada INTEGER NOT NULL DEFAULT 0,
  total_racimos               INTEGER NOT NULL DEFAULT 0,
  total_kg                    NUMERIC(12,2) NOT NULL DEFAULT 0,
  monto_cosecha               NUMERIC(14,2) NOT NULL DEFAULT 0,
  monto_fertilizacion         NUMERIC(14,2) NOT NULL DEFAULT 0,
  monto_bonos                 NUMERIC(14,2) NOT NULL DEFAULT 0,
  deducciones                 NUMERIC(14,2) NOT NULL DEFAULT 0,
  total_pagar                 NUMERIC(14,2) NOT NULL DEFAULT 0,
  estado                      VARCHAR(20) NOT NULL DEFAULT 'pendiente' CHECK (estado IN ('pendiente','aprobada','pagada')),
  fecha_pago                  DATE,
  fecha_calculo               TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- INDEXES
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_cosecha_trabajador ON cosecha(trabajador_id);
CREATE INDEX IF NOT EXISTS idx_cosecha_fecha ON cosecha(fecha_corte);
CREATE INDEX IF NOT EXISTS idx_cosecha_sync ON cosecha(sync_status);
CREATE INDEX IF NOT EXISTS idx_cosecha_lote ON cosecha(lote_id);
CREATE INDEX IF NOT EXISTS idx_fertilizacion_trabajador ON fertilizacion(trabajador_id);
CREATE INDEX IF NOT EXISTS idx_fertilizacion_fecha ON fertilizacion(fecha);
CREATE INDEX IF NOT EXISTS idx_fertilizacion_sync ON fertilizacion(sync_status);
CREATE INDEX IF NOT EXISTS idx_ausencia_trabajador ON ausencia(trabajador_id);
CREATE INDEX IF NOT EXISTS idx_ausencia_fecha ON ausencia(fecha);
CREATE INDEX IF NOT EXISTS idx_liquidacion_trabajador ON liquidacion(trabajador_id);
CREATE INDEX IF NOT EXISTS idx_tarifa_activa ON tarifa(activa, tipo_labor);
