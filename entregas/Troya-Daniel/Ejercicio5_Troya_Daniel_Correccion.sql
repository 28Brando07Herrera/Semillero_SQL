-- =====================================================================

-- CURSO DE SQL  |  CLASE 5  |  AgroDB - base limpia y con cosechas

-- Motor: SQLite   |   Entorno: sqliteonline.com

--

-- AUTOCONTENIDO: se pega COMPLETO en una pestana nueva y se ejecuta.

--

-- Que trae:

--   1. El modelo normalizado de la clase 3.

--   2. El lote de abril YA LIMPIO: es el resultado esperado del

--      ejercicio 4. Todos arrancan hoy del mismo punto.

--   3. Los jornales que faltaban por cargar, ya cargados. Ahora todas

--      las labores tienen costo de mano de obra real.

--   4. Una tabla nueva: cosechas. Sin ella no hay pregunta de negocio

--      que valga la pena.

-- =====================================================================



PRAGMA foreign_keys = ON;



DROP TABLE IF EXISTS cosechas;

DROP TABLE IF EXISTS labor_insumo;

DROP TABLE IF EXISTS labores;

DROP TABLE IF EXISTS insumos;

DROP TABLE IF EXISTS sensores;

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



-- ---------------------------------------------------------------------

-- TABLA NUEVA DE HOY

--

-- Una siembra puede rendir VARIAS cosechas (pasadas sucesivas del mismo

-- lote). Esa es la relacion 1:N que hace interesante la clase: cuando

-- una siembra tiene 2 cosechas Y 3 labores, unir todo de una sola vez

-- no da 5 filas, da 6. Y ahi es donde el SUM empieza a mentir.

-- ---------------------------------------------------------------------

CREATE TABLE cosechas (

    cosecha_id INTEGER PRIMARY KEY,

    siembra_id INTEGER NOT NULL REFERENCES siembras(siembra_id) ON DELETE CASCADE,

    fecha      DATE    NOT NULL,

    kg         NUMERIC(10,2) NOT NULL CHECK (kg > 0),

    calidad    TEXT    NOT NULL DEFAULT 'primera' CHECK (calidad IN ('primera','segunda','descarte')),

    destino    TEXT

);





-- =====================================================================

-- DATOS

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



-- OJO: el codigo de lote se repite entre fincas. 'L-01' existe en la

-- finca 1 y en la finca 2. Por eso el UNIQUE es (finca_id, codigo) y no

-- solo (codigo). Hoy van a necesitar el nombre de la finca para saber

-- de que lote estan hablando.

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

  (7,7,3,'2025-01-30',3950,'en produccion'),

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



-- 19 labores: el lote de abril ya limpio (la copia duplicada borrada,

-- la fecha en ISO, el 'NULL' de texto convertido en NULL de verdad)

-- y todos los jornales cargados.

INSERT INTO labores VALUES

  (1, 1,'fertilizacion',        '2026-03-04','Marta Ruiz',120.00,NULL),

  (2, 1,'control fitosanitario','2026-03-19','Marta Ruiz', 90.00,NULL),

  (3, 2,'fertilizacion',        '2026-03-06','Jorge Mina',135.00,NULL),

  (4, 2,'riego',                '2026-04-02','Jorge Mina', 45.00,'sin insumos'),

  (5, 3,'poda',                 '2026-03-25','Ana Cedeno',210.00,'sin insumos'),

  (6, 4,'fertilizacion',        '2026-03-11','Luis Paez', 110.00,NULL),

  (7, 4,'control fitosanitario','2026-04-08','Luis Paez',  85.00,NULL),

  (8, 5,'siembra',              '2026-02-14','Luis Paez', 320.00,NULL),

  (9, 5,'fertilizacion',        '2026-03-02','Rosa Vera',  95.00,NULL),

  (10,6,'fertilizacion',        '2026-03-17','Pedro Loor',150.00,NULL),

  (11,7,'control fitosanitario','2026-03-28','Pedro Loor', 88.00,NULL),

  (12,8,'riego',                '2026-04-05','Pedro Loor', 68.00,'sin insumos'),

  (13,1,'fertilizacion',        '2026-04-10','Marta Ruiz',125.00,NULL),

  (14,4,'riego',                '2026-04-14','Luis Paez',  52.00,'sin insumos'),

  (15,6,'control fitosanitario','2026-04-16','Pedro Loor', 92.00,NULL),

  (17,2,'poda',                 '2026-04-15','Jorge Mina',180.00,'sin insumos'),

  (18,7,'riego',                '2026-04-18',NULL,         60.00,'sin insumos'),

  (19,3,'cosecha',              '2026-04-22','Ana Cedeno',145.00,'jornal corregido el 13/08'),

  (20,8,'fertilizacion',        '2026-04-25','Pedro Loor',160.00,NULL);



