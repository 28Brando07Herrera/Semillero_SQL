-- ================================================================
-- EJERCICIO PRACTICO 7 - El dia que no fue el mas caluroso
-- Archivo: Ejercicio7
-- Motor: SQLite
-- ================================================================

-- ================================================================
-- PARTE A - LO QUE GROUP BY NO PODIA
-- ================================================================

-- A1. Cada labor junto al total de mano de obra de su siembra.
SELECT
    labor_id,
    siembra_id,
    tipo_labor,
    fecha,
    costo_mano_obra,
    SUM(costo_mano_obra) OVER (
        PARTITION BY siembra_id
    ) AS total_mano_obra_siembra
FROM labores
ORDER BY siembra_id, labor_id;

-- A2. Porcentaje de cada labor sobre el total de su siembra.
WITH costos AS (
    SELECT
        labor_id,
        siembra_id,
        tipo_labor,
        fecha,
        costo_mano_obra,
        SUM(costo_mano_obra) OVER (
            PARTITION BY siembra_id
        ) AS total_mano_obra_siembra
    FROM labores
)
SELECT
    labor_id,
    siembra_id,
    tipo_labor,
    costo_mano_obra,
    total_mano_obra_siembra,
    ROUND(
        costo_mano_obra * 100.0 / total_mano_obra_siembra,
        1
    ) AS porcentaje
FROM costos
ORDER BY siembra_id, labor_id;

-- A3 - Respuesta:
-- GROUP BY siembra_id colapsa todas las labores de una misma siembra
-- en una sola fila. En ese momento se pierde el detalle de cada labor:
-- su labor_id, tipo, fecha y costo individual. OVER(PARTITION BY)
-- permite calcular el total sobre el grupo sin eliminar las filas
-- originales.

-- ================================================================
-- PARTE B - CLASIFICACIONES
-- ================================================================

-- B1. Ranking de lotes por rendimiento dentro de cada finca.
-- Se usa * 1.0 para evitar division entera.
SELECT
    f.nombre AS finca,
    l.codigo AS lote,
    ROUND(SUM(c.kg) * 1.0 / l.hectareas, 2) AS kg_ha,
    RANK() OVER (
        PARTITION BY f.nombre
        ORDER BY SUM(c.kg) * 1.0 / l.hectareas DESC
    ) AS puesto,
    COUNT(c.cosecha_id) AS n_cosechas
FROM fincas AS f
JOIN lotes AS l
    ON l.finca_id = f.finca_id
JOIN siembras AS s
    ON s.lote_id = l.lote_id
JOIN cosechas AS c
    ON c.siembra_id = s.siembra_id
GROUP BY
    f.finca_id,
    f.nombre,
    l.lote_id,
    l.codigo,
    l.hectareas
ORDER BY f.nombre, puesto;

-- B2. Promedio diario del sensor 1 con las tres numeraciones.
WITH diarios AS (
    SELECT
        DATE(fecha_hora) AS dia,
        AVG(valor) AS promedio,
        COUNT(*) AS n
    FROM lecturas
    WHERE sensor_id = 1
      AND fecha_hora >= '2026-04-01'
      AND fecha_hora < '2026-05-01'
    GROUP BY DATE(fecha_hora)
),
rankings AS (
    SELECT
        dia,
        promedio,
        n,
        ROW_NUMBER() OVER (
            ORDER BY promedio DESC, dia ASC
        ) AS numero_de_fila,
        RANK() OVER (
            ORDER BY promedio DESC
        ) AS rango,
        DENSE_RANK() OVER (
            ORDER BY promedio DESC
        ) AS rango_denso
    FROM diarios
)
SELECT
    dia,
    ROUND(promedio, 2) AS promedio,
    numero_de_fila,
    rango,
    rango_denso,
    n
FROM rankings
ORDER BY numero_de_fila;

