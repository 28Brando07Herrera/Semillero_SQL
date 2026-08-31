-- =====================================================================
-- Ejercicio práctico 9 · Cien mil filas y un plan que dice SCAN
-- Herrera, Brando
--
-- Este archivo se corre completo, de arriba a abajo, DESPUÉS de haber
-- ejecutado datos/agrodb_clase9.sql en la misma base.
-- Todo CREATE INDEX propio lleva DROP INDEX IF EXISTS antes, para que
-- una segunda corrida no falle.
-- =====================================================================


-- =====================================================================
-- PARTE A · Mirar antes de tocar
-- =====================================================================

-- A1. Esperado: 105.120 filas, 6 sensores, 17.520 por sensor
SELECT COUNT(*) FROM lecturas_historico;
SELECT sensor_id, COUNT(*) FROM lecturas_historico GROUP BY sensor_id;

-- A2. Los índices que ya existen
SELECT name, tbl_name FROM sqlite_master WHERE type = 'index';
-- Esperado: 5 filas, todas sqlite_autoindex_*

-- Nadie escribió nunca un CREATE INDEX en este curso. ¿De dónde salió?
-- Salió solo, de manera automática. SQLite crea un índice interno
-- (con el prefijo sqlite_autoindex_) cada vez que una columna o
-- combinación de columnas se declara UNIQUE o PRIMARY KEY compuesta,
-- porque para garantizar que no se repita ningún valor, SQLite
-- necesita poder buscar rápido si ese valor ya existe antes de
-- insertar uno nuevo.
--
-- sqlite_autoindex_lecturas_1 es de la tabla lecturas. Se creó con la
-- línea UNIQUE (sensor_id, fecha_hora) que escribimos en la clase 6,
-- para que el datalogger no pudiera cargar dos veces la misma
-- medición. No lo pedimos como índice explícitamente: fue un efecto
-- colateral de pedir esa restricción de unicidad.
--
-- ¿Por qué UNIQUE necesita un índice para funcionar? Porque cada vez
-- que se inserta o actualiza una fila, SQLite tiene que verificar que
-- no exista ya otra fila con esos mismos valores. Sin un índice,
-- verificarlo significaría recorrer toda la tabla en cada INSERT para
-- comparar fila por fila; con el índice, esa verificación es
-- prácticamente instantánea porque los valores ya están ordenados y
-- localizables.

-- A3. ¿Aparece lecturas_historico en esa lista? NO aparece.
-- lecturas_historico usa "lectura_id INTEGER PRIMARY KEY", que en
-- SQLite es un alias directo del rowid interno de la tabla: no es un
-- índice aparte que SQLite tenga que construir y mantener, sino la
-- estructura de almacenamiento física de la tabla misma. Por eso no
-- sale en sqlite_master como índice: ya "es" el orden físico de la
-- tabla, no algo adicional creado sobre ella. Ninguna otra columna de
-- lecturas_historico tiene UNIQUE, así que no hay ningún otro motivo
-- para que SQLite haya creado un índice ahí.


-- =====================================================================
-- PARTE B · Medir, indexar, volver a medir
-- =====================================================================

-- B1. La consulta lenta (mediciones por día en junio, sensor 1)
WITH RECURSIVE dia(n) AS (SELECT 0 UNION ALL SELECT n+1 FROM dia WHERE n < 29)
SELECT n + 1 AS dia_de_junio,
  (SELECT COUNT(*) FROM lecturas_historico l
    WHERE l.sensor_id = 1
      AND l.fecha_hora >= datetime('2026-06-01','+'||n||' days')
      AND l.fecha_hora <  datetime('2026-06-01','+'||(n+1)||' days')) AS n_lecturas
FROM dia;
-- Esperado: 30 filas, todas con 48.
-- Medido en este entorno (Python/sqlite3, no es el navegador ni la
-- consola local, pero sirve como referencia relativa): ~300 ms.
-- Se sintió: sin índice, esta consulta correlacionada recorre
-- lecturas_historico completa (105.120 filas) una vez POR CADA uno de
-- los 30 días, así que el tiempo escala con días x filas totales.

-- B2. ¿Por qué? Preguntémosle a SQLite.
EXPLAIN QUERY PLAN
WITH RECURSIVE dia(n) AS (SELECT 0 UNION ALL SELECT n+1 FROM dia WHERE n < 29)
SELECT n + 1 AS dia_de_junio,
  (SELECT COUNT(*) FROM lecturas_historico l
    WHERE l.sensor_id = 1
      AND l.fecha_hora >= datetime('2026-06-01','+'||n||' days')
      AND l.fecha_hora <  datetime('2026-06-01','+'||(n+1)||' days')) AS n_lecturas
