-- Migration: tarifa_laboral catalog table
-- Stores the full rate catalog with versioned history.
-- Each edit deactivates the current row (sets fecha_fin) and inserts a new one.

CREATE TABLE IF NOT EXISTS tarifa_laboral (
  id               SERIAL PRIMARY KEY,
  codigo_tarifa    VARCHAR(20) UNIQUE,
  area             VARCHAR(50) NOT NULL,
  actividad        VARCHAR(50) NOT NULL,
  tipo             VARCHAR(50),
  metodo_evacuacion VARCHAR(50),
  cable            VARCHAR(30),
  propiedad_equipo VARCHAR(30),
  tipo_palma       VARCHAR(20),
  producto         VARCHAR(50),
  ubicacion        VARCHAR(50),
  rango            VARCHAR(30),
  unidad_rango     VARCHAR(40),
  unidad_tarifa    VARCHAR(20) NOT NULL,
  tarifa           NUMERIC(12,4) NOT NULL,
  descripcion_labor VARCHAR(200),
  notas            VARCHAR(200),
  fecha_inicio     DATE NOT NULL DEFAULT CURRENT_DATE,
  fecha_fin        DATE,
  activa           BOOLEAN DEFAULT TRUE,
  creado_en        TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tarifa_laboral_area ON tarifa_laboral(area);
CREATE INDEX IF NOT EXISTS idx_tarifa_laboral_activa ON tarifa_laboral(activa);
CREATE INDEX IF NOT EXISTS idx_tarifa_laboral_fechas ON tarifa_laboral(fecha_inicio, fecha_fin);

-- Seed with current rates (skip if already seeded)
INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, cable, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'CA-010','Cablevia','Plateo','Mecanico','Sencillo','Metro',28,'Eliminacion de malezas debajo del cable','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'CA-010');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, cable, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'CA-012','Cablevia','Plateo','Mecanico','Doble','Metro',54,'Eliminacion de malezas debajo del cable','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'CA-012');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, cable, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'CA-014','Cablevia','Plateo','Quimico','Sencillo','Metro',27,'Eliminacion de malezas debajo del cable','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'CA-014');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, cable, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'CA-016','Cablevia','Plateo','Quimico','Doble','Metro',52,'Eliminacion de malezas debajo del cable','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'CA-016');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'CE-018','Cercas','Arreglo','Metro','Poste',3000,'Arreglo de cercas por metro','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'CE-018');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'CE-020','Cercas','Arreglo','Poste','Metro',180,'Arreglo de cercas por poste','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'CE-020');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, propiedad_equipo, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'CE-022','Cercas','Corte','Poste','Empresa','2-3','Mts','Poste',1200,'Corte poste de 2 mts con equipo de la empresa','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'CE-022');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, propiedad_equipo, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'CE-024','Cercas','Corte','Poste','Trabajador','2-3','Mts','Poste',1900,'Corte poste de 2 mts con equipo del trabajador','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'CE-024');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'CE-026','Cercas','Corte','Poste','20-30','Diametro ctms','Poste',680,'Corte de poste de diametro entre 20 y 30 centimetros','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'CE-026');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'CE-028','Cercas','Plateo','Quimico','Poste',180,'Limpia de cerca con quimico','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'CE-028');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'CO-030','Cosecha','Alce','Tijera','0-383','Tons Mes','Kilo',7,'Alce de racimos a tijera','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'CO-030');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'CO-032','Cosecha','Alce','Tijera','383-480','Tons Mes','Kilo',8,'Alce de racimos a tijera','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'CO-032');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'CO-034','Cosecha','Alce','Tijera','480-600','Tons Mes','Kilo',9.5,'Alce de racimos a tijera','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'CO-034');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'CO-036','Cosecha','Alce','Tijera','600-1000','Tons Mes','Kilo',13,'Alce de racimos a tijera','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'CO-036');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'CO-038','Cosecha','Alce','Zorrillo','0-383','Tons Mes','Kilo',12,'Alce de racimos a zorrillo','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'CO-038');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'CO-040','Cosecha','Alce','Zorrillo','383-480','Tons Mes','Kilo',13.5,'Alce de racimos a zorrillo','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'CO-040');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'CO-042','Cosecha','Alce','Zorrillo','480-600','Tons Mes','Kilo',15.5,'Alce de racimos a zorrillo','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'CO-042');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'CO-044','Cosecha','Alce','Zorrillo','600-1000','Tons Mes','Kilo',18,'Alce de racimos a zorrillo','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'CO-044');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, ubicacion, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'CO-046','Cosecha','CorteEncalle','Mecanizada','Zona_1','0-65','Tons Mes','Kilo',33,'Corte y encalle de racimos','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'CO-046');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, ubicacion, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'CO-048','Cosecha','CorteEncalle','Mecanizada','Zona_1','65-86','Tons Mes','Kilo',35,'Corte y encalle de racimos','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'CO-048');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, ubicacion, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'CO-050','Cosecha','CorteEncalle','Mecanizada','Zona_1','86-107','Tons Mes','Kilo',37.5,'Corte y encalle de racimos','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'CO-050');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, ubicacion, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'CO-052','Cosecha','CorteEncalle','Mecanizada','Zona_1','107-128','Tons Mes','Kilo',41,'Corte y encalle de racimos','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'CO-052');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, ubicacion, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'CO-054','Cosecha','CorteEncalle','Mecanizada','Zona_1','128-180','Tons Mes','Kilo',45,'Corte y encalle de racimos','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'CO-054');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, ubicacion, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'CO-056','Cosecha','CorteEncalle','Mecanizada','Zona_2','0-68','Tons Mes','Kilo',31,'Corte y encalle de racimos','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'CO-056');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, ubicacion, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'CO-058','Cosecha','CorteEncalle','Mecanizada','Zona_2','68-89','Tons Mes','Kilo',33,'Corte y encalle de racimos','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'CO-058');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, ubicacion, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'CO-060','Cosecha','CorteEncalle','Mecanizada','Zona_2','89-110','Tons Mes','Kilo',35.5,'Corte y encalle de racimos','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'CO-060');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, ubicacion, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'CO-062','Cosecha','CorteEncalle','Mecanizada','Zona_2','110-131','Tons Mes','Kilo',39,'Corte y encalle de racimos','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'CO-062');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, ubicacion, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'CO-064','Cosecha','CorteEncalle','Mecanizada','Zona_2','131-180','Tons Mes','Kilo',43,'Corte y encalle de racimos','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'CO-064');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, ubicacion, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'CO-066','Cosecha','CorteEncalle','Mecanizada','Zona_3','0-67','Tons Mes','Kilo',32,'Corte y encalle de racimos','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'CO-066');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, ubicacion, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'CO-068','Cosecha','CorteEncalle','Mecanizada','Zona_3','67-88','Tons Mes','Kilo',34,'Corte y encalle de racimos','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'CO-068');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, ubicacion, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'CO-070','Cosecha','CorteEncalle','Mecanizada','Zona_3','88-109','Tons Mes','Kilo',36.5,'Corte y encalle de racimos','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'CO-070');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, ubicacion, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'CO-072','Cosecha','CorteEncalle','Mecanizada','Zona_3','109-130','Tons Mes','Kilo',39.5,'Corte y encalle de racimos','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'CO-072');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, ubicacion, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'CO-074','Cosecha','CorteEncalle','Mecanizada','Zona_3','130-180','Tons Mes','Kilo',43.5,'Corte y encalle de racimos','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'CO-074');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, ubicacion, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'CO-076','Cosecha','CorteEncalle','Mecanizada','Zona_4','0-76','Tons Mes','Kilo',26.5,'Corte y encalle de racimos','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'CO-076');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, ubicacion, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'CO-078','Cosecha','CorteEncalle','Mecanizada','Zona_4','76-97','Tons Mes','Kilo',28.5,'Corte y encalle de racimos','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'CO-078');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, ubicacion, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'CO-080','Cosecha','CorteEncalle','Mecanizada','Zona_4','97-128','Tons Mes','Kilo',31,'Corte y encalle de racimos','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'CO-080');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, ubicacion, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'CO-082','Cosecha','CorteEncalle','Mecanizada','Zona_4','128-149','Tons Mes','Kilo',34.5,'Corte y encalle de racimos','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'CO-082');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, ubicacion, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'CO-084','Cosecha','CorteEncalle','Mecanizada','Zona_4','149-180','Tons Mes','Kilo',38.5,'Corte y encalle de racimos','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'CO-084');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'CO-086','Cosecha','Enmalle','Kilo',4,'Enmalle de racimos','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'CO-086');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'CO-088','Cosecha','Pepeo','Kilo',284,'Recoleccion de fruto suelto','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'CO-088');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'DR-090','Drenajes','Limpia','Terciario','Metro',230,'Limpia de terciarios con pala','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'DR-090');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo_palma, producto, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'FE-092','Fertilizacion','Aplicacion','Adulta','Boro','100-200','Gramos palma','Palma',32,'Aplicacion boro','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'FE-092');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo_palma, producto, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'FE-094','Fertilizacion','Aplicacion','Adulta','Fertilizante','500-1000','Gramos palma','Palma',27,'Aplicacion fertilizante adulta','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'FE-094');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo_palma, producto, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'FE-096','Fertilizacion','Aplicacion','Adulta','Fertilizante','1000-1500','Gramos palma','Palma',29,'Aplicacion fertilizante adulta','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'FE-096');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo_palma, producto, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'FE-098','Fertilizacion','Aplicacion','Adulta','Fertilizante','1500-2000','Gramos palma','Palma',36,'Aplicacion fertilizante adulta','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'FE-098');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo_palma, producto, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'FE-100','Fertilizacion','Aplicacion','Adulta','Fertilizante','2000-2500','Gramos palma','Palma',44,'Aplicacion fertilizante adulta','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'FE-100');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo_palma, producto, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'FE-102','Fertilizacion','Aplicacion','Adulta','Fertilizante','2500-3000','Gramos palma','Palma',47,'Aplicacion fertilizante adulta','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'FE-102');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo_palma, producto, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'FE-104','Fertilizacion','Aplicacion','Adulta','Fertilizante','3000-3500','Gramos palma','Palma',53.3333,'Aplicacion fertilizante adulta','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'FE-104');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo_palma, producto, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'FE-106','Fertilizacion','Aplicacion','Adulta','Fertilizante','3500-4000','Gramos palma','Palma',80,'Aplicacion fertilizante adulta','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'FE-106');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo_palma, producto, ubicacion, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'FE-108','Fertilizacion','Aplicacion','Joven','Boro','Siembra_nueva','100-200','Gramos palma','Palma',40,'Aplicacion boro','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'FE-108');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo_palma, producto, ubicacion, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'FE-110','Fertilizacion','Aplicacion','Joven','Fertilizante','Siembra_nueva','500-1000','Gramos palma','Palma',100,'Aplicacion fertilizante palma joven','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'FE-110');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo_palma, producto, ubicacion, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'FE-112','Fertilizacion','Aplicacion','Joven','Fertilizante','Siembra_nueva','1000-1500','Gramos palma','Palma',114,'Aplicacion fertilizante palma joven','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'FE-112');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo_palma, producto, ubicacion, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'FE-114','Fertilizacion','Aplicacion','Joven','Fertilizante','Siembra_nueva','1500-2000','Gramos palma','Palma',133,'Aplicacion fertilizante palma joven','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'FE-114');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo_palma, producto, ubicacion, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'FE-116','Fertilizacion','Aplicacion','Joven','Fertilizante','Siembra_nueva','2000-2500','Gramos palma','Palma',160,'Aplicacion fertilizante palma joven','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'FE-116');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo_palma, producto, ubicacion, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'FE-118','Fertilizacion','Aplicacion','Joven','Fertilizante','Siembra_nueva','2500-3000','Gramos palma','Palma',200,'Aplicacion fertilizante palma joven','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'FE-118');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo_palma, producto, ubicacion, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'FE-120','Fertilizacion','Aplicacion','Joven','Fertilizante','Siembra_nueva','3000-3500','Gramos palma','Palma',229,'Aplicacion fertilizante palma joven','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'FE-120');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo_palma, producto, ubicacion, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'FE-122','Fertilizacion','Aplicacion','Joven','Fertilizante','Siembra_nueva','3500-4000','Gramos palma','Palma',267,'Aplicacion fertilizante palma joven','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'FE-122');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo_palma, producto, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'FE-124','Fertilizacion','Aplicacion','Adulta','Tusa','Palma',1000,'Aplicacion de tusa','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'FE-124');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, producto, ubicacion, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'FE-126','Fertilizacion','Aplicacion','Fertilizante','Ensayo','1000-2500','Gramos palma','Palma',120,'Aplicacion fertilizante ensayo','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'FE-126');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo_palma, producto, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'FE-128','Fertilizacion','Aplicacion','Adulta','Drench','LITRO',133,'Ensayo palma adulta drench','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'FE-128');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, producto, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'FE-132','Fertilizacion','Cargue','Fertilizante','Kilo',16,'Cargue - descargue fertilizante','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'FE-132');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'LA-134','LABORAL','Jornal','Normal','Dia',60000,'Jornal normal destajo','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'LA-134');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'LA-136','LABORAL','Jornal','Minimo','Dia',58363.5,'Jornal minimo','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'LA-136');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'LA-138','LABORAL','Jornal','Tecnico','Dia',100000,'Jornal tecnico','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'LA-138');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'MA-140','Mantenimiento','Desmocune','Palma',266,'Control de kudzu, desmocune','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'MA-140');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, propiedad_equipo, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'MA-142','Mantenimiento','Plateo','Mecanico','Trabajador','Palma',230,'Plateo mecanico con equipo propio del trabajador','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'MA-142');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, propiedad_equipo, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'MA-144','Mantenimiento','Plateo','Mecanico','Empresa','Palma',207,'Plateo mecanico con equipo de la empresa','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'MA-144');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'MA-146','Mantenimiento','Plateo','Quimico','Palma',90,'Plateo quimico','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'MA-146');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, tipo_palma, ubicacion, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'MA-148','Mantenimiento','Poda','Desparrille','Joven','Siembra_nueva','Palma',900,'Poda sanitaria o desparrille','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'MA-148');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, tipo_palma, ubicacion, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'MA-150','Mantenimiento','Poda','Normal','Adulta','Zona_1','Ciclo',71,'Poda','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'MA-150');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, tipo_palma, ubicacion, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'MA-152','Mantenimiento','Poda','Normal','Adulta','Zona_2','Ciclo',64,'Poda','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'MA-152');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, tipo_palma, ubicacion, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'MA-154','Mantenimiento','Poda','Normal','Adulta','Zona_3','Ciclo',56,'Poda','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'MA-154');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, tipo_palma, ubicacion, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'MA-156','Mantenimiento','Poda','Normal','Adulta','Zona_4','Ciclo',49,'Poda','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'MA-156');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, tipo_palma, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'MA-158','Mantenimiento','Poda','Rancho','Adulta','Palma',5000,'Eliminacion de ranchos','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'MA-158');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, rango, unidad_rango, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'MA-160','Mantenimiento','Rastrillo','2-3','Diametro mts','Palma',300,'Rastrilleo de plato por diametro','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'MA-160');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'MA-162','Mantenimiento','Roseria','Hectarea',41000,'Roseria selectiva','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'MA-162');

INSERT INTO tarifa_laboral (codigo_tarifa, area, actividad, tipo, unidad_tarifa, tarifa, descripcion_labor, fecha_inicio)
  SELECT 'SA-164','Sanidad','Fumigacion','PC','Palma',90,'Fumigacion PC','2026-05-01'
  WHERE NOT EXISTS (SELECT 1 FROM tarifa_laboral WHERE codigo_tarifa = 'SA-164');
