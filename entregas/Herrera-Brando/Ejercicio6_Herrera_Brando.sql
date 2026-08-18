-- ================================================================
-- EJERCICIO PRACTICO 6 - El sensor que mintio tres dias
-- Archivo de entrega: Ejercicio6_Apellido_Nombre.sql
-- Base: datos/agrodb_clase6.sql
-- ================================================================

-- ================================================================
-- PARTE A - CONOCER LA TABLA
-- ================================================================

-- A1. Estructura y diez lecturas.
SELECT * FROM lecturas LIMIT 10;

-- A1 - Respuesta:
-- SQLite no tiene un tipo DATETIME nativo. Las fechas/horas pueden
-- almacenarse como TEXT, REAL o INTEGER. Aqui fecha_hora es TEXT,
-- por lo que debemos cuidar el formato ISO (AAAA-MM-DD HH:MM:SS).
-- La consecuencia es que las comparaciones dependen de comparar
-- correctamente cadenas; por ejemplo, un limite '2026-04-30' no
-- incluye los textos '2026-04-30 03:00:00', etc.

-- A2. Lecturas por sensor, primera y ultima medicion.
SELECT
    sensor_id,
    COUNT(*) AS n,
    MIN(fecha_hora) AS primera_medicion,
    MAX(fecha_hora) AS ultima_medicion
FROM lecturas
GROUP BY sensor_id
ORDER BY sensor_id;

-- A2 - Respuesta:
-- El sensor 3 tiene lecturas viejas de febrero y ninguna de abril
-- porque fue dado de baja (activo = 0) despues de medir en febrero.
-- Sus 40 lecturas historicas siguen almacenadas.

-- A3. Sensores sin ninguna lectura.
SELECT
    s.sensor_id,
    s.tipo,
    s.activo,
    l.codigo AS lote,
    f.nombre AS finca
FROM sensores AS s
JOIN lotes AS l ON l.lote_id = s.lote_id
JOIN fincas AS f ON f.finca_id = l.finca_id
LEFT JOIN lecturas AS r ON r.sensor_id = s.sensor_id
WHERE r.sensor_id IS NULL
ORDER BY s.sensor;

-- A4 - Respuesta:
-- activo = 0 significa que el sensor esta dado de baja, pero puede
-- conservar lecturas historicas. El sensor 3 es el ejemplo.
-- Un sensor sin lecturas es el sensor 5: no tiene ninguna fila en
-- lecturas y ademas esta inactivo.
-- Un sensor con lecturas pero ninguna reciente es el sensor 3:
-- tiene 40 lecturas de febrero, pero ninguna de abril.
-- Por tanto, inactivo, sin lecturas y sin lecturas recientes no son
-- conceptos equivalentes.

-- ================================================================
-- PARTE B - FUNCIONES DE FECHA
-- ================================================================

-- B1. Promedio diario del sensor 1 con cantidad de lecturas.
SELECT
    DATE(fecha_hora) AS dia,
    ROUND(AVG(valor), 2) AS promedio,
    COUNT(*) AS n
FROM lecturas
WHERE sensor_id = 1
  AND fecha_hora >= '2026-04-01'
  AND fecha_hora < '2026-05-01'
GROUP BY DATE(fecha_hora)
ORDER BY dia;

-- B2. Curva diaria por hora del sensor 1.
SELECT
    CAST(strftime('%H', fecha_hora) AS INTEGER) AS hora,
    ROUND(AVG(valor), 2) AS promedio,
    COUNT(*) AS n
FROM lecturas
WHERE sensor_id = 1
  AND fecha_hora >= '2026-04-01'
  AND fecha_hora < '2026-05-01'
GROUP BY strftime('%H', fecha_hora)
ORDER BY hora;

-- B3. Lecturas por mes.
SELECT
    strftime('%Y-%m', fecha_hora) AS mes,
    COUNT(*) AS n
FROM lecturas
GROUP BY strftime('%Y-%m', fecha_hora)
ORDER BY mes;

-- B4. Rango con BETWEEN.
SELECT COUNT(*) AS n
FROM lecturas
WHERE fecha_hora BETWEEN '2026-04-01' AND '2026-04-30';

SELECT COUNT(*) AS n
FROM lecturas
WHERE fecha_hora >= '2026-04-01'
  AND fecha_hora < '2026-05-01';

