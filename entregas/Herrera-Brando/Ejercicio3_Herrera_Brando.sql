-- =====================================================================
-- CURSO DE SQL  |  CLASE 3  |  EJERCICIO PRACTICO 3
-- Arreglar el registro de campo
-- Nombre: Brando Herrera
-- =====================================================================
-- NOTA: antes de correr este archivo, pegar y ejecutar agrodb_nucleo.sql
-- completo. Debe dar 3, 6, 8, 10 y 12 en la verificacion.
-- =====================================================================


-- =====================================================================
-- PARTE A - DIAGNOSTICO
-- =====================================================================

-- SELECT * FROM registro_campo_plano;

-- 1) Llega una labor con TRES insumos. Que hay que hacer, y por que es
--    grave y no una molestia:
--    Con el diseno actual (insumo_1/cantidad_1/... insumo_2/cantidad_2/...)
--    no hay una tercera columna insumo_3 para escribir el tercer insumo, asi
--    que la unica forma de meterlo es agregar mas columnas a la tabla
--    (insumo_3, cantidad_3, unidad_3, costo_unit_3), y repetir eso otra vez
--    si llega una labor con cuatro. No es una molestia porque el limite de
--    "cuantos insumos puede llevar una labor" quedo escrito en el DISENO de
--    la tabla, no en los datos: cada vez que la realidad supera ese limite
--    hay que alterar la estructura de la base, no solo agregar una fila.
--    Ademas, para las labores con 1 solo insumo, las columnas del insumo 2
--    (o del 3, si se agregara) quedarian en NULL, desperdiciando espacio y
--    obligando a todas las consultas a revisar "insumo_2 IS NULL" antes de
--    usarlo.

-- 2) SELECT finca, COUNT(*) FROM registro_campo_plano GROUP BY finca;
--    Fincas reales: 3 (Hacienda Santa Rosa, Finca El Guayabo, Agricola La
--    Union — las mismas 3 que existen en la tabla fincas del nucleo).
--    La consulta devuelve 4 grupos porque la fila 4 tiene el nombre escrito
--    "Hacienda Sta. Rosa" en vez de "Hacienda Santa Rosa": para SQL son dos
--    textos distintos, aunque para nosotros sea evidentemente la misma
--    finca, asi que GROUP BY los separa en dos grupos.
--    OJO con la pregunta del error: SQLite NO tira ningun error. La
--    consulta corre perfecto y devuelve 4 filas sin quejarse. Ese es
--    justamente el problema real: un dato mal escrito no rompe nada a la
--    vista, solo da un resultado incorrecto en silencio. Si esto fuera un
--    reporte para el dueno de la finca, dira "tengo 4 fincas" sin que nadie
--    se de cuenta del error.

-- 3) La columna provincia, de que depende?
--    No depende de la fila (de la labor), depende de la finca: toda fila
--    de "Hacienda Santa Rosa" tiene "Los Rios", siempre. Es una dependencia
--    transitiva (provincia depende de finca, y finca ya identifica la fila),
--    exactamente el tipo de redundancia que la normalizacion elimina. Si
--    "Los Rios" cambiara de nombre, en la tabla plana habria que corregirlo
--    en cada una de las filas de esa finca (en este caso, 5 filas) y correr
--    el riesgo de dejar alguna sin actualizar. En el modelo relacional, la
--    provincia vive una sola vez en fincas.provincia, y se corrige ahi.

-- 4) Costo_total de las filas 1 y 4, significan lo mismo?
--    Fila 1 = 140.80 y es 100% costo de insumos (120kg de Urea + 80kg de
--    Muriato de potasio); la mano de obra de esa labor vale 0 en el dato
--    original. Fila 4 = 45.00 y es 100% mano de obra (riego, sin insumos).
--    Numericamente ambos son "costo_total", pero conceptualmente miden
--    cosas distintas: en una fila es "cuanto material se aplico" y en la
--    otra es "cuanto costo la mano de obra". La columna unica costo_total
--    mezcla dos conceptos que en el modelo nuevo separamos en
--    labores.costo_mano_obra y en la suma de labor_insumo.

