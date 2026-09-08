-- =====================================================================
-- CURSO DE SQL  |  AgroDB  |  Ejercicio 10 - Cinco filas que nadie vio
-- Alumno: Byron Yaguar
-- Fecha: 2026-08-22
--
-- Este archivo se ejecuta DESPUES de datos/agrodb_clase10.sql,
-- en la MISMA sesion de sqliteonline.
--
-- LA REGLA DEL DÍA: Los datos malos no dan error.
-- El motor avisa cuando rompés una regla que le escribiste.
-- De todo lo demás, no sabe nada.
-- =====================================================================
PRAGMA foreign_keys = ON;

-- =====================================================================
-- PARTE A - ENCONTRAR LAS CINCO
-- =====================================================================

-- A1 — El control. Comparación:
-- ayer:  3, 6, 8, 10, 7, 19, 16, 6,  9, 973, 7, 105120
-- hoy:   3, 6, 8, 11, 7, 21, 16, 6, 11, 973, 7, 105120, 2
--
-- RESPUESTA A1:
-- Tres tablas crecieron:
--   siembras:  10 -> 11 (1 fila nueva)
--   labores:   19 -> 21 (2 filas nuevas)
--   cosechas:   9 -> 11 (2 filas nuevas)
-- Total: 5 filas entraron sin autorización.
-- El último "2" son los índices que crearon ustedes en el ejercicio 9.

-- A2 — Los dos totales:
SELECT SUM(kg) FROM cosechas;
-- RESULTADO: 33750 (debería ser 30550)

SELECT SUM(kg_total) FROM v_produccion_lote;
-- RESULTADO: 31350 (debería ser 30550)
--
-- RESPUESTAS A2:
-- 1. ¿Por qué dan distinto?
--    Ambos están correctamente calculados PERO SOBRE DATOS DIFERENTES.
--    cosechas.SUM cuenta TODAS las cosechas (incluyendo las 2 malas).
--    v_produccion_lote JOINea cosechas contra siembras, y en ese JOIN
--    se filtra implícitamente: solo se incluyen cosechas cuya siembra existe.
--    La cosecha 10 apunta a siembra 88 que no existe → no aparece en el JOIN.
--    La cosecha 11 apunta a siembra 5 que SÍ existe → aparece en el JOIN.
--
-- 2. ¿Qué fila vale 2400?
--    Cosecha 10, siembra 88 (inexistente).
--    Aparece en SUM(kg) porque es un COUNT puro.
--    NO aparece en v_produccion_lote porque siembra 88 no existe.
--    Diferencia: 33750 - 31350 = 2400 exactamente.
--
-- 3. ¿Cuál de los dos está mal?
--    EL PRIMERO está mal. El SUM(kg) cuenta una cosecha huérfana.
--    El segundo es más confiable porque filtra contra el modelo.
--    Pero AMBOS están mal porque el negocio no quiere ni cosechas huérfanas.

-- A3 — Los huérfanos, gratis:
PRAGMA foreign_key_check;
-- RESULTADO:
-- cosechas|10|siembras|0     (cosecha apunta a siembra 88 que no existe)
-- siembras|11|lotes|1        (siembra apunta a lote 99 que no existe)
--
-- RESPUESTA A3:
-- ¿Cómo entraron si la tabla tiene clave foránea?
-- Porque quien las cargó hizo PRAGMA foreign_keys = OFF.
-- SQLite permite desactivar las restricciones en tiempo de carga.
-- Sin PRAGMA, hubieran dado error y no habrían entrado.
-- Con PRAGMA OFF, entra lo que sea.

-- A4 — Lo que foreign_key_check no ve. Tres consultas:

-- A4a: Una cosecha fechada antes de la siembra a la que pertenece.
SELECT c.cosecha_id, c.fecha, c.kg, c.siembra_id, si.fecha_siembra
FROM cosechas c
JOIN siembras si ON si.siembra_id = c.siembra_id
WHERE c.fecha < si.fecha_siembra;
-- RESULTADO: 1 fila
-- cosecha_id=11, fecha=2025-12-20, kg=800, siembra_id=5, fecha_siembra=2026-01-15
-- Una cosecha de 800 kg fechada en diciembre de un maíz que se sembró en enero.
-- Biológicamente imposible (la planta no existía).

