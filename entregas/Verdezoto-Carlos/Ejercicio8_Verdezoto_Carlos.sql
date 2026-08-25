-- =====================================================================
-- CURSO DE SQL | AgroDB | Ejercicio práctico 8
-- Alumno:
-- Fecha:
--
-- Este archivo se ejecuta DESPUÉS de Agronomia_clases2.sql,
-- en la MISMA sesión de SQLite.
-- =====================================================================

PRAGMA foreign_keys = ON;

-- =====================================================================
-- PARTE A - LA CONSULTA QUE SE QUEDA
-- =====================================================================

-- A1. Cada lote con su finca, código, hectáreas y tipo de suelo.
DROP VIEW IF EXISTS v_lote_finca;

CREATE VIEW v_lote_finca AS
SELECT f.nombre AS finca,
       l.codigo AS lote,
       l.hectareas,
       l.tipo_suelo
FROM lotes AS l
JOIN fincas AS f ON f.finca_id = l.finca_id
WHERE l.lote_id IS NOT NULL;

-- Control A1: deben salir 8 filas.
SELECT COUNT(*) AS filas
FROM v_lote_finca;

-- A2. Lotes de Hacienda Santa Rosa, de mayor a menor hectáreas.
SELECT finca, lote, hectareas, tipo_suelo
FROM v_lote_finca
WHERE finca = 'Hacienda Santa Rosa'
ORDER BY hectareas DESC;

-- A3.
-- Los datos no están guardados dentro de la vista: están en las tablas
-- fincas y lotes. La vista guarda la definición del SELECT.
-- Si se ejecuta UPDATE lotes SET hectareas = 40 WHERE lote_id = 2,
-- v_lote_finca devolverá 40 para L-02, porque SQLite vuelve a ejecutar
-- la consulta de la vista sobre los datos actuales cada vez que se consulta.


-- =====================================================================
-- PARTE B - EL TABLERO DE PRODUCCIÓN
-- =====================================================================

-- B1. Producción por lote.
DROP VIEW IF EXISTS v_produccion_lote;

CREATE VIEW v_produccion_lote AS
SELECT f.nombre AS finca,
       l.codigo AS lote,
       l.hectareas,
       COUNT(c.cosecha_id) AS n_cosechas,
       SUM(c.kg) AS kg_total,
       ROUND(SUM(c.kg) * 1.0 / l.hectareas, 2) AS kg_ha
FROM lotes AS l
JOIN fincas AS f ON f.finca_id = l.finca_id
JOIN siembras AS s ON s.lote_id = l.lote_id
JOIN cosechas AS c ON c.siembra_id = s.siembra_id
WHERE c.cosecha_id IS NOT NULL
GROUP BY l.lote_id, f.nombre, l.codigo, l.hectareas;

-- Control B1: deben salir 6 filas.
SELECT COUNT(*) AS filas
FROM v_produccion_lote;

SELECT finca, lote, hectareas, n_cosechas, kg_total, kg_ha
FROM v_produccion_lote
ORDER BY finca, lote;

-- B2. Producción por finca consultando la vista anterior.
DROP VIEW IF EXISTS v_produccion_finca;

CREATE VIEW v_produccion_finca AS
SELECT finca,
       COUNT(*) AS lotes,
       SUM(kg_total) AS kg,
       ROUND(SUM(kg_total) * 1.0 / SUM(hectareas), 2) AS kg_ha
FROM v_produccion_lote
WHERE kg_total IS NOT NULL
GROUP BY finca;

-- Control B2: deben salir 3 filas.
SELECT COUNT(*) AS filas
FROM v_produccion_finca;

SELECT finca, lotes, kg, kg_ha
FROM v_produccion_finca
ORDER BY finca;

-- B2. Respuesta:
-- En B2 escribí 0 JOIN. La consulta usa solamente v_produccion_lote.
-- En realidad, la vista v_produccion_lote está construida sobre
-- 4 tablas: lotes, fincas, siembras y cosechas.


-- B3. La vista sigue a los datos.
SELECT kg_total, n_cosechas, kg_ha
FROM v_produccion_lote
WHERE finca LIKE 'Hacienda%' AND lote = 'L-01';

INSERT INTO cosechas (siembra_id, fecha, kg, calidad, destino)
VALUES (1, '2026-05-02', 500, 'primera', 'mercado local');