SELECT COUNT(*) AS n
FROM lecturas
WHERE DATE(fecha_hora) = '2026-04-30';

-- B4 - Respuesta:
-- BETWEEN es inclusivo en ambos extremos, pero el limite superior
-- es exactamente el texto '2026-04-30'. Las horas del ultimo dia son
-- textos como '2026-04-30 03:00:00'. Al comparar lexicograficamente,
-- '2026-04-30 03:00:00' es mayor que '2026-04-30', por lo que esas
-- filas quedan fuera del BETWEEN. Por eso se obtienen 905 en lugar
-- de 937. El rango correcto para un mes es >= primer instante y
-- < primer instante del mes siguiente.

-- ================================================================
-- PARTE C - AUDITAR LA SERIE
-- ================================================================

-- C1. Sensor 1: minimo, maximo y promedio crudo.
SELECT
    MIN(valor) AS minimo,
    MAX(valor) AS maximo,
    ROUND(AVG(valor), 2) AS promedio,
    COUNT(*) AS n
FROM lecturas
WHERE sensor_id = 1
  AND fecha_hora >= '2026-04-01'
  AND fecha_hora < '2026-05-01';

-- C1. Promedio excluyendo el codigo de falla.
SELECT
    ROUND(AVG(valor), 2) AS promedio_sin_fallas,
    COUNT(*) AS n
FROM lecturas
WHERE sensor_id = 1
  AND fecha_hora >= '2026-04-01'
  AND fecha_hora < '2026-05-01'
  AND valor <> -99;

-- C1 - Respuesta:
-- La diferencia de aproximadamente 1.5 grados es mas peligrosa que
-- una diferencia enorme porque parece un resultado plausible.
-- Un valor absurdo de -99 puede llamar la atencion de inmediato,
-- mientras que un promedio ligeramente sesgado puede pasar como
-- una medicion normal y terminar en decisiones operativas incorrectas.

-- C2. Cantidad de lecturas averiadas y dias afectados.
SELECT
    COUNT(*) AS lecturas_averiadas
FROM lecturas
WHERE sensor_id = 1
  AND valor = -99
  AND fecha_hora >= '2026-04-01'
  AND fecha_hora < '2026-04-30';

SELECT
    DATE(fecha_hora) AS dia,
    ROUND(AVG(valor), 2) AS promedio_crudo,
    COUNT(*) AS n
FROM lecturas
WHERE sensor_id = 1
  AND valor = -99
  AND fecha_hora >= '2026-04-01'
  AND fecha_hora < '2026-05-01'
GROUP BY DATE(fecha_hora)
ORDER BY dia;

-- Para mostrar el promedio crudo de esos dos dias con todas sus
-- lecturas, no solamente las averiadas:
SELECT
    DATE(fecha_hora) AS dia,
    ROUND(AVG(valor), 2) AS promedio_crudo,
    COUNT(*) AS n
FROM lecturas
WHERE sensor_id = 1
  AND fecha_hora >= '2026-04-01'
  AND fecha_hora < '2026-05-01'
  AND DATE(fecha_hora) IN ('2026-04-19', '2026-04-20')
GROUP BY DATE(fecha_hora)
ORDER BY dia;

-- C3. Este GROUP BY NO encuentra dias faltantes:
SELECT
    DATE(fecha_hora) AS dia,
    COUNT(*) AS n
FROM lecturas
WHERE sensor_id = 2
GROUP BY dia
HAVING n <> 8;

-- C3 - Respuesta:
-- No encuentra los dias 11, 12 y 13 porque no existe ninguna fila
-- para esos dias. GROUP BY solamente puede formar grupos a partir
-- de filas existentes. Un dia sin filas no genera un grupo con n=0;
-- simplemente no aparece.

-- C3. Calendario generado para encontrar dias faltantes.
WITH RECURSIVE dias(d) AS (
    SELECT '2026-04-01'
    UNION ALL
    SELECT DATE(d, '+1 day')
    FROM dias
    WHERE d < '2026-04-30'
)
SELECT d
FROM dias
WHERE d NOT IN (
    SELECT DATE(fecha_hora)
    FROM lecturas
    WHERE sensor_id = 2
)
ORDER BY d;