-- 16 filas: la urea de la labor 20 ya fusionada en una sola de 100 kg.

INSERT INTO labor_insumo VALUES

  (1, 1,120,0.68), (1, 2, 80,0.74), (2, 3, 15,5.20), (3, 1,140,0.68),

  (6, 1, 90,0.68), (6, 4,300,0.22), (7, 3, 10,5.20), (7, 5, 12,3.90),

  (8, 6, 45,2.10), (9, 1, 60,0.70), (10,2,150,0.74), (10,4,400,0.22),

  (11,3, 22,5.20), (13,1,110,0.70), (15,3, 18,5.30), (20,1,100,0.70);



-- Sensor 3 se dio de baja: el lote sigue teniendo un sensor instalado,

-- pero ninguno que este midiendo. No es lo mismo "sin sensor" que

-- "sin sensor activo", y hoy van a tener que distinguirlo.

INSERT INTO sensores VALUES

  (1,1,'temperatura','HYGROCLIP',  '2026-01-15',1),

  (2,1,'humedad',    'HYGROCLIP',  '2026-01-15',1),

  (3,2,'temperatura','HYGROCLIP',  '2026-02-03',0),

  (4,4,'radiacion',  'PYRANOMETER','2026-02-20',1),

  (5,6,'temperatura','uMETOS BASE','2025-11-30',0),

  (6,6,'humedad',    'uMETOS BASE','2025-11-30',1);



-- Nueve cosechas sobre seis siembras. Fijate cuales tienen mas de una.

INSERT INTO cosechas VALUES

  (1,1,'2026-03-20',4200,'primera','mercado local'),

  (2,1,'2026-04-18',3100,'segunda','agroindustria'),

  (3,2,'2026-03-22',5400,'primera','exportacion'),

  (4,3,'2026-04-22',1500,'primera','mercado local'),

  (5,4,'2026-04-05',2600,'primera','mercado local'),

  (6,4,'2026-04-26',1850,'segunda',NULL),

  (7,5,'2026-04-30',9800,'primera','agroindustria'),

  (8,6,'2026-03-28',1200,'primera','exportacion'),

  (9,6,'2026-04-22', 900,'primera','exportacion');





-- =====================================================================

-- VERIFICACION DE CARGA: 3, 6, 8, 10, 7, 19, 16, 6, 9

-- =====================================================================

SELECT 'fincas' AS tabla, COUNT(*) AS filas FROM fincas

UNION ALL SELECT 'cultivos',     COUNT(*) FROM cultivos

UNION ALL SELECT 'lotes',        COUNT(*) FROM lotes

UNION ALL SELECT 'siembras',     COUNT(*) FROM siembras

UNION ALL SELECT 'insumos',      COUNT(*) FROM insumos

UNION ALL SELECT 'labores',      COUNT(*) FROM labores

UNION ALL SELECT 'labor_insumo', COUNT(*) FROM labor_insumo

UNION ALL SELECT 'sensores',     COUNT(*) FROM sensores

UNION ALL SELECT 'cosechas',     COUNT(*) FROM cosechas;

-- =====================================================================
-- PARTE A · Recorrer el modelo
-- =====================================================================

-- ---------------------------------------------------------------------
-- A1. Catálogo de siembras
-- Nombre de finca, código de lote, cultivo, variedad, fecha de siembra y estado.
-- Ordenado por finca y lote.
-- Filas esperadas: 10
-- ---------------------------------------------------------------------
SELECT 
    f.nombre AS finca,
    l.codigo AS lote,
    c.nombre AS cultivo,
    c.variedad,
    s.fecha_siembra,
    s.estado
FROM siembras s
JOIN lotes l ON s.lote_id = l.lote_id
JOIN fincas f ON l.finca_id = f.finca_id
JOIN cultivos c ON s.cultivo_id = c.cultivo_id
ORDER BY f.nombre, l.codigo;


