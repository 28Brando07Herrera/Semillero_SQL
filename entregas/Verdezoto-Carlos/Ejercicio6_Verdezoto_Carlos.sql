-- =====================================================================
-- CURSO DE SQL | AgroDB | Ejercicio práctico 6
-- Alumno: Apellido Nombre
-- Fecha: 2026-08-17
--
-- Este archivo se ejecuta DESPUES de datos/agrodb_clase6.sql,
-- en la MISMA sesion de SQLite.
-- =====================================================================

PRAGMA foreign_keys = ON;

-- =====================================================================
-- PARTE A - CONOCER LA TABLA NUEVA
-- =====================================================================

-- A1. ¿Por qué fecha_hora es TEXT y qué consecuencia tiene?
-- SQLite no tiene un tipo DATETIME nativo; las fechas/horas pueden almacenarse
-- como TEXT, REAL o INTEGER. En este modelo fecha_hora se guarda como TEXT.
-- Al usar el formato ISO 'AAAA-MM-DD HH:MM:SS', el orden lexicografico
-- coincide con el orden cronologico. Aun asi, para calcular partes de la fecha,
-- diferencias de tiempo o desplazar fechas debemos usar DATE(), strftime(),
-- julianday() y datetime(). Ademas, los limites de un rango TEXT deben escribirse
-- correctamente, porque '2026-04-30' es menor que '2026-04-30 03:00:00'.

SELECT * FROM lecturas LIMIT 10;

-- A2. Cantidad de lecturas de cada sensor, con primera y ultima medicion.
SELECT s.sensor_id,
       s.tipo,
       COUNT(l.lectura_id) AS n,
       MIN(l.fecha_hora) AS primera_medicion,
       MAX(l.fecha_hora) AS ultima_medicion
FROM sensores s
LEFT JOIN lecturas l ON l.sensor_id = s.sensor_id
GROUP BY s.sensor_id, s.tipo
ORDER BY s.sensor_id;

-- A2. Comentario: el sensor 3 tiene lecturas de febrero porque fue dado de baja
-- despues de medir durante algunos dias. No tiene ninguna lectura de abril.
-- El sensor 5 no tiene lecturas.

-- A3. Sensores sin ninguna lectura, mostrando lote y finca.
SELECT s.sensor_id,
       s.tipo,
       l.codigo AS lote,
       f.nombre AS finca
FROM sensores s
JOIN lotes l ON l.lote_id = s.lote_id
JOIN fincas f ON f.finca_id = l.finca_id
LEFT JOIN lecturas le ON le.sensor_id = s.sensor_id
WHERE le.lectura_id IS NULL
ORDER BY s.sensor_id;

-- A4. Diferencias:
-- * activo = 0: el sensor esta dado de baja y no deberia considerarse activo.
-- * sin lecturas: nunca existe una fila de lecturas para ese sensor.
-- * lecturas pero ninguna reciente: existen lecturas, pero estan fuera del
--   periodo que estamos auditando. En esta base, el sensor 3 esta inactivo y
--   tiene lecturas antiguas de febrero; el sensor 5 esta inactivo y no tiene
--   ninguna lectura. Por eso un sensor inactivo, uno sin lecturas y uno con
--   lecturas antiguas no significan lo mismo.

-- =====================================================================
-- PARTE B - FUNCIONES DE FECHA
-- =====================================================================

-- B1. Promedio diario del sensor 1, con COUNT(*) al lado.
SELECT DATE(fecha_hora) AS dia,
       ROUND(AVG(valor), 2) AS promedio,
       COUNT(*) AS n
FROM lecturas
WHERE sensor_id = 1
  AND fecha_hora >= '2026-04-01'
  AND fecha_hora <  '2026-05-01'
GROUP BY DATE(fecha_hora)
ORDER BY dia;

-- B2. Promedio del sensor 1 agrupado por hora del dia.
SELECT strftime('%H', fecha_hora) AS hora,
       ROUND(AVG(valor), 2) AS promedio,
       COUNT(*) AS n
