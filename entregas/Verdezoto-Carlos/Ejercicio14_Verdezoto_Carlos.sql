-- =====================================================================
-- CURSO DE SQL | AgroDB sobre Oracle | Ejercicio 14
-- Alumno: [Tu Apellido], [Tu Nombre]
-- Fecha: 07/09/2026
-- =====================================================================

-- =====================================================================
-- PUNTO DE CONTROL 0 - VERIFICACIÓN INICIAL
-- =====================================================================

SELECT 'fincas' AS tabla, COUNT(*) AS filas FROM fincas
UNION ALL SELECT 'cultivos',       COUNT(*) FROM cultivos
UNION ALL SELECT 'lotes',          COUNT(*) FROM lotes
UNION ALL SELECT 'siembras',       COUNT(*) FROM siembras
UNION ALL SELECT 'insumos',        COUNT(*) FROM insumos
UNION ALL SELECT 'labores',        COUNT(*) FROM labores
UNION ALL SELECT 'labor_insumo',   COUNT(*) FROM labor_insumo
UNION ALL SELECT 'sensores',       COUNT(*) FROM sensores
UNION ALL SELECT 'cosechas',       COUNT(*) FROM cosechas
UNION ALL SELECT 'lecturas',       COUNT(*) FROM lecturas
UNION ALL SELECT 'resumen_diario', COUNT(*) FROM resumen_diario
UNION ALL SELECT 'bitacora',       COUNT(*) FROM bitacora;

/*
TABLA            FILAS
------------ ---------
fincas               3
cultivos             6
lotes                8
siembras            10
insumos              7
labores             19
labor_insumo        16
sensores             6
cosechas             9
lecturas          8640
resumen_diario       0
bitacora             0
*/

SELECT TO_CHAR(fecha,'YYYY-MM') AS mes,
       COUNT(*)                 AS cosechas,
       SUM(kg)                  AS kilos
  FROM cosechas
 GROUP BY TO_CHAR(fecha,'YYYY-MM')
 ORDER BY mes;

/*
MES          COSECHAS     KILOS
---------- ---------- ---------
2026-03             3     10800
2026-04             6     19750
*/


-- =====================================================================
-- PARTE A · EL PUNTO DE PARTIDA
-- =====================================================================

-- A1. Reconstruye la vista plana
CREATE OR REPLACE VIEW v_bi_produccion AS
SELECT f.nombre     AS finca,
       l.codigo     AS lote,
       cu.nombre    AS cultivo,
       s.estado     AS estado_siembra,
       co.fecha     AS fecha_cosecha,
       co.calidad   AS calidad,
       co.kg        AS kg
  FROM cosechas co
  JOIN siembras s  ON s.siembra_id  = co.siembra_id
  JOIN lotes    l  ON l.lote_id     = s.lote_id
  JOIN fincas   f  ON f.finca_id    = l.finca_id
  JOIN cultivos cu ON cu.cultivo_id = s.cultivo_id;

SELECT COUNT(*) AS filas, SUM(kg) AS kilos FROM v_bi_produccion;

/*
     FILAS      KILOS
---------- ----------
         9      30550
*/

-- A2. Mide el problema
SELECT finca, COUNT(*) AS veces_escrita
  FROM v_bi_produccion
 GROUP BY finca
 ORDER BY veces_escrita DESC;

/*
FINCA               VECES_ESCRITA
------------------ --------------
Hacienda Santa Rosa             4
Finca El Guayabo                3
Agricola La Union               2
*/

-- A3. Respuesta:
-- Empieza a doler a partir de miles o millones de filas, ya que la redundancia de texto incrementa exponencialmente el uso de almacenamiento en disco, la transferencia de memoria/red y penaliza el rendimiento al procesar agrupaciones pesadas.


-- =====================================================================
-- PARTE B · LAS TRES DIMENSIONES
-- =====================================================================

