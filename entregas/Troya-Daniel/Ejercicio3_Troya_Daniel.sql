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

-- ==========================================================
-- PARTE A - DIAGNOSTICO
-- ==========================================================

-- 1.
-- Si llega una labor que utilizó 3 insumos, no hay dónde
-- guardar el tercero porque la tabla solo tiene insumo_1
-- e insumo_2.
--
-- Para registrarlo habría que agregar nuevas columnas
-- (insumo_3, cantidad_3, unidad_3, costo_unit_3) o dejar
-- información fuera de la base.
--
-- Es un problema grave porque obliga a modificar la
-- estructura de la tabla cada vez que aparezca una nueva
-- necesidad
-- 2.
-- Consulta ejecutada:
-- SELECT finca, COUNT(*)
-- FROM registro_campo_plano
-- GROUP BY finca;
--
-- Resultado obtenido:
--
-- Agricola La Union      3
-- Finca El Guayabo       4
-- Hacienda Santa Rosa    4
-- Hacienda Sta. Rosa     1
--
-- En realidad existen solamente 3 fincas.
--
-- La consulta muestra 4 valores porque una misma finca fue
-- escrita de dos maneras distintas:
--
-- 'Hacienda Santa Rosa'
-- 'Hacienda Sta. Rosa'
--
-- Como SQLite compara el texto literalmente, considera
-- ambos nombres diferentes y los cuenta como grupos
-- distintos.
--
-- SQLite NO genera un error. La consulta funciona
-- correctamente; el problema está en la calidad de los
-- datos almacenados.

-- 3.
-- La columna provincia no depende de cada fila sino de la
-- finca.
--
-- Una finca siempre pertenece a una provincia determinada,
-- por lo que la provincia depende de la finca y no de la
-- labor realizada.
--
-- Si "Los Rios" cambiara de nombre habría que actualizar
-- todas las filas donde aparezca esa provincia, con riesgo
-- de dejar registros inconsistentes. Esto es una anomalía
-- de actualización causada por la redundancia de datos.

-- 4.
-- Fila 1:
-- Fertilización con dos insumos.
-- El costo_total representa la suma del costo de los
-- materiales utilizados.
--
-- Fila 4:
-- Labor de riego sin insumos registrados.
-- El costo_total representa el costo completo de la labor.
--
-- Aunque ambas filas tienen un campo llamado costo_total,
-- no significan exactamente lo mismo.
--
-- En una fila es el costo de insumos y en otra es el costo
-- de una actividad. El significado del dato cambia según
-- el registro, lo que genera ambigüedad.

-- 5.
-- Modelo relacional propuesto:
--
-- LABORES
-- -------------------------
-- labor_id (PK)
-- siembra_id (FK)
-- fecha_labor
-- tipo_labor
-- responsable
-- costo_total
--
-- INSUMOS
-- -------------------------
-- insumo_id (PK)
-- nombre
-- unidad_base
--
-- LABOR_INSUMOS
-- -------------------------
-- labor_insumo_id (PK)
-- labor_id (FK)
-- insumo_id (FK)
-- cantidad
-- unidad
-- costo_unitario
--
-- Relaciones:
--
-- SIEMBRAS (1) ------ (N) LABORES
--
-- LABORES (1) ------- (N) LABOR_INSUMOS
--
-- INSUMOS (1) ------- (N) LABOR_INSUMOS
--
-- De esta forma una labor puede utilizar cualquier cantidad
-- de insumos sin necesidad de agregar columnas nuevas y sin
-- perder información.
SELECT * FROM registro_campo_plano;

SELECT finca, COUNT(*) FROM registro_campo_plano GROUP BY finca;

-- ==========================================================
-- PARTE B - CONSTRUCCION
-- ==========================================================

-- ----------------------------------------------------------
-- 1. INSUMOS
-- ----------------------------------------------------------
CREATE TABLE insumos (
    insumo_id INTEGER PRIMARY KEY,
    nombre TEXT NOT NULL UNIQUE,
    tipo TEXT NOT NULL,
    unidad_medida TEXT NOT NULL,
    precio_referencia NUMERIC(10,2),
    descripcion TEXT,
    CHECK (precio_referencia IS NULL OR precio_referencia >= 0)
);

-- ----------------------------------------------------------
-- 2. LABORES
-- ----------------------------------------------------------
CREATE TABLE labores (
    labor_id INTEGER PRIMARY KEY,
    siembra_id INTEGER NOT NULL,
    tipo_labor TEXT NOT NULL,
    fecha_labor DATE NOT NULL,
    responsable TEXT,
    costo_mano_obra NUMERIC(10,2) DEFAULT 0,
    observacion TEXT,
    FOREIGN KEY (siembra_id)
        REFERENCES siembras(siembra_id),
    CHECK (costo_mano_obra >= 0)
);

