-- =====================================================================
-- CURSO DE SQL | AgroDB | Ejercicio práctico 4
-- Alumno:
-- Fecha: 2026-08-14
--
-- Este archivo se ejecuta DESPUÉS de Agronomia_clase.sql,
-- en la misma sesión de SQLite.
--
-- Objetivo: limpiar el lote de abril sin perder información real.
-- =====================================================================

PRAGMA foreign_keys = ON;


-- =====================================================================
-- PARTE A - DIAGNÓSTICO
-- =====================================================================

-- A1. Labores cuya fecha no está en formato ISO AAAA-MM-DD.
SELECT labor_id, fecha
FROM labores
WHERE fecha NOT LIKE '____-__-__';
-- Resultado esperado: labor_id 17, fecha 15/04/2026.


-- A2. Labores donde responsable contiene el texto 'NULL'.
SELECT labor_id, responsable
FROM labores
WHERE responsable = 'NULL';
-- Resultado esperado: labor_id 18.
--
-- SELECT COUNT(*) FROM labores WHERE responsable IS NULL;
-- Resultado: 0.
-- La fila 18 no aparece porque 'NULL' entre comillas es una cadena de texto,
-- mientras que IS NULL busca el valor NULL real de SQL.


-- A3. Labores cargadas dos veces: misma siembra, tipo, fecha y responsable.
SELECT siembra_id,
       tipo_labor,
       fecha,
       responsable,
       GROUP_CONCAT(labor_id) AS labor_ids,
       COUNT(*) AS cantidad
FROM labores
GROUP BY siembra_id, tipo_labor, fecha, responsable
HAVING COUNT(*) > 1;
-- Resultado esperado: labor_ids 15,16 y cantidad 2.


-- A4. Insumos duplicados comparando el nombre normalizado:
-- minúsculas y sin espacios.
WITH duplicados AS (
    SELECT LOWER(REPLACE(nombre, ' ', '')) AS nombre_normalizado
    FROM insumos
    GROUP BY LOWER(REPLACE(nombre, ' ', ''))
    HAVING COUNT(*) > 1
)
SELECT i.insumo_id,
       i.nombre,
       i.tipo,
       i.unidad,
       i.costo_unit_referencia,
       LOWER(REPLACE(i.nombre, ' ', '')) AS nombre_normalizado
FROM insumos i
JOIN duplicados d
  ON LOWER(REPLACE(i.nombre, ' ', '')) = d.nombre_normalizado
ORDER BY i.insumo_id;
-- Resultado esperado:
-- Urea: ids 1 y 8.
-- Mancozeb: ids 3 y 9.


-- A5. Labores con jornal pendiente: costo 0 y observación pendiente.
SELECT labor_id, costo_mano_obra, observacion
FROM labores
WHERE costo_mano_obra = 0
  AND observacion LIKE '%pendiente%';
-- Resultado esperado: labor_id 19, jornal pendiente de 145.00.


-- A6. Demostración del problema de la fecha rota.
SELECT labor_id, fecha
FROM labores
ORDER BY fecha
LIMIT 3;
-- Resultado: la labor 17 aparece primero porque SQLite ordena el texto
-- lexicográficamente; '15/04/2026' no sigue el formato ISO.

SELECT labor_id, strftime('%m', fecha)
FROM labores
WHERE labor_id = 17;
-- Resultado: labor_id 17 y NULL.
-- strftime no puede interpretar correctamente '15/04/2026' como una
-- fecha ISO, por eso no obtiene el mes.


-- =====================================================================
-- PARTE B - ARREGLOS SIMPLES
-- Regla: cada UPDATE tiene un COUNT previo y todos están en una
-- sola transacción.
-- =====================================================================

BEGIN TRANSACTION;

-- B1. Conteo previo al UPDATE de la fecha.
SELECT COUNT(*) AS filas_a_actualizar
FROM labores
WHERE labor_id = 17
  AND fecha NOT LIKE '____-__-__';
-- Resultado esperado: 1.

UPDATE labores
SET fecha = '2026-04-15'
WHERE labor_id = 17
  AND fecha NOT LIKE '____-__-__';


