-- EJERCICIO PRÁCTICO 10: Cinco filas que nadie vio
-- Estudiante: Cortez Axel
-- Motor: SQLite | Entorno: sqliteonline.com

PRAGMA foreign_keys = ON;

-- Limpieza preventiva para ejecución repetible
DROP TABLE IF EXISTS bitacora;
DROP TRIGGER IF EXISTS tr_cosechas_borrado;
DROP TRIGGER IF EXISTS tr_lotes_update_hectareas;
DROP TRIGGER IF EXISTS tr_labor_no_futura;
DROP TRIGGER IF EXISTS tr_cosecha_no_anterior_siembra;
DROP TRIGGER IF EXISTS tr_update_v_lote_finca;


-- PARTE A · ENCONTRAR LAS CINCO

/*
COMENTARIO A1:
Al comparar los controles de carga:
- 'siembras' subió de 10 a 11 (+1 fila)
- 'labores' subió de 19 a 21 (+2 filas)
- 'cosechas' subió de 9 a 11 (+2 filas)
En total entraron 5 filas espurias que no deberían estar en la base.
*/

-- A2. Comparación de totales agregados
SELECT SUM(kg) AS total_kg_cosechas FROM cosechas;
SELECT SUM(kg_total) AS total_kg_vista FROM v_produccion_lote;

/*
COMENTARIO A2:
1. Dan distinto porque 'cosechas' suma todas las filas físicas existentes en la tabla, mientras que 'v_produccion_lote' hace INNER JOIN con 'siembras' y 'lotes', descartando silenciosamente cualquier cosecha huérfana.
2. La diferencia es exactamente de 2400 kg y corresponde a la cosecha con cosecha_id = 10 (apunta a siembra_id = 88, que no existe).
3. Ambos reportes están mal: el primero porque infla la producción sumando kilos de una siembra fantasma, y el segundo porque oculta que existen registros huérfanos que el JOIN filtró.
*/


-- A3. Detección automática de huérfanos por clave foránea
PRAGMA foreign_key_check;

/*
COMENTARIO A3:
El comando devuelve 2 filas:
1) Tabla 'siembras', fila rowid 11 -> viola la FK hacia 'lotes' (apunta a lote_id = 99).
2) Tabla 'cosechas', fila rowid 10 -> viola la FK hacia 'siembras' (apunta a siembra_id = 88).
Entraron porque quien ejecutó la carga masiva puso `PRAGMA foreign_keys = OFF;`, apagando la validación del motor durante los INSERT.
*/


-- A4. Las tres filas que foreign_key_check no ve

-- 1) Cosecha fechada antes de su siembra (Esperado: cosecha 11 del 2025-12-20, siembra del 2026-01-15)
SELECT c.cosecha_id, c.siembra_id, c.fecha AS fecha_cosecha, si.fecha_siembra, c.kg
FROM cosechas c
JOIN siembras si ON c.siembra_id = si.siembra_id
WHERE c.fecha < si.fecha_siembra;

-- 2) Labores duplicadas: misma siembra, tipo y fecha (Esperado: siembra 6, fertilizacion el 2026-03-17, labores 10 y 22)
SELECT siembra_id, tipo_labor, fecha, COUNT(*) AS repeticiones, GROUP_CONCAT(labor_id) AS labores_duplicadas
FROM labores
GROUP BY siembra_id, tipo_labor, fecha
HAVING COUNT(*) > 1;

-- 3) Labores con fecha en el futuro (Esperado: labor 23 del 2027-02-10)
SELECT labor_id, siembra_id, tipo_labor, fecha, responsable, costo_mano_obra
FROM labores
WHERE fecha > DATE('now');


-- A5. Impacto de la cosecha ilógica en el reporte de rendimiento
SELECT * FROM v_produccion_lote WHERE lote = 'L-02' AND finca LIKE 'Finca%';

/*
COMENTARIO A5:
Cambió de 9800 kg (529.73 kg/ha) a 10600 kg (572.97 kg/ha) porque la cosecha 11 sumó 800 kg a la siembra 5 del lote L-02, a pesar de estar fechada un mes antes de que el cultivo fuera sembrado.
*/


