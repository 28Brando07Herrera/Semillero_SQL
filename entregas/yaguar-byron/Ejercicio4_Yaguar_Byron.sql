-- =====================================================================
-- CURSO DE SQL  |  AgroDB  |  Ejercicio 4
-- Alumno: Byron Yaguar
-- Fecha: 13-08-2026
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

-- 1) A1. Labores cuya fecha no está en formato ISO AAAA-MM-DD. Pista: NOT LIKE '____-__-__' 
-- (cuatro guiones bajos, guion, dos, guion, dos)
SELECT labor_id, fecha FROM labores
WHERE fecha NOT LIKE '____-__-__' 

-- 2)A2. Labores donde el responsable es el texto 'NULL' en vez de un NULL de verdad. Después corré SELECT COUNT(*) FROM labores WHERE 
-- responsable IS NULL y explicá por qué esa fila no aparece ahí.
SELECT labor_id, responsable
FROM labores
WHERE responsable = 'NULL';
-- Resultado esperado: 1
-- La labor 18 contiene el texto 'NULL', no un NULL real.
-- Por eso no aparece al usar IS NULL.

SELECT COUNT(*)
FROM labores
WHERE responsable IS NULL;
-- Resultado esperado: 0
-- 'NULL' entre comillas es un valor de texto.
-- NULL sin comillas representa ausencia de valor.

-- 3)A3. Labores cargadas dos veces: misma siembra, mismo tipo, misma fecha, mismo responsable. 
-- Pista: GROUP BY de esas cuatro columnas + HAVING COUNT(*) > 1. Mostrá los labor_id con GROUP_CONCAT.
SELECT siembra_id, tipo_labor, fecha, responsable, 
       COUNT(*) AS cantidad,
       GROUP_CONCAT(labor_id) AS labor_ids
FROM labores
GROUP BY siembra_id, tipo_labor, fecha, responsable
HAVING COUNT(*) > 1;

-- 4)A4. Insumos duplicados en el catálogo. Ojo: UNIQUE(nombre) no los detectó porque los textos 
-- son distintos. Tenés que comparar normalizado: sin espacios y en minúsculas.
SELECT LOWER(TRIM(nombre)) AS nombre_normalizado,
       COUNT(*) AS cantidad,
       GROUP_CONCAT(insumo_id) AS insumo_ids,
       GROUP_CONCAT(nombre, ' | ') AS nombres_originales
FROM insumos
GROUP BY LOWER(TRIM(nombre))
HAVING COUNT(*) > 1;

-- 5)A5. Labores con jornal sin cargar (costo en 0 y una observación que dice que quedó pendiente)
SELECT labor_id, costo_mano_obra, observacion
FROM labores
WHERE costo_mano_obra = 0 
AND observacion LIKE '%pendiente%';
  
--A6. Antes de tocar la fecha rota, dejá probado por qué era grave. Corré estas dos y explicá cada resultado como comentario:
SELECT labor_id, fecha FROM labores ORDER BY fecha LIMIT 3;
SELECT labor_id, strftime('%m', fecha) FROM labores WHERE labor_id = 17;
-- A6a. Ordenar labores por fecha
SELECT labor_id, fecha 
FROM labores 
ORDER BY fecha 
LIMIT 3;
-- A6b. Extraer el mes usando strftime()
SELECT labor_id, strftime('%m', fecha) 
FROM labores 
WHERE labor_id = 17;


-- =====================================================================
-- PARTE B - CREACION DE TABLAS
-- =====================================================================
BEGIN TRANSACTION;

-- B1. Pasá la fecha rota a formato ISO
-- SELECT COUNT(*): 1 fila
SELECT COUNT(*) FROM labores 
WHERE fecha NOT LIKE '____-__-__';

UPDATE labores 
SET fecha = '2026-04-15' 
WHERE fecha NOT LIKE '____-__-__';

-- B2. Convertí 'NULL' de texto en NULL verdadero
-- SELECT COUNT(*): 1 fila
SELECT COUNT(*) FROM labores 
WHERE responsable = 'NULL';

UPDATE labores 
SET responsable = NULL 
WHERE responsable = 'NULL';

-- B3. Cargá el jornal pendiente y actualizá observación
-- SELECT COUNT(*): 1 fila
SELECT COUNT(*) FROM labores 
WHERE costo_mano_obra = 0 
  AND observacion LIKE '%pendiente%';

UPDATE labores 
SET costo_mano_obra = 145.00,
    observacion = 'jornal cargado, corregido en limpieza del lote de abril'
WHERE labor_id = 19;

COMMIT;

-- =====================================================================
-- PARTE C - MIGRACION
-- =====================================================================
-- C1. Contar labor_insumo ANTES de borrar labor 16
SELECT COUNT(*) FROM labor_insumo 
WHERE labor_id IN (15, 16);

-- C1 - Resultado esperado: 2 filas
-- Explicación: Labor 15 tiene 1 fila, labor 16 tiene 1 fila

-- C2. Borrar la labor duplicada (en transacción)
BEGIN TRANSACTION;

  -- Contar primero
  SELECT COUNT(*) FROM labores WHERE labor_id = 16;
  -- Resultado esperado: 1
  
  -- Borrar solo la copia
  DELETE FROM labores WHERE labor_id = 16;