-- ---------------------------------------------------------------------
-- A2. Todas las labores de abril de 2026
-- Incluye finca, lote, responsable y datos de la labor. Ordenado por fecha.
-- Filas esperadas: 10
-- 
-- NOTA SOBRE LABOR 18:
-- El campo 'responsable' está en NULL porque en la limpieza del ejercicio 4
-- se reemplazó el valor inválido/texto ('NULL' literal o dato sucio) por un NULL
-- real de SQL, representando que no se registró o no se conoce el responsable.
-- ---------------------------------------------------------------------
SELECT 
    f.nombre AS finca,
    l.codigo AS lote,
    lb.labor_id,
    lb.tipo_labor,
    lb.fecha,
    lb.responsable,
    lb.costo_mano_obra
FROM labores lb
JOIN siembras s ON lb.siembra_id = s.siembra_id
JOIN lotes l ON s.lote_id = l.lote_id
JOIN fincas f ON l.finca_id = f.finca_id
WHERE lb.fecha >= '2026-04-01' AND lb.fecha <= '2026-04-30'
ORDER BY lb.fecha;


-- ---------------------------------------------------------------------
-- A3. Detalle de consumo de insumos
-- Para cada labor con insumos: finca, lote, labor, fecha, insumo, cantidad,
-- unidad y costo de línea (cantidad * costo_unitario).
-- 6 tablas unidas (fincas, lotes, siembras, labores, labor_insumo, insumos).
-- Filas esperadas: 16
-- ---------------------------------------------------------------------
SELECT 
    f.nombre AS finca,
    l.codigo AS lote,
    lb.tipo_labor,
    lb.fecha,
    i.nombre AS insumo,
    li.cantidad,
    i.unidad,
    (li.cantidad * li.costo_unitario) AS costo_linea
FROM labor_insumo li
JOIN labores lb ON li.labor_id = lb.labor_id
JOIN insumos i ON li.insumo_id = i.insumo_id
JOIN siembras s ON lb.siembra_id = s.siembra_id
JOIN lotes l ON s.lote_id = l.lote_id
JOIN fincas f ON l.finca_id = f.finca_id
ORDER BY f.nombre, l.codigo, lb.fecha;

-- =====================================================================
-- PARTE B · El SUM que miente
-- =====================================================================

-- ---------------------------------------------------------------------
-- B1. Kilos cosechados por finca
-- ---------------------------------------------------------------------
-- Verificación previa con COUNT(*): 9 filas en total (4 en Santa Rosa, 3 en El Guayabo, 2 en La Union)
SELECT 
    f.nombre AS finca,
    SUM(c.kg) AS total_kg
FROM fincas f
JOIN lotes l ON f.finca_id = l.finca_id
JOIN siembras s ON l.lote_id = s.lote_id
JOIN cosechas c ON s.siembra_id = c.siembra_id
GROUP BY f.finca_id, f.nombre;


-- ---------------------------------------------------------------------
-- B2. Kilos cosechados y labores agregando JOIN directo
-- ---------------------------------------------------------------------
-- RESULTADOS OBTENIDOS (INFLADOS POR FAN-OUT):
-- Hacienda Santa Rosa: 31,400 kg (debería ser 14,200)
-- Finca El Guayabo:    37,900 kg (debería ser 14,250)
-- Agricola La Union:    4,200 kg (debería ser 2,100)
SELECT 
    f.nombre AS finca,
    SUM(c.kg) AS total_kg,
    COUNT(lb.labor_id) AS total_labores
FROM fincas f
JOIN lotes l ON f.finca_id = l.finca_id
JOIN siembras s ON l.lote_id = s.lote_id
JOIN cosechas c ON s.siembra_id = c.siembra_id
JOIN labores lb ON s.siembra_id = lb.siembra_id
GROUP BY f.finca_id, f.nombre;


-- ---------------------------------------------------------------------
-- B3. Demostración del fan-out
-- ---------------------------------------------------------------------
-- a) Labores, cosechas y producto cartesiano por siembra
SELECT 
    s.siembra_id,
    (SELECT COUNT(*) FROM labores lb WHERE lb.siembra_id = s.siembra_id) AS cant_labores,
    (SELECT COUNT(*) FROM cosechas c WHERE c.siembra_id = s.siembra_id) AS cant_cosechas,
    (SELECT COUNT(*) 
     FROM labores lb 
     JOIN cosechas c ON lb.siembra_id = c.siembra_id 
     WHERE lb.siembra_id = s.siembra_id) AS filas_al_unir
FROM siembras s;

