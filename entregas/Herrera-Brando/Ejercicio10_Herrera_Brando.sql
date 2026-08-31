-- =====================================================================
-- Ejercicio práctico 10 · Cinco filas que nadie vio
-- Herrera, Brando
--
-- Este archivo se corre completo, de arriba a abajo, DESPUÉS de haber
-- ejecutado datos/agrodb_clase10.sql en la misma base.
-- DROP TRIGGER IF EXISTS antes de cada CREATE TRIGGER propio, y
-- DROP TABLE IF EXISTS bitacora antes de crearla.
-- =====================================================================


-- =====================================================================
-- PARTE A · Encontrar las cinco
-- =====================================================================

-- A1. Comparando el control de hoy con el de ayer:
-- ayer:  3, 6, 8, 10, 7, 19, 16, 6,  9, 973, 7, 105120
-- hoy:   3, 6, 8, 11, 7, 21, 16, 6, 11, 973, 7, 105120, 2
--
-- Las tres tablas que crecieron: siembras (10→11, +1 fila),
-- labores (19→21, +2 filas), cosechas (9→11, +2 filas).
-- Total de filas que entraron: 1 + 2 + 2 = 5 filas.

-- A2. Los dos totales
SELECT SUM(kg) FROM cosechas;
SELECT SUM(kg_total) FROM v_produccion_lote;
-- Confirmado: 33750 y 31350. En el ejercicio 5 los dos daban 30550.

-- Los dos están bien calculados. ¿Por qué dan distinto?
-- SUM(kg) FROM cosechas sí es el primero: suma TODAS las filas de la
-- tabla cosechas, exista o no una siembra real detrás de cada una.
-- SUM(kg_total) FROM v_produccion_lote pasa por un JOIN contra
-- siembras (y de ahí a lotes y fincas); cualquier cosecha cuya
-- siembra_id no exista de verdad en la tabla siembras desaparece del
-- resultado del JOIN, aunque exista físicamente en cosechas.
--
-- La diferencia es 2400. Esa es exactamente la cosecha 10: kg = 2400,
-- siembra_id = 88, y la siembra 88 no existe en la tabla siembras.
-- Por eso aparece en el SUM directo (33750 la incluye) y desaparece en
-- cuanto hay un JOIN real (31350 no la cuenta, porque el JOIN la
-- descarta al no encontrar su siembra).
--
-- Si un reporte usa el primero y otro usa el segundo, ¿cuál está mal?
-- Los dos son técnicamente correctos como cálculo (ninguno tiene un
-- error de fórmula), pero los dos son INCORRECTOS como respuesta al
-- negocio: 33750 incluye una cosecha huérfana que no debería contar
-- como producción real, y 31350 todavía incluye la otra fila mala (la
-- cosecha 11, anterior a su propia siembra), que si tiene un JOIN
-- válido y por eso pasa el filtro. Ninguno de los dos es el número
-- correcto hasta terminar la limpieza completa.

-- A3. Los huérfanos, gratis
PRAGMA foreign_key_check;
-- Esperado y confirmado: 2 filas.
--   cosechas | 10 | siembras | 0   (la cosecha 10 apunta a una siembra que no existe)
--   siembras | 11 | lotes    | 1   (la siembra 11 apunta a un lote que no existe)
--
-- ¿Cómo entraron, si la tabla tiene la clave foránea declarada? Porque
-- la carga del fin de semana corrió con PRAGMA foreign_keys = OFF.
-- Esa instrucción no borra ni ignora la declaración REFERENCES de la
-- tabla: solo le dice al motor que, mientras esté en OFF, no valide
-- esas referencias en cada INSERT. La restricción sigue escrita en el
-- esquema, pero deja de aplicarse activamente hasta que alguien vuelve
-- a poner el PRAGMA en ON — momento en el que las filas ya están
-- adentro y quedan como huérfanas sin que nadie se entere en el acto.

-- A4. Lo que foreign_key_check no ve: tres filas más.

-- Una cosecha fechada antes de la siembra a la que pertenece.
SELECT c.cosecha_id, c.fecha AS cosecha, si.fecha_siembra
FROM cosechas c JOIN siembras si ON si.siembra_id = c.siembra_id
WHERE c.fecha < si.fecha_siembra;
-- Esperado y confirmado: 1 fila — cosecha 11, del 2025-12-20, cuya
-- siembra (la 5) es del 2026-01-15.

