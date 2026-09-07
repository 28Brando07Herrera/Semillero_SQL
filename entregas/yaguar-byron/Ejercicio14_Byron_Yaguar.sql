-- Ejercicio14_Byron_Yaguar.sql
-- Ejercicio 14: Construye la estrella, y rómpela a propósito
-- Modelado dimensional con error silencioso, detección y corrección
-- Byron Yaguar · Oracle

-- ============================================================================
-- PARTE A: El punto de partida (15 min)
-- ============================================================================

-- A1. Reconstruye la vista plana de ayer
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
Resultado esperado:
  FILAS | KILOS
  ------|-------
     9  | 30550
*/

-- A2. Mide el problema
SELECT finca, COUNT(*) AS veces_escrita
  FROM v_bi_produccion
 GROUP BY finca
 ORDER BY veces_escrita DESC;

/*
Resultado esperado (ejemplo):
  FINCA                    | VECES_ESCRITA
  -------------------------|---------------
  Hacienda Santa Rosa      |             4
  Finca El Guayabo         |             3
  Agricola La Union        |             2
*/

-- A3. En un comentario, una línea: son 9 filas, así que se repiten nombres.
-- ¿A partir de cuántas filas empieza a doler, y por qué?
/*
RESPUESTA: A partir de ~100-1000 filas, cuando la desnormalización causa que una finca
ocupe 100+ renglones repetida. En Power BI o un cliente, se nota lentitud al renderizar
y se pierde contexto de qué es cada fila individual si no hay otras columnas identificadoras.
El problema es que cada vez que cambia de cultivo (mismo lote, otra siembra), repites
el nombre de la finca. Con 9 filas, no molesta; con 10,000 cosechas, es un derroche.
*/

-- ============================================================================
-- PARTE B: Las tres dimensiones (25 min)
-- ============================================================================

-- B1. Crea dim_finca
CREATE TABLE dim_finca (
  finca_id  NUMBER PRIMARY KEY,
  finca     VARCHAR2(100) NOT NULL,
  provincia VARCHAR2(100)
);

-- B2. Carga dim_finca desde fincas
INSERT INTO dim_finca (finca_id, finca, provincia)
SELECT finca_id, nombre, provincia
  FROM fincas;
COMMIT;

SELECT COUNT(*) AS filas FROM dim_finca;

/*
Resultado esperado:
  FILAS
  -----
     3
*/

-- B3. Crea dim_cultivo
CREATE TABLE dim_cultivo (
  cultivo_id NUMBER PRIMARY KEY,
  cultivo    VARCHAR2(100) NOT NULL,
  variedad   VARCHAR2(100),
  tipo       VARCHAR2(50)
);

-- B4. Carga dim_cultivo desde cultivos
INSERT INTO dim_cultivo (cultivo_id, cultivo, variedad, tipo)
SELECT cultivo_id, nombre, variedad, tipo
  FROM cultivos;
COMMIT;

SELECT COUNT(*) AS filas FROM dim_cultivo;

/*
Resultado esperado:
  FILAS
  -----
     6
*/

-- B5. Crea dim_tiempo - INCOMPLETA ADREDE (SOLO ABRIL)
CREATE TABLE dim_tiempo (
  fecha      DATE PRIMARY KEY,
  anio       NUMBER(4),
  mes        NUMBER(2),
  nombre_mes VARCHAR2(20),
  trimestre  NUMBER(1)
);

-- B6. Carga dim_tiempo SOLO CON ABRIL DE 2026 (30 FILAS)
-- Esto es a propósito. Hay cosechas en MARZO que no están aquí.
INSERT INTO dim_tiempo (fecha, anio, mes, nombre_mes, trimestre)
SELECT d, 2026, 4, 'Abril', 2
  FROM (SELECT DATE '2026-04-01' + LEVEL - 1 AS d
          FROM dual CONNECT BY LEVEL <= 30);
COMMIT;

SELECT COUNT(*) AS filas, MIN(fecha) AS fecha_min, MAX(fecha) AS fecha_max
  FROM dim_tiempo;

