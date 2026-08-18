-- =====================================================================
-- CURSO DE SQL  |  CLASE 4  |  EJERCICIO PRACTICO 4
-- Limpiar el lote de abril
-- Nombre: Brando Herrera
-- =====================================================================
-- NOTA: antes de correr este archivo, pegar y ejecutar agrodb_clase4.sql
-- completo, en una pestana nueva. Debe dar 3, 6, 8, 10, 9, 20, 18, 6.
-- =====================================================================


-- =====================================================================
-- PARTE A - DIAGNOSTICO (solo detectar, nada se arregla todavia)
-- =====================================================================

-- A1. Labores cuya fecha no esta en formato ISO
SELECT labor_id, fecha FROM labores WHERE fecha NOT LIKE '____-__-__';
-- Resultado: 1 fila -> labor_id 17, fecha '15/04/2026'

-- A2. Labores donde responsable es el TEXTO 'NULL', no un NULL de verdad
SELECT labor_id, responsable FROM labores WHERE responsable = 'NULL';
-- Resultado: 1 fila -> labor_id 18

-- SELECT COUNT(*) FROM labores WHERE responsable IS NULL;
-- Da 0. Por que la fila 18 no aparece ahi: 'NULL' entre comillas es una
-- cadena de texto de 4 caracteres como cualquier otra ("Marta Ruiz" tiene
-- 10, 'NULL' tiene 4); el motor no la interpreta como "ausencia de valor".
-- IS NULL solo encuentra el marcador especial de SQLite para "no hay
-- dato", que es un concepto distinto de un string que dice la palabra null.

-- A3. Labores cargadas dos veces
SELECT siembra_id, tipo_labor, fecha, responsable,
       COUNT(*) AS veces, GROUP_CONCAT(labor_id) AS labor_ids
FROM labores
GROUP BY siembra_id, tipo_labor, fecha, responsable
HAVING COUNT(*) > 1;
-- Resultado: 1 fila -> siembra 6, 'control fitosanitario', 2026-04-16,
-- Pedro Loor, labor_ids 15,16

-- A4. Insumos duplicados en el catalogo (comparando normalizado)
SELECT LOWER(REPLACE(nombre, ' ', '')) AS normalizado,
       COUNT(*) AS veces, GROUP_CONCAT(insumo_id) AS ids, GROUP_CONCAT(nombre) AS nombres
FROM insumos
GROUP BY normalizado
HAVING COUNT(*) > 1;
-- Resultado: 2 filas -> 'mancozeb' (ids 3 y 9) y 'urea46%' (ids 1 y 8).
-- UNIQUE(nombre) no los detecto porque compara el texto tal cual: 'Urea 46%'
-- y 'Urea 46 %' (con un espacio de mas) son cadenas distintas para SQLite,
-- igual que 'Mancozeb' y 'MANCOZEB' difieren solo en mayusculas. UNIQUE no
-- normaliza espacios ni capitalizacion antes de comparar.

-- A5. Labores con jornal sin cargar
SELECT labor_id, costo_mano_obra, observacion
FROM labores
WHERE costo_mano_obra = 0 AND observacion LIKE '%pendiente%';
-- Resultado: 1 fila -> labor_id 19, observacion 'jornal pendiente de
-- cargar: 145.00'

-- A6. Por que la fecha rota es grave
SELECT labor_id, fecha FROM labores ORDER BY fecha LIMIT 3;
-- Resultado: la primera fila es labor_id 17 con '15/04/2026'. SQLite esta
-- ordenando fecha como TEXTO, caracter por caracter: '1' es menor que '2',
-- asi que '15/04/2026' queda antes que cualquier fecha que empiece con
-- '2026-...', aunque en el calendario real el 15 de abril es POSTERIOR a
-- todas las fechas de marzo y a buena parte de abril. Cualquier reporte
-- ordenado por fecha queda con esa labor mal ubicada, sin ningun error que
-- avise del problema.

SELECT labor_id, strftime('%m', fecha) FROM labores WHERE labor_id = 17;
-- Resultado: strftime devuelve NULL (None). SQLite no reconoce
-- 'dd/mm/aaaa' como fecha valida, asi que cualquier calculo que use
-- strftime, julianday o date() sobre esta fila devuelve NULL en silencio,
-- sin lanzar un error: esa labor simplemente desaparece de cualquier
-- reporte mensual o de cualquier calculo de antiguedad basado en fecha.


