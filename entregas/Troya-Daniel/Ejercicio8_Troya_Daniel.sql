-- =====================================================================
-- CURSO DE SQL  |  CLASE 8  |  AgroDB - la capa de reporte
-- Motor: SQLite   |   Entorno: sqliteonline.com (o tu SQLite local)
--
-- AUTOCONTENIDO: se pega COMPLETO en una pestana nueva y se ejecuta.
--
-- LO QUE CAMBIO RESPECTO DE LA CLASE 7 -------------------------------
--
--   Ninguna tabla. Ninguna fila. Ni una sola.
--
--   Las tablas, los datos y hasta el ultimo numero de control son
--   IDENTICOS a los de agrodb_clase7.sql. Y eso no es pereza: es el
--   tema de hoy.
--
--   Ayer escribieron veinte consultas buenas. Auditaron un podio,
--   encontraron un hueco que habiamos hecho nosotros y calcularon
--   una media movil. Hoy la base no se acuerda de ninguna de las
--   veinte. Un SELECT no deja rastro: se ejecuta, muestra el
--   resultado y se olvida. Si cerraron la pestana, se fue todo.
--
--   Lo unico que sobrevive de una consulta es el archivo .sql que
--   ustedes guardaron a mano. La base, por su cuenta, no guardo nada.
--
-- LO QUE SI TRAE DE NUEVO --------------------------------------------
--
--   Dos VISTAS ya creadas. No las escribieron ustedes: vienen del
--   "tablero de reporteria", que es como vamos a llamar hoy a la
--   persona que se fue del proyecto y dejo esto andando.
--
--     v_temp_diaria        el promedio de temperatura por dia
--     v_alertas_sensores   las lecturas que pasaron un umbral
--
--   Las dos se consultan igual que una tabla:
--
--       SELECT * FROM v_temp_diaria;
--
--   Las dos estan escritas con el mismo estilo, las dos corren sin
--   error y las dos devuelven algo que parece razonable.
--
--   Una de las dos esta mal.
--
--   Mirandolas por afuera no se distingue cual: hay que abrirlas. La
--   parte C del ejercicio es exactamente eso, y la definicion de
--   cualquier vista se lee asi:
--
--       SELECT sql FROM sqlite_master WHERE type = 'view';
--
-- LO QUE SIGUE SIN ARREGLARSE, Y ES A PROPOSITO -----------------------
--
--   * El hueco del sensor 2 (11, 12 y 13 de abril) sigue ahi.
--   * El 19 y el 20 de abril siguen con 7 y 6 lecturas.
--   * lotes.hectareas sigue con enteros en tres lotes, y sigue dando
--     division entera. Hoy eso importa mas que nunca: si el * 1.0 se
--     te escapa adentro de una vista, no se equivoca una consulta.
--     Se equivocan todas las que la usen, todos los dias.
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
-- LA CAPA DE REPORTE
--
-- Estas dos vistas ya estaban publicadas cuando ustedes llegaron.
-- Alguien las escribio, se fue, y el tablero las sigue consultando
-- todas las mananas.
--
-- Una vista NO guarda datos: guarda la pregunta. Cada vez que alguien
-- la consulta, SQLite corre el SELECT de adentro contra las tablas
-- como estan en ese momento.
-- =====================================================================

DROP VIEW IF EXISTS v_alertas_sensores;
DROP VIEW IF EXISTS v_temp_diaria;

-- ---------------------------------------------------------------------
-- v_temp_diaria
-- "El promedio de temperatura de cada dia."
-- ---------------------------------------------------------------------
CREATE VIEW v_temp_diaria AS
SELECT DATE(l.fecha_hora)   AS dia,
       ROUND(AVG(l.valor),2) AS temp_promedio
FROM lecturas l
JOIN sensores s ON s.sensor_id = l.sensor_id
WHERE s.tipo = 'temperatura'
GROUP BY DATE(l.fecha_hora);

-- ---------------------------------------------------------------------
-- v_alertas_sensores
-- "Las lecturas que pasaron el umbral, con su finca y su lote."
--
-- Umbrales: temperatura > 28, humedad < 60, radiacion > 800.
-- ---------------------------------------------------------------------
CREATE VIEW v_alertas_sensores AS
SELECT s.sensor_id,
       s.tipo,
       f.nombre     AS finca,
       lo.codigo    AS lote,
       l.fecha_hora,
       l.valor
