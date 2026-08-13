-- =====================================================================
-- CURSO DE SQL  |  CLASE 4  |  AgroDB - base con datos sucios
-- Motor: SQLite   |   Entorno: sqliteonline.com
--
-- AUTOCONTENIDO: se pega COMPLETO en una pestana nueva y se ejecuta.
-- No necesita agrodb_nucleo.sql previo, ya lo incluye.
--
-- Trae el modelo normalizado de la clase 3 (version de referencia) mas
-- el lote de labores de abril, que llego con problemas. Ese lote es el
-- que hay que limpiar hoy.
-- =====================================================================

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS labor_insumo;
DROP TABLE IF EXISTS labores;
DROP TABLE IF EXISTS insumos;
DROP TABLE IF EXISTS sensores;
DROP TABLE IF EXISTS registro_campo_plano;
DROP TABLE IF EXISTS siembras;
DROP TABLE IF EXISTS lotes;
DROP TABLE IF EXISTS cultivos;
DROP TABLE IF EXISTS fincas;

-- ---------------------------------------------------------------------
-- NUCLEO
-- ---------------------------------------------------------------------
CREATE TABLE fincas (
    finca_id       INTEGER PRIMARY KEY,
    nombre         TEXT    NOT NULL UNIQUE,
    provincia      TEXT    NOT NULL,
    hectareas      NUMERIC(10,2) NOT NULL CHECK (hectareas > 0),
    fecha_registro DATE    NOT NULL,
    responsable    TEXT
);

CREATE TABLE cultivos (
    cultivo_id INTEGER PRIMARY KEY,
    nombre     TEXT    NOT NULL,
    variedad   TEXT,
    ciclo_dias INTEGER NOT NULL CHECK (ciclo_dias > 0),
    tipo       TEXT    NOT NULL
);

CREATE TABLE lotes (
    lote_id    INTEGER PRIMARY KEY,
    finca_id   INTEGER NOT NULL REFERENCES fincas(finca_id),
    codigo     TEXT    NOT NULL,
    hectareas  NUMERIC(10,2) NOT NULL CHECK (hectareas > 0),
    tipo_suelo TEXT,
    UNIQUE (finca_id, codigo)
);

CREATE TABLE siembras (
    siembra_id       INTEGER PRIMARY KEY,
    lote_id          INTEGER NOT NULL REFERENCES lotes(lote_id),
    cultivo_id       INTEGER NOT NULL REFERENCES cultivos(cultivo_id),
    fecha_siembra    DATE    NOT NULL,
    densidad_plantas INTEGER NOT NULL CHECK (densidad_plantas > 0),
    estado           TEXT    NOT NULL DEFAULT 'en curso'
);

-- ---------------------------------------------------------------------
-- MODELO NORMALIZADO (resultado esperado de la clase 3)
--
-- Fijate en las clausulas ON DELETE: cada una expresa una decision
-- distinta sobre que pasa cuando se borra el padre.
-- ---------------------------------------------------------------------
CREATE TABLE insumos (
    insumo_id             INTEGER PRIMARY KEY,
    nombre                TEXT NOT NULL UNIQUE,
    tipo                  TEXT NOT NULL,
    unidad                TEXT NOT NULL,
    costo_unit_referencia NUMERIC(10,2)
);

CREATE TABLE labores (
    labor_id        INTEGER PRIMARY KEY,
    siembra_id      INTEGER NOT NULL REFERENCES siembras(siembra_id),
    tipo_labor      TEXT    NOT NULL,
    fecha           DATE    NOT NULL,
    responsable     TEXT,
    costo_mano_obra NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (costo_mano_obra >= 0),
    observacion     TEXT
);

CREATE TABLE labor_insumo (
    labor_id       INTEGER NOT NULL REFERENCES labores(labor_id) ON DELETE CASCADE,
    insumo_id      INTEGER NOT NULL REFERENCES insumos(insumo_id) ON DELETE RESTRICT,
    cantidad       NUMERIC(10,2) NOT NULL CHECK (cantidad > 0),
    costo_unitario NUMERIC(10,2) NOT NULL CHECK (costo_unitario >= 0),
    PRIMARY KEY (labor_id, insumo_id)
);

