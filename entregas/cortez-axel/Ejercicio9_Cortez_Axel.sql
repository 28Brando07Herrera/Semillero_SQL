-- EJERCICIO PRÁCTICO 9: Cien mil filas y un plan que dice SCAN
-- Estudiante: Cortez Axel
-- Motor: SQLite | Entorno: sqliteonline.com

PRAGMA foreign_keys = ON;

-- Limpieza preventiva de índices creados en la sesión
DROP INDEX IF EXISTS ix_hist_sensor_fecha;
DROP INDEX IF EXISTS ix_hist_fecha;
DROP INDEX IF EXISTS ix_hist_valor;
DROP INDEX IF EXISTS ix_cosechas_fecha;


-- PARTE A · MIRAR ANTES DE TOCAR

-- A1. Conteo de volumen y distribución por sensor
-- Esperado: 105.120 filas totales, 6 sensores con 17.520 mediciones cada uno
SELECT COUNT(*) AS total_historico FROM lecturas_historico;

SELECT sensor_id, COUNT(*) AS lecturas_por_sensor 
FROM lecturas_historico 
GROUP BY sensor_id;


-- A2. Inspección de índices automáticos preexistentes
-- Esperado: 5 filas con prefijo 'sqlite_autoindex_'
SELECT name, tbl_name FROM sqlite_master WHERE type = 'index';

/*
COMENTARIO A2:
1. Estos índices no los creamos con CREATE INDEX; SQLite los genera internamente de forma automática cada vez que definimos restricciones UNIQUE o PRIMARY KEY compuestas/textuales en el esquema.
2. El índice 'sqlite_autoindex_lecturas_1' lo creamos en el Ejercicio 6 al agregar la restricción: `UNIQUE (sensor_id, fecha_hora)`.
3. Una restricción UNIQUE necesita un índice B-Tree obligatoriamente porque en cada INSERT o UPDATE el motor debe verificar en tiempo O(log N) que la clave no esté duplicada; sin un índice, tendría que hacer un escaneo secuencial (SCAN) de toda la tabla en cada inserción.
*/


/*
COMENTARIO A3:
'lecturas_historico' no aparece en esa lista porque su clave primaria está definida como `lectura_id INTEGER PRIMARY KEY`. En SQLite, esto convierte a la columna en un alias directo del 'rowid' (la clave del árbol B principal de la tabla), por lo que no necesita crear una estructura de índice B-Tree separada.
*/


-- PARTE B · MEDIR, INDEXAR, VOLVER A MEDIR

-- B1. Consulta lenta: Conteo diario de mediciones en junio
-- Esperado: 30 filas, todas con n_lecturas = 48
WITH RECURSIVE dia(n) AS (SELECT 0 UNION ALL SELECT n+1 FROM dia WHERE n < 29)
SELECT n + 1 AS dia_de_junio,
  (SELECT COUNT(*) FROM lecturas_historico l
    WHERE l.sensor_id = 1
      AND l.fecha_hora >= datetime('2026-06-01','+'||n||' days')
      AND l.fecha_hora <  datetime('2026-06-01','+'||(n+1)||' days')) AS n_lecturas
FROM dia;

/*
COMENTARIO B1:
En la ejecución se siente una pausa evidente (~350 ms). Para una sola consulta analítica parece poco, pero si 10 usuarios abren el tablero al mismo tiempo, el servidor se satura de inmediato.
*/


-- B2. Diagnóstico de la consulta lenta con EXPLAIN QUERY PLAN
EXPLAIN QUERY PLAN
WITH RECURSIVE dia(n) AS (SELECT 0 UNION ALL SELECT n+1 FROM dia WHERE n < 29)
SELECT n + 1 AS dia_de_junio,
  (SELECT COUNT(*) FROM lecturas_historico l
    WHERE l.sensor_id = 1
      AND l.fecha_hora >= datetime('2026-06-01','+'||n||' days')
      AND l.fecha_hora <  datetime('2026-06-01','+'||(n+1)||' days')) AS n_lecturas
FROM dia;

/*
COMENTARIO B2:
El plan indica `SCAN l`. 
SCAN significa que SQLite recorre la tabla de inicio a fin fila por fila (Full Table Scan). 
Dado que el CTE evalúa la subconsulta 30 veces (una por cada día) y la tabla tiene 105.120 filas, SQLite termina leyendo un total de 3.153.600 filas (30 * 105.120) para devolver apenas 30 números.
*/


