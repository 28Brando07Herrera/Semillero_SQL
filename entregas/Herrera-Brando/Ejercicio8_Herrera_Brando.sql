-- =====================================================================
-- Ejercicio práctico 8 · El tablero que nadie auditó
-- Herrera, Brando
--
-- Este archivo se corre completo, de arriba a abajo, DESPUÉS de haber
-- ejecutado datos/agrodb_clase8.sql en la misma base.
-- Todas mis vistas llevan DROP VIEW IF EXISTS antes del CREATE VIEW
-- para que una segunda corrida no falle.
-- =====================================================================


-- =====================================================================
-- PARTE A · La consulta que se queda
-- =====================================================================

-- A1. v_lote_finca: cada lote con su finca, código, hectáreas y tipo de suelo
DROP VIEW IF EXISTS v_lote_finca;
CREATE VIEW v_lote_finca AS
SELECT f.nombre    AS finca,
       lo.codigo   AS lote,
       lo.hectareas,
       lo.tipo_suelo
FROM lotes lo
JOIN fincas f ON f.finca_id = lo.finca_id;

-- Esperado: 8 filas
SELECT COUNT(*) FROM v_lote_finca;

-- A2. Lotes de Hacienda Santa Rosa, por hectáreas descendente.
-- Esperado: L-02(31), L-01(28.5), L-03(19.25). Sin ningún JOIN acá:
-- el JOIN ya quedó guardado adentro de la vista.
SELECT lote, hectareas
FROM v_lote_finca
WHERE finca = 'Hacienda Santa Rosa'
ORDER BY hectareas DESC;

-- A3. ¿Dónde están guardados los datos que devuelve v_lote_finca?
-- No están guardados en ningún lado propio de la vista: la vista no
-- tiene filas, tiene un SELECT guardado con nombre. Los datos reales
-- siguen viviendo en las tablas lotes y fincas. Si mañana alguien hace
-- UPDATE lotes SET hectareas = 40 WHERE lote_id = 2, la vista devuelve
-- 40 la próxima vez que se consulte, porque cada SELECT * FROM
-- v_lote_finca vuelve a correr el JOIN contra las tablas tal como
-- están en ese momento. La vista no "recuerda" el valor viejo: no
-- tiene memoria propia, sólo tiene la pregunta.


-- =====================================================================
-- PARTE B · El tablero de producción
-- =====================================================================

-- B1. v_produccion_lote: finca, lote, hectáreas, n_cosechas, kg_total, kg_ha
DROP VIEW IF EXISTS v_produccion_lote;
CREATE VIEW v_produccion_lote AS
SELECT f.nombre                                   AS finca,
       lo.codigo                                  AS lote,
       lo.hectareas,
       COUNT(c.cosecha_id)                        AS n_cosechas,
       SUM(c.kg)                                  AS kg_total,
       ROUND(SUM(c.kg) * 1.0 / lo.hectareas, 2)    AS kg_ha
FROM lotes lo
JOIN fincas f    ON f.finca_id  = lo.finca_id
JOIN siembras si ON si.lote_id  = lo.lote_id
JOIN cosechas c  ON c.siembra_id = si.siembra_id
GROUP BY lo.lote_id;

-- Esperado: 6 filas, valores exactos de la tabla del enunciado
SELECT finca, lote, hectareas, n_cosechas, kg_total, kg_ha
FROM v_produccion_lote
ORDER BY finca, lote;

-- B2. v_produccion_finca, construida SOBRE v_produccion_lote (no sobre
-- las tablas). Con: finca, cuántos lotes, kilos totales y kg/ha de la finca.
DROP VIEW IF EXISTS v_produccion_finca;
CREATE VIEW v_produccion_finca AS
SELECT finca,
       COUNT(*)                                              AS lotes,
       SUM(kg_total)                                         AS kg,
       ROUND(SUM(kg_total) * 1.0 / SUM(hectareas), 2)         AS kg_ha
FROM v_produccion_lote
GROUP BY finca;

-- Esperado: 3 filas
SELECT finca, lotes, kg, kg_ha
FROM v_produccion_finca
ORDER BY finca;

-- ¿Cuántos JOIN escribí en B2? Ninguno. Cero. Pero la consulta corre
-- en realidad sobre CUATRO tablas (lotes, fincas, siembras, cosechas),
-- porque v_produccion_finca lee de v_produccion_lote, y esa a su vez
-- lee de las tablas de abajo. Escribir cero JOIN no significa que la
-- base haga menos trabajo: significa que ese trabajo ya está guardado
-- en otro lado y yo no tengo que volver a escribirlo.

