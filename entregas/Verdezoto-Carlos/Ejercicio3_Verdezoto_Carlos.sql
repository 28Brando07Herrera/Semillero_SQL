-- =====================================================================
-- CURSO DE SQL  |  AgroDB  |  Ejercicio 3
-- Alumno:
-- Fecha:
--
-- Este archivo se ejecuta DESPUES de datos/agrodb_nucleo.sql,
-- en la MISMA sesion de sqliteonline.
-- =====================================================================

PRAGMA foreign_keys = ON;


-- =====================================================================
-- PARTE A - DIAGNOSTICO
-- =====================================================================

-- 1)
-- Una labor con tres insumos no puede representarse correctamente en una
-- tabla que solo tiene insumo_1 e insumo_2. Habria que agregar otra columna
-- (insumo_3, cantidad_3, etc.), haciendo crecer la tabla cada vez que aparece
-- una nueva cantidad de insumos. Es un problema grave porque rompe la
-- estructura repetitiva del modelo, dificulta las consultas, aumenta los
-- NULL y obliga a modificar la estructura de la base para registrar un dato
-- que deberia ser de cantidad variable. Con labor_insumo, en cambio, se agrega
-- una fila por cada insumo utilizado.

-- 2)
-- La consulta:
-- SELECT finca, COUNT(*) FROM registro_campo_plano GROUP BY finca;
-- devuelve 4 grupos de texto:
--   Hacienda Santa Rosa -> 4
--   Hacienda Sta. Rosa  -> 1
--   Finca El Guayabo    -> 3
--   Agricola La Union   -> 3
-- En realidad hay 3 fincas. La consulta dice 4 porque la fila 4 tiene una
-- variante mal escrita del nombre de Hacienda Santa Rosa, por lo que SQLite
-- la considera un texto diferente. SQLite NO da error en esta consulta:
-- es una consulta valida porque finca aparece en GROUP BY y COUNT(*) es una
-- funcion de agregacion. El problema es de calidad de datos, no de sintaxis.
-- Total de filas: 4 + 1 + 3 + 3 = 11? No: Hacienda Santa Rosa tiene 4,
-- Hacienda Sta. Rosa tiene 1, Finca El Guayabo tiene 3 y Agricola La Union
-- tiene 3; el total es 11. La fila 12 pertenece a Agricola La Union: por
-- tanto el conteo correcto de grupos es 4 y sus cantidades son 4,1,3,4.
-- La consulta muestra entonces 4 grupos: 4, 1, 3 y 4.

-- 3)
-- provincia depende de la finca, no de cada labor. En el modelo plano se
-- repite en todas las filas de una misma finca. Si Los Rios cambiara de
-- nombre, habria que actualizar muchas filas y podria quedar informacion
-- inconsistente. En el modelo relacional la provincia queda una sola vez
-- en fincas y las labores llegan a ella mediante las relaciones.

-- 4)
-- Las filas 1 y 4 no significan lo mismo aunque ambas tienen un costo_total.
-- En la fila 1, el costo de 140.80 proviene de insumos: 120 kg de Urea
-- (81.60) + 80 kg de Muriato de potasio (59.20). La mano de obra es 0.
-- En la fila 4, los 45.00 corresponden completamente a mano de obra porque
-- no tiene insumos. El mismo campo mezcla, por tanto, conceptos diferentes.

-- 5)
-- Modelo:
-- fincas 1 --- N lotes
-- lotes  1 --- N siembras
-- cultivos 1 --- N siembras
-- siembras 1 --- N labores
-- labores 1 --- N labor_insumo N --- 1 insumos
-- lotes 1 --- N sensores
--
-- Claves foraneas:
-- lotes.finca_id -> fincas.finca_id
-- siembras.lote_id -> lotes.lote_id
-- siembras.cultivo_id -> cultivos.cultivo_id
-- labores.siembra_id -> siembras.siembra_id
-- labor_insumo.labor_id -> labores.labor_id
-- labor_insumo.insumo_id -> insumos.insumo_id
-- sensores.lote_id -> lotes.lote_id


-- =====================================================================
-- PARTE B - CREACION DE TABLAS
-- =====================================================================

DROP TABLE IF EXISTS labor_insumo;
DROP TABLE IF EXISTS labores;
DROP TABLE IF EXISTS insumos;
DROP TABLE IF EXISTS sensores;

