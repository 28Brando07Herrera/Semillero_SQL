-- =====================================================================
-- CURSO DE SQL  |  AgroDB  |  Ejercicio N
-- Alumno:
-- Fecha:
--
-- Este archivo se ejecuta DESPUES de datos/agrodb_nucleo.sql,
-- en la MISMA sesion de sqliteonline.
--
-- Si te trabas mas de 20 minutos: escribi la duda aca como comentario
-- empezando con DUDA, y segui con lo siguiente.
-- =====================================================================

PRAGMA foreign_keys = ON;


-- =====================================================================
-- PARTE A - DIAGNOSTICO  (respuestas como comentario)
-- =====================================================================

-- 1)
-- 2)
-- 3)
-- 4)
-- 5)


-- =====================================================================
-- PARTE B - CREACION DE TABLAS
-- =====================================================================

DROP TABLE IF EXISTS labor_insumo;
DROP TABLE IF EXISTS labores;
DROP TABLE IF EXISTS insumos;
DROP TABLE IF EXISTS sensores;

-- B.1 insumos


-- B.2 labores


-- B.3 labor_insumo


-- B.4 sensores


-- PUNTO DE CONTROL 1 -> deben salir 6 filas
SELECT m.name AS tabla, f."from" AS columna, f."table" AS apunta_a
FROM sqlite_master m
JOIN pragma_foreign_key_list(m.name) f
WHERE m.type = 'table'
  AND m.name IN ('insumos','labores','labor_insumo','sensores')
ORDER BY m.name;


-- =====================================================================
-- PARTE C - MIGRACION
-- =====================================================================

-- C.1 insumos


-- C.2 labores


-- C.3 labor_insumo


-- C.4 sensores


-- PUNTO DE CONTROL 2 -> ninguna fila
PRAGMA foreign_key_check;


-- =====================================================================
-- PARTE D - CONSULTAS   (antes de cada una, la pregunta en palabras)
-- =====================================================================

-- D1. Pregunta:


-- D2. LA PRUEBA DE FUEGO -> 12 filas, las 12 en OK
WITH costo AS (
  SELECT l.labor_id,
         ROUND(l.costo_mano_obra + COALESCE(SUM(li.cantidad * li.costo_unitario), 0), 2) AS calculado
  FROM labores l
  LEFT JOIN labor_insumo li ON li.labor_id = l.labor_id
  GROUP BY l.labor_id, l.costo_mano_obra
)
SELECT p.id, p.costo_total AS original, c.calculado,
       CASE WHEN p.costo_total = c.calculado THEN 'OK' ELSE 'REVISAR' END AS estado
FROM registro_campo_plano p
JOIN costo c ON c.labor_id = p.id
ORDER BY p.id;

-- D3. Pregunta:


-- D4. Pregunta:


-- D5. Pregunta:


-- D6. Pregunta (inventada por mi):


-- =====================================================================
-- CIERRE
-- =====================================================================

-- 1) Que se puede hacer ahora que antes era imposible:
--
-- 2) Por que mas tablas es una mejora y no un retroceso:
--
-- 3) Que pregunta mi modelo TODAVIA no puede responder, y que le falta:
--