-- 5) Modelo a construir (diagrama en palabras):
--    insumos (catalogo) <--- labor_insumo ---> labores (evento) ---> siembras (nucleo)
--                                                                        |
--    lotes (nucleo) <--- sensores                                    (ya existe)
--
--    - labores.siembra_id       -> siembras.siembra_id
--    - labor_insumo.labor_id    -> labores.labor_id
--    - labor_insumo.insumo_id   -> insumos.insumo_id
--    - sensores.lote_id         -> lotes.lote_id
--    Las 4 claves foraneas van siempre del lado "muchos": muchas labores
--    por siembra, muchas filas de labor_insumo por labor y por insumo, y
--    muchos sensores por lote.


-- =====================================================================
-- PARTE B - CONSTRUCCION
-- =====================================================================

-- insumos - el catalogo
CREATE TABLE insumos (
    insumo_id         INTEGER PRIMARY KEY,
    nombre            TEXT NOT NULL UNIQUE,
    tipo              TEXT NOT NULL CHECK (tipo IN ('fertilizante','fungicida','semilla','coadyuvante')),
    unidad_medida     TEXT NOT NULL,
    precio_referencia NUMERIC(10,2)                 -- admite NULL: insumo
                                                      -- nuevo aun sin cotizar
);

-- labores - el evento
CREATE TABLE labores (
    labor_id         INTEGER PRIMARY KEY,
    siembra_id       INTEGER NOT NULL REFERENCES siembras(siembra_id),
    tipo_labor       TEXT NOT NULL,
    fecha            DATE NOT NULL,
    responsable      TEXT NOT NULL,
    costo_mano_obra  NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (costo_mano_obra >= 0),
    observacion      TEXT                            -- admite NULL: no toda
                                                      -- labor necesita una nota
);

-- labor_insumo - la tabla puente
-- por que "cantidad" no puede vivir en labores ni en insumos: cantidad es
-- un dato de la COMBINACION labor+insumo (cuanta Urea llevo ESTA labor),
-- no de la labor sola (una labor puede llevar varios insumos, cada uno con
-- su propia cantidad) ni del insumo solo (la Urea no tiene una "cantidad"
-- fija, cada aplicacion usa una distinta).
-- por que "costo_unitario" va aca y no solo en el catalogo: el precio de un
-- mismo insumo cambia en el tiempo. La Urea 46% cuesta 0.68 en las filas 1,
-- 3 y 6 del plano, pero 0.70 en la fila 9 (probablemente subio el precio
-- entre esas fechas). Si el costo viviera solo en insumos, se perderia el
-- precio real que se pago ese dia; guardarlo en labor_insumo conserva el
-- precio historico de cada aplicacion, y precio_referencia en insumos
-- queda solo como una referencia general, no como la verdad de cada compra.
CREATE TABLE labor_insumo (
    labor_id       INTEGER NOT NULL REFERENCES labores(labor_id),
    insumo_id      INTEGER NOT NULL REFERENCES insumos(insumo_id),
    cantidad       NUMERIC(10,2) NOT NULL CHECK (cantidad > 0),
    costo_unitario NUMERIC(10,2) NOT NULL CHECK (costo_unitario >= 0),
    PRIMARY KEY (labor_id, insumo_id)
);

-- sensores
CREATE TABLE sensores (
    sensor_id          INTEGER PRIMARY KEY,
    lote_id            INTEGER NOT NULL REFERENCES lotes(lote_id),
    tipo               TEXT NOT NULL CHECK (tipo IN ('temperatura','humedad','radiacion')),
    modelo             TEXT,                          -- admite NULL: no todos
                                                       -- los sensores tienen
                                                       -- modelo registrado
    fecha_instalacion  DATE NOT NULL,
    activo             INTEGER NOT NULL DEFAULT 1 CHECK (activo IN (0,1))
);