-- B2 - Respuestas:
-- RANK salta de 2 a 7 porque cinco dias empatan en el puesto 2;
-- despues de cinco filas empatadas, el siguiente puesto es el 7.
-- DENSE_RANK no deja huecos: esos cinco dias comparten el 2 y el
-- siguiente promedio distinto recibe el 3.
--
-- DENSE_RANK permite ver que existen 7 promedios distintos porque
-- su maximo valor es 7.
--
-- ROW_NUMBER siempre asigna un numero diferente a cada fila, aunque
-- los valores empaten. En esta consulta agregamos dia ASC como
-- desempate, por lo que el orden queda determinista. Si solo se
-- ordenara por promedio, el orden entre empatados no estaria garantizado.

-- B3. Ranking auditado con el COUNT(*) de cada dia.
WITH diarios AS (
    SELECT
        DATE(fecha_hora) AS dia,
        AVG(valor) AS promedio,
        COUNT(*) AS n
    FROM lecturas
    WHERE sensor_id = 1
      AND fecha_hora >= '2026-04-01'
      AND fecha_hora < '2026-05-01'
    GROUP BY DATE(fecha_hora)
),
rankings AS (
    SELECT
        dia,
        promedio,
        n,
        ROW_NUMBER() OVER (
            ORDER BY promedio DESC, dia ASC
        ) AS numero_de_fila,
        RANK() OVER (
            ORDER BY promedio DESC
        ) AS rango,
        DENSE_RANK() OVER (
            ORDER BY promedio DESC
        ) AS rango_denso
    FROM diarios
)
SELECT
    dia,
    ROUND(promedio, 2) AS promedio,
    n,
    numero_de_fila,
    rango,
    rango_denso
FROM rankings
ORDER BY numero_de_fila;

-- B3 - Respuestas:
-- El 20 de abril tiene 6 lecturas y el 19 de abril tiene 7.
-- Tienen menos porque ayer se eliminaron las tres lecturas averiadas
-- que contenian -99: una del 19 a las 21:00 y dos del 20 a las
-- 00:00 y 03:00. Limpiar el dato malo no recupera una medicion buena.
--
-- Al quitar las lecturas nocturnas, que eran bajas, el promedio del
-- 20 de abril queda artificialmente elevado. Por eso aparece primero.
--
-- No. El 20 de abril NO fue necesariamente el dia mas caluroso:
-- su primer puesto es consecuencia del sesgo introducido por haber
-- eliminado las tres lecturas malas y haber dejado esos horarios
-- ausentes. El ranking debe leerse junto con su conteo.

-- B4. Ranking usando solamente dias con las 8 lecturas.
WITH diarios AS (
    SELECT
        DATE(fecha_hora) AS dia,
        AVG(valor) AS promedio,
        COUNT(*) AS n
    FROM lecturas
    WHERE sensor_id = 1
      AND fecha_hora >= '2026-04-01'
      AND fecha_hora < '2026-05-01'
    GROUP BY DATE(fecha_hora)
    HAVING COUNT(*) = 8
),
rankings AS (
    SELECT
        dia,
        promedio,
        n,
        RANK() OVER (ORDER BY promedio DESC) AS puesto
    FROM diarios
)
SELECT
    dia,
    ROUND(promedio, 2) AS promedio,
    n,
    puesto
FROM rankings
ORDER BY puesto, dia;

-- B4 - Respuesta:
-- Es una respuesta comparable para los dias completos, pero no es
-- simplemente "la respuesta correcta" para cualquier pregunta.
-- Al descartar el 19 y el 20 perdemos informacion real sobre esos dias:
-- sabemos que faltan mediciones porque fueron eliminadas al limpiar
-- datos, y ya no podemos reconstruir directamente sus valores originales.

