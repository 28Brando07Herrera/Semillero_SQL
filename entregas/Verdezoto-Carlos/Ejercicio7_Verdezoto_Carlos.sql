-- =====================================================================
-- CURSO DE SQL | AgroDB | Ejercicio practico 7
-- Alumno:
-- Fecha: 2026-08-18
--
-- Este archivo contiene las respuestas del Ejercicio 7.
-- Ejecutar DESPUES de Agronomia_clases1.sql, en la misma sesion SQLite.
-- =====================================================================

PRAGMA foreign_keys = ON;

-- =====================================================================
-- PARTE A - LO QUE GROUP BY NO PODIA
-- =====================================================================

-- A1. Cada labor con su costo de mano de obra y el total de mano de
-- obra de toda su siembra, sin colapsar las filas.
SELECT
    l.labor_id,
    l.siembra_id,
    l.tipo_labor,
    l.costo_mano_obra,
    SUM(l.costo_mano_obra) OVER (
        PARTITION BY l.siembra_id
    ) AS total_mano_obra_siembra
FROM labores AS l
ORDER BY l.siembra_id, l.labor_id;


-- A2. Mismo detalle, agregando el porcentaje de cada labor sobre
-- el total de mano de obra de su siembra.
SELECT
    l.labor_id,
    l.siembra_id,
    l.tipo_labor,
    l.costo_mano_obra,
    SUM(l.costo_mano_obra) OVER (
        PARTITION BY l.siembra_id
    ) AS total_mano_obra_siembra,
    ROUND(
        l.costo_mano_obra * 100.0 /
        SUM(l.costo_mano_obra) OVER (PARTITION BY l.siembra_id),
        1
    ) AS porcentaje
FROM labores AS l
ORDER BY l.siembra_id, l.labor_id;

/*
A3. GROUP BY siembra_id no sirve para conservar el detalle de cada labor:
al agrupar, varias labores de la misma siembra se convierten en una sola
fila y se pierde la identidad y el costo individual de cada labor. En
cambio, SUM(...) OVER (PARTITION BY siembra_id) calcula el total sobre el
grupo pero mantiene cada fila original.
*/


-- =====================================================================
-- PARTE B - RANKINGS
-- =====================================================================

-- B1. Ranking de lotes por rendimiento dentro de cada finca.
-- cantidad_filas indica cuántos lotes con cosecha participaron en el ranking.
WITH rendimiento AS (
    SELECT
        f.nombre AS finca,
        l.lote_id,
        l.codigo AS lote,
        ROUND(SUM(c.kg) * 1.0 / l.hectareas, 2) AS kg_ha
    FROM lotes AS l
    JOIN fincas AS f ON f.finca_id = l.finca_id
    JOIN siembras AS s ON s.lote_id = l.lote_id
    JOIN cosechas AS c ON c.siembra_id = s.siembra_id
    GROUP BY f.nombre, l.lote_id, l.codigo, l.hectareas
)
SELECT
    finca,
    lote,
    kg_ha,
    RANK() OVER (
        PARTITION BY finca
        ORDER BY kg_ha DESC
    ) AS puesto,
    COUNT(*) OVER (
        PARTITION BY finca
    ) AS cantidad_filas
FROM rendimiento
ORDER BY finca, puesto, lote;


-- B2. Promedio diario del sensor 1 en abril con ROW_NUMBER, RANK y
-- DENSE_RANK.
WITH diario AS (
    SELECT
        date(fecha_hora) AS dia,
        ROUND(AVG(valor), 2) AS prom
    FROM lecturas
    WHERE sensor_id = 1
      AND date(fecha_hora) BETWEEN '2026-04-01' AND '2026-04-30'
    GROUP BY date(fecha_hora)
)
SELECT
    dia,
    prom,
    ROW_NUMBER() OVER (ORDER BY prom DESC) AS row_number,
    RANK() OVER (ORDER BY prom DESC) AS rank,
    DENSE_RANK() OVER (ORDER BY prom DESC) AS dense_rank
FROM diario
ORDER BY prom DESC, dia;

/*
B2 - Respuestas:
1) RANK salta de 2 a 7 porque cinco dias comparten el puesto 2.
   DENSE_RANK no salta porque asigna rangos consecutivos a cada valor
   distinto: despues del 2 viene el 3.
2) DENSE_RANK muestra de un vistazo que existen 7 promedios distintos:
   el mayor rango es 7.
3) ROW_NUMBER no trata los empates como igualdad: obliga a cada fila a
   tener un numero diferente. Si solo se ordena por prom, el orden entre
   empatados no queda garantizado. Para hacerlo estable se debe agregar
   un desempate, por ejemplo ORDER BY prom DESC, dia.
*/


