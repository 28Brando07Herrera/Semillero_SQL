-- =====================================================================
-- CURSO DE SQL  |  AgroDB  |  Ejercicio 7
-- Alumno: Byron Yaguar
-- Fecha: 2026-08-18
--
-- Este archivo se ejecuta DESPUES de datos/agrodb_clase7.sql,
-- en la MISMA sesion de sqliteonline.
-- =====================================================================
PRAGMA foreign_keys = ON;

-- =====================================================================
-- PARTE A - LO QUE GROUP BY NO PODIA
-- =====================================================================

-- A1. Cada labor con su costo y el costo total de su siembra
SELECT l.labor_id,
       l.siembra_id,
       l.tipo_labor,
       l.costo_mano_obra,
       SUM(l.costo_mano_obra) OVER (PARTITION BY l.siembra_id) AS costo_total_siembra
FROM labores l
ORDER BY l.siembra_id, l.labor_id;

-- A1 VERIFICACION: siembra 5 debe mostrar 415 en ambas filas
-- Labor 8: 320, Labor 9: 95. Ambas ven 415.

-- A2. Agregando el porcentaje
SELECT l.labor_id,
       l.siembra_id,
       l.tipo_labor,
       l.costo_mano_obra,
       SUM(l.costo_mano_obra) OVER (PARTITION BY l.siembra_id) AS costo_total_siembra,
       ROUND(100.0 * l.costo_mano_obra / SUM(l.costo_mano_obra) OVER (PARTITION BY l.siembra_id), 1) AS porcentaje
FROM labores l
ORDER BY l.siembra_id, l.labor_id;

-- A2 VERIFICACION: siembra 5 da 77.1 y 22.9, suman 100

-- A3. Por qué no se puede hacer con GROUP BY:
-- Con GROUP BY siembra_id, colapsamos todas las filas de una siembra en una fila.
-- Se pierde toda la información de labores individuales (labor_id, tipo_labor, costo de cada una).
-- El SELECT tendría que especificar una función de agregación para cada columna: ¿MIN(costo_mano_obra)?
-- ¿MAX? ¿SUM? Perderías el detalle. Con OVER conservas cada fila individual mientras ves el total.
-- Es detalle + resumen simultáneamente, algo que GROUP BY no permite.

-- =====================================================================
-- PARTE B - RANKINGS
-- =====================================================================

-- B1. Ranking de lotes por rendimiento (kg/ha) dentro de cada finca
SELECT f.nombre AS finca,
       l.codigo AS lote,
       ROUND(1.0 * COALESCE(SUM(c.kg), 0) / l.hectareas, 2) AS kg_ha,
       RANK() OVER (PARTITION BY f.nombre ORDER BY 1.0 * COALESCE(SUM(c.kg), 0) / l.hectareas DESC) AS puesto
FROM lotes l
JOIN fincas f ON l.finca_id = f.finca_id
LEFT JOIN siembras si ON l.lote_id = si.lote_id
LEFT JOIN cosechas c ON si.siembra_id = c.siembra_id
GROUP BY l.lote_id, f.nombre, l.codigo, l.hectareas
ORDER BY f.nombre, puesto;

-- B1 NOTA CRITICA: El * 1.0 es obligatorio para evitar división entera.
-- Sin él, 256 kg / 1 ha = 256 en lugar de 256.14

-- B2. Promedio diario del sensor 1, con las tres funciones de numeración
SELECT DATE(l.fecha_hora) AS dia,
       ROUND(AVG(l.valor), 2) AS prom,
       ROW_NUMBER() OVER (ORDER BY ROUND(AVG(l.valor), 2) DESC) AS row_number,
       RANK() OVER (ORDER BY ROUND(AVG(l.valor), 2) DESC) AS rank,
       DENSE_RANK() OVER (ORDER BY ROUND(AVG(l.valor), 2) DESC) AS dense_rank
FROM lecturas l
WHERE l.sensor_id = 1
GROUP BY DATE(l.fecha_hora)
ORDER BY prom DESC;

-- B2 RESPUESTAS:
-- 1) RANK salta de 2 a 7 porque hay 5 empates en 25.63 (posiciones 2,3,4,5,6).
--    RANK da a todos el número 2, luego salta a 7 (2 + 5 empates = 7).
--    DENSE_RANK no salta: da 2 a los empates y 3 al siguiente, contando grupos no posiciones.
--
-- 2) DENSE_RANK te dice de un vistazo: hay 7 promedios distintos (porque dense_rank máximo es 7).
--    ROW_NUMBER siempre da 1..30, no te dice nada.
--
-- 3) ROW_NUMBER le pone números distintos a filas empatadas porque necesita un desempate.
--    Sin él, '2026-04-05' sería 2 y '2026-04-10' también sería 2.
--    ROW_NUMBER usa el orden en que aparecen en la consulta. Mañana podrían aparecer en otro orden
--    (diferentes indexes, diferentes planes de ejecución) y los números cambiarían.