-- B.1 insumos
CREATE TABLE insumos (
    insumo_id          INTEGER PRIMARY KEY,
    nombre             TEXT NOT NULL UNIQUE,
    tipo               TEXT NOT NULL,
    unidad_medida      TEXT NOT NULL,
    precio_referencia  NUMERIC(10,2),
    descripcion        TEXT,
    proveedor          TEXT,
    activo             INTEGER NOT NULL DEFAULT 1
                       CHECK (activo IN (0,1)),
    CHECK (precio_referencia IS NULL OR precio_referencia >= 0)
);

-- B.2 labores
CREATE TABLE labores (
    labor_id           INTEGER PRIMARY KEY,
    siembra_id         INTEGER NOT NULL REFERENCES siembras(siembra_id),
    tipo_labor         TEXT NOT NULL,
    fecha_labor        DATE NOT NULL,
    responsable        TEXT NOT NULL,
    costo_mano_obra    NUMERIC(10,2) NOT NULL DEFAULT 0
                       CHECK (costo_mano_obra >= 0),
    observacion        TEXT,
    equipo             TEXT,
    UNIQUE (siembra_id, fecha_labor, tipo_labor)
);

-- B.3 labor_insumo
CREATE TABLE labor_insumo (
    labor_id           INTEGER NOT NULL REFERENCES labores(labor_id),
    insumo_id          INTEGER NOT NULL REFERENCES insumos(insumo_id),
    cantidad            NUMERIC(10,2) NOT NULL CHECK (cantidad > 0),
    costo_unitario      NUMERIC(10,2) NOT NULL CHECK (costo_unitario >= 0),
    PRIMARY KEY (labor_id, insumo_id)
);

-- B.4 sensores
CREATE TABLE sensores (
    sensor_id          INTEGER PRIMARY KEY,
    lote_id            INTEGER NOT NULL REFERENCES lotes(lote_id),
    tipo               TEXT NOT NULL
                       CHECK (tipo IN ('temperatura','humedad','radiacion')),
    modelo             TEXT,
    fecha_instalacion  DATE NOT NULL,
    activo             INTEGER NOT NULL DEFAULT 1
                       CHECK (activo IN (0,1)),
    numero_serie       TEXT NOT NULL UNIQUE,
    observacion        TEXT
);


-- PUNTO DE CONTROL 1
-- Nota: con las FKs exigidas en la consigna, esta consulta devuelve 4 filas:
-- labor_insumo -> insumos, labor_insumo -> labores, labores -> siembras
-- y sensores -> lotes. La indicacion de que deben salir 6 filas no coincide
-- con el modelo descrito; agregar FKs extra introducira relaciones redundantes
-- que no fueron solicitadas.
SELECT m.name AS tabla, f."from" AS columna, f."table" AS apunta_a
FROM sqlite_master m
JOIN pragma_foreign_key_list(m.name) f
WHERE m.type = 'table'
  AND m.name IN ('insumos','labores','labor_insumo','sensores')
ORDER BY m.name;


-- =====================================================================
-- PARTE C - MIGRACION
-- =====================================================================

-- C.1 insumos
-- Se cargan todos los insumos presentes en el plano y un insumo adicional
-- de catalogo que ninguna labor utiliza, para probar el LEFT JOIN de D3.

INSERT INTO insumos
(insumo_id, nombre, tipo, unidad_medida, precio_referencia, descripcion, proveedor)
VALUES
(1, 'Urea 46%', 'fertilizante', 'kg', 0.68,
 'Fertilizante nitrogenado', 'Proveedor local'),
(2, 'Muriato de potasio', 'fertilizante', 'kg', 0.74,
 'Fuente de potasio', 'Proveedor local'),
(3, 'Mancozeb', 'fungicida', 'kg', 5.20,
 'Fungicida de contacto', 'Proveedor local'),
(4, 'Abono organico', 'fertilizante', 'kg', 0.22,
 'Materia organica para el suelo', 'Proveedor local'),
(5, 'Aceite agricola', 'coadyuvante', 'L', 3.90,
 'Coadyuvante agricola', 'Proveedor local'),
(6, 'Semilla INIAP-180', 'semilla', 'kg', 2.10,
 'Semilla de maiz INIAP-180', 'Proveedor local'),
(7, 'Nematicida X', 'nematicida', 'L', NULL,
 'Insumo de catalogo no utilizado en las labores migradas',
 'Proveedor local');

