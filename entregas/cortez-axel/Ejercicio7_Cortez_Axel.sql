-- EJERCICIO PRÁCTICO 7: El día que no fue el más caluroso
-- Estudiante: Cortez Axel
-- Motor: SQLite | Entorno: sqliteonline.com

PRAGMA foreign_keys = ON;


-- PARTE A · LO QUE GROUP BY NO PODÍA

-- A1. Cada labor con su costo de mano de obra y el total acumulado por siembra
-- Esperado: 19 filas sin colapsar el detalle individual
SELECT 
    labor_id,
    siembra_id,
    tipo_labor,
    fecha,
    costo_mano_obra,
    SUM(costo_mano_obra) OVER (PARTITION BY siembra_id) AS total_mo_siembra
FROM labores
ORDER BY siembra_id, labor_id;


-- A2. Porcentaje que representa cada labor sobre el total de su siembra
-- Esperado: 19 filas (en la siembra 5: 77.1% y 22.9%)
SELECT 
    labor_id,
    siembra_id,
    tipo_labor,
    fecha,
    costo_mano_obra,
    SUM(costo_mano_obra) OVER (PARTITION BY siembra_id) AS total_mo_siembra,
    ROUND((costo_mano_obra * 100.0) / SUM(costo_mano_obra) OVER (PARTITION BY siembra_id), 1) AS pct_sobre_siembra
FROM labores
ORDER BY siembra_id, labor_id;

/*
EXPLICACIÓN A3:
Esta consulta no se puede resolver directamente con un GROUP BY siembra_id porque GROUP BY 
perjudica todas las filas del grupo en un único registro resumen por siembra en la etapa de agregación. 
Al hacer eso, se destruye la identidad individual de cada labor (labor_id, fecha, costo_mano_obra individual), 
imposibilitando mostrar el detalle fila por fila junto con el total consolidado en una sola pasada.
*/

-- PARTE B · RANKINGS

-- B1. Ranking de lotes por rendimiento (kg/ha) dentro de cada finca
-- Esperado: 6 filas
WITH cosechas_por_lote AS (
    SELECT 
        f.nombre AS finca,
        l.codigo AS lote,
        l.hectareas,
        SUM(c.kg) AS total_kg,
        ROUND((SUM(c.kg) * 1.0) / l.hectareas, 2) AS kg_ha
    FROM cosechas c
    JOIN siembras s ON c.siembra_id = s.siembra_id
    JOIN lotes l ON s.lote_id = l.lote_id
    JOIN fincas f ON l.finca_id = f.finca_id
    GROUP BY f.finca_id, l.lote_id
)
SELECT 
    finca,
    lote,
    kg_ha,
    RANK() OVER (PARTITION BY finca ORDER BY kg_ha DESC) AS puesto
FROM cosechas_por_lote
ORDER BY finca, puesto;


-- B2. Promedio diario del sensor 1 con ROW_NUMBER, RANK y DENSE_RANK
-- Esperado: 30 filas
WITH prom_diario_s1 AS (
    SELECT 
        DATE(fecha_hora) AS dia,
        ROUND(AVG(valor), 2) AS prom
    FROM lecturas
    WHERE sensor_id = 1 
      AND fecha_hora >= '2026-04-01' AND fecha_hora < '2026-05-01'
    GROUP BY dia
)
SELECT 
    dia,
    prom,
    ROW_NUMBER() OVER (ORDER BY prom DESC) AS row_number,
    RANK() OVER (ORDER BY prom DESC) AS rank,
    DENSE_RANK() OVER (ORDER BY prom DESC) AS dense_rank
FROM prom_diario_s1
ORDER BY prom DESC, dia;

/*
EXPLICACIÓN B2:
- RANK salta de 2 a 7 porque detecta un empate de 5 días en el puesto 2 (filas 2 a 6). RANK deja los huecos de las posiciones ocupadas (2 + 5 = 7), mientras que DENSE_RANK no deja huecos y asigna inmediatamente el puesto consecutivo 3.
- DENSE_RANK es la función que permite ver de un solo vistazo cuántos promedios distintos existen en el mes, ya que su valor máximo final coincide exactamente con la cantidad de valores únicos (7 promedios distintos).
- ROW_NUMBER asigna números secuenciales estrictos (2, 3, etc.) desempatando de manera arbitraria según el orden físico interno de procesamiento si no hay un criterio explícito de desempate en el ORDER BY. No hay garantía de estabilidad mañana a menos que agreguemos una columna secundaria fija como 'ORDER BY prom DESC, dia ASC'.
*/