-- B3. Ranking agregando COUNT(*) de cada día
SELECT DATE(l.fecha_hora) AS dia,
       ROUND(AVG(l.valor), 2) AS prom,
       COUNT(*) AS n_lecturas,
       RANK() OVER (ORDER BY ROUND(AVG(l.valor), 2) DESC) AS puesto
FROM lecturas l
WHERE l.sensor_id = 1
GROUP BY DATE(l.fecha_hora)
ORDER BY puesto, dia;

-- B3 ANÁLISIS DEL PRIMER PUESTO:
-- 1) 20 de abril tiene 7 lecturas. 19 de abril tiene 6 lecturas.
--    (Todos los demás tienen 8 porque es 1 lectura cada 3 horas × 8 = 240 lecturas en 30 días = 8 por día)
--
-- 2) Tienen menos porque AYER borramos las 3 lecturas averiadas del sensor 1:
--    21:00 del 19, 00:00 del 20, 03:00 del 20. Estaban marcadas como -99.
--
-- 3) La lectura de las 21:00 del 19 era muy baja (probablemente alrededor de 18-20°C).
--    Cuando la borramos, el promedio del 19 subió.
--    Las del 20 a las 00:00 y 03:00 eran aún más bajas (madrugada).
--    Cuando las borramos, el promedio del 20 subió mucho: 27.33 es anormalmente alto.
--
-- 4) NO, el 20 de abril NO fue el día más caluroso de abril.
--    Sale en el podio por culpa de la limpieza. Cuando eliminamos las lecturas frías de madrugada,
--    la media sube artificialmente. El 20 es el primero porque tiene MENOS datos, no porque sea más caliente.
--    Es un sesgo de supervivencia (survival bias): solo quedaron las horas cálidas del día.

-- B4. Ranking solo con días que tienen las 8 lecturas
WITH dias_completos AS (
  SELECT DATE(l.fecha_hora) AS dia,
         ROUND(AVG(l.valor), 2) AS prom,
         COUNT(*) AS n_lecturas
  FROM lecturas l
  WHERE l.sensor_id = 1
  GROUP BY DATE(l.fecha_hora)
  HAVING COUNT(*) = 8
)
SELECT dia,
       prom,
       RANK() OVER (ORDER BY prom DESC) AS puesto,
       n_lecturas
FROM dias_completos
ORDER BY puesto, dia;

-- B4 COMENTARIO:
-- Esta es OTRA respuesta, no la respuesta correcta. Descartamos datos de verdad.
-- Lo que perdimos: la realidad de que esos dos días tienen menos lecturas.
-- Si alguien pregunta "¿cuál fue el día más caluroso?", decir "fue el 20" (27.33) es incorrecto.
-- Decir "si solo mirás días completos, cinco empataron en 25.63" es más honesto pero no es lo mismo.
-- La respuesta correcta es reconocer: "el primero se parece más al segundo porque borramos datos,
-- así que el ranking está distorsionado". Ese es el aprendizaje del día.

-- B5. El mejor lote de cada finca
-- Primero, la versión que NO funciona (comentada):
-- SELECT f.nombre, l.codigo, ROUND(1.0 * SUM(c.kg) / l.hectareas, 2) AS kg_ha
-- FROM lotes l JOIN fincas f ON l.finca_id = f.finca_id
-- LEFT JOIN siembras s ON l.lote_id = s.lote_id
-- LEFT JOIN cosechas c ON s.siembra_id = c.siembra_id
-- GROUP BY l.lote_id
-- WHERE puesto = 1;  -- ERROR!

-- Error: "no such column: puesto" — puesto es una función de ventana, no existe sin OVER.
-- El WHERE se ejecuta ANTES de las ventanas. No puede filtrar por algo que no existe todavía.

-- La versión que sí funciona: CTE + filtro afuera
WITH ranking_lotes AS (
  SELECT f.nombre AS finca,
         l.codigo AS lote,
         ROUND(1.0 * COALESCE(SUM(c.kg), 0) / l.hectareas, 2) AS kg_ha,
         RANK() OVER (PARTITION BY f.nombre ORDER BY 1.0 * COALESCE(SUM(c.kg), 0) / l.hectareas DESC) AS puesto
  FROM lotes l
  JOIN fincas f ON l.finca_id = f.finca_id
  LEFT JOIN siembras si ON l.lote_id = si.lote_id
  LEFT JOIN cosechas c ON si.siembra_id = c.siembra_id
  GROUP BY l.lote_id, f.nombre, l.codigo, l.hectareas
)
SELECT finca, lote, kg_ha, puesto
FROM ranking_lotes
WHERE puesto = 1
ORDER BY finca;