FROM lecturas l
JOIN sensores s ON s.sensor_id = l.sensor_id
JOIN lotes    lo ON lo.lote_id  = s.lote_id
JOIN fincas   f  ON f.finca_id  = lo.finca_id
WHERE s.activo = 1
  AND ( (s.tipo = 'temperatura' AND l.valor > 28)
     OR (s.tipo = 'humedad'     AND l.valor < 60)
     OR (s.tipo = 'radiacion'   AND l.valor > 800) );


-- =====================================================================
-- VERIFICACION DE CARGA
-- Deben salir: 3, 6, 8, 10, 7, 19, 16, 6, 9, 973, 2
--
-- Los diez primeros son los mismos de ayer, hasta el ultimo digito.
-- El once es nuevo: la cantidad de vistas. Es lo unico que hoy
-- encontraran en la base que no estaba ayer.
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
UNION ALL SELECT 'VISTAS',       COUNT(*) FROM sqlite_master WHERE type = 'view';


-- =====================================================================
-- CURSO DE SQL | CLASE 8 | AgroDB - la capa de reporte
-- Archivo de entrega: Ejercicio8_Troya_Daniel.sql
-- Motor: SQLite
-- =====================================================================

-- =====================================================================
-- PARTE A · La consulta que se queda
-- =====================================================================

-- A1. Creación de la vista v_lote_finca
DROP VIEW IF EXISTS v_lote_finca;

CREATE VIEW v_lote_finca AS
SELECT f.nombre AS finca,
       lo.codigo AS lote,
       lo.hectareas,
       lo.tipo_suelo
FROM lotes lo
JOIN fincas f ON f.finca_id = lo.finca_id;

-- Verificación A1: Esperado 8 filas
SELECT COUNT(*) FROM v_lote_finca;


-- A2. Consulta sobre la vista sin JOINs explícitos
SELECT lote,
       hectareas,
       tipo_suelo
FROM v_lote_finca
WHERE finca = 'Hacienda Santa Rosa'
ORDER BY hectareas DESC;


-- A3. Pregunta conceptual
/*
RESPUESTA A3:
1. ¿Dónde están guardados los datos?: Los datos no están guardados en la vista;
   permanecen físicamente almacenados en las tablas base ('lotes' y 'fincas').
   La vista únicamente almacena la definición de la consulta SELECT en el catálogo
   del sistema (sqlite_master).
2. Si se actualiza el lote_id = 2 a 40 hectáreas: La vista devolverá inmediatamente
   40 hectáreas para ese lote.
3. ¿Por qué?: Porque cada vez que se invoca 'v_lote_finca', SQLite ejecuta la consulta
   subyacente en tiempo real contra las tablas base en su estado exacto actual.
*/


-- =====================================================================
-- PARTE B · El tablero de producción
-- =====================================================================

-- B1. Creación de v_produccion_lote
DROP VIEW IF EXISTS v_produccion_lote;

CREATE VIEW v_produccion_lote AS
SELECT f.nombre AS finca,
       lo.codigo AS lote,
       lo.hectareas,
       COUNT(c.cosecha_id) AS n_cosechas,
       ROUND(SUM(c.kg), 2) AS kg_total,
       ROUND(SUM(c.kg) / (lo.hectareas * 1.0), 2) AS kg_ha
FROM fincas f
JOIN lotes lo ON lo.finca_id = f.finca_id
JOIN siembras s ON s.lote_id = lo.lote_id
JOIN cosechas c ON c.siembra_id = s.siembra_id
GROUP BY f.nombre, lo.codigo, lo.hectareas;

-- Verificación B1: Esperado 6 filas
SELECT * FROM v_produccion_lote;


-- B2. Creación de v_produccion_finca usando v_produccion_lote
DROP VIEW IF EXISTS v_produccion_finca;

CREATE VIEW v_produccion_finca AS
SELECT finca,
       COUNT(lote) AS lotes,
       ROUND(SUM(kg_total), 2) AS kg,
       ROUND(SUM(kg_total) / SUM(hectareas * 1.0), 2) AS kg_ha
FROM v_produccion_lote
GROUP BY finca;

-- Verificación B2: Esperado 3 filas
SELECT * FROM v_produccion_finca;

/*
RESPUESTA B2:
- JOINs explícitos escritos en B2: 0 (cero).
- Tablas reales sobre las que corre: Corre por debajo sobre 4 tablas
  ('fincas', 'lotes', 'siembras' y 'cosechas'), que son las que componen
  la vista base 'v_produccion_lote'.
*/