-- B3. Ranking auditado: promedio, cantidad de lecturas y las tres
-- funciones de numeracion.
WITH diario AS (
    SELECT
        date(fecha_hora) AS dia,
        ROUND(AVG(valor), 2) AS prom,
        COUNT(*) AS cantidad_lecturas
    FROM lecturas
    WHERE sensor_id = 1
      AND date(fecha_hora) BETWEEN '2026-04-01' AND '2026-04-30'
    GROUP BY date(fecha_hora)
)
SELECT
    dia,
    prom,
    cantidad_lecturas,
    ROW_NUMBER() OVER (ORDER BY prom DESC) AS row_number,
    RANK() OVER (ORDER BY prom DESC) AS rank,
    DENSE_RANK() OVER (ORDER BY prom DESC) AS dense_rank
FROM diario
ORDER BY prom DESC, dia;

/*
B3 - Respuestas:
1) El 20 de abril tiene 6 lecturas y el 19 de abril tiene 7.
2) No faltaron porque el sensor dejara de medir por si mismo: fueron
   lecturas que la limpieza anterior elimino de la base.
3) Las lecturas eliminadas eran de 21:00 del 19 y de 00:00 y 03:00 del 20.
   En el 20 se eliminaron dos valores bajos, por lo que el promedio quedó
   artificialmente elevado hasta 27.33.
4) NO. El 20 de abril no puede considerarse honestamente el dia mas
   caluroso: su primer puesto fue favorecido por la eliminacion de dos
   lecturas bajas. El ranking esta sesgado por la limpieza de datos.
*/


-- B4. Ranking solamente con dias que tienen las 8 lecturas.
-- Se conserva la cuenta de lecturas para auditar el universo del ranking.
WITH diario AS (
    SELECT
        date(fecha_hora) AS dia,
        ROUND(AVG(valor), 2) AS prom,
        COUNT(*) AS cantidad_lecturas
    FROM lecturas
    WHERE sensor_id = 1
      AND date(fecha_hora) BETWEEN '2026-04-01' AND '2026-04-30'
    GROUP BY date(fecha_hora)
),
completos AS (
    SELECT *
    FROM diario
    WHERE cantidad_lecturas = 8
)
SELECT
    dia,
    prom,
    cantidad_lecturas,
    RANK() OVER (ORDER BY prom DESC) AS puesto
FROM completos
ORDER BY prom DESC, dia;

/*
B4 - Respuesta:
Es una respuesta mas comparable, pero no es simplemente "la respuesta
correcta". Al descartar el 19 y el 20 perdemos justamente dos dias que
tenian datos incompletos y, por tanto, tambien perdemos informacion sobre
lo ocurrido con ellos. La comparacion de los 28 dias restantes es mas
justa, pero no representa los 30 dias completos de abril.
*/


-- B5. VERSION QUE NO FUNCIONA (intencional; NO ejecutarla en una corrida
-- limpia si se quiere evitar detener el script):
--
-- SELECT f.nombre AS finca, l.codigo AS lote,
--        RANK() OVER (
--            PARTITION BY f.nombre
--            ORDER BY SUM(c.kg) * 1.0 / l.hectareas DESC
--        ) AS puesto
-- FROM lotes l
-- JOIN fincas f ON f.finca_id = l.finca_id
-- JOIN siembras s ON s.lote_id = l.lote_id
-- JOIN cosechas c ON c.siembra_id = s.siembra_id
-- GROUP BY f.nombre, l.lote_id, l.codigo, l.hectareas
-- WHERE puesto = 1;
--
-- Error esperado en SQLite: near "WHERE": syntax error.
-- La razon es que WHERE debe aparecer antes de GROUP BY y, ademas, una
-- funcion de ventana no esta disponible para filtrar el conjunto en el
-- mismo nivel de consulta. La solucion es calcular la ventana en una CTE
-- y filtrar en el SELECT exterior.

WITH rendimiento_ranked AS (
    SELECT
        f.nombre AS finca,
        l.codigo AS lote,
        ROUND(SUM(c.kg) * 1.0 / l.hectareas, 2) AS kg_ha,
        ROW_NUMBER() OVER (
            PARTITION BY f.nombre
            ORDER BY SUM(c.kg) * 1.0 / l.hectareas DESC, l.codigo
        ) AS puesto,
        COUNT(*) OVER (
            PARTITION BY f.nombre
        ) AS cantidad_lotes
    FROM lotes AS l
    JOIN fincas AS f ON f.finca_id = l.finca_id
    JOIN siembras AS s ON s.lote_id = l.lote_id
    JOIN cosechas AS c ON c.siembra_id = s.siembra_id
    GROUP BY f.nombre, l.lote_id, l.codigo, l.hectareas
)
SELECT
    finca,
    lote,
    kg_ha,
    puesto,
    cantidad_lotes