FROM dia;
-- Última línea confirmada: SCAN l

-- ¿Qué significa SCAN? Que SQLite recorre la tabla entera, fila por
-- fila, en vez de ir directo a las filas que cumplen el filtro. No
-- tiene ningún índice que le diga dónde buscar, así que revisa todas.
-- Con 30 días y 105.120 filas: como esta subconsulta se ejecuta una
-- vez por cada uno de los 30 días (es una subconsulta correlacionada),
-- en total se están leyendo 30 × 105.120 = 3.153.600 lecturas de fila,
-- aunque la tabla en sí solo tiene 105.120 filas físicas.

-- B3. El índice
DROP INDEX IF EXISTS ix_hist_sensor_fecha;
CREATE INDEX ix_hist_sensor_fecha
    ON lecturas_historico (sensor_id, fecha_hora);

-- B4. Volvemos a correr B1 sin cambiar una letra, y medimos de nuevo.
WITH RECURSIVE dia(n) AS (SELECT 0 UNION ALL SELECT n+1 FROM dia WHERE n < 29)
SELECT n + 1 AS dia_de_junio,
  (SELECT COUNT(*) FROM lecturas_historico l
    WHERE l.sensor_id = 1
      AND l.fecha_hora >= datetime('2026-06-01','+'||n||' days')
      AND l.fecha_hora <  datetime('2026-06-01','+'||(n+1)||' days')) AS n_lecturas
FROM dia;
-- Esperado: mismas 30 filas, mismos 48.
-- Medido: ~0.3 ms (de ~300 ms a ~0.3 ms: unas mil veces más rápido).

EXPLAIN QUERY PLAN
WITH RECURSIVE dia(n) AS (SELECT 0 UNION ALL SELECT n+1 FROM dia WHERE n < 29)
SELECT n + 1 AS dia_de_junio,
  (SELECT COUNT(*) FROM lecturas_historico l
    WHERE l.sensor_id = 1
      AND l.fecha_hora >= datetime('2026-06-01','+'||n||' days')
      AND l.fecha_hora <  datetime('2026-06-01','+'||(n+1)||' days')) AS n_lecturas
FROM dia;
-- Última línea confirmada:
-- SEARCH l USING COVERING INDEX ix_hist_sensor_fecha
--        (sensor_id=? AND fecha_hora>? AND fecha_hora<?)

-- Las 30 filas y los 48 NO cambiaron: siguen siendo exactamente el
-- mismo resultado. Lo que cambió un índice no fue el resultado, sino
-- el CAMINO para llegar a ese resultado: antes SQLite recorría toda
-- la tabla para cada día, ahora va directo a las filas del sensor 1
-- dentro de cada rango de fecha, usando el índice como un atajo
-- ordenado. Un índice nunca cambia qué te devuelve la consulta —solo
-- cambia cuánto trabajo cuesta encontrarlo.


-- =====================================================================
-- PARTE C · La costumbre de tres clases
-- =====================================================================

-- C1. El promedio diario, escrito como se viene escribiendo desde la
-- clase 6, con DATE(fecha_hora) en el WHERE.
SELECT DATE(fecha_hora) AS dia, COUNT(*) AS n, ROUND(AVG(valor),2) AS prom
FROM lecturas_historico
WHERE sensor_id = 1
  AND DATE(fecha_hora) BETWEEN '2026-06-01' AND '2026-06-30'
GROUP BY dia;
-- Esperado y confirmado: 30 filas, cada una con n = 48 y prom = 23.88.

EXPLAIN QUERY PLAN
SELECT DATE(fecha_hora) AS dia, COUNT(*) AS n, ROUND(AVG(valor),2) AS prom
FROM lecturas_historico
WHERE sensor_id = 1
  AND DATE(fecha_hora) BETWEEN '2026-06-01' AND '2026-07-01'
GROUP BY dia;
-- Plan confirmado:
-- SEARCH lecturas_historico USING INDEX ix_hist_sensor_fecha (sensor_id=?)
-- USE TEMP B-TREE FOR GROUP BY

