-- =====================================================================
-- CURSO DE SQL  |  CLASE 3  |  AgroDB - nucleo del sistema
-- Motor: SQLite   |   Entorno: sqliteonline.com
--
-- Este archivo NO se modifica. Se pega tal cual en sqliteonline y se
-- ejecuta completo ANTES de empezar el ejercicio. Crea:
--   * las 4 tablas del nucleo, ya cargadas
--   * la tabla registro_campo_plano, que es la que hay que arreglar
--
-- Contexto: AgroDB es la base de datos detras de un sistema de gestion
-- agricola. Cada finca tiene lotes, en cada lote se hacen siembras de
-- un cultivo, y sobre cada siembra se ejecutan labores de campo.
-- =====================================================================

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS registro_campo_plano;
DROP TABLE IF EXISTS siembras;
DROP TABLE IF EXISTS lotes;
DROP TABLE IF EXISTS cultivos;
DROP TABLE IF EXISTS fincas;


-- ---------------------------------------------------------------------
-- 1. FINCAS
-- ---------------------------------------------------------------------
CREATE TABLE fincas (
    finca_id       INTEGER PRIMARY KEY,
    nombre         TEXT    NOT NULL UNIQUE,
    provincia      TEXT    NOT NULL,
    hectareas      NUMERIC(10,2) NOT NULL CHECK (hectareas > 0),
    fecha_registro DATE    NOT NULL,
    responsable    TEXT                              -- puede ser NULL
);

-- ---------------------------------------------------------------------
-- 2. CULTIVOS  (catalogo: que se puede sembrar)
-- ---------------------------------------------------------------------
CREATE TABLE cultivos (
    cultivo_id  INTEGER PRIMARY KEY,
    nombre      TEXT    NOT NULL,
    variedad    TEXT,                                -- puede ser NULL
    ciclo_dias  INTEGER NOT NULL CHECK (ciclo_dias > 0),
    tipo        TEXT    NOT NULL                     -- 'perenne' o 'ciclo corto'
);

-- ---------------------------------------------------------------------
-- 3. LOTES  (una finca tiene muchos lotes)
-- ---------------------------------------------------------------------
CREATE TABLE lotes (
    lote_id    INTEGER PRIMARY KEY,
    finca_id   INTEGER NOT NULL REFERENCES fincas(finca_id),
    codigo     TEXT    NOT NULL,
    hectareas  NUMERIC(10,2) NOT NULL CHECK (hectareas > 0),
    tipo_suelo TEXT,
    UNIQUE (finca_id, codigo)        -- el codigo se repite entre fincas,
);                                   -- pero no dentro de la misma finca

-- ---------------------------------------------------------------------
-- 4. SIEMBRAS  (en un lote, un cultivo, en una fecha)
-- ---------------------------------------------------------------------
CREATE TABLE siembras (
    siembra_id       INTEGER PRIMARY KEY,
    lote_id          INTEGER NOT NULL REFERENCES lotes(lote_id),
    cultivo_id       INTEGER NOT NULL REFERENCES cultivos(cultivo_id),
    fecha_siembra    DATE    NOT NULL,
    densidad_plantas INTEGER NOT NULL CHECK (densidad_plantas > 0),
    estado           TEXT    NOT NULL DEFAULT 'en curso'
);


-- =====================================================================
-- CARGA DEL NUCLEO
-- =====================================================================

INSERT INTO fincas (finca_id, nombre, provincia, hectareas, fecha_registro, responsable) VALUES
  (1, 'Hacienda Santa Rosa', 'Los Rios', 145.50, '2024-03-12', 'Marta Ruiz'),
  (2, 'Finca El Guayabo',    'Guayas',    62.00, '2024-07-01', 'Luis Paez'),
  (3, 'Agricola La Union',   'Manabi',   210.75, '2025-01-20', NULL);

INSERT INTO cultivos (cultivo_id, nombre, variedad, ciclo_dias, tipo) VALUES
  (1, 'Mango',   'Tommy Atkins', 1460, 'perenne'),
  (2, 'Guayaba', 'Taiwanesa',     730, 'perenne'),
  (3, 'Cacao',   'CCN-51',       1095, 'perenne'),
  (4, 'Banano',  'Cavendish',     300, 'perenne'),
  (5, 'Maiz',    'INIAP-180',     120, 'ciclo corto'),
  (6, 'Cafe',    NULL,           1095, 'perenne');

INSERT INTO lotes (lote_id, finca_id, codigo, hectareas, tipo_suelo) VALUES
  (1, 1, 'L-01', 28.50, 'franco arcilloso'),
  (2, 1, 'L-02', 31.00, 'franco'),
  (3, 1, 'L-03', 19.25, NULL),
  (4, 2, 'L-01', 22.00, 'arenoso'),
  (5, 2, 'L-02', 18.50, 'franco'),
  (6, 3, 'A-1',  55.00, 'franco arcilloso'),
  (7, 3, 'A-2',  47.30, 'arcilloso'),
  (8, 3, 'B-1',  34.00, NULL);