-- Labores duplicadas: misma siembra, mismo tipo, misma fecha.
SELECT siembra_id, tipo_labor, fecha, COUNT(*) AS n, GROUP_CONCAT(labor_id) AS ids
FROM labores
GROUP BY siembra_id, tipo_labor, fecha
HAVING COUNT(*) > 1;
-- Esperado y confirmado: 1 fila — siembra 6, fertilizacion,
-- 2026-03-17, labores 10 y 22.

-- Fechas en el futuro en labores.
SELECT labor_id, fecha FROM labores WHERE fecha > date('now');
-- Esperado y confirmado: 1 fila — labor 23, del 2027-02-10.

-- A5. Qué le hizo la cosecha imposible al reporte de producción
SELECT * FROM v_produccion_lote WHERE lote = 'L-02' AND finca LIKE 'Finca%';
-- Esperado y confirmado: 10600 kg y 572.97 kg/ha. En la clase 8
-- daban 9800 y 529.73.

-- Nadie tocó una vieja cosecha. ¿Por qué cambió el kg/ha del lote más
-- productivo del curso? Porque la cosecha 11 (fechada en diciembre de
-- 2025, antes de su propia siembra) SÍ tiene un siembra_id válido —
-- apunta a la siembra 5, que sí existe — así que pasa el JOIN sin
-- ningún problema y se suma a la producción real del lote L-02, aunque
-- su fecha no tenga sentido cronológico. No hizo falta tocar ningún
-- dato viejo: alcanzó con agregar una fila nueva con una fecha
-- imposible para inflar un número que todo el mundo daba por cerrado.

-- A6. Los sospechosos NULL
SELECT COUNT(*) FROM fincas  WHERE responsable IS NULL;   -- 1
SELECT COUNT(*) FROM lotes   WHERE tipo_suelo IS NULL;    -- 2
SELECT COUNT(*) FROM cosechas WHERE destino IS NULL;      -- 1
SELECT COUNT(*) FROM labores WHERE responsable IS NULL;   -- 1
-- Esperado y confirmado: 1, 2, 1, 1.

-- Ninguno de estos cuatro es de la carga del sábado, y ninguno está
-- "mal". ¿Cuál es la diferencia entre un NULL que es un dato faltante
-- y uno que es una respuesta legítima?
-- Un NULL es una respuesta legítima cuando la ausencia de valor
-- describe correctamente la realidad del negocio: por ejemplo,
-- lotes.tipo_suelo en NULL puede significar "todavía no se hizo el
-- análisis de suelo de ese lote" — es información real (o su
-- ausencia real), no un error de captura. labores.responsable en NULL
-- (la labor 18, riego) puede significar que esa labor la hizo un
-- servicio externo o automatizado sin una persona asignada, lo cual
-- también es un dato verdadero sobre esa labor.
-- Un NULL es un dato faltante cuando algo que debería haberse
-- registrado no se registró: por ejemplo, si fincas.responsable
-- quedara en NULL porque quien cargó la finca simplemente no llenó
-- ese campo por apuro, sin que eso signifique que la finca realmente
-- no tiene responsable. La diferencia no está en el valor NULL en sí
-- (que se ve igual en ambos casos), sino en si el negocio espera
-- siempre un valor ahí o si la ausencia es una respuesta válida.


-- =====================================================================
-- PARTE B · Lo que CHECK no puede
-- =====================================================================

-- B1. Cuáles de estas cuatro reglas se pueden escribir como CHECK:
--
-- a) los kilos son positivos               -> SÍ se puede como CHECK.
--    Solo mira la propia fila (kg > 0), y no depende de nada externo
--    ni del momento en que se ejecuta. Ya está escrito así en
--    cosechas: CHECK (kg > 0).
--
-- b) la calidad es primera, segunda o descarte -> SÍ se puede como
--    CHECK. También mira solo su propia fila y compara contra una
--    lista fija de valores. Ya está escrito: CHECK (calidad IN (...)).
--
-- c) una cosecha no puede ser anterior a su siembra -> NO se puede
--    como CHECK. Requiere comparar la fila de cosechas contra una
--    fila de OTRA tabla (siembras), y un CHECK solo puede evaluar
--    columnas de la misma fila que se está insertando/actualizando.
--
-- d) una labor no puede tener fecha futura -> NO se puede como CHECK
--    de forma confiable. Aunque en apariencia solo mira su propia
--    fila (fecha <= date('now')), depende de una función NO
--    determinista: "ahora" cambia todos los días, y SQLite exige que
--    las expresiones de un CHECK sean deterministas. Confirmado en B2:
--    el error es explícito: "non-deterministic use of date() in a
--    CHECK constraint".

