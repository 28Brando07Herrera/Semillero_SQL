-- =====================================================================
-- EJERCICIO PRACTICO 10 · CINCO FILAS QUE NADIE VIO
-- =====================================================================
PRAGMA foreign_keys = ON;

-- Limpieza de entorno de trabajo
DROP TABLE IF EXISTS bitacora;
DROP TRIGGER IF EXISTS tr_cosechas_delete_bitacora;
DROP TRIGGER IF EXISTS tr_lotes_update_hectareas;
DROP TRIGGER IF EXISTS tr_labor_no_futura;
DROP TRIGGER IF EXISTS tr_cosecha_valida_fecha;
DROP TRIGGER IF EXISTS tr_instead_update_v_lote_finca;


-- =====================================================================
-- PARTE A · ENCONTRAR LAS CINCO
-- =====================================================================

-- A1 — El control
/*
Respuesta A1:
Crecieron 3 tablas:
- siembras (de 10 paso a 11 filas -> 1 fila nueva)
- labores (de 19 paso a 21 filas -> 2 filas nuevas)
- cosechas (de 9 paso a 11 filas -> 2 filas nuevas)

En total entraron 5 filas nuevas a la base de datos.
(El numero 2 al final representa los indices creados ix_hist_sensor_fecha e ix_hist_fecha).
*/


-- A2 — Los dos totales
SELECT SUM(kg) AS total_cosechas FROM cosechas;
SELECT SUM(kg_total) AS total_vista_lotes FROM v_produccion_lote;

/*
Respuesta A2:
1. Ambos estan bien calculados segun sus estructuras SQL. La diferencia surge porque SUM(kg) suma
   absolutamente todas las filas de la tabla 'cosechas', mientras que 'v_produccion_lote' realiza 
   INNER JOINs navegando por cosechas -> siembras -> lotes -> fincas.
2. La cosecha_id = 10 tiene exactamente 2400 kg. Esta cosecha apunta a la siembra_id = 88, la cual 
   NO existe en la tabla 'siembras'. Por ende, el INNER JOIN de la vista la descarta, pero SUM(kg) directo la incluye.
3. El primer reporte (SUM direct) esta mal porque esta sumando produccion de una siembra fantasma/inexistente.
*/


-- A3 — Los huerfanos, gratis
PRAGMA foreign_key_check;

/*
Respuesta A3:
Filas reportadas por foreign_key_check: 2 filas.
1. Tabla 'siembras', rowid 11 -> apunta a tabla 'lotes' (lote_id 99 no existe).
2. Tabla 'cosechas', rowid 10 -> apunta a tabla 'siembras' (siembra_id 88 no existe).

Entraron a la base de datos debido a que la carga del CSV se realizo ejecutando temporalmente
PRAGMA foreign_keys = OFF;, lo cual desactiva las comprobaciones del motor durante el INSERT.
*/


-- A4 — Lo que foreign_key_check no ve

-- 1. Cosecha fechada antes de la siembra a la que pertenece
SELECT c.* 
FROM cosechas c
JOIN siembras si ON c.siembra_id = si.siembra_id
WHERE c.fecha < si.fecha_siembra;

-- 2. Labores duplicadas: misma siembra, mismo tipo, misma fecha
SELECT siembra_id, tipo_labor, fecha, COUNT(*) AS repetidos, GROUP_CONCAT(labor_id) AS labor_ids
FROM labores
GROUP BY siembra_id, tipo_labor, fecha
HAVING COUNT(*) > 1;

-- 3. Fechas en el futuro en labores
SELECT * 
FROM labores
WHERE fecha > date('now');


-- A5 — Impacto en reporte de produccion
SELECT * FROM v_produccion_lote WHERE lote = 'L-02' AND finca LIKE 'Finca%';

/*
Respuesta A5:
El kg/ha aumento porque se inserto la cosecha_id = 11 (800 kg) asociada a la siembra_id = 5 (lote L-02 de Finca El Guayabo). 
Aunque su fecha (2025-12-20) era imposible por ser anterior a la siembra (2026-01-15), el GROUP BY de la vista 
agrupó matemáticamente esos 800 kg adicionales en el lote, inflando el acumulado de 9800 a 10600 kg.
*/


