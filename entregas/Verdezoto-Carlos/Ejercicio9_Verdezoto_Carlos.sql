-- =====================================================================
-- CURSO DE SQL  |  AgroDB  |  Ejercicio 9
-- Alumno: Verdezoto León Carlos Gabriel
-- Fecha: 2026-08-20
--
-- Este archivo se ejecuta DESPUES de datos/agrodb_clase9.sql (Agronomia_clase3.sql)
-- en la MISMA sesión de SQLite.
-- =====================================================================

PRAGMA foreign_keys = ON;

-- =====================================================================
-- PARTE A · MIRAR ANTES DE TOCAR
-- =====================================================================

-- A1. Conteo inicial
SELECT COUNT(*) AS total_filas FROM lecturas_historico;
SELECT sensor_id, COUNT(*) AS filas_por_sensor FROM lecturas_historico GROUP BY sensor_id;

-- A2. Listar índices autogenerados
SELECT name, tbl_name FROM sqlite_master WHERE type = 'index';

/*
RESPUESTAS A2:
1. Estos índices no los creó un usuario mediante `CREATE INDEX`, sino que los genera SQLite automáticamente 
   para garantizar el cumplimiento de restricciones de unicidad y llaves primarias (`UNIQUE` / `PRIMARY KEY`).
2. `sqlite_autoindex_lecturas_1` fue creado implícitamente en el Ejercicio 6 mediante la declaración de 
   la restricción: `UNIQUE (sensor_id, fecha_hora)` dentro de la definición de la tabla `lecturas`.
3. Un `UNIQUE` requiere un índice porque para validar de manera eficiente en cada inserción/actualización que 
   un valor no esté duplicado, SQLite necesita buscarlo rápidamente mediante una estructura B-Tree (O(log N)) 
   en lugar de realizar un escaneo completo de la tabla (O(N)).
*/

/*
RESPUESTA A3:
`lecturas_historico` no aparece en esa lista de autogénesis porque su llave primaria fue declarada exactamente como 
`lectura_id INTEGER PRIMARY KEY`. En SQLite, esto convierte a la columna en un alias directo del `rowid` nativo de la 
tabla B-Tree principal (organizada por Clave). Por lo tanto, no crea una estructura B-Tree de índice secundaria separada.
*/


-- =====================================================================
-- PARTE B · MEDIR, INDEXAR, VOLVER A MEDIR
-- =====================================================================

-- B1. Consulta lenta
WITH RECURSIVE dia(n) AS (SELECT 0 UNION ALL SELECT n+1 FROM dia WHERE n < 29)
SELECT n + 1 AS dia_de_junio,
  (SELECT COUNT(*) FROM lecturas_historico l
    WHERE l.sensor_id = 1
      AND l.fecha_hora >= datetime('2026-06-01','+'||n||' days')
      AND l.fecha_hora <  datetime('2026-06-01','+'||(n+1)||' days')) AS n_lecturas
FROM dia;
/*
Métrica de tiempo: 
- Local (.timer on): ~0.184 segundos / Navegador: Se siente una leve pausa visual.
*/

-- B2. Diagnóstico del plan de ejecución con EXPLAIN
EXPLAIN QUERY PLAN
WITH RECURSIVE dia(n) AS (SELECT 0 UNION ALL SELECT n+1 FROM dia WHERE n < 29)
SELECT n + 1 AS dia_de_junio,
  (SELECT COUNT(*) FROM lecturas_historico l
    WHERE l.sensor_id = 1
      AND l.fecha_hora >= datetime('2026-06-01','+'||n||' days')
      AND l.fecha_hora <  datetime('2026-06-01','+'||(n+1)||' days')) AS n_lecturas
FROM dia;

/*
RESPUESTA B2:
- La palabra 'SCAN' indica que SQLite no posee un acceso directo indexado a las filas y debe recorrer la tabla completa 
  fila por fila (Full Table Scan).
- Dado que el CTE evalúa la subconsulta 30 veces (una por cada día) y en cada iteración recorre las 105.120 filas de la 
  tabla `lecturas_historico`, SQLite está procesando en total: 30 * 105.120 = 3.153.600 filas.
*/

-- B3. Creación del índice compuesto adecuado
DROP INDEX IF EXISTS ix_hist_sensor_fecha;
CREATE INDEX ix_hist_sensor_fecha ON lecturas_historico (sensor_id, fecha_hora);

-- B4. Medición post-índice y verificación de plan
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
RESPUESTA B4:
Las 30 filas de salida y el conteo de 48 no cambiaron en absoluto. Un índice no altera el resultado final de 
los datos; únicamente transforma la estrategia interna de búsqueda para obtener la información de forma más rápida.
*/