-- B2. Conteo previo al UPDATE del responsable.
SELECT COUNT(*) AS filas_a_actualizar
FROM labores
WHERE labor_id = 18
  AND responsable = 'NULL';
-- Resultado esperado: 1.

UPDATE labores
SET responsable = NULL
WHERE labor_id = 18
  AND responsable = 'NULL';


-- B3. Conteo previo al UPDATE del jornal.
SELECT COUNT(*) AS filas_a_actualizar
FROM labores
WHERE labor_id = 19
  AND costo_mano_obra = 0
  AND observacion LIKE '%jornal pendiente%';
-- Resultado esperado: 1.

UPDATE labores
SET costo_mano_obra = 145.00,
    observacion = 'jornal cargado y corregido: 145.00'
WHERE labor_id = 19
  AND costo_mano_obra = 0
  AND observacion LIKE '%jornal pendiente%';

COMMIT;


-- Verificación de A1, A2 y A5 después de los arreglos.
SELECT labor_id, fecha
FROM labores
WHERE fecha NOT LIKE '____-__-__';
-- Debe devolver 0 filas.

SELECT labor_id, responsable
FROM labores
WHERE responsable = 'NULL';
-- Debe devolver 0 filas.

SELECT labor_id, costo_mano_obra, observacion
FROM labores
WHERE costo_mano_obra = 0
  AND observacion LIKE '%pendiente%';
-- Debe devolver 0 filas.


-- =====================================================================
-- PARTE C - LA LABOR DUPLICADA Y EL CASCADE
-- =====================================================================

-- C1. Antes de borrar la copia, contar sus insumos.
SELECT COUNT(*) AS filas_labor_insumo
FROM labor_insumo
WHERE labor_id = 16;
-- Resultado esperado: 1.


-- C2. Borrar solamente la copia, que tiene el id mayor.
BEGIN TRANSACTION;

SELECT COUNT(*) AS filas_a_borrar
FROM labores
WHERE labor_id = 16;
-- Resultado esperado: 1.

DELETE FROM labores
WHERE labor_id = 16;

COMMIT;


-- C3. Volver a contar los insumos de la labor eliminada.
SELECT COUNT(*) AS filas_labor_insumo
FROM labor_insumo
WHERE labor_id = 16;
-- Resultado esperado: 0.
--
-- La fila desapareció automáticamente porque labor_insumo tiene la
-- clave foránea:
-- REFERENCES labores(labor_id) ON DELETE CASCADE
-- Al borrar la labor 16, SQLite eliminó automáticamente sus filas hijas
-- de labor_insumo.


-- C4. Línea del modelo que provoca el CASCADE:
-- labor_id INTEGER NOT NULL REFERENCES labores(labor_id) ON DELETE CASCADE,


-- =====================================================================
-- PARTE D - FUSIONAR LOS INSUMOS DUPLICADOS
-- =====================================================================

-- D1. Camino obvio que FALLA.
-- Se conserva como comentario para que el archivo pueda ejecutarse completo.
--
-- BEGIN TRANSACTION;
-- UPDATE labor_insumo SET insumo_id = 1 WHERE insumo_id = 8;
-- -- Error esperado: UNIQUE constraint failed:
-- -- labor_insumo.labor_id, labor_insumo.insumo_id
-- ROLLBACK;
--
-- Falla porque la labor 20 ya tiene una fila con (labor_id=20, insumo_id=1)
-- y la fila (20,8) no puede convertirse directamente en (20,1), ya que
-- esa combinación es la PRIMARY KEY de labor_insumo.


-- D2. Fusionar Urea 46 % (id 8) con Urea 46% (id 1).
BEGIN TRANSACTION;

-- D2.1 Conteo previo: filas donde existe el insumo bueno y también
-- el duplicado para la misma labor.
SELECT COUNT(*) AS filas_a_sumar
FROM labor_insumo li
WHERE li.insumo_id = 1
  AND EXISTS (
      SELECT 1
      FROM labor_insumo dup
      WHERE dup.labor_id = li.labor_id
        AND dup.insumo_id = 8
  );
-- Resultado esperado: 1 (la labor 20).

