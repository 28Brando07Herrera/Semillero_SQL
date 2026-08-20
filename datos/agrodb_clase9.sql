-- =====================================================================
-- CURSO DE SQL  |  CLASE 9  |  AgroDB - la base a escala
-- Motor: SQLite   |   Entorno: sqliteonline.com (o tu SQLite local)
--
-- AUTOCONTENIDO: se pega COMPLETO en una pestana nueva y se ejecuta.
-- OJO: este tarda unos segundos mas que los anteriores. Es a proposito:
-- esta generando cien mil filas.
--
-- QUE TRAE DE NUEVO --------------------------------------------------
--
--   1. El ejercicio 8 resuelto: las cinco vistas que construyeron
--      ayer ya estan creadas.
--
--        v_lote_finca         el JOIN lote-finca guardado
--        v_produccion_lote    kg y kg/ha por lote, con el * 1.0 adentro
--        v_produccion_finca   construida SOBRE la anterior
--        v_costo_siembra      las 10 siembras, sin fan-out, cierra en 3562.30
--        v_temp_diaria_v2     solo sensores activos, con su conteo
--
--   2. lecturas_historico: **105.120 filas**.
--
--      Es un ano entero de mediciones cada 30 minutos para los 6
--      sensores. Hasta hoy la tabla lecturas tenia 973 filas y todo
--      era instantaneo. A esta escala, no.
--
--      La tabla NO tiene ningun indice propio. Eso es el ejercicio.
--
-- POR QUE v_temp_diaria SIGUE ESTANDO, Y SIGUE MAL --------------------
--
--   La parte C6 del ejercicio 8 preguntaba si convenia reemplazar la
--   vista mala o publicar la buena al lado. Aca esta la respuesta que
--   se tomo: **las dos**. v_temp_diaria_v2 es la buena y es la que hay
--   que usar; v_temp_diaria queda como estaba porque el tablero de la
--   finca la consulta todas las mananas y romperlo sin avisar no es
--   una opcion. Se deprecia, no se borra.
--
--   Si les molesta verla ahi: esa incomodidad es exactamente la que
--   siente cualquiera que hereda una base con diez anos encima.
--
-- LO QUE SIGUE IGUAL --------------------------------------------------
--
--   Las 10 tablas del modelo y las 973 filas de lecturas no cambiaron.
--   lotes.hectareas sigue con enteros. El hueco del sensor 2 sigue ahi.
--   El 19 y el 20 de abril siguen con 7 y 6 lecturas.
-- =====================================================================

PRAGMA foreign_keys = ON;

-- Las vistas se borran primero: una vista cuya tabla desaparece no da
-- error al momento de borrar la tabla. Queda rota y muda hasta que
-- alguien la consulta.
DROP VIEW  IF EXISTS v_alertas_sensores;
DROP VIEW  IF EXISTS v_temp_diaria;
DROP VIEW  IF EXISTS v_produccion_lote;
DROP VIEW  IF EXISTS v_produccion_finca;
DROP VIEW  IF EXISTS v_lote_finca;
DROP VIEW  IF EXISTS v_costo_siembra;
DROP VIEW  IF EXISTS v_temp_diaria_v2;
DROP VIEW  IF EXISTS v_hist_diaria;

DROP TABLE IF EXISTS lecturas_historico;

DROP TABLE IF EXISTS lecturas;
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
-- NUCLEO (identico a la clase 5)
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

CREATE TABLE cosechas (
    cosecha_id INTEGER PRIMARY KEY,
    siembra_id INTEGER NOT NULL REFERENCES siembras(siembra_id) ON DELETE CASCADE,
    fecha      DATE    NOT NULL,
    kg         NUMERIC(10,2) NOT NULL CHECK (kg > 0),
    calidad    TEXT    NOT NULL DEFAULT 'primera' CHECK (calidad IN ('primera','segunda','descarte')),
    destino    TEXT
);

-- ---------------------------------------------------------------------
-- lecturas, ahora con las dos restricciones puestas
--
-- En la clase 6 esta tabla no tenia ninguna de las dos, y las cuatro
-- mentiras del dia salieron de ahi. Ahora:
--
--   * el CHECK vuelve imposible que un codigo de falla se disfrace de
--     temperatura. Un -99 ya no entra: da error y corta la carga.
--   * el UNIQUE vuelve imposible que el datalogger cargue dos veces la
--     misma medicion.
--
-- Ninguna de las dos repara nada de lo que ya estaba cargado. Por eso
-- la limpieza tuvo que correr primero.
-- ---------------------------------------------------------------------
CREATE TABLE lecturas (
    lectura_id INTEGER PRIMARY KEY,
    sensor_id  INTEGER NOT NULL REFERENCES sensores(sensor_id) ON DELETE CASCADE,
    fecha_hora TEXT    NOT NULL,
    valor      NUMERIC(10,2) NOT NULL CHECK (valor BETWEEN -50 AND 1500),
    UNIQUE (sensor_id, fecha_hora)
);