-- B3. La vista sigue a los datos
SELECT kg_total, n_cosechas, kg_ha 
FROM v_produccion_lote
WHERE finca LIKE 'Hacienda%' AND lote = 'L-01';

INSERT INTO cosechas (siembra_id, fecha, kg, calidad, destino)
VALUES (1, '2026-05-02', 500, 'primera', 'mercado local');

SELECT kg_total, n_cosechas, kg_ha 
FROM v_produccion_lote
WHERE finca LIKE 'Hacienda%' AND lote = 'L-01';

DELETE FROM cosechas WHERE fecha = '2026-05-02';

/*
RESPUESTA B3:
El número cambió sin hacer UPDATE porque la vista no almacena datos precalculados,
sino que guarda la pregunta; al consultar la vista, SQLite vuelve a hacer la
pregunta directamente sobre las tablas base, leyendo los datos nuevos insertados.
*/


-- B4. La trampa del IF NOT EXISTS
-- CREATE VIEW IF NOT EXISTS v_produccion_lote AS SELECT 1 AS chiste;
-- SELECT * FROM v_produccion_lote;

/*
RESPUESTA B4:
- ¿Dio error?: No, la sentencia se ejecutó sin errores.
- ¿Qué devolvió?: Devolvió la estructura y filas originales de 'v_produccion_lote'.
- Explicación: SQLite detectó que la vista ya existía e ignoró silenciosamente el nuevo
  CREATE. Esto es más peligroso que un error porque oculta fallos de despliegue o cambios
  de versión sin advertir al administrador que el nuevo código fue descartado.
*/


-- =====================================================================
-- PARTE C · El tablero que ya estaba publicado
-- =====================================================================

-- C1. Conteo de filas en v_temp_diaria
SELECT COUNT(*) FROM v_temp_diaria;

/*
HIPÓTESIS C1:
Los 5 días adicionales provienen de lecturas pertenecientes a otro mes o a otro
sensor (como el sensor 3 que operó en febrero antes de su baja), mezcladas por
falta de filtros de fecha o de estado activo.
*/


-- C2. Auditoría de la definición
-- SELECT sql FROM sqlite_master WHERE type = 'view';

/*
RESPUESTA C2:
1. Filtro del WHERE: Filtra exclusivamente 's.tipo = "temperatura"'. No filtra por
   estado del sensor ('s.activo = 1') ni por rango de fechas/mes.
2. Sensores de temperatura existentes:
   - Sensor 1: activo = 1 (lecturas en abril de 2026).
   - Sensor 3: activo = 0 (lecturas en febrero de 2026).
   - Sensor 5: activo = 0 (sin lecturas registradas).
   Son 3 sensores de temperatura en total.
3. Origen de los 5 días extra: Provienen del Sensor 3, que tiene 40 lecturas tomadas
   entre el 4 y el 8 de febrero de 2026 (5 días de febrero).
*/


-- C3. Ranking con vista tal como está
SELECT dia,
       temp_promedio,
       RANK() OVER (ORDER BY temp_promedio DESC) AS ranking
FROM v_temp_diaria;

/*
RESPUESTA C3:
De los 10 días empatados en el segundo puesto (25.63), exactamente 5 corresponden
al sensor inactivo de febrero. Un tablero con este top 10 está mintiendo, ya que
mezcla temporadas climáticas distintas y revive métricas de un sensor dado de baja.
*/


-- C4. El segundo problema (sesgo en promedio)
/*
RESPUESTA C4:
1. ¿Puede alguien darse cuenta solo con esta vista?: No, porque solo expone 'dia' y
   'temp_promedio', ocultando cuántas mediciones componen ese promedio.
2. Columna de una sola palabra que habría alcanzado: 'lecturas' (o 'n_lecturas' / 'conteo' mediante COUNT(*)).
3. Duración del error: En una consulta suelta dura una sola ejecución; en una vista dura
   meses o años de forma permanente, propagándose a todos los reportes dependientes.
*/


-- C5. Creación de v_temp_diaria_v2 corregida
DROP VIEW IF EXISTS v_temp_diaria_v2;

CREATE VIEW v_temp_diaria_v2 AS
SELECT s.sensor_id,
       DATE(l.fecha_hora) AS dia,
       COUNT(*) AS lecturas,
       ROUND(AVG(l.valor), 2) AS temp_promedio
