-- =====================================================================
-- CURSO DE SQL  |  AgroDB  |  Ejercicio 8
-- Alumno: Byron Yaguar
-- Fecha: 2026-08-18
--
-- Este archivo se ejecuta DESPUES de datos/agrodb_clase8.sql,
-- en la MISMA sesion de sqliteonline.
-- =====================================================================
PRAGMA foreign_keys = ON;

-- =====================================================================
-- PARTE A - LA CONSULTA QUE SE QUEDA
-- =====================================================================

-- A1. Crear v_lote_finca
DROP VIEW IF EXISTS v_lote_finca;
CREATE VIEW v_lote_finca AS
SELECT f.nombre AS finca,
       lo.codigo AS lote,
       lo.hectareas,
       lo.tipo_suelo
FROM lotes lo
JOIN fincas f ON lo.finca_id = f.finca_id;

-- Verificar: deberían ser 8 filas
SELECT COUNT(*) FROM v_lote_finca;

-- A2. Usar la vista: lotes de Hacienda Santa Rosa ordenados por hectáreas
SELECT finca, lote, hectareas
FROM v_lote_finca
WHERE finca = 'Hacienda Santa Rosa'
ORDER BY hectareas DESC;

-- A2 ESPERADO: 3 filas - L-02 (31), L-01 (28.5), L-03 (19.25)

-- A3. Dónde están guardados los datos:
-- Los datos NO están en la vista. La vista guarda solo la PREGUNTA (el SELECT).
-- Los datos están en las tablas originales: fincas y lotes.
-- Si mañana alguien hace UPDATE lotes SET hectareas = 40 WHERE lote_id = 2,
-- la vista devolvería 40 porque corre el SELECT contra las tablas actualizadas.
-- Una vista no es un snapshot: es una pregunta que se re-ejecuta cada vez.

-- =====================================================================
-- PARTE B - EL TABLERO DE PRODUCCION
-- =====================================================================

-- B1. Crear v_produccion_lote
DROP VIEW IF EXISTS v_produccion_lote;
CREATE VIEW v_produccion_lote AS
SELECT f.nombre AS finca,
       lo.codigo AS lote,
       lo.hectareas,
       COUNT(c.cosecha_id) AS n_cosechas,
       COALESCE(SUM(c.kg), 0) AS kg_total,
       ROUND(1.0 * COALESCE(SUM(c.kg), 0) / lo.hectareas, 2) AS kg_ha
FROM lotes lo
JOIN fincas f ON lo.finca_id = f.finca_id
LEFT JOIN siembras si ON lo.lote_id = si.lote_id
LEFT JOIN cosechas c ON si.siembra_id = c.siembra_id
GROUP BY lo.lote_id, f.nombre, lo.codigo, lo.hectareas
ORDER BY f.nombre, lo.codigo;

-- B1 ESPERADO: 6 filas
SELECT * FROM v_produccion_lote;

-- B2. Crear v_produccion_finca consultando v_produccion_lote
DROP VIEW IF EXISTS v_produccion_finca;
CREATE VIEW v_produccion_finca AS
SELECT finca,
       COUNT(*) AS lotes,
       SUM(kg_total) AS kg,
       ROUND(1.0 * SUM(kg_total) / SUM(hectareas), 2) AS kg_ha
FROM v_produccion_lote
WHERE n_cosechas > 0
GROUP BY finca;

-- B2 ESPERADO: 3 filas
SELECT * FROM v_produccion_finca;

-- B2 COMENTARIO:
-- En B2 NO escribí ningún JOIN explícito. Cero JOINs.
-- Pero en realidad está corriendo sobre: fincas, lotes, siembras, cosechas.
-- (4 tablas). La composición de vistas oculta la complejidad real.

-- B3. La vista sigue a los datos (antes de INSERT)
SELECT kg_total, n_cosechas, kg_ha FROM v_produccion_lote
 WHERE finca LIKE 'Hacienda%' AND lote = 'L-01';