-- B3. La vista sigue a los datos.
-- Antes del INSERT (esperado: 7300 / 2 / 256.14)
SELECT kg_total, n_cosechas, kg_ha FROM v_produccion_lote
 WHERE finca LIKE 'Hacienda%' AND lote = 'L-01';

INSERT INTO cosechas (siembra_id, fecha, kg, calidad, destino)
VALUES (1, '2026-05-02', 500, 'primera', 'mercado local');

-- Después del INSERT (esperado: 7800 / 3 / 273.68)
SELECT kg_total, n_cosechas, kg_ha FROM v_produccion_lote
 WHERE finca LIKE 'Hacienda%' AND lote = 'L-01';

DELETE FROM cosechas WHERE fecha = '2026-05-02';

-- Después del DELETE (esperado: vuelve a 7300 / 2 / 256.14)
SELECT kg_total, n_cosechas, kg_ha FROM v_produccion_lote
 WHERE finca LIKE 'Hacienda%' AND lote = 'L-01';

-- Nadie ejecutó un UPDATE sobre la vista, y aun así el número cambió.
-- Cambió porque la vista no guarda el resultado: guarda la PREGUNTA
-- ("suma los kg de cosechas de este lote"). El INSERT modificó la
-- tabla cosechas, que es donde vive el dato real. La próxima vez que
-- alguien pregunta v_produccion_lote, SQLite vuelve a correr esa
-- pregunta contra la tabla ya modificada. No hay nada mágico: es la
-- misma consulta, corriendo sobre datos distintos.

-- B4. La trampa del IF NOT EXISTS
CREATE VIEW IF NOT EXISTS v_produccion_lote AS SELECT 1 AS chiste;
SELECT * FROM v_produccion_lote;

-- No dio error. Y el SELECT siguió devolviendo la vista de producción
-- original (finca, lote, hectareas, n_cosechas, kg_total, kg_ha), NO
-- la vista "chiste" de una sola columna.
-- Qué hizo SQLite con mi CREATE: como ya existía una vista con ese
-- nombre, IF NOT EXISTS le dijo a SQLite "si ya está, no hagas nada",
-- y SQLite obedeció en silencio: no creó la vista nueva, no tocó la
-- vieja, y no me avisó de que mi intento fue ignorado.
-- Por qué es más peligroso que un error: un error se nota enseguida,
-- para la ejecución y me obliga a mirarlo. Este "éxito silencioso" no
-- para nada: si yo hubiera querido reemplazar v_produccion_lote por
-- una versión corregida y hubiera usado por error IF NOT EXISTS en vez
-- de DROP + CREATE, mi script terminaría sin errores y yo me iría
-- pensando que ya quedó arreglada, cuando en realidad la vista vieja
-- (con el error) sigue exactamente igual.


-- =====================================================================
-- PARTE C · El tablero que ya estaba publicado
-- =====================================================================

-- C1. Esperado: 35
SELECT COUNT(*) FROM v_temp_diaria;

-- Hipótesis antes de investigar: si abril tiene 30 días y salen 35,
-- sobran 5 días que no son de abril. Lo más probable es que la vista
-- esté mezclando lecturas de otro mes, o de un sensor que no debería
-- estar contando (por ejemplo uno dado de baja que igual tiene
-- lecturas viejas cargadas en la tabla).

-- C2. Definición real de la vista
SELECT sql FROM sqlite_master WHERE type = 'view' AND name = 'v_temp_diaria';

-- ¿Qué filtra el WHERE de esa vista? Filtra s.tipo = 'temperatura':
-- solo deja pasar lecturas de sensores de temperatura, descarta
-- humedad y radiación.
-- ¿Qué NO filtra? No filtra por s.activo. No le importa si el sensor
-- está dado de baja o no, y tampoco filtra por rango de fecha.

-- Sensores de tipo temperatura:
SELECT sensor_id, tipo, activo FROM sensores WHERE tipo = 'temperatura';
-- Son 3: sensor 1 (activo=1), sensor 3 (activo=0) y sensor 5 (activo=0).