-- =====================================================================
-- DATOS DEL MODELO (identicos a la clase 5)
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

INSERT INTO labor_insumo VALUES
  (1, 1,120,0.68), (1, 2, 80,0.74), (2, 3, 15,5.20), (3, 1,140,0.68),
  (6, 1, 90,0.68), (6, 4,300,0.22), (7, 3, 10,5.20), (7, 5, 12,3.90),
  (8, 6, 45,2.10), (9, 1, 60,0.70), (10,2,150,0.74), (10,4,400,0.22),
  (11,3, 22,5.20), (13,1,110,0.70), (15,3, 18,5.30), (20,1,100,0.70);

-- Sensor 3 y sensor 5 estan dados de baja (activo = 0).
-- El 3 alcanzo a medir en febrero antes de que lo bajaran. El 5 nunca
-- llego a enviar nada. No es lo mismo "sensor inactivo" que "sensor
-- sin lecturas", y hoy hay que distinguirlo.
INSERT INTO sensores VALUES
  (1,1,'temperatura','HYGROCLIP',  '2026-01-15',1),
  (2,1,'humedad',    'HYGROCLIP',  '2026-01-15',1),
  (3,2,'temperatura','HYGROCLIP',  '2026-02-03',0),
  (4,4,'radiacion',  'PYRANOMETER','2026-02-20',1),
  (5,6,'temperatura','uMETOS BASE','2025-11-30',0),
  (6,6,'humedad',    'uMETOS BASE','2025-11-30',1);

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
-- CARGA DE LECTURAS (ya limpia)
--
-- Abril de 2026, una medicion cada 3 horas (8 por dia, 30 dias).
-- Se generan con un CTE recursivo en vez de escribir mil INSERT a mano.
-- El valor sigue una curva diaria realista: la temperatura sube al
-- mediodia, la humedad hace lo contrario, y la radiacion es cero de
-- noche. Eso importa: el promedio por hora tiene que dar una curva.
-- =====================================================================

-- n va de 0 a 239.  dia = n/8 + 1   hora = (n%8)*3
WITH RECURSIVE serie(n) AS (
    SELECT 0
    UNION ALL
    SELECT n + 1 FROM serie WHERE n < 239
)
INSERT INTO lecturas (sensor_id, fecha_hora, valor)
-- Sensor 1: temperatura, lote L-01 de Hacienda Santa Rosa
SELECT 1,
       datetime('2026-04-01 00:00:00', '+' || (n * 3) || ' hours'),
       CASE (n % 8) * 3
           WHEN  0 THEN 19 WHEN  3 THEN 18 WHEN  6 THEN 20 WHEN  9 THEN 25
           WHEN 12 THEN 29 WHEN 15 THEN 30 WHEN 18 THEN 26 ELSE 22
       END + ((n / 8) % 5) - 2
FROM serie
-- las 3 que el sensor escribio como -99 y que la limpieza borro
WHERE datetime('2026-04-01 00:00:00', '+' || (n * 3) || ' hours') NOT IN
      ('2026-04-19 21:00:00', '2026-04-20 00:00:00', '2026-04-20 03:00:00')
UNION ALL
-- Sensor 2: humedad, mismo lote. OJO: se salta del 11 al 13 de abril.
SELECT 2,
       datetime('2026-04-01 00:00:00', '+' || (n * 3) || ' hours'),
       CASE (n % 8) * 3
           WHEN  0 THEN 88 WHEN  3 THEN 90 WHEN  6 THEN 87 WHEN  9 THEN 75
           WHEN 12 THEN 62 WHEN 15 THEN 58 WHEN 18 THEN 70 ELSE 82
       END + ((n / 8) % 4) - 1
FROM serie
WHERE (n / 8) + 1 NOT IN (11, 12, 13)
UNION ALL
-- Sensor 4: radiacion, lote L-01 de Finca El Guayabo. De noche da 0.
SELECT 4,
       datetime('2026-04-01 00:00:00', '+' || (n * 3) || ' hours'),
       CASE (n % 8) * 3
           WHEN  9 THEN 420 WHEN 12 THEN 860 WHEN 15 THEN 720 WHEN 18 THEN 150
           ELSE 0
       END
       + CASE WHEN (n % 8) * 3 BETWEEN 9 AND 18 THEN ((n / 8) % 3) * 20 ELSE 0 END
