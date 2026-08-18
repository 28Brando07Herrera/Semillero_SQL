-- =====================================================================
-- CURSO DE SQL  |  AgroDB  |  Ejercicio 6
-- Alumno: Byron Yaguar
-- Fecha: 2026-08-18
--
-- Este archivo se ejecuta DESPUES de datos/agrodb_clase6.sql,
-- en la MISMA sesion de sqliteonline.
-- =====================================================================
PRAGMA foreign_keys = ON;

-- =====================================================================
-- PARTE A - DIAGNOSTICO
-- =====================================================================

-- A1. Estructura de la tabla lecturas
SELECT * FROM lecturas LIMIT 10;

-- A1 RESPUESTA:
-- SQLite no tiene un tipo DATETIME nativo; guarda las fechas como TEXT.
-- Esto ocurre porque SQLite es minimalista y usa TEXT para máxima flexibilidad.
-- Consecuencia para nosotros: debemos convertir fecha_hora a funciones como DATE(),
-- strftime(), julianday() antes de hacer cálculos. Sin conversión, '2026-04-30'
-- no es < '2026-04-30 03:00:00' en comparación textual.

-- A2. Cuántas lecturas por sensor, con su primera y última medición
SELECT sensor_id,
       COUNT(*) AS n_lecturas,
       MIN(fecha_hora) AS primera_lectura,
       MAX(fecha_hora) AS ultima_lectura
FROM lecturas
GROUP BY sensor_id
ORDER BY sensor_id;

-- A2 RESPUESTA:
-- Esperado: 5 filas. Un sensor tiene solo 40 lecturas todas de febrero porque
-- ese sensor (sensor_id = 5) fue instalado después de que terminara febrero,
-- pero sus lecturas viejas quedaron en la base. Está obsoleto o fue un error de carga.

-- A3. Sensores sin ninguna lectura
SELECT s.sensor_id, s.lote_id, l.nombre AS lote, f.nombre AS finca
FROM sensores s
LEFT JOIN lotes l ON s.lote_id = l.lote_id
LEFT JOIN fincas f ON l.finca_id = f.finca_id
WHERE s.sensor_id NOT IN (SELECT DISTINCT sensor_id FROM lecturas);

-- A3 RESPUESTA:
-- Esperado: 1 sensor. Usa LEFT JOIN para incluir sensores incluso si no tienen lecturas,
-- luego WHERE NOT IN para filtrar solo los ausentes en la tabla lecturas.

-- A4. Diferencias entre tres estados de sensor
-- En comentario:
-- - Sensor con activo = 0: el registro existe, está marcado como inactivo, pero podría tener lecturas históricas.
-- - Sensor sin lecturas: existe en la tabla sensores pero NUNCA ha enviado datos (LEFT JOIN + IS NULL).
-- - Sensor con lecturas pero ninguna reciente: tiene datos históricos pero nada desde hace semanas/meses
--   (como sensor_id = 5 que solo tiene febrero).

-- =====================================================================
-- PARTE B - FUNCIONES DE FECHA
-- =====================================================================

-- B1. Promedio diario del sensor 1 con conteo de lecturas
SELECT DATE(fecha_hora) AS dia,
       COUNT(*) AS n_lecturas,
       ROUND(AVG(valor), 2) AS promedio_temp
FROM lecturas
WHERE sensor_id = 1
GROUP BY DATE(fecha_hora)
ORDER BY dia;

-- B1 ESPERADO: 30 filas, primeras cinco: 21.63, 22.63, 23.63, 24.63, 25.63

-- B2. Curva del día: promedio por hora del día (sensor 1)
SELECT strftime('%H', fecha_hora) AS hora,
       COUNT(*) AS n_lecturas,
       ROUND(AVG(valor), 2) AS promedio_temp
FROM lecturas
WHERE sensor_id = 1
GROUP BY strftime('%H', fecha_hora)
ORDER BY CAST(hora AS INTEGER);

-- B2 ESPERADO: 8 filas con curva que sube al mediodía y baja de madrugada

-- B3. Lecturas por mes (toda la tabla)
SELECT strftime('%Y-%m', fecha_hora) AS mes,
       COUNT(*) AS n_lecturas
FROM lecturas
GROUP BY strftime('%Y-%m', fecha_hora)
ORDER BY mes;

-- B3 ESPERADO: 2 filas - febrero 40, abril 937

-- B4. La trampa del BETWEEN
SELECT 'BETWEEN' AS metodo, COUNT(*) AS n FROM lecturas
WHERE fecha_hora BETWEEN '2026-04-01' AND '2026-04-30'
UNION ALL
SELECT '>=/<' AS metodo, COUNT(*) AS n FROM lecturas
WHERE fecha_hora >= '2026-04-01' AND fecha_hora < '2026-05-01';

-- Verificar lecturas del 30 de abril específicamente
SELECT COUNT(*) AS abril_30 FROM lecturas WHERE DATE(fecha_hora) = '2026-04-30';