-- B1. Créalas
CREATE TABLE dim_finca (
  finca_id  NUMBER       PRIMARY KEY,
  finca     VARCHAR2(60) NOT NULL,
  provincia VARCHAR2(40) NOT NULL
);

CREATE TABLE dim_cultivo (
  cultivo_id NUMBER       PRIMARY KEY,
  cultivo    VARCHAR2(40) NOT NULL,
  variedad   VARCHAR2(40),
  tipo       VARCHAR2(20) NOT NULL
);

CREATE TABLE dim_tiempo (
  fecha      DATE         PRIMARY KEY,
  anio       NUMBER(4)    NOT NULL,
  mes        NUMBER(2)    NOT NULL,
  nombre_mes VARCHAR2(20) NOT NULL,
  trimestre  NUMBER(1)    NOT NULL
);

-- B2. Carga las dos fáciles
INSERT INTO dim_finca (finca_id, finca, provincia)
SELECT finca_id, nombre, provincia FROM fincas;

INSERT INTO dim_cultivo (cultivo_id, cultivo, variedad, tipo)
SELECT cultivo_id, nombre, variedad, tipo FROM cultivos;

COMMIT;

-- B3. Carga el calendario MAL a propósito (Solo Abril 2026)
INSERT INTO dim_tiempo (fecha, anio, mes, nombre_mes, trimestre)
SELECT d, 2026, 4, 'Abril', 2
  FROM (SELECT DATE '2026-04-01' + LEVEL - 1 AS d
          FROM dual CONNECT BY LEVEL <= 30);
COMMIT;

-- Punto de Control 2:
SELECT 'dim_finca' AS tabla, COUNT(*) AS filas FROM dim_finca
UNION ALL SELECT 'dim_cultivo', COUNT(*) FROM dim_cultivo
UNION ALL SELECT 'dim_tiempo', COUNT(*) FROM dim_tiempo;

/*
TABLA             FILAS
------------ ----------
dim_finca             3
dim_cultivo           6
dim_tiempo           30
*/


-- =====================================================================
-- PARTE C · LA TABLA DE HECHOS
-- =====================================================================

-- C1. Crea h_cosecha
-- GRANO: una fila por cosecha.
CREATE TABLE h_cosecha (
  cosecha_id NUMBER       PRIMARY KEY,
  finca_id   NUMBER       NOT NULL,
  cultivo_id NUMBER       NOT NULL,
  fecha      DATE         NOT NULL,
  kg         NUMBER(10,2) NOT NULL
);

-- C2. Cárgala
INSERT INTO h_cosecha (cosecha_id, finca_id, cultivo_id, fecha, kg)
SELECT co.cosecha_id,
       l.finca_id,
       s.cultivo_id,
       TRUNC(co.fecha),
       co.kg
  FROM cosechas co
  JOIN siembras s ON s.siembra_id = co.siembra_id
  JOIN lotes l    ON l.lote_id    = s.lote_id;
COMMIT;

-- C3. Comprueba el hecho solo
SELECT COUNT(*) AS filas, SUM(kg) AS kilos FROM h_cosecha;

/*
     FILAS      KILOS
---------- ----------
         9      30550
*/

-- C4. Cruzando sólo con dim_cultivo
SELECT dc.cultivo, SUM(h.kg) AS kilos
  FROM h_cosecha h
  JOIN dim_cultivo dc ON dc.cultivo_id = h.cultivo_id
 GROUP BY dc.cultivo
 ORDER BY kilos DESC;

/*
CULTIVO         KILOS
---------- ----------
Mango           12700
Maiz             9800
Guayaba          5950
Cacao            2100
*/

-- C5. Respuesta:
-- Está bien. Al usar INNER JOIN, solo se muestran las dimensiones con coincidencias en hechos. Para incluir Banano y Café con 0 kg habría que usar un LEFT JOIN desde dim_cultivo hacia h_cosecha y aplicar NVL/COALESCE(SUM(h.kg), 0).