-- C4. Huecos detectados comparando cada lectura con la anterior.
SELECT
    sensor_id,
    anterior,
    fecha_hora,
    ROUND(
        (julianday(fecha_hora) - julianday(anterior)) * 24,
        1
    ) AS horas_sin_medir
FROM (
    SELECT
        sensor_id,
        fecha_hora,
        LAG(fecha_hora) OVER (
            PARTITION BY sensor_id
            ORDER BY fecha_hora
        ) AS anterior
    FROM lecturas
)
WHERE anterior IS NOT NULL
  AND (julianday(fecha_hora) - julianday(anterior)) * 24 > 3;

-- C4 - Respuesta:
-- El hueco corresponde a 75 horas y no 72 porque se mide desde la
-- ultima lectura existente antes del hueco hasta la primera lectura
-- existente despues del hueco. La distancia incluye el intervalo
-- normal que precede al primer dia faltante y los tres dias completos
-- sin mediciones: 3 + 72 = 75 horas.

-- C5. Duplicados por sensor y fecha/hora.
SELECT
    sensor_id,
    fecha_hora,
    COUNT(*) AS n
FROM lecturas
GROUP BY sensor_id, fecha_hora
HAVING COUNT(*) > 1;

-- C5 - Restriccion que habria impedido el duplicado:
-- ALTER TABLE lecturas ADD CONSTRAINT uq_lecturas_sensor_fecha
-- UNIQUE (sensor_id, fecha_hora);
--
-- SQLite no permite agregar una restriccion UNIQUE de esta forma
-- mediante ALTER TABLE. En el diseno de la tabla se puede declarar:
-- UNIQUE (sensor_id, fecha_hora)
-- dentro de CREATE TABLE, o crear un indice unico:
-- CREATE UNIQUE INDEX uq_lecturas_sensor_fecha
-- ON lecturas(sensor_id, fecha_hora);

-- ================================================================
-- PARTE D - REPORTE ENTREGABLE
-- ================================================================

-- D1. Promedio de abril por finca, lote y tipo de sensor.
-- Se excluyen las lecturas de falla y se usa rango semiabierto.
SELECT
    f.nombre AS finca,
    l.codigo AS lote,
    s.tipo,
    COUNT(*) AS n,
    ROUND(AVG(r.valor), 2) AS promedio
FROM lecturas AS r
JOIN sensores AS s ON s.sensor_id = r.sensor_id
JOIN lotes AS l ON l.lote_id = s.lote_id
JOIN fincas AS f ON f.finca_id = l.finca_id
WHERE r.fecha_hora >= '2026-04-01'
  AND r.fecha_hora < '2026-05-01'
  AND NOT (s.sensor_id = 1 AND r.valor = -99)
GROUP BY f.finca_id, f.nombre, l.lote_id, l.codigo, s.sensor_id, s.tipo
ORDER BY f.nombre, l.codigo, s.tipo;

-- D2. Alertas diarias del sensor 1.
WITH dias_sensor AS (
    SELECT
        DATE(fecha_hora) AS dia,
        MAX(valor) AS maxima,
        COUNT(*) AS n
    FROM lecturas
    WHERE sensor_id = 1
      AND fecha_hora >= '2026-04-01'
      AND fecha_hora < '2026-05-01'
      AND valor <> -99
    GROUP BY DATE(fecha_hora)
)
SELECT
    dia,
    maxima,
    n,
    CASE
        WHEN maxima >= 32 THEN 'ALERTA CALOR'
        WHEN maxima >= 30 THEN 'atencion'
        ELSE 'normal'
    END AS estado
FROM dias_sensor
WHERE maxima >= 30
ORDER BY dia;

-- D3. Cantidad de dias por estado.
WITH dias_sensor AS (
    SELECT
        DATE(fecha_hora) AS dia,
        MAX(valor) AS maxima,
        COUNT(*) AS n
    FROM lecturas
    WHERE sensor_id = 1
      AND fecha_hora >= '2026-04-01'
      AND fecha_hora < '2026-05-01'
      AND valor <> -99
    GROUP BY DATE(fecha_hora)
),
clasificados AS (
    SELECT
        dia,
        n,
        CASE
            WHEN maxima >= 32 THEN 'ALERTA CALOR'
            WHEN maxima >= 30 THEN 'atencion'
            ELSE 'normal'
        END AS estado
    FROM dias_sensor
)
SELECT
    estado,
    COUNT(*) AS dias
