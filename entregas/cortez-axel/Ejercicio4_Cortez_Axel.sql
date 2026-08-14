-- EJERCICIO PRÁCTICO 4: Limpiar el lote de abril
-- Estudiante: Cortez Axel
-- Motor: SQLite | Entorno: sqliteonline.com

PRAGMA foreign_keys = ON;


-- PARTE A · DIAGNÓSTICO

-- A1. Labores cuya fecha no está en formato ISO AAAA-MM-DD
SELECT labor_id, fecha, tipo_labor, responsable
FROM labores
WHERE fecha NOT LIKE '____-__-__';


-- A2. Labores donde el responsable es el texto 'NULL' en vez de un NULL real
SELECT labor_id, fecha, tipo_labor, responsable
FROM labores
WHERE responsable = 'NULL';

/*
EXPLICACIÓN A2:
La consulta 'WHERE responsable IS NULL' busca valores nulos reales (sin valor en la celda).
La fila con labor_id = 18 contiene una cadena de texto con cuatro caracteres 'N-U-L-L' ('NULL').
Como el motor distingue entre un dato que no está y la cadena 'NULL', la consulta no incluye tal fila.
*/


-- A3. Labores cargadas dos veces (misma siembra, tipo, fecha y responsable)
SELECT siembra_id, tipo_labor, fecha, responsable, GROUP_CONCAT(labor_id) AS labores_duplicadas
FROM labores
GROUP BY siembra_id, tipo_labor, fecha, responsable
HAVING COUNT(*) > 1;


-- A4. Insumos duplicados en el catálogo (comparando normalizado: sin espacios y en minúsculas)
SELECT LOWER(REPLACE(nombre, ' ', '')) AS nombre_normalizado, 
       GROUP_CONCAT(insumo_id) AS ids_duplicados,
       GROUP_CONCAT(nombre) AS nombres_originales,
       COUNT(*) AS total
FROM insumos
GROUP BY LOWER(REPLACE(nombre, ' ', ''))
HAVING COUNT(*) > 1;


-- A5. Labores con jornal sin cargar (costo en 0 y observación pendiente)
SELECT labor_id, tipo_labor, costo_mano_obra, observacion
FROM labores
WHERE costo_mano_obra = 0 
  AND observacion LIKE '%jornal pendiente%';


-- A6. Demostración del impacto del formato de fecha roto
SELECT labor_id, fecha FROM labores ORDER BY fecha LIMIT 3;
/*
RESULTADO Y EXPLICACIÓN:
Devuelve las filas 17 ('15/04/2026'), 8 ('2026-02-14') y 9 ('2026-03-02').
Ocurre porque SQLite ordena las fechas como texto (orden alfabético). Como '1' viene antes que '2',
la fecha '15/04/2026' se posiciona erróneamente antes que cualquier fecha del año '2026'.
*/

SELECT labor_id, strftime('%m', fecha) FROM labores WHERE labor_id = 17;
/*
RESULTADO Y EXPLICACIÓN:
Devuelve labor_id = 17 y NULL.
La función strftime() exige el formato estricto 'YYYY-MM-DD'. Al recibir '15/04/2026',
falla al parsear el texto y da NULL, imposibilitando filtros o agregaciones por mes.
*/


-- PARTE B · ARREGLOS SIMPLES

-- CONTEOS PREVIOS:
-- B1. SELECT COUNT(*) FROM labores WHERE fecha NOT LIKE '____-__-__'; --> Debería ser 1
-- B2. SELECT COUNT(*) FROM labores WHERE responsable = 'NULL'; --> Debería ser 1
-- B3. SELECT COUNT(*) FROM labores WHERE costo_mano_obra = 0 AND observacion LIKE '%jornal pendiente%'; --> Debería ser 1

BEGIN TRANSACTION;

  -- B1. Arreglar formato de fecha del labor_id = 17
  UPDATE labores 
  SET fecha = '2026-04-15' 
  WHERE labor_id = 17 AND fecha NOT LIKE '____-__-__';

  -- B2. Convertir texto 'NULL' en NULL real para labor_id = 18
  UPDATE labores 
  SET responsable = NULL 
  WHERE responsable = 'NULL';

  -- B3. Cargar el jornal pendiente (145.00) y actualizar observación en labor_id = 19
  UPDATE labores 
  SET costo_mano_obra = 145.00,
      observacion = 'Jornal cargado y corregido (originalmente pendiente)'
  WHERE labor_id = 19 
    AND costo_mano_obra = 0 
    AND observacion LIKE '%jornal pendiente%';