FROM rendimiento_ranked
WHERE puesto = 1
ORDER BY finca;

/*
B5 - Explicacion:
El WHERE exterior ya puede ver puesto porque la funcion de ventana fue
calculada previamente dentro de la CTE. Se usa ROW_NUMBER porque se
solicita una sola fila por finca. El desempate por lote hace estable el
resultado si dos lotes tienen exactamente el mismo rendimiento.
*/


-- =====================================================================
-- PARTE C - MIRAR LA FILA DE AL LADO
-- =====================================================================

-- C1. Cada cosecha con la cosecha anterior de la misma siembra y delta.
SELECT
    siembra_id,
    fecha,
    kg,
    LAG(kg) OVER (
        PARTITION BY siembra_id
        ORDER BY fecha
    ) AS anterior,
    kg - LAG(kg) OVER (
        PARTITION BY siembra_id
        ORDER BY fecha
    ) AS delta
FROM cosechas
ORDER BY siembra_id, fecha;

/*
C1 - Respuesta:
Las seis filas con NULL son las primeras cosechas de cada siembra. No
existe una fila anterior dentro de su particion para comparar. No es un
error de la consulta: NULL significa correctamente que no hay antecedente.
*/


-- C2. Solo cosechas que rindieron menos que la anterior.
WITH comparacion AS (
    SELECT
        siembra_id,
        fecha,
        kg,
        LAG(kg) OVER (
            PARTITION BY siembra_id
            ORDER BY fecha
        ) AS anterior
    FROM cosechas
)
SELECT
    siembra_id,
    anterior AS de,
    kg AS a,
    kg - anterior AS delta
FROM comparacion
WHERE anterior IS NOT NULL
  AND kg < anterior
ORDER BY siembra_id;

/*
C2 - Respuesta:
Las tres siembras que tuvieron un segundo corte, las tres cayeron.
Le preguntaria al jefe de finca: ¿que ocurrio entre el primer y segundo
corte —manejo, clima, plagas, disponibilidad de agua o madurez— que pueda
explicar la caida del rendimiento?
*/


-- C3. Dias entre cada cosecha y la siguiente de la misma siembra.
SELECT
    siembra_id,
    fecha,
    LEAD(fecha) OVER (
        PARTITION BY siembra_id
        ORDER BY fecha
    ) AS siguiente,
    ROUND(
        julianday(
            LEAD(fecha) OVER (
                PARTITION BY siembra_id
                ORDER BY fecha
            )
        ) - julianday(fecha),
        0
    ) AS dias_hasta_siguiente
FROM cosechas
ORDER BY siembra_id, fecha;


-- C4. Deteccion de huecos de mas de 3 horas.
SELECT
    sensor_id,
    ant,
    fecha_hora,
    ROUND(
        (julianday(fecha_hora) - julianday(ant)) * 24,
        1
    ) AS horas_sin_medir
FROM (
    SELECT
        sensor_id,
        fecha_hora,
        LAG(fecha_hora) OVER (
            PARTITION BY sensor_id
            ORDER BY fecha_hora
        ) AS ant
    FROM lecturas
)
WHERE ant IS NOT NULL
  AND (julianday(fecha_hora) - julianday(ant)) * 24 > 3;

/*
C4 - Respuestas:
1) El hueco nuevo del sensor 1 salio de las tres lecturas defectuosas que
   la limpieza anterior elimino; al borrar esas filas aparecio un salto
   entre la lectura anterior y la siguiente.
2) Es un hueco de la base de datos causado por la limpieza, no una prueba
   de que el sensor haya dejado de medir.
3) Habia que guardar un registro de auditoria o bitacora de eliminacion:
   sensor, fecha_hora original, valor descartado, motivo, fecha de
   eliminacion y quien ejecuto o autorizo la limpieza.
*/


-- =====================================================================
-- PARTE D - ACUMULADOS Y MEDIA MOVIL
-- =====================================================================