FROM lecturas l
JOIN sensores s ON s.sensor_id = l.sensor_id
WHERE s.tipo = 'temperatura'
  AND s.activo = 1
GROUP BY s.sensor_id, DATE(l.fecha_hora);

-- Verificación C5: Esperado 30 filas
SELECT * FROM v_temp_diaria_v2 ORDER BY temp_promedio DESC;

/*
RESPUESTA C5:
El 20 de abril sigue primero porque su promedio aritmético real de ese día fue 27.33.
No se alteró la matemática del dato, sino que se arregló la transparencia: ahora el
tablero muestra que ese promedio se calculó con solo 6 lecturas en lugar de las 8 normales.
*/


-- C6. Pregunta de gestión y arquitectura
/*
RESPUESTA C6:
1. Si se reemplaza bruscamente la vista: Los reportes, ETLs o queries dependientes que
   hagan 'SELECT dia, temp_promedio' por posición ordinal o esquemas rígidos fallarán
   o romperán dashboards en producción a las 7 AM.
2. Cambio en los promedios: Se explica formalmente que el promedio mensual anterior estaba
   contaminado con datos residuales de sensores inactivos de febrero, y que el valor actual
   refleja fielmente la operación real de los sensores activos de abril.
3. Estrategia adecuada: Publicar primero 'v_temp_diaria_v2', notificar formalmente el plan de
   deprecación a los consumidores de datos, dar un periodo de migración y luego retirar la v1.
*/


-- C7. Auditoría de v_alertas_sensores
SELECT COUNT(*) 
FROM lecturas l 
JOIN sensores s ON s.sensor_id = l.sensor_id
WHERE (s.tipo = 'temperatura' AND l.valor > 28)
   OR (s.tipo = 'humedad' AND l.valor < 60)
   OR (s.tipo = 'radiacion' AND l.valor > 800);

/*
RESPUESTA C7:
La vista 'v_alertas_sensores' está CORRECTAMENTE ESCRITA. Incluye de forma explícita
el predicado 'WHERE s.activo = 1', descartando con éxito las 10 lecturas anómalas
del sensor inactivo 3 y conservando únicamente las 93 alertas operativas válidas.
*/


-- =====================================================================
-- PARTE D · Lo que una vista no puede, y lo que sí puede esconder
-- =====================================================================

-- D1. Escritura sobre vista agregada
/*
INTENTO DE ESCRITURA:
INSERT INTO v_produccion_lote VALUES ('x','y',1,1,1,1);
-- Error: cannot modify v_produccion_lote because it is a view

UPDATE v_produccion_lote SET kg_total = 0;
-- Error: cannot modify v_produccion_lote because it is a view

RESPUESTA D1:
'kg_total' es un SUM(cosechas.kg); para asignarle 8000, SQLite tendría que inventar
cómo distribuir arbitrariamente ese valor entre múltiples registros individuales de la
tabla base, lo cual es matemáticamente indeterminado sin un trigger INSTEAD OF.
*/


-- D2. Indexación sobre vistas
/*
INTENTO DE ÍNDICE:
CREATE INDEX ix_kgha ON v_produccion_lote(kg_ha);
-- Error: views may not be indexed

RESPUESTA D2:
No, una vista estándar no hace la consulta más rápida. SQLite ejecuta la consulta
completa con sus JOINs y agregaciones cada vez que se consulta la vista.
*/


-- D3. Validación diferida de esquemas
/*
CREATE VIEW v_fantasma AS SELECT * FROM tabla_que_no_existe; -- Ejecuta correctamente
SELECT * FROM v_fantasma; -- Error: no such table: tabla_que_no_existe

RESPUESTA D3:
SQLite valida la existencia de los objetos referenciados en tiempo de ejecución (al consultar),
no al momento del CREATE VIEW. Si se renombra una tabla base, decenas de vistas dependientes
quedarán rotas silenciosamente hasta que una consulta de usuario falle en producción.
*/


-- D4. El fan-out heredado y vista v_costo_siembra
/*
RESPUESTA D4:
1. ¿Por qué 455 y no 335?: Por fan-out relacional. La siembra 1 tiene una labor con 2 insumos,
   duplicando la fila de esa labor al hacer JOIN y sumando su mano de obra dos veces.
2. ¿Qué siembras desaparecieron?: Las siembras 9 y 10 desaparecieron debido al INNER JOIN
   con 'labores', ya que aún no registran labores realizadas.
*/

