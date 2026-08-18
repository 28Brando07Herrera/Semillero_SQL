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

-- =====================================================================
--PARTE A: DIAGNOSTICO
-- =====================================================================

-- A1. Labores cuya fecha no esta en formato ISO AAAA-MM-DD
SELECT labor_id, siembra_id, tipo_labor, fecha, responsable
FROM labores
WHERE fecha NOT LIKE '____-__-__';


-- A2. Labores donde el responsable es el texto 'NULL'
SELECT labor_id, siembra_id, tipo_labor, fecha, responsable
FROM labores
WHERE responsable = 'NULL';

-- SELECT COUNT(*) FROM labores WHERE responsable IS NULL;
-- Explicacion: El conteo devuelve 0 (o no incluye esta fila) porque el operador 'IS NULL' 
-- busca un valor ausente o desconocido (NULL real), mientras que la fila contiene la 
-- cadena de texto literal 'NULL', la cual cuenta como un texto valido de 4 caracteres.


-- A3. Labores cargadas dos veces (duplicadas)
SELECT siembra_id, tipo_labor, fecha, responsable, 
       GROUP_CONCAT(labor_id) AS labor_ids, 
       COUNT(*) AS repeticiones
FROM labores
GROUP BY siembra_id, tipo_labor, fecha, responsable
HAVING COUNT(*) > 1;


-- A4. Insumos duplicados en el catalogo
SELECT LOWER(REPLACE(nombre, ' ', '')) AS nombre_normalizado, 
       GROUP_CONCAT(insumo_id) AS insumo_ids, 
       GROUP_CONCAT(nombre) AS nombres_originales,
       COUNT(*) AS repeticiones
FROM insumos
GROUP BY LOWER(REPLACE(nombre, ' ', ''))
HAVING COUNT(*) > 1;


-- A5. Labores con jornal sin cargar
SELECT labor_id, siembra_id, tipo_labor, fecha, costo_mano_obra, observacion
FROM labores
WHERE costo_mano_obra = 0 
  AND observacion LIKE '%pendiente%';


-- A6. Demostración de la gravedad de la fecha rota

SELECT labor_id, fecha FROM labores ORDER BY fecha LIMIT 3;
-- Explicacion: SQL ordena las fechas no ISO como cadenas de texto alfabeticas. 
-- La fecha '15/04/2026' comienza con '1', por lo que aparece primera en el ORDER BY,
-- antes que las fechas de marzo o abril en formato ISO ('2024-...', '2026-...').

SELECT labor_id, strftime('%m', fecha) FROM labores WHERE labor_id = 17;
-- Explicacion: Devuelve NULL porque las funciones de fecha de SQLite (como strftime) 
-- requieren estrictamente el formato ISO 'AAAA-MM-DD'. Al recibir '15/04/2026', 
-- no puede interpretarla y falla silenciosamente retornando NULL.
-- 
-- 
-- =====================================================================
-- PARTE B: ARREGLOS SIMPLES
-- =====================================================================

BEGIN TRANSACTION;

-- B1. Pasá la fecha rota a formato ISO
-- SELECT COUNT(*) FROM labores WHERE labor_id = 17 AND fecha = '15/04/2026';
-- Conteo previo: 1
UPDATE labores
SET fecha = '2026-04-15'
WHERE labor_id = 17;


-- B2. Convertí el 'NULL' de texto en un NULL de verdad
-- SELECT COUNT(*) FROM labores WHERE responsable = 'NULL';
-- Conteo previo: 1
UPDATE labores
SET responsable = NULL
WHERE responsable = 'NULL';


-- B3. Cargá el jornal pendiente y actualizá la observación
-- SELECT COUNT(*) FROM labores WHERE labor_id = 19;
-- Conteo previo: 1
UPDATE labores
SET costo_mano_obra = 145.00,
    observacion = 'Jornal regularizado post-carga (antes pendiente)'
WHERE labor_id = 19;

COMMIT;


-- =====================================================================
-- VERIFICACION (Las 3 consultas deben devolver 0 filas)
-- =====================================================================