FROM serie
UNION ALL
-- Sensor 6: humedad, lote A-1 de Agricola La Union
SELECT 6,
       datetime('2026-04-01 00:00:00', '+' || (n * 3) || ' hours'),
       CASE (n % 8) * 3
           WHEN  0 THEN 91 WHEN  3 THEN 92 WHEN  6 THEN 89 WHEN  9 THEN 78
           WHEN 12 THEN 66 WHEN 15 THEN 61 WHEN 18 THEN 73 ELSE 85
       END + ((n / 8) % 3) - 1
FROM serie;

-- Sensor 3: lecturas viejas de febrero, de antes de que lo dieran de
-- baja. Siguen ahi. Cualquier promedio "por sensor" que no filtre por
-- fecha las va a mezclar con las de abril.
WITH RECURSIVE serie2(n) AS (
    SELECT 0 UNION ALL SELECT n + 1 FROM serie2 WHERE n < 39
)
INSERT INTO lecturas (sensor_id, fecha_hora, valor)
SELECT 3,
       datetime('2026-02-04 00:00:00', '+' || (n * 3) || ' hours'),
       CASE (n % 8) * 3
           WHEN  0 THEN 21 WHEN  3 THEN 20 WHEN  6 THEN 22 WHEN  9 THEN 27
           WHEN 12 THEN 31 WHEN 15 THEN 32 WHEN 18 THEN 28 ELSE 24
       END
FROM serie2;


-- =====================================================================
-- LA CAPA DE REPORTE (clase 8 + el ejercicio 8 resuelto)
-- =====================================================================

-- --- las dos que ya venian con la clase 8 -----------------------------

-- v_temp_diaria: DEPRECADA. No filtra sensores dados de baja y no
-- expone el conteo. Se conserva porque hay un tablero que la consulta.
-- Para trabajo nuevo, usar v_temp_diaria_v2.
CREATE VIEW v_temp_diaria AS
SELECT DATE(l.fecha_hora)   AS dia,
       ROUND(AVG(l.valor),2) AS temp_promedio
FROM lecturas l
JOIN sensores s ON s.sensor_id = l.sensor_id
WHERE s.tipo = 'temperatura'
GROUP BY DATE(l.fecha_hora);

CREATE VIEW v_alertas_sensores AS
SELECT s.sensor_id, s.tipo, f.nombre AS finca, lo.codigo AS lote,
       l.fecha_hora, l.valor
FROM lecturas l
JOIN sensores s ON s.sensor_id = l.sensor_id
JOIN lotes    lo ON lo.lote_id  = s.lote_id
JOIN fincas   f  ON f.finca_id  = lo.finca_id
WHERE s.activo = 1
  AND ( (s.tipo = 'temperatura' AND l.valor > 28)
     OR (s.tipo = 'humedad'     AND l.valor < 60)
     OR (s.tipo = 'radiacion'   AND l.valor > 800) );

-- --- las cinco del ejercicio 8 ----------------------------------------

CREATE VIEW v_lote_finca AS
SELECT lo.lote_id, f.nombre AS finca, lo.codigo AS lote,
       lo.hectareas, lo.tipo_suelo
FROM lotes lo
JOIN fincas f ON f.finca_id = lo.finca_id;

-- El * 1.0 vive aca adentro, escrito una sola vez.
CREATE VIEW v_produccion_lote AS
SELECT f.nombre  AS finca, lo.codigo AS lote, lo.hectareas,
       COUNT(c.cosecha_id) AS n_cosechas,
       SUM(c.kg)           AS kg_total,
       ROUND(SUM(c.kg) * 1.0 / lo.hectareas, 2) AS kg_ha
FROM cosechas c
JOIN siembras si ON si.siembra_id = c.siembra_id
JOIN lotes lo    ON lo.lote_id    = si.lote_id
JOIN fincas f    ON f.finca_id    = lo.finca_id
GROUP BY f.nombre, lo.codigo, lo.hectareas;

-- Construida SOBRE la anterior: cero JOIN escritos.
CREATE VIEW v_produccion_finca AS
SELECT finca, COUNT(*) AS lotes, SUM(kg_total) AS kg,
       ROUND(SUM(kg_total) * 1.0 / SUM(hectareas), 2) AS kg_ha
FROM v_produccion_lote
GROUP BY finca;

-- Las 10 siembras, sin fan-out. El total cierra en 3562.30.
CREATE VIEW v_costo_siembra AS
SELECT si.siembra_id, f.nombre AS finca, lo.codigo AS lote,
  COALESCE((SELECT SUM(la.costo_mano_obra) FROM labores la
            WHERE la.siembra_id = si.siembra_id), 0) AS costo_mano_obra,
  COALESCE((SELECT SUM(li.cantidad * li.costo_unitario) FROM labores la
            JOIN labor_insumo li ON li.labor_id = la.labor_id
            WHERE la.siembra_id = si.siembra_id), 0) AS costo_insumos,
  COALESCE((SELECT SUM(la.costo_mano_obra) FROM labores la
            WHERE la.siembra_id = si.siembra_id), 0)