-- B5 ESPERADO: 3 filas - A-1 (38.18), L-02 (529.73), L-01 (256.14)

-- =====================================================================
-- PARTE C - MIRAR LA FILA DE AL LADO
-- =====================================================================

-- C1. Cada cosecha con la anterior de la misma siembra
SELECT c.cosecha_id,
       c.siembra_id,
       c.fecha,
       c.kg,
       LAG(c.kg) OVER (PARTITION BY c.siembra_id ORDER BY c.fecha) AS kg_anterior,
       c.kg - LAG(c.kg) OVER (PARTITION BY c.siembra_id ORDER BY c.fecha) AS delta
FROM cosechas c
ORDER BY c.siembra_id, c.fecha;

-- C1 COMENTARIO:
-- Los 6 NULL (siembras 1, 4, 6: primera cosecha; siembras 3, 5, 8: única cosecha)
-- son NULL porque LAG de la primera fila no tiene "anterior". No es error; es correcto.
-- LAG(x) cuando no hay fila anterior devuelve NULL, que es lo que queremos.

-- C2. Cosechas que rindieron menos que la anterior
WITH cosechas_con_anterior AS (
  SELECT c.siembra_id,
         c.kg,
         LAG(c.kg) OVER (PARTITION BY c.siembra_id ORDER BY c.fecha) AS kg_anterior
  FROM cosechas c
)
SELECT siembra_id,
       kg_anterior AS de,
       kg AS a,
       kg - kg_anterior AS delta
FROM cosechas_con_anterior
WHERE kg < kg_anterior
ORDER BY siembra_id;

-- C2 COMENTARIO EN UNA LINEA:
-- Las tres siembras que tuvieron dos cosechas decayeron todas. ¿Por qué?
-- ¿Fue diferente manejo entre cosechas? ¿Cambió el estado de la planta?
-- ¿Es normal que la segunda cosecha sea menor o estamos dejando producto en el lote?

-- C3. Días entre cosechas consecutivas de la misma siembra
SELECT c.siembra_id,
       c.fecha,
       c.kg,
       LEAD(c.fecha) OVER (PARTITION BY c.siembra_id ORDER BY c.fecha) AS fecha_siguiente,
       CAST(LEAD(c.fecha) OVER (PARTITION BY c.siembra_id ORDER BY c.fecha) AS TEXT) AS fecha_siguiente_text,
       ROUND((julianday(LEAD(c.fecha) OVER (PARTITION BY c.siembra_id ORDER BY c.fecha))
              - julianday(c.fecha))) AS dias_hasta_siguiente
FROM cosechas c
ORDER BY c.siembra_id, c.fecha;

-- C3 ESPERADO: 9 filas, solo 3 con número (29, 21, 25)

-- C4. El hueco que hicimos nosotros al limpiar
WITH lecturas_con_anterior AS (
  SELECT l.sensor_id,
         l.fecha_hora,
         LAG(l.fecha_hora) OVER (PARTITION BY l.sensor_id ORDER BY l.fecha_hora) AS anterior
  FROM lecturas l
)
SELECT sensor_id,
       anterior AS desde,
       fecha_hora AS hasta,
       ROUND((julianday(fecha_hora) - julianday(anterior)) * 24, 1) AS horas
FROM lecturas_con_anterior
WHERE anterior IS NOT NULL
  AND (julianday(fecha_hora) - julianday(anterior)) * 24 > 3
ORDER BY sensor_id, fecha_hora;

-- C4 COMENTARIO:
-- 1) El hueco del sensor 1 (12 horas entre 19-04 18:00 y 20-04 06:00) es NUEVO.
--    En la clase 6 no existía. Salió porque borramos las 3 lecturas averiadas
--    (21:00 del 19, 00:00 del 20, 03:00 del 20). El sensor ESTABA midiendo,
--    pero nosotros los borramos con la mejor intención.
--
-- 2) ES UN HUECO DE LA BASE DE DATOS, no del sensor. El sensor funcionaba.
--    Nosotros creamos el hueco al limpiar. Es un efecto secundario no intencionado.
--
-- 3) Lo que habría que haber hecho: agregar una columna "es_valido" (TRUE/FALSE)
--    o "motivo_exclusion" (NULL si ok, 'sensor error', 'lectura duplicada', etc).
--    Borrar las filas es irreversible. En seis meses, cuando alguien audite,
--    no hay forma de saber qué pasó. Con una columna de flags, queda todo auditado.

-- =====================================================================
-- PARTE D - ACUMULADOS Y MEDIA MOVIL
-- =====================================================================