-- B4 RESPUESTA:
-- BETWEEN da 905, >= y < da 937. Faltan 32 lecturas.
-- El BETWEEN pierde las 32 del 30 de abril porque '2026-04-30' como texto es < '2026-04-30 03:00:00'.
-- BETWEEN '2026-04-01' AND '2026-04-30' termina en '2026-04-30' (medianoche),
-- no en '2026-04-30 23:59:59'. Cualquier lectura de abril 30 después de medianoche queda fuera.
-- Es la trampa más cara: un reporte mensual que se come el último día no da error, solo silenciosamente faltan datos.

-- =====================================================================
-- PARTE C - AUDITAR LA SERIE
-- =====================================================================

-- C1. Valor imposible: sensor 1
SELECT MIN(valor) AS minimo,
       MAX(valor) AS maximo,
       ROUND(AVG(valor), 2) AS promedio_crudo
FROM lecturas
WHERE sensor_id = 1;

-- C1a. Sin valores averiados (-99)
SELECT ROUND(AVG(valor), 2) AS promedio_limpio
FROM lecturas
WHERE sensor_id = 1 AND valor <> -99;

-- C1 RESPUESTA:
-- Mínimo -99, máximo 32, promedio crudo 22.15, promedio limpio 23.68.
-- La diferencia de 1.5 grados es PEOR que 20 grados porque es invisible.
-- Un reporte que muestra 22.15 parece plausible. Nadie notaría que hay un -99 escondido.
-- Con 20 grados de diferencia evidente, alguien preguntaría qué pasó.
-- Los errores silenciosos son más peligrosos que los errores obvios.

-- C2. Cuántas lecturas averiadas y de qué días
SELECT DATE(fecha_hora) AS dia,
       COUNT(*) AS n_averiadas,
       ROUND(AVG(valor), 2) AS promedio_con_error
FROM lecturas
WHERE sensor_id = 1 AND valor = -99
GROUP BY DATE(fecha_hora)
ORDER BY dia;

-- C2 RESPUESTA:
-- 3 lecturas averiadas en 2 días. Los promedios diarios crudos son 9.38 y -4.25.
-- Un promedio de -4.25°C en abril en Los Ríos es imposible biológicamente.
-- Ese número habría llegado al tablero sin auditoría.

-- C3a. El camino que NO funciona (GROUP BY sin calendario)
SELECT DATE(fecha_hora) AS dia, COUNT(*) AS n
FROM lecturas
WHERE sensor_id = 2
GROUP BY dia
HAVING n <> 8;

-- C3a RESPUESTA:
-- Da 0 filas aunque falten 3 días. Un GROUP BY solo agrupa lo que existe.
-- Un día sin registros no es un "grupo vacío" — simplemente no existe como grupo.
-- Para encontrar lo que NO existe, necesitamos un calendario generado.

-- C3b. Encontrar huecos con calendario recursivo
WITH RECURSIVE dias(d) AS (
    SELECT '2026-04-01'
    UNION ALL
    SELECT DATE(d, '+1 day') FROM dias WHERE d < '2026-04-30'
)
SELECT d AS dia_faltante
FROM dias
WHERE d NOT IN (SELECT DATE(fecha_hora) FROM lecturas WHERE sensor_id = 2)
ORDER BY d;

-- C3 ESPERADO: 3 días - 11, 12, 13 de abril

-- C4. Detectar huecos con LAG (comparar con lectura anterior)
SELECT sensor_id,
       anterior,
       fecha_hora,
       ROUND((julianday(fecha_hora) - julianday(anterior)) * 24, 1) AS horas_sin_medir
FROM (
  SELECT sensor_id, fecha_hora,
         LAG(fecha_hora) OVER (PARTITION BY sensor_id ORDER BY fecha_hora) AS anterior
  FROM lecturas
)
WHERE anterior IS NOT NULL
  AND (julianday(fecha_hora) - julianday(anterior)) * 24 > 3
ORDER BY horas_sin_medir DESC;

-- C4 RESPUESTA:
-- 1 fila con 75 horas. No 72 porque se cuenta desde la ÚLTIMA lectura buena (antes del hueco)
-- hasta la PRIMERA lectura DESPUÉS del hueco, ambas inclusivas. 3 días × 24 horas + 3 horas extras.

-- C5. Duplicados: mismo sensor, misma fecha_hora
SELECT sensor_id,
       fecha_hora,
       COUNT(*) AS cuantas_veces
FROM lecturas
GROUP BY sensor_id, fecha_hora
HAVING COUNT(*) > 1
ORDER BY sensor_id, fecha_hora;

-- C5 RESPUESTA:
-- 1 fila - sensor 1, 2026-04-07 12:00:00.
-- La restricción que falta en lecturas es:
-- UNIQUE (sensor_id, fecha_hora)
-- Esto habría impedido que la misma lectura entrara dos veces.
-- Si se agrega hoy, la BD rechazaría la carga de datos viejos que tienen el duplicado.

-- =====================================================================
-- PARTE D - EL REPORTE
-- =====================================================================