-- =====================================================================
-- PARTE B - ARREGLOS SIMPLES  (una sola transaccion)
-- =====================================================================

BEGIN TRANSACTION;

  -- B1. Fecha rota -> formato ISO
  -- SELECT COUNT(*) FROM labores WHERE fecha NOT LIKE '____-__-__';  -> 1
  UPDATE labores SET fecha = '2026-04-15' WHERE labor_id = 17;

  -- B2. 'NULL' de texto -> NULL de verdad
  -- SELECT COUNT(*) FROM labores WHERE responsable = 'NULL';  -> 1
  UPDATE labores SET responsable = NULL WHERE labor_id = 18;

  -- B3. Jornal pendiente -> se carga y se deja constancia
  -- SELECT COUNT(*) FROM labores WHERE costo_mano_obra = 0
  --   AND observacion LIKE '%pendiente%';  -> 1
  UPDATE labores
  SET costo_mano_obra = 145.00,
      observacion = 'jornal cargado el 2026-08-13, corregido de faltante'
  WHERE labor_id = 19;

COMMIT;

-- Reverificacion: las tres deben dar 0 filas
SELECT labor_id, fecha FROM labores WHERE fecha NOT LIKE '____-__-__';        -- 0
SELECT labor_id, responsable FROM labores WHERE responsable = 'NULL';         -- 0
SELECT labor_id FROM labores
WHERE costo_mano_obra = 0 AND observacion LIKE '%pendiente%';                 -- 0


-- =====================================================================
-- PARTE C - LA LABOR DUPLICADA Y EL CASCADE
-- =====================================================================

-- C1. Filas de labor_insumo para la copia que vamos a borrar (labor_id 16,
--     el id mayor de las dos, la que se conserva es la 15)
SELECT COUNT(*) FROM labor_insumo WHERE labor_id = 16;
-- Resultado: 1

BEGIN TRANSACTION;
  -- C2. Borrar solo la copia
  DELETE FROM labores WHERE labor_id = 16;
COMMIT;

-- C3. Volver a contar
SELECT COUNT(*) FROM labor_insumo WHERE labor_id = 16;
-- Resultado: 0. Cambio sin que yo borrara esa fila de labor_insumo a mano:
-- al borrar la labor 16, el motor borro automaticamente sus filas hijas en
-- labor_insumo por el ON DELETE CASCADE de esa clave foranea. No hice un
-- DELETE FROM labor_insumo; fue una consecuencia automatica del DELETE
-- sobre labores.

-- C4. Linea de agrodb_clase4.sql que causa este comportamiento:
--     labor_id INTEGER NOT NULL REFERENCES labores(labor_id) ON DELETE CASCADE,


-- =====================================================================
-- PARTE D - FUSIONAR LOS INSUMOS DUPLICADOS
-- =====================================================================

-- D1. El camino obvio (NO ejecutar en serio, solo para ver el error):
-- UPDATE labor_insumo SET insumo_id = 1 WHERE insumo_id = 8;
--
-- Error real al probarlo:
--   UNIQUE constraint failed: labor_insumo.labor_id, labor_insumo.insumo_id
--
-- Por que falla: labor_insumo tiene PRIMARY KEY (labor_id, insumo_id). La
-- labor 20 ya tiene una fila (20, 1, ...) para la urea buena, Y otra fila
-- (20, 8, ...) para la urea duplicada. Si el UPDATE cambia esa segunda fila
-- de insumo_id 8 a insumo_id 1, quedarian DOS filas con la misma clave
-- primaria (20, 1), lo cual esta prohibido. SQLite aborta el UPDATE
-- COMPLETO al toparse con esa fila (no solo esa fila, la sentencia entera),
-- asi que ni siquiera la fila de la labor 13 (que no chocaba) llega a
-- actualizarse. Si esto se hubiera corrido dentro de un BEGIN, un ROLLBACK
-- deja todo como estaba (y de hecho no hace falta: SQLite ya revirtio la
-- sentencia sola al fallar).