-- Verificacion B1 (A1 original)
SELECT labor_id, siembra_id, tipo_labor, fecha, responsable
FROM labores
WHERE fecha NOT LIKE '____-__-__';

-- Verificacion B2 (A2 original)
SELECT labor_id, siembra_id, tipo_labor, fecha, responsable
FROM labores
WHERE responsable = 'NULL';

-- Verificacion B3 (A5 original)
SELECT labor_id, siembra_id, tipo_labor, fecha, costo_mano_obra, observacion
FROM labores
WHERE costo_mano_obra = 0 
  AND observacion LIKE '%pendiente%';
  
  
-- =====================================================================
-- PARTE C: LA LABOR DUPLICADA Y EL CASCADE
-- =====================================================================

-- C1. Conteo previo en labor_insumo para la labor duplicada (labor_id = 16)
SELECT COUNT(*) FROM labor_insumo WHERE labor_id = 16;


-- C2. Borrado de la copia duplicada (la del ID mayor) dentro de una transaccion
-- SELECT COUNT(*) FROM labores WHERE labor_id = 16;
-- Conteo previo: 1

BEGIN TRANSACTION;

DELETE FROM labores
WHERE labor_id = 16;

COMMIT;


-- C3. Re-conteo en labor_insumo tras la eliminacion
SELECT COUNT(*) FROM labor_insumo WHERE labor_id = 16;

-- Explicacion: El conteo cambio a 0 porque la tabla 'labor_insumo' tiene definida 
-- una clave foranea hacia 'labores' con la clausula 'ON DELETE CASCADE'. Al borrar 
-- la labor padre (labor_id = 16), SQLite elimina automaticamente todas sus filas asociadas.


-- C4. Linea del script inicial que provoco este comportamiento:
-- labor_id INTEGER NOT NULL REFERENCES labores(labor_id) ON DELETE CASCADE,


-- =====================================================================
-- PARTE D: FUSIONAR INSUMOS DUPLICADOS
-- =====================================================================

-- D1. Intento fallido
-- UPDATE labor_insumo SET insumo_id = 1 WHERE insumo_id = 8;
-- Error: UNIQUE constraint failed: labor_insumo.labor_id, labor_insumo.insumo_id
-- Falla porque la labor 20 ya tiene el insumo 1; al cambiar el 8 por 1, duplicaria la PK (20, 1).


-- D2 y D3. Fusion correcta
BEGIN TRANSACTION;

-- 1. Sumar cantidad del duplicado en la labor 20 (60 + 40 = 100 kg)
-- SELECT COUNT(*) FROM labor_insumo WHERE labor_id = 20 AND insumo_id = 1; -- Conteo: 1
UPDATE labor_insumo
SET cantidad = cantidad + 40
WHERE labor_id = 20 AND insumo_id = 1;

-- 2. Borrar la fila duplicada ya sumada
-- SELECT COUNT(*) FROM labor_insumo WHERE labor_id = 20 AND insumo_id = 8; -- Conteo: 1
DELETE FROM labor_insumo
WHERE labor_id = 20 AND insumo_id = 8;

-- 3. Reapuntar insumos sin conflicto
-- SELECT COUNT(*) FROM labor_insumo WHERE insumo_id = 8; -- Conteo: 1
UPDATE labor_insumo SET insumo_id = 1 WHERE insumo_id = 8;

-- SELECT COUNT(*) FROM labor_insumo WHERE insumo_id = 9; -- Conteo: 1
UPDATE labor_insumo SET insumo_id = 3 WHERE insumo_id = 9;

-- 4. Borrar duplicados del catalogo
-- SELECT COUNT(*) FROM insumos WHERE insumo_id IN (8, 9); -- Conteo: 2
DELETE FROM insumos WHERE insumo_id IN (8, 9);

COMMIT;


-- D4. Comprobacion
SELECT * FROM labor_insumo WHERE labor_id = 20;