FROM clasificados
GROUP BY estado
ORDER BY CASE estado
    WHEN 'ALERTA CALOR' THEN 1
    WHEN 'atencion' THEN 2
    ELSE 3
END;

-- D4. Riego con lecturas del mismo dia y mismo lote.
-- Las cinco tablas son: labores, siembras, lotes, sensores y lecturas.
SELECT
    la.labor_id,
    la.fecha,
    l.codigo AS lote,
    f.nombre AS finca,
    COUNT(r.lectura_id) AS n
FROM labores AS la
JOIN siembras AS si
    ON si.siembra_id = la.siembra_id
JOIN lotes AS l
    ON l.lote_id = si.lote_id
JOIN fincas AS f
    ON f.finca_id = l.finca_id
JOIN sensores AS s
    ON s.lote_id = l.lote_id
JOIN lecturas AS r
    ON r.sensor_id = s.sensor_id
   AND DATE(r.fecha_hora) = la.fecha
WHERE la.tipo_labor = 'riego'
  AND la.fecha >= '2026-04-01'
  AND la.fecha < '2026-05-01'
GROUP BY
    la.labor_id,
    la.fecha,
    l.lote_id,
    l.codigo,
    f.finca_id,
    f.nombre
HAVING COUNT(r.lectura_id) > 1
ORDER BY la.fecha;

-- D4 - Pregunta de negocio:
-- ¿Que comportamiento mostraban los sensores del lote el mismo dia
-- en que se realizo un riego?
--
-- Al modelo le falta registrar una relacion explicita entre la labor
-- de riego y el evento/medicion del sensor, por ejemplo un identificador
-- de evento de riego, hora de inicio/fin o cantidad de agua aplicada.
-- Con solo fecha y lote podemos asociar lecturas temporalmente, pero
-- no saber con precision que mediciones fueron causadas por ese riego
-- ni evaluar su efecto.

-- ================================================================
-- PARTE E - CIERRE
-- ================================================================

-- E1 - Respuesta:
-- El BETWEEN es probablemente el mas dificil de detectar despues de
-- entregar el reporte. El reporte devuelve un numero valido, no un
-- error, y solo omite las lecturas con hora del ultimo dia. El hueco,
-- el duplicado y el -99 pueden dejar otras pistas en los conteos o
-- valores; en cambio, un BETWEEN mal planteado puede parecer correcto
-- durante mucho tiempo.

-- E2. Restricciones recomendadas:
-- Para una temperatura cuyo rango valido sea, por ejemplo, -20 a 60:
-- CHECK (valor >= -20 AND valor <= 60)
--
-- Y para impedir duplicados:
-- UNIQUE (sensor_id, fecha_hora)
--
-- Si se agregan hoy, no corrigen ni eliminan automaticamente las filas
-- malas que ya estan cargadas. Primero hay que identificarlas y
-- corregirlas/eliminarlas. Ademas, una restriccion UNIQUE no podra
-- crearse mientras existan duplicados que la violen.

-- E3 - Respuesta:
-- A esa escala puede dejar de funcionar bien un reporte que haga
-- GROUP BY/ORDER BY sobre millones de lecturas sin indices adecuados:
-- aumentaran los tiempos de consulta y el costo de recorrer y agrupar
-- grandes cantidades de filas.

-- ================================================================
-- EXTRA +5 - QUINTO PROBLEMA DE CALIDAD
-- ================================================================

-- Detectar sensores dados de baja que todavia tienen lecturas.
-- El sensor 3 esta activo = 0 y conserva 40 lecturas historicas.
-- No necesariamente es un error historico (pueden ser utiles), pero
-- es una alerta de calidad/consistencia operacional: una consulta
-- actual podria mezclar facilmente datos de un sensor fuera de servicio.
SELECT
    s.sensor_id,
    s.activo,
    COUNT(r.lectura_id) AS n_lecturas,
    MIN(r.fecha_hora) AS primera_lectura,
    MAX(r.fecha_hora) AS ultima_lectura
FROM sensores AS s
JOIN lecturas AS r ON r.sensor_id = s.sensor_id
WHERE s.activo = 0
GROUP BY s.sensor_id, s.activo
ORDER BY s.sensor_id;

-- ================================================================
-- FIN DEL EJERCICIO 6
-- ================================================================
