-- EJERCICIO PRÁCTICO 14: Construye la estrella, y rómpela a propósito
-- Estudiante: Axel Cortez
-- Motor: Oracle Database 23ai (FreeSQL)
-- 

-- ============================================================================
-- PUNTO DE CONTROL 0: Verificación inicial del script base
-- ============================================================================

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
TABLA          | FILAS
---------------+------
fincas         |     3
cultivos       |     6
lotes          |     8
siembras       |    10
insumos        |     7
labores        |    19
labor_insumo   |    16
sensores       |     6
cosechas       |     9
lecturas       |  8640
resumen_diario |     0
bitacora       |     0
*/

SELECT TO_CHAR(fecha,'YYYY-MM') AS mes,
       COUNT(*)                 AS cosechas,
       SUM(kg)                  AS kilos
  FROM cosechas
 GROUP BY TO_CHAR(fecha,'YYYY-MM')
 ORDER BY mes;

/*
MES     | COSECHAS | KILOS
--------+----------+-------
2026-03 |        3 | 10800
2026-04 |        6 | 19750
*/


-- ============================================================================
-- PARTE A · EL PUNTO DE PARTIDA
-- ============================================================================

-- A1. Reconstruir la vista plana
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
PUNTO DE CONTROL 1:
FILAS | KILOS
------+------
    9 | 30550
*/

-- A2. Repetición de cadenas en la vista desnormalizada
SELECT finca, COUNT(*) AS veces_escrita
  FROM v_bi_produccion
 GROUP BY finca
 ORDER BY veces_escrita DESC;

/*
FINCA               | VECES_ESCRITA
--------------------+--------------
Hacienda Santa Rosa |             4
Finca El Guayabo    |             3
Agricola La Union   |             2
*/

/*
COMENTARIO A3:
Empieza a doler a partir de decenas de miles o millones de filas, ya que repetir cadenas de texto largas consume espacio innecesario en disco, satura el ancho de banda al transferir datos y ralentiza los escaneos de memoria en consultas analíticas.
*/


-- ============================================================================
-- PARTE B · LAS TRES DIMENSIONES
-- ============================================================================

-- B1. Crear las tablas de dimensiones
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

-- B2. Cargar dim_finca y dim_cultivo
INSERT INTO dim_finca (finca_id, finca, provincia)
SELECT finca_id, nombre, provincia FROM fincas;

INSERT INTO dim_cultivo (cultivo_id, cultivo, variedad, tipo)
SELECT cultivo_id, nombre, variedad, tipo FROM cultivos;

COMMIT;

-- B3. Cargar el calendario INCOMPLETO a propósito (solo abril 2026)
INSERT INTO dim_tiempo (fecha, anio, mes, nombre_mes, trimestre)
SELECT d, 2026, 4, 'Abril', 2
  FROM (SELECT DATE '2026-04-01' + LEVEL - 1 AS d
          FROM dual CONNECT BY LEVEL <= 30);

COMMIT;

-- PUNTO DE CONTROL 2:
SELECT 'dim_finca' AS dim, COUNT(*) AS filas FROM dim_finca
UNION ALL SELECT 'dim_cultivo', COUNT(*) FROM dim_cultivo
UNION ALL SELECT 'dim_tiempo',  COUNT(*) FROM dim_tiempo;

/*
DIM         | FILAS
------------+------
dim_finca   |     3
dim_cultivo |     6
dim_tiempo  |    30
*/


-- ============================================================================
-- PARTE C · LA TABLA DE HECHOS
-- ============================================================================

-- GRANO: una fila por cosecha.
CREATE TABLE h_cosecha (
  cosecha_id NUMBER       PRIMARY KEY,
  finca_id   NUMBER       NOT NULL,
  cultivo_id NUMBER       NOT NULL,
  fecha      DATE         NOT NULL,
  calidad    VARCHAR2(20) NOT NULL,
  destino    VARCHAR2(40),
  kg         NUMBER(10,2) NOT NULL
);