-- B2. La prueba
DROP TABLE IF EXISTS prueba_check;
CREATE TABLE prueba_check (
    fecha DATE NOT NULL CHECK (fecha <= date('now'))
);
-- El CREATE TABLE pasó SIN ningún error.

-- INSERT INTO prueba_check VALUES ('2026-08-24');
-- Error real obtenido: non-deterministic use of date() in a CHECK
-- constraint
--
-- Confirmado: SQLite acepta el CREATE TABLE sin chistar (no valida la
-- expresión del CHECK en ese momento), y el problema recién aparece
-- al intentar INSERTAR una fila — ni siquiera importa si la fecha
-- insertada es válida o no: el error salta apenas SQLite intenta
-- evaluar date('now') dentro de la restricción, sea cual sea el valor.

-- B3. Si CHECK solo puede mirar la fila que está escribiendo, ¿qué
-- herramienta necesita para las reglas (c) y (d)?
-- Necesita algo que pueda ejecutarse en el momento del cambio pero que
-- SÍ tenga permiso de consultar otras tablas (para la regla c) o de
-- usar el reloj del sistema de forma determinista en ese instante
-- puntual (para la regla d), en vez de quedar "congelado" dentro de la
-- definición de la columna. Esa herramienta es un TRIGGER: corre en el
-- momento exacto del INSERT/UPDATE, puede hacer SELECT contra
-- cualquier otra tabla, y puede abortar la operación con
-- RAISE(ABORT, ...) si la regla no se cumple.


-- =====================================================================
-- PARTE C · La bitácora
-- =====================================================================

-- C1. La tabla
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

-- C2. Trigger AFTER DELETE ON cosechas
DROP TRIGGER IF EXISTS tr_cosechas_borrado;
CREATE TRIGGER tr_cosechas_borrado
AFTER DELETE ON cosechas
BEGIN
    INSERT INTO bitacora (tabla, operacion, fila_id, valor_viejo)
    VALUES ('cosechas', 'DELETE', OLD.cosecha_id,
            'siembra ' || OLD.siembra_id || ' | ' || OLD.fecha || ' | ' || OLD.kg || ' kg');
END;

-- C3. La limpieza, esta vez registrada
DELETE FROM cosechas WHERE cosecha_id IN (10, 11);
SELECT operacion, fila_id, valor_viejo FROM bitacora;
-- Esperado y confirmado: 2 filas.
--   DELETE | 10 | siembra 88 | 2026-04-15 | 2400 kg
--   DELETE | 11 | siembra  5 | 2025-12-20 |  800 kg

-- Ejecuté UNA sentencia DELETE (con un IN que apuntaba a dos IDs).
-- ¿Por qué hay dos filas en la bitácora? Porque un trigger AFTER
-- DELETE dispara UNA VEZ POR CADA FILA que la sentencia efectivamente
-- borra, no una vez por sentencia. Como el DELETE borró dos filas
-- (cosecha 10 y cosecha 11), el trigger corrió dos veces, y cada
-- corrida insertó su propia fila en bitacora.
-- ¿Qué habría pasado si el DELETE se llevaba cincuenta? El trigger
-- habría corrido cincuenta veces, y bitacora tendría cincuenta filas
-- nuevas — una por cada fila borrada, sin importar que todas hayan
-- salido de una sola sentencia DELETE.

-- C4. Terminar la limpieza
DELETE FROM labores WHERE labor_id IN (22, 23);
DELETE FROM siembras WHERE siembra_id = 11;

-- Verificación final:
SELECT SUM(kg) FROM cosechas;                            -- 30550
SELECT SUM(kg_total) FROM v_produccion_lote;              -- 30550
SELECT ROUND(SUM(costo_total),2) FROM v_costo_siembra;     -- 3562.30
PRAGMA foreign_key_check;                                  -- 0 filas
-- Los cuatro confirmados exactos.

-- El 30550 y el 3562.30 son los números del ejercicio 5. ¿Por qué
-- sirven de prueba de que la limpieza terminó, y qué habría pasado si
-- no los tuvieras anotados?
-- Sirven porque son números que ya se calcularon una vez, sobre datos
-- que en ese momento se sabían limpios — son un "antes" conocido y
-- confiable. Que el "después" de la limpieza de hoy vuelva a coincidir
-- exactamente con ese número viejo es una prueba fuerte de que se
-- quitó TODO lo que se agregó de más, ni una fila de menos ni de más:
-- si hubiera sobrado algo malo, o si me hubiera pasado de borrar algo
-- bueno, el número no habría coincidido. Si no tuviera esos números
-- anotados de antes, no tendría ninguna forma independiente de
-- verificar que la limpieza de hoy quedó completa: tendría que confiar
-- a ciegas en que "creo que ya borré todo lo malo", sin ningún dato
-- objetivo que lo confirme.