-- =====================================================================
-- PARTE C · LA COSTUMBRE DE TRES CLASES
-- =====================================================================

-- C1. Consulta aplicando la función DATE() en la cláusula WHERE
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
RESPUESTA C2:
1. El índice solo utilizó la primera columna del prefijo: (sensor_id=?). Ignoró por completo `fecha_hora` en la búsqueda del rango.
2. Está evaluando la función sobre TODAS las 17.520 filas pertenecientes al sensor 1 en la tabla, en lugar de reducir el 
   trabajo a las 1.440 filas correspondientes al mes de junio.
*/

/*
RESPUESTA C3:
Un índice almacena la clave `fecha_hora` ordenada textualmente en el árbol B-Tree. Al envolver el campo en una función 
como `DATE(fecha_hora)`, el valor evaluado se transforma dinámicamente y la estructura ordenada ya no coincide directamente con la búsqueda. 
Análogamente, en el índice alfabético de un libro, si te piden palabras donde la "tercera letra es una X", tener las palabras 
ordenadas por su primera letra no te sirve de nada: debes leer absolutamente todo el índice para encontrar las coincidencias.
*/

-- C4. Reescritura óptima mediante un rango nativo
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
RESPUESTA C5:
Si se consulta `fecha_hora <= '2026-06-30'`, el motor compara la cadena exacta `'2026-06-30'` (que equivale implícitamente a 
`'2026-06-30 00:00:00'`). Esto descartaría todas las lecturas ocurridas durante el resto del día 30 de junio 
(por ejemplo: `'2026-06-30 00:30:00'`, `'2026-06-30 12:00:00'`, etc.).
*/

/*
RESPUESTA C6:
A pequeña escala (un año), la diferencia en milisegundos es casi imperceptible en el reloj. 
Sin embargo, cuando la base crezca a 10 años de historial, la consulta ineficiente pasará de examinar 17.520 filas a 175.200 
filas por sensor, degradando el desempeño del sistema linealmente a medida que los datos aumentan.
*/

-- C7. Consulta de entregas anteriores corregida:
-- Consulta previa (Clase 6/7 con antipatrón):
-- SELECT * FROM lecturas WHERE DATE(fecha_hora) = '2026-04-10';
--
-- Reescritura óptima de hoy:
SELECT * 
FROM lecturas 
WHERE fecha_hora >= '2026-04-10 00:00:00' 
  AND fecha_hora <  '2026-04-11 00:00:00';


-- =====================================================================
-- PARTE D · CUÁNDO EL ÍNDICE NO ALCANZA
-- =====================================================================

-- D1. Verificación del prefijo izquierdo
EXPLAIN QUERY PLAN
SELECT COUNT(*) FROM lecturas_historico
WHERE fecha_hora >= '2026-06-01' AND fecha_hora < '2026-07-01';

/*
RESPUESTA D1:
1. `ix_hist_sensor_fecha` se ordenó primero por `sensor_id` y luego por `fecha_hora`. Al omitir `sensor_id` en el `WHERE`, 
   se rompe la regla del prefijo izquierdo, por lo que SQLite no puede saltar directo en el árbol (no puede hacer SEARCH).
2. `USING COVERING INDEX` significa que, aunque debe recorrer todas las entradas del índice (SCAN), no necesita leer la 
   tabla principal en disco, ya que la columna `fecha_hora` solicitada ya existe dentro del archivo del índice secundario.
*/

-- D2. Creación del índice individual por fecha
DROP INDEX IF EXISTS ix_hist_fecha;
CREATE INDEX ix_hist_fecha ON lecturas_historico (fecha_hora);

EXPLAIN QUERY PLAN
SELECT COUNT(*) FROM lecturas_historico
WHERE fecha_hora >= '2026-06-01' AND fecha_hora < '2026-07-01';

/*
RESPUESTA D2:
Tener dos índices en una misma tabla no es malo en sí mismo; permite optimizar patrones de consulta distintos. 
Comienza a ser perjudicial cuando la cantidad de índices es excesiva, pues incrementa el uso de almacenamiento y 
degrada considerablemente la velocidad de las operaciones de escritura (`INSERT`, `UPDATE`, `DELETE`).
*/

-- D3. Demostración de ORDER BY optimizado
-- Paso 1: Con ambos índices creados
EXPLAIN QUERY PLAN
SELECT fecha_hora, valor FROM lecturas_historico
WHERE sensor_id = 1 ORDER BY fecha_hora LIMIT 10;

-- Paso 2: Eliminando índices
DROP INDEX IF EXISTS ix_hist_sensor_fecha;
DROP INDEX IF EXISTS ix_hist_fecha;