-- C2. Cargar la tabla de hechos
INSERT INTO h_cosecha (cosecha_id, finca_id, cultivo_id, fecha, calidad, destino, kg)
SELECT co.cosecha_id,
       l.finca_id,
       s.cultivo_id,
       TRUNC(co.fecha),
       co.calidad,
       co.destino,
       co.kg
  FROM cosechas co
  JOIN siembras s ON s.siembra_id = co.siembra_id
  JOIN lotes l    ON l.lote_id    = s.lote_id;

COMMIT;

-- C3. Comprobar hechos sin dimensiones (PUNTO DE CONTROL 3)
SELECT COUNT(*) AS filas, SUM(kg) AS kilos FROM h_cosecha;

/*
FILAS | KILOS
------+------
    9 | 30550
*/

-- C4. Cruce exclusivo con dim_cultivo
SELECT dc.cultivo, SUM(h.kg) AS kilos
  FROM h_cosecha h
  JOIN dim_cultivo dc ON dc.cultivo_id = h.cultivo_id
 GROUP BY dc.cultivo
 ORDER BY kilos DESC;

/*
CULTIVO | KILOS
--------+------
Mango   | 12700
Maiz    |  9800
Guayaba |  5950
Cacao   |  2100
*/

/*
COMENTARIO C5:
Está bien porque sólo 4 cultivos tuvieron cosechas reales registradas en el período. Para que Banano y Café figuren con valor 0 habría que usar `RIGHT JOIN dim_cultivo dc ON dc.cultivo_id = h.cultivo_id` junto con `NVL(SUM(h.kg), 0)`.
*/


-- ============================================================================
-- PARTE D · LA TRAMPA (EL NÚMERO MALO DE 19 750)
-- ============================================================================

-- D1. Cruce con calendario incompleto (PUNTO DE CONTROL 4)
SELECT df.finca, SUM(h.kg) AS kilos
  FROM h_cosecha h
  JOIN dim_finca  df ON df.finca_id = h.finca_id
  JOIN dim_tiempo dt ON dt.fecha    = h.fecha
 GROUP BY df.finca
 ORDER BY kilos DESC;

/*
FINCA               | KILOS
--------------------+------
Finca El Guayabo    | 14250
Hacienda Santa Rosa |  4600
Agricola La Union   |   900
*/

SELECT SUM(kilos) AS total_incorrecto
  FROM (
    SELECT df.finca, SUM(h.kg) AS kilos
      FROM h_cosecha h
      JOIN dim_finca  df ON df.finca_id = h.finca_id
      JOIN dim_tiempo dt ON dt.fecha    = h.fecha
     GROUP BY df.finca
  );

/*
TOTAL_INCORRECTO
----------------
           19750
*/

/*
COMENTARIO D2:
Los 10 800 kilos que faltan corresponden a las 3 cosechas de marzo de 2026, las cuales fueron filtradas silenciosamente por el INNER JOIN debido a que `dim_tiempo` solo contenía fechas de abril.
*/

/*
COMENTARIO D3:
Oracle no dio absolutamente ningún mensaje de error; ejecutó la consulta con éxito reportando un cálculo falso.
*/

-- D4. Consulta de detección de huérfanos (PUNTO DE CONTROL 5)
SELECT h.cosecha_id, h.fecha, h.kg
  FROM h_cosecha h
  LEFT JOIN dim_tiempo dt ON dt.fecha = h.fecha
 WHERE dt.fecha IS NULL;

/*
COSECHA_ID | FECHA     | KG
-----------+-----------+-----
         1 | 2026-03-20| 4200
         3 | 2026-03-22| 5400
         8 | 2026-03-28| 1200
*/

-- D5. Control de cuadre diario: Origen vs Estrella
SELECT (SELECT SUM(kg) FROM cosechas) AS origen,
       (SELECT SUM(h.kg)
          FROM h_cosecha h
          JOIN dim_tiempo dt ON dt.fecha = h.fecha) AS estrella
  FROM dual;

/*
ORIGEN | ESTRELLA
-------+---------
 30550 |    19750
*/

-- D6. La restricción que sí avisa (PUNTO DE CONTROL 6)
-- Al ejecutar con el calendario roto:
-- ALTER TABLE h_cosecha ADD CONSTRAINT fk_h_cosecha_tiempo FOREIGN KEY (fecha) REFERENCES dim_tiempo(fecha);

