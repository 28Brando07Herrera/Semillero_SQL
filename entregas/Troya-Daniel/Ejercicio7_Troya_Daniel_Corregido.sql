-- =====================================================================
-- CURSO DE SQL  |  CLASE 7  |  AgroDB - la serie ya auditada
-- Motor: SQLite   |   Entorno: sqliteonline.com
--
-- AUTOCONTENIDO: se pega COMPLETO en una pestana nueva y se ejecuta.
--
-- Que trae:
--   1. Todo el modelo de la clase 6, sin una sola tabla nueva. Hoy no
--      se agrega nada: hoy se le pregunta otra cosa a lo que ya hay.
--   2. El ejercicio 6 aplicado. La tabla lecturas ahora tiene las dos
--      restricciones que le faltaban, y las filas malas ya no estan.
--
-- LO QUE CAMBIO RESPECTO DE LA CLASE 6 -------------------------------
--
--   * lecturas gana CHECK (valor BETWEEN -50 AND 1500) y
--     UNIQUE (sensor_id, fecha_hora). Son las dos lineas que el
--     ejercicio 6 pedia escribir en la parte E.
--
--   * Se fueron 4 filas: las 3 lecturas averiadas del sensor 1 (los
--     -99 del 19 y 20 de abril) y la medicion duplicada del 7 de abril
--     a las 12:00. La limpieza fue esta, y tuvo que correr ANTES de
--     poder agregar las restricciones:
--
--         DELETE FROM lecturas WHERE valor < -50;
--         DELETE FROM lecturas WHERE lectura_id NOT IN (
--             SELECT MIN(lectura_id) FROM lecturas
--             GROUP BY sensor_id, fecha_hora);
--
--     Ese es el orden real y no se puede invertir: una restriccion no
--     limpia lo que ya esta cargado, solo impide lo que viene.
--
--   * De 977 lecturas quedan 973.
--
-- LO QUE **NO** SE ARREGLO, Y ES A PROPOSITO --------------------------
--
--   * El hueco del sensor 2 sigue ahi: no hay lecturas del 11, 12 y 13
--     de abril. Eso no era un dato malo, era un dato que no existe, y
--     no se inventa.
--
--   * Al borrar las 3 lecturas averiadas, el 19 de abril quedo con 7
--     mediciones y el 20 con 6, en vez de 8. Limpiar datos malos no
--     devuelve datos buenos: deja agujeros. Hoy eso importa.
--
--   * lotes.hectareas sigue con valores enteros en tres lotes. Sigue
--     dando division entera. Sigue siendo su problema.
-- =====================================================================

PRAGMA foreign_keys = ON;

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
-- VERIFICACION DE CARGA
-- Deben salir: 3, 6, 8, 10, 7, 19, 16, 6, 9, 973
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
UNION ALL SELECT 'lecturas',     COUNT(*) FROM lecturas;

-- =====================================================================
-- EJERCICIO PRÁCTICO 7 · EL DÍA QUE NO FUE EL MÁS CALUROSO
-- =====================================================================

-- =====================================================================
-- PARTE A · LO QUE GROUP BY NO PODÍA
-- =====================================================================

-- A1. Cada labor con su costo de mano de obra y el costo total de su siembra.
SELECT 
    labor_id,
    siembra_id,
    tipo_labor,
    costo_mano_obra,
    SUM(costo_mano_obra) OVER (PARTITION BY siembra_id) AS total_mano_obra_siembra
FROM labores;

-- A2. Porcentaje que representa cada labor sobre el total de mano de obra de su siembra.
SELECT 
    labor_id,
    siembra_id,
    tipo_labor,
    costo_mano_obra,
    SUM(costo_mano_obra) OVER (PARTITION BY siembra_id) AS total_mano_obra_siembra,
    ROUND((costo_mano_obra * 100.0) / SUM(costo_mano_obra) OVER (PARTITION BY siembra_id), 1) AS pct_sobre_total
FROM labores;

/*
A3 · Explicación de por qué no se puede hacer con GROUP BY siembra_id:
GROUP BY colapsa todas las filas que comparten el mismo 'siembra_id' en un único registro resumen por grupo en la fase de agrupamiento. 
En ese momento exacto se destruye la granularidad a nivel de labor individual: se pierden el 'labor_id', el 'tipo_labor', la 'fecha' y el 'costo_mano_obra' específico de cada labor. 
Por tanto, resulta imposible proyectar simultáneamente el atributo individual de la labor y el total agregado de la siembra en una misma fila sin recurrir a una función de ventana OVER (PARTITION BY ...), la cual preserva la identidad de cada fila original.
*/