-- A6. Conteo de valores NULL en columnas permitidas
-- Esperado: 1, 2, 1, 1
SELECT 
    (SELECT COUNT(*) FROM fincas WHERE responsable IS NULL) AS null_fincas_responsable,
    (SELECT COUNT(*) FROM lotes WHERE tipo_suelo IS NULL) AS null_lotes_tipo_suelo,
    (SELECT COUNT(*) FROM cosechas WHERE destino IS NULL) AS null_cosechas_destino,
    (SELECT COUNT(*) FROM labores WHERE responsable IS NULL) AS null_labores_responsable;

/*
COMENTARIO A6:
Un NULL como dato faltante ocurre cuando la información existía pero no se registró por descuido (por ejemplo, 'labores.responsable' donde una labor de riego se ejecutó pero no anotaron el jornalero a cargo).
Un NULL legítimo representa ausencia real y válida de la entidad en el mundo físico (por ejemplo, 'lotes.tipo_suelo' donde aún no se ha hecho el análisis agronómico de laboratorio, o 'cosechas.destino' para una cosecha de segunda almacenada sin asignar).
*/


-- PARTE B · LO QUE CHECK NO PUEDE

/*
COMENTARIO B1:
- a) Kilos positivos -> SÍ se puede con CHECK (`CHECK (kg > 0)`), evalúa una sola columna de la fila insertada.
- b) Calidad restringida -> SÍ se puede con CHECK (`CHECK (calidad IN ('primera','segunda','descarte'))`), valida valores fijos locales.
- c) Cosecha posterior a siembra -> NO se puede con CHECK estándar, porque requiere consultar la columna 'fecha_siembra' de otra tabla ('siembras').
- d) Labor no futura -> NO se puede con CHECK determinista si usamos `date('now')`, ya que SQLite no permite funciones no deterministas o basadas en tiempo dentro de un CHECK.
*/

-- B2. Prueba empírica del CHECK no determinista
-- CREATE TABLE prueba_check (fecha DATE NOT NULL CHECK (fecha <= date('now')));
-- INSERT INTO prueba_check VALUES ('2026-01-01');
/*
COMENTARIO B2:
SQLite permite crear la tabla sin errores, pero al intentar hacer INSERT arroja:
SQLITE_ERROR: sqlite3 result code 1: non-deterministic functions prohibited in CHECK constraints
Esto confirma que `date('now')` está prohibido dentro de un CHECK.
*/

/*
COMENTARIO B3:
Como CHECK solo tiene visibilidad sobre la fila individual y valores estáticos en memoria, para cruzar datos con otras tablas (regla c) o evaluar funciones temporales dinámicas (regla d) necesitamos Triggers (disparadores).
*/


-- PARTE C · LA BITÁCORA

-- C1. Creación de tabla de auditoría
CREATE TABLE bitacora (
    evento_id   INTEGER PRIMARY KEY,
    tabla       TEXT NOT NULL,
    operacion   TEXT NOT NULL,
    fila_id     INTEGER,
    valor_viejo TEXT,
    valor_nuevo TEXT,
    cuando      TEXT NOT NULL DEFAULT (datetime('now'))
);


-- C2. Trigger de auditoría para borrados en cosechas
CREATE TRIGGER tr_cosechas_borrado
AFTER DELETE ON cosechas
FOR EACH ROW
BEGIN
    INSERT INTO bitacora (tabla, operacion, fila_id, valor_viejo, valor_nuevo, cuando)
    VALUES (
        'cosechas',
        'DELETE',
        OLD.cosecha_id,
        'siembra_id: ' || OLD.siembra_id || ' | fecha: ' || OLD.fecha || ' | kg: ' || OLD.kg || ' | calidad: ' || OLD.calidad,
        NULL,
        datetime('now')
    );
END;


-- C3. Limpieza registrada de cosechas espurias
DELETE FROM cosechas WHERE cosecha_id IN (10, 11);

SELECT operacion, fila_id, valor_viejo FROM bitacora;

/*
COMENTARIO C3:
Aparecen 2 filas en bitácora porque los triggers en SQLite operan en nivel de fila (`FOR EACH ROW`), disparándose una vez por cada registro afectado por el comando; si el DELETE hubiera borrado cincuenta filas, se habrían insertado cincuenta eventos en la bitácora.
*/


-- C4. Depuración total de registros malos y validación de integridad
DELETE FROM labores WHERE labor_id IN (22, 23);
DELETE FROM siembras WHERE siembra_id = 11;