-- Sumar la cantidad del duplicado a la fila del insumo bueno.
UPDATE labor_insumo
SET cantidad = cantidad + (
    SELECT dup.cantidad
    FROM labor_insumo dup
    WHERE dup.labor_id = labor_insumo.labor_id
      AND dup.insumo_id = 8
)
WHERE insumo_id = 1
  AND EXISTS (
      SELECT 1
      FROM labor_insumo dup
      WHERE dup.labor_id = labor_insumo.labor_id
        AND dup.insumo_id = 8
  );


-- D2.2 Conteo previo: filas duplicadas que ya fueron sumadas.
SELECT COUNT(*) AS filas_a_borrar
FROM labor_insumo dup
WHERE dup.insumo_id = 8
  AND EXISTS (
      SELECT 1
      FROM labor_insumo bueno
      WHERE bueno.labor_id = dup.labor_id
        AND bueno.insumo_id = 1
  );
-- Resultado esperado: 1 (la fila de la labor 20).

DELETE FROM labor_insumo
WHERE insumo_id = 8
  AND EXISTS (
      SELECT 1
      FROM labor_insumo bueno
      WHERE bueno.labor_id = labor_insumo.labor_id
        AND bueno.insumo_id = 1
  );


-- D2.3 Conteo previo: filas del duplicado que no chocan con el bueno.
SELECT COUNT(*) AS filas_a_reapuntar
FROM labor_insumo
WHERE insumo_id = 8;
-- Resultado esperado: 1 (la labor 13).

UPDATE labor_insumo
SET insumo_id = 1
WHERE insumo_id = 8;


-- D2.4 Conteo previo: eliminar el insumo duplicado del catálogo.
SELECT COUNT(*) AS filas_a_borrar
FROM insumos
WHERE insumo_id = 8;
-- Resultado esperado: 1.

DELETE FROM insumos
WHERE insumo_id = 8;

COMMIT;


-- D3. Fusionar Mancozeb (id 9) con Mancozeb (id 3).
BEGIN TRANSACTION;

-- D3.1 Conteo previo al reapuntamiento.
SELECT COUNT(*) AS filas_a_reapuntar
FROM labor_insumo
WHERE insumo_id = 9;
-- Resultado esperado: 1.

UPDATE labor_insumo
SET insumo_id = 3
WHERE insumo_id = 9;


-- D3.2 Conteo previo al borrado del duplicado del catálogo.
SELECT COUNT(*) AS filas_a_borrar
FROM insumos
WHERE insumo_id = 9;
-- Resultado esperado: 1.

DELETE FROM insumos
WHERE insumo_id = 9;

COMMIT;


-- D4. Comprobar que la labor 20 tiene una sola fila de Urea con 100 kg.
SELECT labor_id, insumo_id, cantidad, costo_unitario
FROM labor_insumo
WHERE labor_id = 20
  AND insumo_id = 1;
-- Resultado esperado: una sola fila con cantidad = 100.


-- =====================================================================
-- PARTE E - VERIFICACIÓN Y DEMOS
-- =====================================================================

-- E1. Conteo final de insumos, labores y labor_insumo.
SELECT
    (SELECT COUNT(*) FROM insumos) AS insumos,
    (SELECT COUNT(*) FROM labores) AS labores,
    (SELECT COUNT(*) FROM labor_insumo) AS labor_insumo;
-- Resultado esperado: 7, 19, 16.


-- E2. Verificación de duplicados de labores.
SELECT siembra_id, tipo_labor, fecha, responsable, COUNT(*) AS cantidad
FROM labores
GROUP BY siembra_id, tipo_labor, fecha, responsable
HAVING COUNT(*) > 1;
-- Debe devolver 0 filas.


-- E2. Verificación de duplicados normalizados de insumos.
SELECT LOWER(REPLACE(nombre, ' ', '')) AS nombre_normalizado,
       COUNT(*) AS cantidad
FROM insumos
GROUP BY LOWER(REPLACE(nombre, ' ', ''))
HAVING COUNT(*) > 1;
-- Debe devolver 0 filas.


