-- =====================================================================
-- CURSO DE SQL  |  AgroDB  |  Ejercicio 5
-- Alumno:
-- Fecha:
--
-- Este archivo se ejecuta DESPUES de Agronomia_ejercicios.sql
-- en la MISMA sesion de SQLite.
--
-- Importante:
-- 1) Antes de cada SUM se deja una consulta COUNT(*) de control.
-- 2) Todo reporte que menciona un lote incluye tambien la finca.
-- =====================================================================

PRAGMA foreign_keys = ON;


-- =====================================================================
-- PARTE A - RECORRER EL MODELO
-- =====================================================================

-- A1. Catalogo de siembras: finca, lote, cultivo, variedad,
--     fecha de siembra y estado. Una fila por siembra.
-- Control: COUNT(*) -> 10 filas.
SELECT COUNT(*)
FROM siembras s
JOIN lotes l   ON l.lote_id = s.lote_id
JOIN fincas f  ON f.finca_id = l.finca_id
JOIN cultivos c ON c.cultivo_id = s.cultivo_id;

SELECT f.nombre AS finca,
       l.codigo AS lote,
       c.nombre AS cultivo,
       c.variedad,
       s.fecha_siembra,
       s.estado
FROM siembras s
JOIN lotes l    ON l.lote_id = s.lote_id
JOIN fincas f   ON f.finca_id = l.finca_id
JOIN cultivos c ON c.cultivo_id = s.cultivo_id
ORDER BY f.nombre, l.codigo, s.siembra_id;


-- A2. Todas las labores de abril de 2026 con finca, lote y responsable.
-- Control: COUNT(*) -> 10 filas.
SELECT COUNT(*)
FROM labores lb
JOIN siembras s ON s.siembra_id = lb.siembra_id
JOIN lotes l    ON l.lote_id = s.lote_id
JOIN fincas f   ON f.finca_id = l.finca_id
WHERE lb.fecha >= '2026-04-01'
  AND lb.fecha <  '2026-05-01';

SELECT lb.labor_id,
       lb.fecha,
       f.nombre AS finca,
       l.codigo AS lote,
       lb.responsable
FROM labores lb
JOIN siembras s ON s.siembra_id = lb.siembra_id
JOIN lotes l    ON l.lote_id = s.lote_id
JOIN fincas f   ON f.finca_id = l.finca_id
WHERE lb.fecha >= '2026-04-01'
  AND lb.fecha <  '2026-05-01'
ORDER BY lb.fecha;

-- La labor 18 tiene responsable NULL porque en los datos fue cargada
-- sin responsable; el NULL representa un dato faltante real, no texto.


-- A3. Detalle de consumo de insumos.
-- Control: COUNT(*) -> 16 filas.
SELECT COUNT(*)
FROM labores lb
JOIN siembras s      ON s.siembra_id = lb.siembra_id
JOIN lotes l         ON l.lote_id = s.lote_id
JOIN fincas f        ON f.finca_id = l.finca_id
JOIN labor_insumo li ON li.labor_id = lb.labor_id
JOIN insumos i       ON i.insumo_id = li.insumo_id;

SELECT f.nombre AS finca,
       l.codigo AS lote,
       lb.tipo_labor,
       lb.fecha,
       i.nombre AS insumo,
       li.cantidad,
       i.unidad,
       ROUND(li.cantidad * li.costo_unitario, 2) AS costo_linea
FROM labores lb
JOIN siembras s      ON s.siembra_id = lb.siembra_id
JOIN lotes l         ON l.lote_id = s.lote_id
JOIN fincas f        ON f.finca_id = l.finca_id
JOIN labor_insumo li ON li.labor_id = lb.labor_id
JOIN insumos i       ON i.insumo_id = li.insumo_id
ORDER BY lb.fecha, lb.labor_id, i.nombre;


-- =====================================================================
-- PARTE B - EL SUM QUE MIENTE
-- =====================================================================

-- B1. Kilos cosechados por finca.
-- Control COUNT(*): Santa Rosa 4, El Guayabo 3, La Union 2.
SELECT f.nombre AS finca,
       COUNT(*) AS filas_control
FROM cosechas c
JOIN siembras s ON s.siembra_id = c.siembra_id
JOIN lotes l    ON l.lote_id = s.lote_id
JOIN fincas f   ON f.finca_id = l.finca_id
GROUP BY f.finca_id, f.nombre
ORDER BY f.finca_id;

SELECT f.nombre AS finca,
       SUM(c.kg) AS kilos_cosechados