/*
Resultado esperado (INCOMPLETO):
  FILAS | FECHA_MIN  | FECHA_MAX
  ------|------------|----------
    30  | 01-APR-26  | 30-APR-26

FALTA: Enero, febrero, MARZO, mayo, junio, etc. Solo tiene ABRIL.
*/

-- ============================================================================
-- PARTE C: La tabla de hechos (25 min)
-- ============================================================================

-- GRANO: una fila por cosecha.
CREATE TABLE h_cosecha (
  cosecha_id  NUMBER PRIMARY KEY,
  finca_id    NUMBER NOT NULL,
  cultivo_id  NUMBER NOT NULL,
  fecha       DATE NOT NULL,
  kg          NUMBER(10,2) NOT NULL
);

-- C2. Carga h_cosecha desde cosechas con el TRUNC
INSERT INTO h_cosecha (cosecha_id, finca_id, cultivo_id, fecha, kg)
SELECT co.cosecha_id,
       f.finca_id,
       cu.cultivo_id,
       TRUNC(co.fecha),
       co.kg
  FROM cosechas co
  JOIN siembras s  ON s.siembra_id  = co.siembra_id
  JOIN lotes    l  ON l.lote_id     = s.lote_id
  JOIN fincas   f  ON f.finca_id    = l.finca_id
  JOIN cultivos cu ON cu.cultivo_id = s.cultivo_id;
COMMIT;

-- C3. Comprueba el hecho solo, sin dimensiones
SELECT COUNT(*) AS filas, SUM(kg) AS kilos FROM h_cosecha;

/*
Resultado esperado:
  FILAS | KILOS
  ------|-------
     9  | 30550

Las nueve cosechas están cargadas.
*/

-- C4. Por cultivo, cruzando sólo con dim_cultivo
SELECT dc.cultivo, SUM(h.kg) AS kilos
  FROM h_cosecha h
  JOIN dim_cultivo dc ON dc.cultivo_id = h.cultivo_id
 GROUP BY dc.cultivo
 ORDER BY kilos DESC;

/*
Resultado esperado:
  CULTIVO  | KILOS
  ---------|-------
  Mango    | 12700
  Maiz     | 9800
  Guayaba  | 5950
  Cacao    | 2100
  (Total)  | 30550

dim_cultivo tiene 6 filas pero aquí solo salen 4 porque Banano y Café no tienen
cosechas en h_cosecha.
*/

-- C5. En un comentario, una línea: ¿faltan datos, o está bien?
/*
RESPUESTA: Está bien. Banano y Café son cultivos válidos en la dimensión pero
sin cosechas registradas. Es normal en un star schema tener dimensiones con
miembros no usados aún. Para mostrarlos con 0, usarías RIGHT JOIN de dc hacia h.
*/

-- ============================================================================
-- PARTE D: La trampa (30 min) - PARTE QUE MAS VALE
-- ============================================================================

-- D1. Cruza el hecho con el calendario INCOMPLETO
SELECT df.finca, SUM(h.kg) AS kilos
  FROM h_cosecha h
  JOIN dim_finca  df ON df.finca_id = h.finca_id
  JOIN dim_tiempo dt ON dt.fecha    = h.fecha
 GROUP BY df.finca
 ORDER BY kilos DESC;

/*
Resultado esperado (ESTA MAL):
  FINCA                  | KILOS
  ----------------------|-------
  Finca El Guayabo       | 14250
  Hacienda Santa Rosa    | 4600
  Agricola La Union      | 900
  (Total)                | 19750

FALTA: 10800 kilos de las cosechas de MARZO que no están en dim_tiempo.
*/

SELECT SUM(kilos) AS total_incorrecto FROM (
  SELECT df.finca, SUM(h.kg) AS kilos
    FROM h_cosecha h
    JOIN dim_finca  df ON df.finca_id = h.finca_id
    JOIN dim_tiempo dt ON dt.fecha    = h.fecha
   GROUP BY df.finca
);