-- b) Comparación COUNT(*) vs COUNT(DISTINCT) en Finca 1
-- EXPLICACIÓN:
-- COUNT(*) devuelve 11 porque se combinan cada labor con cada cosecha de cada siembra
-- (por ejemplo, siembra 1 tiene 3 labores y 2 cosechas = 6 filas; siembra 2 tiene 3 labores y 1 cosecha = 3 filas; etc.),
-- generando un producto cartesiano local.
-- COUNT(DISTINCT c.cosecha_id) devuelve 4, que es la cantidad real de registros únicos de cosechas que tiene la finca 1.
SELECT 
    COUNT(*) AS total_filas_producto_cartesiano,
    COUNT(DISTINCT c.cosecha_id) AS total_cosechas_reales
FROM fincas f
JOIN lotes l ON f.finca_id = l.finca_id
JOIN siembras s ON l.lote_id = s.lote_id
JOIN cosechas c ON s.siembra_id = c.siembra_id
JOIN labores lb ON s.siembra_id = lb.siembra_id
WHERE f.finca_id = 1;


-- ---------------------------------------------------------------------
-- B4. Corrección con agregaciones independientes (CTEs)
-- ---------------------------------------------------------------------
WITH kilos_por_finca AS (
    SELECT 
        l.finca_id,
        SUM(c.kg) AS total_kg
    FROM siembras s
    JOIN lotes l ON s.lote_id = l.lote_id
    JOIN cosechas c ON s.siembra_id = c.siembra_id
    GROUP BY l.finca_id
),
labores_por_finca AS (
    SELECT 
        l.finca_id,
        COUNT(lb.labor_id) AS total_labores
    FROM siembras s
    JOIN lotes l ON s.lote_id = l.lote_id
    JOIN labores lb ON s.siembra_id = lb.siembra_id
    GROUP BY l.finca_id
)
SELECT 
    f.nombre AS finca,
    COALESCE(k.total_kg, 0) AS total_kg,
    COALESCE(lab.total_labores, 0) AS total_labores
FROM fincas f
LEFT JOIN kilos_por_finca k ON f.finca_id = k.finca_id
LEFT JOIN labores_por_finca lab ON f.finca_id = lab.finca_id;


-- ---------------------------------------------------------------------
-- B5. Error en la otra dirección (Pérdida y duplicación)
-- ---------------------------------------------------------------------
SELECT SUM(costo_mano_obra) FROM labores;

SELECT SUM(lb.costo_mano_obra)
FROM labores lb 
JOIN labor_insumo li ON li.labor_id = lb.labor_id;

-- EXPLICACIÓN:
-- 1. Filas que perdió: Al hacer INNER JOIN con labor_insumo, se excluyen las labores que no utilizaron insumos (7 labores).
-- 2. Filas que contó de más: Las labores que consumieron múltiples insumos (como labor_id 1, 6, 7, 10) se repiten en el JOIN, sumando su costo_mano_obra varias veces.

-- Conteo de labores sin insumos:
SELECT COUNT(*) AS labores_sin_insumos
FROM labores lb
LEFT JOIN labor_insumo li ON lb.labor_id = li.labor_id
WHERE li.labor_id IS NULL;

-- =====================================================================
-- PARTE C · Encontrar lo que falta
-- =====================================================================

-- ---------------------------------------------------------------------
-- C1. Lotes sin ningún sensor instalado
-- ---------------------------------------------------------------------
SELECT 
    f.nombre AS finca,
    l.codigo AS lote
FROM lotes l
JOIN fincas f ON l.finca_id = f.finca_id
LEFT JOIN sensores s ON l.lote_id = s.lote_id
WHERE s.sensor_id IS NULL;


-- ---------------------------------------------------------------------
-- C2. Lotes sin ningún sensor activo
-- ---------------------------------------------------------------------
-- Si se coloca 'activo = 1' en el WHERE, devuelve 7 filas porque descarta 
-- los registros con sensores inactivos convirtiendo el LEFT JOIN en un filtro estricto.
-- Al colocar 'activo = 1' en el ON, el LEFT JOIN preserva todos los lotes y solo 
-- empareja con sensores que estén activos, permitiendo identificar correctamente 
-- los 5 lotes sin sensores funcionando.

SELECT 
    f.nombre AS finca,
    l.codigo AS lote