-- =====================================================================
-- PARTE B · RANKINGS
-- =====================================================================

-- B1. Ranking de lotes por rendimiento (kg/ha) dentro de cada finca, con su puesto y cuenta auditada.
SELECT 
    f.nombre AS finca,
    l.codigo AS lote,
    ROUND(SUM(c.kg) * 1.0 / l.hectareas, 2) AS kg_ha,
    COUNT(c.cosecha_id) AS total_cosechas,
    RANK() OVER (
        PARTITION BY f.nombre 
        ORDER BY (SUM(c.kg) * 1.0 / l.hectareas) DESC
    ) AS puesto
FROM cosechas c
JOIN siembras s ON c.siembra_id = s.siembra_id
JOIN lotes l ON s.lote_id = l.lote_id
JOIN fincas f ON l.finca_id = f.finca_id
GROUP BY f.finca_id, f.nombre, l.lote_id, l.codigo, l.hectareas;

-- B2. Promedio diario del sensor 1 en abril con ROW_NUMBER, RANK y DENSE_RANK.
SELECT 
    DATE(fecha_hora) AS dia,
    ROUND(AVG(valor), 2) AS prom,
    ROW_NUMBER() OVER (ORDER BY AVG(valor) DESC) AS row_number,
    RANK() OVER (ORDER BY AVG(valor) DESC) AS rank,
    DENSE_RANK() OVER (ORDER BY AVG(valor) DESC) AS dense_rank
FROM lecturas
WHERE sensor_id = 1 
  AND fecha_hora >= '2026-04-01' 
  AND fecha_hora < '2026-05-01'
GROUP BY DATE(fecha_hora);

/*
B2 · Preguntas sobre funciones de ranking:
1. RANK salta de 2 a 7 porque 5 días comparten el puesto 2 (ocupan las posiciones ordinales 2, 3, 4, 5 y 6). RANK asigna la posición ordinal real al siguiente valor distinto (1 + 5 = 7), reflejando la cantidad de elementos superiores. En cambio, DENSE_RANK enumera los valores únicos escalonadamente sin saltar números (1, 2, 3...).
2. DENSE_RANK te dice de un vistazo que hay 7 promedios distintos: el valor máximo que alcanza en la última fila del ranking coincide exactamente con el número de valores únicos evaluados.
3. ROW_NUMBER asigna un número estrictamente secuencial y único a cada fila. Al existir empates en AVG(valor) y no haber un criterio secundario de desempate en el ORDER BY, el orden entre empates es no determinista (arbitrario según el orden interno en que el motor procesa las filas). Nada garantiza que mañana no cambie el orden si el plan de ejecución, los índices o la inserción de datos varían.
*/

-- B3. Promedio diario del sensor 1 en abril auditado con COUNT(*) para verificar la representatividad.
SELECT 
    DATE(fecha_hora) AS dia,
    ROUND(AVG(valor), 2) AS prom,
    COUNT(*) AS lecturas_dia,
    ROW_NUMBER() OVER (ORDER BY AVG(valor) DESC) AS row_number,
    RANK() OVER (ORDER BY AVG(valor) DESC) AS rank,
    DENSE_RANK() OVER (ORDER BY AVG(valor) DESC) AS dense_rank
FROM lecturas
WHERE sensor_id = 1 
  AND fecha_hora >= '2026-04-01' 
  AND fecha_hora < '2026-05-01'
GROUP BY DATE(fecha_hora);

/*
B3 · Auditoría del primer puesto (20 de abril):
1. El 20 de abril tiene 6 lecturas. El 19 de abril tiene 7 lecturas (los demás días normales tienen 8 lecturas).
2. Tienen menos lecturas porque en la limpieza de la clase anterior se ejecutó un DELETE de los registros con valor < -50, eliminando las lecturas con código de falla (-99): una lectura del 19 de abril (21:00) y dos lecturas del 20 de abril (00:00 y 03:00).
3. Las tres lecturas eliminadas correspondían al horario nocturno y de madrugada (21:00, 00:00 y 03:00), que son los momentos más fríos de la curva diaria. Al extirpar el valle frío del cálculo, el promedio diurno artificialmente infla el resultado del día.
4. NO, el 20 de abril no fue el día más caluroso. Su primer puesto es un artefacto metodológico: tiene un promedio inflado por sesgo de muestreo (horas frías faltantes), no por temperaturas reales más altas.
*/