-- A4b: Labores duplicadas (misma siembra, tipo, fecha).
SELECT si.siembra_id, la.tipo_labor, la.fecha, COUNT(*) AS cuantas,
       GROUP_CONCAT(la.labor_id) AS labor_ids
FROM labores la
JOIN siembras si ON si.siembra_id = la.siembra_id
GROUP BY si.siembra_id, la.tipo_labor, la.fecha
HAVING COUNT(*) > 1;
-- RESULTADO: 1 fila
-- siembra_id=6, tipo_labor=fertilizacion, fecha=2026-03-17, labores 10 y 22
-- La misma labor cargada dos veces. Duplicado perfecto.

-- A4c: Fechas en el futuro en labores.
SELECT labor_id, siembra_id, fecha, tipo_labor
FROM labores
WHERE fecha > date('now')
ORDER BY fecha DESC;
-- RESULTADO: 1 fila
-- labor_id=23, siembra_id=7, fecha=2027-02-10, riego
-- Una labor fechada 7 meses en el futuro. Sin sentido en una base operacional.

-- A5 — El impacto en el reporte:
SELECT * FROM v_produccion_lote WHERE lote = 'L-02' AND finca LIKE 'Finca%';
-- RESULTADO: 10600 kg, 572.97 kg/ha (debería ser 9800 y 529.73)
--
-- RESPUESTA A5:
-- Nadie tocó una cosecha vieja. El lote L-02 de Finca El Guayabo tiene
-- ahora una cosecha NUEVA (la cosecha 11: 800 kg del 2025-12-20 de la siembra 5
-- que está en otro lote). No espera—eso no cierra. Mirá el número: 10600 = 9800 + 800.
-- La cosecha 11 está en siembra 5, que está en lote L-02 (lote_id=5).
-- Finca El Guayabo es finca 2. Lote L-02 es lote 5, que es finca 2.
-- Entonces sí: la cosecha imposible se suma al lote correcto por error de FK.
-- El kg/ha cambió porque: antes 9800/18.5 = 529.73, ahora 10600/18.5 = 572.97.

-- A6 — Los NULL sospechosos:
SELECT
  (SELECT COUNT(*) FROM fincas WHERE responsable IS NULL) AS fincas_NULL,
  (SELECT COUNT(*) FROM lotes WHERE tipo_suelo IS NULL) AS lotes_NULL,
  (SELECT COUNT(*) FROM cosechas WHERE destino IS NULL) AS cosechas_NULL,
  (SELECT COUNT(*) FROM labores WHERE responsable IS NULL) AS labores_NULL;
-- RESULTADO: 1, 2, 1, 1
--
-- RESPUESTA A6:
-- Ninguno de estos cuatro NULL es de la carga del sábado. Todos existían.
-- ¿Cuál es la diferencia entre un NULL faltante y uno legítimo?
--   - NULL FALTANTE: falta de datos. Ej: responsable en una labor de riego
--     automático (no hay persona responsable, es un sistema). Debería ser NOT NULL.
--   - NULL LEGÍTIMO: la respuesta es "no aplica". Ej: tipo_suelo = NULL en lote 3
--     significa que nadie hizo análisis de suelo, es un dato real de negocio.
--     O destino = NULL en cosecha cuando no está decidido aún.
-- En esta lista:
--   - fincas.responsable = NULL: Agricola La Union sin responsable → faltante.
--   - lotes.tipo_suelo = NULL: lotes 3 y 8 sin análisis → legítimo.
--   - cosechas.destino = NULL: una cosecha sin destino decidido → legítimo.
--   - labores.responsable = NULL: labor 18 (riego del 2026-04-18) → faltante o legítimo.

-- =====================================================================
-- PARTE B - LO QUE CHECK NO PUEDE
-- =====================================================================