-- B3. Creación del índice compuesto óptimo
CREATE INDEX ix_hist_sensor_fecha
    ON lecturas_historico (sensor_id, fecha_hora);


-- B4. Repetición de la consulta B1 y verificación del nuevo plan
-- Esperado: Mismas 30 filas con 48, pero ejecución instantánea
WITH RECURSIVE dia(n) AS (SELECT 0 UNION ALL SELECT n+1 FROM dia WHERE n < 29)
SELECT n + 1 AS dia_de_junio,
  (SELECT COUNT(*) FROM lecturas_historico l
    WHERE l.sensor_id = 1
      AND l.fecha_hora >= datetime('2026-06-01','+'||n||' days')
      AND l.fecha_hora <  datetime('2026-06-01','+'||(n+1)||' days')) AS n_lecturas
FROM dia;

EXPLAIN QUERY PLAN
WITH RECURSIVE dia(n) AS (SELECT 0 UNION ALL SELECT n+1 FROM dia WHERE n < 29)
SELECT n + 1 AS dia_de_junio,
  (SELECT COUNT(*) FROM lecturas_historico l
    WHERE l.sensor_id = 1
      AND l.fecha_hora >= datetime('2026-06-01','+'||n||' days')
      AND l.fecha_hora <  datetime('2026-06-01','+'||(n+1)||' days')) AS n_lecturas
FROM dia;

/*
COMENTARIO B4:
El plan ahora muestra: `SEARCH l USING COVERING INDEX ix_hist_sensor_fecha (sensor_id=? AND fecha_hora>? AND fecha_hora<?)`.
Las 30 filas y los 48 no cambiaron. El índice no modificó en absoluto el resultado de los datos; lo que cambió fue el mecanismo de acceso del motor, pasando de escanear 3.1 millones de registros a realizar búsquedas binarias directas en el B-Tree en cuestión de microsegundos.
*/

-- PARTE C · LA COSTUMBRE DE TRES CLASES

-- C1. Consulta con función en el WHERE (Mala práctica común)
-- Esperado: 30 filas con n = 48 y prom = 23.88
SELECT DATE(fecha_hora) AS dia, COUNT(*) AS n, ROUND(AVG(valor),2) AS prom
FROM lecturas_historico
WHERE sensor_id = 1
  AND DATE(fecha_hora) BETWEEN '2026-06-01' AND '2026-06-30'
GROUP BY dia;

EXPLAIN QUERY PLAN
SELECT DATE(fecha_hora) AS dia, COUNT(*) AS n, ROUND(AVG(valor),2) AS prom
FROM lecturas_historico
WHERE sensor_id = 1
  AND DATE(fecha_hora) BETWEEN '2026-06-01' AND '2026-06-30'
GROUP BY dia;


/*
COMENTARIO C2:
1. El índice solo se usó para la condición `sensor_id=?`. La condición de fecha con `DATE()` no pudo aprovechar el índice.
2. Está trabajando sobre las 17.520 filas completas que tiene el sensor 1 en todo el año, cargándolas en memoria para aplicarles la función DATE() una por una, en lugar de ir directamente a las 1.440 filas que corresponden a junio.
*/


/*
COMENTARIO C3:
El índice guarda las cadenas completas 'YYYY-MM-DD HH:MM:SS' ordenadas lexicográficamente. 
Al envolver la columna en `DATE(fecha_hora)`, obligamos a SQLite a ejecutar una función sobre cada valor para conocer el resultado antes de poder comparar. 
Es como buscar en el índice alfabético de un libro todas las palabras cuya tercera letra sea una 'e': tener el libro ordenado de la A a la Z no sirve para esa regla, y toca leer todo el índice palabra por palabra.
*/


-- C4. Corrección: Consulta SARGable con rango semiabierto puro
-- Esperado: Mismas 30 filas (48 / 23.88), plan óptimo con búsqueda compuesta
SELECT DATE(fecha_hora) AS dia, COUNT(*) AS n, ROUND(AVG(valor),2) AS prom
FROM lecturas_historico
WHERE sensor_id = 1
  AND fecha_hora >= '2026-06-01'
  AND fecha_hora <  '2026-07-01'
GROUP BY dia;

EXPLAIN QUERY PLAN
SELECT DATE(fecha_hora) AS dia, COUNT(*) AS n, ROUND(AVG(valor),2) AS prom
FROM lecturas_historico
WHERE sensor_id = 1
  AND fecha_hora >= '2026-06-01'
  AND fecha_hora <  '2026-07-01'