-- B4. Ranking filtrando únicamente días completos (8 lecturas).
WITH promedios_diarios AS (
    SELECT 
        DATE(fecha_hora) AS dia,
        ROUND(AVG(valor), 2) AS prom,
        COUNT(*) AS total_lecturas
    FROM lecturas
    WHERE sensor_id = 1 
      AND fecha_hora >= '2026-04-01' 
      AND fecha_hora < '2026-05-01'
    GROUP BY DATE(fecha_hora)
)
SELECT 
    dia,
    prom,
    total_lecturas,
    RANK() OVER (ORDER BY prom DESC) AS puesto
FROM promedios_diarios
WHERE total_lecturas = 8;

/*
B4 · Reflexión sobre la exclusión:
Es simplemente otra respuesta sujeta a un compromiso metodológico. Al descartar el 19 y 20 de abril ganamos consistencia comparativa (todas las medias se evalúan sobre la misma base horaria), pero perdimos la información real y válida de las mediciones diurnas de esos dos días. La solución no es asumir que no existieron, sino imputar/tratar los valles faltantes o contextualizar la serie temporal.
*/

-- B5. El mejor lote de cada finca (una sola fila por finca).

/*
-- Intento fallido sin subconsulta/CTE:
SELECT 
    f.nombre AS finca,
    l.codigo AS lote,
    ROUND(SUM(c.kg) * 1.0 / l.hectareas, 2) AS kg_ha,
    COUNT(c.cosecha_id) AS total_cosechas,
    ROW_NUMBER() OVER (
        PARTITION BY f.nombre 
        ORDER BY (SUM(c.kg) * 1.0 / l.hectareas) DESC
    ) AS puesto
FROM cosechas c
JOIN siembras s ON c.siembra_id = s.siembra_id
JOIN lotes l ON s.lote_id = l.lote_id
JOIN fincas f ON l.finca_id = f.finca_id
WHERE puesto = 1
GROUP BY f.finca_id, f.nombre, l.lote_id, l.codigo, l.hectareas;

Mensaje de error:
"Error: misuse of window function ROW_NUMBER() or no such column: puesto"

Explicación:
En el orden lógico de ejecución de SQL, la cláusula WHERE se evalúa antes que el SELECT y que el cálculo de las funciones de ventana. Por ello, el motor no conoce el alias 'puesto' ni permite evaluar funciones de ventana en WHERE, obligando a encapsular la ventana en una CTE/subconsulta y filtrar afuera.
*/

-- Versión correcta con CTE:
WITH ranking_lotes AS (
    SELECT 
        f.nombre AS finca,
        l.codigo AS lote,
        ROUND(SUM(c.kg) * 1.0 / l.hectareas, 2) AS kg_ha,
        COUNT(c.cosecha_id) AS total_cosechas,
        ROW_NUMBER() OVER (
            PARTITION BY f.nombre 
            ORDER BY (SUM(c.kg) * 1.0 / l.hectareas) DESC
        ) AS puesto
    FROM cosechas c
    JOIN siembras s ON c.siembra_id = s.siembra_id
    JOIN lotes l ON s.lote_id = l.lote_id
    JOIN fincas f ON l.finca_id = f.finca_id
    GROUP BY f.finca_id, f.nombre, l.lote_id, l.codigo, l.hectareas
)
SELECT 
    finca,
    lote,
    kg_ha,
    total_cosechas
FROM ranking_lotes
WHERE puesto = 1;


-- =====================================================================
-- PARTE C · MIRAR LA FILA DE AL LADO
-- =====================================================================

-- C1. Cada cosecha con los kilos de la cosecha anterior de la misma siembra y la diferencia.
SELECT 
    siembra_id,
    cosecha_id,
    fecha,
    kg,
    LAG(kg) OVER (PARTITION BY siembra_id ORDER BY fecha) AS anterior,
    kg - LAG(kg) OVER (PARTITION BY siembra_id ORDER BY fecha) AS delta
FROM cosechas;

/*
C1 · Explicación de los NULL:
Son NULL porque representan la primera cosecha cronológica de cada siembra dentro de su partición. Al no existir una fila previa para ese 'siembra_id', LAG() retorna NULL por definición. La consulta es enteramente correcta.
*/