-- C2. Comparado con el plan de B4:
-- B4:  (sensor_id=? AND fecha_hora>? AND fecha_hora<?)
-- C1:  (sensor_id=?)                     <- solo esta parte
--
-- ¿Qué parte de la condición usa el índice, y cuál no? El índice
-- resuelve SOLO el filtro sensor_id = 1. La condición de fecha
-- (DATE(fecha_hora) BETWEEN ...) NO se resuelve con el índice: queda
-- afuera, como un filtro que SQLite aplica fila por fila después de
-- encontrar todas las filas del sensor 1.
--
-- ¿Sobre cuántas filas del sensor 1 está trabajando de verdad?
-- El sensor 1 tiene 17.520 lecturas en total (todo el año). Como el
-- índice solo filtra por sensor_id y no por fecha, SQLite tiene que
-- revisar las 17.520 filas del sensor 1 una por una y evaluarles
-- DATE(fecha_hora) BETWEEN..., aunque junio solo tenga 1.440 de esas
-- filas. Está trabajando sobre 17.520, no sobre 1.440.

-- C3. Por qué un índice ordenado por fecha_hora no sirve para DATE(fecha_hora).
-- El índice guarda los valores de fecha_hora TAL COMO ESTÁN
-- ALMACENADOS ('2026-06-15 14:30:00', por ejemplo), ordenados letra
-- por letra como texto. DATE(fecha_hora) le aplica una función a ese
-- valor ANTES de compararlo, y el resultado de esa función
-- (‘2026-06-15’) es un valor que el índice nunca calculó ni guardó en
-- ningún lado. Es como el índice alfabético al final de un libro,
-- ordenado por la primera letra de cada palabra: si alguien pide
-- "todas las palabras que tienen 'a' como tercera letra", ese índice
-- no le sirve de nada, porque está ordenado por un criterio distinto
-- al que se está preguntando. Para que un índice ayude, la pregunta
-- tiene que hacerse sobre la misma columna, en crudo, tal cual está
-- guardada, no sobre el resultado de transformarla.

-- C4. El arreglo: preguntar por la columna tal como está guardada, con
-- un rango, en vez de aplicarle una función.
SELECT DATE(fecha_hora) AS dia, COUNT(*) AS n, ROUND(AVG(valor),2) AS prom
FROM lecturas_historico
WHERE sensor_id = 1
  AND fecha_hora >= '2026-06-01'
  AND fecha_hora <  '2026-07-01'
GROUP BY dia;
-- Esperado y confirmado: las mismas 30 filas, los mismos 48, los
-- mismos 23.88.

EXPLAIN QUERY PLAN
SELECT DATE(fecha_hora) AS dia, COUNT(*) AS n, ROUND(AVG(valor),2) AS prom
FROM lecturas_historico
WHERE sensor_id = 1
  AND fecha_hora >= '2026-06-01'
  AND fecha_hora <  '2026-07-01'
GROUP BY dia;
-- Plan confirmado:
-- SEARCH lecturas_historico USING INDEX ix_hist_sensor_fecha
--        (sensor_id=? AND fecha_hora>? AND fecha_hora<?)
-- USE TEMP B-TREE FOR GROUP BY

-- C5. Usé < '2026-07-01' y no <= '2026-06-30'. Si hubiera escrito
-- fecha_hora <= '2026-06-30', ¿qué lecturas del 30 de junio se
-- pierden? Comprobado: se pierden 48 lecturas, prácticamente TODO el
-- 30 de junio, excepto la de exactamente medianoche (00:00:00).
-- Por qué: fecha_hora se guarda como texto, del tipo
-- '2026-06-30 14:30:00'. Comparado como texto contra el literal
-- '2026-06-30' (sin hora), cualquier fecha_hora que tenga algo después
-- de la fecha (' 00:30:00', ' 14:30:00', etc.) es, letra por letra,
-- MAYOR que '2026-06-30' solo, porque el string es más largo y sigue
-- después del corte. Solo pasa el filtro <= la fila que coincide
-- exactamente con '2026-06-30' sin nada más, que en este caso es la
-- de las 00:00:00. Usar < '2026-07-01' evita este problema porque no
-- depende de dónde "corta" la comparación de texto dentro del mismo día.

