-- =============================================================================
-- Ejercicio Práctico 14 · Construye la estrella, y rómpela a propósito
-- Estudiante: Troya Daniel
-- Esquema: agro
-- =============================================================================

-- -----------------------------------------------------------------------------
-- PUNTO DE CONTROL 0: Ejecución del script agrodb_oracle_clase14.sql
-- -----------------------------------------------------------------------------
/*
Los doce números de control:
3, 6, 8, 10, 7, 19, 16, 6, 9, 8640, 0, 0

Reparto por mes:
2026-03    3 cosechas    10800 kilos
2026-04    6 cosechas    19750 kilos
*/


-- =============================================================================
-- PARTE A · El punto de partida
-- =============================================================================

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

-- Punto de control 1
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
FINCA                                                        VECES_ESCRITA
------------------------------------------------------------ -------------
Hacienda Santa Rosa                                                      4
Finca El Guayabo                                                         3
Agricola La Union                                                        2
*/

-- A3. Pregunta:
-- Empieza a doler a partir de decenas de miles o millones de filas, porque repetir texto desnormalizado consume almacenamiento innecesario en disco y memoria RAM, ralentizando los agrupamientos en comparación con claves numéricas.


-- =============================================================================
-- PARTE B · Las tres dimensiones
-- =============================================================================

-- B1. Crear tablas de dimensiones
CREATE TABLE dim_finca (
    finca_id  NUMBER PRIMARY KEY,
    finca     VARCHAR2(60) NOT NULL,
    provincia VARCHAR2(40) NOT NULL
);

CREATE TABLE dim_cultivo (
    cultivo_id NUMBER PRIMARY KEY,
    cultivo    VARCHAR2(40) NOT NULL,
    variedad   VARCHAR2(40),
    tipo       VARCHAR2(20) NOT NULL
);

CREATE TABLE dim_tiempo (
    fecha      DATE PRIMARY KEY,
    anio       NUMBER(4) NOT NULL,
    mes        NUMBER(2) NOT NULL,
    nombre_mes VARCHAR2(20) NOT NULL,
    trimestre  NUMBER(1) NOT NULL
);

-- B2. Cargar fincas y cultivos
INSERT INTO dim_finca (finca_id, finca, provincia)
SELECT finca_id, nombre, provincia FROM fincas;

INSERT INTO dim_cultivo (cultivo_id, cultivo, variedad, tipo)
SELECT cultivo_id, nombre, variedad, tipo FROM cultivos;
COMMIT;

-- B3. Cargar calendario incompleto (solo abril de 2026, mal a propósito)
INSERT INTO dim_tiempo (fecha, anio, mes, nombre_mes, trimestre)
SELECT d, 2026, 4, 'Abril', 2
  FROM (SELECT DATE '2026-04-01' + LEVEL - 1 AS d
          FROM dual CONNECT BY LEVEL <= 30);
COMMIT;

-- Punto de control 2
SELECT 'dim_finca' AS tabla, COUNT(*) AS filas FROM dim_finca
UNION ALL SELECT 'dim_cultivo', COUNT(*) FROM dim_cultivo
UNION ALL SELECT 'dim_tiempo', COUNT(*) FROM dim_tiempo;
/*
TABLA            FILAS
----------- ----------
dim_finca            3
dim_cultivo          6
dim_tiempo          30
*/


-- =============================================================================
-- PARTE C · La tabla de hechos
-- =============================================================================

-- C1. Crear h_cosecha
-- GRANO: una fila por cosecha individual realizada.
CREATE TABLE h_cosecha (
    cosecha_id NUMBER PRIMARY KEY,
    finca_id   NUMBER NOT NULL,
    cultivo_id NUMBER NOT NULL,
    fecha      DATE NOT NULL,
    kg         NUMBER(10,2) NOT NULL,
    calidad    VARCHAR2(20)
);

-- C2. Cargar hechos
INSERT INTO h_cosecha (cosecha_id, finca_id, cultivo_id, fecha, kg, calidad)
SELECT co.cosecha_id,
       f.finca_id,
       cu.cultivo_id,
       TRUNC(co.fecha),
       co.kg,
       co.calidad
  FROM cosechas co
  JOIN siembras s  ON s.siembra_id  = co.siembra_id
  JOIN lotes    l  ON l.lote_id     = s.lote_id
  JOIN fincas   f  ON f.finca_id    = l.finca_id
  JOIN cultivos cu ON cu.cultivo_id = s.cultivo_id;
COMMIT;

-- C3. Comprobación del hecho solo
SELECT COUNT(*) AS filas, SUM(kg) AS kilos FROM h_cosecha;
/*
     FILAS      KILOS
---------- ----------
         9      30550
*/

-- C4. Agregación por cultivo
SELECT dc.cultivo, SUM(h.kg) AS kilos
  FROM h_cosecha h
  JOIN dim_cultivo dc ON dc.cultivo_id = h.cultivo_id
 GROUP BY dc.cultivo
 ORDER BY kilos DESC;
/*
CULTIVO                                       KILOS
---------------------------------------- ----------
Mango                                         12700
Maiz                                           9800
Guayaba                                        5950
Cacao                                          2100
*/

-- C5. Pregunta:
-- Está bien, no faltan datos: no hubo cosechas para Banano ni Café. Para que aparezcan con 0, habría que hacer un RIGHT JOIN desde h_cosecha a dim_cultivo (o LEFT JOIN desde dim_cultivo) y usar NVL(SUM(h.kg), 0).


