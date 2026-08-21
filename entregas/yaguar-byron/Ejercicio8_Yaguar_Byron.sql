-- =====================================================================
-- CURSO DE SQL  |  AgroDB  |  Ejercicio 9 - Cien mil filas y un plan
-- Alumno: Byron Yaguar
-- Fecha: 2026-08-21
--
-- Este archivo se ejecuta DESPUES de datos/agrodb_clase9.sql,
-- en la MISMA sesion de sqliteonline.
--
-- La regla del dia: EL RELOJ ES UNA ANÉCDOTA, EL PLAN ES LA EVIDENCIA.
-- Toda afirmación sobre performance va acompañada de un EXPLAIN QUERY PLAN.
-- =====================================================================
PRAGMA foreign_keys = ON;

-- =====================================================================
-- PARTE A - MIRAR ANTES DE TOCAR
-- =====================================================================

-- A1. Contá lo que hay. Esperado: 105.120 filas, 6 sensores, 17.520 por sensor.
SELECT COUNT(*) FROM lecturas_historico;
-- RESULTADO: 105120 ✓

SELECT sensor_id, COUNT(*) FROM lecturas_historico GROUP BY sensor_id;
-- RESULTADO: 6 sensores, cada uno con 17520 filas ✓

-- A2 — los índices que ya existen.
SELECT name, tbl_name FROM sqlite_master WHERE type = 'index';
-- RESULTADO: 5 filas con sqlite_autoindex_*
--
-- RESPUESTAS:
-- 1. ¿De dónde salieron?
--    Los índices autoindex de SQLite se crean automáticamente cuando una tabla
--    tiene restricciones UNIQUE o PRIMARY KEY. No fueron creados manualmente
--    con CREATE INDEX.
--
-- 2. sqlite_autoindex_lecturas_1 es de la tabla lecturas. ¿Ustedes lo crearon?
--    Sí, en el ejercicio 6 con la línea: UNIQUE (sensor_id, fecha_hora)
--    Esta restricción obliga a SQLite a crear un índice automático para
--    validar la unicidad de forma eficiente.
--
-- 3. ¿Por qué un UNIQUE necesita un índice para funcionar?
--    Un UNIQUE necesita un índice para verificar rápidamente que no exista
--    otro registro con la misma combinación. Sin índice, sería O(n) en cada
--    INSERT (comparar contra todas las filas). Con índice es O(log n).
--    El índice es la estructura que permite esta búsqueda binaria.

-- A3. ¿Aparece lecturas_historico en esa lista? ¿Por qué no?
--
-- RESPUESTA: NO aparece. lecturas_historico NO tiene índices propios porque:
--   * El lectura_id es INTEGER PRIMARY KEY, que en SQLite es un alias para rowid.
--   * El rowid en SQLite es IMPLÍCITO y no crea un índice separado.
--   * No hay restricción UNIQUE en esta tabla.
--   * Cualquier consulta que filtre por sensor_id o fecha_hora debe SCAN
--     todas las 105.120 filas porque SQLite no sabe dónde están.
--     Eso es exactamente el problema del ejercicio de hoy.

-- =====================================================================
-- PARTE B - MEDIR, INDEXAR, VOLVER A MEDIR (30 min)
-- =====================================================================

-- B1 — la consulta lenta. Tablero que pide mediciones por día en junio:
-- ESPERADO: 30 filas, todas con 48.
WITH RECURSIVE dia(n) AS (SELECT 0 UNION ALL SELECT n+1 FROM dia WHERE n < 29)
SELECT n + 1 AS dia_de_junio,
  (SELECT COUNT(*) FROM lecturas_historico l
    WHERE l.sensor_id = 1
      AND l.fecha_hora >= datetime('2026-06-01','+'||n||' days')
      AND l.fecha_hora <  datetime('2026-06-01','+'||(n+1)||' days')) AS n_lecturas
FROM dia;
-- RESULTADO: 30 filas × 48 = correcto ✓
-- TIEMPO: 0.486 segundos (sin índices). Se sintió.

