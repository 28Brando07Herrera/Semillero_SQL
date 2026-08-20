-- ============================================================================
-- EJERCICIO PRÁCTICO 6: El sensor que mintió tres días
-- Estudiante: Cortez Axel
-- Motor: SQLite | Entorno: sqliteonline.com
-- ============================================================================

PRAGMA foreign_keys = ON;

-- PARTE A · CONOCER LA TABLA NUEVA

-- A1. Inspección inicial de la tabla lecturas
SELECT * FROM lecturas LIMIT 10;

/*
EXPLICACIÓN A1:
SQLite no cuenta con un tipo de dato de almacenamiento específico para DATETIME; maneja 
las fechas y horas usando tipos de almacenamiento primitivos (TEXT en formato ISO8601, REAL o INTEGER).
La consecuencia para nosotros es que la integridad de fecha no se valida por tipo: el motor trata 
el campo como una simple cadena de texto y exige que utilicemos el formato estándar 'YYYY-MM-DD HH:MM:SS'
junto con funciones de fecha especializadas (DATE, strftime, julianday) para poder ordenar, filtrar o calcular.
*/


-- A2. Conteo de lecturas por sensor, primera y última medición
SELECT 
    sensor_id,
    COUNT(*) AS total_lecturas,
    MIN(fecha_hora) AS primera_medicion,
    MAX(fecha_hora) AS ultima_medicion
FROM lecturas
GROUP BY sensor_id
ORDER BY sensor_id;

/*
EXPLICACIÓN A2 (Sensor 3):
El sensor 3 tiene 40 lecturas de febrero y ninguna de abril porque fue dado de baja (activo = 0) 
el 03/02/2026. Sus mediciones históricas permanecen en la base de datos, por lo que cualquier 
promedio que no filtre por rango de fechas mezclaría datos viejos e inactivos con el mes actual.
*/


-- A3. Sensores sin ninguna lectura registrada (LEFT JOIN + IS NULL)
SELECT 
    s.sensor_id,
    s.tipo,
    s.modelo,
    f.nombre AS finca,
    l.codigo AS lote
FROM sensores s
JOIN lotes l ON s.lote_id = l.lote_id
JOIN fincas f ON l.finca_id = f.finca_id
LEFT JOIN lecturas lec ON s.sensor_id = lec.sensor_id
WHERE lec.lectura_id IS NULL;


/*
EXPLICACIÓN A4:
- Sensor con 'activo = 0': Es un sensor dado de baja u operativamente inactivo (Sensores 3 y 5).
- Sensor sin lecturas: Es un equipo instalado que nunca ha enviado ninguna medición a la base (Sensor 5).
- Sensor con lecturas pero ninguna reciente: Es un sensor que registró datos en el pasado pero dejó de reportar 
  en el periodo analizado (Sensor 3, cuyas mediciones son de febrero).
*/


-- PARTE B · LAS FUNCIONES DE FECHA

-- B1. Promedio diario del sensor 1 con conteo de lecturas por día
SELECT 
    DATE(fecha_hora) AS dia,
    COUNT(*) AS n_lecturas,
    ROUND(AVG(valor), 2) AS promedio_diario
FROM lecturas
WHERE sensor_id = 1
GROUP BY dia
ORDER BY dia;


-- B2. Curva diaria: Promedio del sensor 1 agrupado por hora del día
-- Esperado: 8 filas (0, 3, 6, 9, 12, 15, 18, 21)
SELECT 
    strftime('%H', fecha_hora) AS hora_dia,
    COUNT(*) AS n_lecturas,
    ROUND(AVG(valor), 2) AS promedio_temperatura
FROM lecturas
WHERE sensor_id = 1
GROUP BY hora_dia
ORDER BY hora_dia;


-- B3. Total de lecturas por mes de toda la tabla
-- Esperado: 2 filas (2026-02 con 40, 2026-04 con 937)
SELECT 
    strftime('%Y-%m', fecha_hora) AS mes,
    COUNT(*) AS total_lecturas
FROM lecturas
GROUP BY mes
ORDER BY mes;