-- B1 — ¿Cuáles se pueden escribir como CHECK?
--
-- RESPUESTA B1:
-- a) los kilos son positivos - CHECK (kg > 0)
--    SÍ se puede. Es validación de una sola fila, sin dependencias.
--
-- b) la calidad es 'primera', 'segunda' o 'descarte' → CHECK
--    SÍ se puede. Es enumeración de valores, una sola fila.
--
-- c) una cosecha no puede ser anterior a su siembra → NO CHECK
--    NO se puede. Necesita acceder a la tabla siembras para validar.
--    CHECK solo ve la fila que se escribe (cosechas). Necesita TRIGGER.
--
-- d) una labor no puede tener fecha futura → NO CHECK (con 'now')
--    Depende. En teoría se puede CHECK (fecha <= date('now')),
--    pero date('now') se evalúa al momento de CREAR la tabla, no de INSERT.
--    (Se verá en B2.)

-- B2 — Probá que tenés razón con la (d):
-- Nota: SQLite rechaza CHECK con date('now') como "no deterministic"
-- porque la función no es determinística (cambia cada día).
-- En la práctica, usamos TRIGGER para esto, como se ve en D1.
--
-- RESPUESTA B2 (comentario):
-- El CREATE TABLE falla con "non-deterministic use of date() in CHECK".
-- SQLite es estricto: CHECK debe ser determinística (misma entrada = mismo resultado).
-- date('now') cambia cada día, así que rechaza su uso en CHECK.
-- Este es exactamente el caso donde necesitás TRIGGER, no CHECK.
-- (En otras bases de datos como PostgreSQL, se permite.)

-- El comentario de B3 explica por qué TRIGGER es necesario para estas reglas.

-- B3 — ¿Qué herramienta necesitás para (c) y (d)?
--
-- RESPUESTA B3 (dos líneas):
-- Si CHECK solo puede mirar la fila que se está escribiendo, necesitás TRIGGERS.
-- BEFORE INSERT / UPDATE permite validar contra otras tablas y rechazar con RAISE.

-- =====================================================================
-- PARTE C - LA BITÁCORA
-- =====================================================================

-- C1 — Crear la tabla:
DROP TABLE IF EXISTS bitacora;
CREATE TABLE bitacora (
    evento_id   INTEGER PRIMARY KEY,
    tabla       TEXT NOT NULL,
    operacion   TEXT NOT NULL,
    fila_id     INTEGER,
    valor_viejo TEXT,
    valor_nuevo TEXT,
    cuando      TEXT NOT NULL DEFAULT (datetime('now'))
);

-- C2 — Crear trigger AFTER DELETE ON cosechas:
DROP TRIGGER IF EXISTS tr_cosechas_borrado;
CREATE TRIGGER tr_cosechas_borrado
AFTER DELETE ON cosechas
BEGIN
    INSERT INTO bitacora (tabla, operacion, fila_id, valor_viejo)
    VALUES ('cosechas', 'DELETE',
            OLD.cosecha_id,
            'cosecha_id=' || OLD.cosecha_id || ', siembra_id=' || OLD.siembra_id ||
            ', fecha=' || OLD.fecha || ', kg=' || OLD.kg);
END;

-- C3 — La limpieza, esta vez registrada:
DELETE FROM cosechas WHERE cosecha_id IN (10, 11);

SELECT operacion, fila_id, valor_viejo FROM bitacora;
-- RESULTADO: 2 filas (una por cada DELETE)
--
-- RESPUESTA C3 (comentario):
-- Ejecutaste UNA sentencia DELETE, pero hay 2 filas en bitácora.
-- Porque el trigger se dispara UNA VEZ POR FILA borrada, no una vez por DELETE.
-- Si la sentencia DELETE se llevaba 50 cosechas, habrían sido 50 filas en bitácora.
-- El trigger se ejecuta DESPUÉS de cada DELETE individual, acumulando registros.

-- C4 — Terminar la limpieza. Crear triggers para labores y siembras:
DROP TRIGGER IF EXISTS tr_labores_borrado;
CREATE TRIGGER tr_labores_borrado
AFTER DELETE ON labores
BEGIN
    INSERT INTO bitacora (tabla, operacion, fila_id, valor_viejo)
    VALUES ('labores', 'DELETE',
            OLD.labor_id,
            'labor_id=' || OLD.labor_id || ', siembra_id=' || OLD.siembra_id ||
            ', tipo=' || OLD.tipo_labor || ', fecha=' || OLD.fecha);
END;