-- B2 — preguntarle a SQLite por qué. El plan de B1:
--
-- RESULTADO DEL PLAN:
-- |--CO-ROUTINE dia
-- |  |--SETUP
-- |  |  `--SCAN CONSTANT ROW
-- |  `--RECURSIVE STEP
-- |     `--SCAN dia
-- |--SCAN dia
-- `--CORRELATED SCALAR SUBQUERY 3
--    `--SCAN l
--
-- SIGNIFICADO DE SCAN:
-- SCAN significa "recorrer tabla completa". La última línea "SCAN l" dice que
-- SQLite examina TODAS las filas de lecturas_historico (l) para cada día,
-- incluso aunque solo le pidan las de sensor 1 en ese rango de fechas.
--
-- ¿CUÁNTAS FILAS LEE EN TOTAL?
-- 30 días × 105.120 filas = 3.153.600 lecturas procesadas.
-- (Aunque muchas se descartan por la condición WHERE, primero las lee todas.)

-- B3 — crear el índice. SIN cambiar nada en las consultas siguientes.
DROP INDEX IF EXISTS ix_hist_sensor_fecha;
CREATE INDEX ix_hist_sensor_fecha
    ON lecturas_historico (sensor_id, fecha_hora);

-- B4. Volver a correr B1 sin cambiarle una letra:
WITH RECURSIVE dia(n) AS (SELECT 0 UNION ALL SELECT n+1 FROM dia WHERE n < 29)
SELECT n + 1 AS dia_de_junio,
  (SELECT COUNT(*) FROM lecturas_historico l
    WHERE l.sensor_id = 1
      AND l.fecha_hora >= datetime('2026-06-01','+'||n||' days')
      AND l.fecha_hora <  datetime('2026-06-01','+'||(n+1)||' days')) AS n_lecturas
FROM dia;
-- RESULTADO: idéntico: 30 filas × 48 ✓
-- TIEMPO: 0.000 segundos (con índices). Instantáneo.

-- Plan de B4:
-- |--CO-ROUTINE dia
-- |  |--SETUP
-- |  |  `--SCAN CONSTANT ROW
-- |  `--RECURSIVE STEP
-- |     `--SCAN dia
-- |--SCAN dia
-- `--CORRELATED SCALAR SUBQUERY 3
--    `--SEARCH l USING COVERING INDEX ix_hist_sensor_fecha (sensor_id=? AND fecha_hora>? AND fecha_hora<?)
--
-- RESPUESTA: ¿CAMBIÓ ALGO?
-- El resultado (30 × 48) es EXACTAMENTE igual. No cambió ni una fila.
-- El índice no cambió QUE devolvemos, cambió CÓMO lo encontramos.
--
-- EXPLICACIÓN CON LA PALABRA "RESULTADO":
-- Un índice no afecta el resultado. Afecta cómo SQLite busca para producir ese resultado.
-- Antes: SCAN (leer 105.120 × 30 filas)
-- Después: SEARCH + COVERING INDEX (ir directo a las ~1.440 filas relevantes)
-- El resultado sigue siendo 30 días × 48 = 1.440 filas totales procesadas.

-- =====================================================================
-- PARTE C - LA COSTUMBRE DE TRES CLASES (35 min)
-- =====================================================================

-- C1. Escribí el promedio diario del sensor 1 en junio COMO VENÍS ESCRIBIENDO:
SELECT DATE(fecha_hora) AS dia, COUNT(*) AS n, ROUND(AVG(valor),2) AS prom
FROM lecturas_historico
WHERE sensor_id = 1
  AND DATE(fecha_hora) BETWEEN '2026-06-01' AND '2026-06-30'
GROUP BY dia;
-- RESULTADO: 30 filas, cada una con n = 48 y prom = 23.88 ✓