-- B3. Ranking de abril agregando el conteo de lecturas (COUNT(*))
WITH prom_diario_auditado AS (
    SELECT 
        DATE(fecha_hora) AS dia,
        COUNT(*) AS n_lecturas,
        ROUND(AVG(valor), 2) AS prom
    FROM lecturas
    WHERE sensor_id = 1 
      AND fecha_hora >= '2026-04-01' AND fecha_hora < '2026-05-01'
    GROUP BY dia
)
SELECT 
    dia,
    n_lecturas,
    prom,
    RANK() OVER (ORDER BY prom DESC) AS rank,
    DENSE_RANK() OVER (ORDER BY prom DESC) AS dense_rank
FROM prom_diario_auditado
ORDER BY prom DESC, dia;

/*
RESPUESTAS AUDITORÍA B3:
1. El 20 de abril tiene 6 lecturas; el 19 de abril tiene 7 lecturas (frente a las 8 normales).
2. Tienen menos lecturas porque en la limpieza de la Clase 6 borramos las 3 mediciones que tenían el código de falla -99.
3. Las lecturas borradas correspondían a la noche y madrugada (21:00, 00:00 y 03:00), que son justamente las horas más frías del ciclo diario. Al eliminar las temperaturas bajas de la noche, el promedio del día 20 se calculó casi exclusivamente con las horas de sol, inflando artificialmente el promedio diario a 27.33 °C.
4. NO, el 20 de abril no fue el día más caluroso. Su primer puesto es un artefacto de la limpieza de datos: al faltarle las mediciones nocturnas frías, su promedio quedó sesgado hacia arriba.
*/


-- B4. Ranking recalculado únicamente con días de 8 lecturas completas
-- Esperado: 28 filas
WITH prom_dias_completos AS (
    SELECT 
        DATE(fecha_hora) AS dia,
        COUNT(*) AS n_lecturas,
        ROUND(AVG(valor), 2) AS prom
    FROM lecturas
    WHERE sensor_id = 1 
      AND fecha_hora >= '2026-04-01' AND fecha_hora < '2026-05-01'
    GROUP BY dia
    HAVING COUNT(*) = 8
)
SELECT 
    dia,
    n_lecturas,
    prom,
    RANK() OVER (ORDER BY prom DESC) AS rank,
    DENSE_RANK() OVER (ORDER BY prom DESC) AS dense_rank
FROM prom_dias_completos
ORDER BY prom DESC, dia;

/*
EXPLICACIÓN B4:
Es una respuesta metodológicamente más rigurosa para comparar días bajo igualdad de condiciones de muestreo, pero no es la verdad absoluta. Al descartar por completo el 19 y 20 de abril, perdimos la visibilidad de dos días enteros de operación agrícola y asumimos que no ocurrieron picos térmicos reales durante esas jornadas.
*/


-- B5. El mejor lote de cada finca (filtro afuera con CTE)
-- Intento fallido documentado:
-- SELECT finca, lote, kg_ha, RANK() OVER (PARTITION BY finca ORDER BY kg_ha DESC) AS puesto FROM (...) WHERE puesto = 1;
/*
ERROR OBTENIDO EN EL INTENTO FALLIDO:
SQLITE_ERROR: sqlite3 result code 1: no such column: puesto (o misuse of window function si se coloca la función dentro del WHERE)

EXPLICACIÓN B5:
En el orden lógico de ejecución de SQL, la cláusula WHERE se procesa antes que las funciones de ventana (OVER) y antes de la asignación de alias del SELECT. Por ende, el WHERE no puede evaluar el alias 'puesto' ni filtrar sobre el resultado de una ventana. Se debe encapsular en una CTE o subconsulta y filtrar afuera.
*/

WITH ranking_lotes_finca AS (
    SELECT 
        f.nombre AS finca,
        l.codigo AS lote,
        ROUND((SUM(c.kg) * 1.0) / l.hectareas, 2) AS kg_ha,
        ROW_NUMBER() OVER (PARTITION BY f.nombre ORDER BY (SUM(c.kg) * 1.0) / l.hectareas DESC) AS puesto
    FROM cosechas c
    JOIN siembras s ON c.siembra_id = s.siembra_id
    JOIN lotes l ON s.lote_id = l.lote_id
    JOIN fincas f ON l.finca_id = f.finca_id
    GROUP BY f.finca_id, l.lote_id
)
SELECT finca, lote, kg_ha
FROM ranking_lotes_finca
WHERE puesto = 1
ORDER BY finca;
-- Esperado: Agricola La Union (A-1: 38.18) | Finca El Guayabo (L-02: 529.73) | Hacienda Santa Rosa (L-01: 256.14)

-- PARTE C · MIRAR LA FILA DE AL LADO (LAG / LEAD)