FROM lecturas
WHERE sensor_id = 1
  AND fecha_hora >= '2026-04-01'
  AND fecha_hora <  '2026-05-01'
GROUP BY strftime('%H', fecha_hora)
ORDER BY hora;

-- B3. Lecturas por mes de toda la tabla.
SELECT strftime('%Y-%m', fecha_hora) AS mes,
       COUNT(*) AS n
FROM lecturas
GROUP BY strftime('%Y-%m', fecha_hora)
ORDER BY mes;

-- B4. Trampa del BETWEEN.
SELECT COUNT(*) AS cantidad_between
FROM lecturas
WHERE fecha_hora BETWEEN '2026-04-01' AND '2026-04-30';

SELECT COUNT(*) AS cantidad_rango_correcto
FROM lecturas
WHERE fecha_hora >= '2026-04-01'
  AND fecha_hora <  '2026-05-01';

SELECT COUNT(*) AS lecturas_30_abril
FROM lecturas
WHERE DATE(fecha_hora) = '2026-04-30';

-- B4. Comentario: BETWEEN es inclusivo en ambos extremos, pero compara los
-- valores TEXT. El limite superior '2026-04-30' no contiene hora y es menor
-- lexicograficamente que '2026-04-30 03:00:00', '...06:00:00', etc. Por eso
-- ninguna lectura del 30 de abril con hora queda dentro del BETWEEN. El rango
-- correcto para todo abril es >= '2026-04-01' y < '2026-05-01'.

-- =====================================================================
-- PARTE C - AUDITAR LA SERIE
-- =====================================================================

-- C1. Minimo, maximo y promedio del sensor 1 en abril.
SELECT MIN(valor) AS minimo,
       MAX(valor) AS maximo,
       ROUND(AVG(valor), 2) AS promedio,
       COUNT(*) AS n
FROM lecturas
WHERE sensor_id = 1
  AND fecha_hora >= '2026-04-01'
  AND fecha_hora <  '2026-05-01';

-- C1. Promedio excluyendo la lectura averiada (-99).
SELECT ROUND(AVG(valor), 2) AS promedio_sin_averiadas,
       COUNT(*) AS n
FROM lecturas
WHERE sensor_id = 1
  AND fecha_hora >= '2026-04-01'
  AND fecha_hora <  '2026-05-01'
  AND valor <> -99;

-- C1. Comentario: una diferencia de aproximadamente 1.5 grados es mas peligrosa
-- que una diferencia enorme porque puede parecer un dato razonable y pasar
-- inadvertida. Un valor extremadamente absurdo suele llamar la atencion; un
-- promedio ligeramente desplazado puede producir decisiones equivocadas sin
-- levantar una alerta.

-- C2. Días que contienen lecturas averiadas y su promedio crudo del dia.
SELECT DATE(fecha_hora) AS dia,
       COUNT(*) AS n,
       SUM(CASE WHEN valor = -99 THEN 1 ELSE 0 END) AS lecturas_averiadas,
       ROUND(AVG(valor), 2) AS promedio_crudo
FROM lecturas
WHERE sensor_id = 1
  AND fecha_hora >= '2026-04-01'
  AND fecha_hora <  '2026-05-01'
GROUP BY DATE(fecha_hora)
HAVING SUM(CASE WHEN valor = -99 THEN 1 ELSE 0 END) > 0
ORDER BY dia;

-- C3. Camino que NO funciona: un dia ausente no forma un grupo.
SELECT DATE(fecha_hora) AS dia,
       COUNT(*) AS n
FROM lecturas
WHERE sensor_id = 2
GROUP BY dia
HAVING n <> 8;

-- C3. Camino correcto: generar el calendario y buscar los dias sin filas.
WITH RECURSIVE dias(d) AS (
    SELECT '2026-04-01'
    UNION ALL
    SELECT DATE(d, '+1 day') FROM dias WHERE d < '2026-04-30'
)
SELECT d AS dia
FROM dias
WHERE d NOT IN (
    SELECT DATE(fecha_hora)
    FROM lecturas
    WHERE sensor_id = 2
)
ORDER BY d;