-- Lecturas de cada uno de esos tres sensores:
SELECT sensor_id, MIN(fecha_hora) AS desde, MAX(fecha_hora) AS hasta, COUNT(*) AS n
FROM lecturas
WHERE sensor_id IN (1, 3, 5)
GROUP BY sensor_id;
-- Sensor 1: abril, 237 lecturas (activo).
-- Sensor 3: FEBRERO (2026-02-04 a 2026-02-08), 40 lecturas, y está
-- dado de baja (activo=0).
-- Sensor 5: no tiene ninguna lectura cargada.

-- Entonces: los 5 días de más son 2026-02-04, 05, 06, 07 y 08 — las
-- lecturas de FEBRERO del sensor 3, que sigue dado de baja pero cuyas
-- lecturas viejas nunca se filtraron. La vista las suma igual que si
-- fueran de un sensor activo de abril, porque nunca se fija en la
-- columna activo.

-- C3. Ranking usando la vista tal como está
SELECT dia, temp_promedio,
       RANK() OVER (ORDER BY temp_promedio DESC) AS puesto
FROM v_temp_diaria;
-- Esperado y confirmado: 35 filas. Puesto 1 = 2026-04-20 (27.33).
-- Puesto 2 = empate de 10 días en 25.63.

-- De esos 10 empatados en el segundo puesto, 5 son del sensor 3
-- (dado de baja): 2026-02-04, 02-05, 02-06, 02-07 y 02-08.
-- Un tablero que muestra ese top 10 tal cual está MINTIENDO, no solo
-- informando: la mitad de ese podio no corresponde a un sensor que la
-- finca considera confiable hoy, y nadie que mire el tablero se
-- enteraría de que esos días son de un sensor de baja y de un mes
-- distinto al que el tablero dice mostrar.

-- C4. El segundo problema (no es el mismo que el de los 35 días).
-- v_temp_diaria devuelve solo dos columnas: dia y temp_promedio.
-- ¿Puede alguien que solo tiene esta vista darse cuenta de que el 20
-- de abril es primero por una razón rara? NO puede. No tiene forma de
-- distinguir un día con pocas lecturas confiables de un día con
-- muchas: ambos se ven exactamente igual, un número con dos decimales.
-- ¿Qué columna, de una sola palabra, habría alcanzado para notarlo?
-- "n_lecturas" (o algo equivalente): con eso a la vista, un promedio
-- calculado sobre 6 lecturas en vez de las 8 normales del día habría
-- saltado a la vista.
-- Ayer ese error dificultó UNA consulta puntual. Escrito adentro de
-- una vista, dura para siempre (o hasta que alguien la audite): cada
-- mañana que el tablero la consulte, hereda el mismo defecto sin que
-- nadie tenga que volver a cometer el error.

-- C5. v_temp_diaria_v2: solo sensores activos, con cantidad de
-- lecturas por día y el sensor_id.
DROP VIEW IF EXISTS v_temp_diaria_v2;
CREATE VIEW v_temp_diaria_v2 AS
SELECT DATE(l.fecha_hora)    AS dia,
       s.sensor_id           AS sensor_id,
       ROUND(AVG(l.valor),2) AS temp_promedio,
       COUNT(*)              AS n_lecturas
FROM lecturas l
JOIN sensores s ON s.sensor_id = l.sensor_id
WHERE s.tipo = 'temperatura'
  AND s.activo = 1
GROUP BY DATE(l.fecha_hora), s.sensor_id;

-- Esperado: 30 filas
SELECT COUNT(*) FROM v_temp_diaria_v2;

-- Esperado: primer puesto sigue siendo 2026-04-20 con 27.33, y n_lecturas = 6
SELECT dia, sensor_id, temp_promedio, n_lecturas,
       RANK() OVER (ORDER BY temp_promedio DESC) AS puesto
FROM v_temp_diaria_v2
LIMIT 5;

-- El 20 de abril sigue primero. ¿Arreglé el ranking o arreglé otra
-- cosa? Arreglé OTRA cosa: saqué del cálculo los 5 días de febrero del
-- sensor de baja (35 → 30 filas), y agregué la columna n_lecturas para
-- que el que consulte la vista pueda ver que ese primer puesto se
-- calculó con solo 6 lecturas en vez de 8. El ranking del 20 de abril
-- como primer puesto NO cambió, porque el problema de ese día
-- (lecturas faltantes) es un problema distinto al problema de los 35
-- días (sensor de baja mezclado). Corregí el segundo, no el primero;
-- el primero ahora es visible en vez de estar escondido.