-- B3 ESPERADO ANTES: 7300 | 2 | 256.14

-- Insertar una cosecha nueva
INSERT INTO cosechas (siembra_id, fecha, kg, calidad, destino)
VALUES (1, '2026-05-02', 500, 'primera', 'mercado local');

-- Verificar (después del INSERT)
SELECT kg_total, n_cosechas, kg_ha FROM v_produccion_lote
 WHERE finca LIKE 'Hacienda%' AND lote = 'L-01';

-- B3 ESPERADO DESPUES: 7800 | 3 | 273.68

-- Borrar la cosecha
DELETE FROM cosechas WHERE fecha = '2026-05-02';

-- Verificar (después del DELETE)
SELECT kg_total, n_cosechas, kg_ha FROM v_produccion_lote
 WHERE finca LIKE 'Hacienda%' AND lote = 'L-01';

-- B3 ESPERADO FINAL: 7300 | 2 | 256.14

-- B3 COMENTARIO:
-- Nadie ejecutó UPDATE sobre la vista. Los datos cambiaron porque
-- se insertó una fila en cosechas. La vista pregunta "¿cuántos kg
-- tiene cada lote?", y esa pregunta se re-ejecuta cada vez.
-- La respuesta cambió porque la realidad (los datos subyacentes) cambió.

-- B4. La trampa del IF NOT EXISTS
-- Nota: en la vida real, esto iba a reemplazar la vista con versión mala,
-- pero como ya creamos v_produccion_lote arriba, SQLite NO hará nada.
-- El IF NOT EXISTS evita el error pero también evita la actualización.
CREATE VIEW IF NOT EXISTS v_produccion_lote AS SELECT 1 AS chiste;
SELECT * FROM v_produccion_lote;

-- B4 COMENTARIO:
-- SQLite NO reemplazo la vista porque ya existe. El SELECT devolvió
-- las 6 filas correctas de la vista original, no el "1 AS chiste".
-- Esto es más peligroso que un error porque: 1) no hay error que alerte
-- al desarrollador, 2) alguien que espera que IF NOT EXISTS haya ejecutado
-- el CREATE está viviendo una mentira silenciosa, 3) en bash o Python,
-- esto es invisible y mata pipelines.

-- =====================================================================
-- PARTE C - EL TABLERO QUE YA ESTABA PUBLICADO
-- =====================================================================

-- C1. Contar filas de v_temp_diaria
SELECT COUNT(*) AS filas_v_temp_diaria FROM v_temp_diaria;

-- C1 ESPERADO: 35

-- C1 HIPOTESIS:
-- Abril tiene 30 días. Los 5 de más probablemente vienen de otro mes
-- (tal vez febrero, donde hay un sensor de temperatura que está dado de baja
-- pero tiene datos). O la vista incluye algún sensor inactivo que debería
-- haber filtrado.

-- C2. Abrir la vista: ver su definición
SELECT sql FROM sqlite_master WHERE type = 'view' AND name = 'v_temp_diaria';

-- C2 RESPUESTA:
-- 1) El WHERE filtra s.tipo = 'temperatura'. NO filtra por fecha ni por
--    sensor activo. Incluye TODOS los sensores de temperatura, incluso
--    los que están dados de baja (activo = 0).
--
-- 2) Sensores de temperatura:
SELECT sensor_id, tipo, activo,
       MIN(fecha_hora) AS primera, MAX(fecha_hora) AS ultima
FROM lecturas l
JOIN sensores s ON s.sensor_id = l.sensor_id
WHERE s.tipo = 'temperatura'
GROUP BY s.sensor_id;

-- Resultado: 3 sensores
-- - sensor 1 (activo): abril
-- - sensor 3 (inactivo): febrero
--
-- 3) Los 5 días de más son de febrero. El sensor 3 está dado de baja
--    pero fue medido en febrero (40 filas, aprox 5 días de datos).
--    La vista los incluye sin filtro.