-- D2. La fusion correcta, en orden, en una transaccion
BEGIN TRANSACTION;

  -- Paso 1: donde la labor YA tiene el insumo bueno (1), sumar la
  -- cantidad de la fila duplicada (8)
  UPDATE labor_insumo
  SET cantidad = cantidad + (
      SELECT cantidad FROM labor_insumo AS dup
      WHERE dup.labor_id = labor_insumo.labor_id AND dup.insumo_id = 8
  )
  WHERE insumo_id = 1
    AND labor_id IN (SELECT labor_id FROM labor_insumo WHERE insumo_id = 8);

  -- Paso 2: borrar las filas del duplicado que ya quedaron sumadas
  DELETE FROM labor_insumo
  WHERE insumo_id = 8
    AND labor_id IN (SELECT labor_id FROM labor_insumo WHERE insumo_id = 1);

  -- Paso 3: reapuntar al insumo bueno las filas que NO chocaban
  -- (la labor 13, que solo tenia insumo_id 8)
  UPDATE labor_insumo SET insumo_id = 1 WHERE insumo_id = 8;

  -- Paso 4: recien ahora, borrar del catalogo el insumo duplicado
  DELETE FROM insumos WHERE insumo_id = 8;

COMMIT;

-- D3. Lo mismo con el Mancozeb (bueno = 3, duplicado = 9)
BEGIN TRANSACTION;

  UPDATE labor_insumo
  SET cantidad = cantidad + (
      SELECT cantidad FROM labor_insumo AS dup
      WHERE dup.labor_id = labor_insumo.labor_id AND dup.insumo_id = 9
  )
  WHERE insumo_id = 3
    AND labor_id IN (SELECT labor_id FROM labor_insumo WHERE insumo_id = 9);

  DELETE FROM labor_insumo
  WHERE insumo_id = 9
    AND labor_id IN (SELECT labor_id FROM labor_insumo WHERE insumo_id = 3);

  UPDATE labor_insumo SET insumo_id = 3 WHERE insumo_id = 9;

  DELETE FROM insumos WHERE insumo_id = 9;

COMMIT;

-- D4. Comprobacion: la labor 20 debe tener una sola fila de urea, con 100
SELECT * FROM labor_insumo WHERE labor_id = 20;
-- Resultado: 1 fila -> (20, 1, 100, 0.7)


-- =====================================================================
-- PARTE E - VERIFICACION Y DEMOS
-- =====================================================================

-- E1. Conteo final
SELECT 'insumos' AS tabla, COUNT(*) AS filas FROM insumos
UNION ALL SELECT 'labores', COUNT(*) FROM labores
UNION ALL SELECT 'labor_insumo', COUNT(*) FROM labor_insumo;
-- Resultado: 7, 19, 16 -- coincide exacto con lo esperado

-- E2. Que no quede nada roto
SELECT COUNT(*) FROM labores WHERE fecha NOT LIKE '____-__-__';              -- 0
SELECT COUNT(*) FROM labores WHERE responsable = 'NULL';                     -- 0
SELECT COUNT(*) FROM (
  SELECT siembra_id, tipo_labor, fecha, responsable, COUNT(*) c
  FROM labores GROUP BY siembra_id, tipo_labor, fecha, responsable
  HAVING c > 1
);                                                                            -- 0
SELECT COUNT(*) FROM (
  SELECT LOWER(REPLACE(nombre,' ','')) n, COUNT(*) c
  FROM insumos GROUP BY n HAVING c > 1
);                                                                            -- 0
PRAGMA foreign_key_check;                                                    -- ninguna fila

-- E3. RESTRICT protege el catalogo: intentar borrar un insumo en uso
-- DELETE FROM insumos WHERE insumo_id = 1;
-- Error real al probarlo: FOREIGN KEY constraint failed
-- (la urea sigue en uso en labor_insumo; ON DELETE RESTRICT en esa FK
-- impide borrar el insumo mientras existan filas que lo referencien)

-- E4. El experimento del susto
BEGIN TRANSACTION;
  UPDATE labores SET responsable = 'Pedro Loor';   -- sin WHERE
  SELECT COUNT(*) FROM labores WHERE responsable = 'Pedro Loor';