-- C6. Reemplazar la vista vieja. (No ejecuto el DROP/CREATE real de
-- v_temp_diaria acá para no romper la comparación con C1–C4 en esta
-- misma corrida; dejo la respuesta en comentario.)
-- 1) El tablero de la finca consulta v_temp_diaria todas las mañanas
--    y espera DOS columnas. Si yo reemplazo la vista por la buena, que
--    tiene CUATRO columnas (dia, sensor_id, temp_promedio,
--    n_lecturas), mañana a las 7 el tablero puede romperse (si asume
--    posición de columnas o un shape fijo) o, peor, seguir corriendo
--    pero mostrando mal las columnas de más si no las tiene previstas.
-- 2) Los promedios de abril van a bajar de golpe porque desaparecen
--    los días de febrero que estaban inflando artificialmente el
--    ranking, y porque el promedio real (sin mezclar sensores de baja)
--    es distinto. Lo que le digo a quien pregunte: "el número de antes
--    incluía lecturas de un sensor dado de baja en febrero, mezcladas
--    con las de abril; el número nuevo es el correcto porque solo usa
--    sensores activos del período que corresponde."
-- 3) Lo que haría distinto: publicar v_temp_diaria_v2 al lado de la
--    vieja y avisar, en vez de reemplazar de un día para otro. Un
--    reemplazo silencioso de una vista que otros consultan a diario es
--    exactamente el mismo error de fondo que causó este problema (nadie
--    audita algo que "ya está funcionando"). Publicar la v2, avisar
--    quién la usa, y dar tiempo para migrar el tablero es más lento,
--    pero no le rompe el número a nadie sin avisar.

-- C7. Auditoría de v_alertas_sensores
SELECT sql FROM sqlite_master WHERE type = 'view' AND name = 'v_alertas_sensores';

-- Esperado: 93 filas totales — 42 temperatura, 21 humedad, 30 radiación
SELECT COUNT(*) FROM v_alertas_sensores;
SELECT tipo, COUNT(*) FROM v_alertas_sensores GROUP BY tipo;

-- La misma consulta sin el filtro de sensores activos (esperado: 103)
SELECT COUNT(*) FROM lecturas l JOIN sensores s ON s.sensor_id = l.sensor_id
WHERE (s.tipo='temperatura' AND l.valor > 28)
   OR (s.tipo='humedad'     AND l.valor < 60)
   OR (s.tipo='radiacion'   AND l.valor > 800);

-- Esta vista SÍ filtra activo = 1 (está en su WHERE). ¿Está bien
-- escrita? Sí, está bien escrita: los 93 registros con el filtro de
-- activo frente a los 103 sin filtro confirman que el WHERE hace
-- exactamente lo que dice hacer, y no deja pasar de más ni de menos.
-- Auditar esta vista y encontrar que está correcta también es un
-- resultado válido del ejercicio: no toda vista heredada está rota.


-- =====================================================================
-- PARTE D · Lo que una vista no puede, y lo que sí puede esconder
-- =====================================================================

-- D1. Intentar escribir en una vista.
-- INSERT INTO v_produccion_lote VALUES ('x','y',1,1,1,1);
-- Error: cannot modify v_produccion_lote because it is a view
--
-- UPDATE v_produccion_lote SET kg_total = 0;
-- Error: cannot modify v_produccion_lote because it is a view
--
-- kg_total es un SUM de varias filas de cosechas. Si SQLite dejara
-- escribirle 8000 directamente, tendría que decidir por sí solo cómo
-- repartir ese 8000 entre las cosechas individuales que hoy suman ese
-- total (¿le resta a una? ¿reparte proporcional? ¿borra las demás?) —
-- no hay una única forma correcta de "deshacer" un SUM, por eso
-- SQLite ni lo intenta y directamente lo prohíbe.

-- D2. Intentar indexar una vista.
-- CREATE INDEX ix_kgha ON v_produccion_lote(kg_ha);
-- Error: views may not be indexed
--
-- Entonces: ¿una vista hace que la consulta sea más rápida? NO. Una
-- vista no acelera nada por sí sola, porque no guarda datos propios
-- que se puedan indexar. Cada vez que hago SELECT * FROM
-- v_produccion_lote, SQLite corre por dentro el SELECT completo que
-- quedó guardado en la definición de la vista, contra las tablas base,
-- con los mismos índices (o falta de ellos) que tendría si yo hubiera
-- escrito esa consulta a mano.