-- ----------------------------------------------------------
-- 3. LABOR_INSUMO
-- ----------------------------------------------------------
CREATE TABLE labor_insumo (
    labor_id INTEGER NOT NULL,
    insumo_id INTEGER NOT NULL,
    cantidad NUMERIC(10,2) NOT NULL,
    costo_unitario NUMERIC(10,2) NOT NULL,

    PRIMARY KEY (labor_id, insumo_id),

    FOREIGN KEY (labor_id)
        REFERENCES labores(labor_id),

    FOREIGN KEY (insumo_id)
        REFERENCES insumos(insumo_id),

    CHECK (cantidad > 0),
    CHECK (costo_unitario >= 0)
);

-- ----------------------------------------------------------
-- 4. SENSORES
-- ----------------------------------------------------------
CREATE TABLE sensores (
    sensor_id INTEGER PRIMARY KEY,
    lote_id INTEGER NOT NULL,
    tipo TEXT NOT NULL,
    modelo TEXT,
    fecha_instalacion DATE NOT NULL,
    activo INTEGER DEFAULT 1,
    serie TEXT UNIQUE,

    FOREIGN KEY (lote_id)
        REFERENCES lotes(lote_id),

    CHECK (activo IN (0,1))
);


SELECT m.name AS tabla,
       f."from" AS columna,
       f."table" AS apunta_a
FROM sqlite_master m
JOIN pragma_foreign_key_list(m.name) f
WHERE m.type = 'table'
ORDER BY m.name;

-- ==========================================================
-- PARTE C - Migración
-- ==========================================================

-- 1. INSUMOS
INSERT INTO insumos
(insumo_id,nombre,tipo,unidad_medida,precio_referencia)
VALUES
(1,'Urea 46%','fertilizante','kg',0.69),
(2,'Muriato de potasio','fertilizante','kg',0.74),
(3,'Mancozeb','fungicida','kg',5.20),
(4,'Abono organico','fertilizante','kg',0.22),
(5,'Aceite agricola','coadyuvante','L',3.90),
(6,'Semilla INIAP-180','semilla','kg',2.10),

-- insumo extra sin uso
(7,'Cal Dolomitica','enmienda','kg',NULL);

--2. LABORES
INSERT INTO labores VALUES
(1,1,'fertilizacion','2026-03-04','Marta Ruiz',0,NULL),
(2,1,'control fitosanitario','2026-03-19','Marta Ruiz',0,NULL),

(3,2,'fertilizacion','2026-03-06','Jorge Mina',0,NULL),

-- corregido Sta. -> Santa
(4,2,'riego','2026-04-02','Jorge Mina',45,NULL),

(5,3,'poda','2026-03-25','Ana Cedeno',210,NULL),

(6,4,'fertilizacion','2026-03-11','Luis Paez',0,NULL),
(7,4,'control fitosanitario','2026-04-08','Luis Paez',0,NULL),

(8,5,'siembra','2026-02-14','Luis Paez',0,NULL),
(9,5,'fertilizacion','2026-03-02','Rosa Vera',0,NULL),

(10,6,'fertilizacion','2026-03-17','Pedro Loor',0,NULL),

--3. LABOR_INSUMO
INSERT INTO labor_insumo VALUES
(1,1,120,0.68),
(1,2,80,0.74),

(2,3,15,5.20),

(3,1,140,0.68),

(6,1,90,0.68),
(6,4,300,0.22),

(7,3,10,5.20),
(7,5,12,3.90),

(8,6,45,2.10),

(9,1,60,0.70),

(10,2,150,0.74),
(10,4,400,0.22),

(11,3,22,5.20);

SELECT * 
FROM labor_insumo;

-- 4. Sensores
INSERT INTO sensores VALUES
(1,1,'humedad','HM-100','2025-01-10',1,'SN001'),
(2,2,'temperatura','TMP-20','2025-02-15',1,'SN002'),
(3,6,'radiacion',NULL,'2025-03-01',1,'SN003');

SELECT * 
FROM sensores;

--Comprobacion
PRAGMA foreign_key_check;   -- no debe devolver ninguna fila

--Parte D - Verificación y preguntas de negocio
-- D1.
-- ¿Cuántas filas hay en cada una de las cuatro tablas nuevas?