FROM lotes l
JOIN fincas f ON l.finca_id = f.finca_id
LEFT JOIN sensores s ON l.lote_id = s.lote_id AND s.activo = 1
WHERE s.sensor_id IS NULL;


-- ---------------------------------------------------------------------
-- C3. Siembras sin ninguna labor registrada
-- ---------------------------------------------------------------------
SELECT 
    f.nombre AS finca,
    l.codigo AS lote,
    c.nombre AS cultivo,
    s.estado
FROM siembras s
JOIN lotes l ON s.lote_id = l.lote_id
JOIN fincas f ON l.finca_id = f.finca_id
JOIN cultivos c ON s.cultivo_id = c.cultivo_id
LEFT JOIN labores lb ON s.siembra_id = lb.siembra_id
WHERE lb.labor_id IS NULL;


-- ---------------------------------------------------------------------
-- C4. Insumos del catálogo que nunca se usaron
-- ---------------------------------------------------------------------
SELECT 
    i.insumo_id,
    i.nombre AS insumo
FROM insumos i
LEFT JOIN labor_insumo li ON i.insumo_id = li.insumo_id
WHERE li.insumo_id IS NULL;


-- ---------------------------------------------------------------------
-- C5. Siembras en producción sin cosecha registrada
-- ---------------------------------------------------------------------
-- Mensaje para el jefe de finca:
-- La siembra 7 (Cacao CCN-51 en el lote A-2 de Agrícola La Unión) está marcada 
-- como 'en produccion' desde enero 2025, pero no registra ninguna cosecha ni labores recientes. 
-- Se debe verificar en campo si hubo cosechas no reportadas o si el estado debe actualizarse.

SELECT 
    f.nombre AS finca,
    l.codigo AS lote,
    c.nombre AS cultivo,
    s.fecha_siembra,
    s.estado
FROM siembras s
JOIN lotes l ON s.lote_id = l.lote_id
JOIN fincas f ON l.finca_id = f.finca_id
JOIN cultivos c ON s.cultivo_id = c.cultivo_id
LEFT JOIN cosechas cs ON s.siembra_id = cs.siembra_id
WHERE s.estado = 'en produccion' AND cs.cosecha_id IS NULL;

-- =====================================================================
-- PARTE D · Las preguntas del jefe
-- =====================================================================

-- ---------------------------------------------------------------------
-- D1. Rendimiento en kg por hectárea de cada lote cosechado
-- ---------------------------------------------------------------------
-- CONSULTA CON ERROR (SUM(c.kg) / l.hectareas sin agrupar previamente):
-- Tres salen mal (Santa Rosa L-01, El Guayabo L-01, La Union A-1) y tres bien (Santa Rosa L-02, El Guayabo L-02, El Guayabo L-03).
-- EXPLICACIÓN:
-- Los lotes con múltiples cosechas (siembras 1, 4 y 6) dividen la suma total acumulada por las hectáreas una sola vez por fila si no se consolida por lote/siembra, o duplican filas si hay más de una siembra por lote (como L-01 en Santa Rosa que tiene siembras 1 y 9). Al calcular sobre el total de kilos cosechados dividido para las hectáreas del lote, la agregación debe ser explícita a nivel de lote cosechado.

-- CONSULTA CORREGIDA:
SELECT 
    f.nombre AS finca,
    l.codigo AS lote,
    l.hectareas,
    SUM(c.kg) AS total_kg,
    ROUND(SUM(c.kg) * 1.0 / l.hectareas, 2) AS rendimiento_kg_ha
FROM lotes l
JOIN fincas f ON l.finca_id = f.finca_id
JOIN siembras s ON l.lote_id = s.lote_id
JOIN cosechas c ON s.siembra_id = c.siembra_id
GROUP BY l.lote_id, f.nombre, l.codigo, l.hectareas
ORDER BY rendimiento_kg_ha DESC;


-- ---------------------------------------------------------------------
-- D2. Costo total por finca (Mano de obra + Insumos)
-- ---------------------------------------------------------------------
WITH mo_finca AS (
    SELECT 
        l.finca_id,
        SUM(lb.costo_mano_obra) AS total_mo
    FROM labores lb
    JOIN siembras s ON lb.siembra_id = s.siembra_id
    JOIN lotes l ON s.lote_id = l.lote_id
    GROUP BY l.finca_id
),
insumos_finca AS (
    SELECT 
        l.finca_id,
        SUM(li.cantidad * li.costo_unitario) AS total_insumos
    FROM labor_insumo li
    JOIN labores lb ON li.labor_id = lb.labor_id
    JOIN siembras s ON lb.siembra_id = s.siembra_id
    JOIN lotes l ON s.lote_id = l.lote_id
    GROUP BY l.finca_id
)
SELECT 
    f.nombre AS finca,
    COALESCE(mo.total_mo, 0) AS mano_obra,
    COALESCE(ins.total_insumos, 0) AS insumos,
    (COALESCE(mo.total_mo, 0) + COALESCE(ins.total_insumos, 0)) AS costo_total