-- B5. Primero, version que NO funciona:
-- SELECT f.nombre AS finca, l.codigo AS lote,
--        SUM(c.kg) * 1.0 / l.hectareas AS kg_ha,
--        ROW_NUMBER() OVER (
--            PARTITION BY f.nombre
--            ORDER BY SUM(c.kg) * 1.0 / l.hectareas DESC
--        ) AS puesto
-- FROM fincas f
-- JOIN lotes l ON l.finca_id = f.finca_id
-- JOIN siembras s ON s.lote_id = l.lote_id
-- JOIN cosechas c ON c.siembra_id = s.siembra_id
-- WHERE puesto = 1
-- GROUP BY f.nombre, l.codigo, l.hectareas;
--
-- Error de SQLite:
-- misuse of aliased window function puesto
--
-- La ventana se calcula despues de las etapas que aplican WHERE.
-- Por eso WHERE no puede ver directamente el resultado de una
-- funcion de ventana del mismo SELECT. Se calcula primero en un CTE
-- y luego se filtra desde la consulta exterior.

-- B5. Version correcta: CTE + filtro afuera.
WITH rendimiento AS (
    SELECT
        f.nombre AS finca,
        l.codigo AS lote,
        ROUND(SUM(c.kg) * 1.0 / l.hectareas, 2) AS kg_ha,
        ROW_NUMBER() OVER (
            PARTITION BY f.nombre
            ORDER BY SUM(c.kg) * 1.0 / l.hectareas DESC, l.codigo ASC
        ) AS puesto,
        COUNT(c.cosecha_id) AS n_cosechas
    FROM fincas AS f
    JOIN lotes AS l
        ON l.finca_id = f.finca_id
    JOIN siembras AS s
        ON s.lote_id = l.lote_id
    JOIN cosechas AS c
        ON c.siembra_id = s.siembra_id
    GROUP BY
        f.finca_id,
        f.nombre,
        l.lote_id,
        l.codigo,
        l.hectareas
)
SELECT
    finca,
    lote,
    kg_ha,
    puesto,
    n_cosechas
FROM rendimiento
WHERE puesto = 1
ORDER BY finca;

-- ================================================================
-- PARTE C - MIRAR LA FILA DE AL LADO
-- ================================================================

-- C1. Cada cosecha con la cosecha anterior de la misma siembra.
WITH cosechas_ordenadas AS (
    SELECT
        siembra_id,
        fecha,
        kg,
        LAG(kg) OVER (
            PARTITION BY siembra_id
            ORDER BY fecha
        ) AS kg_anterior
    FROM cosechas
)
SELECT
    siembra_id,
    fecha,
    kg,
    kg_anterior,
    kg - kg_anterior AS diferencia
FROM cosechas_ordenadas
ORDER BY siembra_id;

-- C1 - Respuesta:
-- Las seis primeras cosechas de siembras que solo tienen un corte
-- tienen NULL porque no existe una fila anterior dentro de su misma
-- siembra. No es un error: LAG correctamente informa que no hay
-- valor anterior disponible.

-- C2. Cosechas que rindieron menos que la anterior.
WITH cosechas_ordenadas AS (
    SELECT
        siembra_id,
        fecha,
        kg,
        LAG(kg) OVER (
            PARTITION BY siembra_id
            ORDER BY fecha
        ) AS kg_anterior
    FROM cosechas
)
SELECT
    siembra_id,
    kg_anterior AS cosecha_anterior,
    kg,
    kg - kg_anterior AS delta
FROM cosechas_ordenadas
WHERE kg_anterior IS NOT NULL
  AND kg < kg_anterior
ORDER BY siembra_id;

-- C2 - Respuesta:
-- Las tres siembras que tuvieron un segundo corte, las tres cayeron.
-- Le preguntaria al jefe de finca si hubo cambios en riego, clima,
-- manejo, fertilizacion, plagas o condiciones del lote entre ambos cortes.