SELECT kg_total, n_cosechas, kg_ha
FROM v_produccion_lote
WHERE finca LIKE 'Hacienda%' AND lote = 'L-01';

DELETE FROM cosechas
WHERE fecha = '2026-05-02';

-- B3. Respuesta:
-- Antes: 7300 / 2 / 256.14
-- Después: 7800 / 3 / 273.68
-- Al borrar: 7300 / 2 / 256.14
-- La pregunta se responde porque nadie modificó la vista: se modificó
-- la tabla cosechas y la vista recalculó sus resultados al consultarse.


-- B4. Trampa del IF NOT EXISTS.
CREATE VIEW IF NOT EXISTS v_produccion_lote AS
SELECT 1 AS chiste;

SELECT *
FROM v_produccion_lote;

-- B4. Respuesta:
-- SQLite no dio error y no reemplazó la vista existente; ignoró el
-- CREATE porque v_produccion_lote ya existe.
-- Esto es más peligroso que un error porque parece que la nueva vista
-- se creó, pero en realidad se continúa usando silenciosamente la vieja.


-- =====================================================================
-- PARTE C - AUDITORÍA DEL TABLERO PUBLICADO
-- =====================================================================

-- C1. Conteo de v_temp_diaria: deben salir 35.
SELECT COUNT(*) AS filas
FROM v_temp_diaria;

-- Hipótesis inicial:
-- Las cinco filas adicionales probablemente provienen de otro sensor
-- de temperatura que tiene lecturas fuera de abril, concretamente
-- lecturas antiguas de febrero.


-- C2. Definición de las vistas publicadas.
SELECT name, sql
FROM sqlite_master
WHERE type = 'view'
  AND name IN ('v_temp_diaria', 'v_alertas_sensores');

-- C2.1. La vista v_temp_diaria filtra únicamente s.tipo = 'temperatura'.
-- No filtra s.activo = 1 ni limita las lecturas al mes de abril.

-- C2.2. Sensores de temperatura, estado y fechas de lectura.
SELECT s.sensor_id,
       s.tipo,
       s.activo,
       MIN(DATE(l.fecha_hora)) AS primera_lectura,
       MAX(DATE(l.fecha_hora)) AS ultima_lectura,
       COUNT(l.lectura_id) AS n_lecturas
FROM sensores AS s
LEFT JOIN lecturas AS l ON l.sensor_id = s.sensor_id
WHERE s.tipo = 'temperatura'
GROUP BY s.sensor_id, s.tipo, s.activo
ORDER BY s.sensor_id;

-- Resultado esperado:
-- sensor 1 | temperatura | activo 1 | 2026-04-01 | 2026-04-30 | 237
-- sensor 3 | temperatura | activo 0 | 2026-02-04 | 2026-02-08 | 40
-- sensor 5 | temperatura | activo 0 | NULL       | NULL       | 0
-- Hay 3 sensores de tipo temperatura.

-- C2.3. Las cinco fechas adicionales salen del sensor 3, que está
-- inactivo pero conserva lecturas del 4 al 8 de febrero de 2026.


-- C3. Ranking de días más calurosos usando la vista tal como está.
SELECT dia,
       temp_promedio,
       RANK() OVER (ORDER BY temp_promedio DESC) AS puesto
FROM v_temp_diaria
ORDER BY puesto, dia;

-- C3. Respuesta:
-- De los diez días empatados en 25.63, cinco pertenecen al sensor 3,
-- que está dado de baja. Por tanto, un tablero que los presenta como
-- días de temperatura de abril está informando de forma engañosa:
-- mezcla datos de febrero de un sensor inactivo con los datos de abril.


-- C4. El segundo problema de v_temp_diaria.
-- 1) No. Alguien que solo tiene esta vista no puede darse cuenta,
-- porque la vista solo expone dia y temp_promedio y oculta el sensor
-- que produjo cada promedio.
-- 2) La columna sensor_id habría sido suficiente para detectar el origen.
-- 3) El error dura mientras la vista permanezca publicada y sea usada;
-- todas las consultas que dependan de ella heredan el mismo problema.


-- C5. Versión defendible: solo sensores activos, cantidad de lecturas
-- visible y sensor_id identificado.
DROP VIEW IF EXISTS v_temp_diaria_v2;

CREATE VIEW v_temp_diaria_v2 AS
SELECT DATE(l.fecha_hora) AS dia,
       s.sensor_id,
       ROUND(AVG(l.valor), 2) AS temp_promedio,
       COUNT(*) AS n_lecturas