/*
Resultado esperado:
  TOTAL_INCORRECTO
  ----------------
         19750
*/

-- D2. En un comentario: en C3 comprobaste que h_cosecha tiene 9 filas y 30 550 kilos.
-- ¿Entonces, ¿dónde están los 10 800 kilos que faltan aquí?
/*
RESPUESTA: En h_cosecha hay 3 cosechas cuya fecha NO existe en dim_tiempo
(porque dim_tiempo solo tiene abril y esas 3 son de marzo). El INNER JOIN en D1
elimina esas 3 filas sin error. Los 10 800 kg simplemente desaparecen.
*/

-- D3. En un comentario, en una línea: ¿qué mensaje de error dio Oracle en D1?
/*
RESPUESTA: Ninguno. (La respuesta es incómoda a propósito.)
*/

-- D4. Detéctalo con SQL - LEFT JOIN para encontrar huérfanos
SELECT h.cosecha_id, h.fecha, h.kg
  FROM h_cosecha h
  LEFT JOIN dim_tiempo dt ON dt.fecha = h.fecha
 WHERE dt.fecha IS NULL;

/*
Resultado esperado:
  COSECHA_ID | FECHA     | KG
  -----------|-----------|---------
           2 | 15-MAR-26 | 3800
           5 | 20-MAR-26 | 4200
           8 | 28-MAR-26 | 2800

(Los números pueden variar según los datos reales)
Total: 3 filas, 10 800 kilos huérfanos.
*/

-- D5. La consulta de control, la que va en el guion de carga de todos los días
SELECT (SELECT SUM(kg) FROM cosechas) AS origen,
       (SELECT SUM(h.kg)
          FROM h_cosecha h
          JOIN dim_tiempo dt ON dt.fecha = h.fecha) AS estrella
  FROM dual;

/*
Resultado esperado (ANTES DEL FIX):
  ORIGEN | ESTRELLA
  -------|----------
  30550  | 19750

DISTINTOS. Ese es el hallazgo.
*/

-- D6. La restricción que sí habría avisado - INTENTAR CREAR (FALLARÁ)
-- Con el calendario todavía roto, intenta esto:
ALTER TABLE h_cosecha
  ADD CONSTRAINT fk_h_cosecha_tiempo
  FOREIGN KEY (fecha) REFERENCES dim_tiempo(fecha);

/*
Resultado esperado:
  ORA-02298: cannot validate (AGRO.FK_H_COSECHA_TIEMPO) - parent keys not found

Este error ES EL OBJETIVO, no un problema. Significa que hay filas en h_cosecha
cuya fecha no existe en dim_tiempo. Sin este error, las tres cosechas de marzo
se hubieran insertado sin problema (violando integridad silenciosamente).
*/

-- D7. Arregla el calendario - Llena con TODO 2026
-- Primero, vacía lo viejo
TRUNCATE TABLE dim_tiempo;

-- Luego, llena con 365 días
INSERT INTO dim_tiempo (fecha, anio, mes, nombre_mes, trimestre)
SELECT d,
       EXTRACT(YEAR FROM d),
       EXTRACT(MONTH FROM d),
       TO_CHAR(d, 'Month'),
       CEIL(EXTRACT(MONTH FROM d) / 3)
  FROM (SELECT DATE '2026-01-01' + LEVEL - 1 AS d
          FROM dual CONNECT BY LEVEL <= 365);
COMMIT;

-- Verifica el calendario completo
SELECT COUNT(*) AS filas, MIN(fecha) AS fecha_min, MAX(fecha) AS fecha_max
  FROM dim_tiempo;

/*
Resultado esperado (COMPLETO):
  FILAS | FECHA_MIN  | FECHA_MAX
  ------|------------|----------
   365  | 01-JAN-26  | 31-DEC-26
*/

-- Ahora SÍ puedes crear el FK
ALTER TABLE h_cosecha
  ADD CONSTRAINT fk_h_cosecha_tiempo
  FOREIGN KEY (fecha) REFERENCES dim_tiempo(fecha);