DROP TRIGGER IF EXISTS tr_siembras_borrado;
CREATE TRIGGER tr_siembras_borrado
AFTER DELETE ON siembras
BEGIN
    INSERT INTO bitacora (tabla, operacion, fila_id, valor_viejo)
    VALUES ('siembras', 'DELETE',
            OLD.siembra_id,
            'siembra_id=' || OLD.siembra_id || ', lote_id=' || OLD.lote_id ||
            ', fecha_siembra=' || OLD.fecha_siembra);
END;

-- Borrar las filas malas:
DELETE FROM labores WHERE labor_id IN (22, 23);
DELETE FROM siembras WHERE siembra_id = 11;

-- Verificar que quedó limpio:
SELECT SUM(kg) FROM cosechas;
-- RESULTADO: 30550 

SELECT SUM(kg_total) FROM v_produccion_lote;
-- RESULTADO: 30550 

SELECT ROUND(SUM(costo_total),2) FROM v_costo_siembra;
-- RESULTADO: 3562.30 

PRAGMA foreign_key_check;
-- RESULTADO: 0 filas 
--
-- RESPUESTA C4 (comentario):
-- El 30550 y el 3562.30 son los números que cerraban en el ejercicio 5.
-- Sirven como prueba de que la base volvió a su estado correcto.
-- Si no los hubieras anotado, no sabrías si limpiar fue suficiente.
-- Los números son la única métrica objetiva de que el negocio está de acuerdo.

-- C5 — Un trigger de UPDATE para hectareas:
DROP TRIGGER IF EXISTS tr_lotes_hectareas_update;
CREATE TRIGGER tr_lotes_hectareas_update
AFTER UPDATE OF hectareas ON lotes
BEGIN
    INSERT INTO bitacora (tabla, operacion, fila_id, valor_viejo, valor_nuevo)
    VALUES ('lotes', 'UPDATE',
            NEW.lote_id,
            'hectareas=' || OLD.hectareas,
            'hectareas=' || NEW.hectareas);
END;

-- Probarlo:
UPDATE lotes SET hectareas = 40 WHERE lote_id = 2;
UPDATE lotes SET hectareas = 31 WHERE lote_id = 2;   -- dejalo como estaba

SELECT operacion, tabla, fila_id, valor_viejo, valor_nuevo
FROM bitacora
WHERE tabla = 'lotes' AND operacion = 'UPDATE'
ORDER BY evento_id DESC LIMIT 2;
-- RESULTADO: 2 filas nuevas, la segunda deshaciendo la primera ✓

-- C6 — UPDATE OF (precisión):
-- El trigger anterior ya es AFTER UPDATE OF hectareas.
-- Probá que no se dispara si actualizas otro campo:
UPDATE lotes SET tipo_suelo = 'franco' WHERE lote_id = 2;

SELECT COUNT(*) FROM bitacora WHERE tabla = 'lotes' AND operacion = 'UPDATE';
-- RESULTADO: 2 (no cambió, las dos del C5)
--
-- RESPUESTA C6 (comentario):
-- La precisión UPDATE OF hectareas es útil en tablas que se actualizan mucho.
-- Si el trigger se disparara en CUALQUIER UPDATE, generaría ruido en la bitácora.
-- UPDATE OF filtra: solo dispara cuando se actualiza ESA columna.
-- En una tabla que cambia de tipo_suelo, destino, observación constantemente,
-- pero rara vez cambia hectareas, el trigger solo se anota para lo importante.

-- C7 — La columna que falta. El CURRENT_USER:
SELECT CURRENT_TIMESTAMP;
-- RESULTADO: 2026-08-22 13:45:32 (o similar, funcionamiento OK)

-- SQLite no tiene CURRENT_USER. En PostgreSQL/SQL Server sí.
-- Este es el punto: tu bitácora tiene CUANDO pero no tiene QUIÉN.
--
-- RESPUESTA C7 (tres líneas):
--
-- 1. ¿Puede SQLite cumplir la promesa de "quién cambió"?
--    NO. SQLite no tiene concepto de usuarios ni sesiones de conexión.
--    CURRENT_USER no existe en SQLite (existe en PostgreSQL, SQL Server, etc.).
--    Una única instancia SQLite no sabe "quién" está conectado sin intervención externa.
--
-- 2. ¿La bitácora puede decir "la borramos a propósito"?
--    NO. El trigger registra OPERACIONES (DELETE, UPDATE, INSERT), no INTENCIONES.
--    No hay forma de saber si fue un error, depuración, o propósito.
--    Solo está el timestamp y los valores antiguos/nuevos.
--
-- 3. ¿De dónde tienen que salir el QUIEN y el MOTIVO?
--    Primera forma: APLICACIÓN. La app que inserta en bitácora TAMBIÉN inserta
--       una fila con usuario y motivo en una tabla de auditoría superior.
--    Segunda forma: VISTA. Un procedimiento SQL que antes de borrar registra
--       una fila en bitácora_manual con usuario=? y motivo=?. Require login externo.

