/*==================================*======================
  EJERCICIO*14
  BRANDO MANUEL HERRERA DIAZ
==*======================================================*/


/*=============================*===========================
  PARTE A
=========================================================*/

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

SELECT COUNT(*) AS filas,
       SUM(kg) AS kilos
FROM v_bi_produccion;

/*
FILAS  KILOS
9      30550
*/


SELECT finca,
       COUNT(*) AS veces_escrita
FROM v_bi_produccion
GROUP BY finca
ORDER BY veces_escrita DESC;

/*

Hacienda Santa Rosa   4
Finca El Guayabo      3
Agricola La Union     2

*/


-- A3
-- Empieza a doler cuando existen miles o millones de filas,
-- porque los mismos nombres se almacenan y procesan muchas veces,
-- aumentando espacio y tiempo de consulta.



/*=========================================================
  PARTE B
=========================================================*/

CREATE TABLE dim_finca (
  finca_id NUMBER PRIMARY KEY,
  finca VARCHAR2(60) NOT NULL,
  provincia VARCHAR2(40) NOT NULL
);

CREATE TABLE dim_cultivo (
  cultivo_id NUMBER PRIMARY KEY,
  cultivo VARCHAR2(40) NOT NULL,
  variedad VARCHAR2(40),
  tipo VARCHAR2(20) NOT NULL
);

CREATE TABLE dim_tiempo (
  fecha DATE PRIMARY KEY,
  anio NUMBER(4) NOT NULL,
  mes NUMBER(2) NOT NULL,
  nombre_mes VARCHAR2(20) NOT NULL,
  trimestre NUMBER(1) NOT NULL
);


INSERT INTO dim_finca (finca_id, finca, provincia)
SELECT finca_id, nombre, provincia
FROM fincas;

INSERT INTO dim_cultivo (cultivo_id, cultivo, variedad, tipo)
SELECT cultivo_id, nombre, variedad, tipo
FROM cultivos;

COMMIT;


SELECT COUNT(*) FROM dim_finca;
/*
3
*/

SELECT COUNT(*) FROM dim_cultivo;
/*
6
*/


/* Cargar calendario MAL a propósito */

INSERT INTO dim_tiempo (fecha, anio, mes, nombre_mes, trimestre)
SELECT d, 2026, 4, 'Abril', 2
FROM (
    SELECT DATE '2026-04-01' + LEVEL - 1 AS d
    FROM dual
    CONNECT BY LEVEL <= 30
);

COMMIT;


SELECT COUNT(*) FROM dim_tiempo;
/*
30
*/


/*=========================================================
  PARTE C
=========================================================*/

-- GRANO: una fila por cosecha.

CREATE TABLE h_cosecha (
  cosecha_id NUMBER PRIMARY KEY,
  finca_id NUMBER NOT NULL,
  cultivo_id NUMBER NOT NULL,
  fecha DATE NOT NULL,
  calidad VARCHAR2(20) NOT NULL,
  kg NUMBER(10,2) NOT NULL
);


INSERT INTO h_cosecha
(cosecha_id, finca_id, cultivo_id, fecha, calidad, kg)
SELECT co.cosecha_id,
       f.finca_id,
       cu.cultivo_id,
       TRUNC(co.fecha),
       co.calidad,
       co.kg
FROM cosechas co
JOIN siembras s  ON s.siembra_id = co.siembra_id
JOIN lotes l     ON l.lote_id = s.lote_id
JOIN fincas f    ON f.finca_id = l.finca_id
JOIN cultivos cu ON cu.cultivo_id = s.cultivo_id;

COMMIT;


SELECT COUNT(*) AS filas,
       SUM(kg) AS kilos
FROM h_cosecha;

/*
FILAS  KILOS
9      30550
*/


SELECT dc.cultivo,
       SUM(h.kg) AS kilos
FROM h_cosecha h
JOIN dim_cultivo dc
ON dc.cultivo_id = h.cultivo_id
GROUP BY dc.cultivo
ORDER BY kilos DESC;

/*

Mango      12700
Maiz        9800
Guayaba     5950
Cacao       2100

*/


-- C5
-- No faltan datos.
-- Banano y Café existen en la dimensión pero aún no tienen cosechas.
-- Para mostrarlos con 0 se podría usar LEFT JOIN.



/*=========================================================
  PARTE D
=========================================================*/

SELECT df.finca,
       SUM(h.kg) AS kilos
FROM h_cosecha h
JOIN dim_finca  df ON df.finca_id = h.finca_id
JOIN dim_tiempo dt ON dt.fecha = h.fecha
GROUP BY df.finca
ORDER BY kilos DESC;