-- A6 — Los NULL sospechosos
SELECT 
  (SELECT COUNT(*) FROM fincas WHERE responsable IS NULL) AS null_fincas_resp,
  (SELECT COUNT(*) FROM lotes WHERE tipo_suelo IS NULL) AS null_lotes_suelo,
  (SELECT COUNT(*) FROM cosechas WHERE destino IS NULL) AS null_cosechas_destino,
  (SELECT COUNT(*) FROM labores WHERE responsable IS NULL) AS null_labores_resp;

/*
Respuesta A6:
Un NULL como dato faltante representa una omisión indeseada o descuido operativo (e.g., labores.responsable IS NULL 
en la labor 18 donde no se registro quien la ejecuto). 
Un NULL como respuesta legitima representa la ausencia aplicable de un atributo por definicion de negocio 
(e.g., lotes.tipo_suelo IS NULL en lotes no analizados o cosechas.destino IS NULL para excedentes no asignados).
*/


-- =====================================================================
-- PARTE B · LO QUE CHECK NO PUEDE
-- =====================================================================

/*
Respuesta B1:
a) Los kilos son positivos -> SE PUEDE (CHECK (kg > 0)). Revisa valores estaticos de la misma fila.
b) La calidad es 'primera', 'segunda' o 'descarte' -> SE PUEDE (CHECK (calidad IN (...))). Revisa dominio de valores de la fila.
c) Una cosecha no puede ser anterior a su siembra -> NO SE PUEDE mediante CHECK. Requiere comparar contra la columna 'fecha_siembra' de OTRA tabla ('siembras').
d) Una labor no puede tener fecha futura -> NO SE PUEDE en SQLite mediante CHECK si se usa date('now'). SQLite prohíbe funciones no deterministas o de tiempo dinámico en cláusulas CHECK.
*/

-- B2 — Prueba de restriccion dinamica en CHECK
DROP TABLE IF EXISTS prueba_check;
CREATE TABLE prueba_check (
    fecha DATE NOT NULL CHECK (fecha <= date('now'))
);

-- Intento de insercion para validar conducta de SQLite:
-- INSERT INTO prueba_check VALUES ('2030-01-01');
/*
Resultado B2:
 al ejecutar INSERT INTO prueba_check VALUES ('2025-01-01'); o cualquier fecha, SQLite devuelve error:
"Error: non-deterministic use of date() in CHECK"
SQLite bloquea la evaluacion en tiempo de insercion porque date('now') varia segun el dia de ejecucion.
*/

/*
Respuesta B3:
Dado que CHECK solo evalúa de forma estática la fila entrante, para validar reglas complejas entre tablas (Regla c)
o restricciones temporales dinámicas en tiempo real (Regla d) se requiere utilizar TRIGGERS (desencadenadores BEFORE).
*/


-- =====================================================================
-- PARTE C · LA BITACORA
-- =====================================================================

-- C1 — Creacion de tabla bitacora
CREATE TABLE bitacora (
    evento_id   INTEGER PRIMARY KEY,
    tabla       TEXT NOT NULL,
    operacion   TEXT NOT NULL,
    fila_id     INTEGER,
    valor_viejo TEXT,
    valor_nuevo TEXT,
    cuando      TEXT NOT NULL DEFAULT (datetime('now'))
);

-- C2 — Trigger AFTER DELETE en cosechas
CREATE TRIGGER tr_cosechas_delete_bitacora
AFTER DELETE ON cosechas
FOR EACH ROW
BEGIN
    INSERT INTO bitacora (tabla, operacion, fila_id, valor_viejo)
    VALUES (
        'cosechas',
        'DELETE',
        OLD.cosecha_id,
        'siembra_id: ' || OLD.siembra_id || ', fecha: ' || OLD.fecha || ', kg: ' || OLD.kg
    );
END;

-- C3 — Limpieza de cosechas malas
DELETE FROM cosechas WHERE cosecha_id IN (10, 11);
SELECT operacion, fila_id, valor_viejo FROM bitacora;

/*
Respuesta C3:
Hay 2 filas en la bitacora porque el trigger esta definido 'FOR EACH ROW' (se ejecuta de forma individual por cada fila 
afectada por la instruccion). Si el DELETE hubiese borrado 50 filas, la bitacora habria registrado 50 entradas individuales.
*/

-- C4 — Terminar la limpieza
DELETE FROM labores WHERE labor_id IN (22, 23);
DELETE FROM siembras WHERE siembra_id = 11;