-- D3. La vista que no valida nada.
DROP VIEW IF EXISTS v_fantasma;
CREATE VIEW v_fantasma AS SELECT * FROM tabla_que_no_existe;
-- Esto funciona sin error.
-- SELECT * FROM v_fantasma;  -- esto sí falla: no such table: tabla_que_no_existe
--
-- ¿En qué momento SQLite revisa que la vista tiene sentido? Recién
-- cuando alguien la CONSULTA, no cuando se CREA. El CREATE VIEW solo
-- guarda el texto del SELECT; SQLite no valida en ese momento que las
-- tablas o columnas que menciona existan de verdad.
-- Para una base con cuarenta vistas encadenadas y una tabla que
-- alguien renombró: esa base puede vivir tranquila, sin ningún error,
-- durante semanas, hasta que alguien consulte justo la vista (o una
-- de las que dependen de ella) que apunta a la tabla renombrada. El
-- error no aparece en el momento del cambio que lo causó, sino mucho
-- después, en el momento del uso, lo que hace casi imposible conectar
-- la causa con el efecto sin auditar.

-- D4. El error que se hereda (fan-out).
DROP VIEW IF EXISTS v_costo_mal;
CREATE VIEW v_costo_mal AS
SELECT si.siembra_id,
       SUM(la.costo_mano_obra)              AS costo_mano_obra,
       SUM(li.cantidad + li.costo_unitario) AS costo_insumos
FROM siembras si
JOIN labores la           ON la.siembra_id = si.siembra_id
LEFT JOIN labor_insumo li ON li.labor_id = la.labor_id
GROUP BY si.siembra_id;

-- Esperado: 8 filas, siembra 1 con costo_mano_obra = 455
SELECT COUNT(*) FROM v_costo_mal;
SELECT * FROM v_costo_mal WHERE siembra_id = 1;

-- ¿Por qué 455 y no 335? La siembra 1 tiene la labor 1 (fertilización,
-- costo_mano_obra = 120) con DOS insumos asociados en labor_insumo.
-- El LEFT JOIN contra labor_insumo multiplica la fila de la labor 1
-- por cada insumo que tiene: la labor 1 aparece dos veces en el
-- resultado intermedio, y por lo tanto su costo_mano_obra (120) se
-- suma dos veces (240) en vez de una. Sumado a la labor 2 (90) y la
-- labor 13 (125): 240 + 90 + 125 = 455. El número real, sin duplicar,
-- es 120 + 90 + 125 = 335. Este es el fan-out de la clase 5: un JOIN
-- "uno a muchos" que infla un SUM de la tabla del lado "uno".
--
-- ¿Qué dos siembras desaparecieron? Las siembras 9 y 10, porque no
-- tienen ninguna fila en labores, y el JOIN (no LEFT JOIN) contra
-- labores las excluye por completo del resultado.
SELECT si.siembra_id
FROM siembras si
LEFT JOIN labores la ON la.siembra_id = si.siembra_id
WHERE la.labor_id IS NULL;

-- v_costo_siembra, la versión que se puede defender: las 10 siembras,
-- con finca y lote, mano de obra sin inflar (agregada aparte antes de
-- unir con insumos) e insumos agregados aparte también, para que
-- ningún fan-out cruce ambos totales.
DROP VIEW IF EXISTS v_costo_siembra;
CREATE VIEW v_costo_siembra AS
SELECT si.siembra_id,
       f.nombre                                                              AS finca,
       lo.codigo                                                             AS lote,
       COALESCE(mo.costo_mano_obra, 0)                                       AS costo_mano_obra,
       COALESCE(ins.costo_insumos, 0)                                        AS costo_insumos,
       ROUND(COALESCE(mo.costo_mano_obra, 0) + COALESCE(ins.costo_insumos, 0), 2) AS costo_total
FROM siembras si
JOIN lotes  lo ON lo.lote_id = si.lote_id
JOIN fincas f  ON f.finca_id = lo.finca_id
LEFT JOIN (
    SELECT siembra_id, SUM(costo_mano_obra) AS costo_mano_obra
    FROM labores
    GROUP BY siembra_id
) mo ON mo.siembra_id = si.siembra_id
LEFT JOIN (
    SELECT la.siembra_id, SUM(li.cantidad * li.costo_unitario) AS costo_insumos
    FROM labores la
    JOIN labor_insumo li ON li.labor_id = la.labor_id
    GROUP BY la.siembra_id
) ins ON ins.siembra_id = si.siembra_id;