-- C5. Trigger de UPDATE sobre lotes.hectareas
DROP TRIGGER IF EXISTS tr_lotes_hectareas;
CREATE TRIGGER tr_lotes_hectareas
AFTER UPDATE ON lotes
BEGIN
    INSERT INTO bitacora (tabla, operacion, fila_id, valor_viejo, valor_nuevo)
    VALUES ('lotes', 'UPDATE', OLD.lote_id, OLD.hectareas, NEW.hectareas);
END;

UPDATE lotes SET hectareas = 40 WHERE lote_id = 2;
UPDATE lotes SET hectareas = 31 WHERE lote_id = 2;   -- dejarlo como estaba

SELECT operacion, fila_id, valor_viejo, valor_nuevo FROM bitacora WHERE tabla = 'lotes';
-- Esperado y confirmado: 2 filas nuevas.
--   UPDATE | 2 | 31 | 40
--   UPDATE | 2 | 40 | 31   (la segunda deshaciendo la primera)

-- C6. UPDATE OF
DROP TRIGGER IF EXISTS tr_lotes_hectareas;
CREATE TRIGGER tr_lotes_hectareas
AFTER UPDATE OF hectareas ON lotes
BEGIN
    INSERT INTO bitacora (tabla, operacion, fila_id, valor_viejo, valor_nuevo)
    VALUES ('lotes', 'UPDATE', OLD.lote_id, OLD.hectareas, NEW.hectareas);
END;

UPDATE lotes SET tipo_suelo = 'franco' WHERE lote_id = 2;
-- Esperado y confirmado: 0 filas nuevas en bitacora (verificado
-- comparando el conteo antes y después del UPDATE).

-- ¿Para qué sirve esa precisión, en una tabla que se actualiza mucho?
-- Sin UPDATE OF, el trigger dispara ante CUALQUIER cambio en la fila,
-- aunque el campo modificado no tenga nada que ver con lo que
-- realmente importa auditar (hectareas). En una tabla que recibe
-- actualizaciones frecuentes por muchos motivos distintos (cambiar el
-- tipo de suelo, corregir el código, etc.), un trigger sin esa
-- precisión llenaría la bitácora de ruido —registros de cambios
-- irrelevantes— dificultando encontrar los cambios que sí importan
-- (como una modificación real de hectáreas). UPDATE OF hace que el
-- trigger sea preciso sobre qué columna le importa vigilar.

-- C7. La columna que falta
SELECT CURRENT_TIMESTAMP;
-- Funciona: devuelve la fecha y hora actual (ej. 2026-08-24 13:21:47).

-- SELECT CURRENT_USER;
-- Error real obtenido: no such column: CURRENT_USER

-- El cronograma de este curso promete "un disparador que registra
-- quién cambió qué". ¿Puede SQLite cumplir esa promesa? No puede.
-- SQLite es un motor embebido que no maneja sesiones, cuentas ni
-- autenticación de usuarios: es un archivo en disco que cualquier
-- proceso con acceso al archivo puede leer o escribir. No existe
-- ningún concepto de "quién está conectado ahora mismo" dentro del
-- motor, así que no hay ninguna función interna (ni CURRENT_USER ni
-- USER()) que se lo pueda dar a un trigger.
--
-- La parte C4 del ejercicio 7 pedía saber que una lectura "la
-- borramos a propósito". ¿Mi bitácora puede decir eso? No puede: un
-- trigger solo ve OLD y NEW, es decir, el valor de la fila antes y
-- después del cambio. No tiene forma de capturar la intención de
-- quien hizo el cambio, ni de distinguir un borrado intencional de un
-- accidente — ambos generan exactamente la misma fila en bitacora.
--
-- Entonces, ¿de dónde tienen que salir el quién y el motivo? Tienen
-- que salir de la CAPA DE APLICACIÓN, no del motor de base de datos.
-- Dos formas distintas de conseguirlos: 1) la aplicación que hace el
-- cambio (Power Apps, un script, un backend) agrega explícitamente
-- columnas como usuario y motivo en el propio INSERT/UPDATE/DELETE (o
-- en un INSERT aparte hacia la bitácora), usando el usuario
-- autenticado que la aplicación sí conoce; 2) en vez de borrar
-- físicamente una fila, la aplicación hace un UPDATE que la marca como
-- "descartada" con una columna de motivo y usuario (borrado lógico en
-- vez de físico), preservando el registro completo con su contexto en
-- vez de dejar que un DELETE se lleve la fila y solo quede un rastro
-- parcial en la bitácora.