-- Verificaciones de integridad:
SELECT SUM(kg) FROM cosechas;                 -- 30550
SELECT SUM(kg_total) FROM v_produccion_lote;  -- 30550
SELECT ROUND(SUM(costo_total),2) FROM v_costo_siembra;  -- 3562.30
PRAGMA foreign_key_check;                     -- 0 filas

/*
Respuesta C4:
Los valores 30550 kg y 3562.30 USD corresponden a la linea base limpia previa a la contaminacion por el CSV. Sirven como 
prueba de control porque garantizan que se eliminaron exactamente los registros ilegitimos sin alterar los datos validos. 
Sin estos puntos de control, no habria certeza de si quedaron datos corruptos o si se borraron filas legitimas por error.
*/

-- C5 — Trigger de UPDATE en lotes
CREATE TRIGGER tr_lotes_update_hectareas
AFTER UPDATE ON lotes
FOR EACH ROW
BEGIN
    INSERT INTO bitacora (tabla, operacion, fila_id, valor_viejo, valor_nuevo)
    VALUES (
        'lotes',
        'UPDATE',
        OLD.lote_id,
        'hectareas: ' || OLD.hectareas,
        'hectareas: ' || NEW.hectareas
    );
END;

UPDATE lotes SET hectareas = 40 WHERE lote_id = 2;
UPDATE lotes SET hectareas = 31 WHERE lote_id = 2;

-- C6 — Optimización con AFTER UPDATE OF
DROP TRIGGER IF EXISTS tr_lotes_update_hectareas;

CREATE TRIGGER tr_lotes_update_hectareas
AFTER UPDATE OF hectareas ON lotes
FOR EACH ROW
BEGIN
    INSERT INTO bitacora (tabla, operacion, fila_id, valor_viejo, valor_nuevo)
    VALUES (
        'lotes',
        'UPDATE',
        OLD.lote_id,
        'hectareas: ' || OLD.hectareas,
        'hectareas: ' || NEW.hectareas
    );
END;

UPDATE lotes SET tipo_suelo = 'franco' WHERE lote_id = 2;

/*
Respuesta C6:
Especificar 'OF hectareas' evita la ejecucion innecesaria del trigger de auditoria cuando se modifican otras columnas de la tabla. 
En tablas con alta frecuencia de actualizacion (ej. cambios frecuentes de observaciones o estados), esto ahorra overhead de I/O y reduce contencion.
*/

-- C7 — La columna que falta
-- SELECT CURRENT_TIMESTAMP; -- Funciona correctamente
-- SELECT CURRENT_USER; -- Genera error

/*
Pegado de error:
"Error: no such column: CURRENT_USER"

Respuesta C7:
1. SQLite es un motor de base de datos embebido sin gestion nativa de usuarios, conexiones en red o sesiones autenticadas; 
   por ende, carece de funciones del sistema para identificar el usuario del SO o la sesion de BD.
2. No, la bitacora actual solo registra el cambio a nivel de motor, pero no captura el contexto de negocio o intencionalidad humana.
3. El 'quien' y el 'motivo' deben proveerse desde:
   a) La capa de aplicacion (backend), pasandolos explícitamente como variables a tablas temporales de contexto o mediante llamadas a procedimientos.
   b) Columnas explicitas de auditoria en la payload de la consulta (ej: incluir 'modificado_por' y 'motivo_cambio' en la tabla afectada).
*/


-- =====================================================================
-- PARTE D · IMPEDIR, Y ESCRIBIR EN UNA VISTA
-- =====================================================================

-- D1 — BEFORE + RAISE para fecha futura en labores
CREATE TRIGGER tr_labor_no_futura
BEFORE INSERT ON labores
FOR EACH ROW
BEGIN
    SELECT CASE 
        WHEN NEW.fecha > date('now') THEN 
            RAISE(ABORT, 'Error: No se permite registrar labores con fecha futura.')
    END;
END;

-- Prueba D1:
-- INSERT INTO labores VALUES (99, 1, 'riego', '2030-01-01', 'Tester', 50.00, NULL);
/*
Error retornado por la prueba:
"Error: Error: No se permite registrar labores con fecha futura."

Comentario D1:
Este trigger es PREVENTIVO (BEFORE): aborta la transaccion E IMPIDE que la fila invalida toque la tabla.
El trigger de la Parte C es AUDITOR (AFTER): no impide la operacion, sino que reacciona despues de realizada para registrar evidencia.
*/