-- C6. Medido: la diferencia entre C1 (con DATE() en el WHERE) y C4
-- (con el rango explícito) es chica en este caso: son 17.520 filas
-- contra 1.440, y en ambos casos el tiempo es imperceptible al ojo o
-- se mide en milisegundos.
-- Si el reloj casi no lo muestra, ¿por qué arreglarlo igual?
--   1) Porque el reloj de hoy no es el reloj de mañana: esta consulta
--      corre sobre UN sensor y UN año. La versión con DATE() sigue
--      escaneando TODAS las filas del sensor (17.520 hoy) aunque solo
--      necesite 1.440; ese desperdicio crece proporcional al total de
--      datos del sensor, no al tamaño de lo que en verdad se pidió.
--   2) La regla del día es "el plan es la evidencia, no el reloj": el
--      plan de C1 ya muestra el problema (SEARCH solo por sensor_id,
--      sin acotar fecha) aunque el cronómetro todavía no lo delate.
--      Esperar a que el reloj se queje es esperar a que ya sea tarde.
--   3) Con diez años de datos en vez de uno, el sensor tendría del
--      orden de 175.200 lecturas en vez de 17.520. La versión con
--      DATE(fecha_hora) seguiría escaneando TODAS esas 175.200 filas
--      para sacar un mes, mientras que la versión con rango seguiría
--      leyendo solo las ~1.440 del mes pedido, sin importar cuántos
--      años más se acumulen atrás. La diferencia, que hoy es
--      imperceptible, se volvería évidente exactamente en el momento
--      en que ya sea más caro corregirla en producción.

-- C7. Consulta propia de ejercicios anteriores que usa DATE(fecha_hora)
-- en el WHERE. Del ejercicio 8, Parte C (auditoría de v_temp_diaria),
-- usé varias veces cosas como:
--
--   SELECT dia, temp_promedio, RANK() OVER (ORDER BY temp_promedio DESC)
--   FROM v_temp_diaria;
--
-- que por dentro filtra con GROUP BY DATE(l.fecha_hora) (la vista
-- v_temp_diaria agrupa así). En ese momento el volumen era de 973
-- filas y no importaba. Hoy, con 105.120 filas, la reescribiría
-- evitando agrupar/filtrar por DATE(fecha_hora) directamente y en su
-- lugar generando el rango de cada día de antemano (como hice en B1),
-- o -si el requisito lo permite- guardando una columna de fecha ya
-- normalizada (solo la parte de fecha, sin hora) en vez de calcularla
-- al vuelo en cada consulta.


-- =====================================================================
-- PARTE D · Cuándo el índice no alcanza
-- =====================================================================

-- D1. El prefijo izquierdo. Con ix_hist_sensor_fecha (sensor_id, fecha_hora)
-- ya creado, preguntamos SOLO por fecha_hora (sin sensor_id):
EXPLAIN QUERY PLAN
SELECT COUNT(*) FROM lecturas_historico
WHERE fecha_hora >= '2026-06-01' AND fecha_hora < '2026-07-01';
-- Confirmado: SCAN lecturas_historico USING COVERING INDEX ix_hist_sensor_fecha

-- ¿Por qué SCAN y no SEARCH, si fecha_hora está en el índice?
-- Porque el índice está ordenado PRIMERO por sensor_id y DENTRO de
-- cada sensor_id, por fecha_hora — como un directorio telefónico
-- ordenado por apellido y luego por nombre. Si busco solo por nombre
-- (sin apellido), no puedo "saltar" directo a las páginas correctas:
-- tengo que revisar cada bloque de apellido para encontrar los
-- nombres que coinciden. Sin filtrar por sensor_id (la primera
-- columna del índice), SQLite no puede usar el índice para saltar
-- directo a un rango de fecha: tiene que recorrerlo entero.
--
-- Dice USING COVERING INDEX. Si igual recorre todo, ¿para qué sirve?
-- Sirve porque el índice contiene las columnas sensor_id y fecha_hora
-- (y el rowid), que es todo lo que esta consulta necesita para contar
-- (COUNT(*) no necesita el valor). Recorrer el índice completo, que es
-- más chico y compacto que la tabla entera (no trae la columna valor),
-- es más barato que recorrer la tabla completa, aunque siga siendo un
-- recorrido total y no una búsqueda directa.

-- D2. El índice que sí sirve para esa consulta.
DROP INDEX IF EXISTS ix_hist_fecha;
CREATE INDEX ix_hist_fecha ON lecturas_historico (fecha_hora);

EXPLAIN QUERY PLAN
SELECT COUNT(*) FROM lecturas_historico
WHERE fecha_hora >= '2026-06-01' AND fecha_hora < '2026-07-01';
-- Confirmado: pasa a SEARCH lecturas_historico USING COVERING INDEX
-- ix_hist_fecha (fecha_hora>? AND fecha_hora<?)