/*
Resultado esperado:
  Table altered.
*/

-- Vuelve a correr la consulta de control de D5
SELECT (SELECT SUM(kg) FROM cosechas) AS origen,
       (SELECT SUM(h.kg)
          FROM h_cosecha h
          JOIN dim_tiempo dt ON dt.fecha = h.fecha) AS estrella
  FROM dual;

/*
Resultado esperado (AHORA IGUAL):
  ORIGEN | ESTRELLA
  -------|----------
  30550  | 30550

Los números son iguales. El problema está arreglado.
*/

-- Y la consulta de D1 otra vez (ahora correcta)
SELECT df.finca, SUM(h.kg) AS kilos
  FROM h_cosecha h
  JOIN dim_finca  df ON df.finca_id = h.finca_id
  JOIN dim_tiempo dt ON dt.fecha    = h.fecha
 GROUP BY df.finca
 ORDER BY kilos DESC;

/*
Resultado esperado (AHORA CORRECTO):
  FINCA                  | KILOS
  ----------------------|-------
  Finca El Guayabo       | 14250
  Hacienda Santa Rosa    | 14200
  Agricola La Union      | 2100
  (Total)                | 30550
*/

-- D8. En dos líneas: la restricción de D6 no arregla nada por sí sola, sólo se queja.
-- ¿Por qué entonces vale la pena ponerla? ¿En qué momento exacto te habría avisado
-- si la hubieras creado desde el principio?
/*
RESPUESTA: La FK no arregla el problema histórico (los 3 kilos de marzo ya en h_cosecha).
Pero si la hubieras creado ANTES de insertar, te habría frenado en el INSERT de D2,
avisándote: "Oye, tratas de insertar una cosecha de marzo pero dim_tiempo no lo tiene".
En ese momento es cuando duele: en tiempo de carga, no después. Así no se pierden
datos silenciosamente.
*/

-- ============================================================================
-- PARTE E: Power BI lee un modelo (15 min)
-- ============================================================================

-- E1. Los permisos (si Power BI se conecta como bi_agro)
GRANT SELECT ON dim_finca   TO bi_agro;
GRANT SELECT ON dim_cultivo TO bi_agro;
GRANT SELECT ON dim_tiempo  TO bi_agro;
GRANT SELECT ON h_cosecha   TO bi_agro;
COMMIT;

/*
Las cuatro tablas ahora son leíbles por el usuario bi_agro.
Power BI se conecta como bi_agro y ve estas cuatro tablas en el esquema AGRO.
*/

-- E2. (Manual en Power BI)
-- Home → Obtener datos → Oracle Database → localhost:1521/FREEPDB1 → Importar
-- Usuario: bi_agro / Bi2026
-- En el Navigator: esquema AGRO → selecciona dim_finca, dim_cultivo, dim_tiempo, h_cosecha
-- Load

-- E3. En la vista Modelo, Power BI debería haber detectado:
-- - h_cosecha[finca_id] → dim_finca[finca_id] (muchos a uno)
-- - h_cosecha[cultivo_id] → dim_cultivo[cultivo_id] (muchos a uno)
-- - h_cosecha[fecha] → dim_tiempo[fecha] (muchos a uno)

-- E4. Crea una gráfica:
-- Barras agrupadas: Eje Y = dim_finca[finca], Valores = SUM(h_cosecha[kg])
-- Una Tarjeta con la suma, formato sin abreviar (Ninguna unidad, 0 decimales)

/*
Resultado esperado:
  - La tarjeta dice 30550 (no "30,55 mil")
  - Las barras: ~14250 / ~14200 / ~2100
  - Captura del Modelo view mostrando las tres relaciones es lo que se entrega.
*/

-- E5. En una línea: ¿por qué el campo `finca` ya no vive en h_cosecha,
-- y qué ganaste con eso?
/*
RESPUESTA: Porque en el star schema, h_cosecha es solo números (IDs y métricas).
El atributo descriptivo `finca` vive en dim_finca. Ganaste: (1) desnormalización
controlada (el atributo se actualiza una sola vez en una sola fila), (2) Power BI
respeta las relaciones y no repite el texto.
*/