-- B4. La trampa del BETWEEN y fechas de texto
-- Consulta 1 (BETWEEN): devuelve 905 lecturas
SELECT COUNT(*) AS total_between FROM lecturas
WHERE fecha_hora BETWEEN '2026-04-01' AND '2026-04-30';

-- Consulta 2 (Rango semiabierto): devuelve 937 lecturas
SELECT COUNT(*) AS total_rango_correcto FROM lecturas
WHERE fecha_hora >= '2026-04-01' AND fecha_hora < '2026-05-01';

-- Localización de las 32 lecturas perdidas del 30 de abril:
SELECT COUNT(*) AS lecturas_30_abril FROM lecturas WHERE DATE(fecha_hora) = '2026-04-30';

/*
EXPLICACIÓN B4:
Al comparar texto, '2026-04-30' equivale a '2026-04-30 00:00:00'.
La cláusula 'BETWEEN 2026-04-01 AND 2026-04-30' evalúa si la cadena 'fecha_hora' es alfabéticamente menor o igual a '2026-04-30'.
Cualquier registro posterior como '2026-04-30 03:00:00' es alfabéticamente mayor a '2026-04-30', 
por lo que el BETWEEN descarta todas las mediciones del 30 de abril excepto la de medianoche (00:00:00).
*/


-- PARTE C · AUDITAR LA SERIE

-- C1. El valor imposible (Sensor 1)
-- Valores crudos: min -99, max 32, promedio 22.15 (conteo: 241 lecturas)
SELECT 
    COUNT(*) AS n_crudo,
    MIN(valor) AS min_crudo,
    MAX(valor) AS max_crudo,
    ROUND(AVG(valor), 2) AS promedio_crudo
FROM lecturas
WHERE sensor_id = 1 AND fecha_hora >= '2026-04-01' AND fecha_hora < '2026-05-01';

-- Promedio limpio excluyendo valores de falla (valor > 0): promedio 23.68 (conteo: 238 lecturas)
SELECT 
    COUNT(*) AS n_limpio,
    MIN(valor) AS min_limpio,
    MAX(valor) AS max_limpio,
    ROUND(AVG(valor), 2) AS promedio_limpio
FROM lecturas
WHERE sensor_id = 1 
  AND fecha_hora >= '2026-04-01' AND fecha_hora < '2026-05-01'
  AND valor > 0;

/*
EXPLICACIÓN C1:
Una diferencia de grado y medio (1.53 °C) es mucho más peligrosa porque cae dentro de rangos climáticos verosímiles 
y no levanta sospechas a simple vista en un tablero, provocando decisiones agronómicas erróneas. Si la diferencia fuera 
de veinte grados, cualquier operador detectaría de inmediato que el dato está corrompido.
*/


-- C2. Lecturas averiadas y promedio crudo de esos días
-- Esperado: 3 lecturas en 2 días (2026-04-19 y 2026-04-20)
SELECT lectura_id, sensor_id, fecha_hora, valor
FROM lecturas
WHERE sensor_id = 1 AND valor = -99;

-- Promedios crudos de los días afectados: 2026-04-19 con 9.38 y 2026-04-20 con -4.25
SELECT 
    DATE(fecha_hora) AS dia,
    COUNT(*) AS n_lecturas,
    ROUND(AVG(valor), 2) AS promedio_crudo
FROM lecturas
WHERE sensor_id = 1 AND DATE(fecha_hora) IN ('2026-04-19', '2026-04-20')
GROUP BY dia;


-- C3. El hueco: Identificar días faltantes del sensor 2
-- Camino fallido con GROUP BY: devuelve 0 filas porque los días ausentes no generan grupo.
SELECT DATE(fecha_hora) AS dia, COUNT(*) AS n
FROM lecturas WHERE sensor_id = 2
GROUP BY dia HAVING n <> 8;