EXPLAIN QUERY PLAN
SELECT fecha_hora, valor FROM lecturas_historico
WHERE sensor_id = 1 ORDER BY fecha_hora LIMIT 10;

/*
RESPUESTA D3 (Paso 2):
SQLite está realizando una ordenación explícita en memoria/disco creando una tabla temporal B-Tree (`USE TEMP B-TREE`). 
Está procesando las 17.520 filas del sensor 1 para ordenarlas en su totalidad, solo para finalmente descartar la inmensa 
mayoría y entregar 10.
*/

-- Paso 3: Recreando únicamente el índice por fecha
CREATE INDEX ix_hist_fecha ON lecturas_historico (fecha_hora);

EXPLAIN QUERY PLAN
SELECT fecha_hora, valor FROM lecturas_historico
WHERE sensor_id = 1 ORDER BY fecha_hora LIMIT 10;

/*
RESPUESTA D3 (Paso 3):
SQLite evita el paso de ordenación (`USE TEMP B-TREE`) porque recorre las filas a través del índice `ix_hist_fecha`, 
el cual ya se encuentra físicamente ordenado por el campo `fecha_hora`.
*/

-- Paso 4: Recreando el índice compuesto para restaurar el estado
CREATE INDEX ix_hist_sensor_fecha ON lecturas_historico (sensor_id, fecha_hora);


-- D4. Evaluación del SEARCH de baja selectividad
DROP INDEX IF EXISTS ix_hist_valor;
CREATE INDEX ix_hist_valor ON lecturas_historico (valor);

EXPLAIN QUERY PLAN SELECT COUNT(*) FROM lecturas_historico WHERE valor > 28;
SELECT COUNT(*) FROM lecturas_historico WHERE valor > 28;

/*
RESPUESTA D4:
1. No está óptimamente resuelta. A pesar de que el plan reporte `SEARCH`, la consulta devuelve más del 50% del total de filas.
2. Tuvo que recorrer individualmente 59.495 entradas en la estructura del índice secundario.
3. No alcanza con que el plan diga `SEARCH`. Es indispensable verificar la selectividad del filtro y la cantidad total de filas recorridas.
*/

-- D5. Limpieza del índice no selectivo
DROP INDEX IF EXISTS ix_hist_valor;
/*
RESPUESTA D5:
Se elimina el índice `ix_hist_valor` debido a su baja selectividad, pues el costo de mantenerlo en escrituras 
supera con creces el beneficio nulo obtenido en las lecturas.
*/


-- =====================================================================
-- PARTE E · LO QUE CUESTA, Y CIERRE
-- =====================================================================

/*
RESPUESTA E1:
Las tres monedas son: Espacio en disco, Memoria RAM (caché) y Tiempo de Escritura (`INSERT`/`UPDATE`/`DELETE`).
En este escenario de sensores con inserciones continuas, la más cara es el tiempo de escritura, ya que cada nueva 
lectura exige actualizar tanto la tabla base como cada uno de los índices asociados en tiempo real.
*/

/*
RESPUESTA E2:
El trabajo computacional pesado de estructurar y acelerar la búsqueda de los datos lo realiza exclusivamente el índice; 
la vista solo actúa como un alias sintáctico reutilizable de la consulta.
*/

/*
RESPUESTA E3:
1. ¿Cuál es el volumen total de filas que involucra la consulta y cuántas estimo que debería retornar?
2. ¿El plan de ejecución actual (`EXPLAIN QUERY PLAN`) está realizando un `SCAN` evitable o un `SEARCH` ineficiente debido a funciones en el `WHERE`?
3. ¿Cómo están estructurados los filtros y agregaciones en la consulta, de modo que me permitan diseñar un índice que cumpla con la regla del prefijo izquierdo o un índice de cobertura?
*/


-- =====================================================================
-- EXTRA (Puntos adicionales)
-- =====================================================================

-- Consulta lenta detectada en la tabla `labores` relacionando insumos:
EXPLAIN QUERY PLAN
SELECT l.labor_id, l.tipo_labor, li.cantidad
FROM labores l
JOIN labor_insumo li ON li.labor_id = l.labor_id
WHERE li.insumo_id = 1;

-- Creación del índice para acelerar la búsqueda de insumos:
DROP INDEX IF EXISTS ix_labor_insumo_id;
CREATE INDEX ix_labor_insumo_id ON labor_insumo (insumo_id);

-- Plan optimizado con SEARCH:
EXPLAIN QUERY PLAN
SELECT l.labor_id, l.tipo_labor, li.cantidad
FROM labores l
JOIN labor_insumo li ON li.labor_id = l.labor_id
WHERE li.insumo_id = 1;