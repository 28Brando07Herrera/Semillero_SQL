-- =====================================================================
-- CURSO DE SQL  |  AgroDB  |  Ejercicio 3
-- Alumno: Byron Yaguar Rios
-- Fecha: 12/08/2026

-- Este archivo se ejecuta DESPUES de datos/agrodb_nucleo.sql,
-- en la MISMA sesion de sqliteonline.

-- Si te trabas mas de 20 minutos: escribi la duda aca como comentario
-- empezando con DUDA, y segui con lo siguiente.
-- =====================================================================

PRAGMA foreign_keys = ON;


-- =====================================================================
-- PARTE A - DIAGNOSTICO  (respuestas como comentario)
-- =====================================================================

SELECT * FROM registro_campo_plano;

-- 1) Si llega una labor que uso TRES insumos, habria que agregar columnas
--    insumo_3, cantidad_3, unidad_3, costo_unit_3 a la tabla, o bien
--    duplicar la fila entera con datos distintos solo en el tercer insumo.
--    Eso es un problema GRAVE, no una molestia, porque:
--    - Cambiar el esquema requiere alterar la tabla (DDL) cada vez que
--      el negocio agrega un insumo mas; eso es impracticable en produccion.
--    - Duplicar filas rompe la cardinalidad: ya no hay "una fila = una labor".
--    - Las columnas vacias (NULL) en insumo_2 cuando solo hay uno generan
--      confusion y hacen que calculos como SUM() sean propensos a error.
--    En un modelo relacional correcto, cada insumo va en su propia fila
--    en una tabla puente (labor_insumo), sin importar cuantos sean.

-- 2) La consulta GROUP BY finca sobre el plano DEBERIA dar 3 fincas,
--    pero puede devolver MAS porque el nombre esta escrito de forma
--    distinta en diferentes filas:
--       'Hacienda Santa Rosa'  (filas 1, 2, 3, 5)
--       'Hacienda Sta. Rosa'   (fila 4  <- error ortografico/abreviacion)
--    SQLite trata esas dos cadenas como valores distintos, por lo que
--    agrupa por separado y muestra 4 grupos en vez de 3.
--    En SQLite no hay error de ejecucion: la consulta corre y devuelve
--    silenciosamente un resultado incorrecto, que es peor que un error visible.

-- 3) La columna 'provincia' depende de la columna 'finca', NO de la fila.
--    Esto viola la 3FN: provincia es un atributo de la finca, no de la labor.
--    Si 'Los Rios' cambia de nombre, hay que actualizar CADA fila de esa
--    finca en la tabla plana. Si se olvida una sola fila, la base queda con
--    datos contradictorios (anomalia de actualizacion). En el modelo
--    normalizado, provincia vive solo en la tabla 'fincas'.

-- 4) La fila 1 tiene costo_total = 140.80 y TIENE dos insumos; ese valor
--    representa el costo de los insumos aplicados (120*0.68 + 80*0.74 = 140.80).
--    La fila 4 tiene costo_total = 45.00 y NO tiene insumos; ese valor
--    representa unicamente el costo de mano de obra del riego.
--    La misma columna 'costo_total' codifica conceptos distintos segun la
--    fila: a veces es costo de insumos, a veces es costo de mano de obra.
--    Eso hace imposible comparar o sumar totales de forma confiable.

-- 5) MODELO PROPUESTO (diagrama en comentario):

--   fincas (existente)
--   lotes (existente)
--   siembras (existente) <------ labores (NUEVA)
--   sensores (NUEVA)           labor_insumo (NUEVA)
--                              insumos (NUEVA)
-- Claves foraneas:
--     labores.siembra_id        --> siembras.siembra_id
--     labor_insumo.labor_id     --> labores.labor_id
--     labor_insumo.insumo_id    --> insumos.insumo_id
--     sensores.lote_id          --> lotes.lote_id


-- =====================================================================
-- PARTE B - CREACION DE TABLAS
-- =====================================================================