-- Identificación real mediante calendario recursivo:
-- Esperado: 3 días (2026-04-11, 2026-04-12, 2026-04-13)
WITH RECURSIVE dias(d) AS (
    SELECT '2026-04-01'
    UNION ALL
    SELECT DATE(d, '+1 day') FROM dias WHERE d < '2026-04-30'
)
SELECT d AS dia_faltante FROM dias
WHERE d NOT IN (SELECT DATE(fecha_hora) FROM lecturas WHERE sensor_id = 2);


-- C4. Detección del salto temporal usando LAG()

SELECT sensor_id, anterior, fecha_hora,
       ROUND((julianday(fecha_hora) - julianday(anterior)) * 24, 1) AS horas_sin_medir
FROM (
  SELECT sensor_id, fecha_hora,
         LAG(fecha_hora) OVER (PARTITION BY sensor_id ORDER BY fecha_hora) AS anterior
  FROM lecturas
)
WHERE anterior IS NOT NULL
  AND (julianday(fecha_hora) - julianday(anterior)) * 24 > 3;

/*
EXPLICACIÓN C4:
Da 75 horas y no 72 porque se mide el lapso completo transcurrido entre la última lectura válida 
(10/04 a las 21:00) y la primera lectura tras el restablecimiento (14/04 a las 00:00). 
Son 3 días completos sin medir (72 horas) más el intervalo normal de muestreo de 3 horas (72 + 3 = 75 h).
*/


-- C5. Detección de duplicados (Mismo sensor y fecha_hora)

SELECT sensor_id, fecha_hora, COUNT(*) AS total
FROM lecturas
GROUP BY sensor_id, fecha_hora
HAVING COUNT(*) > 1;

/*
RESTRICCIÓN FALTANTE:
UNIQUE (sensor_id, fecha_hora)
o bien:
CREATE UNIQUE INDEX idx_lecturas_sensor_fecha ON lecturas (sensor_id, fecha_hora);
*/


-- PARTE D · EL REPORTE QUE SÍ SE PUEDE ENTREGAR

-- D1. Promedio limpio de abril por finca, lote y tipo de sensor

SELECT 
    f.nombre AS finca,
    l.codigo AS lote,
    s.tipo,
    COUNT(*) AS n,
    ROUND(AVG(lec.valor), 2) AS promedio
FROM lecturas lec
JOIN sensores s ON lec.sensor_id = s.sensor_id
JOIN lotes l ON s.lote_id = l.lote_id
JOIN fincas f ON l.finca_id = f.finca_id
WHERE lec.fecha_hora >= '2026-04-01' AND lec.fecha_hora < '2026-05-01'
  AND lec.valor > 0
GROUP BY f.finca_id, l.lote_id, s.tipo
ORDER BY f.nombre, s.tipo;


-- D2. Alertas térmicas diarias en Sensor 1 (Días no normales)
-- Esperado: 18 filas
WITH max_diarios AS (
    SELECT 
        DATE(fecha_hora) AS dia,
        MAX(valor) AS max_temp
    FROM lecturas
    WHERE sensor_id = 1 
      AND fecha_hora >= '2026-04-01' AND fecha_hora < '2026-05-01'
      AND valor > 0
    GROUP BY dia
)
SELECT 
    dia,
    max_temp,
    CASE 
        WHEN max_temp >= 32 THEN 'ALERTA CALOR'
        WHEN max_temp >= 30 THEN 'atencion'
        ELSE 'normal'
    END AS estado
FROM max_diarios
WHERE max_temp >= 30
ORDER BY dia;


-- D3. Resumen de estados térmicos del mes
-- Esperado: ALERTA CALOR 6 · atencion 12 · normal 12 (Total: 30)
WITH clasificacion AS (
    SELECT 
        DATE(fecha_hora) AS dia,
        CASE 
            WHEN MAX(valor) >= 32 THEN 'ALERTA CALOR'
            WHEN MAX(valor) >= 30 THEN 'atencion'
            ELSE 'normal'
        END AS estado
    FROM lecturas
    WHERE sensor_id = 1 
      AND fecha_hora >= '2026-04-01' AND fecha_hora < '2026-05-01'
      AND valor > 0
    GROUP BY dia
)
SELECT 
    estado,
    COUNT(*) AS cantidad_dias