-- C3. Ranking de días más calurosos USANDO LA VISTA TAL COMO ESTA
SELECT dia, temp_promedio,
       RANK() OVER (ORDER BY temp_promedio DESC) AS puesto
FROM v_temp_diaria
ORDER BY temp_promedio DESC;

-- C3 ESPERADO: 35 filas. Primer puesto: 2026-04-20 (27.33).
-- Segundo puesto: empate de 10 días en 25.63.

-- C3 COMENTARIO:
-- De esos 10 empatados en 25.63, algunos son de febrero (sensor 3 dado de baja).
-- Un tablero que muestra esa información está mintiendo: está diciendo
-- "estos son los 10 días más calurosos" pero algunos vienen de un sensor
-- que ya no existe.

-- C4. El segundo problema (ausencia de COUNT)
-- 1) ¿Puede alguien que solo tiene esta vista darse cuenta por qué el 20
--    está primero? NO. La vista solo devuelve dia y temp_promedio.
--    No muestra cuántas lecturas se usaron para calcular cada promedio.
--    El 20 de abril tiene 6 lecturas (falta de la limpieza), pero eso
--    es invisible en la vista.
--
-- 2) La columna que falta: COUNT (contar las lecturas que participaron).
--
-- 3) Escrito en una vista: dura PARA SIEMPRE. Cada mañana el tablero
--    consulta esta vista y no se entera del problema. Si en 6 meses
--    alguien audita, encontrará dos errores en una sola vista (sensor
--    de baja + falta COUNT).

-- C5. Crear v_temp_diaria_v2, la versión defendible
DROP VIEW IF EXISTS v_temp_diaria_v2;
CREATE VIEW v_temp_diaria_v2 AS
SELECT DATE(l.fecha_hora) AS dia,
       COUNT(*) AS n_lecturas,
       l.sensor_id,
       ROUND(AVG(l.valor), 2) AS temp_promedio
FROM lecturas l
JOIN sensores s ON s.sensor_id = l.sensor_id
WHERE s.tipo = 'temperatura' AND s.activo = 1
GROUP BY DATE(l.fecha_hora), l.sensor_id;

-- Verificar
SELECT * FROM v_temp_diaria_v2 ORDER BY temp_promedio DESC LIMIT 7;

-- C5 ESPERADO: 30 filas. El 20 de abril sigue primero con 27.33,
-- pero ahora al lado dice n_lecturas = 6.

-- C5 COMENTARIO:
-- El 20 de abril sigue primero. No arreglé el ranking: el 20 de abril
-- genuinamente tiene el promedio más alto. Lo que arreglé fue OTRA COSA:
-- ahora es auditable. Alguien ve el 6 y pregunta "¿por qué 6 y no 8?".
-- Eso lleva a descubrir la limpieza de ayer y entender el ranking.

-- C6. Qué pasa cuando reemplazás una vista que otros usan
-- 1) El tablero espera SELECT dia, temp_promedio (2 columnas).
--    v_temp_diaria_v2 tiene 4 columnas (dia, n_lecturas, sensor_id, temp_promedio).
--    A las 7am, el tablero rompe: "unknown column n_lecturas" o simplemente
--    muestra columnas inesperadas que su layout no sabe qué hacer.
--
-- 2) Los promedios bajan porque ahora solo incluyen abril y sensores activos.
--    Alguien reporta que los números cambiaron. ¿Le digo que los viejos eran
--    mentira? ¿Que estaban contando un sensor que desactivamos?
--    Eso requiere una conversación con el jefe de operaciones.
--
-- 3) Habría publicado v_temp_diaria_v2 como NUEVA vista y avisado:
--    "v_temp_diaria está discontinuada. Usen v_temp_diaria_v2.
--    Diferencia: ahora solo sensores activos y con conteo de lecturas."
--    Así la gente elige cuándo cambiar, y tiene una transición clara.