+ COALESCE((SELECT SUM(li.cantidad * li.costo_unitario) FROM labores la
            JOIN labor_insumo li ON li.labor_id = la.labor_id
            WHERE la.siembra_id = si.siembra_id), 0) AS costo_total
FROM siembras si
JOIN lotes lo ON lo.lote_id = si.lote_id
JOIN fincas f ON f.finca_id = lo.finca_id;

-- La honesta: solo sensores activos, y con el conteo a la vista.
CREATE VIEW v_temp_diaria_v2 AS
SELECT s.sensor_id, DATE(l.fecha_hora) AS dia,
       COUNT(*) AS n_lecturas, ROUND(AVG(l.valor),2) AS temp_promedio
FROM lecturas l
JOIN sensores s ON s.sensor_id = l.sensor_id
WHERE s.tipo = 'temperatura' AND s.activo = 1
GROUP BY s.sensor_id, DATE(l.fecha_hora);


-- =====================================================================
-- LA ESCALA
--
-- Un ano completo, cada 30 minutos, para los 6 sensores:
--   365 dias x 48 mediciones x 6 sensores = 105.120 filas.
--
-- Se genera con un CTE recursivo. Tarda unos segundos: es la primera
-- vez en el curso que la base hace esperar.
--
-- OJO CON LO QUE **NO** TIENE: ni un solo indice propio. El
-- lectura_id es INTEGER PRIMARY KEY, que en SQLite es el rowid y no
-- crea un indice aparte, y no hay ningun UNIQUE. Cualquier consulta
-- que filtre por sensor o por fecha tiene que recorrer las 105.120
-- filas una por una.
--
-- Eso es exactamente el ejercicio de hoy.
--
-- SOBRE LOS DATOS: la curva diaria se repite igual todos los dias, asi
-- que todos los promedios diarios dan lo mismo. Es a proposito y no es
-- un error: hoy no importa QUE dicen los datos, importa CUANTO CUESTA
-- encontrarlos. Los datos con los que se piensa siguen estando en
-- lecturas, que no se toco.
-- =====================================================================

CREATE TABLE lecturas_historico (
    lectura_id INTEGER PRIMARY KEY,
    sensor_id  INTEGER NOT NULL,
    fecha_hora TEXT    NOT NULL,
    valor      NUMERIC(10,2) NOT NULL
);

WITH RECURSIVE t(n) AS (
    SELECT 0
    UNION ALL
    SELECT n + 1 FROM t WHERE n < 17519
)
INSERT INTO lecturas_historico (sensor_id, fecha_hora, valor)
SELECT s.sensor_id,
       datetime('2026-01-01 00:00:00', '+' || (t.n * 30) || ' minutes'),
       CASE s.tipo
           WHEN 'temperatura' THEN 24 + (t.n % 48) / 4.0 - 6
           WHEN 'humedad'     THEN 75 + (t.n % 48) / 2.0 - 12
           ELSE (t.n % 48) * 18
       END
FROM t, sensores s;


-- =====================================================================
-- VERIFICACION DE CARGA
-- Deben salir: 3, 6, 8, 10, 7, 19, 16, 6, 9, 973, 7, 105120
--
-- Los diez primeros son los de siempre y no se movieron.
-- El 7 son las vistas (las 2 de ayer + las 5 que construyeron).
-- El 105120 es lo nuevo, y es el tema del dia.
-- =====================================================================
SELECT 'fincas' AS tabla, COUNT(*) AS filas FROM fincas
UNION ALL SELECT 'cultivos',     COUNT(*) FROM cultivos
UNION ALL SELECT 'lotes',        COUNT(*) FROM lotes
UNION ALL SELECT 'siembras',     COUNT(*) FROM siembras
UNION ALL SELECT 'insumos',      COUNT(*) FROM insumos
UNION ALL SELECT 'labores',      COUNT(*) FROM labores
UNION ALL SELECT 'labor_insumo', COUNT(*) FROM labor_insumo
UNION ALL SELECT 'sensores',     COUNT(*) FROM sensores
UNION ALL SELECT 'cosechas',     COUNT(*) FROM cosechas
UNION ALL SELECT 'lecturas',     COUNT(*) FROM lecturas
UNION ALL SELECT 'VISTAS',       COUNT(*) FROM sqlite_master WHERE type = 'view'
UNION ALL SELECT 'lecturas_historico', COUNT(*) FROM lecturas_historico;