CREATE TABLE sensores (
    sensor_id         INTEGER PRIMARY KEY,
    lote_id           INTEGER NOT NULL REFERENCES lotes(lote_id),
    tipo              TEXT    NOT NULL,
    modelo            TEXT,
    fecha_instalacion DATE    NOT NULL,
    activo            INTEGER NOT NULL DEFAULT 1 CHECK (activo IN (0,1))
);


-- =====================================================================
-- DATOS LIMPIOS (marzo)
-- =====================================================================
INSERT INTO fincas VALUES
  (1,'Hacienda Santa Rosa','Los Rios',145.50,'2024-03-12','Marta Ruiz'),
  (2,'Finca El Guayabo','Guayas',62.00,'2024-07-01','Luis Paez'),
  (3,'Agricola La Union','Manabi',210.75,'2025-01-20',NULL);

INSERT INTO cultivos VALUES
  (1,'Mango','Tommy Atkins',1460,'perenne'),
  (2,'Guayaba','Taiwanesa',730,'perenne'),
  (3,'Cacao','CCN-51',1095,'perenne'),
  (4,'Banano','Cavendish',300,'perenne'),
  (5,'Maiz','INIAP-180',120,'ciclo corto'),
  (6,'Cafe',NULL,1095,'perenne');

INSERT INTO lotes VALUES
  (1,1,'L-01',28.50,'franco arcilloso'),
  (2,1,'L-02',31.00,'franco'),
  (3,1,'L-03',19.25,NULL),
  (4,2,'L-01',22.00,'arenoso'),
  (5,2,'L-02',18.50,'franco'),
  (6,3,'A-1',55.00,'franco arcilloso'),
  (7,3,'A-2',47.30,'arcilloso'),
  (8,3,'B-1',34.00,NULL);

INSERT INTO siembras VALUES
  (1,1,1,'2025-02-10',2800,'en produccion'),
  (2,2,1,'2025-03-05',3100,'en produccion'),
  (3,3,2,'2025-06-18',1900,'en curso'),
  (4,4,2,'2025-05-22',2200,'en produccion'),
  (5,5,5,'2026-01-15',6500,'cosechado'),
  (6,6,3,'2024-11-08',4100,'en produccion'),
  (7,7,3,'2025-01-30',3950,'en curso'),
  (8,8,4,'2025-09-14',5200,'en curso'),
  (9,1,5,'2026-02-02',7000,'perdido'),
  (10,6,1,'2025-04-19',2600,'en curso');

INSERT INTO insumos VALUES
  (1,'Urea 46%','fertilizante','kg',0.68),
  (2,'Muriato de potasio','fertilizante','kg',0.74),
  (3,'Mancozeb','fungicida','kg',5.20),
  (4,'Abono organico','fertilizante','kg',0.22),
  (5,'Aceite agricola','coadyuvante','L',3.90),
  (6,'Semilla INIAP-180','semilla','kg',2.10),
  (7,'Cal agricola','enmienda','kg',0.15);

INSERT INTO labores VALUES
  (1, 1,'fertilizacion','2026-03-04','Marta Ruiz',0.00,NULL),
  (2, 1,'control fitosanitario','2026-03-19','Marta Ruiz',0.00,NULL),
  (3, 2,'fertilizacion','2026-03-06','Jorge Mina',0.00,NULL),
  (4, 2,'riego','2026-04-02','Jorge Mina',45.00,'sin insumos'),
  (5, 3,'poda','2026-03-25','Ana Cedeno',210.00,'sin insumos'),
  (6, 4,'fertilizacion','2026-03-11','Luis Paez',0.00,NULL),
  (7, 4,'control fitosanitario','2026-04-08','Luis Paez',0.00,NULL),
  (8, 5,'siembra','2026-02-14','Luis Paez',0.00,NULL),
  (9, 5,'fertilizacion','2026-03-02','Rosa Vera',0.00,NULL),
  (10,6,'fertilizacion','2026-03-17','Pedro Loor',0.00,NULL),
  (11,7,'control fitosanitario','2026-03-28','Pedro Loor',0.00,NULL),
  (12,8,'riego','2026-04-05','Pedro Loor',68.00,'sin insumos');