-- C3. Comentario: GROUP BY solo puede agrupar filas que existen. Un dia en el
-- que el sensor no registro ninguna lectura no genera un grupo con COUNT = 0;
-- simplemente no aparece. Por eso primero se necesita un calendario completo
-- y luego comparar sus fechas contra las fechas realmente registradas.

-- C4. Detectar huecos comparando cada lectura con la anterior.
SELECT sensor_id,
       anterior,
       fecha_hora,
       ROUND((julianday(fecha_hora) - julianday(anterior)) * 24, 1) AS horas_sin_medir
FROM (
    SELECT sensor_id,
           fecha_hora,
           LAG(fecha_hora) OVER (
               PARTITION BY sensor_id
               ORDER BY fecha_hora
           ) AS anterior
    FROM lecturas
)
WHERE anterior IS NOT NULL
  AND (julianday(fecha_hora) - julianday(anterior)) * 24 > 3;

-- C4. Comentario: son 75 horas y no 72 porque la ultima lectura buena es el
-- 10 de abril a las 21:00 y la primera posterior al hueco es el 14 de abril
-- a las 00:00. La diferencia entre esos dos instantes es exactamente 75 horas.

-- C5. Detectar mediciones duplicadas.
SELECT sensor_id,
       fecha_hora,
       COUNT(*) AS n
FROM lecturas
GROUP BY sensor_id, fecha_hora
HAVING COUNT(*) > 1;

-- C5. Restriccion que habria impedido el duplicado:
-- UNIQUE (sensor_id, fecha_hora)
-- Ejemplo:
-- CREATE UNIQUE INDEX uq_lecturas_sensor_fecha
-- ON lecturas(sensor_id, fecha_hora);

-- =====================================================================
-- PARTE D - REPORTE QUE SI SE PUEDE ENTREGAR
-- =====================================================================

-- D1. Promedio de abril por finca, lote y tipo de sensor, excluyendo averiadas.
SELECT f.nombre AS finca,
       l.codigo AS lote,
       s.tipo,
       COUNT(*) AS n,
       ROUND(AVG(le.valor), 2) AS promedio
FROM lecturas le
JOIN sensores s ON s.sensor_id = le.sensor_id
JOIN lotes l ON l.lote_id = s.lote_id
JOIN fincas f ON f.finca_id = l.finca_id
WHERE le.fecha_hora >= '2026-04-01'
  AND le.fecha_hora <  '2026-05-01'
  AND le.valor <> -99
GROUP BY f.nombre, l.codigo, s.tipo
ORDER BY f.nombre, l.codigo, s.tipo;

-- D2. Clasificar cada dia del sensor 1 segun su temperatura maxima y mostrar
-- solamente los dias que no son normales.
WITH diario AS (
    SELECT DATE(fecha_hora) AS dia,
           MAX(valor) AS max_temp
    FROM lecturas
    WHERE sensor_id = 1
      AND fecha_hora >= '2026-04-01'
      AND fecha_hora <  '2026-05-01'
    GROUP BY DATE(fecha_hora)
), clasificado AS (
    SELECT dia,
           max_temp,
           CASE
               WHEN max_temp >= 32 THEN 'ALERTA CALOR'
               WHEN max_temp >= 30 THEN 'atencion'
               ELSE 'normal'
           END AS estado
    FROM diario
)
SELECT dia, max_temp, estado
FROM clasificado
WHERE estado <> 'normal'
ORDER BY dia;

-- D3. Resumen de estados de todos los dias del sensor 1.
WITH diario AS (
    SELECT DATE(fecha_hora) AS dia,
           MAX(valor) AS max_temp
    FROM lecturas
    WHERE sensor_id = 1
      AND fecha_hora >= '2026-04-01'
      AND fecha_hora <  '2026-05-01'
    GROUP BY DATE(fecha_hora)
), clasificado AS (
    SELECT CASE
               WHEN max_temp >= 32 THEN 'ALERTA CALOR'
               WHEN max_temp >= 30 THEN 'atencion'
               ELSE 'normal'
           END AS estado
    FROM diario
)
SELECT estado,
       COUNT(*) AS n