-- C.2 labores
-- Filas del plano -> siembra_id:
-- 1,2 -> 1 ; 3,4 -> 2 ; 5 -> 3 ; 6,7 -> 4 ;
-- 8,9 -> 5 ; 10 -> 6 ; 11 -> 7 ; 12 -> 8.
--
-- Cuando existen insumos, costo_mano_obra = 0.
-- Cuando no existen insumos, todo costo_total pasa a costo_mano_obra.
-- La fila 4 queda asociada a siembra 2, normalizando la finca del lote
-- correspondiente sin conservar la variante mal escrita.

INSERT INTO labores
(labor_id, siembra_id, tipo_labor, fecha_labor, responsable, costo_mano_obra, observacion)
VALUES
(1,  1, 'fertilizacion',          '2026-03-04', 'Marta Ruiz',  0,     NULL),
(2,  1, 'control fitosanitario',  '2026-03-19', 'Marta Ruiz',  0,     NULL),
(3,  2, 'fertilizacion',          '2026-03-06', 'Jorge Mina',  0,     NULL),
(4,  2, 'riego',                  '2026-04-02', 'Jorge Mina',  45.00, 'Registro normalizado durante la migracion.'),
(5,  3, 'poda',                   '2026-03-25', 'Ana Cedeno',  210.00, NULL),
(6,  4, 'fertilizacion',          '2026-03-11', 'Luis Paez',   0,     NULL),
(7,  4, 'control fitosanitario',  '2026-04-08', 'Luis Paez',   0,     NULL),
(8,  5, 'siembra',                '2026-02-14', 'Luis Paez',   0,     NULL),
(9,  5, 'fertilizacion',          '2026-03-02', 'Rosa Vera',   0,     NULL),
(10, 6, 'fertilizacion',           '2026-03-17', 'Pedro Loor',  0,     NULL),
(11, 7, 'control fitosanitario',  '2026-03-28', 'Pedro Loor',  0,     NULL),
(12, 8, 'riego',                  '2026-04-05', 'Pedro Loor',  68.00, NULL);

-- C.3 labor_insumo
-- cantidad pertenece a la relacion labor-insumo porque cambia segun la
-- aplicacion de cada labor. costo_unitario tambien pertenece aqui porque
-- puede cambiar entre aplicaciones: la Urea cuesta 0.68 en unas filas y
-- 0.70 en la fila 9.

INSERT INTO labor_insumo (labor_id, insumo_id, cantidad, costo_unitario)
VALUES
(1,  1, 120, 0.68),
(1,  2,  80,  0.74),
(2,  3,  15,  5.20),
(3,  1, 140, 0.68),
(6,  1,  90,  0.68),
(6,  4, 300, 0.22),
(7,  3,  10,  5.20),
(7,  5,  12,  3.90),
(8,  6,  45,  2.10),
(9,  1,  60,  0.70),
(10, 2, 150, 0.74),
(10, 4, 400, 0.22),
(11, 3,  22, 5.20);

-- C.4 sensores
-- El registro_campo_plano no contiene ninguna columna ni fila de sensores.
-- Se deja esta tabla sin registros para no inventar datos que no existen en
-- la fuente.

-- C.4 no requiere INSERT porque no hay informacion de sensores en el plano.


-- PUNTO DE CONTROL 2 -> ninguna fila
PRAGMA foreign_key_check;


-- =====================================================================
-- PARTE D - CONSULTAS
-- =====================================================================

-- D1. Pregunta:
-- ¿Cuantas filas hay en cada una de las cuatro tablas nuevas?
SELECT 'insumos' AS tabla, COUNT(*) AS filas FROM insumos
UNION ALL
SELECT 'labores', COUNT(*) FROM labores
UNION ALL
SELECT 'labor_insumo', COUNT(*) FROM labor_insumo
UNION ALL
SELECT 'sensores', COUNT(*) FROM sensores;