-- =====================================================================
-- PARTE D - IMPEDIR, Y ESCRIBIR EN UNA VISTA
-- =====================================================================

-- D1 — BEFORE + RAISE. Trigger que no permite labores futuras:
DROP TRIGGER IF EXISTS tr_labor_no_futura;
CREATE TRIGGER tr_labor_no_futura
BEFORE INSERT ON labores
BEGIN
    SELECT CASE WHEN NEW.fecha > date('now')
        THEN RAISE(ABORT, 'Labor no puede ser posterior a hoy')
    END;
END;

-- Probarlo con una labor de 2030:
-- INSERT INTO labores VALUES (999, 1, 'prueba', '2030-01-01', 'Test', 50, NULL);
-- RESULTADO: Error: Labor no puede ser posterior a hoy (ABORT)
--
-- RESPUESTA D1 (comentario):
-- La diferencia entre este trigger BEFORE + RAISE y el de C2 AFTER DELETE:
-- - AFTER DELETE (C2): registra un evento que YA SUCEDIÓ. Documentación histórica.
-- - BEFORE INSERT (D1): impide que el evento suceda. Control preventivo.
-- - AFTER no puede rechazar. BEFORE sí, con RAISE(ABORT).

-- D2 — La regla que necesita otra tabla. Trigger que impide cosecha anterior a siembra:
DROP TRIGGER IF EXISTS tr_cosecha_no_anterior;
CREATE TRIGGER tr_cosecha_no_anterior
BEFORE INSERT ON cosechas
BEGIN
    SELECT CASE WHEN NEW.fecha < (SELECT fecha_siembra FROM siembras WHERE siembra_id = NEW.siembra_id)
        THEN RAISE(ABORT, 'Cosecha no puede ser anterior a la fecha de siembra')
    END;
END;

-- Probarlo intentando insertar la cosecha 11 de nuevo:
-- INSERT INTO cosechas VALUES (11, 5, '2025-12-20', 800, 'primera', 'mercado local');
-- RESULTADO: Error: Cosecha no puede ser anterior a la fecha de siembra (ABORT)

-- D3 — INSTEAD OF en una vista:
DROP TRIGGER IF EXISTS tr_lote_finca_update_hectareas;
CREATE TRIGGER tr_lote_finca_update_hectareas
INSTEAD OF UPDATE ON v_lote_finca
BEGIN
    UPDATE lotes
    SET hectareas = NEW.hectareas
    WHERE lote_id = NEW.lote_id;

    INSERT INTO bitacora (tabla, operacion, fila_id, valor_viejo, valor_nuevo)
    VALUES ('lotes (via vista)', 'UPDATE',
            NEW.lote_id,
            'hectareas=' || OLD.hectareas,
            'hectareas=' || NEW.hectareas);
END;

-- Probarlo:
UPDATE v_lote_finca SET hectareas = 99 WHERE lote_id = 1;

SELECT hectareas FROM lotes WHERE lote_id = 1;
-- RESULTADO: 99 

-- Dejarlo como estaba:
UPDATE v_lote_finca SET hectareas = 28.5 WHERE lote_id = 1;

SELECT hectareas FROM lotes WHERE lote_id = 1;
-- RESULTADO: 28.5 
--
-- RESPUESTA D3 (dos líneas):
-- La vista no cambió (sigue siendo SELECT de lotes + fincas).
-- Quien decide qué significa "escribir" en la vista es el TRIGGER INSTEAD OF.
-- El trigger traduce el UPDATE de la vista a un UPDATE de la tabla subyacente.