GROUP BY dia;


/*
COMENTARIO C5:
Si escribo `<= '2026-06-30'`, la comparación textual asume medianoche `'2026-06-30 00:00:00'`. 
Como los registros tienen hora (ej. '2026-06-30 00:30:00', '2026-06-30 15:00:00'), cualquier medición posterior a la medianoche es mayor que '2026-06-30', por lo que me perdería 47 de las 48 lecturas del último día del mes.
*/


/*
COMENTARIO C6:
Aunque con 105k filas la diferencia en el cronómetro sea de pocos milisegundos, con 5 o 10 años de operación histórica (millones de filas) evaluar `DATE()` sobre millones de registros bloquea la CPU y el pool de conexiones; estructurar consultas SARGable asegura que la base escale sin degradar el servicio.
*/


/*
COMENTARIO C7:
Consulta mía en el Ejercicio 6 / 7:
SELECT DATE(fecha_hora) AS dia, AVG(valor) FROM lecturas WHERE sensor_id = 1 AND DATE(fecha_hora) = '2026-04-20' GROUP BY dia;

Cómo la escribo hoy:
SELECT DATE(fecha_hora) AS dia, AVG(valor) FROM lecturas WHERE sensor_id = 1 AND fecha_hora >= '2026-04-20' AND fecha_hora < '2026-04-21' GROUP BY DATE(fecha_hora);
*/

-- PARTE D · CUÁNDO EL ÍNDICE NO ALCANZA

-- D1. Demostración de la regla del prefijo izquierdo (Leftmost Prefix)
EXPLAIN QUERY PLAN
SELECT COUNT(*) FROM lecturas_historico
WHERE fecha_hora >= '2026-06-01' AND fecha_hora < '2026-07-01';

/*
COMENTARIO D1:
1. Dice SCAN porque el índice compuesto está ordenado primero por 'sensor_id' y luego por 'fecha_hora'. Al no incluir el sensor en el filtro, SQLite no puede hacer un salto directo (SEARCH) al rango de fechas.
2. Dice COVERING INDEX porque el índice contiene la columna 'fecha_hora' que pide el WHERE. SQLite aprovecha que el archivo del índice es más estrecho y liviano que la tabla completa para escanearlo a él en lugar de leer toda la tabla física en disco.
*/


-- D2. Creación de índice por fecha independiente
CREATE INDEX ix_hist_fecha ON lecturas_historico (fecha_hora);

EXPLAIN QUERY PLAN
SELECT COUNT(*) FROM lecturas_historico
WHERE fecha_hora >= '2026-06-01' AND fecha_hora < '2026-07-01';

/*
COMENTARIO D2:
Tener dos índices no está mal si responden a patrones de búsqueda distintos (uno filtra por sensor+fecha y el otro solo por fecha global). Empezaría a estar mal si creamos índices redundantes para cada campo sin justificación, ya que cada índice penaliza los tiempos de inserción (INSERT/UPDATE) y ocupa almacenamiento innecesario.
*/


-- D3. El ORDER BY gratis
-- Paso 1: Con ambos índices
EXPLAIN QUERY PLAN
SELECT fecha_hora, valor FROM lecturas_historico
WHERE sensor_id = 1 ORDER BY fecha_hora LIMIT 10;

-- Paso 2: Sin ningún índice
DROP INDEX ix_hist_sensor_fecha;
DROP INDEX ix_hist_fecha;

EXPLAIN QUERY PLAN
SELECT fecha_hora, valor FROM lecturas_historico
WHERE sensor_id = 1 ORDER BY fecha_hora LIMIT 10;

/*
COMENTARIO D3 (Paso 2):
SQLite tuvo que escanear toda la tabla (SCAN) y cargar las 105.120 filas en una estructura temporal en memoria/disco (USE TEMP B-TREE FOR ORDER BY) para ordenarlas todas antes de poder recortar las 10 que pide el LIMIT.
*/

-- Paso 3: Solo con índice sobre fecha_hora
CREATE INDEX ix_hist_fecha ON lecturas_historico (fecha_hora);

EXPLAIN QUERY PLAN
SELECT fecha_hora, valor FROM lecturas_historico
WHERE sensor_id = 1 ORDER BY fecha_hora LIMIT 10;

/*
COMENTARIO D3 (Paso 3):
Ya no aparece 'USE TEMP B-TREE' porque el índice ya almacena físicamente los datos ordenados por fecha_hora. SQLite solo tiene que recorrer el índice en su orden natural y detenerse inmediatamente en cuanto encuentra las primeras 10 coincidencias con sensor_id = 1.
*/