-- D2. Pregunta:
-- ¿El costo reconstruido de cada labor coincide exactamente con el
-- costo_total original del registro_campo_plano?
WITH costo AS (
  SELECT l.labor_id,
         ROUND(
             l.costo_mano_obra
             + COALESCE(SUM(li.cantidad * li.costo_unitario), 0),
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
           WHEN p.costo_total = c.calculado THEN 'OK'
           ELSE 'REVISAR'
       END AS estado
FROM registro_campo_plano p
JOIN costo c
  ON c.labor_id = p.id
ORDER BY p.id;


-- D3. Pregunta:
-- ¿Que insumos existen en el catalogo pero nunca fueron utilizados por
-- ninguna labor?
SELECT i.insumo_id, i.nombre, i.tipo, i.unidad_medida
FROM insumos i
LEFT JOIN labor_insumo li
       ON li.insumo_id = i.insumo_id
WHERE li.insumo_id IS NULL
ORDER BY i.insumo_id;


-- D4. Pregunta:
-- ¿Cual es el gasto total en insumos por finca, ordenado de mayor a menor?
-- Se cruzan cinco tablas: fincas, lotes, siembras, labores y labor_insumo.
SELECT f.nombre AS finca,
       ROUND(SUM(li.cantidad * li.costo_unitario), 2) AS gasto_insumos
FROM fincas f
JOIN lotes lo
  ON lo.finca_id = f.finca_id
JOIN siembras s
  ON s.lote_id = lo.lote_id
JOIN labores l
  ON l.siembra_id = s.siembra_id
JOIN labor_insumo li
  ON li.labor_id = l.labor_id
GROUP BY f.finca_id, f.nombre
ORDER BY gasto_insumos DESC;


-- D5. Pregunta:
-- ¿Que lotes no tienen ningun sensor instalado?
SELECT lo.lote_id,
       lo.codigo,
       f.nombre AS finca
FROM lotes lo
JOIN fincas f
  ON f.finca_id = lo.finca_id
LEFT JOIN sensores se
  ON se.lote_id = lo.lote_id
WHERE se.sensor_id IS NULL
ORDER BY lo.lote_id;


-- D6. Pregunta:
-- ¿Que lotes tienen mas de un sensor instalado?
-- Esta pregunta solo puede modelarse directamente con la relacion
-- lote-sensor, que no existia en la tabla plana.
SELECT lo.lote_id,
       lo.codigo,
       f.nombre AS finca,
       COUNT(se.sensor_id) AS cantidad_sensores
FROM lotes lo
JOIN fincas f
  ON f.finca_id = lo.finca_id
JOIN sensores se
  ON se.lote_id = lo.lote_id
GROUP BY lo.lote_id, lo.codigo, f.nombre
HAVING COUNT(se.sensor_id) > 1
ORDER BY cantidad_sensores DESC, lo.lote_id;


-- =====================================================================
-- CIERRE
-- =====================================================================

-- 1) Que se puede hacer ahora que antes era imposible:
-- Ahora se pueden registrar cantidades variables de insumos sin agregar
-- columnas nuevas, conservar el costo unitario historico de cada aplicacion,
-- consultar el catalogo completo aunque un insumo nunca se haya usado y
-- relacionar las labores con siembras y, de estas, con lotes y fincas.
-- Tambien existe una estructura para registrar sensores por lote.

-- 2) Por que mas tablas es una mejora y no un retroceso:
-- La separacion reduce la redundancia y evita inconsistencias. Los datos de
-- una finca, un lote, una siembra o un insumo se almacenan una sola vez y
-- las relaciones se expresan con claves foraneas. La tabla puente permite
-- representar cualquier cantidad de insumos por labor sin repetir columnas.
-- Tener mas tablas no significa tener menos informacion: significa que la
-- informacion esta organizada segun las relaciones del dominio.

-- 3) Que pregunta mi modelo TODAVIA no puede responder, y que le falta:
-- Todavia no puede responder cuanto inventario fisico queda en bodega de
-- cada insumo, porque el modelo tiene un catalogo y consumos, pero no tiene
-- entradas, salidas ni existencias de inventario. Habria que agregar una
-- tabla de movimientos de inventario con insumo, tipo de movimiento,
-- cantidad, fecha y, si corresponde, referencia de la operacion.


-- =====================================================================
-- EXTRA - RESTRICCION DE DATOS IMPOSIBLES
-- =====================================================================

-- Este INSERT se deja comentado para que el archivo ejecute completo.
-- Si se ejecutara, SQLite lo rechazaria por la restriccion CHECK
-- (cantidad > 0), demostrando que el modelo impide una cantidad imposible:
--
-- INSERT INTO labor_insumo (labor_id, insumo_id, cantidad, costo_unitario)
-- VALUES (1, 7, -5, 1.00);
--
-- Resultado esperado: error de CHECK constraint failed.