COMMIT;

-- VERIFICACIÓN DE LA PARTE B (Todas deben devolver 0 filas)
SELECT COUNT(*) AS a1_restantes FROM labores WHERE fecha NOT LIKE '____-__-__';
SELECT COUNT(*) AS a2_restantes FROM labores WHERE responsable = 'NULL';
SELECT COUNT(*) AS a5_restantes FROM labores WHERE costo_mano_obra = 0 AND observacion LIKE '%jornal pendiente%';


-- PARTE C · LA LABOR DUPLICADA Y EL CASCADE

-- C1. Conteo de filas en labor_insumo para la labor duplicada (labor_id = 16)
SELECT COUNT(*) AS filas_labor_16_antes FROM labor_insumo WHERE labor_id = 16;
-- Conteo previo: 1 fila registrada para labor_id = 16.

BEGIN TRANSACTION;

  -- C2. Borrar solo la copia duplicada (la del ID mayor: 16)
  DELETE FROM labores WHERE labor_id = 16;

COMMIT;

-- C3. Volver a contar en labor_insumo para labor_id = 16
SELECT COUNT(*) AS filas_labor_16_despues FROM labor_insumo WHERE labor_id = 16;
-- Conteo posterior: 0 filas.

/*
EXPLICACIÓN C3:
La fila vinculada a labor_id = 16 en la tabla 'labor_insumo' desapareció automáticamente sin lanzar
un DELETE explícito sobre ella gracias a la cláusula ON DELETE CASCADE definida en la clave foránea.
*/

/*
C4. Línea de agrodb_clase4.sql que causó este comportamiento:
labor_id INTEGER NOT NULL REFERENCES labores(labor_id) ON DELETE CASCADE,
*/

-- PARTE D · FUSIONAR LOS INSUMOS DUPLICADOS

/*
D1. ERROR OBTENIDO AL INTENTAR UPDATE DIRECTO EN LA UREA:
UPDATE labor_insumo SET insumo_id = 1 WHERE insumo_id = 8;

Mensaje de error en SQLite:
SQLITE_ERROR: sqlite3 result code 19: UNIQUE constraint failed: labor_insumo.labor_id, labor_insumo.insumo_id

EXPLICACIÓN D1:
La tabla 'labor_insumo' posee una clave primaria compuesta PRIMARY KEY (labor_id, insumo_id).
Como la labor_id = 20 ya tenía cargada una fila con el insumo_id = 1, al intentar cambiar el insumo_id = 8 a 1
en la misma labor, el motor detecta la duplicación de la tupla (20, 1) e interrumpe el proceso por violar la restricción.
*/

-- D2. Fusión correcta de la Urea (Insumo 8 hacia Insumo 1)
-- Conteos previos:
-- SELECT COUNT(*) FROM labor_insumo WHERE insumo_id = 8; --> Debería ser 2 (labores 13 y 20)

BEGIN TRANSACTION;

  --1: En la labor 20 (donde chocan ambos IDs), sumar la cantidad del duplicado (40) al primario (60)
  UPDATE labor_insumo
  SET cantidad = cantidad + (
      SELECT cantidad FROM labor_insumo WHERE labor_id = 20 AND insumo_id = 8
  )
  WHERE labor_id = 20 AND insumo_id = 1;

  -- Step 2: Eliminar la fila duplicada de la labor 20 que ya fue sumada
  DELETE FROM labor_insumo WHERE labor_id = 20 AND insumo_id = 8;

  -- Step 3: Reapuntar al insumo bueno (1) las filas que no chocaban (labor 13)
  UPDATE labor_insumo SET insumo_id = 1 WHERE insumo_id = 8;

  -- Step 4: Eliminar el insumo duplicado (8) del catálogo
  DELETE FROM insumos WHERE insumo_id = 8;

COMMIT;


-- D3. Fusión del Mancozeb (Insumo 9 hacia Insumo 3)
-- Conteos previos:
-- SELECT COUNT(*) FROM labor_insumo WHERE insumo_id = 9; --> Debería ser 1 (labor 15)

BEGIN TRANSACTION;

  -- No genera conflicto de clave primaria en la labor 15 porque no tenía el insumo 3 cargado previamente.
  UPDATE labor_insumo SET insumo_id = 3 WHERE insumo_id = 9;

  -- Eliminar el insumo duplicado (9) del catálogo
  DELETE FROM insumos WHERE insumo_id = 9;

COMMIT;