FROM cosechas c
JOIN siembras s ON s.siembra_id = c.siembra_id
JOIN lotes l    ON l.lote_id = s.lote_id
JOIN fincas f   ON f.finca_id = l.finca_id
GROUP BY f.finca_id, f.nombre
ORDER BY f.finca_id;

-- Resultado correcto:
-- Hacienda Santa Rosa = 14200
-- Finca El Guayabo    = 14250
-- Agricola La Union   = 2100


-- B2. Consulta deliberadamente incorrecta: se agrega labores al JOIN
--     sin separar primero las relaciones 1:N.
-- Control COUNT(*): Santa Rosa 11, El Guayabo 8, La Union 4.
SELECT f.nombre AS finca,
       COUNT(*) AS filas_control
FROM cosechas c
JOIN siembras s ON s.siembra_id = c.siembra_id
JOIN lotes l    ON l.lote_id = s.lote_id
JOIN fincas f   ON f.finca_id = l.finca_id
JOIN labores lb ON lb.siembra_id = s.siembra_id
GROUP BY f.finca_id, f.nombre
ORDER BY f.finca_id;

SELECT f.nombre AS finca,
       SUM(c.kg) AS kilos_inflados,
       COUNT(lb.labor_id) AS cantidad_labores
FROM cosechas c
JOIN siembras s ON s.siembra_id = c.siembra_id
JOIN lotes l    ON l.lote_id = s.lote_id
JOIN fincas f   ON f.finca_id = l.finca_id
JOIN labores lb ON lb.siembra_id = s.siembra_id
GROUP BY f.finca_id, f.nombre
ORDER BY f.finca_id;

-- Los kilos inflados obtenidos son:
-- Santa Rosa 41100, El Guayabo 32950, La Union 4200.


-- B3.a. Para cada siembra: labores, cosechas y filas del JOIN entre ambas.
SELECT s.siembra_id,
       (SELECT COUNT(*)
        FROM labores lb
        WHERE lb.siembra_id = s.siembra_id) AS cantidad_labores,
       (SELECT COUNT(*)
        FROM cosechas c
        WHERE c.siembra_id = s.siembra_id) AS cantidad_cosechas,
       (SELECT COUNT(*)
        FROM labores lb
        JOIN cosechas c ON c.siembra_id = lb.siembra_id
        WHERE lb.siembra_id = s.siembra_id) AS filas_join
FROM siembras s
ORDER BY s.siembra_id;

-- Para la siembra 1: 3 labores, 2 cosechas y 6 filas.
-- 3 x 2 = 6: cada labor se combina con cada cosecha.


-- B3.b. Finca 1: COUNT(*) contra COUNT(DISTINCT cosecha_id).
SELECT COUNT(*) AS filas_join,
       COUNT(DISTINCT c.cosecha_id) AS cosechas_distintas
FROM cosechas c
JOIN siembras s ON s.siembra_id = c.siembra_id
JOIN lotes l    ON l.lote_id = s.lote_id
JOIN fincas f   ON f.finca_id = l.finca_id
JOIN labores lb ON lb.siembra_id = s.siembra_id
WHERE f.finca_id = 1;

-- Resultado esperado: 11 y 4.
-- La diferencia significa que las mismas cosechas aparecen repetidas
-- al combinarse con varias labores. COUNT(DISTINCT) evita ese fan-out.


-- B4. Correccion: agregar cada relacion hija por separado y luego unir.
-- Control de cosechas: 4, 3 y 2 filas por finca.
SELECT l.finca_id, COUNT(*) AS filas_control_cosechas
FROM cosechas c
JOIN siembras s ON s.siembra_id = c.siembra_id
JOIN lotes l    ON l.lote_id = s.lote_id
GROUP BY l.finca_id
ORDER BY l.finca_id;

-- Control de labores: 8, 5 y 6 filas por finca.
SELECT l.finca_id, COUNT(*) AS filas_control_labores
FROM labores lb
JOIN siembras s ON s.siembra_id = lb.siembra_id
JOIN lotes l    ON l.lote_id = s.lote_id
GROUP BY l.finca_id
ORDER BY l.finca_id;

WITH cosecha_por_finca AS (
    SELECT l.finca_id,
           SUM(c.kg) AS kilos
    FROM cosechas c
    JOIN siembras s ON s.siembra_id = c.siembra_id
    JOIN lotes l    ON l.lote_id = s.lote_id
    GROUP BY l.finca_id
),
labores_por_finca AS (
    SELECT l.finca_id,
           COUNT(*) AS cantidad_labores
    FROM labores lb
    JOIN siembras s ON s.siembra_id = lb.siembra_id
    JOIN lotes l    ON l.lote_id = s.lote_id
    GROUP BY l.finca_id
)
SELECT f.nombre AS finca,
       COALESCE(cpf.kilos, 0) AS kilos_cosechados,
       COALESCE(lpf.cantidad_labores, 0) AS cantidad_labores