-- Cuadre de control (Esperado: 30550 / 30550 / 3562.30 / 0 filas)
SELECT SUM(kg) AS total_kg_cosechas FROM cosechas;
SELECT SUM(kg_total) AS total_kg_lotes FROM v_produccion_lote;
SELECT ROUND(SUM(costo_total), 2) AS total_costos FROM v_costo_siembra;
PRAGMA foreign_key_check;

/*
COMENTARIO C4:
Los números 30550 kg y $3562.30 son exactamente los totales originales auditados desde la clase 5. 
Sirven de prueba irrefutable de que eliminamos únicamente la basura sin alterar los datos productivos legítimos; si no los hubiéramos anotado, no sabríamos si la base quedó en su estado correcto o si perdimos información real durante la limpieza.
*/


-- C5. Trigger de auditoría para UPDATE en lotes
CREATE TRIGGER tr_lotes_update_hectareas
AFTER UPDATE OF hectareas ON lotes
FOR EACH ROW
BEGIN
    INSERT INTO bitacora (tabla, operacion, fila_id, valor_viejo, valor_nuevo, cuando)
    VALUES (
        'lotes',
        'UPDATE',
        OLD.lote_id,
        'hectareas: ' || OLD.hectareas,
        'hectareas: ' || NEW.hectareas,
        datetime('now')
    );
END;

-- Prueba C5:
UPDATE lotes SET hectareas = 40 WHERE lote_id = 2;
UPDATE lotes SET hectareas = 31 WHERE lote_id = 2;

SELECT * FROM bitacora WHERE tabla = 'lotes';


-- C6. Precisión con UPDATE OF
UPDATE lotes SET tipo_suelo = 'franco' WHERE lote_id = 2;

-- Verificación C6 (Esperado: No se agregaron filas nuevas):
SELECT * FROM bitacora WHERE tabla = 'lotes';

/*
COMENTARIO C6:
Usar `UPDATE OF columna` evita registrar eventos innecesarios en la bitácora cuando se modifican otros atributos (como 'tipo_suelo'), ahorrando espacio en disco y tiempo de procesamiento en tablas transaccionales de alta concurrencia.
*/


-- C7. La limitación del usuario en SQLite embebido
-- SELECT CURRENT_TIMESTAMP; -> Funciona (devuelve la fecha/hora actual)
-- SELECT CURRENT_USER;      -> SQLITE_ERROR: sqlite3 result code 1: no such column: CURRENT_USER
/*
COMENTARIO C7:
1. SQLite es un motor de base de datos embebido sin gestión nativa de sesiones de red ni autenticación de usuarios; por eso no existe una variable de sistema `CURRENT_USER`.
2. La bitácora actual solo registra qué cambió, cuándo y en qué tabla, pero no tiene forma de saber si la lectura se borró por mantenimiento preventivo, por depuración de anomalías o por accidente.
3. Para capturar el usuario y el motivo se requiere:
   a) Que la aplicación que se conecta a la base pase el usuario y la justificación como parámetros en tablas de sesión o variables temporales.
   b) Agregar explícitamente columnas `usuario` y `motivo` en las tablas de la aplicación y exigirlas en la interfaz de usuario antes de ejecutar cualquier DELETE/UPDATE.
*/


-- PARTE D · IMPEDIR Y ESCRIBIR EN UNA VISTA

-- D1. Validación temporal activa mediante BEFORE INSERT y RAISE(ABORT)
CREATE TRIGGER tr_labor_no_futura
BEFORE INSERT ON labores
FOR EACH ROW
BEGIN
    SELECT CASE 
        WHEN NEW.fecha > DATE('now')
        THEN RAISE(ABORT, 'ERROR DE NEGOCIO: No se permiten labores con fechas futuras')
    END;
END;

-- Prueba D1 (Intentar insertar labor en 2030):
-- INSERT INTO labores VALUES (99, 1, 'riego', '2030-01-01', 'Luis Paez', 50.00, NULL);
/*
ERROR OBTENIDO D1:
SQLITE_ERROR: sqlite3 result code 19: ERROR DE NEGOCIO: No se permiten labores con fechas futuras

COMENTARIO D1:
La diferencia es que el trigger de la Parte C es reactivo (`AFTER`), permitiendo la operación y anotando lo ocurrido para auditoría posterior; este trigger es preventivo (`BEFORE`), interceptando la transacción antes de que toque el disco y abortando el cambio con un error.
*/