FROM fincas f
LEFT JOIN mo_finca mo ON f.finca_id = mo.finca_id
LEFT JOIN insumos_finca ins ON f.finca_id = ins.finca_id;


-- ---------------------------------------------------------------------
-- D3. Rankings cortos
-- ---------------------------------------------------------------------
-- a) Responsables por cantidad de labores
SELECT 
    responsable,
    COUNT(*) AS cantidad_labores
FROM labores
WHERE responsable IS NOT NULL
GROUP BY responsable
ORDER BY cantidad_labores DESC;

-- b) Insumos por costo total consumido
SELECT 
    i.nombre AS insumo,
    SUM(li.cantidad * li.costo_unitario) AS costo_total_consumido
FROM labor_insumo li
JOIN insumos i ON li.insumo_id = i.insumo_id
GROUP BY i.insumo_id, i.nombre
ORDER BY costo_total_consumido DESC;

-- =====================================================================
-- PARTE E · Cierre
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Error más peligroso en un reporte gerencial
-- ---------------------------------------------------------------------
-- El SUM inflado (fan-out) es el más peligroso porque no genera errores de sintaxis y devuelve un número aparentemente válido.
-- La gerencia toma decisiones financieras y operativas basadas en datos que parecen consistentes pero multiplican costos o producción en silencio.
-- A diferencia de un fallo visible o filas faltantes evidentes, la duplicación por relaciones 1:N pasa completamente desapercibida sin una auditoría profunda.


-- ---------------------------------------------------------------------
-- 2. Formas Normales de las refactorizaciones de la Clase 3
-- ---------------------------------------------------------------------
-- a) Separar insumo_1, insumo_2, insumo_3 en filas de labor_insumo:
--    1FN (Primera Forma Normal) -> Elimina grupos repetitivos y asegura atomicidad por fila.
--
-- b) Sacar unidad a la tabla insumos:
--    2FN (Segunda Forma Normal) -> Elimina dependencias parciales de claves compuestas en tablas intermedias.
--
-- c) Sacar provincia a la tabla fincas:
--    3FN (Tercera Forma Normal) -> Elimina dependencias transitivas respecto a la clave primaria.


-- ---------------------------------------------------------------------
-- 3. Pregunta de negocio que AgroDB aún no puede responder
-- ---------------------------------------------------------------------
-- Pregunta: "¿Cuál es el ingreso total y margen de ganancia real obtenido por cada siembra o lote?"
-- Falta: Una columna de 'precio_unitario_venta' (o 'ingreso_total') en la tabla 'cosechas', o una tabla de 'ventas' vinculada a cada cosecha.

-- =====================================================================
-- EXTRA · Pregunta de negocio propia (+5 pts)
-- =====================================================================

-- ---------------------------------------------------------------------
-- Pregunta: ¿Cuál es el costo total de insumos invertido por cada tipo
-- de cultivo en cada finca, desglosando la cantidad de siembras activas?
-- (Utiliza 5 tablas: fincas, lotes, siembras, cultivos, labor_insumo y labores)
-- ---------------------------------------------------------------------
-- COUNT(*) de control sobre el consumo de insumos: 16 registros base en labor_insumo
SELECT 
    f.nombre AS finca,
    c.nombre AS cultivo,
    COUNT(DISTINCT s.siembra_id) AS total_siembras,
    ROUND(SUM(li.cantidad * li.costo_unitario), 2) AS gasto_total_insumos
FROM fincas f
JOIN lotes l ON f.finca_id = l.finca_id
JOIN siembras s ON l.lote_id = s.lote_id
JOIN cultivos c ON s.cultivo_id = c.cultivo_id
JOIN labores lb ON s.siembra_id = lb.siembra_id
JOIN labor_insumo li ON lb.labor_id = li.labor_id
GROUP BY f.nombre, c.nombre
ORDER BY gasto_total_insumos DESC;