-- E2. Verificación de fechas rotas.
SELECT labor_id, fecha
FROM labores
WHERE fecha NOT LIKE '____-__-__';
-- Debe devolver 0 filas.


-- E2. Verificación de responsable con el texto 'NULL'.
SELECT labor_id, responsable
FROM labores
WHERE responsable = 'NULL';
-- Debe devolver 0 filas.


-- E2. Verificación de claves foráneas huérfanas.
PRAGMA foreign_key_check;
-- Debe devolver 0 filas.


-- E3. Demostración de RESTRICT.
-- El intento se deja comentado para que el archivo pueda ejecutarse
-- completamente. Debe producir el siguiente error en SQLite:
--
-- BEGIN TRANSACTION;
-- DELETE FROM insumos WHERE insumo_id = 1;
-- -- Error esperado: FOREIGN KEY constraint failed
-- ROLLBACK;
--
-- El error ocurre porque labor_insumo todavía utiliza el insumo 1 y la
-- restricción fue definida como ON DELETE RESTRICT.


-- E4. Experimento del susto: UPDATE sin WHERE, protegido por ROLLBACK.
BEGIN TRANSACTION;

UPDATE labores
SET responsable = 'Pedro Loor';

SELECT COUNT(*) AS durante_la_transaccion
FROM labores
WHERE responsable = 'Pedro Loor';
-- Resultado: 19.
-- Sin el ROLLBACK, las 19 labores habrían quedado con responsable Pedro Loor.

ROLLBACK;

SELECT COUNT(*) AS despues_del_rollback
FROM labores
WHERE responsable = 'Pedro Loor';
-- Resultado: 4.
-- Después del ROLLBACK vuelven a quedar solamente las 4 labores que
-- originalmente tenían responsable Pedro Loor.


-- =====================================================================
-- EXTRA +5 - CONTROL DE CALIDAD ADICIONAL
-- =====================================================================

-- Detectar costos unitarios de labor_insumo que no coinciden con el
-- costo de referencia del catálogo.
SELECT li.labor_id,
       li.insumo_id,
       i.nombre,
       li.costo_unitario AS costo_cargado,
       i.costo_unit_referencia AS costo_referencia
FROM labor_insumo li
JOIN insumos i ON i.insumo_id = li.insumo_id
WHERE li.costo_unitario <> i.costo_unit_referencia
ORDER BY li.labor_id, li.insumo_id;
-- Este control detecta diferencias de costo que no fueron solicitadas
-- para corregir en el ejercicio.


-- =====================================================================
-- CIERRE
-- =====================================================================

-- 1) De los cinco problemas, ¿cuál habría sido el más caro si nadie lo
-- detectaba en seis meses?
--
-- La labor duplicada habría sido uno de los problemas más costosos,
-- porque una misma actividad podría contabilizarse dos veces, afectando
-- costos, inventario, reportes de productividad y decisiones de gestión.
-- Además, si se replicara durante seis meses, el impacto acumulado podría
-- ser mucho mayor que el de un único jornal pendiente.


-- 2) UNIQUE(nombre) existía y aun así entraron dos ureas. ¿Qué restricción
-- habría que agregarle a la tabla para que el motor lo impidiera solo?
--
-- Habría que imponer una unicidad sobre una expresión normalizada, por
-- ejemplo sobre LOWER(REPLACE(nombre, ' ', '')), mediante un índice UNIQUE
-- sobre esa expresión. Así 'Urea 46%' y 'Urea 46 %' serían considerados
-- el mismo nombre para efectos de la restricción.


-- 3) ¿Qué tendría que haber hecho distinto el pasante al cargar, para que
-- nada de esto pasara?
--
-- Debió validar y normalizar los datos antes de insertarlos: fechas en
-- formato ISO, NULL real en lugar de la cadena 'NULL', detección de
-- duplicados mediante claves normalizadas, verificación de labores
-- repetidas y comprobación de jornales pendientes. También debió usar
-- transacciones, controles de calidad y restricciones adecuadas para
-- impedir inconsistencias antes de confirmar la carga.


-- =====================================================================
-- FIN DEL EJERCICIO 4
-- =====================================================================
