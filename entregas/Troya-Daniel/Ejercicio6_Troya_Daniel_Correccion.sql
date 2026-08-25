-- =====================================================================
-- CURSO DE SQL  |  CLASE 6  |  AgroDB - lecturas de sensores
-- Motor: SQLite   |   Entorno: sqliteonline.com
--
-- AUTOCONTENIDO: se pega COMPLETO en una pestana nueva y se ejecuta.
--
-- Que trae:
--   1. Todo el modelo de la clase 5 (nucleo + insumos + labores +
--      labor_insumo + sensores + cosechas), sin cambios.
--   2. Una tabla nueva: lecturas. Una fila por medicion. Es la primera
--      tabla del curso que no se puede mirar entera: son casi mil filas.
--   3. Cuatro problemas metidos a proposito. No estan marcados. Parte
--      del ejercicio de hoy es encontrarlos.
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
-- TABLA NUEVA DE HOY: lecturas
--
-- Una fila por medicion. Un sensor mide cada 3 horas, todos los dias,
-- para siempre. Es la primera tabla del curso que crece sola.
--
-- Fijense en lo que NO tiene:
--   * no hay CHECK sobre valor. Un sensor averiado puede escribir
--     cualquier numero y la base lo va a aceptar sin chistar.
--   * no hay UNIQUE (sensor_id, fecha_hora). Si el datalogger reenvia
--     un paquete, la misma medicion entra dos veces.
-- Las dos cosas son decisiones de diseno, y las dos se pagan hoy.
-- ---------------------------------------------------------------------
CREATE TABLE lecturas (
    lectura_id INTEGER PRIMARY KEY,
    sensor_id  INTEGER NOT NULL REFERENCES sensores(sensor_id) ON DELETE CASCADE,
    fecha_hora TEXT    NOT NULL,
    valor      NUMERIC(10,2) NOT NULL
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
-- CARGA DE LECTURAS
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

-- El datalogger del sensor 1 reenvio un paquete: esta medicion entra
-- dos veces, con el mismo sensor y la misma fecha_hora. No hay UNIQUE
-- que lo impida.
INSERT INTO lecturas (sensor_id, fecha_hora, valor) VALUES
  (1, '2026-04-07 12:00:00', 29);

-- El sensor 1 se averio la noche del 19 y, en vez de una temperatura,
-- escribio su codigo de falla (-99) durante tres mediciones seguidas.
-- Nadie lo reviso. Las lecturas estan ahi, son NOT NULL, y no hay
-- ningun CHECK que diga que una temperatura de -99 grados es imposible.
UPDATE lecturas SET valor = -99
WHERE sensor_id = 1
  AND fecha_hora IN ('2026-04-19 21:00:00',
                     '2026-04-20 00:00:00',
                     '2026-04-20 03:00:00');


-- =====================================================================
-- VERIFICACION DE CARGA
-- Deben salir: 3, 6, 8, 10, 7, 19, 16, 6, 9, 977
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
-- PARTE A · Conocer la tabla nueva
-- =====================================================================

-- A1
SELECT * FROM lecturas LIMIT 10;

/*
SQLite no tiene un tipo de dato DATETIME nativo dedicado; almacena las fechas 
como cadenas de texto (TEXT), enteros o reales bajo su sistema de tipado dinámico. 
La consecuencia para nosotros es que el orden lexicográfico (alfabético) debe 
coincidir con el orden cronológico estricto, obligando al uso del estándar ISO-8601 
(YYYY-MM-DD HH:MM:SS) para que las comparaciones y funciones de fecha operen correctamente.
*/

-- A2
SELECT 
    sensor_id,
    COUNT(*) AS total_lecturas,
    MIN(fecha_hora) AS primera_medicion,
    MAX(fecha_hora) AS ultima_medicion
FROM lecturas
GROUP BY sensor_id;

/*
El sensor 3 fue dado de baja (activo = 0) el 2026-02-03 tras operar brevemente 
en febrero, por lo que solo registró mediciones históricas previas a su desactivación 
y ninguna durante la campaña de abril.
*/

-- A3
SELECT 
    f.nombre AS finca,
    l.codigo AS lote,
    s.sensor_id,
    s.tipo,
    s.modelo
FROM sensores s
JOIN lotes l ON s.lote_id = l.lote_id
JOIN fincas f ON l.finca_id = f.finca_id
LEFT JOIN lecturas lec ON s.sensor_id = lec.sensor_id
WHERE lec.lectura_id IS NULL;

/*
A4:
- Sensor con activo = 0: Sensor dado de baja administrativa o técnicamente en el catálogo (sensores 3 y 5).
- Sensor sin lecturas: Sensor registrado que jamás ha emitido un registro a la base de datos (sensor 5).
- Sensor con lecturas pero ninguna reciente: Sensor que tiene registros históricos antiguos pero dejó de reportar en el período evaluado (sensor 3, con datos de febrero pero ninguno de abril).
*/


-- =====================================================================
-- PARTE B · Las funciones de fecha
-- =====================================================================

-- B1
SELECT 
    DATE(fecha_hora) AS dia,
    COUNT(*) AS n,
    ROUND(AVG(valor), 2) AS promedio_diario
FROM lecturas
WHERE sensor_id = 1
GROUP BY dia
ORDER BY dia;

-- B2
SELECT 
    strftime('%H', fecha_hora) AS hora,
    COUNT(*) AS n,
    ROUND(AVG(valor), 2) AS promedio_temperatura
FROM lecturas
WHERE sensor_id = 1
GROUP BY hora
ORDER BY hora;

-- B3
SELECT 
    strftime('%Y-%m', fecha_hora) AS mes,
    COUNT(*) AS n
FROM lecturas
GROUP BY mes
ORDER BY mes;

-- B4
SELECT COUNT(*) FROM lecturas WHERE fecha_hora BETWEEN '2026-04-01' AND '2026-04-30';
SELECT COUNT(*) FROM lecturas WHERE fecha_hora >= '2026-04-01' AND fecha_hora < '2026-05-01';
SELECT COUNT(*) FROM lecturas WHERE DATE(fecha_hora) = '2026-04-30';

/*
La comparación BETWEEN '2026-04-01' AND '2026-04-30' evalúa las cadenas literalmente. 
El límite superior '2026-04-30' equivale conceptualmente a '2026-04-30 00:00:00'. 
Cualquier registro del 30 de abril con hora posterior (por ejemplo '2026-04-30 03:00:00') 
es alfabéticamente mayor que '2026-04-30', quedando excluido de la condición.
*/


-- =====================================================================
-- PARTE C · Auditar la serie
-- =====================================================================

-- C1
-- Consulta con valor crudo
SELECT 
    MIN(valor) AS min_crudo,
    MAX(valor) AS max_crudo,
    ROUND(AVG(valor), 2) AS avg_crudo,
    COUNT(*) AS n
FROM lecturas
WHERE sensor_id = 1 
  AND fecha_hora >= '2026-04-01' 
  AND fecha_hora < '2026-05-01';

-- Consulta excluyendo lecturas averiadas
SELECT 
    MIN(valor) AS min_filtrado,
    MAX(valor) AS max_filtrado,
    ROUND(AVG(valor), 2) AS avg_filtrado,
    COUNT(*) AS n
FROM lecturas
WHERE sensor_id = 1 
  AND fecha_hora >= '2026-04-01' 
  AND fecha_hora < '2026-05-01'
  AND valor > -50;

/*
Una desviación de 1.5 °C es mucho más peligrosa porque genera un resultado verosímil 
que pasa desapercibido en auditorías visuales y reportes operacionales. Un error 
de 20 °C alertaría de inmediato al agrónomo por inverosimilitud climática.
*/

-- C2
SELECT 
    DATE(fecha_hora) AS dia,
    COUNT(*) AS n,
    ROUND(AVG(valor), 2) AS promedio_crudo
FROM lecturas
WHERE sensor_id = 1
  AND DATE(fecha_hora) IN ('2026-04-19', '2026-04-20')
GROUP BY dia;

-- C3
-- Camino que no funciona (no detecta días faltantes)
SELECT DATE(fecha_hora) AS dia, COUNT(*) AS n
FROM lecturas 
WHERE sensor_id = 2
GROUP BY dia 
HAVING n <> 8;

/*
GROUP BY solo procesa filas existentes en la tabla. Si durante un día entero 
no se insertó ningún registro, no existe grupo sobre el cual evaluar la agregación 
o filtrar con HAVING.
*/

-- Detección real con calendario generado
WITH RECURSIVE dias(d) AS (
    SELECT '2026-04-01'
    UNION ALL
    SELECT DATE(d, '+1 day') FROM dias WHERE d < '2026-04-30'
)
SELECT d AS dia_faltante
FROM dias
WHERE d NOT IN (
    SELECT DATE(fecha_hora) 
    FROM lecturas 
    WHERE sensor_id = 2
);

-- C4
SELECT 
    sensor_id, 
    anterior, 
    fecha_hora,
    ROUND((julianday(fecha_hora) - julianday(anterior)) * 24, 1) AS horas_sin_medir
FROM (
    SELECT 
        sensor_id, 
        fecha_hora,
        LAG(fecha_hora) OVER (PARTITION BY sensor_id ORDER BY fecha_hora) AS anterior
    FROM lecturas
)
WHERE anterior IS NOT NULL
  AND (julianday(fecha_hora) - julianday(anterior)) * 24 > 3;

/*
Da 75 horas porque se mide el lapso completo transcurrido entre la última lectura válida 
(2026-04-10 21:00:00) y la primera lectura tras la reactivación (2026-04-14 00:00:00): 
3 horas restantes del día 10 + 72 horas de los días 11, 12 y 13.
*/

-- C5
SELECT 
    sensor_id, 
    fecha_hora, 
    COUNT(*) AS repeticiones
FROM lecturas
GROUP BY sensor_id, fecha_hora
HAVING COUNT(*) > 1;

/*
Restricción faltante en el CREATE TABLE:
UNIQUE (sensor_id, fecha_hora)
*/


-- =====================================================================
-- PARTE D · El reporte que sí se puede entregar
-- =====================================================================

-- D1
SELECT 
    f.nombre AS finca,
    l.codigo AS lote,
    s.tipo,
    COUNT(lec.lectura_id) AS n,
    ROUND(AVG(lec.valor), 2) AS promedio
FROM sensores s
JOIN lotes l ON s.lote_id = l.lote_id
JOIN fincas f ON l.finca_id = f.finca_id
JOIN lecturas lec ON s.sensor_id = lec.sensor_id
WHERE lec.fecha_hora >= '2026-04-01' 
  AND lec.fecha_hora < '2026-05-01'
  AND lec.valor > -50
GROUP BY f.nombre, l.codigo, s.tipo
ORDER BY f.nombre, l.codigo, s.tipo;

-- D2
SELECT 
    DATE(fecha_hora) AS dia,
    MAX(valor) AS temp_max,
    CASE 
        WHEN MAX(valor) >= 32 THEN 'ALERTA CALOR'
        WHEN MAX(valor) >= 30 THEN 'atencion'
        ELSE 'normal'
    END AS estado
FROM lecturas
WHERE sensor_id = 1
  AND fecha_hora >= '2026-04-01' 
  AND fecha_hora < '2026-05-01'
  AND valor > -50
GROUP BY dia
HAVING estado IN ('ALERTA CALOR', 'atencion')
ORDER BY dia;

-- D3
WITH clasificacion_dias AS (
    SELECT 
        DATE(fecha_hora) AS dia,
        CASE 
            WHEN MAX(valor) >= 32 THEN 'ALERTA CALOR'
            WHEN MAX(valor) >= 30 THEN 'atencion'
            ELSE 'normal'
        END AS estado
    FROM lecturas
    WHERE sensor_id = 1
      AND fecha_hora >= '2026-04-01' 
      AND fecha_hora < '2026-05-01'
      AND valor > -50
    GROUP BY dia
)
SELECT 
    estado,
    COUNT(*) AS total_dias
FROM clasificacion_dias
GROUP BY estado
ORDER BY 
    CASE estado 
        WHEN 'ALERTA CALOR' THEN 1 
        WHEN 'atencion' THEN 2 
        ELSE 3 
    END;

-- D4
SELECT 
    lab.labor_id,
    lab.tipo_labor,
    lab.fecha,
    f.nombre AS finca,
    l.codigo AS lote,
    COUNT(lec.lectura_id) AS n_lecturas
FROM labores lab
JOIN siembras sie ON lab.siembra_id = sie.siembra_id
JOIN lotes l ON sie.lote_id = l.lote_id
JOIN fincas f ON l.finca_id = f.finca_id
JOIN sensores s ON s.lote_id = l.lote_id
JOIN lecturas lec ON lec.sensor_id = s.sensor_id 
                 AND DATE(lec.fecha_hora) = lab.fecha
WHERE lab.tipo_labor = 'riego'
GROUP BY lab.labor_id, lab.tipo_labor, lab.fecha, f.nombre, l.codigo;

/*
Pregunta de negocio: ¿Cómo respondieron las condiciones del suelo/ambiente (humedad/temperatura) 
a la aplicación de una labor de riego específica en ese lote?
Falta en el modelo: Registrar la hora exacta de ejecución de la labor (actualmente solo tiene DATE) 
y mediciones de volumen de agua aplicado para cruzar el impacto antes/después del riego.
*/


-- =====================================================================
-- PARTE E · Cierre
-- =====================================================================

/*
1. El error más difícil de detectar tras la entrega es el BETWEEN con fechas sueltas. 
No genera nulos, no rompe la cardinalidad esperada de forma evidente ni produce valores 
fuera de rango numérico; simplemente omite sistemáticamente el último día del mes 
alterando promedios y sumatorias de manera silenciosa y verosímil.

2. Restricciones a incorporar:
   - CHECK (valor >= -20 AND valor <= 60) -- ajustado al tipo de medición física
   - UNIQUE (sensor_id, fecha_hora)
Si se aplican directamente sobre la base actual con un ALTER TABLE o recreación de esquema, 
la operación fallará con un error de violación de integridad debido a las filas con 
valor = -99 y a la lectura duplicada del 2026-04-07 12:00:00 ya presentes en la tabla.

3. Rendimiento en consultas temporales sin índices: los escaneos de tabla completa 
(Full Table Scan) en lecturas harán colapsar los tiempos de respuesta al filtrar por 
fecha_hora o sensor_id sobre cientos de miles de registros.
*/

-- =====================================================================
-- EXTRA · Quinto problema de calidad no pedido
-- =====================================================================

/*
PROBLEMA DETECTADO:
Inconsistencia de integridad temporal entre entidades relacionadas.
El sensor 4 registra mediciones continuas a lo largo de todo abril de 2026 
(240 lecturas en el lote L-01 de Finca El Guayabo), pero la siembra asociada 
a ese mismo lote (siembra_id = 4) fue establecida el 2025-05-22 y finalizó 
con su cosecha total el 2026-04-05 (cosecha_id = 5). 

A partir del 6 de abril, el sensor sigue transmitiendo datos sobre un lote 
que agronómicamente ya no tiene cultivo activo en producción, mezclando 
lecturas de suelo descubierto con lecturas bajo cobertura vegetal sin que 
exista una nueva siembra registrada.
*/

SELECT 
    f.nombre AS finca,
    l.codigo AS lote,
    s.sensor_id,
    s.tipo AS tipo_sensor,
    DATE(lec.fecha_hora) AS fecha_lectura,
    COUNT(lec.lectura_id) AS n_lecturas_huerfanas_de_cultivo,
    ROUND(AVG(lec.valor), 2) AS promedio_radiacion
FROM lecturas lec
JOIN sensores s ON lec.sensor_id = s.sensor_id
JOIN lotes l ON s.lote_id = l.lote_id
JOIN fincas f ON l.finca_id = f.finca_id
JOIN siembras sie ON sie.lote_id = l.lote_id
JOIN cosechas cos ON cos.siembra_id = sie.siembra_id
WHERE s.sensor_id = 4
  AND DATE(lec.fecha_hora) > cos.fecha
  AND lec.fecha_hora >= '2026-04-01' 
  AND lec.fecha_hora < '2026-05-01'
GROUP BY f.nombre, l.codigo, s.sensor_id, s.tipo, DATE(lec.fecha_hora)
ORDER BY fecha_lectura;