INSERT INTO labor_insumo VALUES
  (1,1,120,0.68), (1,2,80,0.74), (2,3,15,5.20), (3,1,140,0.68),
  (6,1,90,0.68),  (6,4,300,0.22), (7,3,10,5.20), (7,5,12,3.90),
  (8,6,45,2.10),  (9,1,60,0.70),  (10,2,150,0.74), (10,4,400,0.22),
  (11,3,22,5.20);

INSERT INTO sensores VALUES
  (1,1,'temperatura','HYGROCLIP','2026-01-15',1),
  (2,1,'humedad','HYGROCLIP','2026-01-15',1),
  (3,2,'temperatura','HYGROCLIP','2026-02-03',1),
  (4,4,'radiacion','PYRANOMETER','2026-02-20',1),
  (5,6,'temperatura','uMETOS BASE','2025-11-30',0),
  (6,6,'humedad','uMETOS BASE','2025-11-30',1);


-- =====================================================================
-- EL LOTE DE ABRIL  <-- ESTO ES LO QUE HAY QUE LIMPIAR
--
-- Lo cargo un pasante desde una planilla, sin revisar. Todo entro sin
-- un solo mensaje de error. Ninguna restriccion lo impidio, porque
-- ninguno de estos problemas es un problema de tipo de dato.
-- =====================================================================

-- Dos insumos que ya existian, cargados de nuevo con otra escritura
INSERT INTO insumos VALUES
  (8,'Urea 46 %','fertilizante','kg',0.68),      -- duplicado de 1 (espacio)
  (9,'MANCOZEB','fungicida','kg',5.20);          -- duplicado de 3 (mayusculas)

INSERT INTO labores VALUES
  (13,1,'fertilizacion','2026-04-10','Marta Ruiz',0.00,NULL),
  (14,4,'riego','2026-04-14','Luis Paez',52.00,NULL),
  -- 15 y 16 son la MISMA labor cargada dos veces
  (15,6,'control fitosanitario','2026-04-16','Pedro Loor',0.00,NULL),
  (16,6,'control fitosanitario','2026-04-16','Pedro Loor',0.00,NULL),
  -- fecha en formato dd/mm/aaaa: ordena mal y strftime no la entiende
  (17,2,'poda','15/04/2026','Jorge Mina',180.00,NULL),
  -- el texto 'NULL' NO es NULL
  (18,7,'riego','2026-04-18','NULL',60.00,NULL),
  -- jornal que nunca se cargo
  (19,3,'cosecha','2026-04-22','Ana Cedeno',0.00,'jornal pendiente de cargar: 145.00'),
  -- usa los DOS ids de la urea en la misma labor
  (20,8,'fertilizacion','2026-04-25','Pedro Loor',0.00,NULL);

INSERT INTO labor_insumo VALUES
  (13,8,110,0.70),   -- urea, pero con el id duplicado
  (15,9,18,5.30),    -- mancozeb, pero con el id duplicado
  (16,9,18,5.30),    -- la copia de la labor duplicada
  (20,1,60,0.70),    -- urea id 1
  (20,8,40,0.70);    -- ...y urea id 8, en la MISMA labor


-- =====================================================================
-- VERIFICACION DE CARGA: 3, 6, 8, 10, 9, 20, 18, 6
-- =====================================================================
SELECT 'fincas' AS tabla, COUNT(*) AS filas FROM fincas
UNION ALL SELECT 'cultivos', COUNT(*) FROM cultivos
UNION ALL SELECT 'lotes',    COUNT(*) FROM lotes
UNION ALL SELECT 'siembras', COUNT(*) FROM siembras
UNION ALL SELECT 'insumos',  COUNT(*) FROM insumos
UNION ALL SELECT 'labores',  COUNT(*) FROM labores
UNION ALL SELECT 'labor_insumo', COUNT(*) FROM labor_insumo
UNION ALL SELECT 'sensores', COUNT(*) FROM sensores;