-- =====================================================================
-- PARTE D · LA TRAMPA (El hallazgo)
-- =====================================================================

-- D1. Cruza el hecho con el calendario roto
SELECT df.finca, SUM(h.kg) AS kilos
  FROM h_cosecha h
  JOIN dim_finca  df ON df.finca_id = h.finca_id
  JOIN dim_tiempo dt ON dt.fecha    = h.fecha
 GROUP BY df.finca
 ORDER BY kilos DESC;

/*
FINCA                    KILOS
------------------- ----------
Finca El Guayabo         14250
Hacienda Santa Rosa       4600
Agricola La Union          900
*/

SELECT SUM(kilos) AS total FROM (
  SELECT SUM(h.kg) AS kilos
    FROM h_cosecha h
    JOIN dim_finca  df ON df.finca_id = h.finca_id
    JOIN dim_tiempo dt ON dt.fecha    = h.fecha
   GROUP BY df.finca
);

/*
     TOTAL
----------
     19750
*/

-- D2. Respuesta:
-- Los 10 800 kg faltantes corresponden a las cosechas ocurridas en el mes de marzo de 2026, las cuales fueron descartadas por el INNER JOIN dado que dim_tiempo únicamente contenía fechas de abril.

-- D3. Respuesta:
-- Oracle no dio absolutamente ningún mensaje de error; la consulta ejecutó exitosamente devolviendo un resultado lógicamente incorrecto pero sintácticamente válido.

-- D4. Detéctalo con SQL
SELECT h.cosecha_id, h.fecha, h.kg
  FROM h_cosecha h
  LEFT JOIN dim_tiempo dt ON dt.fecha = h.fecha
 WHERE dt.fecha IS NULL;

/*
COSECHA_ID FECHA             KG
---------- --------- ----------
         1 20-MAR-26       4200
         3 22-MAR-26       5400
         8 28-MAR-26       1200
*/

-- D5. Consulta de control
SELECT (SELECT SUM(kg) FROM cosechas) AS origen,
       (SELECT SUM(h.kg)
          FROM h_cosecha h
          JOIN dim_tiempo dt ON dt.fecha = h.fecha) AS estrella
  FROM dual;

/*
    ORIGEN   ESTRELLA
---------- ----------
     30550      19750
*/

-- D6. Restricción para validar integridad
ALTER TABLE h_cosecha
  ADD CONSTRAINT fk_h_cosecha_tiempo
  FOREIGN KEY (fecha) REFERENCES dim_tiempo(fecha);

/*
Error que empieza en la línea: 198 del comando -
ALTER TABLE h_cosecha
  ADD CONSTRAINT fk_h_cosecha_tiempo
  FOREIGN KEY (fecha) REFERENCES dim_tiempo(fecha)
Informe de errores -
ORA-02298: cannot validate (AGRO.FK_H_COSECHA_TIEMPO) - parent keys not found
02298. 00000 - "cannot validate (%s.%s) - parent keys not found"
*Cause:    An alter table validating constraint failed because the table has
           child records.
*Action:   Obtain the missing parent key values or delete the child records.
*/

-- D7. Arregla el calendario
DELETE FROM dim_tiempo;

INSERT INTO dim_tiempo (fecha, anio, mes, nombre_mes, trimestre)
SELECT d,
       TO_NUMBER(TO_CHAR(d, 'YYYY')),
       TO_NUMBER(TO_CHAR(d, 'MM')),
       TO_CHAR(d, 'Month', 'NLS_DATE_LANGUAGE=Spanish'),
       TO_NUMBER(TO_CHAR(d, 'Q'))
  FROM (SELECT DATE '2026-01-01' + LEVEL - 1 AS d
          FROM dual CONNECT BY LEVEL <= 365);
COMMIT;

-- Reintentar ALTER TABLE y consulta de control
ALTER TABLE h_cosecha
  ADD CONSTRAINT fk_h_cosecha_tiempo
  FOREIGN KEY (fecha) REFERENCES dim_tiempo(fecha);