-- Control general de la base limpia
SELECT 'fincas' AS tabla, COUNT(*) AS filas FROM fincas
UNION ALL SELECT 'cultivos', COUNT(*) FROM cultivos
UNION ALL SELECT 'lotes',    COUNT(*) FROM lotes
UNION ALL SELECT 'siembras', COUNT(*) FROM siembras
UNION ALL SELECT 'insumos',  COUNT(*) FROM insumos
UNION ALL SELECT 'labores',  COUNT(*) FROM labores
UNION ALL SELECT 'labor_insumo', COUNT(*) FROM labor_insumo
UNION ALL SELECT 'sensores', COUNT(*) FROM sensores;

-- =====================================================================
-- PARTE E: VERIFICACION Y DEMOS
-- =====================================================================

-- E1. Conteo final de insumos, labores y labor_insumo
SELECT 
    (SELECT COUNT(*) FROM insumos) AS insumos,
    (SELECT COUNT(*) FROM labores) AS labores,
    (SELECT COUNT(*) FROM labor_insumo) AS labor_insumo;


-- E2. Verificacion de claves foraneas huerfanas (debe devolver 0 filas)
PRAGMA foreign_key_check;


-- E3. Demostracion de proteccion RESTRICT
-- DELETE FROM insumos WHERE insumo_id = 1;
-- Error devuelto por SQLite:
-- Runtime error: FOREIGN KEY constraint failed (19)
-- Explicacion: ON DELETE RESTRICT impide borrar 'Urea 46%' porque existen registros 
-- en 'labor_insumo' que referencian a esta clave primaria.


-- E4. El experimento del susto
BEGIN TRANSACTION;
  UPDATE labores SET responsable = 'Pedro Loor';   -- sin WHERE
  SELECT COUNT(*) FROM labores WHERE responsable = 'Pedro Loor'; -- Primer numero: 19
ROLLBACK;

SELECT COUNT(*) FROM labores WHERE responsable = 'Pedro Loor';   -- Segundo numero: 4

-- Explicacion:
-- El primer conteo da 19 porque el UPDATE sin WHERE sobreescribio toda la tabla.
-- El segundo conteo vuelve a 4 gracias al ROLLBACK que deshizo la transaccion.
-- Sin el BEGIN...ROLLBACK, se habrian sobrescrito permanentemente los responsables 
-- de todas las labores de la base de datos sin posibilidad de recuperacion.

-- =====================================================================
-- CIERRE: RESPUESTAS REFLEXIVAS
-- =====================================================================

-- 1. ¿Cuál habría sido el problema más caro en 6 meses?
-- El insumo duplicado (Urea id 1 y id 8).
-- Al tener el stock y los costos divididos en dos registros distintos,
-- los reportes de costos por lote darían un valor falso y las compras
-- de insumos se calcularían mal, provocando sobrecompra o desabastecimiento.


-- 2. ¿Qué restricción impediría que entren ureas duplicadas en la tabla?
-- Un índice único funcional o restricción sobre el texto normalizado:
-- CREATE UNIQUE INDEX idx_insumos_nombre_limpio ON insumos (LOWER(REPLACE(nombre, ' ', '')));
-- Esto obliga a la base de datos a comparar los nombres sin espacios y en
-- minúsculas, rechazando variantes como 'Urea 46 %' o 'UREA 46%'.


-- 3. ¿Qué tendría que haber hecho distinto el pasante al cargar?
-- Usar transacciones para probar la carga antes de aplicarla definitivamente,
-- validar los nombres contra el catálogo existente antes de crear insumos nuevos,
-- y asegurarse de usar fechas en formato ISO (AAAA-MM-DD).

-- =====================================================================
-- EXTRA (+5 PTS): PROBLEMA DE CALIDAD NO SOLICITADO
-- Inconsistencia cronologica: labores registradas antes de la fecha de siembra
-- =====================================================================

SELECT l.labor_id, l.siembra_id, l.tipo_labor, l.fecha AS fecha_labor, s.fecha_siembra
FROM labores l
JOIN siembras s ON l.siembra_id = s.siembra_id
WHERE l.fecha < s.fecha_siembra;

-- Explicacion: Encuentra labores con fechas anteriores a la fecha oficial en la que 
-- se realizo la siembra. Esto representa una incoherencia de datos de negocio 
-- (no se puede fertilizar o regar un cultivo que no ha sido sembrado aun).