-- C7. Auditar v_alertas_sensores
SELECT COUNT(*) FROM v_alertas_sensores;

-- C7 ESPERADO: 93 filas (42 temp, 21 humedad, 30 radiacion)

-- Verificar sin el filtro de activo
SELECT COUNT(*) FROM lecturas l
JOIN sensores s ON s.sensor_id = l.sensor_id
WHERE (s.tipo='temperatura' AND l.valor > 28)
   OR (s.tipo='humedad'     AND l.valor < 60)
   OR (s.tipo='radiacion'   AND l.valor > 800);

-- C7 ESPERADO SIN FILTRO: 103

-- C7 COMENTARIO:
-- v_alertas_sensores SÍ filtra activo = 1, y da 93 (menos que 103).
-- Esta vista ESTÁ BIEN ESCRITA. No incluye sensores dados de baja.
-- Es la lección: auditar una vista y encontrar que está correcta
-- también es un resultado válido y hay que reportarlo así.

-- =====================================================================
-- PARTE D - LO QUE UNA VISTA NO PUEDE, Y LO QUE SI PUEDE ESCONDER
-- =====================================================================

-- D1. Intentar INSERT en una vista
-- INSERT INTO v_produccion_lote VALUES ('x','y',1,1,1,1);
-- Error esperado: "cannot modify v_produccion_lote because it does not have
-- an underlying base table" (o similar, depende de SQLite).

-- D1 COMENTARIO:
-- kg_total es un SUM que agrega varias cosechas. Si SQLite permitiera
-- INSERT 8000 en kg_total, tendría que: crear una siembra nueva? insertar
-- cosechas hasta que sumen 8000? No hay forma de "invertir" un SUM.
-- Por eso SQLite rechaza escritura en vistas complejas.

-- D2. Intentar indexar una vista
-- CREATE INDEX ix_kgha ON v_produccion_lote(kg_ha);
-- Error esperado: "cannot create index on view" (o similar).

-- D2 COMENTARIO:
-- NO, una vista no hace que la consulta sea más rápida. De hecho es lo
-- contrario: cada SELECT FROM v_produccion_lote re-ejecuta el SELECT
-- de adentro contra todas las tablas. No hay índice que ayude.
-- Lo que SQLite corre es: el SELECT interno contra fincas, lotes, siembras,
-- cosechas, agrupado y ordenado.

-- D3. Vista sobre tabla inexistente
-- CREATE VIEW v_fantasma AS SELECT * FROM tabla_que_no_existe;
-- ^ Esto FUNCIONA (no da error).
-- SELECT * FROM v_fantasma;
-- ^ Esto FALLA (da error).

-- D3 COMENTARIO:
-- SQLite revisa que la vista tenga sentido solo cuando la CONSULTAS,
-- no cuando la CREAS. Esto es peligroso en una base con 40 vistas
-- encadenadas: si alguien renombra una tabla, todas las vistas que la usan
-- quedan rotas. Pero no lo ves hasta que intentes consultarlas.

-- D4. El error que se hereda: fan-out en v_costo_mal
DROP VIEW IF EXISTS v_costo_mal;
CREATE VIEW v_costo_mal AS
SELECT si.siembra_id,
       SUM(la.costo_mano_obra)              AS costo_mano_obra,
       SUM(li.cantidad * li.costo_unitario) AS costo_insumos
FROM siembras si
JOIN labores la      ON la.siembra_id = si.siembra_id
LEFT JOIN labor_insumo li ON li.labor_id = la.labor_id
GROUP BY si.siembra_id;

-- Verificar
SELECT * FROM v_costo_mal;