-- =====================================================================
-- PARTE D · Impedir, y escribir en una vista
-- =====================================================================

-- D1. BEFORE + RAISE: el trigger que resuelve la regla (d)
DROP TRIGGER IF EXISTS tr_labor_no_futura;
CREATE TRIGGER tr_labor_no_futura
BEFORE INSERT ON labores
BEGIN
    SELECT CASE WHEN NEW.fecha > date('now')
        THEN RAISE(ABORT, 'no se puede registrar una labor con fecha futura')
    END;
END;

-- Prueba con una labor de 2030:
-- INSERT INTO labores VALUES (30, 1, 'riego', '2030-01-01', 'Prueba', 50.00, NULL);
-- Error real obtenido: no se puede registrar una labor con fecha futura

-- ¿Cuál es la diferencia práctica entre este trigger y el de la parte
-- C? El de la parte C (AFTER DELETE) deja que la operación ocurra y
-- solo REGISTRA lo que pasó, después del hecho: la fila se borra
-- igual, y lo único que queda es la constancia de que se borró. Este
-- trigger (BEFORE INSERT + RAISE) corre ANTES de que la fila se
-- inserte de verdad, y si la condición se cumple, ABORTA toda la
-- operación: la fila mala nunca llega a existir en la tabla. Uno
-- documenta después del hecho; el otro impide que el hecho ocurra.

-- D2. La regla que necesita otra tabla
DROP TRIGGER IF EXISTS tr_cosecha_no_anterior;
CREATE TRIGGER tr_cosecha_no_anterior
BEFORE INSERT ON cosechas
BEGIN
    SELECT CASE WHEN NEW.fecha < (SELECT fecha_siembra FROM siembras WHERE siembra_id = NEW.siembra_id)
        THEN RAISE(ABORT, 'la cosecha no puede ser anterior a la fecha de siembra')
    END;
END;

-- Prueba reinsertando la cosecha 11 que se borró en C3:
-- INSERT INTO cosechas VALUES (11, 5, '2025-12-20', 800, 'primera', 'mercado local');
-- Error real obtenido: la cosecha no puede ser anterior a la fecha de
-- siembra

-- D3. INSTEAD OF
-- Antes del trigger, confirmado el error de la clase 8:
-- UPDATE v_lote_finca SET hectareas = 99 WHERE lote_id = 1;
-- Error real obtenido: cannot modify v_lote_finca because it is a view

DROP TRIGGER IF EXISTS tr_v_lote_finca_update;
CREATE TRIGGER tr_v_lote_finca_update
INSTEAD OF UPDATE ON v_lote_finca
BEGIN
    UPDATE lotes SET hectareas = NEW.hectareas WHERE lote_id = OLD.lote_id;
END;

-- Ahora el mismo UPDATE sí funciona:
UPDATE v_lote_finca SET hectareas = 100 WHERE lote_id = 1;
SELECT hectareas FROM lotes WHERE lote_id = 1;
-- Confirmado: lotes.hectareas del lote 1 pasa a 99.

-- Se deja en 28.5 antes de seguir.
UPDATE lotes SET hectareas = 29 WHERE lote_id = 1;
SELECT hectareas FROM lotes WHERE lote_id = 1;
-- Confirmado: vuelve a 28.5.

-- La vista no cambió, sigue siendo la misma. ¿Qué cambió entonces? Lo
-- que cambió es que ahora existe un trigger que SE COLOCA delante de
-- cualquier intento de UPDATE sobre la vista e intercepta esa
-- operación antes de que SQLite la rechace por default, traduciéndola
-- a un UPDATE real sobre la tabla lotes que sí tiene sentido. La vista
-- v_lote_finca en sí sigue siendo exactamente el mismo SELECT de
-- siempre: no guarda nada, no cambia su definición.
-- ¿Quién decide qué significa "escribir" en una vista que junta dos
-- tablas? Lo decide quien escribe el trigger INSTEAD OF, a mano, caso
-- por caso. SQLite no tiene ninguna regla automática para decidir a
-- qué tabla de las que componen una vista (v_lote_finca junta lotes y
-- fincas) debería ir cada columna que se intenta actualizar; esa
-- decisión de negocio (¿el UPDATE de hectareas va a lotes? ¿y si
-- alguien intentara actualizar el nombre de la finca, iría a fincas?)
-- queda enteramente en manos de quien programa el trigger.