DROP TABLE IF EXISTS labor_insumo;
DROP TABLE IF EXISTS labores;
DROP TABLE IF EXISTS insumos;
DROP TABLE IF EXISTS sensores;

-- B.1 insumos  (catalogo: lo que se puede aplicar en campo)
CREATE TABLE insumos (
    insumo_id         INTEGER PRIMARY KEY,
    nombre            TEXT    NOT NULL UNIQUE,                -- UNIQUE: no puede haber dos insumos con el mismo nombre
    tipo              TEXT    NOT NULL
                      CHECK (tipo IN ('fertilizante','fungicida','semilla',
                                      'aceite','herbicida','otro')),
    unidad_medida     TEXT    NOT NULL DEFAULT 'kg',          -- DEFAULT: la mayoria se mide en kg
    precio_referencia NUMERIC(10,2)                           -- NULL permitido: puede existir sin precio de referencia
);

-- B.2 labores  (el evento: que se hizo, sobre que siembra y cuando)
CREATE TABLE labores (
    labor_id        INTEGER PRIMARY KEY,
    siembra_id      INTEGER NOT NULL REFERENCES siembras(siembra_id),
    tipo_labor      TEXT    NOT NULL,
    fecha_labor     DATE    NOT NULL,
    responsable     TEXT,                                     -- NULL permitido: puede registrarse sin asignar
    costo_mano_obra NUMERIC(10,2) NOT NULL DEFAULT 0,         -- DEFAULT: la mayoria de labores con insumos tiene mano_obra=0
    observacion     TEXT,                                     -- NULL permitido: campo opcional
    CHECK (costo_mano_obra >= 0)                              -- CHECK: no puede ser negativo
);

-- B.3 labor_insumo  (tabla puente: que insumos llevo cada labor y cuantos)

-- Por que 'cantidad' no puede vivir en 'labores' ni en 'insumos':
--   En 'labores': una labor puede usar varios insumos, habria que repetir la fila.
--   En 'insumos': un insumo se usa en muchas labores con cantidades diferentes.
--   La cantidad es un atributo de la RELACION entre labor e insumo.

-- Por que 'costo_unitario' va aca y no solo en el catalogo:
--   El precio cambia entre compras. Fila 1 tiene Urea a $0.68 y fila 9 a $0.70.
--   Si solo guardaramos el precio en el catalogo, al actualizarlo perderiamos
--   el historico de lo que se pago realmente en cada labor.
CREATE TABLE labor_insumo (
    labor_id       INTEGER NOT NULL REFERENCES labores(labor_id),
    insumo_id      INTEGER NOT NULL REFERENCES insumos(insumo_id),
    cantidad       NUMERIC(10,2) NOT NULL CHECK (cantidad > 0),        -- CHECK: cantidad positiva
    costo_unitario NUMERIC(10,2) NOT NULL CHECK (costo_unitario >= 0), -- CHECK: precio no negativo
    PRIMARY KEY (labor_id, insumo_id)                                  -- PK compuesta obligatoria
);

-- B.4 sensores  (un lote puede tener varios sensores; un sensor pertenece a un lote)
CREATE TABLE sensores (
    sensor_id         INTEGER PRIMARY KEY,
    lote_id           INTEGER NOT NULL REFERENCES lotes(lote_id),
    tipo              TEXT    NOT NULL
                      CHECK (tipo IN ('temperatura','humedad','radiacion','otro')),
    modelo            TEXT,                                            -- NULL permitido: modelo puede ser desconocido
    fecha_instalacion DATE    NOT NULL DEFAULT (DATE('now')),          -- DEFAULT: fecha de hoy al registrar
    activo            INTEGER NOT NULL DEFAULT 1                       -- DEFAULT: nuevo sensor esta activo
                      CHECK (activo IN (0, 1)),
    UNIQUE (lote_id, modelo)                                           -- UNIQUE: mismo modelo no se repite en un lote
);