-- D4 COMENTARIO PARTE 1:
-- 455 en lugar de 335 porque:
-- La siembra 1 tiene labor 1, 2, 13.
-- Labor 1 tiene 2 insumos (urea y muriato).
-- El JOIN a labor_insumo duplica la fila de labor 1.
-- La sumatoria de costo_mano_obra suma 120 dos veces = 240 en lugar de 120.
-- Similar con las otras labores. Total inflado.

-- D4 COMENTARIO PARTE 2:
-- Siembras 3 y 8 desaparecieron. LEFT JOIN la comió porque:
-- Siembra 3 no tiene labores. JOIN labores la elimina.
-- Siembra 8 tiene labor 12 que está en labores, pero labor 12 no tiene
-- insumos. Cuando haces GROUP BY sin las claves completas... (en realidad
-- ambas desaparecen por LEFT JOIN a una tabla sin coincidencias).

-- D4. Crear v_costo_siembra, la buena: 10 siembras
DROP VIEW IF EXISTS v_costo_siembra;
CREATE VIEW v_costo_siembra AS
WITH costo_mano_por_siembra AS (
  SELECT si.siembra_id,
         SUM(la.costo_mano_obra) AS costo_mano_obra
  FROM siembras si
  JOIN labores la ON la.siembra_id = si.siembra_id
  GROUP BY si.siembra_id
),
costo_insumos_por_siembra AS (
  SELECT si.siembra_id,
         COALESCE(SUM(li.cantidad * li.costo_unitario), 0) AS costo_insumos
  FROM siembras si
  LEFT JOIN labores la ON la.siembra_id = si.siembra_id
  LEFT JOIN labor_insumo li ON li.labor_id = la.labor_id
  GROUP BY si.siembra_id
)
SELECT f.nombre AS finca,
       lo.codigo AS lote,
       s.siembra_id,
       COALESCE(cm.costo_mano_obra, 0) AS costo_mano_obra,
       COALESCE(ci.costo_insumos, 0) AS costo_insumos,
       ROUND(COALESCE(cm.costo_mano_obra, 0) + COALESCE(ci.costo_insumos, 0), 2) AS costo_total
FROM siembras s
LEFT JOIN costo_mano_por_siembra cm ON s.siembra_id = cm.siembra_id
LEFT JOIN costo_insumos_por_siembra ci ON s.siembra_id = ci.siembra_id
JOIN lotes lo ON s.lote_id = lo.lote_id
JOIN fincas f ON lo.finca_id = f.finca_id
ORDER BY s.siembra_id;

-- Verificar: 10 filas
SELECT COUNT(*) FROM v_costo_siembra;

-- Verificar: siembra 1 debe dar 335 | 295.80 | 630.80
SELECT finca, lote, costo_mano_obra, costo_insumos, costo_total
FROM v_costo_siembra
WHERE siembra_id = 1;

-- Verificar: suma total debe cerrar en 3562.30
SELECT ROUND(SUM(costo_total), 2) AS suma_total FROM v_costo_siembra;

-- D4 ESPERADO: 3562.30 (igual al ejercicio 5)

-- =====================================================================
-- PARTE E - CIERRE
-- =====================================================================

-- 1) Diferencia práctica entre vista y CTE:
-- Una CTE vive mientras se ejecuta esa consulta. Una vista vive en la base
-- de datos y se reutiliza en cualquier consulta que la llame, cualquier día.

-- 2) Por qué es difícil encontrar errores adentro de una vista:
-- Una vista no devuelve un error obvio. Devuelve números que parecen
-- razonables (35 en lugar de 30, 455 en lugar de 335). Nadie audita
-- una consulta que "funciona". El error está escondido adentro del
-- SELECT, no en la salida.

-- 3) Tres reglas para publicar una vista que otros van a usar:
--    a) El nombre tiene que decir exactamente qué contiene (ej: v_temp_diaria_sensores_activos_abril)
--    b) Todo promedio tiene que tener un COUNT() al lado (auditable)
--    c) Todo filtro tiene que estar explícito en el SELECT (no dar nada por sobreentendido)