-- D2. Validación de integridad entre tablas distintas
CREATE TRIGGER tr_cosecha_no_anterior_siembra
BEFORE INSERT ON cosechas
FOR EACH ROW
BEGIN
    SELECT CASE 
        WHEN NEW.fecha < (SELECT fecha_siembra FROM siembras WHERE siembra_id = NEW.siembra_id)
        THEN RAISE(ABORT, 'ERROR DE NEGOCIO: La fecha de cosecha no puede ser anterior a la fecha de siembra')
    END;
END;

-- Prueba D2 (Reintentar insertar cosecha 11 inválida):
-- INSERT INTO cosechas VALUES (11, 5, '2025-12-20', 800, 'primera', 'mercado local');
/*
ERROR OBTENIDO D2:
SQLITE_ERROR: sqlite3 result code 19: ERROR DE NEGOCIO: La fecha de cosecha no puede ser anterior a la fecha de siembra
*/


-- D3. Escritura controlada sobre vistas mediante INSTEAD OF
CREATE TRIGGER tr_update_v_lote_finca
INSTEAD OF UPDATE OF hectareas ON v_lote_finca
FOR EACH ROW
BEGIN
    UPDATE lotes
    SET hectareas = NEW.hectareas
    WHERE lote_id = OLD.lote_id;
END;

-- Prueba D3:
UPDATE v_lote_finca SET hectareas = 99 WHERE lote_id = 1;

-- Verificación:
SELECT lote_id, hectareas FROM lotes WHERE lote_id = 1;

-- Restauración obligatoria a 28.5:
UPDATE v_lote_finca SET hectareas = 28.5 WHERE lote_id = 1;
SELECT lote_id, hectareas FROM lotes WHERE lote_id = 1;

/*
COMENTARIO D3:
La vista no cambió; lo que cambió fue que definimos una regla explícita que intercepta la orden de actualización dirigida a la vista y la traduce en una sentencia UPDATE válida contra la tabla base 'lotes'.
El desarrollador o administrador que escribe el trigger INSTEAD OF es quien decide la semántica de escritura en vistas compuestas.
*/


-- PARTE E · CIERRE

/*
1. Tres cosas que la bitácora no ve:
- Modificaciones directas por consola que desactiven triggers o reemplacen el archivo de base de datos a nivel de sistema operativo (me preocupa seriamente).
- Consultas de lectura SELECT (no me preocupa en operaciones cotidianas, salvo para auditorías de privacidad).
- Intentos fallidos de inserción que fueron rechazados por restricciones CHECK o triggers BEFORE (no me preocupa tanto porque nunca llegaron a persistirse).

2. Trigger vs Índice en dificultad de descubrimiento:
El trigger es mucho más difícil de descubrir porque se ejecuta de manera oculta como un efecto colateral en segundo plano y `EXPLAIN QUERY PLAN` no lo muestra explícitamente en el árbol de operaciones del SELECT, a diferencia de los índices que son visibles en los nodos SCAN/SEARCH.

3. Procedimiento para borrado de datos en producción:
1) Ejecutar primero un SELECT con el WHERE exacto para auditar y documentar las filas afectadas y sus claves primarias.
2) Iniciar una transacción explícita (`BEGIN TRANSACTION;`), aplicar el DELETE verificado y comprobar los totales agregados resultantes.
3) Si los conteos de control coinciden con la bitácora y las métricas de negocio, confirmar con `COMMIT;` o revertir de inmediato con `ROLLBACK;`.
*/


-- EXTRA (+5 PUNTOS): Chequeo de calidad personalizado
-- Regla: Detección de labores registradas fuera del ciclo de vida de la siembra 
-- (labores anteriores a la fecha de siembra)

SELECT 
    la.labor_id,
    la.siembra_id,
    f.nombre AS finca,
    lo.codigo AS lote,
    si.fecha_siembra,
    la.fecha AS fecha_labor,
    la.tipo_labor
FROM labores la
JOIN siembras si ON la.siembra_id = si.siembra_id
JOIN lotes lo ON si.lote_id = lo.lote_id
JOIN fincas f ON lo.finca_id = f.finca_id
WHERE la.fecha < si.fecha_siembra;

/*
ACCIÓN DEL NEGOCIO SI DIERA FILAS:
Si esta consulta devolviera filas, significaría que se imputaron costos de mano de obra y agroquímicos a un cultivo antes de su existencia; el negocio debería aislar esos jornales y reasignarlos a labores de preparación de suelo del lote o corregir la fecha de siembra en el sistema antes de cerrar la contabilidad de la campaña.
*/