-- PUNTO DE CONTROL 1 -> deben salir 6 filas
-- labores->siembras, labor_insumo->labores, labor_insumo->insumos, sensores->lotes
SELECT m.name AS tabla, f."from" AS columna, f."table" AS apunta_a
FROM sqlite_master m
JOIN pragma_foreign_key_list(m.name) f
WHERE m.type = 'table'
  AND m.name IN ('insumos','labores','labor_insumo','sensores')
ORDER BY m.name;


-- =====================================================================
-- PARTE C - MIGRACION
-- =====================================================================
-- Orden: primero la tabla apuntada, luego la que apunta.
-- insumos -> labores -> labor_insumo
-- lotes ya existe -> sensores

-- C.1 insumos  (catalogo de insumos + 1 de catalogo sin usar: Sulfato de calcio)
INSERT INTO insumos (insumo_id, nombre, tipo, unidad_medida, precio_referencia) VALUES
  (1, 'Urea 46%',           'fertilizante', 'kg', 0.68),
  (2, 'Muriato de potasio', 'fertilizante', 'kg', 0.74),
  (3, 'Mancozeb',           'fungicida',    'kg', 5.20),
  (4, 'Abono organico',     'fertilizante', 'kg', 0.22),
  (5, 'Semilla INIAP-180',  'semilla',      'kg', 2.10),
  (6, 'Aceite agricola',    'aceite',       'L',  3.90),
  (7, 'Sulfato de calcio',  'fertilizante', 'kg', NULL); -- insumo de catalogo sin usar


-- C.2 labores
-- Regla de reparto de costo_total del plano:
--   Si la fila TIENE insumos  -> costo_mano_obra = 0    (el costo_total son insumos)
--   Si la fila NO tiene insumos -> costo_mano_obra = costo_total (todo es mano de obra)
--
-- Mapeo a siembra_id segun tabla del ejercicio:
--   filas 1,2 -> siembra_id=1  | filas 3,4 -> siembra_id=2
--   fila  5   -> siembra_id=3  | filas 6,7 -> siembra_id=4
--   filas 8,9 -> siembra_id=5  | fila  10  -> siembra_id=6
--   fila  11  -> siembra_id=7  | fila  12  -> siembra_id=8
--
-- La fila 4 tenia 'Hacienda Sta. Rosa' (nombre con error).
-- Se asigna correctamente a siembra_id=2 sin dejar rastro del error.
INSERT INTO labores (labor_id, siembra_id, tipo_labor, fecha_labor, responsable, costo_mano_obra) VALUES
  (1,  1, 'fertilizacion',         '2026-03-04', 'Marta Ruiz',  0.00),
  (2,  1, 'control fitosanitario', '2026-03-19', 'Marta Ruiz',  0.00),
  (3,  2, 'fertilizacion',         '2026-03-06', 'Jorge Mina',  0.00),
  (4,  2, 'riego',                 '2026-04-02', 'Jorge Mina',  45.00),
  (5,  3, 'poda',                  '2026-03-25', 'Ana Cedeno',  210.00),
  (6,  4, 'fertilizacion',         '2026-03-11', 'Luis Paez',   0.00),
  (7,  4, 'control fitosanitario', '2026-04-08', 'Luis Paez',   0.00),
  (8,  5, 'siembra',               '2026-02-14', 'Luis Paez',   0.00),
  (9,  5, 'fertilizacion',         '2026-03-02', 'Rosa Vera',   0.00),
  (10, 6, 'fertilizacion',         '2026-03-17', 'Pedro Loor',  0.00),
  (11, 7, 'control fitosanitario', '2026-03-28', 'Pedro Loor',  0.00),
  (12, 8, 'riego',                 '2026-04-05', 'Pedro Loor',  68.00);