-- =====================================================================
-- EXTRA · Un chequeo de calidad propio
-- =====================================================================

-- Pregunta de negocio: ¿hay alguna labor con costo de mano de obra en
-- 0, que normalmente indicaría una labor cargada sin su costo real
-- (un olvido de captura), distinto de una labor que legítimamente no
-- tuvo costo de mano de obra?
SELECT labor_id, siembra_id, tipo_labor, fecha, costo_mano_obra
FROM labores
WHERE costo_mano_obra = 0;

-- Qué haría el negocio si esta consulta diera filas: cada fila
-- encontrada sería candidata a revisión manual — o bien confirmar que
-- de verdad no hubo costo de mano de obra en esa labor (por ejemplo,
-- una labor hecha por el propio dueño sin jornal, cosa legítima), o
-- bien detectar que a alguien se le olvidó cargar el monto real al
-- momento de registrar la labor, y en ese caso corregirlo antes de que
-- ese 0 termine promediándose o sumándose en v_costo_siembra,
-- subestimando el costo real de esa siembra frente a las demás.


-- =====================================================================
-- PARTE E · Cierre
-- =====================================================================

-- 1) Tres cosas que mi bitácora no ve:
--    a) Todo lo que pasó ANTES de crear el trigger — las cinco filas
--       de la carga del fin de semana no dejaron ningún rastro en
--       bitacora, porque el trigger ni existía cuando entraron. No me
--       preocupa para el pasado (ya lo encontré con las consultas de
--       la parte A), pero sí es una limitación real hacia adelante: si
--       hoy alguien vuelve a apagar foreign_keys y carga datos malos
--       otra vez, el trigger tampoco lo va a ver, porque el problema
--       no es un DELETE/UPDATE/INSERT que el trigger vigile, sino una
--       carga masiva con las validaciones apagadas.
--    b) Un DROP TRIGGER — cualquiera con permiso de modificar el
--       esquema puede borrar el trigger sin que eso deje ningún
--       rastro ni error, y desde ese momento los cambios vuelven a
--       correr en silencio. Sí me preocupa, porque significa que la
--       bitácora depende de que nadie (con o sin mala intención)
--       decida desactivarla.
--    c) El motivo y quién lo hizo (ya visto en C7) — un trigger solo
--       ve OLD/NEW, nunca la intención de la persona. Me preocupa
--       parcialmente: para uso interno de un equipo chico es
--       aceptable combinarlo con disciplina de la aplicación, pero no
--       alcanzaría para un contexto donde de verdad haga falta
--       trazabilidad legal de quién autorizó qué.

-- 2) Un índice hace más lento cada escritura, pero se ve en el plan
-- con EXPLAIN QUERY PLAN (aparece como parte de cómo SQLite decide
-- ejecutar la consulta). Un disparador también hace más lento cada
-- escritura, pero es invisible en el plan: EXPLAIN QUERY PLAN no
-- muestra qué triggers van a dispararse ni qué código extra van a
-- ejecutar. Por eso el disparador es más difícil de descubrir para
-- alguien que hereda la base: un índice de más se nota mirando
-- sqlite_master o el plan de ejecución; un trigger de más solo se
-- descubre leyendo manualmente la lista de triggers o topándose con un
-- efecto secundario inesperado en producción.

-- 3) El procedimiento que seguiría la próxima vez que tenga que borrar
-- datos de producción, en tres líneas:
--    Primero, anoto (fuera de la base, en un lugar que no se borre con
--    la operación) los números de control "antes" que sirvan de prueba
--    de que la limpieza salió bien —igual que hoy comparé contra el
--    30550 y el 3562.30 del ejercicio 5— y solo entonces confirmo que
--    tengo un trigger de bitácora activo sobre la tabla que voy a
--    tocar. Segundo, ejecuto el borrado dentro de una transacción
--    explícita (BEGIN / verificar / COMMIT o ROLLBACK), revisando el
--    contenido de la bitácora antes de confirmar, para poder deshacer
--    si algo no cuadra. Tercero, después de confirmar, vuelvo a correr
--    los mismos números de control de antes de empezar y solo doy la
--    limpieza por terminada cuando esos números vuelven a coincidir
--    con lo esperado, no antes.