-- Ahora hay dos índices sobre la misma tabla. ¿Está mal? No está mal
-- en sí mismo: cada índice sirve para un patrón de consulta distinto
-- (uno para "por sensor y luego por fecha", otro para "solo por
-- fecha"), y ambos son consultas reales que ya usamos hoy. Empezaría a
-- estar mal si se acumulan índices que nadie consulta realmente, o que
-- se solapan sin necesidad (por ejemplo, un tercer índice solo por
-- sensor_id sería redundante, porque ix_hist_sensor_fecha ya cubre ese
-- caso por prefijo izquierdo). Cada índice de más cuesta espacio en
-- disco y hace más lento cada INSERT/UPDATE, así que la pregunta no es
-- "¿está mal tener dos?" sino "¿los dos se usan de verdad?".

-- D3. El ORDER BY gratis. Misma consulta, tres planes distintos según
-- qué índices existan. (Los pasos siguientes recrean el escenario en
-- el orden exacto que pide el enunciado.)

-- Paso 1: con los dos índices creados (ix_hist_sensor_fecha e ix_hist_fecha)
EXPLAIN QUERY PLAN
SELECT fecha_hora, valor FROM lecturas_historico
WHERE sensor_id = 1 ORDER BY fecha_hora LIMIT 10;
-- Confirmado, una sola línea:
-- SEARCH lecturas_historico USING INDEX ix_hist_sensor_fecha (sensor_id=?)

-- Paso 2: sin ningún índice
DROP INDEX ix_hist_sensor_fecha;
DROP INDEX ix_hist_fecha;

EXPLAIN QUERY PLAN
SELECT fecha_hora, valor FROM lecturas_historico
WHERE sensor_id = 1 ORDER BY fecha_hora LIMIT 10;
-- Confirmado:
-- SCAN lecturas_historico
-- USE TEMP B-TREE FOR ORDER BY

-- Apareció una línea que no estaba: USE TEMP B-TREE FOR ORDER BY.
-- ¿Qué está haciendo SQLite ahí, y sobre cuántas filas? Como no hay
-- ningún índice, SQLite primero tiene que traer TODAS las filas del
-- sensor 1 (17.520 filas) recorriendo la tabla entera (105.120 filas
-- totales), y como esas filas no vienen en ningún orden útil por
-- fecha, las junta en una estructura temporal en memoria/disco (un
-- B-Tree temporal) solo para poder ordenarlas y así devolver las
-- primeras 10. Trabaja sobre las 105.120 filas de la tabla para
-- terminar devolviendo solo 10.

-- Paso 3: solo con el índice sobre fecha_hora
CREATE INDEX ix_hist_fecha ON lecturas_historico (fecha_hora);

EXPLAIN QUERY PLAN
SELECT fecha_hora, valor FROM lecturas_historico
WHERE sensor_id = 1 ORDER BY fecha_hora LIMIT 10;
-- Confirmado: SCAN lecturas_historico USING INDEX ix_hist_fecha

-- Sigue diciendo SCAN (recorre todo), pero la línea de
-- USE TEMP B-TREE ya no está. Si igual recorre la tabla entera, ¿por
-- qué dejó de ordenar? Porque el índice ix_hist_fecha ya tiene las
-- filas ordenadas por fecha_hora de antemano: cuando SQLite lo
-- recorre en su orden natural, las va entregando ya en el orden que
-- el ORDER BY pidió, sin necesidad de juntarlas aparte y ordenarlas
-- manualmente. El índice le da el orden "gratis" simplemente por
-- cómo está construido, aunque igual tenga que revisarlo de punta a
-- punta para encontrar las filas del sensor 1 dentro de ese orden.

-- Paso 4: recrear el índice compuesto antes de seguir.
CREATE INDEX ix_hist_sensor_fecha ON lecturas_historico (sensor_id, fecha_hora);

-- D4. Un SEARCH que no sirve de mucho.
DROP INDEX IF EXISTS ix_hist_valor;
CREATE INDEX ix_hist_valor ON lecturas_historico (valor);

EXPLAIN QUERY PLAN SELECT COUNT(*) FROM lecturas_historico WHERE valor > 28;
SELECT COUNT(*) FROM lecturas_historico WHERE valor > 28;
-- Confirmado: SEARCH lecturas_historico USING COVERING INDEX
--             ix_hist_valor (valor>?)
-- Confirmado: 59.495 filas de 105.120.

-- El plan dice SEARCH. ¿Está esta consulta bien resuelta? NO, no en la
-- práctica, aunque el plan diga la palabra que "queríamos ver". Un
-- SEARCH normalmente promete ir directo a las filas que cumplen la
-- condición sin mirar las demás, pero acá la condición (valor > 28)
-- cumple más de la MITAD de toda la tabla (59.495 de 105.120, más del
-- 56%). Un índice tiene sentido cuando ayuda a IGNORAR la mayoría de
-- las filas; cuando el resultado es más de la mitad de la tabla, el
-- índice igual tiene que recorrer prácticamente la misma cantidad de
-- entradas que tendría que revisar un SCAN completo, solo que
-- ordenadas de otra forma.
--
-- ¿Cuántas entradas del índice tuvo que recorrer para contar 59.495
-- filas? Exactamente 59.495 entradas del índice (una por cada fila que
-- cumple valor > 28) — el índice no tiene atajos para "saltarse"
-- filas que sí cumplen la condición, tiene que visitarlas todas para
-- contarlas, sean 5 o sean 59.495.
--
-- ¿Alcanza con mirar si el plan dice SEARCH? No alcanza. Además de la
-- palabra SEARCH, hay que mirar QUÉ PROPORCIÓN de la tabla en realidad
-- está devolviendo/recorriendo esa búsqueda. Un SEARCH sobre más de la
-- mitad de las filas no ahorra casi nada frente a un SCAN directo, y
-- en cambio el índice de todas formas sigue costando espacio en disco
-- y trabajo extra en cada escritura.

-- D5. Borramos el índice de valor.
DROP INDEX IF EXISTS ix_hist_valor;
-- Por qué: ese índice no está pagando su costo. La consulta que lo
-- motivó (valor > 28) devuelve más de la mitad de la tabla, así que el
-- índice apenas ahorra trabajo de lectura frente a un SCAN normal,
-- mientras que igual suma espacio en disco y hace más lento cada
-- INSERT nuevo en lecturas_historico (que en este modelo se inserta
-- cada 30 minutos, por sensor). El costo de mantenerlo no se justifica
-- con el beneficio que da.


-- =====================================================================
-- PARTE E · Lo que cuesta, y cierre
-- =====================================================================

-- E1. Un índice se paga en tres monedas:
--   1) Espacio en disco: el índice es una copia ordenada (parcial) de
--      los datos, que ocupa lugar además de la tabla original.
--   2) Escrituras más lentas: cada INSERT, UPDATE o DELETE sobre la
--      tabla tiene que actualizar también todos los índices que la
--      cubren, así que escribir se vuelve más trabajo cuantos más
--      índices existan.
--   3) Mantenimiento humano: alguien tiene que saber que el índice
--      existe, para qué sirve, y decidir cuándo ya no vale la pena
--      (como en D4-D5) o cuándo falta uno nuevo.
-- En una tabla de sensores que recibe una medición cada 30 minutos, la
-- más cara de las tres es la escritura (2): son inserciones
-- constantes y frecuentes (cada sensor, cada media hora, todo el año),
-- así que cualquier índice de más que no se use de verdad se paga una
-- y otra vez, en cada una de esas inserciones, aunque casi nunca se
-- lea.