INSERT INTO siembras (siembra_id, lote_id, cultivo_id, fecha_siembra, densidad_plantas, estado) VALUES
  (1,  1, 1, '2025-02-10', 2800, 'en produccion'),
  (2,  2, 1, '2025-03-05', 3100, 'en produccion'),
  (3,  3, 2, '2025-06-18', 1900, 'en curso'),
  (4,  4, 2, '2025-05-22', 2200, 'en produccion'),
  (5,  5, 5, '2026-01-15', 6500, 'cosechado'),
  (6,  6, 3, '2024-11-08', 4100, 'en produccion'),
  (7,  7, 3, '2025-01-30', 3950, 'en curso'),
  (8,  8, 4, '2025-09-14', 5200, 'en curso'),
  (9,  1, 5, '2026-02-02', 7000, 'perdido'),
  (10, 6, 1, '2025-04-19', 2600, 'en curso');


-- =====================================================================
-- LA TABLA QUE HAY QUE ARREGLAR
--
-- Asi es como el jefe de campo lleva hoy el registro de labores: una
-- sola hoja de Excel, importada tal cual. Funciona... hasta que no.
-- =====================================================================

CREATE TABLE registro_campo_plano (
    id             INTEGER PRIMARY KEY,
    finca          TEXT,
    provincia      TEXT,
    lote           TEXT,
    cultivo        TEXT,
    fecha_labor    DATE,
    tipo_labor     TEXT,
    responsable    TEXT,
    insumo_1       TEXT,
    cantidad_1     NUMERIC(10,2),
    unidad_1       TEXT,
    costo_unit_1   NUMERIC(10,2),
    insumo_2       TEXT,
    cantidad_2     NUMERIC(10,2),
    unidad_2       TEXT,
    costo_unit_2   NUMERIC(10,2),
    costo_total    NUMERIC(10,2)
);

INSERT INTO registro_campo_plano VALUES
 (1,'Hacienda Santa Rosa','Los Rios','L-01','Mango','2026-03-04','fertilizacion','Marta Ruiz',
    'Urea 46%',120,'kg',0.68,'Muriato de potasio',80,'kg',0.74,140.80),
 (2,'Hacienda Santa Rosa','Los Rios','L-01','Mango','2026-03-19','control fitosanitario','Marta Ruiz',
    'Mancozeb',15,'kg',5.20,NULL,NULL,NULL,NULL,78.00),
 (3,'Hacienda Santa Rosa','Los Rios','L-02','Mango','2026-03-06','fertilizacion','Jorge Mina',
    'Urea 46%',140,'kg',0.68,NULL,NULL,NULL,NULL,95.20),
 (4,'Hacienda Sta. Rosa','Los Rios','L-02','Mango','2026-04-02','riego','Jorge Mina',
    NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,45.00),
 (5,'Hacienda Santa Rosa','Los Rios','L-03','Guayaba','2026-03-25','poda','Ana Cedeno',
    NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,210.00),
 (6,'Finca El Guayabo','Guayas','L-01','Guayaba','2026-03-11','fertilizacion','Luis Paez',
    'Urea 46%',90,'kg',0.68,'Abono organico',300,'kg',0.22,127.20),
 (7,'Finca El Guayabo','Guayas','L-01','Guayaba','2026-04-08','control fitosanitario','Luis Paez',
    'Mancozeb',10,'kg',5.20,'Aceite agricola',12,'L',3.90,98.80),
 (8,'Finca El Guayabo','Guayas','L-02','Maiz','2026-02-14','siembra','Luis Paez',
    'Semilla INIAP-180',45,'kg',2.10,NULL,NULL,NULL,NULL,94.50),
 (9,'Finca El Guayabo','Guayas','L-02','Maiz','2026-03-02','fertilizacion','Rosa Vera',
    'Urea 46%',60,'kg',0.70,NULL,NULL,NULL,NULL,42.00),
 (10,'Agricola La Union','Manabi','A-1','Cacao','2026-03-17','fertilizacion','Pedro Loor',
    'Muriato de potasio',150,'kg',0.74,'Abono organico',400,'kg',0.22,199.00),
 (11,'Agricola La Union','Manabi','A-2','Cacao','2026-03-28','control fitosanitario','Pedro Loor',
    'Mancozeb',22,'kg',5.20,NULL,NULL,NULL,NULL,114.40),
 (12,'Agricola La Union','Manabi','B-1','Banano','2026-04-05','riego','Pedro Loor',
    NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,68.00);


-- =====================================================================
-- VERIFICACION: deben salir 3, 6, 8, 10 y 12
-- =====================================================================
SELECT 'fincas'   AS tabla, COUNT(*) AS filas FROM fincas
UNION ALL SELECT 'cultivos', COUNT(*) FROM cultivos
UNION ALL SELECT 'lotes',    COUNT(*) FROM lotes
UNION ALL SELECT 'siembras', COUNT(*) FROM siembras
UNION ALL SELECT 'plano',    COUNT(*) FROM registro_campo_plano;