-- Plan de C1:
-- SEARCH lecturas_historico USING INDEX ix_hist_sensor_fecha (sensor_id=?)
-- USE TEMP B-TREE FOR GROUP BY
--
-- C2. Comparalo con el plan de B4:
-- B4 PLAN:   SEARCH ix_hist_sensor_fecha (sensor_id=? AND fecha_hora>? AND fecha_hora<?)
-- C1 PLAN:   SEARCH ix_hist_sensor_fecha (sensor_id=?)
--                     ^ Faltan los range checks ^
--
-- RESPUESTAS:
-- 1. ¿Qué parte del índice se usó y cuál no?
--    Se usó: la condición sensor_id = 1 (la columna izquierda del índice)
--    NO se usó: la condición DATE(fecha_hora) BETWEEN ... (no puede usar fecha_hora directamente)
--
-- 2. ¿Sobre cuántas filas del sensor 1 está trabajando?
--    El sensor 1 tiene 17.520 lecturas en total (todo el año).
--    Junio tiene solo 1.440 (30 días × 48).
--    SQLite filtra por sensor_id → 17.520 filas
--    Luego filtra en memoria por DATE() → queda con 1.440
--    Eso es 12× más trabajo del necesario.

-- C3 — por qué el índice no funciona con DATE(fecha_hora):
--
-- EXPLICACIÓN:
-- El índice está ordenado por fecha_hora TAL COMO SE GUARDÓ: como texto.
-- Por ejemplo: '2026-06-01 00:00:00', '2026-06-01 00:30:00', '2026-06-02 00:00:00', etc.
--
-- Cuando pedís DATE(fecha_hora), le estás pidiendo que:
--   1. Lee cada fila del índice
--   2. Extrae solo la parte de la fecha (aplicar función)
--   3. Recién ahí compara con '2026-06-01'
--
-- El índice NO PUEDE ir directo a '2026-06-01' porque lo que está guardado
-- es '2026-06-01 00:00:00', no '2026-06-01'.
--
-- Analogía: un índice de un libro alfabético por nombre. Si te pido
-- "todas las palabras cuya 3ª letra es 'a'" no puedo usar el índice
-- sin primero leer TODAS las palabras y transformarlas.

-- C4 — el arreglo. Reescribí preguntando por la columna TAL COMO ESTÁ GUARDADA:
SELECT DATE(fecha_hora) AS dia, COUNT(*) AS n, ROUND(AVG(valor),2) AS prom
FROM lecturas_historico
WHERE sensor_id = 1
  AND fecha_hora >= '2026-06-01'
  AND fecha_hora <  '2026-07-01'
GROUP BY dia;
-- RESULTADO: mismas 30 filas, mismos 48, mismos 23.88 ✓

-- Plan de C4:
-- SEARCH lecturas_historico USING INDEX ix_hist_sensor_fecha (sensor_id=? AND fecha_hora>? AND fecha_hora<?)
-- USE TEMP B-TREE FOR GROUP BY
--
-- Ahora SÍ usa las tres partes del índice, y SQLite encuentra directamente
-- las 1.440 filas de junio para el sensor 1.

-- C5. Fijate que usé < '2026-07-01' y no <= '2026-06-30'.
--
-- PREGUNTA: si escribo fecha_hora <= '2026-06-30', ¿qué lecturas del 30 pierdo?
--
-- RESPUESTA:
-- Pierdo TODAS las del 30 de junio después de las 00:00:00.
-- Porque '2026-06-30' como texto es SOLO '2026-06-30', y cualquier
-- timestamp '2026-06-30 00:30:00' es TEXTUALMENTE > '2026-06-30'.
-- El símbolo <= detiene en medianoche, no incluye el resto del día.
-- Por eso < '2026-07-01' es correcto: incluye TODO desde medianoche del 1°
-- hasta medianoche del día siguiente (que es el 1° de julio).

-- C6 — la honesta. Medición de tiempos:
-- C1 con DATE()/BETWEEN: 0.006 segundos (sensor 1: 17.520 filas procesadas)
-- C4 con rango correcto: 0.002 segundos (sensor 1: 1.440 filas procesadas)
--
-- RESPUESTAS - ¿por qué habría que arreglarlo si el reloj casi no lo muestra?
--
-- Tres razones:
--
-- 1. ESCALA. Hoy es junio, son 30 días. Con un año completo el margen crece.
--    Con 10 años de datos (casi el 100% del mercado agrícola), la diferencia
--    sería de 1.440 filas contra 175.200, un factor de 120×. Ya no es
--    "se sintió un poco lento", es "está roto".
--
-- 2. VISIBILIDAD DEL PLAN. El plan dice SEARCH (buen síntoma), pero la
--    realidad es que está haciendo el trabajo en dos etapas: índice +
--    filtro en memoria. Los planes mienten cuando omiten detalles.
--
-- 3. ACUMULACIÓN. Esta consulta corre automáticamente en un dashboard cada
--    15 minutos. 96 veces/día × 365 días = 35.040 ejecutions/año.
--    0.004 segundos de diferencia = 140 segundos/año de CPU por nada.