-- C2. Solo las cosechas que rindieron menos que la anterior de su misma siembra.
WITH cosechas_comparadas AS (
    SELECT 
        siembra_id,
        fecha,
        LAG(kg) OVER (PARTITION BY siembra_id ORDER BY fecha) AS de,
        kg AS a,
        kg - LAG(kg) OVER (PARTITION BY siembra_id ORDER BY fecha) AS delta
    FROM cosechas
)
SELECT 
    siembra_id,
    de,
    a,
    delta
FROM cosechas_comparadas
WHERE delta < 0;

/*
C2 · Pregunta al jefe de finca:
¿A qué factores atribuye la pérdida consistente de rendimiento en los segundos cortes (agotamiento de nutrientes, estrés hídrico, plagas acumuladas o manejo agronómico post-primer corte)?
*/

-- C3. Días transcurridos entre cada cosecha y la siguiente de la misma siembra (LEAD).
SELECT 
    siembra_id,
    cosecha_id,
    fecha,
    LEAD(fecha) OVER (PARTITION BY siembra_id ORDER BY fecha) AS fecha_siguiente,
    CAST(ROUND(julianday(LEAD(fecha) OVER (PARTITION BY siembra_id ORDER BY fecha)) - julianday(fecha)) AS INTEGER) AS dias_hasta_siguiente
FROM cosechas;

-- C4. Detección de huecos de medición mayores a 3 horas.
SELECT 
    sensor_id, 
    ant AS desde, 
    fecha_hora AS hasta,
    ROUND((julianday(fecha_hora) - julianday(ant)) * 24, 1) AS horas
FROM (
    SELECT 
        sensor_id, 
        fecha_hora,
        LAG(fecha_hora) OVER (PARTITION BY sensor_id ORDER BY fecha_hora) AS ant
    FROM lecturas
)
WHERE ant IS NOT NULL
  AND (julianday(fecha_hora) - julianday(ant)) * 24 > 3;

/*
C4 · Diagnóstico de huecos:
1. El hueco del sensor 1 (12 horas) se originó al borrar los tres registros con valor -99 del 19-abr 21:00 al 20-abr 03:00.
2. Es un hueco artificial en la base de datos generado por nuestra limpieza, no una desconexión física del sensor.
3. Se debió implementar un flag de estado (ej. `es_invalido = 1`), marcar el valor como `NULL` o conservar una tabla de auditoría (`lecturas_eliminadas`) antes de purgar los datos.
*/


-- =====================================================================
-- PARTE D · ACUMULADOS Y MEDIA MÓVIL
-- =====================================================================