FROM lecturas AS l
JOIN sensores AS s ON s.sensor_id = l.sensor_id
WHERE s.tipo = 'temperatura'
  AND s.activo = 1
  AND DATE(l.fecha_hora) BETWEEN '2026-04-01' AND '2026-04-30'
GROUP BY DATE(l.fecha_hora), s.sensor_id;

-- Control C5: deben salir 30 filas.
SELECT COUNT(*) AS filas
FROM v_temp_diaria_v2;

-- Primeros días del ranking. El 20 de abril debe aparecer con 27.33
-- y n_lecturas = 6.
SELECT dia, sensor_id, temp_promedio, n_lecturas,
       RANK() OVER (ORDER BY temp_promedio DESC) AS puesto
FROM v_temp_diaria_v2
ORDER BY puesto, dia;

-- C5. Respuesta:
-- No se arregló el ranking en sí; se arregló el problema de los datos
-- que entraban al ranking. Ahora solo se consideran sensores activos,
-- se restringe abril y se muestra el conteo y el sensor responsable.


-- C6. Reemplazar una vista publicada.
-- No se ejecuta DROP/CREATE sobre la vista vieja en este ejercicio,
-- porque se conserva la versión original para auditarla.
--
-- 1) Si el tablero espera dos columnas y mañana v_temp_diaria tiene
-- cuatro, las consultas que esperen exactamente dos columnas pueden
-- fallar o dejar de funcionar correctamente.
-- 2) Le diría al responsable que el cambio no es solo técnico: se
-- corrigió una fuente de datos inválida y por eso los promedios pueden
-- cambiar; el cambio debe quedar documentado y comunicado.
-- 3) Preferiría publicar v_temp_diaria_v2 al lado de la vieja, avisar
-- y migrar el tablero de forma controlada, en lugar de romper el
-- contrato de la vista que otros ya consumen.


-- C7. Auditoría de v_alertas_sensores.
SELECT COUNT(*) AS filas
FROM v_alertas_sensores;

SELECT tipo, COUNT(*) AS alertas
FROM v_alertas_sensores
GROUP BY tipo
ORDER BY tipo;

-- Comparación sin el filtro de sensores activos.
SELECT COUNT(*) AS filas_sin_filtro_activo
FROM lecturas AS l
JOIN sensores AS s ON s.sensor_id = l.sensor_id
WHERE (s.tipo = 'temperatura' AND l.valor > 28)
   OR (s.tipo = 'humedad'     AND l.valor < 60)
   OR (s.tipo = 'radiacion'   AND l.valor > 800);

-- C7. Respuesta:
-- La vista devuelve 93 filas: 42 de temperatura, 21 de humedad y
-- 30 de radiación. Sin activo = 1 serían 103.
-- Sí, está bien escrita: filtra explícitamente s.activo = 1 y además
-- conserva finca y lote. Auditar y encontrar que una vista está bien
-- escrita también es un resultado válido.


-- =====================================================================
-- PARTE D - LO QUE UNA VISTA NO PUEDE, Y LO QUE SÍ PUEDE ESCONDER
-- =====================================================================

-- D1. Intentos de escritura sobre una vista.
-- Los siguientes dos comandos producen:
-- ERROR: cannot modify v_produccion_lote because it is a view
-- ERROR: cannot modify v_produccion_lote because it is a view

-- INSERT INTO v_produccion_lote VALUES ('x','y',1,1,1,1);
-- UPDATE v_produccion_lote SET kg_total = 0;

-- Si SQLite dejara escribir 8000 en kg_total, tendría que traducir
-- ese cambio a operaciones coherentes sobre las tablas subyacentes,
-- especialmente sobre las filas de cosechas que forman el SUM.


-- D2. Intento de indexar una vista.
-- ERROR: views may not be indexed

-- CREATE INDEX ix_kgha ON v_produccion_lote(kg_ha);

-- D2. Respuesta:
-- No. Una vista no hace que la consulta sea más rápida por sí misma.
-- Cada SELECT sobre v_produccion_lote vuelve a ejecutar la consulta
-- que define la vista contra las tablas subyacentes.


-- D3. Vista que no valida referencias al crearla.
-- CREATE VIEW v_fantasma AS SELECT * FROM tabla_que_no_existe;
-- SELECT * FROM v_fantasma;