SELECT 'insumos' AS tabla, COUNT(*) AS filas FROM insumos
UNION ALL
SELECT 'labores', COUNT(*) FROM labores
UNION ALL
SELECT 'labor_insumo', COUNT(*) FROM labor_insumo
UNION ALL
SELECT 'sensores', COUNT(*) FROM sensores;

-- D2.
-- ¿El costo calculado desde el modelo relacional coincide
-- con el costo_total original de cada registro?

WITH costo AS (
  SELECT l.labor_id,
         ROUND(
           l.costo_mano_obra +
           COALESCE(SUM(li.cantidad * li.costo_unitario),0),
           2
         ) AS calculado
  FROM labores l
  LEFT JOIN labor_insumo li
         ON li.labor_id = l.labor_id
  GROUP BY l.labor_id, l.costo_mano_obra
)
SELECT p.id,
       p.costo_total AS original,
       c.calculado,
       CASE
         WHEN p.costo_total = c.calculado
         THEN 'OK'
         ELSE 'REVISAR'
       END AS estado
FROM registro_campo_plano p
JOIN costo c
     ON c.labor_id = p.id
ORDER BY p.id;

-- D3.
-- ¿Qué insumo del catálogo nunca fue utilizado
-- en ninguna labor?

SELECT i.*
FROM insumos i
LEFT JOIN labor_insumo li
       ON li.insumo_id = i.insumo_id
WHERE li.insumo_id IS NULL;

-- D4.
-- ¿Cuál es el gasto total en insumos por finca,
-- ordenado de mayor a menor?

SELECT f.nombre AS finca,
       ROUND(SUM(li.cantidad * li.costo_unitario),2) AS gasto_insumos
FROM fincas f
JOIN lotes l
     ON l.finca_id = f.finca_id
JOIN siembras s
     ON s.lote_id = l.lote_id
JOIN labores la
     ON la.siembra_id = s.siembra_id
JOIN labor_insumo li
     ON li.labor_id = la.labor_id
GROUP BY f.finca_id, f.nombre
ORDER BY gasto_insumos DESC;

-- D5.
-- ¿Qué lotes no tienen ningún sensor instalado?

SELECT l.lote_id,
       l.codigo,
       f.nombre AS finca
FROM lotes l
JOIN fincas f
     ON f.finca_id = l.finca_id
LEFT JOIN sensores s
       ON s.lote_id = l.lote_id
WHERE s.sensor_id IS NULL;

-- D6.
-- ¿Cuántos tipos distintos de insumos utiliza cada finca? -- pregunta inventada por mi

SELECT f.nombre AS finca,
       COUNT(DISTINCT li.insumo_id) AS tipos_insumo
FROM fincas f
JOIN lotes l
     ON l.finca_id = f.finca_id
JOIN siembras s
     ON s.lote_id = l.lote_id
JOIN labores la
     ON la.siembra_id = s.siembra_id
JOIN labor_insumo li
     ON li.labor_id = la.labor_id
GROUP BY f.finca_id, f.nombre
ORDER BY tipos_insumo DESC;

--Extra: demostrar con un INSERT que falla que tu modelo impide un dato imposible
-- Este INSERT debe fallar porque costo_unitario no puede ser negativo.
INSERT INTO labor_insumo
VALUES (1,2,10,-5);

-- ==========================================================
-- CIERRE
-- ==========================================================

-- 1.
-- ¿Qué se puede hacer ahora que antes era imposible?
--
-- Ahora es posible registrar una cantidad ilimitada de
-- insumos por labor sin modificar la estructura de la base.
-- También se pueden analizar costos por finca, lote,
-- cultivo o insumo, mantener catálogos independientes y
-- garantizar la integridad de los datos mediante claves
-- foráneas.

-- 2.
-- La tabla plana tenía 17 columnas; tu modelo tiene más
-- tablas y más columnas en total. ¿Por qué eso es una mejora
-- y no un retroceso?
--
-- Es una mejora porque la información ya no está repetida.
-- Cada dato se guarda una sola vez y se relaciona mediante
-- claves. Esto reduce errores de escritura, evita
-- inconsistencias, facilita las actualizaciones y hace que
-- la base sea escalable. Aunque existen más tablas, cada una
-- tiene una responsabilidad clara y los datos están
-- normalizados.

-- 3.
-- Una pregunta que tu modelo todavía no puede responder,
-- y qué habría que agregarle.
--
-- No es posible responder cuál fue el rendimiento obtenido
-- en cada cosecha (kg por hectárea o toneladas producidas),
-- porque el modelo no almacena información de producción.
--
-- Para responder esa pregunta habría que agregar una tabla
-- de cosechas con datos como fecha de cosecha, cantidad
-- recolectada, calidad del producto y precio de venta.