FROM fincas f
LEFT JOIN cosecha_por_finca cpf ON cpf.finca_id = f.finca_id
LEFT JOIN labores_por_finca lpf ON lpf.finca_id = f.finca_id
ORDER BY f.finca_id;


-- B5. Error en la otra direccion.
SELECT SUM(costo_mano_obra) AS total_mano_obra
FROM labores;
-- Control COUNT(*) -> 19 labores.

SELECT SUM(lb.costo_mano_obra) AS total_mano_obra_con_insumos
FROM labores lb
JOIN labor_insumo li ON li.labor_id = lb.labor_id;
-- Control COUNT(*) -> 16 filas, no 19 labores.

SELECT COUNT(*) AS labores_sin_insumo
FROM labores lb
LEFT JOIN labor_insumo li ON li.labor_id = lb.labor_id
WHERE li.labor_id IS NULL;
-- Resultado: 7 labores sin insumos.

-- Primera consulta: 2330.00.
-- Segunda consulta: 2035.00.
-- La segunda pierde 7 labores porque el JOIN interno exige que exista
-- al menos un insumo.
-- Ademas, cuenta de mas las labores que tienen varios insumos: una misma
-- labor aparece una vez por cada fila de labor_insumo.


-- =====================================================================
-- PARTE C - ENCONTRAR LO QUE FALTA
-- =====================================================================

-- C1. Lotes sin ningun sensor instalado.
SELECT f.nombre AS finca,
       l.codigo AS lote
FROM lotes l
JOIN fincas f ON f.finca_id = l.finca_id
LEFT JOIN sensores se ON se.lote_id = l.lote_id
WHERE se.sensor_id IS NULL
ORDER BY f.nombre, l.codigo;

-- Esperado: 4 lotes.


-- C2. Primero, la condicion en WHERE: es la prueba incorrecta.
-- El resultado es 0 filas porque los lotes sin sensor producen NULL y
-- NULL = 1 no es verdadero.
SELECT f.nombre AS finca,
       l.codigo AS lote
FROM lotes l
JOIN fincas f ON f.finca_id = l.finca_id
LEFT JOIN sensores se ON se.lote_id = l.lote_id
WHERE se.activo = 1
  AND se.sensor_id IS NULL;

-- Correccion: activo = 1 debe estar en el ON.
SELECT f.nombre AS finca,
       l.codigo AS lote
FROM lotes l
JOIN fincas f ON f.finca_id = l.finca_id
LEFT JOIN sensores se
       ON se.lote_id = l.lote_id
      AND se.activo = 1
WHERE se.sensor_id IS NULL
ORDER BY f.nombre, l.codigo;

-- Esperado: 5 lotes.
-- Diferencia: WHERE filtra despues del LEFT JOIN y elimina las filas NULL;
-- ON decide que filas hijas participan en la union y conserva el lote
-- cuando no existe ningun sensor activo.


-- C3. Siembras sin ninguna labor.
SELECT f.nombre AS finca,
       l.codigo AS lote,
       c.nombre AS cultivo,
       s.estado
FROM siembras s
JOIN lotes l    ON l.lote_id = s.lote_id
JOIN fincas f   ON f.finca_id = l.finca_id
JOIN cultivos c ON c.cultivo_id = s.cultivo_id
LEFT JOIN labores lb ON lb.siembra_id = s.siembra_id
WHERE lb.labor_id IS NULL
ORDER BY f.nombre, l.codigo;

-- Esperado: 2.


-- C4. Insumos nunca utilizados.
SELECT i.nombre AS insumo
FROM insumos i
LEFT JOIN labor_insumo li ON li.insumo_id = i.insumo_id
WHERE li.insumo_id IS NULL
ORDER BY i.nombre;

-- Esperado: 1: Cal agricola.


-- C5. Siembras en produccion sin cosecha.
SELECT f.nombre AS finca,
       l.codigo AS lote,
       c.nombre AS cultivo,
       s.estado
FROM siembras s
JOIN lotes l    ON l.lote_id = s.lote_id
JOIN fincas f   ON f.finca_id = l.finca_id
JOIN cultivos c ON c.cultivo_id = s.cultivo_id
LEFT JOIN cosechas co ON co.siembra_id = s.siembra_id
WHERE s.estado = 'en produccion'
  AND co.cosecha_id IS NULL;