/*

Finca El Guayabo      14250
Hacienda Santa Rosa    4600
Agricola La Union       900

TOTAL 19750

*/


-- D2
-- Los 10800 kg faltantes corresponden a cosechas de marzo.
-- No existen fechas de marzo en dim_tiempo.


-- D3
-- Oracle no mostró ningún error.
-- La consulta devolvió un resultado incorrecto sin advertencias.


SELECT h.cosecha_id,
       h.fecha,
       h.kg
FROM h_cosecha h
LEFT JOIN dim_tiempo dt
ON dt.fecha = h.fecha
WHERE dt.fecha IS NULL;

/*

1  20-MAR-26  4200
3  22-MAR-26  5400
8  28-MAR-26  1200

TOTAL 10800

*/


SELECT (SELECT SUM(kg) FROM cosechas) AS origen,
       (SELECT SUM(h.kg)
          FROM h_cosecha h
          JOIN dim_tiempo dt
            ON dt.fecha = h.fecha) AS estrella
FROM dual;

/*

ORIGEN  ESTRELLA
30550   19750

*/


ALTER TABLE h_cosecha
ADD CONSTRAINT fk_h_cosecha_tiempo
FOREIGN KEY (fecha)
REFERENCES dim_tiempo(fecha);

/*

ORA-02298

cannot validate (AGRODB.FK_H_COSECHA_TIEMPO)
parent keys not found

*/


DELETE FROM dim_tiempo;
COMMIT;


INSERT INTO dim_tiempo
(fecha, anio, mes, nombre_mes, trimestre)
SELECT d,
       EXTRACT(YEAR FROM d),
       EXTRACT(MONTH FROM d),
       TO_CHAR(d,'Month'),
       TO_NUMBER(TO_CHAR(d,'Q'))
FROM (
    SELECT DATE '2026-01-01' + LEVEL - 1 AS d
    FROM dual
    CONNECT BY LEVEL <= 365
);

COMMIT;


SELECT COUNT(*) FROM dim_tiempo;

/*
365
*/


ALTER TABLE h_cosecha
ADD CONSTRAINT fk_h_cosecha_tiempo
FOREIGN KEY (fecha)
REFERENCES dim_tiempo(fecha);

/*
Table altered.
*/


SELECT (SELECT SUM(kg) FROM cosechas) AS origen,
       (SELECT SUM(h.kg)
          FROM h_cosecha h
          JOIN dim_tiempo dt
            ON dt.fecha = h.fecha) AS estrella
FROM dual;

/*

30550   30550

*/


SELECT df.finca,
       SUM(h.kg) AS kilos
FROM h_cosecha h
JOIN dim_finca df ON df.finca_id = h.finca_id
JOIN dim_tiempo dt ON dt.fecha = h.fecha
GROUP BY df.finca
ORDER BY kilos DESC;

/*

Finca El Guayabo      14250
Hacienda Santa Rosa   14200
Agricola La Union      2100

TOTAL 30550

*/


-- D8
-- La clave foránea no corrige datos.
-- Su utilidad es detectar el problema inmediatamente e impedir cargas inconsistentes.



/*=========================================================
  PARTE E
=========================================================*/

CONNECT SYSTEM/Agrodb2026@localhost:1521/FREEPDB1;

CREATE USER bi_agro IDENTIFIED BY Bi2026;

GRANT CREATE SESSION TO bi_agro;


CONNECT AGRODB/Agrodb2026@localhost:1521/FREEPDB1;

GRANT SELECT ON dim_finca TO bi_agro;
GRANT SELECT ON dim_cultivo TO bi_agro;
GRANT SELECT ON dim_tiempo TO bi_agro;
GRANT SELECT ON h_cosecha TO bi_agro;


/*=========================================================
  PARTE F
=========================================================*/

-- F1
-- El grano define qué representa una fila de la tabla de hechos.
-- Si el equipo no comparte el mismo grano, los cálculos serán inconsistentes.

-- F2
-- Una dimensión puede tener filas sin hechos asociados.
-- Lo peligroso es tener hechos sin dimensión porque se pierden registros al hacer JOIN.

-- F3
-- Todos los casos producen resultados incorrectos que parecen válidos si no existen controles.

-- F4
-- En modo Importar el tablero mostrará los datos de la última actualización.
-- La clave foránea impide cargar fechas inexistentes en dim_tiempo.

-- F5
-- El modelo operativo sirve para registrar transacciones.
-- El modelo estrella está optimizado para análisis y reportes, por lo que no reemplaza al sistema operativo.