/*
MENSAJE LITERAL OBTENIDO:
ORA-02298: cannot validate (AGRO.FK_H_COSECHA_TIEMPO) - parent keys not found
*/

-- D7. Reparar el calendario para todo el año 2026
DELETE FROM dim_tiempo;

INSERT INTO dim_tiempo (fecha, anio, mes, nombre_mes, trimestre)
SELECT d,
       TO_NUMBER(TO_CHAR(d, 'YYYY')),
       TO_NUMBER(TO_CHAR(d, 'MM')),
       TO_CHAR(d, 'Month'),
       TO_NUMBER(TO_CHAR(d, 'Q'))
  FROM (SELECT DATE '2026-01-01' + LEVEL - 1 AS d
          FROM dual CONNECT BY LEVEL <= 365);

COMMIT;

-- Creación exitosa de la FK (Table altered.)
ALTER TABLE h_cosecha
  ADD CONSTRAINT fk_h_cosecha_tiempo
  FOREIGN KEY (fecha) REFERENCES dim_tiempo(fecha);

-- Verificación de cuadre D5 corregido:
SELECT (SELECT SUM(kg) FROM cosechas) AS origen,
       (SELECT SUM(h.kg)
          FROM h_cosecha h
          JOIN dim_tiempo dt ON dt.fecha = h.fecha) AS estrella
  FROM dual;

/*
ORIGEN | ESTRELLA
-------+---------
 30550 |    30550
*/

-- D1 corregido (PUNTO DE CONTROL 7):
SELECT df.finca, SUM(h.kg) AS kilos
  FROM h_cosecha h
  JOIN dim_finca  df ON df.finca_id = h.finca_id
  JOIN dim_tiempo dt ON dt.fecha    = h.fecha
 GROUP BY df.finca
 ORDER BY kilos DESC;

/*
FINCA               | KILOS
--------------------+------
Finca El Guayabo    | 14250
Hacienda Santa Rosa | 14200
Agricola La Union   |  2100
*/

/*
COMENTARIO D8:
Vale la pena porque garantiza integridad referencial estricta a nivel de base de datos; si hubiera existido desde el inicio, nos habría alertado en el momento exacto del INSERT inicial en `h_cosecha` lanzando ORA-02291.
*/


-- ============================================================================
-- PARTE E · PERMISOS PARA POWER BI
-- ============================================================================

GRANT SELECT ON dim_finca   TO bi_agro;
GRANT SELECT ON dim_cultivo TO bi_agro;
GRANT SELECT ON dim_tiempo  TO bi_agro;
GRANT SELECT ON h_cosecha   TO bi_agro;

/*
COMENTARIO E5:
El campo 'finca' no vive en 'h_cosecha' porque se traslada a la dimensión 'dim_finca', normalizando el modelo estrella y evitando redundancia de cadenas en los hechos numéricos.
*/


-- ============================================================================
-- PARTE F · PREGUNTAS DE CIERRE
-- ============================================================================

/*
1. ¿Qué es el grano?:
Es el nivel atómico mínimo de detalle que representa una fila individual de la tabla de hechos; si el equipo difiere sobre él, las métricas se distorsionan por doble contabilización o agregaciones incoherentes.

2. ¿Por qué no es simétrico?:
No es simétrico porque una dimensión puede tener entidades maestras sin transacciones asociadas (como cultivos sin cosecha aún), pero un hecho no puede registrar un evento con una fecha inexistente sin perderse silenciosamente en los JOINs.

3. ¿Qué tienen en común?:
Que ninguno arrojó un error de sintaxis ni una excepción técnica en el motor SQL: devolvieron datos aparentemente sanos mientras distorsionaban la realidad del negocio en silencio.

4. Cosecha con fecha de enero de 2027:
El tablero en modo Importar ignorará la cosecha si la dimensión no la cubre; sin embargo, en la base de datos la inserción será abortada al instante con un error ORA-02291 gracias a la clave foránea `fk_h_cosecha_tiempo`.

5. ¿Por qué no reemplazar el modelo operativo?:
Porque el modelo transaccional normalizado (OLTP) está optimizado para inserciones concurrentes rápidas y cero anomalías de actualización, mientras que el modelo estrella (OLAP) está optimizado exclusivamente para lectura y agregación analítica.
*/