-- C7 — buscá en tus entregas anteriores una consulta con DATE() en WHERE:
--
-- Del Ejercicio 6 enunciado, B4:
-- SELECT COUNT(*) FROM lecturas
-- WHERE DATE(fecha_hora) = '2026-04-30';
--
-- Cómo lo escribo hoy:
SELECT COUNT(*) FROM lecturas
WHERE fecha_hora >= '2026-04-30' AND fecha_hora < '2026-05-01';
-- Resultado: mismo, pero sin función en WHERE.

-- =====================================================================
-- PARTE D - CUÁNDO EL ÍNDICE NO ALCANZA (25 min)
-- =====================================================================

-- D1 — el prefijo izquierdo.
EXPLAIN QUERY PLAN
SELECT COUNT(*) FROM lecturas_historico
WHERE fecha_hora >= '2026-06-01' AND fecha_hora < '2026-07-01';
-- PLAN: SCAN lecturas_historico USING COVERING INDEX ix_hist_sensor_fecha
--
-- RESPUESTAS:
--
-- 1. ¿POR QUÉ DICE "SCAN" si fecha_hora ESTÁ en el índice?
--    Porque el índice es (sensor_id, fecha_hora).
--    Cuando buscas solo por fecha_hora, estás buscando por la SEGUNDA
--    columna del índice, ignorando la PRIMERA.
--    SQLite no puede usar un índice que comienza con sensor_id para
--    una búsqueda que solo menciona fecha_hora. Es el problema del
--    "prefijo izquierdo": necesitas las columnas de izquierda a derecha.
--
-- 2. DICE "USING COVERING INDEX". ¿Para qué le sirve si igual recorre todo?
--    "COVERING" significa que todas las columnas que necesita (COUNT(*))
--    ya están en el índice, no necesita ir a la tabla principal.
--    Sigue siendo SCAN (lee todo), pero desde el índice, que es más
--    compacto y caché-friendly que la tabla.

-- D2. Crear el índice que SÍ sirve para esa consulta:
DROP INDEX IF EXISTS ix_hist_fecha;
CREATE INDEX ix_hist_fecha ON lecturas_historico (fecha_hora);

EXPLAIN QUERY PLAN
SELECT COUNT(*) FROM lecturas_historico
WHERE fecha_hora >= '2026-06-01' AND fecha_hora < '2026-07-01';
-- PLAN AHORA: SEARCH lecturas_historico USING COVERING INDEX ix_hist_fecha (fecha_hora>? AND fecha_hora<?)
--
-- RESPUESTA: ¿Está mal tener dos índices?
--
-- No está mal TODAVÍA. Hay 105.120 filas, un índice adicional cuesta:
--   * 100KB extra en disco (estimado)
--   * Milisegundos en cada INSERT
--
-- Está mal cuando:
--   * Más de 10-20% de los INSERTs llegan a esta tabla y cada índice
--     duplica el trabajo
--   * La tabla crece a ritmo muy rápido (ej: sensores a escala industrial,
--     1 millón de filas/día). Entonces el costo de mantener índices
--     contraproducentes explota.
--   * Hay dudas sobre cuál de los dos índices se usa realmente y cuál
--     es un fantasma. Hoy es claro, pero en una base con 200 índices no lo es.

-- D3 — el ORDER BY gratis. Tres planes en orden exacto.

-- PASO 1 — Con los dos índices creados:
EXPLAIN QUERY PLAN
SELECT fecha_hora, valor FROM lecturas_historico
WHERE sensor_id = 1 ORDER BY fecha_hora LIMIT 10;
-- PLAN: SEARCH lecturas_historico USING INDEX ix_hist_sensor_fecha (sensor_id=?)
--
-- NOTA: No aparece "USE TEMP B-TREE FOR ORDER BY" ni nada de SORT.
-- Observación pendiente para PASO 3.