-- E2. ¿Quién hace el trabajo, la vista o el índice? El índice. Una
-- vista solo le pone nombre a una consulta y no acelera nada por sí
-- misma (ya lo vimos en la clase 8: no se puede indexar una vista
-- directamente). Quien realmente reduce el trabajo de lectura es el
-- índice creado sobre la tabla de abajo; la vista simplemente hereda
-- la velocidad (o lentitud) de las tablas que consulta por dentro.

-- E3. Las tres preguntas que me haría, en orden, la próxima vez que
-- una consulta esté lenta:
--   1) ¿Qué dice EXPLAIN QUERY PLAN? (no "creo un índice" a ciegas:
--      primero hay que ver si de verdad dice SCAN sobre una tabla
--      grande, y sobre qué columnas se está filtrando).
--   2) De lo que el WHERE/ORDER BY/GROUP BY realmente necesita, ¿hay
--      alguna función aplicada sobre la columna (como DATE(fecha_hora))
--      que esté anulando un índice que ya existe, y se puede reescribir
--      como un rango en su lugar?
--   3) Si hace falta un índice nuevo, ¿la condición que resolvería
--      devuelve una porción chica de la tabla (donde un SEARCH real
--      ahorra trabajo) o más de la mitad (donde un índice nuevo no
--      compensa el costo de mantenerlo, como pasó en D4)?