-- C.3 labor_insumo
-- Verificacion matematica fila por fila:
--   labor 1:  120*0.68 + 80*0.74 = 81.60 + 59.20 = 140.80 OK
--   labor 2:  15*5.20            = 78.00           OK
--   labor 3:  140*0.68           = 95.20           OK
--   labor 4:  sin insumos, mano_obra=45.00         OK
--   labor 5:  sin insumos, mano_obra=210.00        OK
--   labor 6:  90*0.68 + 300*0.22 = 61.20 + 66.00 = 127.20 OK
--   labor 7:  10*5.20 + 12*3.90  = 52.00 + 46.80 = 98.80  OK
--   labor 8:  45*2.10            = 94.50           OK
--   labor 9:  60*0.70            = 42.00           OK  (Urea a 0.70, diferente a labores anteriores)
--   labor 10: 150*0.74 + 400*0.22= 111.00+88.00  = 199.00 OK
--   labor 11: 22*5.20            = 114.40          OK
--   labor 12: sin insumos, mano_obra=68.00         OK
INSERT INTO labor_insumo (labor_id, insumo_id, cantidad, costo_unitario) VALUES
  (1,  1, 120,  0.68),
  (1,  2,  80,  0.74),
  (2,  3,  15,  5.20),
  (3,  1, 140,  0.68),
  (6,  1,  90,  0.68),
  (6,  4, 300,  0.22),
  (7,  3,  10,  5.20),
  (7,  6,  12,  3.90),
  (8,  5,  45,  2.10),
  (9,  1,  60,  0.70),
  (10, 2, 150,  0.74),
  (10, 4, 400,  0.22),
  (11, 3,  22,  5.20);


-- C.4 sensores  (datos de ejemplo para poblar la tabla)
INSERT INTO sensores (sensor_id, lote_id, tipo, modelo, fecha_instalacion, activo) VALUES
  (1, 1, 'temperatura', 'DS18B20', '2025-06-01', 1),
  (2, 1, 'humedad',     'DHT22',   '2025-06-01', 1),
  (3, 4, 'temperatura', 'DS18B20', '2025-08-15', 1),
  (4, 6, 'humedad',     'SHT31',   '2025-09-01', 1),
  (5, 6, 'radiacion',   'Si1145',  '2025-09-01', 0),
  (6, 7, 'temperatura', 'DS18B20', '2026-01-10', 1);


-- PUNTO DE CONTROL 2 -> ninguna fila
PRAGMA foreign_key_check;


-- =====================================================================
-- PARTE D - CONSULTAS   (antes de cada una, la pregunta en palabras)
-- =====================================================================

-- D1. Pregunta: Cuantas filas tiene cada una de las cuatro tablas nuevas?
SELECT 'insumos'      AS tabla, COUNT(*) AS filas FROM insumos
UNION ALL
SELECT 'labores',               COUNT(*)           FROM labores
UNION ALL
SELECT 'labor_insumo',          COUNT(*)           FROM labor_insumo
UNION ALL
SELECT 'sensores',              COUNT(*)           FROM sensores;


-- D2. LA PRUEBA DE FUEGO -> 12 filas, las 12 en OK
-- Pregunta: El costo recalculado desde las tablas nuevas coincide con el costo_total original del plano?
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


-- D3. Pregunta: Que insumo del catalogo nunca fue utilizado en ninguna labor?
SELECT i.insumo_id, i.nombre, i.tipo
FROM insumos i
LEFT JOIN labor_insumo li ON li.insumo_id = i.insumo_id
WHERE li.insumo_id IS NULL;


-- D4. Pregunta: Cual es el gasto total en insumos por finca, de mayor a menor?
-- (Cruza 5 tablas: labor_insumo -> labores -> siembras -> lotes -> fincas)
SELECT
    f.nombre                                       AS finca,
    ROUND(SUM(li.cantidad * li.costo_unitario), 2) AS gasto_total_insumos
FROM labor_insumo li
JOIN labores  l  ON l.labor_id   = li.labor_id
JOIN siembras s  ON s.siembra_id = l.siembra_id
JOIN lotes    lo ON lo.lote_id   = s.lote_id
JOIN fincas   f  ON f.finca_id   = lo.finca_id
GROUP BY f.finca_id, f.nombre
ORDER BY gasto_total_insumos DESC;