FROM clasificacion
GROUP BY estado
ORDER BY cantidad_dias;


-- D4. Cruce de riego con lecturas de sensores del mismo día y lote (5 tablas)
-- Esperado: 1 fila (Labor 14, 2026-04-14, Finca El Guayabo, Lote L-01, 8 lecturas)
SELECT 
    lb.labor_id,
    f.nombre AS finca,
    l.codigo AS lote,
    lb.tipo_labor,
    lb.fecha,
    COUNT(lec.lectura_id) AS n_lecturas_dia
FROM labores lb
JOIN siembras s ON lb.siembra_id = s.siembra_id
JOIN lotes l ON s.lote_id = l.lote_id
JOIN fincas f ON l.finca_id = f.finca_id
JOIN sensores sen ON l.lote_id = sen.lote_id
JOIN lecturas lec ON sen.sensor_id = lec.sensor_id AND DATE(lec.fecha_hora) = lb.fecha
WHERE lb.tipo_labor = 'riego'
GROUP BY lb.labor_id, f.nombre, l.codigo, lb.tipo_labor, lb.fecha;

/*
EXPLICACIÓN D4:
- Pregunta de negocio: "¿Cuál fue el impacto de una labor de riego sobre las variables microclimáticas 
  (humedad del suelo / radiación / temperatura) antes, durante y después de su ejecución?"
- Qué le falta al modelo: Falta registrar la hora exacta de ejecución de las labores en la tabla 'labores' 
  (actualmente solo tiene DATE sin TIME) y disponer de sensores de humedad de suelo específicos en todos los lotes irrigados.
*/


-- PARTE E · CIERRE

/*
1. ¿Cuál es el problema más difícil de detectar una vez entregado el reporte?
El error de filtrado por 'BETWEEN'. No genera excepciones, no produce valores negativos o aberrantes 
y entrega un promedio matemáticamente coherente pero incompleto al omitir de forma silenciosa el último día 
del mes, haciendo casi imposible su detección salvo mediante auditoría cruzada de conteos contra el calendario anual.

2. Restricciones a agregar:
- CHECK (valor BETWEEN -10 AND 60) -- (o rangos adaptados a cada variable física)
- UNIQUE (sensor_id, fecha_hora)
¿Qué pasa con las filas malas ya cargadas?:
SQLite no valida restricciones de tablas existentes sobre filas antiguas de forma automática al alterar tablas simples. 
Sin embargo, si se intenta recrear la tabla o ejecutar un 'PRAGMA integrity_check', el motor marcará errores de violación 
y no permitirá insertar nuevas filas ni actualizar las existentes sin antes depurar la base.

3. ¿Qué dejará de funcionar a escala de medio millón de lecturas?:
Las consultas de agregación y los escaneos secuenciales ('Full Table Scans') sobre 'fecha_hora' y 'sensor_id' 
se volverán críticamente lentos sin índices B-Tree específicos, degradando la respuesta del dashboard en tiempo real.
*/


-- EXTRA (+5 PUNTOS): Detección de un quinto problema de calidad no pedido
-- Detección de lecturas registradas en sensores dados de baja (activo = 0)
-- posteriores a su fecha formal de instalación/desactivación.

SELECT 
    s.sensor_id,
    s.tipo,
    s.modelo,
    s.fecha_instalacion,
    s.activo,
    COUNT(lec.lectura_id) AS total_lecturas_inactivas,
    MIN(lec.fecha_hora) AS primera_lectura,
    MAX(lec.fecha_hora) AS ultima_lectura
FROM sensores s
JOIN lecturas lec ON s.sensor_id = lec.sensor_id
WHERE s.activo = 0
GROUP BY s.sensor_id;

/*
EXPLICACIÓN EXTRA:
Esta consulta detecta una inconsistencia de integridad operativa: existen 40 lecturas registradas 
para el sensor_id = 3, el cual está marcado en el catálogo como 'activo = 0'. En sistemas IoT en producción, 
la base o el servicio de ingestión debe rechazar paquetes telemétricos provenientes de hardware desactivado.
*/