-- D2 — Trigger para impedir cosechas anteriores a la siembra
CREATE TRIGGER tr_cosecha_valida_fecha
BEFORE INSERT ON cosechas
FOR EACH ROW
BEGIN
    SELECT CASE 
        WHEN NEW.fecha < (SELECT fecha_siembra FROM siembras WHERE siembra_id = NEW.siembra_id) THEN
            RAISE(ABORT, 'Error: La fecha de cosecha no puede ser anterior a la fecha de siembra.')
    END;
END;

-- Prueba D2 (Reinsertar cosecha 11 invalida):
-- INSERT INTO cosechas VALUES (11, 5, '2025-12-20', 800, 'primera', 'mercado local');
/*
Error retornado por la prueba:
"Error: Error: La fecha de cosecha no me puede ser anterior a la fecha de siembra."
*/

-- D3 — INSTEAD OF UPDATE en Vistas
CREATE TRIGGER tr_instead_update_v_lote_finca
INSTEAD OF UPDATE ON v_lote_finca
FOR EACH ROW
BEGIN
    UPDATE lotes 
    SET hectareas = NEW.hectareas
    WHERE lote_id = OLD.lote_id;
END;

-- Ejecucion de actualizacion en vista:
UPDATE v_lote_finca SET hectareas = 99 WHERE lote_id = 1;

-- Restauracion del estado inicial requerido:
UPDATE v_lote_finca SET hectareas = 28.5 WHERE lote_id = 1;

/*
Respuesta D3:
La vista no almacena datos por si misma (sigue siendo una consulta guardada). Lo que cambio es que el trigger intercepto 
la sentencia UPDATE dirigida a la vista y ejecuto la reescritura de datos sobre la tabla subyacente ('lotes'). 
El desarrollador/disenador de la base de datos es quien decide la logica de negocio de que significa "escribir" en una vista multisitio.
*/


-- =====================================================================
-- PARTE E · CIERRE
-- =====================================================================

/*
1. Tres cosas que la bitacora no ve:
   a) Consultas SELECT (lecturas de datos): No preocupa para integridades de escritura, pero si para auditorias de privacidad.
   b) Operaciones realizadas con PRAGMA foreign_keys = OFF u omitidas por triggers deshabilitados: Preocupa gravemente, vulnera la auditoria.
   c) La identidad del usuario del sistema operativo/aplicación que ejecuto la sentencia: Preocupa, resta trazabilidad personal.

2. Un trigger es considerablemente MÁS DIFÍCIL de descubrir que un índice. Un indice deja huellas claras en los planes 
   de ejecucion (EXPLAIN QUERY PLAN muestra si se usa SEARCH TABLE o SCAN TABLE), mientras que un trigger ejecuta logica oculta 
   "por detras" produciendo efectos secundarios imprevistos o bloqueos sin salir reflejado explícitamente en el costo directo de la consulta.

3. Procedimiento para borrado de datos en produccion:
   - Identificar exactamente las filas afectadas con consultas SELECT previas y respaldar dichas filas en una tabla temporal de resguardo.
   - Ejecutar el DELETE dentro de una transaccion explicita (BEGIN TRANSACTION) verificando el recuento de filas afectadas.
   - Confirmar que los triggers de auditoria (bitacora) hayan registrado el evento con causa/ticket de soporte antes de hacer COMMIT.
*/


-- =====================================================================
-- EXTRA · CHEQUEO DE CALIDAD PROPIO SOBRE AGRODB
-- =====================================================================

-- Regla de Negocio Propia: "No pueden existir lotes cuya superficie supere la superficie total de la finca a la que pertenecen".
SELECT lo.lote_id, lo.codigo AS lote, lo.hectareas AS ha_lote, f.nombre AS finca, f.hectareas AS ha_finca
FROM lotes lo
JOIN fincas f ON f.finca_id = lo.finca_id
WHERE lo.hectareas > f.hectareas;

/*
Accion del negocio si devolviera filas:
Si la consulta retornara filas, implicaria una inconsistencia fisica grave en el catastro de la empresa. 
El negocio deberia bloquear inmediatamente las proyecciones de rendimiento de esos lotes, notificar al area de agrimensura 
para auditar los limites cartograficos y corregir las hectareas en 'lotes' o 'fincas' segun las escrituras reales.
*/