-- D1. Kilos por fecha y acumulado del curso.
WITH por_fecha AS (
    SELECT
        fecha,
        SUM(kg) AS kg
    FROM cosechas
    GROUP BY fecha
)
SELECT
    fecha,
    kg,
    SUM(kg) OVER (
        ORDER BY fecha
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS acumulado
FROM por_fecha
ORDER BY fecha;


-- D2. Acumulado reiniciado por finca.
WITH por_finca AS (
    SELECT
        f.nombre AS finca,
        c.fecha,
        c.kg
    FROM cosechas AS c
    JOIN siembras AS s ON s.siembra_id = c.siembra_id
    JOIN lotes AS l ON l.lote_id = s.lote_id
    JOIN fincas AS f ON f.finca_id = l.finca_id
)
SELECT
    finca,
    fecha,
    kg,
    SUM(kg) OVER (
        PARTITION BY finca
        ORDER BY fecha
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS acumulado
FROM por_finca
ORDER BY finca, fecha;

/*
D2 - Respuesta:
Lo que cambio fue agregar PARTITION BY finca al OVER. Eso reinicia la
suma cada vez que comienza una finca diferente; el ORDER BY fecha sigue
definiendo el orden del acumulado dentro de cada particion.
*/


-- D3. Media movil de 7 dias del promedio diario del sensor 1.
-- La ventana se calcula sobre los 30 dias y el filtro de presentacion se
-- haria afuera si se necesita mostrar solo un rango.
WITH diario AS (
    SELECT
        date(fecha_hora) AS d,
        ROUND(AVG(valor), 2) AS prom
    FROM lecturas
    WHERE sensor_id = 1
      AND date(fecha_hora) BETWEEN '2026-04-01' AND '2026-04-30'
    GROUP BY date(fecha_hora)
),
movil AS (
    SELECT
        d,
        prom,
        ROUND(
            AVG(prom) OVER (
                ORDER BY d
                ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
            ),
            2
        ) AS media_movil
    FROM diario
)
SELECT
    d,
    prom,
    media_movil
FROM movil
ORDER BY d;


-- D4. Media movil con cantidad real de dias dentro de la ventana.
WITH diario AS (
    SELECT
        date(fecha_hora) AS d,
        ROUND(AVG(valor), 2) AS prom
    FROM lecturas
    WHERE sensor_id = 1
      AND date(fecha_hora) BETWEEN '2026-04-01' AND '2026-04-30'
    GROUP BY date(fecha_hora)
),
movil AS (
    SELECT
        d,
        prom,
        ROUND(
            AVG(prom) OVER (
                ORDER BY d
                ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
            ),
            2
        ) AS media_movil,
        COUNT(*) OVER (
            ORDER BY d
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS cantidad_dias
    FROM diario
)
SELECT
    d,
    prom,
    media_movil,
    cantidad_dias
FROM movil
ORDER BY d;

/*
D4 - Respuesta:
La media movil del 1 de abril se calculo sobre 1 solo dia, no sobre 7.
Por eso, si un tablero la llama simplemente "media de 7 dias" desde el
primer dia, esta afirmando que siempre hay siete observaciones cuando en
realidad la ventana todavia esta incompleta.
*/

/*
D5 - Respuesta:
El 20 de abril la media movil suavizo el valor 27.33 hasta 24.33, pero en
este caso tambien tapo un problema de calidad de datos.
La aparente temperatura extrema fue causada por haber eliminado dos
lecturas bajas; suavizarla no corrige esa causa.
*/


-- =====================================================================
-- PARTE E - CIERRE
-- =====================================================================

/*
E1) GROUP BY reduce varias filas a una fila por grupo, mientras OVER
    calcula sobre una particion sin eliminar las filas del detalle.

E2) ROW_NUMBER devolveria una sola fila aunque hubiera empate; sin un
    desempate explicito, cual fila gana puede no estar garantizado. Si
    quisiera conservar todos los mejores lotes empatados, usaria RANK()
    y filtraria puesto = 1.

E3) Regla para futuras limpiezas:
    Nunca borrar datos malos sin dejar trazabilidad de que fueron
    eliminados.
    Guardar el valor original, la fecha, el motivo y quien hizo la
    limpieza.
    Asi una ausencia futura puede distinguirse de una medicion que nunca
    existio.
*/


-- =====================================================================
-- EXTRA (+5) - PREGUNTA DE NEGOCIO
-- =====================================================================

-- ¿Que porcentaje del total cosechado de cada finca representa cada
-- cosecha y cuanto se ha acumulado de ese porcentaje?
WITH cosecha_finca AS (
    SELECT
        f.nombre AS finca,
        c.fecha,
        c.kg
    FROM cosechas AS c
    JOIN siembras AS s ON s.siembra_id = c.siembra_id
    JOIN lotes AS l ON l.lote_id = s.lote_id
    JOIN fincas AS f ON f.finca_id = l.finca_id
)
SELECT
    finca,
    fecha,
    kg,
    ROUND(
        kg * 100.0 / SUM(kg) OVER (PARTITION BY finca),
        2
    ) AS porcentaje_cosecha,
    ROUND(
        SUM(kg) OVER (
            PARTITION BY finca
            ORDER BY fecha
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) * 100.0 / SUM(kg) OVER (PARTITION BY finca),
        2
    ) AS porcentaje_acumulado
FROM cosecha_finca
ORDER BY finca, fecha;