-- Esperado: 10 filas, siembra 1 = 335 | 295.80 | 630.80
SELECT COUNT(*) FROM v_costo_siembra;
SELECT costo_mano_obra, costo_insumos, costo_total
FROM v_costo_siembra WHERE siembra_id = 1;

-- Esperado: 3562.30 (mismo número del ejercicio 5)
SELECT ROUND(SUM(costo_total), 2) FROM v_costo_siembra;


-- =====================================================================
-- EXTRA · Una vista propia que responde una pregunta que no me pidieron
-- =====================================================================

-- Pregunta de negocio: entre las siembras que ya cosecharon, ¿cuáles
-- están costando más caro por cada kilo producido? v_costo_siembra me
-- da el costo, pero no dice nada sobre lo que esa siembra realmente
-- entregó. Cruzarla con cosechas es la parte que faltaba para poder
-- decidir dónde revisar rendimiento, no solo dónde se gastó más.
DROP VIEW IF EXISTS v_eficiencia_siembra;
CREATE VIEW v_eficiencia_siembra AS
SELECT vcs.siembra_id,
       vcs.finca,
       vcs.lote,
       vcs.costo_total,
       COALESCE(SUM(c.kg), 0)      AS kg_cosechados,
       COUNT(c.cosecha_id)         AS n_cosechas,
       CASE WHEN SUM(c.kg) > 0
            THEN ROUND(vcs.costo_total / SUM(c.kg), 2)
            ELSE NULL
       END                          AS costo_por_kg
FROM v_costo_siembra vcs
LEFT JOIN cosechas c ON c.siembra_id = vcs.siembra_id
GROUP BY vcs.siembra_id;

SELECT COUNT(*) FROM v_eficiencia_siembra;  -- 10, una fila por siembra
SELECT siembra_id, finca, lote, costo_total, kg_cosechados, costo_por_kg
FROM v_eficiencia_siembra
ORDER BY costo_por_kg DESC;

-- Por qué merece ser vista y no una consulta suelta: se construye
-- sobre v_costo_siembra (que a su vez ya resuelve el fan-out de mano
-- de obra vs. insumos), y es exactamente el tipo de número que un
-- responsable de finca va a querer revisar cada cierre de mes, no una
-- sola vez. Guardarla como vista significa que la próxima vez que se
-- cargue una cosecha o una labor nueva, el costo_por_kg se recalcula
-- solo, sin que nadie tenga que volver a escribir el cruce entre
-- costos e insumos y cosechas.


-- =====================================================================
-- PARTE E · Cierre
-- =====================================================================

-- 1) Vista vs. CTE, en una frase: la CTE vive solo durante la consulta
-- en la que se escribió (muere apenas termina esa sentencia); la vista
-- vive en la base de datos hasta que alguien la borra con DROP VIEW,
-- y cualquier otra consulta futura la puede usar.

-- 2) ¿Por qué es más difícil encontrar un error adentro de una vista
-- que adentro de una consulta? Porque una consulta suelta se ve
-- completa cada vez que alguien la corre y la puede revisar ahí mismo;
-- una vista se consulta por su nombre, como si fuera una tabla, y la
-- persona que la usa normalmente confía en el nombre y nunca abre su
-- definición con sqlite_master para revisar qué hay adentro.

-- 3) Tres reglas que me impongo antes de publicar una vista para gente
-- que nunca va a leer su definición:
--    a) El nombre tiene que decir exactamente qué filtra, no solo qué
--       tema toca: no "v_temperaturas" sino algo que deje claro si son
--       todos los sensores o solo los activos (ej. v_temp_diaria_activos).
--    b) Toda vista que agregue (SUM, AVG, COUNT) tiene que mostrar
--       también el conteo de filas que usó para ese cálculo, para que
--       quien la lea pueda notar si un promedio se calculó con menos
--       datos de los esperados.
--    c) Ninguna vista se publica sin antes correr, al menos una vez,
--       la misma consulta SIN el filtro que se supone que tiene, para
--       comparar los dos números y confirmar con datos —no de
--       memoria— que ese filtro realmente está haciendo lo que dice
--       que hace.