-- Paso 4: Restaurar el índice compuesto principal
CREATE INDEX ix_hist_sensor_fecha ON lecturas_historico (sensor_id, fecha_hora);


-- D4. Análisis de selectividad: Un SEARCH que no ayuda
CREATE INDEX ix_hist_valor ON lecturas_historico (valor);

EXPLAIN QUERY PLAN SELECT COUNT(*) FROM lecturas_historico WHERE valor > 28;
SELECT COUNT(*) FROM lecturas_historico WHERE valor > 28;

/*
COMENTARIO D4:
1. NO está bien resuelta. Que el plan diga SEARCH no garantiza eficiencia si la consulta carece de selectividad.
2. Tuvo que recorrer 59.495 entradas en el índice, lo que representa más del 56% de toda la tabla.
3. No basta con ver SEARCH; hay que analizar la selectividad del predicado (qué porcentaje de filas devuelve) y el costo total de E/S. Cuando se recupera más del 20-30% de la tabla, un SCAN secuencial directo suele ser más rápido que saltar por las páginas de un índice.
*/


-- D5. Eliminación del índice de baja selectividad
DROP INDEX ix_hist_valor;

/*
COMENTARIO D5:
Lo borro porque una columna con baja selectividad (>56% de aciertos) genera sobrecosto de mantenimiento y espacio en cada INSERT/UPDATE sin aportar una mejora real en las consultas.
*/

-- PARTE E · LO QUE CUESTA Y CIERRE

/*
1. Las tres monedas de un índice:
Se pagan en: 1) Espacio en disco, 2) Memoria RAM (Buffer Pool) y 3) Tiempo de CPU/escritura en operaciones DML (INSERT, UPDATE, DELETE).
En tablas de telemetría y sensores, la más cara es el tiempo de escritura/DML, porque con frecuencias de 30 minutos cada inserción obliga a rebalancear múltiples árboles B de índices en tiempo real.

2. ¿Quién hace el trabajo?:
El índice hace el trabajo físico de optimizar las rutas de acceso en disco; la vista solo guarda el texto de la consulta para no tener que reescribirlo.

3. Tres preguntas antes de crear un índice:
1) ¿Está la consulta escrita de forma SARGable (sin funciones como DATE() o LIKE '%...' sobre las columnas filtradas)?
2) ¿Tiene el filtro suficiente selectividad (devuelve un subconjunto pequeño de filas o se trae media tabla)?
3) ¿Existe ya algún índice cuyo prefijo izquierdo o columnas cubran esta condición sin necesidad de crear uno nuevo?
*/


-- EXTRA: Optimización de consulta en cosechas

-- Consulta lenta: Auditoría de cosechas por rango de fecha
-- Plan sin índice:
EXPLAIN QUERY PLAN
SELECT c.cosecha_id, f.nombre AS finca, l.codigo AS lote, c.fecha, c.kg
FROM cosechas c
JOIN siembras s ON c.siembra_id = s.siembra_id
JOIN lotes l ON s.lote_id = l.lote_id
JOIN fincas f ON l.finca_id = f.finca_id
WHERE c.fecha >= '2026-04-01' AND c.fecha < '2026-05-01';
-- Muestra SCAN c

-- Creación del índice para optimizar la búsqueda por fecha en cosechas:
CREATE INDEX ix_cosechas_fecha ON cosechas (fecha);

-- Plan optimizado con índice:
EXPLAIN QUERY PLAN
SELECT c.cosecha_id, f.nombre AS finca, l.codigo AS lote, c.fecha, c.kg
FROM cosechas c
JOIN siembras s ON c.siembra_id = s.siembra_id
JOIN lotes l ON s.lote_id = l.lote_id
JOIN fincas f ON l.finca_id = f.finca_id
WHERE c.fecha >= '2026-04-01' AND c.fecha < '2026-05-01';
-- Muestra SEARCH c USING INDEX ix_cosechas_fecha (fecha>? AND fecha<?)

/*
JUSTIFICACIÓN EXTRA:
La tabla cosechas se consulta frecuentemente por ventanas mensuales para liquidaciones agrícolas. Al indexar 'fecha', el optimizador arranca el plan haciendo un SEARCH directo por rango temporal sobre 'cosechas' en lugar de recorrer toda la tabla con SCAN, reduciendo los accesos a disco antes de resolver los JOINs con siembras y lotes.
*/