/*
Table H_COSECHA altered.
*/

SELECT (SELECT SUM(kg) FROM cosechas) AS origen,
       (SELECT SUM(h.kg)
          FROM h_cosecha h
          JOIN dim_tiempo dt ON dt.fecha = h.fecha) AS estrella
  FROM dual;

/*
    ORIGEN   ESTRELLA
---------- ----------
     30550      30550
*/

SELECT df.finca, SUM(h.kg) AS kilos
  FROM h_cosecha h
  JOIN dim_finca  df ON df.finca_id = h.finca_id
  JOIN dim_tiempo dt ON dt.fecha    = h.fecha
 GROUP BY df.finca
 ORDER BY kilos DESC;

/*
FINCA                    KILOS
------------------- ----------
Finca El Guayabo         14250
Hacienda Santa Rosa      14200
Agricola La Union         2100
*/

-- D8. Respuesta:
-- Vale la pena porque garantiza integridad referencial a nivel de base de datos.
-- Te habría avisado en el momento exacto en que intentaste cargar la tabla de hechos (C2) mediante un error ORA-02291, impidiendo el ingreso de datos huérfanos antes de que lleguen a los tableros analíticos.


-- =====================================================================
-- PARTE E · POWER BI LEE UN MODELO
-- =====================================================================

-- E1. Conceder permisos
GRANT SELECT ON dim_finca   TO bi_agro;
GRANT SELECT ON dim_cultivo TO bi_agro;
GRANT SELECT ON dim_tiempo  TO bi_agro;
GRANT SELECT ON h_cosecha   TO bi_agro;

/*
Grant succeeded.
Grant succeeded.
Grant succeeded.
Grant succeeded.
*/

-- E5. Respuesta:
-- No vive en la tabla de hechos para mantener la tabla liviana y evitar redundancia. Se gana la capacidad de actualizar atributos de dimensiones en un solo lugar sin alterar millones de registros de hechos, mejorando el rendimiento y consumo de almacenamiento.


-- =====================================================================
-- PARTE F · PREGUNTAS DE CIERRE
-- =====================================================================

-- 1) ¿Qué es el grano y qué pasa si el equipo no concuerda?
-- El grano define el nivel de detalle de cada registro en la tabla de hechos. Si hay ambigüedad, el equipo combinará niveles de agregación erróneos (ej. filas por día con filas por mes), generando multiplicaciones de valores (fan-out) o duplicación de indicadores.

-- 2) ¿Por qué la falta de simetría entre dimensiones sin uso y hechos huérfanos?
-- Una dimensión representa entidades de contexto que pueden no haber registrado eventos todavía (lo cual es normal). En cambio, un hecho sin dimensión es un evento sin contexto de análisis, lo que provoca la pérdida invisible de datos al cruzar las tablas con INNER JOIN.

-- 3) ¿Qué tienen en común los cuatro errores analíticos vistos?
-- Todos son errores silenciosos: la sintaxis SQL se ejecuta perfectamente y las consultas entregan respuestas válidas sin arrojar ningún aviso o fallo técnico, ocultando cifras de negocio completamente erróneas.

-- 4) Cosecha de enero de 2027 sin actualizar dim_tiempo:
-- Power BI mostrará un valor desactualizado o incompleto al no incluir la nueva cosecha por la falta del registro en la dimensión tiempo. La FK impedirá la inserción en h_cosecha lanzando un error ORA-02291 al intentar cargar el hecho.

-- 5) ¿Por qué mantener el modelo operativo y no reemplazarlo por el modelo estrella?
-- El modelo operativo (OLTP) está optimizado para transacciones rápidas, escrituras concurrentes e integridad de datos sin redundancia. El modelo estrella (OLAP) está optimizado para consultas analíticas pesadas y lectura eficiente. Cada uno cumple un propósito arquitectónico distinto.