-- Punto de control 1
SELECT m.name AS tabla, f."from" AS columna, f."table" AS apunta_a
FROM sqlite_master m
JOIN pragma_foreign_key_list(m.name) f
WHERE m.type = 'table'
  AND m.name IN ('insumos','labores','labor_insumo','sensores')
ORDER BY m.name;
-- NOTA: con las 4 tablas construidas tal como las describe cada seccion de
-- la guia (labores -> siembras; labor_insumo -> labores e -> insumos;
-- sensores -> lotes) esta consulta da 4 filas, no 6. Revise el diseno mas
-- de una vez y no encontre una quinta o sexta relacion que la guia pida en
-- algun lado; esto lo marco como DUDA en vez de forzar una FK que no tiene
-- justificacion en el enunciado.
-- DUDA: el punto de control dice "deben salir 6 filas" pero con el diseno
-- que describe la guia (4 tablas, 4 relaciones: labores->siembras,
-- labor_insumo->labores, labor_insumo->insumos, sensores->lotes) a mi me
-- salen 4. No agregue relaciones inventadas para forzar el numero.


-- =====================================================================
-- PARTE C - MIGRACION
-- =====================================================================

-- 3.1 catalogo de insumos (incluye Nitrato de calcio, que no se usa en
--     ninguna labor: es la fila huerfana que pide la consulta D3)
INSERT INTO insumos (insumo_id, nombre, tipo, unidad_medida, precio_referencia) VALUES
  (1, 'Urea 46%',           'fertilizante', 'kg', 0.68),
  (2, 'Muriato de potasio', 'fertilizante', 'kg', 0.74),
  (3, 'Mancozeb',           'fungicida',    'kg', 5.20),
  (4, 'Abono organico',     'fertilizante', 'kg', 0.22),
  (5, 'Aceite agricola',    'coadyuvante',  'L',  3.90),
  (6, 'Semilla INIAP-180',  'semilla',      'kg', 2.10),
  (7, 'Nitrato de calcio',  'fertilizante', 'kg', NULL);

-- 3.2 labores (una fila por cada fila del plano; costo_mano_obra = 0
--     cuando la labor tiene insumos, o = costo_total cuando no los tiene)
INSERT INTO labores (labor_id, siembra_id, tipo_labor, fecha, responsable, costo_mano_obra, observacion) VALUES
  (1,  1, 'fertilizacion',         '2026-03-04', 'Marta Ruiz', 0,      NULL),
  (2,  1, 'control fitosanitario', '2026-03-19', 'Marta Ruiz', 0,      NULL),
  (3,  2, 'fertilizacion',         '2026-03-06', 'Jorge Mina', 0,      NULL),
  (4,  2, 'riego',                 '2026-04-02', 'Jorge Mina', 45.00,  NULL),
  (5,  3, 'poda',                  '2026-03-25', 'Ana Cedeno', 210.00, NULL),
  (6,  4, 'fertilizacion',         '2026-03-11', 'Luis Paez',  0,      NULL),
  (7,  4, 'control fitosanitario', '2026-04-08', 'Luis Paez',  0,      'Se detecto antracnosis leve en hojas'),
  (8,  5, 'siembra',               '2026-02-14', 'Luis Paez',  0,      NULL),
  (9,  5, 'fertilizacion',         '2026-03-02', 'Rosa Vera',  0,      NULL),
  (10, 6, 'fertilizacion',         '2026-03-17', 'Pedro Loor', 0,      NULL),
  (11, 7, 'control fitosanitario', '2026-03-28', 'Pedro Loor', 0,      NULL),
  (12, 8, 'riego',                 '2026-04-05', 'Pedro Loor', 68.00,  NULL);
-- La fila 4 del plano decia "Hacienda Sta. Rosa" (nombre mal escrito); en
-- este modelo la labor no guarda el nombre de la finca en absoluto, solo
-- siembra_id -> lote_id -> finca_id. Al consultar el nombre real siempre
-- sale de fincas.nombre ('Hacienda Santa Rosa'), asi que la variante con
-- error no tiene donde existir: se corrige por diseno, no con un UPDATE.