COMMIT;

-- C3. Contar labor_insumo DESPUES de borrar labor 16
SELECT COUNT(*) FROM labor_insumo 
WHERE labor_id IN (15, 16);

-- C3 - Resultado esperado: 1 fila (solo de labor 15)
-- Explicación CRÍTICA: El COUNT cambió de 2 a 1 sin que nosotros 
-- borráramos manualmente la fila (16, 9, 18, 5.30) de labor_insumo.
-- ¿Por qué? Porque SQLite ejecutó automáticamente ON DELETE CASCADE.
-- Cuando borramos labor 16 de la tabla labores, SQLite vio que 
-- labor_insumo depende de labores con la cláusula ON DELETE CASCADE.
-- Entonces, automáticamente borró la fila (16, 9, 18, 5.30).
-- Es una reacción en cadena que garantiza integridad referencial.

-- C4. La línea de código que hizo que esto sucediera
-- Búsqueda en datos/agrodb_clase4.sql:
-- 
-- CREATE TABLE labor_insumo (
--     labor_id       INTEGER NOT NULL REFERENCES labores(labor_id) ON DELETE CASCADE,
--                                                                    ^^^^^^^^^^^^^^^^
--     insumo_id      INTEGER NOT NULL REFERENCES insumos(insumo_id) ON DELETE RESTRICT,
--     cantidad       NUMERIC(10,2) NOT NULL CHECK (cantidad > 0),
--     costo_unitario NUMERIC(10,2) NOT NULL CHECK (costo_unitario >= 0),
--     PRIMARY KEY (labor_id, insumo_id)
-- );
--
-- La cláusula ON DELETE CASCADE en labor_id es la culpable.
-- Significa: "Si borro una fila en labores, borra automáticamente
-- todas las filas en labor_insumo que hacen referencia a esa labor"

-- PUNTO DE CONTROL 2 -> ninguna fila
PRAGMA foreign_key_check;

-- =====================================================================
-- PARTE D - FUSIÓN DE INSUMOS DUPLICADOS
-- =====================================================================
-- D1. Probar el camino obvio (y ver que falla)
BEGIN TRANSACTION;
  UPDATE labor_insumo SET insumo_id = 1 WHERE insumo_id = 8;
ROLLBACK;
-- Error esperado: UNIQUE constraint failed: labor_insumo.labor_id, labor_insumo.insumo_id
-- Explicación: Ya existe (20, 1). Dos filas no pueden tener la misma PRIMARY KEY.
-- D2. Resolver correctamente (en orden)
BEGIN TRANSACTION;

  -- D2a. Sumar cantidad donde ya existe
  SELECT COUNT(*) FROM labor_insumo WHERE labor_id = 20 AND insumo_id = 1;
  UPDATE labor_insumo SET cantidad = cantidad + 40 WHERE labor_id = 20 AND insumo_id = 1;
  SELECT cantidad FROM labor_insumo WHERE labor_id = 20 AND insumo_id = 1;
  -- Resultado: 100

  -- D2b. Borrar fila duplicada que ya sumamos
  SELECT COUNT(*) FROM labor_insumo WHERE labor_id = 20 AND insumo_id = 8;
  DELETE FROM labor_insumo WHERE labor_id = 20 AND insumo_id = 8;

  -- D2c. Reapuntar otras labores al insumo bueno
  SELECT COUNT(*) FROM labor_insumo WHERE insumo_id = 8;
  UPDATE labor_insumo SET insumo_id = 1 WHERE insumo_id = 8;

  -- D2d. Borrar insumos duplicados del catálogo
  SELECT COUNT(*) FROM insumos WHERE insumo_id IN (8, 9);
  DELETE FROM insumos WHERE insumo_id IN (8, 9);

COMMIT;

-- D3. Fusionar Mancozeb
BEGIN TRANSACTION;

  SELECT labor_id, insumo_id, cantidad FROM labor_insumo WHERE insumo_id = 9;
  SELECT COUNT(*) FROM labor_insumo WHERE insumo_id = 9;
  UPDATE labor_insumo SET insumo_id = 3 WHERE insumo_id = 9;

COMMIT;

-- D4. Comprobar labor 20
SELECT labor_id, insumo_id, cantidad, costo_unitario 
FROM labor_insumo 
WHERE labor_id = 20;
-- Resultado esperado: 1 fila (20, 1, 100, 0.70)

-- =====================================================================
-- CIERRE
-- =====================================================================

-- 1) De los 5 problemas, ¿cuál fue el más caro en 6 meses?
-- Respuesta: Los insumos duplicados. Rompen TODOS los reportes de costo.

-- 2) ¿Qué restricción evita duplicados normalizados?
-- Respuesta: UNIQUE(LOWER(TRIM(nombre))) o GENERATED ALWAYS AS con UNIQUE.

-- 3) ¿Qué debería haber hecho el pasante?
-- Respuesta: Validar datos ANTES (fechas, espacios, NULL). 
-- Cargar en tabla temporal, verificar, luego mover a producción.
-- Usar transacciones desde el inicio.