-- Esperado: Agricola La Union, A-2, Cacao, en produccion.
-- Al jefe de finca le diria que esta siembra esta en produccion pero no
-- tiene ninguna cosecha registrada, por lo que debe revisarse de inmediato.


-- =====================================================================
-- PARTE D - LAS PREGUNTAS DEL JEFE
-- =====================================================================

-- D1. Rendimiento.
-- Primero se prueba la division directa.
-- En SQLite, cuando ambos operandos quedan como enteros, la division
-- descarta la parte decimal.
--
-- Control COUNT(*) por lote: cada grupo tiene 1 o 2 cosechas.
SELECT f.nombre AS finca,
       l.codigo AS lote,
       COUNT(*) AS filas_control
FROM cosechas c
JOIN siembras s ON s.siembra_id = c.siembra_id
JOIN lotes l    ON l.lote_id = s.lote_id
JOIN fincas f   ON f.finca_id = l.finca_id
GROUP BY s.siembra_id, l.lote_id, f.finca_id
ORDER BY f.nombre, l.codigo;

-- Consulta inicial (incorrecta en los lotes con hectareas enteras).
SELECT f.nombre AS finca,
       l.codigo AS lote,
       l.hectareas,
       SUM(c.kg) AS kilos,
       ROUND(SUM(c.kg) / l.hectareas, 2) AS rendimiento_kg_ha
FROM cosechas c
JOIN siembras s ON s.siembra_id = c.siembra_id
JOIN lotes l    ON l.lote_id = s.lote_id
JOIN fincas f   ON f.finca_id = l.finca_id
GROUP BY s.siembra_id, l.lote_id, f.finca_id
ORDER BY rendimiento_kg_ha DESC;

-- Salen mal:
-- El Guayabo L-01 -> 202.00 (correcto 202.27)
-- Santa Rosa L-02 -> 174.00 (correcto 174.19)
-- La Union A-1    -> 38.00  (correcto 38.18)
-- Se corrige forzando division real con * 1.0.

SELECT f.nombre AS finca,
       l.codigo AS lote,
       l.hectareas,
       SUM(c.kg) AS kilos,
       ROUND(SUM(c.kg) * 1.0 / l.hectareas, 2) AS rendimiento_kg_ha
FROM cosechas c
JOIN siembras s ON s.siembra_id = c.siembra_id
JOIN lotes l    ON l.lote_id = s.lote_id
JOIN fincas f   ON f.finca_id = l.finca_id
GROUP BY s.siembra_id, l.lote_id, f.finca_id
ORDER BY rendimiento_kg_ha DESC;

-- Top 3 correcto:
-- Finca El Guayabo L-02 -> 529.73
-- Hacienda Santa Rosa L-01 -> 256.14
-- Finca El Guayabo L-01 -> 202.27


-- D2. Costo total por finca, separado en mano de obra e insumos.
-- Control de mano de obra: Santa Rosa 8, El Guayabo 5, La Union 6.
SELECT f.nombre AS finca,
       COUNT(*) AS filas_control_mano_obra
FROM labores lb
JOIN siembras s ON s.siembra_id = lb.siembra_id
JOIN lotes l    ON l.lote_id = s.lote_id
JOIN fincas f   ON f.finca_id = l.finca_id
GROUP BY f.finca_id, f.nombre
ORDER BY f.finca_id;

-- Control de lineas de insumos: Santa Rosa 5, El Guayabo 6, La Union 5.
SELECT f.nombre AS finca,
       COUNT(*) AS filas_control_insumos
FROM labor_insumo li
JOIN labores lb ON lb.labor_id = li.labor_id
JOIN siembras s ON s.siembra_id = lb.siembra_id
JOIN lotes l    ON l.lote_id = s.lote_id
JOIN fincas f   ON f.finca_id = l.finca_id
GROUP BY f.finca_id, f.nombre
ORDER BY f.finca_id;

