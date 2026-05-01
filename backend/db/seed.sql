-- Hacienda La Ilusión — Seed Data
-- Run after schema.sql

-- ============================================================
-- LOTES (10 lotes across 4 zonas)
-- ============================================================
INSERT INTO lote (cod_lote, nombre, zona, hectareas, numero_palmas, peso_promedio_kg, anio_siembra) VALUES
  ('021A', 'Lote 21A', 1, 18.5, 1110, 22.5, 2005),
  ('010B', 'Lote 10B', 1, 15.2, 912, 20.0, 2007),
  ('033',  'Lote 33',  2, 22.0, 1320, 24.0, 2003),
  ('042',  'Lote 42',  2, 19.8, 1188, 21.5, 2006),
  ('015C', 'Lote 15C', 2, 16.0, 960,  23.0, 2008),
  ('057',  'Lote 57',  3, 25.0, 1500, 25.5, 2001),
  ('061',  'Lote 61',  3, 20.5, 1230, 22.0, 2004),
  ('074',  'Lote 74',  4, 17.5, 1050, 19.5, 2009),
  ('082',  'Lote 82',  4, 23.0, 1380, 26.0, 2002),
  ('091B', 'Lote 91B', 4, 14.0, 840,  21.0, 2010)
ON CONFLICT (cod_lote) DO NOTHING;

-- ============================================================
-- TRABAJADORES (15 workers: mix of roles)
-- Passwords: bcrypt of '1234' — replace with real hashes in production
-- PINs: 4-digit codes for offline login
-- ============================================================
INSERT INTO trabajador (cod_cosechero, cedula, nombre_completo, telefono, pin, password_hash, rol, zona, activo, fecha_ingreso) VALUES
  ('HLI001', '1001234567', 'Carlos Ernesto Pérez',     '3101234001', '1234', NULL, 'cosechador',   1, TRUE, '2022-01-15'),
  ('HLI002', '1002345678', 'Jhon Alexander Ruiz',      '3101234002', '2345', NULL, 'cosechador',   1, TRUE, '2021-06-10'),
  ('HLI003', '1003456789', 'Mauricio Salcedo Vargas',  '3101234003', '3456', NULL, 'cosechador',   2, TRUE, '2023-03-01'),
  ('HLI004', '1004567890', 'Luis Fernando Cano',       '3101234004', '4567', NULL, 'cosechador',   2, TRUE, '2022-08-20'),
  ('HLI005', '1005678901', 'Pedro Antonio Mena',       '3101234005', '5678', NULL, 'cosechador',   3, TRUE, '2021-11-05'),
  ('HLI006', '1006789012', 'Edwin Javier Torres',      '3101234006', '6789', NULL, 'cosechador',   3, TRUE, '2022-04-12'),
  ('HLI007', '1007890123', 'Rodrigo Stiven Leal',      '3101234007', '7890', NULL, 'cosechador',   4, TRUE, '2023-01-08'),
  ('HLI008', '1008901234', 'Nelson Fabio Díaz',        '3101234008', '8901', NULL, 'recolector',   1, TRUE, '2022-07-15'),
  ('HLI009', '1009012345', 'Jairo Andrés Moreno',      '3101234009', '9012', NULL, 'recolector',   2, TRUE, '2021-09-20'),
  ('HLI010', '1010123456', 'William Ospina Castro',    '3101234010', '0123', NULL, 'fertilizador', 1, TRUE, '2022-02-28'),
  ('HLI011', '1011234567', 'Diego Armando Herrera',    '3101234011', '1122', NULL, 'fertilizador', 2, TRUE, '2023-05-15'),
  ('HLI012', '1012345678', 'Óscar Iván Gutierrez',     '3101234012', '2233', NULL, 'fertilizador', 3, TRUE, '2021-12-01'),
  ('HLI013', '1013456789', 'Rafael Antonio Silva',     '3101234013', '3344', NULL, 'supervisor',   1, TRUE, '2020-03-10'),
  ('TT639',  '1014567890', 'Tomás Arbeláez García',    '3101234014', '4455', NULL, 'cosechador',   2, TRUE, '2022-10-05'),
  ('ADMIN01','1099999999', 'Administrador Sistema',    '3101230000', '0000', '$2b$10$examplehashadmin000000000000000000000000000', 'admin', NULL, TRUE, '2020-01-01')
ON CONFLICT (cod_cosechero) DO NOTHING;