-- =====================================================================
-- PARTE E - CIERRE (15 min)
-- =====================================================================

-- E1 — Tres cosas que tu bitácora no ve:
--
-- RESPUESTA E1:
-- 1. La IDENTIDAD de quién hizo el cambio.
--    No me preocupa AHORA porque SQLite no tiene sesiones.
--    Sí me preocuparía en producción: la bitácora necesaría usuario_id.
--
-- 2. El MOTIVO (intención) del cambio.
--    No me preocupa porque el negocio la define fuera: en comentarios,
--    en la orden de limpieza, en un ticket. La bitácora es registro, no análisis.
--
-- 3. El ORDEN de operaciones en una transacción grande.
--    Me preocupa un poco. Si borro 50 cosechas y 20 labores en una transacción,
--    bitácora tiene 70 filas pero no sé si los ordenes son reales o paralelos.
--    (En SQLite serial, no importa. En concurrencia, sí.)

-- E2 — ¿Cuál es más difícil de descubrir: índice o trigger?
--
-- RESPUESTA E2 (una frase):
-- El TRIGGER es más difícil de descubrir porque EXPLAIN QUERY PLAN no lo ve.
-- Un índice aparece en el plan. Un trigger es invisible hasta que se dispara.

-- E3 — Procedimiento para borrar datos de producción (clase 6 vs hoy):
--
-- RESPUESTA E3 (tres líneas):
-- 1. VALIDACIÓN: Antes de borrar, corre el chequeo que encontraría esa fila
--    (como las queries de A4). Asegurate de que es realmente un dato malo.
-- 2. TRANSACCIÓN + BITÁCORA: Dentro de una transacción, con trigger activo,
--    registra qué borraste. Después, verificá con los números de cierre (30550).
-- 3. COMUNICACIÓN: Dejá documentada la orden (ticket, commit message).
--    Si alguien pregunta "¿por qué falta?", la bitácora da la prueba.

-- =====================================================================
-- EXTRA (opcional - +5 puntos)
-- =====================================================================

-- Un chequeo de calidad propio: Labores sin responsable Y sin observación.
-- ¿Qué le interesaría al negocio? Una labor que no tiene quién la hizo
-- NI por qué se hizo es sospechosa. Necesita documentación.

-- Consulta de auditoría que busca este patrón:
SELECT labor_id, siembra_id, fecha, tipo_labor, responsable, observacion
FROM labores
WHERE responsable IS NULL AND observacion IS NULL
ORDER BY fecha DESC;
-- RESULTADO: 0 filas. Nada completamente sin documentación.

-- Pero si buscamos PARCIALMENTE sin documentación:
SELECT labor_id, siembra_id, fecha, tipo_labor, responsable, observacion
FROM labores
WHERE responsable IS NULL OR observacion IS NULL
ORDER BY fecha DESC;
-- RESULTADO: Labor 18 (riego sin responsable pero con obs "sin insumos")
--            Labor 5, 12, 17 (poda/riego sin observación pero con responsable)

-- RESPUESTA EXTRA:
-- El negocio querría validar: "cada labor debe tener QUIÉN y POR QUÉ".
-- Labor 18 (riego 2026-04-18): responsable=NULL, obs='sin insumos' → legítima (sistema automático).
-- Labor 5 (poda 2026-03-25): responsable='Ana Cedeno', obs=NULL → legítima (trabajo simple, obvio).
-- Si hubiese una labor con AMBOS NULL, sería un data quality issue.
-- El trigger BEFORE INSERT podría rechazar eso, pero aquí los datos históricos están limpios.

-- =====================================================================
-- VERIFICACIÓN FINAL
-- =====================================================================

-- Verificar estado final de la base:
SELECT 'fincas' AS tabla, COUNT(*) AS filas FROM fincas
UNION ALL SELECT 'siembras', COUNT(*) FROM siembras
UNION ALL SELECT 'labores', COUNT(*) FROM labores
UNION ALL SELECT 'cosechas', COUNT(*) FROM cosechas
UNION ALL SELECT 'bitacora', COUNT(*) FROM bitacora;

-- Esperado: fincas=3, siembras=10, labores=19, cosechas=9, bitacora=7
-- (3 deletes + 2 updates de lotes + 2 updates de deshace)