-- D5. Pregunta: Que lotes NO tienen ningun sensor instalado?
SELECT lo.lote_id, lo.codigo, f.nombre AS finca
FROM lotes  lo
JOIN fincas f  ON f.finca_id = lo.finca_id
LEFT JOIN sensores s ON s.lote_id = lo.lote_id
WHERE s.sensor_id IS NULL
ORDER BY f.nombre, lo.codigo;


-- D6. Pregunta (inventada): Cual es el responsable que mas gasto en mano de obra
--     acumulo en cada finca, y cuanto fue ese total?
-- Esta pregunta era imposible en el plano porque costo_total mezclaba
-- mano de obra e insumos en una sola columna sin distincion.
SELECT
    f.nombre                         AS finca,
    l.responsable,
    ROUND(SUM(l.costo_mano_obra), 2) AS total_mano_obra
FROM labores  l
JOIN siembras s  ON s.siembra_id = l.siembra_id
JOIN lotes    lo ON lo.lote_id   = s.lote_id
JOIN fincas   f  ON f.finca_id   = lo.finca_id
GROUP BY f.finca_id, f.nombre, l.responsable
ORDER BY f.nombre, total_mano_obra DESC;


-- =====================================================================
-- EXTRA (+5 pts): INSERT que falla, demostrando que el modelo
--                 impide datos imposibles gracias a CHECK constraints
-- =====================================================================

-- Descomentar para probar: falla porque cantidad = -10 viola CHECK (cantidad > 0)
-- INSERT INTO labor_insumo (labor_id, insumo_id, cantidad, costo_unitario)
-- VALUES (1, 1, -10, 0.68);

-- Descomentar para probar: falla porque costo_mano_obra = -5 viola CHECK (costo_mano_obra >= 0)
-- INSERT INTO labores (labor_id, siembra_id, tipo_labor, fecha_labor, responsable, costo_mano_obra)
-- VALUES (99, 1, 'poda', '2026-05-01', 'Test', -5.00);


-- =====================================================================
-- CIERRE
-- =====================================================================

-- 1) Que se puede hacer ahora que antes era imposible:
--    - Registrar una labor con N insumos sin cambiar el esquema de la base.
--    - Saber cuanto se gasto en mano de obra vs. insumos por separado.
--    - Consultar el historico de precios de un insumo: la fila 1 pago Urea
--      a $0.68 y la fila 9 a $0.70; ambos valores conviven sin pisarse.
--    - Agregar insumos al catalogo aunque nunca se hayan usado.
--    - Saber cuantos sensores tiene cada lote y de que tipo.
--    - Detectar lotes sin monitoreo (consulta D5).
--    - Actualizar la provincia de una finca en un solo lugar sin riesgo
--      de dejar filas inconsistentes.
--
-- 2) Por que mas tablas es una mejora y no un retroceso:
--    Tener mas tablas significa que cada concepto esta en su lugar exacto
--    (principio de unica fuente de verdad). La tabla plana tenia 17 columnas
--    con datos repetidos, campos multivaluados (insumo_1, insumo_2) y
--    significados ambiguos (costo_total). El modelo nuevo:
--    - Elimina la repeticion: el nombre de la finca vive en un solo lugar.
--    - Elimina columnas de largo variable: ya no hay limite de insumos por labor.
--    - Separa responsabilidades: cada tabla tiene una sola razon para cambiar.
--    - Hace cumplir reglas de negocio con restricciones (CHECK, FK, NOT NULL)
--      en lugar de depender de disciplina humana.
--    Mas tablas = menos redundancia, mas integridad, mas capacidad de crecer.
--
-- 3) Una pregunta que mi modelo TODAVIA no puede responder, y que le falta:
--    Pregunta: Cual fue el rendimiento en toneladas por hectarea de cada
--    siembra al momento de la cosecha?
--    Para responderla habria que agregar una tabla 'cosechas' con:
--      cosecha_id, siembra_id, fecha_cosecha, toneladas_producidas, observacion.
--    El modelo actual registra que se hicieron labores (fertilizacion, poda,
--    riego) pero no captura el resultado economico final de cada siembra.