-- ============================================================
-- TARIFAS (rates per tipo_labor — COP per kg or unit)
-- ============================================================
INSERT INTO tarifa (tipo_labor, zona, precio_por_kg, precio_por_unidad, fecha_inicio, activa) VALUES
  ('cosecha_recolector', 1, 85.00,  NULL, '2024-01-01', TRUE),
  ('cosecha_recolector', 2, 88.00,  NULL, '2024-01-01', TRUE),
  ('cosecha_recolector', 3, 90.00,  NULL, '2024-01-01', TRUE),
  ('cosecha_recolector', 4, 87.00,  NULL, '2024-01-01', TRUE),
  ('cosecha_mecanizada', 1, 75.00,  NULL, '2024-01-01', TRUE),
  ('cosecha_mecanizada', 2, 77.00,  NULL, '2024-01-01', TRUE),
  ('cosecha_mecanizada', 3, 79.00,  NULL, '2024-01-01', TRUE),
  ('cosecha_mecanizada', 4, 76.00,  NULL, '2024-01-01', TRUE),
  ('fertilizacion',      1, NULL, 350.00, '2024-01-01', TRUE),
  ('fertilizacion',      2, NULL, 360.00, '2024-01-01', TRUE),
  ('fertilizacion',      3, NULL, 370.00, '2024-01-01', TRUE),
  ('fertilizacion',      4, NULL, 355.00, '2024-01-01', TRUE)
ON CONFLICT DO NOTHING;

-- ============================================================
-- INCENTIVOS
-- ============================================================
INSERT INTO incentivo (nombre, tipo, umbral, monto_bono, activo, descripcion) VALUES
  (
    'Bono asistencia perfecta quincena',
    'dias_trabajados',
    14,
    50000,
    TRUE,
    'Trabaja los 14 días hábiles de la quincena sin ausencias injustificadas y gana $50.000 adicionales'
  ),
  (
    'Bono productividad quincena',
    'racimos_quincena',
    500,
    80000,
    TRUE,
    'Supera 500 racimos en la quincena y gana $80.000 adicionales'
  )
ON CONFLICT DO NOTHING;

-- ============================================================
-- SAMPLE COSECHA RECORDS (30 records across 7 days)
-- Using UUIDs and the first 9 cosechador/recolector workers
-- ============================================================
INSERT INTO cosecha (
  cosecha_id, trabajador_id, cod_cosechero, lote_id,
  ticket_extractora, fecha_corte, tipo_cosecha, metodo_recoleccion,
  total_racimos, peso_extractora_sin_recolector,
  total_racimos_recolector, peso_extractora_recolector,
  sync_status, created_offline, device_id
) SELECT
  gen_random_uuid(),
  t.trabajador_id,
  t.cod_cosechero,
  l.lote_id,
  'TKT-' || LPAD((ROW_NUMBER() OVER())::TEXT, 5, '0'),
  CURRENT_DATE - (gs.day_offset || ' days')::INTERVAL,
  CASE WHEN t.rol = 'recolector' THEN 'RECOLECTOR_DE_RACIMOS' ELSE 'MECANIZADA' END,
  CASE WHEN t.rol = 'recolector' THEN 'CON_TIJERA' ELSE 'NO_APLICA' END,
  (50 + FLOOR(RANDOM() * 100))::INTEGER,
  (800 + FLOOR(RANDOM() * 1200))::NUMERIC(10,2),
  CASE WHEN t.rol = 'recolector' THEN (20 + FLOOR(RANDOM() * 40))::INTEGER ELSE NULL END,
  CASE WHEN t.rol = 'recolector' THEN (200 + FLOOR(RANDOM() * 400))::NUMERIC(10,2) ELSE NULL END,
  'synced',
  FALSE,
  'SERVER_SEED'
FROM
  (SELECT generate_series(0, 6) AS day_offset) gs
  CROSS JOIN (
    SELECT t.trabajador_id, t.cod_cosechero, t.rol, t.zona,
           ROW_NUMBER() OVER() AS rn
    FROM trabajador t
    WHERE t.rol IN ('cosechador','recolector') AND t.activo = TRUE
    LIMIT 9
  ) t
  JOIN lote l ON l.zona = t.zona
WHERE
  (gs.day_offset + t.rn) % 3 != 0
LIMIT 30;

-- ============================================================
-- SAMPLE FERTILIZACION RECORDS
-- ============================================================
INSERT INTO fertilizacion (
  fertilizacion_id, trabajador_id, lote_id, fecha,
  palmas_fertilizadas, dosis_por_palma, total_aplicado,
  sync_status, device_id
) SELECT
  gen_random_uuid(),
  t.trabajador_id,
  l.lote_id,
  CURRENT_DATE - (gs.day_offset || ' days')::INTERVAL,
  (50 + FLOOR(RANDOM() * 150))::INTEGER,
  2.5,
  ((50 + FLOOR(RANDOM() * 150)) * 2.5)::NUMERIC(10,3),
  'synced',
  'SERVER_SEED'
FROM
  (SELECT generate_series(0, 6) AS day_offset) gs
  CROSS JOIN (
    SELECT t.trabajador_id, t.zona
    FROM trabajador t
    WHERE t.rol = 'fertilizador' AND t.activo = TRUE
  ) t
  JOIN lote l ON l.zona = t.zona
LIMIT 15;