-- D4. Comprobación: La labor 20 debe tener una sola fila de urea con cantidad 100
SELECT labor_id, insumo_id, cantidad, costo_unitario 
FROM labor_insumo 
WHERE labor_id = 20;


-- PARTE E · VERIFICACIÓN Y DEMOS

-- E1. Conteo final esperado: 7 insumos, 19 labores, 16 labor_insumo
SELECT 'insumos' AS tabla, COUNT(*) AS total FROM insumos
UNION ALL
SELECT 'labores', COUNT(*) FROM labores
UNION ALL
SELECT 'labor_insumo', COUNT(*) FROM labor_insumo;


-- E2. Verificación de integridad de claves foráneas
PRAGMA foreign_key_check;


-- E3. Demostración de protección RESTRICT en el catálogo
-- Intentar borrar el insumo 'Urea 46%' (insumo_id = 1), el cual está asignado a varias labores:
-- DELETE FROM insumos WHERE insumo_id = 1;
/*
ERROR OBTENIDO:
SQLITE_ERROR: sqlite3 result code 1819: FOREIGN KEY constraint failed

EXPLICACIÓN E3:
La tabla 'labor_insumo' define su FK apuntando a 'insumos' con 'ON DELETE RESTRICT'.
Esto prohíbe de forma estricta la eliminación de cualquier registro del catálogo que se encuentre en uso.
*/


-- E4. Experimento del susto (Uso de transacciones de prueba)
BEGIN TRANSACTION;
  UPDATE labores SET responsable = 'Pedro Loor'; -- UPDATE destructivo sin cláusula WHERE
  SELECT COUNT(*) AS total_pedro_loor_temp FROM labores WHERE responsable = 'Pedro Loor';
ROLLBACK;

SELECT COUNT(*) AS total_pedro_loor_real FROM labores WHERE responsable = 'Pedro Loor';

/*
RESULTADOS Y EXPLICACIÓN E4:
- Número dentro del BEGIN (temporal): 19
- Número después del ROLLBACK (real): 3
- ¿Qué habría pasado sin el BEGIN?: Se habrían sobrescrito de forma irrecuperable los nombres de los 
  responsables de las 19 labores existentes en la base de datos por 'Pedro Loor'.
*/

-- CIERRE

/*
1. ¿Cuál de los cinco problemas habría sido el más caro en 6 meses?
El problema de las fechas en formato no estándar ('15/04/2026'). En sistemas agrícolas, los reportes financieros 
y contables operan agregando costos mediante rangos mensuales o trimestrales usando funciones de fecha como strftime/BETWEEN. 
Las labores con fechas mal estructuradas quedan excluidas de las agregaciones automáticas, ocultando desembolsos operativos 
reales y sesgando la rentabilidad por hectárea calculada por la gerencia.

2. ¿Qué restricción adicional habría impedido duplicados como "Urea 46 %" o "MANCOZEB"?
Podria ser una restricción UNIQUE basada en una expresión o índice funcional sobre el nombre normalizado:
CREATE UNIQUE INDEX idx_insumos_nombre_limpio ON insumos (LOWER(REPLACE(nombre, ' ', '')));
De esta forma, la base de datos convierte el texto a minúsculas y remueve espacios antes de evaluar la unicidad.

3. ¿Qué tendría que haber hecho distinto el pasante?
El pasante debió procesar los datos previa carga mediante un script de validación (staging) o un proceso ETL que sanitizara 
los textos (TRIM, UPPER/LOWER), convirtiera fechas al estándar ISO (YYYY-MM-DD), mapeara las claves de insumos contra el catálogo 
existente y rechazara registros sin costo cargado o duplicados.
*/

-- ============================================================================
-- EXTRA (+5 PUNTOS): Detección de un problema de calidad no pedido
-- Detectar labores registradas sobre siembras cuyo estado es 'cosechado' o 'perdido'
-- ============================================================================

SELECT l.labor_id, l.fecha, l.tipo_labor, s.siembra_id, s.estado AS estado_siembra
FROM labores l
JOIN siembras s ON l.siembra_id = s.siembra_id
WHERE s.estado IN ('cosechado', 'perdido');

/*
EXPLICACIÓN EXTRA:
Esta consulta detecta una falla de regla de negocio en el ingreso de datos porque se están 
registrando y cobrando labores de campo (como fertilizaciones o siembras) en lotes 
donde la siembra ya figura como 'cosechado' (siembra_id 5) o 'perdido' (siembra_id 9). 
El sistema debería prohibir el ingreso de nuevas labores si la siembra no está 'en curso' o 'en produccion'.
*/