-- Resultado:
-- El CREATE funciona. El SELECT produce:
-- ERROR: no such table: main.tabla_que_no_existe
--
-- SQLite comprueba la referencia cuando necesita resolver/ejecutar
-- la vista, no necesariamente cuando la definición se registra.
-- En una base con muchas vistas encadenadas, renombrar una tabla puede
-- dejar vistas rotas que no fallan hasta que alguien las consulta.


-- D4. Fan-out heredado.
DROP VIEW IF EXISTS v_costo_mal;

CREATE VIEW v_costo_mal AS
SELECT si.siembra_id,
       SUM(la.costo_mano_obra) AS costo_mano_obra,
       SUM(li.cantidad * li.costo_unitario) AS costo_insumos
FROM siembras AS si
JOIN labores AS la ON la.siembra_id = si.siembra_id
LEFT JOIN labor_insumo AS li ON li.labor_id = la.labor_id
GROUP BY si.siembra_id;

SELECT *
FROM v_costo_mal
ORDER BY siembra_id;

-- D4.1. La siembra 1 da 455 en vez de 335 porque su labor 1 tiene dos
-- insumos. El JOIN genera dos filas para esa labor y SUM(costo_mano_obra)
-- suma dos veces los 120 de mano de obra: 90 + 120 + 120 = 455.
--
-- D4.2. Las siembras 9 y 10 desaparecen porque no tienen labores.
-- El JOIN que las elimina es el JOIN interno entre siembras y labores.
--
-- D4.3. Vista correcta: se agregan por separado la mano de obra y los
-- insumos antes de unirlos, evitando el fan-out.
DROP VIEW IF EXISTS v_costo_siembra;

CREATE VIEW v_costo_siembra AS
WITH mano_obra AS (
    SELECT siembra_id,
           SUM(costo_mano_obra) AS costo_mano_obra
    FROM labores
    GROUP BY siembra_id
),
insumos_siembra AS (
    SELECT la.siembra_id,
           SUM(li.cantidad * li.costo_unitario) AS costo_insumos
    FROM labores AS la
    JOIN labor_insumo AS li ON li.labor_id = la.labor_id
    GROUP BY la.siembra_id
)
SELECT si.siembra_id,
       f.nombre AS finca,
       l.codigo AS lote,
       ROUND(COALESCE(m.costo_mano_obra, 0), 2) AS costo_mano_obra,
       ROUND(COALESCE(i.costo_insumos, 0), 2) AS costo_insumos,
       ROUND(COALESCE(m.costo_mano_obra, 0)
           + COALESCE(i.costo_insumos, 0), 2) AS costo_total
FROM siembras AS si
JOIN lotes AS l ON l.lote_id = si.lote_id
JOIN fincas AS f ON f.finca_id = l.finca_id
LEFT JOIN mano_obra AS m ON m.siembra_id = si.siembra_id
LEFT JOIN insumos_siembra AS i ON i.siembra_id = si.siembra_id
WHERE si.siembra_id IS NOT NULL;

-- Control D4: deben salir 10 filas.
SELECT COUNT(*) AS filas
FROM v_costo_siembra;

SELECT siembra_id, finca, lote, costo_mano_obra, costo_insumos, costo_total
FROM v_costo_siembra
ORDER BY siembra_id;

-- La siembra 1 debe ser: 335 | 295.80 | 630.80.
SELECT ROUND(SUM(costo_total), 2) AS total_general
FROM v_costo_siembra;
-- Esperado: 3562.30


-- =====================================================================
-- PARTE E - CIERRE
-- =====================================================================

-- 1) Una vista queda almacenada en la base y puede ser reutilizada
-- hasta que se modifique o elimine; una CTE solo existe durante la
-- ejecución de una sentencia.
--
-- 2) Es más difícil detectar un error en una vista porque el usuario
-- normalmente consulta el resultado sin leer la definición y puede
-- desconocer qué filtros, JOIN, agrupaciones o columnas ocultas heredó.
-- Además, el mismo error se repite en todas las consultas que consumen
-- la vista.
--
-- 3) Mis tres reglas:
--    a) El nombre debe describir exactamente qué contiene la vista.
--    b) Todo filtro importante debe aparecer de forma explícita y
--       verificable en la definición.
--    c) Todo promedio o agregado que necesite contexto debe mostrar
--       su COUNT(*) y las dimensiones necesarias para auditarlo.


-- =====================================================================
-- FIN DEL EJERCICIO 8
-- =====================================================================