-- C3. Dias entre cada cosecha y la siguiente de la misma siembra.
WITH cosechas_ordenadas AS (
    SELECT
        siembra_id,
        fecha,
        kg,
        LEAD(fecha) OVER (
            PARTITION BY siembra_id
            ORDER BY fecha
        ) AS fecha_siguiente
    FROM cosechas
)
SELECT
    siembra_id,
    fecha,
    kg,
    fecha_siguiente,
    CASE
        WHEN fecha_siguiente IS NOT NULL
        THEN CAST(julianday(fecha_siguiente) - julianday(fecha) AS INTEGER)
    END AS dias_hasta_siguiente
FROM cosechas_ordenadas
ORDER BY siembra_id, fecha;

-- C4. Huecos despues de la limpieza.
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
  AND (julianday(fecha_hora) - julianday(ant)) * 24 > 3
ORDER BY sensor_id, fecha_hora;

-- C4 - Respuestas:
-- 1. El sensor 1 aparecio porque ayer eliminamos sus tres lecturas
-- averiadas. Al borrarlas, la serie quedo con un hueco visible.
-- 2. Es un hueco de la base de datos/serie observada, provocado por
-- nuestra limpieza; no significa que el sensor haya dejado de medir.
-- 3. Debiamos conservar una bitacora de calidad/auditoria con la
-- lectura eliminada, motivo, fecha de eliminacion y quien o que proceso
-- la elimino. Asi despues se puede distinguir "nunca hubo dato" de
-- "hubo dato y fue descartado a proposito".

-- ================================================================
-- PARTE D - ACUMULADOS Y MEDIOS MOVILES
-- ================================================================