-- D1. Promedio de abril por finca, lote, tipo sensor
-- (excluyendo averiadas, usando rango de fechas correcto)
SELECT f.nombre AS finca,
       l.nombre AS lote,
       s.tipo AS tipo_sensor,
       COUNT(*) AS n,
       ROUND(AVG(l2.valor), 2) AS promedio
FROM lecturas l2
JOIN sensores s ON l2.sensor_id = s.sensor_id
JOIN lotes l ON s.lote_id = l.lote_id
JOIN fincas f ON l.finca_id = f.finca_id
WHERE DATE(l2.fecha_hora) >= '2026-04-01'
  AND DATE(l2.fecha_hora) < '2026-05-01'
  AND l2.valor <> -99
GROUP BY f.finca_id, l.lote_id, s.tipo
ORDER BY f.nombre, l.nombre, s.tipo;

-- D1 ESPERADO: 4 filas
-- Finca La Union, L-01, humedad, 240, 79.38
-- Finca El Guayabo, L-01, radiacion, 240, 278.75
-- Hacienda Santa Rosa, L-01, humedad, 216, 76.91
-- Hacienda Santa Rosa, L-01, temperatura, 238, 23.68

-- D2. Alertas por temperatura máxima diaria (sensor 1)
SELECT DATE(fecha_hora) AS dia,
       MAX(valor) AS temp_max,
       CASE
         WHEN MAX(valor) >= 32 THEN 'ALERTA CALOR'
         WHEN MAX(valor) >= 30 THEN 'atencion'
         ELSE 'normal'
       END AS estado
FROM lecturas
WHERE sensor_id = 1
GROUP BY DATE(fecha_hora)
HAVING estado <> 'normal'
ORDER BY dia;

-- D2 ESPERADO: 18 filas (días no normales)

-- D3. Resumen de alertas
SELECT CASE
         WHEN MAX(valor) >= 32 THEN 'ALERTA CALOR'
         WHEN MAX(valor) >= 30 THEN 'atencion'
         ELSE 'normal'
       END AS estado,
       COUNT(*) AS dias
FROM (
  SELECT DATE(fecha_hora) AS dia, MAX(valor) AS max_valor
  FROM lecturas
  WHERE sensor_id = 1
  GROUP BY DATE(fecha_hora)
)
GROUP BY estado
ORDER BY CASE estado
         WHEN 'ALERTA CALOR' THEN 1
         WHEN 'atencion' THEN 2
         WHEN 'normal' THEN 3
       END;

-- D3 ESPERADO: ALERTA CALOR 6, atencion 12, normal 12

-- D4. Labores de riego con sensores del mismo día y lote
SELECT l.labor_id,
       DATE(l.fecha_labor) AS dia_labor,
       lo.nombre AS lote,
       f.nombre AS finca,
       COUNT(DISTINCT lec.lectura_id) AS n_lecturas_sensor
FROM labores l
JOIN lotes lo ON l.lote_id = lo.lote_id
JOIN fincas f ON lo.finca_id = f.finca_id
JOIN sensores s ON s.lote_id = lo.lote_id
JOIN lecturas lec ON s.sensor_id = lec.sensor_id
WHERE l.tipo_labor = 'riego'
  AND DATE(l.fecha_labor) = DATE(lec.fecha_hora)
GROUP BY l.labor_id, lo.lote_id, s.sensor_id
ORDER BY l.labor_id;

-- D4 ESPERADO: 1 fila - labor 14, 2026-04-14, L-01, 8 lecturas

-- D4 COMENTARIO:
-- Pregunta de negocio: "¿Qué riegos se hicieron en condiciones de humedad específicas?"
-- Le falta al modelo: una tabla de "objetivos" o "recetas" que diga
-- "en L-01 cuando la humedad es < 70% es hora de riego". Hoy solo podemos
-- cruzar los datos; no podemos validar si el riego fue en el momento correcto.

-- =====================================================================
-- PARTE E - CIERRE
-- =====================================================================

-- 1) De los cuatro problemas (hueco, valor de falla, duplicado, BETWEEN),
--    ¿cuál es el más difícil de detectar una vez entregado el reporte?
-- RESPUESTA: El BETWEEN. El hueco se nota cuando falta un sensor del reporte.
-- El duplicado se nota si comparas dos reportes. El valor de falla (-99) es un código explícito.
-- Pero BETWEEN que pierde el último día NO da error, NO suma mal (suma 905 de 937 tan tranquilo),
-- y nadie nota hasta que diciembre cierra con 11 meses completos en lugar de 12.

-- 2) Restricciones que le agregarías a lecturas:
-- CHECK (valor >= -50 AND valor <= 150) -- Temperatura plausible
-- UNIQUE (sensor_id, fecha_hora) -- No duplicados
-- Problema: Si las agregas hoy, SQLite rechaza la carga porque ya existen filas que las violarían.
-- Habría que limpiar primero (borrar los -99 y el duplicado).

-- 3) Una cosa que va a dejar de funcionar bien a escala (17.500+ lecturas, 200+ sensores):
-- El acceso sin índices. Con 500k filas, un SELECT sin índice en (sensor_id, fecha_hora)
-- se va a hacer muy lento. Necesitaríamos índices compuestos para las consultas comunes.