-- =============================================================================
-- PARTE D · La trampa y su solución
-- =============================================================================

-- D1. Cruce con el calendario incompleto (error silencioso: 19 750)
SELECT df.finca, SUM(h.kg) AS kilos
  FROM h_cosecha h
  JOIN dim_finca  df ON df.finca_id = h.finca_id
  JOIN dim_tiempo dt ON dt.fecha    = h.fecha
 GROUP BY df.finca
 ORDER BY kilos DESC;
/*
FINCA                                                             KILOS
------------------------------------------------------------ ----------
Finca El Guayabo                                                  14250
Hacienda Santa Rosa                                                4600
Agricola La Union                                                   900
*/

-- Total de D1
SELECT SUM(kilos) AS total
  FROM (
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

-- D2. Pregunta:
-- Los 10 800 kg están en h_cosecha en las 3 cosechas de marzo. Al hacer INNER JOIN con dim_tiempo (que solo tiene abril), Oracle las descartó silenciosamente.

-- D3. Pregunta:
-- Ninguno. Oracle no dio ningún error porque el JOIN relacional es sintácticamente válido.

-- D4. Detectar las filas huérfanas
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

-- D5. Control de cuadratura
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

-- D6. Intentar crear la Foreign Key con datos faltantes
ALTER TABLE h_cosecha
  ADD CONSTRAINT fk_h_cosecha_tiempo
  FOREIGN KEY (fecha) REFERENCES dim_tiempo(fecha);
/*
ERROR at line 2:
ORA-02298: cannot validate (AGRO.FK_H_COSECHA_TIEMPO) - parent keys not found
Help: https://docs.oracle.com/error-help/db/ora-02298/
*/

-- D7. Arreglar dim_tiempo con todo 2026
DELETE FROM dim_tiempo;

INSERT INTO dim_tiempo (fecha, anio, mes, nombre_mes, trimestre)
SELECT d,
       2026,
       TO_NUMBER(TO_CHAR(d, 'MM')),
       TO_CHAR(d, 'Month'),
       TO_NUMBER(TO_CHAR(d, 'Q'))
  FROM (SELECT DATE '2026-01-01' + LEVEL - 1 AS d
          FROM dual CONNECT BY LEVEL <= 365);
COMMIT;

-- Validar filas de dim_tiempo (365)
SELECT COUNT(*) AS filas_tiempo FROM dim_tiempo;
/*
FILAS_TIEMPO
------------
         365
*/

-- Reintentar la Foreign Key
ALTER TABLE h_cosecha
  ADD CONSTRAINT fk_h_cosecha_tiempo
  FOREIGN KEY (fecha) REFERENCES dim_tiempo(fecha);
/*
Table altered.
*/

-- Reejecutar control de cuadratura (D5)
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

-- Reejecutar desglose por finca (D1)
SELECT df.finca, SUM(h.kg) AS kilos
  FROM h_cosecha h
  JOIN dim_finca  df ON df.finca_id = h.finca_id
  JOIN dim_tiempo dt ON dt.fecha    = h.fecha
 GROUP BY df.finca
 ORDER BY kilos DESC;
/*
FINCA                                                             KILOS
------------------------------------------------------------ ----------
Finca El Guayabo                                                  14250
Hacienda Santa Rosa                                               14200
Agricola La Union                                                  2100
*/

-- D8. Pregunta:
-- Vale la pena porque garantiza integridad referencial en el motor de base de datos. Si hubiera estado desde el inicio, habría abortado con error ORA-02291 en el momento exacto del INSERT en h_cosecha (C2).


-- =============================================================================
-- PARTE E · Power BI lee un modelo
-- =============================================================================

-- E1. Conceder permisos
GRANT SELECT ON dim_finca   TO bi_agro;
GRANT SELECT ON dim_cultivo TO bi_agro;
GRANT SELECT ON dim_tiempo  TO bi_agro;
GRANT SELECT ON h_cosecha   TO bi_agro;

-- E5. Pregunta:
-- No vive en h_cosecha para normalizar la dimensión y evitar redundancia. Ganamos ahorro de espacio en la tabla de hechos y poder actualizar o enriquecer atributos de la finca en un único lugar.


-- =============================================================================
-- PARTE F · Preguntas de cierre
-- =============================================================================

-- F1: El grano es el nivel atómico de detalle que representa una fila en la tabla de hechos. Si dos personas creen que es distinto, se mezclarán niveles de agregación produciendo métricas infladas por doble conteo.

-- F2: Las dimensiones representan contextos posibles o catálogos maestros (que pueden no tener transacciones asociadas), mientras que los hechos son eventos reales obligados a tener contexto; perder la dimensión del hecho corrompe la medición.

-- F3: Los cuatro son errores silenciosos: no arrojan ningún error de sintaxis ni de motor y muestran resultados que aparentan ser correctos pero son falsos.

-- F4: El tablero mostrará los datos desactualizados hasta que se ejecute la actualización/refresh en Power BI. En Oracle, la FK impedirá la inserción con un error ORA-02291 porque el año 2027 no existe en dim_tiempo.

-- F5: Porque el modelo operativo está normalizado (OLTP) para transacciones rápidas, integridad y concurrencia de escritura diaria, mientras que el modelo estrella (OLAP) está optimizado exclusivamente para lecturas y consultas analíticas de BI.