-- 3.3 labor_insumo (un insumo/cantidad por cada insumo_1 e insumo_2 no NULL)
INSERT INTO labor_insumo (labor_id, insumo_id, cantidad, costo_unitario) VALUES
  (1,  1, 120, 0.68),
  (1,  2, 80,  0.74),
  (2,  3, 15,  5.20),
  (3,  1, 140, 0.68),
  (6,  1, 90,  0.68),
  (6,  4, 300, 0.22),
  (7,  3, 10,  5.20),
  (7,  5, 12,  3.90),
  (8,  6, 45,  2.10),
  (9,  1, 60,  0.70),      -- mismo insumo que la fila 1, precio distinto
  (10, 2, 150, 0.74),
  (10, 4, 400, 0.22),
  (11, 3, 22,  5.20);

-- 3.4 sensores (dato nuevo, no viene del plano; 3 de los 8 lotes quedan
--     sin sensor a proposito, para la consulta D5)
INSERT INTO sensores (sensor_id, lote_id, tipo, modelo, fecha_instalacion, activo) VALUES
  (1, 1, 'temperatura', 'DS18B20', '2025-01-15', 1),
  (2, 1, 'humedad',     NULL,      '2025-01-15', 1),
  (3, 2, 'temperatura', 'DS18B20', '2025-02-01', 1),
  (4, 4, 'humedad',     'SHT31',   '2025-03-10', 1),
  (5, 6, 'radiacion',   NULL,      '2024-12-05', 0),
  (6, 7, 'temperatura', 'DS18B20', '2025-04-20', 1),
  (7, 7, 'humedad',     'SHT31',   '2025-04-20', 1);

-- Punto de control 2
PRAGMA foreign_key_check;   -- no debe devolver ninguna fila


-- =====================================================================
-- PARTE D - VERIFICACION Y PREGUNTAS DE NEGOCIO
-- =====================================================================

-- D1. Conteo de filas de las 4 tablas nuevas
SELECT 'insumos' AS tabla, COUNT(*) AS filas FROM insumos
UNION ALL SELECT 'labores',      COUNT(*) FROM labores
UNION ALL SELECT 'labor_insumo', COUNT(*) FROM labor_insumo
UNION ALL SELECT 'sensores',     COUNT(*) FROM sensores;
-- Esperado: 7 | 12 | 13 | 7


-- D2. La prueba de fuego: costo reconstruido vs costo original
-- Pregunta: coincide el costo que calcula el modelo nuevo con el que
-- traia la hoja de Excel original, labor por labor?
WITH costo AS (
  SELECT l.labor_id,
         ROUND(l.costo_mano_obra + COALESCE(SUM(li.cantidad * li.costo_unitario), 0), 2) AS calculado
  FROM labores l
  LEFT JOIN labor_insumo li ON li.labor_id = l.labor_id
  GROUP BY l.labor_id, l.costo_mano_obra
)
SELECT p.id, p.costo_total AS original, c.calculado,
       CASE WHEN p.costo_total = c.calculado THEN 'OK' ELSE 'REVISAR' END AS estado
FROM registro_campo_plano p
JOIN costo c ON c.labor_id = p.id
ORDER BY p.id;
-- Resultado: 12 filas, las 12 en 'OK'


-- D3. Pregunta: que insumo del catalogo nunca se ha usado en ninguna labor?
SELECT i.insumo_id, i.nombre
FROM insumos i
LEFT JOIN labor_insumo li ON li.insumo_id = i.insumo_id
WHERE li.insumo_id IS NULL;
-- Resultado: 1 fila (Nitrato de calcio)


-- D4. Pregunta: cuanto se ha gastado en insumos por finca, de mayor a menor?
SELECT
    f.nombre AS finca,
    ROUND(SUM(li.cantidad * li.costo_unitario), 2) AS gasto_insumos