-- D1. Kilos cosechados por fecha, con acumulado del año
SELECT c.fecha,
       SUM(c.kg) AS kg_del_dia,
       SUM(SUM(c.kg)) OVER (ORDER BY c.fecha) AS acumulado
FROM cosechas c
GROUP BY c.fecha
ORDER BY c.fecha;

-- D1 ESPERADO: 8 filas, última = 30550

-- D2. Acumulado reiniciándose por finca
SELECT c.fecha,
       f.nombre AS finca,
       SUM(c.kg) AS kg_del_dia,
       SUM(SUM(c.kg)) OVER (PARTITION BY f.nombre ORDER BY c.fecha) AS acumulado_finca
FROM cosechas c
JOIN siembras s ON c.siembra_id = s.siembra_id
JOIN lotes l ON s.lote_id = l.lote_id
JOIN fincas f ON l.finca_id = f.finca_id
GROUP BY c.fecha, f.nombre
ORDER BY f.nombre, c.fecha;

-- D2 ESPERADO: 9 filas. Acumulados finales: 2100, 14250, 14200

-- D2 COMENTARIO:
-- Lo que cambió: de OVER (ORDER BY ...) a OVER (PARTITION BY f.nombre ORDER BY ...)
-- Eso alcanza. PARTITION BY reinicia la ventana en cada finca.
-- Sin PARTITION BY, la ventana es global (una sola "línea" de acumulación).
-- Con PARTITION BY, son tres ventanas independientes, una por finca.

-- D3. Media móvil de 7 días del promedio diario del sensor 1
WITH promedios_diarios AS (
  SELECT DATE(l.fecha_hora) AS d,
         ROUND(AVG(l.valor), 2) AS prom
  FROM lecturas l
  WHERE l.sensor_id = 1
  GROUP BY DATE(l.fecha_hora)
)
SELECT d AS dia,
       prom,
       ROUND(AVG(prom) OVER (ORDER BY d ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 2) AS media_movil
FROM promedios_diarios
ORDER BY d;

-- D3 ESPERADO: 30 filas. Del 18 al 21: 23.63→23.49, 24.86→23.81, 27.33→24.33, 21.63→23.91

-- D4. Media móvil con COUNT de la ventana
WITH promedios_diarios AS (
  SELECT DATE(l.fecha_hora) AS d,
         ROUND(AVG(l.valor), 2) AS prom
  FROM lecturas l
  WHERE l.sensor_id = 1
  GROUP BY DATE(l.fecha_hora)
)
SELECT d AS dia,
       prom,
       ROUND(AVG(prom) OVER (ORDER BY d ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 2) AS media_movil,
       COUNT(*) OVER (ORDER BY d ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS n_dias
FROM promedios_diarios
ORDER BY d;

-- D4 COMENTARIO:
-- Los primeros 6 días tienen n_dias = 1, 2, 3, 4, 5, 6 (no 7).
-- El 1 de abril, la media móvil se calculó sobre 1 solo día (23.25), no 7.
-- Un tablero que muestra 23.25 sin aclarar que es "media de 1 día" está afirmando que es
-- "media de 7 días", lo cual es mentira. El COUNT(*) al lado lo deja en evidencia.

-- D5. Análisis del 20 de abril
-- El 20: promedio crudo 27.33, media móvil 24.33. La media móvil TAPO EL PROBLEMA.
-- El 20 tiene solo 7 lecturas (no 8) porque borramos las de madrugada que eran más frías.
-- La media móvil "suaviza" el 27.33 a 24.33, pero no porque haya ruido que sacar,
-- sino porque los días de alrededor son normales (~25). El 27.33 es anómalo.
-- La media móvil hizo parecer plausible un número que es sospechoso. Fue contraproducente.

-- =====================================================================
-- PARTE E - CIERRE
-- =====================================================================

-- 1) GROUP BY vs OVER (PARTITION BY ...):
-- GROUP BY colapsa filas y pierde detalle; OVER conserva cada fila y agrega una columna.

-- 2) Si dos lotes empataran en kg/ha, ROW_NUMBER elegiría uno arbitrariamente
--    (el primero que aparezca en la consulta). Si necesito determinismo (mismo resultado siempre),
--    debo agregar un segundo ORDER BY: ORDER BY kg/ha DESC, lote_id.

-- 3) Regla para la próxima limpieza:
--    Nunca borres. En su lugar, marca filas como inválidas con una columna flags o estado.
--    Cuando borras, creates agujeros invisibles en series de tiempo.
--    El que lee el reporte no sabe que datos desaparecieron, así que confía en lo que ve.
--    Si una lectura averiada se ve como "muy alta" o "muy baja", obvia. Si desaparece, es invisible.
--    Auditabilidad: siempre guarda la pista de qué borraste y por qué.