ROLLBACK;
SELECT COUNT(*) FROM labores WHERE responsable = 'Pedro Loor';
-- Dentro de la transaccion: 19 (TODAS las labores, incluidas las que no
-- eran de Pedro Loor, quedaron reescritas).
-- Despues del ROLLBACK: 5 (vuelve al numero real de labores que de verdad
-- son de Pedro Loor).
-- Sin el BEGIN, ese UPDATE sin WHERE se habria confirmado solo, de forma
-- permanente, borrando para siempre el dato de quien hizo cada una de las
-- otras 14 labores. No habria manera de recuperarlo sin un backup previo.

-- EXTRA (+5): un problema de calidad que no pedian - precios pagados que
-- se alejan del precio de referencia del catalogo (posible error de
-- tipeo o insumo que subio de precio sin actualizar el catalogo)
-- Pregunta: en que aplicaciones el precio pagado se aleja mas de un 1%
-- del precio de referencia del catalogo?
SELECT li.labor_id, i.nombre, li.costo_unitario, i.costo_unit_referencia,
       ROUND(ABS(li.costo_unitario - i.costo_unit_referencia) * 100.0
             / i.costo_unit_referencia, 1) AS desvio_pct
FROM labor_insumo li
JOIN insumos i ON i.insumo_id = li.insumo_id
WHERE i.costo_unit_referencia IS NOT NULL
  AND ABS(li.costo_unitario - i.costo_unit_referencia) / i.costo_unit_referencia > 0.01
ORDER BY desvio_pct DESC;
-- Resultado: 3 filas, las tres de Urea 46% pagada a 0.70 cuando el
-- catalogo dice 0.68 (2.9% de desvio) -- no es un error de carga, pero es
-- una senal de que el precio de referencia del catalogo quedo desactualizado.


-- =====================================================================
-- CIERRE
-- =====================================================================

-- 1) De los cinco problemas, cual habria sido el mas caro si nadie lo
--    detectaba en seis meses? Justifica:
--    El jornal sin cargar (A5/labor 19). Los otros cuatro son problemas de
--    CALIDAD del dato (fechas, duplicados, texto 'NULL'), pero ese es un
--    problema de DINERO real no pagado: 145.00 que a alguien se le deben
--    y que ningun reporte de costos iba a mostrar, porque en la base ese
--    trabajo aparecia con costo 0. En seis meses, multiplicado por cada
--    jornal que un pasante distinto cargue igual de mal, esto se convierte
--    en una diferencia de nomina real, no solo en un dato feo.

-- 2) UNIQUE(nombre) existia y aun asi entraron dos ureas. Que restriccion
--    habria que agregar para que el motor lo impidiera solo?
--    UNIQUE por si solo compara el texto exacto, byte a byte. Habria que
--    poder declarar una restriccion sobre una version NORMALIZADA del
--    nombre (sin espacios y en minusculas), algo como un indice unico
--    sobre una columna calculada sobre LOWER(REPLACE(nombre,' ','')), o
--    directamente exigir en la aplicacion de carga que ese normalizado se
--    calcule antes de insertar y se valide contra los que ya existen.
--    SQLite permite indices UNIQUE sobre expresiones (no solo sobre
--    columnas), por ejemplo:
--      CREATE UNIQUE INDEX idx_insumo_normalizado
--      ON insumos (LOWER(REPLACE(nombre, ' ', '')));
--    (no lo implemento en este archivo porque el enunciado pide solo
--    describirla, no aplicarla).

-- 3) Que tendria que haber hecho distinto el pasante al cargar?
--    Antes de cada INSERT en insumos, buscar primero si ya existia algo
--    parecido (por ejemplo con un SELECT ... WHERE LOWER(REPLACE(nombre,
--    ' ','')) = ...) en vez de escribir el nombre de memoria cada vez.
--    Para las fechas, escribirlas siempre en el mismo formato AAAA-MM-DD
--    desde el origen (la planilla), en vez de dejar que Excel las
--    autoformatee como dd/mm/aaaa. Y para el jornal, no dejar una labor a
--    medio cargar con una nota en observacion "para despues": si el dato
--    no estaba listo, mejor no cargar esa fila todavia que cargarla con
--    costo 0 y una nota que nadie iba a revisar.

-- =====================================================================
-- FIN DEL EJERCICIO
-- =====================================================================