DROP VIEW IF EXISTS v_costo_siembra;

CREATE VIEW v_costo_siembra AS
WITH mo AS (
    SELECT siembra_id,
           SUM(costo_mano_obra) AS total_mo
    FROM labores
    GROUP BY siembra_id
),
ins AS (
    SELECT la.siembra_id,
           SUM(li.cantidad * li.costo_unitario) AS total_ins
    FROM labores la
    JOIN labor_insumo li ON li.labor_id = la.labor_id
    GROUP BY la.siembra_id
)
SELECT si.siembra_id,
       f.nombre AS finca,
       lo.codigo AS lote,
       COALESCE(mo.total_mo, 0) AS costo_mano_obra,
       COALESCE(ins.total_ins, 0) AS costo_insumos,
       ROUND(COALESCE(mo.total_mo, 0) + COALESCE(ins.total_ins, 0), 2) AS costo_total
FROM siembras si
JOIN lotes lo ON lo.lote_id = si.lote_id
JOIN fincas f ON f.finca_id = lo.finca_id
LEFT JOIN mo ON mo.siembra_id = si.siembra_id
LEFT JOIN ins ON ins.siembra_id = si.siembra_id;

-- Verificación D4: Debe dar exactamente 3562.30 y 10 filas
SELECT ROUND(SUM(costo_total), 2) AS control_total FROM v_costo_siembra;
SELECT COUNT(*) AS total_siembras FROM v_costo_siembra;


-- =====================================================================
-- PARTE E · Cierre
-- =====================================================================

/*
RESPUESTA E1:
Una CTE vive únicamente durante el tiempo de ejecución de la sentencia que la contiene,
mientras que una vista persiste de forma permanente en el catálogo de la base de datos.

RESPUESTA E2:
Porque la vista encapsula la lógica interna y devuelve una tabla limpia y válida a la vista;
el usuario confía ciegamente en el resultado final sin ver los filtros faltantes ni las duplicaciones subyacentes.

RESPUESTA E3 (Reglas para publicar vistas):
1. Regla de Nomenclatura: El nombre debe reflejar fielmente el grano y alcance real del reporte (ej. 'v_temp_diaria_sensores_activos' y nunca nombres ambiguos).
2. Regla de Trazabilidad: Ningún promedio o valor agregado se publica sin incluir el COUNT(*) del soporte muestral y el identificador de la entidad origen.
3. Regla de Blindaje contra Fan-Out: Las agregaciones de relaciones uno-a-muchos independientes deben precalcularse por separado antes de realizar JOINs entre sí.
*/


-- =====================================================================
-- EXTRA · Vista de Negocio Propia
-- Pregunta de negocio: ¿Cuál es el margen de rendimiento económico por
-- siembra (Kilos cosechados vs Costo total invertido)?
-- =====================================================================

DROP VIEW IF EXISTS v_rendimiento_economico_siembra;

CREATE VIEW v_rendimiento_economico_siembra AS
WITH cos AS (
    SELECT siembra_id,
           SUM(kg) AS kg_cosechados,
           COUNT(cosecha_id) AS n_cosechas
    FROM cosechas
    GROUP BY siembra_id
)
SELECT cs.siembra_id,
       cs.finca,
       cs.lote,
       c.nombre AS cultivo,
       si.estado AS estado_siembra,
       COALESCE(cos.kg_cosechados, 0) AS kg_totales,
       cs.costo_total,
       CASE 
           WHEN COALESCE(cos.kg_cosechados, 0) > 0 
           THEN ROUND(cs.costo_total / (cos.kg_cosechados * 1.0), 2)
           ELSE NULL 
       END AS costo_por_kg
FROM v_costo_siembra cs
JOIN siembras si ON si.siembra_id = cs.siembra_id
JOIN cultivos c ON c.cultivo_id = si.cultivo_id
LEFT JOIN cos ON cos.siembra_id = cs.siembra_id;

/*
JUSTIFICACIÓN:
Responde directamente a la necesidad de controlar la eficiencia del gasto agrícola por kilogramo producido.
Merece ser vista y no consulta suelta porque reutiliza la capa 'v_costo_siembra' evitando duplicar lógica contable,
proporcionando un indicador clave para auditorías agronómicas y decisiones de siembra en ciclos posteriores.
*/