FROM clasificado
GROUP BY estado
ORDER BY CASE estado
             WHEN 'ALERTA CALOR' THEN 1
             WHEN 'atencion' THEN 2
             ELSE 3
         END;

-- D4. Labores de riego que tienen lecturas de sensores del mismo dia y lote.
-- Se incluyen finca y lote porque la regla de formato exige que todo reporte
-- que mencione un lote indique tambien la finca.
SELECT lb.labor_id,
       lb.fecha,
       f.nombre AS finca,
       lo.codigo AS lote,
       COUNT(le.lectura_id) AS n
FROM labores lb
JOIN siembras si ON si.siembra_id = lb.siembra_id
JOIN lotes lo ON lo.lote_id = si.lote_id
JOIN fincas f ON f.finca_id = lo.finca_id
JOIN sensores se ON se.lote_id = lo.lote_id
JOIN lecturas le
  ON le.sensor_id = se.sensor_id
 AND DATE(le.fecha_hora) = lb.fecha
WHERE lb.tipo_labor = 'riego'
GROUP BY lb.labor_id, lb.fecha, f.nombre, lo.codigo
ORDER BY lb.labor_id;

-- D4. Pregunta de negocio: ¿qué labores de riego se realizaron en un lote
-- cuando los sensores estaban registrando datos ese mismo día, y cuántas
-- lecturas respaldan esa actividad? Para responderla completamente faltaría
-- relacionar explícitamente una labor con el sensor o con las condiciones
-- ambientales observadas y, si se busca evaluar el resultado del riego,
-- registrar métricas posteriores como consumo de agua y efecto sobre humedad.

-- =====================================================================
-- PARTE E - CIERRE
-- =====================================================================

-- E1. El hueco es el problema mas dificil de detectar una vez entregado el
-- reporte porque no deja una fila anomala: simplemente faltan datos. Un AVG
-- puede seguir produciendo un numero aparentemente normal y el informe no
-- muestra por si solo que existieron tres dias sin mediciones. Por eso COUNT
-- y la auditoria de continuidad son indispensables.

-- E2. Restricciones propuestas:
-- 1) CHECK (valor >= -40)
-- 2) UNIQUE (sensor_id, fecha_hora)
-- La primera impide aceptar el codigo de falla -99 bajo un rango minimo de
-- temperatura razonable; en un modelo mas completo convendria manejar limites
-- especificos segun el tipo de sensor. La segunda impide duplicar una medicion
-- del mismo sensor en el mismo instante.
-- Si se agregan hoy, no limpian las filas malas que ya existen. Las restricciones
-- afectan a nuevas inserciones/actualizaciones; primero habria que detectar y
-- corregir o eliminar los datos invalidos y duplicados existentes.

-- E3. A esta escala, una cosa que puede dejar de funcionar bien es el costo y
-- tiempo de consultas sobre lecturas historicas si no existen indices adecuados.
-- Con cientos de miles de filas, buscar por sensor y fecha repetidamente puede
-- requerir leer demasiadas filas. Un indice como (sensor_id, fecha_hora) seria
-- una mejora natural para esas consultas.

-- EXTRA (+5). Quinta comprobacion de calidad: detectar valores NULL o fuera de
-- un rango basico de almacenamiento. NOT NULL ya evita NULL en valor, pero una
-- consulta de auditoria puede detectar valores negativos extremos que no sean
-- coherentes con el dominio esperado.
SELECT sensor_id,
       MIN(valor) AS minimo,
       MAX(valor) AS maximo,
       COUNT(*) AS n
FROM lecturas
GROUP BY sensor_id
HAVING MIN(valor) < -40;