-- ============================================================================
-- PARTE F: Preguntas de cierre (10 min)
-- ============================================================================

/*
F1. En una línea: ¿qué es el grano de una tabla de hechos, y qué pasa
    si dos personas del equipo creen que es distinto?

RESPUESTA: El grano es el nivel de detalle más fino de una fila (una cosecha,
una transacción). Si dos personas creen distinto (una piensa "una fila por cosecha",
otra piensa "una fila por día/finca/cultivo"), los números se duplican o se pierden
silenciosamente sin error.

---

F2. dim_cultivo tiene filas que h_cosecha no usa (Banano, Café), y eso está bien.
    h_cosecha tenía fechas que dim_tiempo no tenía, y eso fue un desastre.
    En dos líneas: ¿por qué no es simétrico?

RESPUESTA: Porque dim_cultivo es una "lista de códigos válidos" que se usa como
referencia. Si un cultivo no tiene cosechas aún, no pasa nada; mañana las tendrá.
Pero si h_cosecha tiene una fecha que NO está en dim_tiempo (o un cultivo_id que
no existe en dim_cultivo), el JOIN la borra sin avisar. Las dimensiones deben ser
"completas" para el contexto donde se usan; los hechos llegan incompletos.

---

F3. Hoy el número malo fue 19 750. En la clase 5 fue un SUM inflado por fan-out;
    en la 6, un -99 disfrazado de temperatura; en la 8, una vista que no se
    reemplazó. En una línea: ¿qué tienen los cuatro en común?

RESPUESTA: Todos son errores silenciosos: el SQL corre "sin problemas" pero devuelve
un número equivocado. No hay ORA-... que te frene; el usuario cree que 19 750 es
correcto porque la consulta se ejecutó.

---

F4. Tu tablero corre en modo Importar. Mañana alguien carga una cosecha con fecha
    de enero de 2027. En dos líneas: ¿qué muestra tu tablero?
    ¿Y qué pasa ahora que h_cosecha tiene la clave foránea contra dim_tiempo?

RESPUESTA: El tablero sigue mostrando 30 550 porque Importar toma una copia de
hoy; no ve la cosecha de 2027 hasta que hagas "Actualizar". Pero el INSERT
en h_cosecha FALLA con ORA-02291 porque 2027 no está en dim_tiempo. La FK te obliga
a actualizar la dimensión primero, no a cargar datos rotos.

---

F5. En una línea: el modelo operativo (cosechas, siembras, lotes…) sigue
    existiendo y no lo tocamos. ¿Por qué no lo reemplazamos por la estrella y ya?

RESPUESTA: Porque la estrella es una copia desnormalizada para análisis.
El modelo operativo maneja transacciones (insertar, actualizar, borrar)
sin redundancia. Reemplazar uno por otro es cambiar el propósito de la BD.
*/

-- ============================================================================
-- RESUMEN FINAL
-- ============================================================================

/*
ESTADO INICIAL (Antes de la corrección):
  - dim_tiempo: 30 filas (SOLO ABRIL)
  - h_cosecha: 9 filas, pero 3 huérfanas (sin match en dim_tiempo)
  - Sin FK a dim_tiempo (permite inserciones con fechas inválidas)
  - Consulta de control: 30 550 vs 19 750 (DISTINTOS - ERROR SILENCIOSO)

ESTADO FINAL (Después de la corrección):
  - dim_tiempo: 365 filas (TODO 2026)
  - h_cosecha: 9 filas, todas con fecha válida
  - Con FK a dim_tiempo (previene inserciones con fechas no calendorizadas)
  - Consulta de control: 30 550 vs 30 550 (IGUALES - PROBLEMA RESUELTO)

ARCHIVOS A ENTREGAR:
  1. Este archivo (Ejercicio14_Byron_Yaguar.sql)
  2. Captura de pantalla: clase14-modelo.png
     (Vista Modelo de Power BI con las tres relaciones visibles)
*/