WITH mano_obra AS (
    SELECT l.finca_id,
           SUM(lb.costo_mano_obra) AS mano_obra
    FROM labores lb
    JOIN siembras s ON s.siembra_id = lb.siembra_id
    JOIN lotes l    ON l.lote_id = s.lote_id
    GROUP BY l.finca_id
),
insumos AS (
    SELECT l.finca_id,
           SUM(li.cantidad * li.costo_unitario) AS costo_insumos
    FROM labor_insumo li
    JOIN labores lb ON lb.labor_id = li.labor_id
    JOIN siembras s ON s.siembra_id = lb.siembra_id
    JOIN lotes l    ON l.lote_id = s.lote_id
    GROUP BY l.finca_id
)
SELECT f.nombre AS finca,
       ROUND(COALESCE(mo.mano_obra, 0), 2) AS mano_obra,
       ROUND(COALESCE(ins.costo_insumos, 0), 2) AS insumos,
       ROUND(COALESCE(mo.mano_obra, 0) +
             COALESCE(ins.costo_insumos, 0), 2) AS total
FROM fincas f
LEFT JOIN mano_obra mo ON mo.finca_id = f.finca_id
LEFT JOIN insumos ins  ON ins.finca_id = f.finca_id
ORDER BY f.finca_id;

-- Resultados:
-- Santa Rosa 1441.00
-- El Guayabo  1024.50
-- La Union    1096.80
-- Total general 3562.30


-- D3.a. Responsables por cantidad de labores.
SELECT lb.responsable,
       COUNT(*) AS cantidad_labores
FROM labores lb
WHERE lb.responsable IS NOT NULL
GROUP BY lb.responsable
ORDER BY cantidad_labores DESC, lb.responsable;

-- Pedro Loor queda primero con 5.


-- D3.b. Insumos por costo total consumido.
-- Control COUNT(*): Abono 2, Aceite 1, Mancozeb 4, Muriato 2,
-- Semilla 1, Urea 6.
SELECT i.nombre AS insumo,
       COUNT(*) AS filas_control
FROM labor_insumo li
JOIN insumos i ON i.insumo_id = li.insumo_id
GROUP BY i.insumo_id, i.nombre
ORDER BY i.nombre;

SELECT i.nombre AS insumo,
       ROUND(SUM(li.cantidad * li.costo_unitario), 2) AS costo_total
FROM labor_insumo li
JOIN insumos i ON i.insumo_id = li.insumo_id
GROUP BY i.insumo_id, i.nombre
ORDER BY costo_total DESC;

-- Urea 46% queda primera con 427.00.


-- =====================================================================
-- PARTE E - CIERRE
-- =====================================================================

-- 1) La mas peligrosa es la suma inflada por fan-out.
-- Es especialmente riesgosa porque la consulta puede ejecutarse sin error
-- y entregar un numero aparentemente razonable pero falso. Un gerente
-- podria tomar decisiones sobre costos, produccion o rendimiento basandose
-- en ese dato sin detectar el problema.

-- 2)
-- separar insumo_1, insumo_2, insumo_3 en labor_insumo -> 1FN
-- sacar unidad a la tabla insumos                         -> 3FN
-- sacar provincia a la tabla fincas                       -> 3FN

-- 3) Pregunta que AgroDB todavia no puede responder:
-- "Cuanto ingreso o margen genero cada cosecha/lote?"
-- El modelo registra kilos, costos y destino, pero no registra precio de
-- venta ni ingreso asociado a cada cosecha. Haría falta, por ejemplo,
-- una tabla ventas (venta_id, cosecha_id, fecha, precio_kg, cantidad_kg,
-- ingreso) o una columna equivalente asociada a cosechas.


-- =====================================================================
-- EXTRA (+5)
-- =====================================================================

-- Pregunta propia: ¿Que responsable ha realizado labores con insumos y
-- cuanto dinero se ha consumido en esas labores?
-- Usa 5 tablas: responsables/labores, siembras, lotes, fincas,
-- labor_insumo e insumos.
-- Control COUNT(*) antes del SUM: 16 lineas de consumo.
SELECT COUNT(*) AS filas_control
FROM labores lb
JOIN siembras s      ON s.siembra_id = lb.siembra_id
JOIN lotes l         ON l.lote_id = s.lote_id
JOIN fincas f        ON f.finca_id = l.finca_id
JOIN labor_insumo li ON li.labor_id = lb.labor_id
JOIN insumos i       ON i.insumo_id = li.insumo_id;

SELECT lb.responsable,
       ROUND(SUM(li.cantidad * li.costo_unitario), 2) AS costo_insumos
FROM labores lb
JOIN siembras s      ON s.siembra_id = lb.siembra_id
JOIN lotes l         ON l.lote_id = s.lote_id
JOIN fincas f        ON f.finca_id = l.finca_id
JOIN labor_insumo li ON li.labor_id = lb.labor_id
JOIN insumos i       ON i.insumo_id = li.insumo_id
GROUP BY lb.responsable
ORDER BY costo_insumos DESC;