-- D1. Kilos por fecha y acumulado anual.
WITH kilos_dia AS (
    SELECT
        fecha,
        SUM(kg) AS kg_dia
    FROM cosechas
    GROUP BY fecha
)
SELECT
    fecha,
    kg_dia,
    SUM(kg_dia) OVER (
        ORDER BY fecha
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS acumulado,
    COUNT(*) AS n_fechas
FROM kilos_dia
ORDER BY fecha;

-- D2. Acumulado reiniciado por finca.
WITH kilos_finca_dia AS (
    SELECT
        f.nombre AS finca,
        c.fecha,
        SUM(c.kg) AS kg_dia
    FROM cosechas AS c
    JOIN siembras AS s
        ON s.siembra_id = c.siembra_id
    JOIN lotes AS l
        ON l.lote_id = s.lote_id
    JOIN fincas AS f
        ON f.finca_id = l.finca_id
    GROUP BY
        f.finca_id,
        f.nombre,
        c.fecha
)
SELECT
    finca,
    fecha,
    kg_dia,
    SUM(kg_dia) OVER (
        PARTITION BY finca
        ORDER BY fecha
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS acumulado_finca,
    COUNT(*) OVER (
        PARTITION BY finca
        ORDER BY fecha
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS n_fechas_acumuladas
FROM kilos_finca_dia
ORDER BY finca, fecha;

-- D2 - Respuesta:
-- En D1 el OVER solo ordena todas las fechas juntas. En D2 se agrega
-- PARTITION BY finca, que crea una ventana independiente por finca.
-- Por eso el SUM vuelve a empezar en cero al cambiar de finca.

-- D3. Media movil de 7 dias del promedio diario del sensor 1.
-- Primero se construye el promedio de los 30 dias; despues se aplica
-- la ventana sobre esos 30 dias.
WITH diarios AS (
    SELECT
        DATE(fecha_hora) AS d,
        ROUND(AVG(valor), 2) AS prom,
        COUNT(*) AS n
    FROM lecturas
    WHERE sensor_id = 1
      AND fecha_hora >= '2026-04-01'
      AND fecha_hora < '2026-05-01'
    GROUP BY DATE(fecha_hora)
),
movil AS (
    SELECT
        d,
        prom,
        n,
        AVG(prom) OVER (
            ORDER BY d
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS media_movil
    FROM diarios
)
SELECT
    d,
    ROUND(prom, 2) AS promedio,
    ROUND(media_movil, 2) AS media_movil,
    n
FROM movil
ORDER BY d;

-- D4. Media movil y cantidad de dias que realmente entraron.
WITH diarios AS (
    SELECT
        DATE(fecha_hora) AS d,
        ROUND(AVG(valor), 2) AS prom,
        COUNT(*) AS n
    FROM lecturas
    WHERE sensor_id = 1
      AND fecha_hora >= '2026-04-01'
      AND fecha_hora < '2026-05-01'
    GROUP BY DATE(fecha_hora)
),
movil AS (
    SELECT
        d,
        prom,
        n,
        AVG(prom) OVER (
            ORDER BY d
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS media_movil,
        COUNT(*) OVER (
            ORDER BY d
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS dias_en_ventana
    FROM diarios
)
SELECT
    d,
    ROUND(prom, 2) AS promedio,
    ROUND(media_movil, 2) AS media_movil,
    n,
    dias_en_ventana
FROM movil
ORDER BY d;

-- D4 - Respuesta:
-- El 1 de abril la media movil se calcula solamente sobre 1 dia,
-- porque no existen seis dias anteriores dentro de la serie.
-- Por tanto, no es una media de 7 dias completos.
-- Si un tablero la muestra como "media movil de 7 dias" sin aclarar
-- el conteo, estaria sugiriendo una ventana completa de 7 dias cuando
-- al inicio solo se uso una cantidad menor de dias.

-- D5 - Respuesta:
-- El medio movil suavizo el pico numericamente, pero tambien puede
-- tapar un problema. El 27.33 del 20 de abril fue elevado porque
-- faltaban tres lecturas nocturnas despues de la limpieza.
-- La media movil de 24.33 mezcla ese dato sesgado con otros seis dias
-- y puede hacer que el problema parezca solamente ruido normal.

-- ================================================================
-- PARTE E - CIERRE
-- ================================================================

-- E1 - Respuesta:
-- GROUP BY colapsa varias filas en grupos y devuelve una fila por grupo;
-- OVER calcula sobre una ventana sin eliminar las filas originales.

-- E2 - Respuesta:
-- La consulta de B5 usa ROW_NUMBER con un desempate por lote. Si dos
-- lotes empataran en kg/ha, ROW_NUMBER igual devolveria uno como puesto
-- 1 y al otro como puesto 2 por el desempate. Eso no seria lo ideal si
-- la pregunta de negocio es "todos los mejores lotes". En ese caso
-- convendria RANK o DENSE_RANK y filtrar el puesto 1.

-- E3 - Respuesta:
-- Al limpiar datos no debo confundir "dato malo" con "dato inexistente".
-- Si elimino una fila, debo registrar que existio, por que se elimino
-- y quien/proceso lo hizo.
-- Ademas, los reportes deben conservar indicadores de cobertura para
-- que un promedio o ranking no premie artificialmente una serie incompleta.

-- ================================================================
-- EXTRA +5 - PREGUNTA DE NEGOCIO ADICIONAL
-- ================================================================

-- Pregunta: ¿cual fue la cosecha mas reciente de cada siembra que
-- efectivamente tuvo cosecha, y cuantos kilos produjo?
-- Esto sirve para identificar rapidamente el ultimo resultado productivo
-- de cada siembra sin perder el detalle de la fila original.
WITH cosechas_rank AS (
    SELECT
        c.cosecha_id,
        c.siembra_id,
        c.fecha,
        c.kg,
        ROW_NUMBER() OVER (
            PARTITION BY c.siembra_id
            ORDER BY c.fecha DESC, c.cosecha_id DESC
        ) AS puesto
    FROM cosechas AS c
)
SELECT
    siembra_id,
    cosecha_id,
    fecha,
    kg,
    puesto
FROM cosechas_rank
WHERE puesto = 1
ORDER BY siembra_id;

-- ================================================================
-- FIN DEL EJERCICIO 7
-- ================================================================