-- D1. Kilos cosechados por fecha con acumulado anual.
WITH cosechas_dia AS (
    SELECT 
        fecha,
        SUM(kg) AS kg_dia
    FROM cosechas
    GROUP BY fecha
)
SELECT 
    fecha,
    kg_dia,
    SUM(kg_dia) OVER (ORDER BY fecha ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS acumulado_anual
FROM cosechas_dia;

-- D2. Kilos cosechados acumulados reiniciándose por finca.
WITH cosechas_finca_dia AS (
    SELECT 
        f.nombre AS finca,
        c.fecha,
        SUM(c.kg) AS kg_dia
    FROM cosechas c
    JOIN siembras s ON c.siembra_id = s.siembra_id
    JOIN lotes l ON s.lote_id = l.lote_id
    JOIN fincas f ON l.finca_id = f.finca_id
    GROUP BY f.finca_id, f.nombre, c.fecha
)
SELECT 
    finca,
    fecha,
    kg_dia,
    SUM(kg_dia) OVER (
        PARTITION BY finca 
        ORDER BY fecha 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS acumulado_finca
FROM cosechas_finca_dia;

/*
D2 · Explicación del cambio:
Se agregó 'PARTITION BY finca' dentro de la cláusula OVER. Esto divide el cálculo acumulativo en particiones independientes por finca, reiniciando la suma a 0 al cambiar de finca.
*/

-- D3. Media móvil de 7 días del promedio diario del sensor 1 en abril.
WITH prom_diario_sensor1 AS (
    SELECT 
        DATE(fecha_hora) AS d,
        ROUND(AVG(valor), 2) AS prom
    FROM lecturas
    WHERE sensor_id = 1 
      AND fecha_hora >= '2026-04-01' 
      AND fecha_hora < '2026-05-01'
    GROUP BY DATE(fecha_hora)
)
SELECT 
    d AS dia,
    prom,
    ROUND(AVG(prom) OVER (
        ORDER BY d 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 2) AS media_movil
FROM prom_diario_sensor1;

-- D4. Media móvil con recuento auditado del marco de la ventana (ROWS BETWEEN).
WITH prom_diario_sensor1 AS (
    SELECT 
        DATE(fecha_hora) AS d,
        ROUND(AVG(valor), 2) AS prom
    FROM lecturas
    WHERE sensor_id = 1 
      AND fecha_hora >= '2026-04-01' 
      AND fecha_hora < '2026-05-01'
    GROUP BY DATE(fecha_hora)
)
SELECT 
    d AS dia,
    prom,
    COUNT(*) OVER (
        ORDER BY d 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS dias_en_ventana,
    ROUND(AVG(prom) OVER (
        ORDER BY d 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 2) AS media_movil
FROM prom_diario_sensor1;

/*
D4 · Análisis de la ventana incompleta:
La media móvil del 1 de abril se calculó sobre 1 solo día (COUNT = 1), no sobre 7. Mostrar esa columna sin advertir el tamaño real de la ventana afirma falsamente que los primeros 6 días representan la estabilidad de una semana completa, cuando en realidad sufren de alta volatilidad muestral.

D5 · Diagnóstico del 20 de abril (Media móvil vs. Promedio crudo):
La media móvil tapó el problema en lugar de remover ruido. Al promediar el 27.33 falso con los días previos, diluyó el pico artificial y normalizó un dato corrupto haciéndolo parecer un comportamiento agronómico plausible cuando en realidad nació de un sesgo de muestreo.
*/


-- =====================================================================
-- PARTE E · CIERRE
-- =====================================================================

/*
E1 · Diferencia entre GROUP BY y OVER (PARTITION BY ...):
GROUP BY colapsa múltiples filas en un único registro agregado por grupo, mientras que OVER (PARTITION BY ...) calcula la agregación manteniendo intacta cada fila individual con su granularidad original.

E2 · Comportamiento de ROW_NUMBER ante empates en B5:
ROW_NUMBER desempataría arbitrariamente asignando el puesto 1 a uno de los lotes y el puesto 2 al otro, devolviendo un único lote según el orden físico interno. No sería lo deseado si se requiere visibilidad completa de ambos líderes; para mostrar empates justos debería usarse RANK() o DENSE_RANK() filtrando por puesto = 1.

E3 · Regla definitiva para limpieza de datos:
Al depurar registros anómalos nunca se debe eliminar físicamente sin documentar ni evaluar el sesgo que genera la ausencia; toda métrica posterior debe auditar el conteo de soporte (COUNT) para verificar que la muestra siga siendo estadísticamente representativa.
*/


-- =====================================================================
-- EXTRA (+5 PTS) · CONSULTA DE NEGOCIO ADICIONAL CON VENTANA
-- =====================================================================

/*
Pregunta de Negocio:
¿Cuánto gasta cada siembra en labores acumuladas a lo largo del tiempo, y qué porcentaje del costo total final de la siembra se ha consumido en cada labor ejecutada?

Justificación de Negocio:
Permite a la gerencia financiera monitorear la tasa de quemado de presupuesto (burn rate) en tiempo real conforme avanza el ciclo agronómico, identificando labores críticas que consumen la mayor parte del capital operativo antes de la cosecha.
*/

SELECT 
    f.nombre AS finca,
    l.codigo AS lote,
    s.siembra_id,
    lab.fecha,
    lab.tipo_labor,
    lab.costo_mano_obra,
    COUNT(lab.labor_id) OVER (
        PARTITION BY s.siembra_id
    ) AS total_labores_siembra,
    SUM(lab.costo_mano_obra) OVER (
        PARTITION BY s.siembra_id 
        ORDER BY lab.fecha 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS costo_acumulado_mano_obra,
    SUM(lab.costo_mano_obra) OVER (
        PARTITION BY s.siembra_id
    ) AS costo_total_siembra,
    ROUND((lab.costo_mano_obra * 100.0) / SUM(lab.costo_mano_obra) OVER (PARTITION BY s.siembra_id), 1) AS pct_impacto_labor
FROM labores lab
JOIN siembras s ON lab.siembra_id = s.siembra_id
JOIN lotes l ON s.lote_id = l.lote_id
JOIN fincas f ON l.finca_id = f.finca_id
ORDER BY s.siembra_id, lab.fecha;