-- C1. Comparación con la cosecha anterior de la misma siembra
-- Esperado: 9 filas (6 con NULL en anterior)
SELECT 
    cosecha_id,
    siembra_id,
    fecha,
    kg AS kg_actual,
    LAG(kg) OVER (PARTITION BY siembra_id ORDER BY fecha) AS kg_anterior,
    kg - LAG(kg) OVER (PARTITION BY siembra_id ORDER BY fecha) AS diferencia_kg
FROM cosechas
ORDER BY siembra_id, fecha;

/*
EXPLICACIÓN C1:
Las seis filas muestran NULL en 'kg_anterior' porque corresponden a la primera cosecha registrada de cada siembra dentro de su partición. Al no existir una fila previa para esa siembra en la secuencia cronológica, LAG() retorna NULL por definición. La consulta es 100% correcta.
*/


-- C2. Cosechas que rindieron menos que la anterior de su misma siembra
-- Esperado: 3 filas (Siembras 1, 4 y 6)
WITH comp_cosechas AS (
    SELECT 
        siembra_id,
        LAG(kg) OVER (PARTITION BY siembra_id ORDER BY fecha) AS de,
        kg AS a,
        kg - LAG(kg) OVER (PARTITION BY siembra_id ORDER BY fecha) AS delta
    FROM cosechas
)
SELECT siembra_id, de, a, delta
FROM comp_cosechas
WHERE delta < 0
ORDER BY siembra_id;

/*
PREGUNTA AL JEFE DE FINCA C2:
"Jefe, en las tres siembras donde se realizó un segundo corte hubo una caída promedio del 28% en el volumen recolectado. ¿Esta disminución responde al agotamiento natural de la curva de floración del cultivo o evidencia un déficit nutricional/hídrico tras la primera cosecha?"
*/


-- C3. Días transcurridos entre cosechas sucesivas usando LEAD
-- Esperado: 9 filas (3 con cálculo de días: 29, 21 y 25 días)
SELECT 
    cosecha_id,
    siembra_id,
    fecha AS fecha_actual,
    LEAD(fecha) OVER (PARTITION BY siembra_id ORDER BY fecha) AS fecha_siguiente,
    CAST(julianday(LEAD(fecha) OVER (PARTITION BY siembra_id ORDER BY fecha)) - julianday(fecha) AS INTEGER) AS dias_entre_cosechas
FROM cosechas
ORDER BY siembra_id, fecha;


-- C4. Detección de saltos temporales > 3 horas en la serie de sensores
-- Esperado: 2 filas (Sensor 1 con 12.0 horas y Sensor 2 con 75.0 horas)
SELECT sensor_id, ant AS desde, fecha_hora AS hasta,
       ROUND((julianday(fecha_hora) - julianday(ant)) * 24, 1) AS horas
FROM (
  SELECT sensor_id, fecha_hora,
         LAG(fecha_hora) OVER (PARTITION BY sensor_id ORDER BY fecha_hora) AS ant
  FROM lecturas
)
WHERE ant IS NOT NULL
  AND (julianday(fecha_hora) - julianday(ant)) * 24 > 3
ORDER BY sensor_id;

/*
EXPLICACIÓN C4:
1. El hueco de 12 horas del sensor 1 se generó al eliminar las 3 mediciones consecutivas con valor -99 (21:00 del día 19, 00:00 y 03:00 del día 20).
2. Es un hueco inducido en la base de datos por nuestra limpieza, no una desconexión física del hardware (el sensor sí transmitió, pero transmitió basura).
3. Para mantener la trazabilidad histórica, en vez de borrar el registro (DELETE) debió implementarse una columna de auditoría como 'es_valido' / 'estado_lectura' o trasladar los registros anómalos a una tabla 'lecturas_rechazadas_log' indicando el motivo del descarte.
*/

-- PARTE D · ACUMULADOS Y MEDIA MÓVIL

-- D1. Kilos cosechados por fecha y acumulado anual
-- Esperado: 8 filas cerrando en 30550 kg
WITH kg_diarios AS (
    SELECT fecha, SUM(kg) AS kg_dia
    FROM cosechas
    GROUP BY fecha
)
SELECT 
    fecha,
    kg_dia,
    SUM(kg_dia) OVER (ORDER BY fecha) AS kg_acumulado_anual
FROM kg_diarios
ORDER BY fecha;


-- D2. Acumulado anual particionado por finca
-- Esperado: 9 filas cerrando en 2100 (La Union), 14250 (El Guayabo) y 14200 (Santa Rosa)
WITH kg_finca_fecha AS (
    SELECT 
        f.nombre AS finca,
        c.fecha,
        SUM(c.kg) AS kg_dia
    FROM cosechas c
    JOIN siembras s ON c.siembra_id = s.siembra_id
    JOIN lotes l ON s.lote_id = l.lote_id
    JOIN fincas f ON l.finca_id = f.finca_id
    GROUP BY f.nombre, c.fecha
)
SELECT 
    finca,
    fecha,
    kg_dia,
    SUM(kg_dia) OVER (PARTITION BY finca ORDER BY fecha) AS kg_acumulado_finca