-- PASO 2 — Sin ningún índice. Primero borrá los dos:
DROP INDEX IF EXISTS ix_hist_sensor_fecha;
DROP INDEX IF EXISTS ix_hist_fecha;

EXPLAIN QUERY PLAN
SELECT fecha_hora, valor FROM lecturas_historico
WHERE sensor_id = 1 ORDER BY fecha_hora LIMIT 10;
-- PLAN:
-- |--SCAN lecturas_historico
-- `--USE TEMP B-TREE FOR ORDER BY
--
-- Aparece una línea nueva: SQLite tuvo que crear una estructura temporal
-- (B-TREE) en memoria para ordenar los 17.520 resultados antes de devolver
-- los 10 primeros. Es costoso.

-- PASO 3 — Solo con el índice sobre fecha_hora:
CREATE INDEX ix_hist_fecha ON lecturas_historico (fecha_hora);

EXPLAIN QUERY PLAN
SELECT fecha_hora, valor FROM lecturas_historico
WHERE sensor_id = 1 ORDER BY fecha_hora LIMIT 10;
-- PLAN: SCAN lecturas_historico USING INDEX ix_hist_fecha
--
-- Dice SCAN (recorre la tabla), PERO la línea "USE TEMP B-TREE FOR ORDER BY"
-- DESAPARECIÓ. ¿Cómo puede ser?
--
-- RESPUESTA (dos líneas):
-- El índice ix_hist_fecha guarda las filas ORDENADAS por fecha_hora.
-- Cuando SQLite hace SCAN usando ese índice, lee las filas YA ORDENADAS,
-- así que no necesita crear tabla temporal. SCAN + index ordenado = gratis.

-- PASO 4. Volver a crear el índice compuesto antes de seguir:
DROP INDEX IF EXISTS ix_hist_fecha;
CREATE INDEX ix_hist_sensor_fecha ON lecturas_historico (sensor_id, fecha_hora);

-- D4 — un SEARCH que no sirve de mucho.
DROP INDEX IF EXISTS ix_hist_valor;
CREATE INDEX ix_hist_valor ON lecturas_historico (valor);

EXPLAIN QUERY PLAN
SELECT COUNT(*) FROM lecturas_historico WHERE valor > 28;
-- PLAN: SEARCH lecturas_historico USING COVERING INDEX ix_hist_valor (valor>?)

SELECT COUNT(*) FROM lecturas_historico WHERE valor > 28;
-- RESULTADO: 59.495 filas de 105.120 (56.6% de la tabla)
--
-- RESPUESTAS (la más fina del día):
--
-- 1. ¿ESTÁ ESTA CONSULTA BIEN RESUELTA?
--    NO. El plan dice SEARCH, que parecería correcto, pero es un SEARCH
--    que lee el 56% de la tabla. Técnicamente usa el índice, pero ineficiente.
--
-- 2. ¿CUÁNTAS ENTRADAS DEL ÍNDICE TUVO QUE RECORRER?
--    Todas las 59.495 entradas donde valor > 28.
--    Un SEARCH no es "acceso random eficiente"; puede ser
--    "lectura secuencial del 56% del índice", que es peor que
--    SCAN de toda la tabla sin ordenar.
--
-- 3. ¿ALCANZA CON MIRAR SI EL PLAN DICE "SEARCH"?
--    NO. Hay que mirar TAMBIÉN cuántas filas devuelve vs cuántas procesa.
--    Si la consulta devuelve >50% de la tabla, un índice sobre esa
--    columna probablemente no ayude. El SCAN sin índice sería más rápido.
--    La regla: si > 20% de la tabla, considera SCAN. Si > 50%, SCAN gana.

-- D5. Borrar el índice de valor:
DROP INDEX IF EXISTS ix_hist_valor;
--
-- ¿POR QUÉ?
-- Porque un índice sobre una columna que es muy selectiva (pocos valores únicos)
-- o que se consulta sin rango (ej: valor = 25) SÍ ayuda. Pero valor > 28
-- devuelve más de la mitad, donde SCAN gana. Mantenerlo cuesta (INSERT lento,
-- disco usado) sin beneficio. Se borra.

-- =====================================================================
-- PARTE E - LO QUE CUESTA, Y CIERRE (10 min)
-- =====================================================================

-- E1. Un índice se paga en tres monedas:
--
-- TRES MONEDAS (COSTOS):
--
-- 1. DISCO: Cada índice consume espacio. Con 105.120 filas,
--    cada índice consume ~1-2 MB (depende del tipo de dato).
--    Hoy no es problema. Con 100 millones de filas, empieza a serlo.
--
-- 2. ESCRITURA (INSERT/UPDATE/DELETE): Cada vez que entra una fila nueva,
--    SQLite debe mantener TODOS los índices. Sin índices: 1 operación.
--    Con 3 índices: ~4 operaciones. En tablas de sensores que reciben datos
--    cada 30 minutos: 48 INSERTs/día/sensor = 288 escrituras/sensor/día.
--    Con 6 sensores = 1.728 INSERTs/día. Si cada índice suma 50 microsegundos,
--    son 86 milisegundos de overhead diario. Acumulado en N años, es real.
--
-- ¿CUÁL ES LA MÁS CARA EN UNA TABLA DE SENSORES?
--
-- LA ESCRITURA. Una tabla de sensores recibe mediciones CONTINUAMENTE,
-- pero se CONSULTA poco (tal vez una vez/hora en un dashboard).
--
-- Relación: ~2.000 INSERTs/día pero solo 24 consultas.
-- La proporción de "cambio" contra "lectura" es 80-90 a 1.
-- Por eso los sensores agrícolas reales usan DW (data warehouse):
-- copian a una tabla "fría" (sin índices) después del ciclo de carga.

-- E2. Una vista NO acelera nada. Hoy indexaste la tabla que está abajo.
--
-- ¿QUIÉN HACE EL TRABAJO?
--
-- El índice. Una vista es solo un alias: al consultarla, SQLite aún
-- tiene que ejecutar su SELECT subyacente. El índice es lo que hace
-- que ese SELECT sea rápido. La vista es transparencia; el índice
-- es el motor.

-- E3. Las TRES PREGUNTAS que te vas a hacer cuando algo esté lento:
--
-- PREGUNTA 1: ¿EXISTE UN EXPLAIN QUERY PLAN?
--   Corre EXPLAIN QUERY PLAN de la consulta lenta.
--   ¿Dice SCAN? ¿Dice SEARCH?
--   ¿Cuántas filas está leyendo realmente vs cuántas devuelve?
--
-- PREGUNTA 2: ¿CUÁLES COLUMNAS FILTRO EN DONDE (LEFT TO RIGHT)?
--   Mira tu WHERE: sensor_id, fecha_hora, valor, etc.
--   El índice DEBE empezar con la columna MÁS SELECTIVA (la que quita más filas).
--   Si hay dos filtros (sensor_id Y fecha_hora), ambos left-to-right.
--   Si hay uno solo, no necesitas índice compuesto.
--
-- PREGUNTA 3: ¿CUÁNTAS FILAS ESPERO vs CUÁNTAS DEVUELVO?
--   Si la consulta devuelve >20% de la tabla, el índice probablemente
--   no ayude. SCAN es más rápido.
--   Si devuelve <5%, un índice es imprescindible.
--   Entre 5-20%: depende, medir con el plan.
--
-- (La PRIMERA pregunta NO puede ser "creo un índice".)

-- =====================================================================
-- EXTRA (OPCIONAL - +5 puntos si el índice NO AYUDA)
-- =====================================================================

-- Consulta lenta encontrada: promedio de humedad por día en marzo
-- (usando la misma estrategia errónea del Ejercicio 6)
SELECT '=== EXTRA: Consulta lenta original ===' AS test;

SELECT DATE(fecha_hora) AS dia, ROUND(AVG(valor),2) AS humedad_prom
FROM lecturas_historico
WHERE sensor_id IN (2, 6)  -- sensores de humedad
  AND DATE(fecha_hora) BETWEEN '2026-03-01' AND '2026-03-31'
GROUP BY dia;
-- RESULTADO: 31 filas, todos con 71.00 aprox.

-- PLAN ORIGINAL (con ix_hist_sensor_fecha):
EXPLAIN QUERY PLAN
SELECT DATE(fecha_hora) AS dia, ROUND(AVG(valor),2) AS humedad_prom
FROM lecturas_historico
WHERE sensor_id IN (2, 6)
  AND DATE(fecha_hora) BETWEEN '2026-03-01' AND '2026-03-31'
GROUP BY dia;
-- PLAN: SEARCH ix_hist_sensor_fecha (sensor_id=?)  [cubre ambos sensores]
--       USE TEMP B-TREE FOR GROUP BY
--
-- Problema: fecha_hora no se usa, recorre 35.040 filas de dos sensores
-- para un mes (1.440 esperadas).

-- INDEXACIÓN INCORRECTA (NO AYUDA):
-- Probé crear un índice sobre (tipo_sensor, fecha_hora) pero
-- lecturas_historico NO tiene columna tipo_sensor (está en sensores).
--
-- Entonces creé un índice sobre (valor, fecha_hora):
DROP INDEX IF EXISTS ix_hist_valor_fecha;
CREATE INDEX ix_hist_valor_fecha ON lecturas_historico (valor, fecha_hora);

EXPLAIN QUERY PLAN
SELECT DATE(fecha_hora) AS dia, ROUND(AVG(valor),2) AS humedad_prom
FROM lecturas_historico
WHERE sensor_id IN (2, 6)
  AND DATE(fecha_hora) BETWEEN '2026-03-01' AND '2026-03-31'
GROUP BY dia;
-- PLAN: SEARCH ix_hist_sensor_fecha (sensor_id=?)
--       USE TEMP B-TREE FOR GROUP BY
--
-- NO CAMBIÓ. Sigue siendo lento porque:
--
-- 1. El filtro por sensor_id se evalúa PRIMERO (es más selectivo)
--   y ya está en ix_hist_sensor_fecha.
-- 2. El nuevo índice (valor, fecha_hora) no empieza con sensor_id,
--   así que SQLite no lo considera. Es un índice INÚTIL.
-- 3. Para que ayudara, necesitaría ser (sensor_id, fecha_hora, valor).
--   Pero incluso así, como usamos DATE(fecha_hora), seguiría sin ayudar.

-- SOLUCIÓN CORRECTA:
SELECT DATE(fecha_hora) AS dia, ROUND(AVG(valor),2) AS humedad_prom
FROM lecturas_historico
WHERE sensor_id IN (2, 6)
  AND fecha_hora >= '2026-03-01'
  AND fecha_hora <  '2026-04-01'
GROUP BY dia;
-- RESULTADO: mismo, 31 × 71.00

EXPLAIN QUERY PLAN
SELECT DATE(fecha_hora) AS dia, ROUND(AVG(valor),2) AS humedad_prom
FROM lecturas_historico
WHERE sensor_id IN (2, 6)
  AND fecha_hora >= '2026-03-01'
  AND fecha_hora <  '2026-04-01'
GROUP BY dia;
-- PLAN: SEARCH ix_hist_sensor_fecha (sensor_id=? AND fecha_hora>? AND fecha_hora<?)
--       USE TEMP B-TREE FOR GROUP BY
--
-- Ahora usa ambas partes del índice: van directo a las ~1.440 filas.

-- CONCLUSIÓN DEL EXTRA:
-- El índice (valor, fecha_hora) NO AYUDA porque:
--   1. No contiene la columna de filtro primario (sensor_id)
--   2. SQLite usa el índice más específico primero, que es (sensor_id, fecha_hora)
--   3. Un índice mal diseñado cuesta disco y escritura sin beneficio
--
-- Bonus: El índice se borra porque es un fantasma.
DROP INDEX IF EXISTS ix_hist_valor_fecha;

-- =====================================================================
-- CIERRE - Verificación final
-- =====================================================================

-- Índices finales que quedan después de todo el ejercicio:
SELECT name, tbl_name FROM sqlite_master WHERE type = 'index' AND name LIKE 'ix_hist%';
-- Esperado: solo ix_hist_sensor_fecha
--
-- Porque:
--   * ix_hist_fecha se borrò al final de D3
--   * ix_hist_valor se borrò en D5
--   * ix_hist_valor_fecha se borrò al final del EXTRA
--   * Solo queda ix_hist_sensor_fecha que es el que REALMENTE AYUDA