FROM fincas f
JOIN lotes lt        ON lt.finca_id = f.finca_id
JOIN siembras s       ON s.lote_id = lt.lote_id
JOIN labores l        ON l.siembra_id = s.siembra_id
JOIN labor_insumo li  ON li.labor_id = l.labor_id
GROUP BY f.nombre
ORDER BY gasto_insumos DESC;
-- Resultado: 3 filas (una por finca)


-- D5. Pregunta: que lotes no tienen ningun sensor instalado?
SELECT lt.lote_id, lt.codigo, f.nombre AS finca
FROM lotes lt
JOIN fincas f ON f.finca_id = lt.finca_id
LEFT JOIN sensores se ON se.lote_id = lt.lote_id
WHERE se.sensor_id IS NULL;
-- Resultado: 3 filas (L-03 de Sta. Rosa, L-02 de El Guayabo, B-1 de La Union)


-- D6. Pregunta propia: cual es el costo promedio de mano de obra por tipo
-- de labor? (la tabla plana no podia responder esto porque mezclaba mano
-- de obra e insumos en una sola columna costo_total, sin forma de aislar
-- solo la parte de mano de obra)
SELECT tipo_labor, COUNT(*) AS veces, ROUND(AVG(costo_mano_obra), 2) AS promedio_mano_obra
FROM labores
GROUP BY tipo_labor
ORDER BY promedio_mano_obra DESC;
-- Resultado: 5 filas (una por tipo de labor)


-- EXTRA (+5): demostrar con un INSERT que falla que el modelo impide un
-- dato imposible (cantidad negativa en labor_insumo)
-- INSERT INTO labor_insumo (labor_id, insumo_id, cantidad, costo_unitario)
-- VALUES (1, 3, -5, 5.20);
-- Resultado real al probarlo: "CHECK constraint failed: cantidad > 0"
-- (lo dejo comentado para que el archivo completo siga corriendo de
-- principio a fin sin interrumpirse en un error esperado; descomentar
-- esta linea sola para verificar el fallo).


-- =====================================================================
-- CIERRE
-- =====================================================================

-- 1) Que se puede hacer ahora que antes era imposible:
--    Registrar una labor con cualquier cantidad de insumos (0, 1, 2, 10),
--    sin tocar la estructura de la tabla, agregando filas en labor_insumo.
--    Tambien se puede saber el precio real que se pago por un insumo en
--    cada aplicacion especifica (la Urea a 0.68 y despues a 0.70), algo que
--    la tabla plana no distinguia bien mas que mirando cada fila a mano.

-- 2) La tabla plana tenia 17 columnas; el modelo tiene mas tablas y mas
--    columnas en total. Por que es una mejora y no un retroceso:
--    Mas columnas repartidas en tablas mas chicas no es lo mismo que mas
--    columnas en una sola tabla ancha. Cada tabla nueva tiene solo las
--    columnas que le corresponden a su propia entidad (un insumo tiene
--    nombre y unidad; una labor tiene fecha y responsable), y ninguna fila
--    tiene columnas vacias "por si acaso" como pasaba con insumo_2 cuando
--    la labor solo llevaba un insumo. El numero total de columnas crecio,
--    pero la cantidad de espacio desperdiciado y de datos repetidos bajo.

-- 3) Una pregunta que el modelo TODAVIA no puede responder, y que habria
--    que agregarle:
--    No puede responder "que temperatura o humedad registro el sensor de
--    tal lote en tal fecha", porque la tabla sensores solo guarda que el
--    sensor existe y esta activo, no sus lecturas. Habria que agregar una
--    quinta tabla, lecturas_sensor (FK -> sensores), con columnas como
--    fecha_hora, valor y unidad, para poder cruzar esas lecturas contra las
--    labores y, por ejemplo, ver si el riego se aplico cuando la humedad
--    del suelo ya estaba baja.

-- =====================================================================
-- FIN DEL EJERCICIO
-- =====================================================================