FROM kg_finca_fecha
ORDER BY finca, fecha;

/*
EXPLICACIÓN D2:
Se añadió 'PARTITION BY finca' dentro de la cláusula OVER. Esto alcanza porque le indica al motor 
que debe reiniciar la suma acumulativa en cero cada vez que cambia el valor de la finca.
*/


-- D3 y D4. Media móvil de 7 días del Sensor 1 con conteo de ventana de control
-- Esperado: 30 filas (Días 18 al 21: 23.49, 23.81, 24.33, 23.91)
WITH serie_diaria_s1 AS (
    SELECT 
        DATE(fecha_hora) AS d,
        COUNT(*) AS n_lecturas_dia,
        ROUND(AVG(valor), 2) AS prom
    FROM lecturas
    WHERE sensor_id = 1 
      AND fecha_hora >= '2026-04-01' AND fecha_hora < '2026-05-01'
    GROUP BY d
)
SELECT 
    d AS dia,
    prom,
    COUNT(*) OVER (ORDER BY d ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS ventana_dias,
    ROUND(AVG(prom) OVER (ORDER BY d ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 2) AS media_movil_7d
FROM serie_diaria_s1
ORDER BY dia;

/*
EXPLICACIÓN D4:
El 1 de abril solo tiene 1 día en su ventana de cálculo (él mismo); no es una media de 7 días. 
Si el tablero no aclara que la ventana está incompleta en los primeros 6 días del mes, 
está afirmando falsamente que se trata de un promedio representativo de una semana entera cuando en realidad toma menos observaciones.
*/

/*
EXPLICACIÓN D5:
La media móvil en este caso le tapó un problema a la serie. Al mezclar el promedio anómalo de 27.33 °C con los 6 días anteriores, 
suavizó el número a 24.33 °C haciéndolo lucir perfectamente normal y ocultando que el día 20 había perdido sus mediciones nocturnas.
*/

-- PARTE E · CIERRE

/*
1. Diferencia entre GROUP BY y OVER (PARTITION BY):
GROUP BY colapsa múltiples filas en una sola fila resumen, mientras que OVER (PARTITION BY) calcula agregaciones sobre grupos manteniendo intacta cada fila individual del resultado.

2. Empates con ROW_NUMBER en B5:
Si dos lotes empataran exactamente en kg/ha, ROW_NUMBER asignaría 1 a uno y 2 al otro de forma arbitraria, ocultando al segundo lote. Si quisiéramos mostrar ambos en caso de empate real, deberíamos usar RANK() o DENSE_RANK().

3. Regla para futuras limpiezas de datos:
Al depurar series temporales o métricas continuas, nunca se deben eliminar filas destructivamente (DELETE) sin registrar metadatos de calidad o imputar valores nulos explícitos; los vacíos generados alteran el denominador de los promedios y falsean las conclusiones estadísticas.
*/

-- EXTRA (+5 PUNTOS): Pregunta de negocio con ventana no pedida
-- "Variación porcentual diaria del consumo de humedad frente al promedio móvil semanal"
-- Permite detectar anomalías de retención hídrica o posibles fallas de riego en el lote A-1.

WITH humedad_diaria AS (
    SELECT 
        f.nombre AS finca,
        l.codigo AS lote,
        DATE(lec.fecha_hora) AS dia,
        COUNT(*) AS lecturas_dia,
        ROUND(AVG(lec.valor), 2) AS humedad_prom_dia
    FROM lecturas lec
    JOIN sensores s ON lec.sensor_id = s.sensor_id
    JOIN lotes l ON s.lote_id = l.lote_id
    JOIN fincas f ON l.finca_id = f.finca_id
    WHERE s.tipo = 'humedad' 
      AND lec.fecha_hora >= '2026-04-01' AND lec.fecha_hora < '2026-05-01'
    GROUP BY f.finca_id, l.lote_id, dia
)
SELECT 
    finca,
    lote,
    dia,
    lecturas_dia,
    humedad_prom_dia,
    ROUND(AVG(humedad_prom_dia) OVER (
        PARTITION BY finca, lote 
        ORDER BY dia 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 2) AS humedad_media_movil_7d,
    ROUND(
        (humedad_prom_dia - AVG(humedad_prom_dia) OVER (
            PARTITION BY finca, lote 
            ORDER BY dia 
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        )) * 100.0 / AVG(humedad_prom_dia) OVER (
            PARTITION BY finca, lote 
            ORDER BY dia 
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ), 2
    ) AS desvio_pct_vs_movil
FROM humedad_diaria
ORDER BY finca, lote, dia;
