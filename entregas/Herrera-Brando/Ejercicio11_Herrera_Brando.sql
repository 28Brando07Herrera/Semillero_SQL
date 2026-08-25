-- =====================================================================
-- Ejercicio práctico 11 · Fila por fila es lento por lento
-- Herrera, Brando
--

--
-- Este archivo arranca en la Parte A, como pide la consigna. El script
-- base (datos/agrodb_oracle_clase11.sql) se corre antes, aparte.
-- =====================================================================


-- =====================================================================
-- PARTE A · Lo que se rompe al cruzar la calle
-- =====================================================================

-- A1. Las cinco sentencias

-- 1) SELECT 1;
-- Error: ORA-00923: FROM keyword not found where expected
-- Versión que sí corre en Oracle:
SELECT 1 FROM dual;

-- 2) SELECT COUNT(*) FROM lecturas LIMIT 5;
-- Error: ORA-00933: SQL command not properly ended
-- Versión que sí corre en Oracle:
SELECT COUNT(*) FROM lecturas FETCH FIRST 5 ROWS ONLY;

-- 3) DROP TABLE IF EXISTS basura;
-- Error: ORA-00933: SQL command not properly ended
-- (Oracle no tiene la cláusula IF EXISTS en DROP TABLE. Hay que
-- preguntarle primero al catálogo si la tabla existe.)
-- Versión que sí corre en Oracle:
BEGIN
  FOR t IN (SELECT table_name FROM user_tables WHERE table_name = 'BASURA') LOOP
    EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name;
  END LOOP;
END;
/

-- 4) SELECT DATE(fecha_hora) FROM lecturas WHERE ROWNUM = 1;
-- Error: ORA-00936: missing expression
-- (DATE() no es una función en Oracle: DATE es una palabra reservada
-- para el tipo/literal de fecha, no algo que se pueda "llamar" con
-- paréntesis sobre una columna.)
-- Versión que sí corre en Oracle:
SELECT TRUNC(fecha_hora) FROM lecturas WHERE ROWNUM = 1;

-- 5) SELECT sensor_id, COUNT(*) FROM lecturas GROUP BY sensor_id;
-- Esta NO se rompe. Corre exactamente igual que en SQLite, sin
-- cambiar una letra. Es la mitad de la lección del día: SELECT,
-- COUNT(*) y GROUP BY son SQL de verdad, no una particularidad de
-- SQLite — funcionan igual en cualquier motor relacional serio.

-- A2. La cadena vacía
SELECT CASE WHEN '' IS NULL THEN 'la vacia ES null' ELSE 'la vacia NO es null' END AS resultado
  FROM dual;
-- Esperado (documentado en las diapositivas): en Oracle devuelve
-- "la vacia ES null" — exactamente lo opuesto a SQLite, donde '' y
-- NULL son cosas distintas.

-- Si tuviera una columna observacion y quisiera distinguir "no
-- escribió nada" (NULL) de "anotó explícitamente que no hay nada"
-- (cadena vacía), ¿podría hacerlo en Oracle? NO podría hacerlo con
-- una cadena vacía, porque en Oracle '' y NULL son literalmente el
-- mismo valor — no existe forma de guardar "cero caracteres" distinto
-- de "ausencia de dato". ¿Qué tendría que hacer en su lugar? Usar un
-- valor centinela que SÍ tenga longitud mayor a cero: por ejemplo, un
-- solo espacio en blanco (' ', que en Oracle SÍ es distinto de NULL
-- porque tiene longitud 1), o mejor todavía, agregar una columna
-- booleana aparte (por ejemplo observacion_confirmada NUMBER(1)) que
-- registre explícitamente si alguien confirmó "no hay observación",
-- separando esa intención del hecho de que el campo de texto esté
-- vacío.

-- A3. La cicatriz del * 1.0
SELECT SUM(c.kg) AS kg, SUM(c.kg) / l.hectareas AS kg_ha
  FROM cosechas c
  JOIN siembras s ON s.siembra_id = c.siembra_id
  JOIN lotes    l ON l.lote_id    = s.lote_id
 WHERE l.lote_id = 1
 GROUP BY l.hectareas;
-- Esperado (documentado en el ejercicio): 7300 y 256.14... — el mismo
-- 256.14 del ejercicio 8, sin necesidad de multiplicar por 1.0 en
-- ningún lado. (7300 / 28.5 = 256.140350877192982456...)

-- ¿Por qué acá no hace falta el * 1.0? Porque en Oracle, NUMBER es un
-- tipo numérico de verdad, con precisión y decimales integrados: al
-- dividir dos NUMBER, el resultado conserva los decimales sin que
-- haga falta forzarlo. ¿El * 1.0 era una regla de SQL o una defensa
-- contra algo particular de SQLite? Era una defensa puntual contra
-- SQLite: ahí, dos columnas de tipo INTEGER (o con afinidad entera)
-- dividen con división entera si ambos operandos son enteros, y el
-- * 1.0 forzaba a que uno de los dos se tratara como número de punto
-- flotante. Esa necesidad nunca existió en el estándar SQL ni en
-- Oracle: era una cicatriz del motor específico con el que se empezó
-- el curso, no una regla general del lenguaje.

-- A4. TRUNC(fecha_hora), el DATE(fecha_hora) de Oracle
SELECT TRUNC(fecha_hora) AS dia, COUNT(*) AS n
  FROM lecturas
 WHERE sensor_id = 1
 GROUP BY TRUNC(fecha_hora)
 ORDER BY dia
 FETCH FIRST 3 ROWS ONLY;
-- Esperado (documentado en el ejercicio): 3 filas, los días 1, 2 y 3
-- de abril, 48 lecturas cada uno (1440 lecturas del sensor 1 / 30 días
-- de abril = 48 por día).

-- Hipótesis (a confirmar en la Parte C): sí, vale lo mismo que
-- DATE(fecha_hora) en SQLite. TRUNC(fecha_hora) en el WHERE también
-- debería anular un índice normal sobre fecha_hora, por la misma
-- razón de siempre: un índice ordenado por el valor crudo de la
-- columna no sabe nada sobre el resultado de aplicarle una función.
-- La diferencia (que Oracle sí tiene y SQLite no) es que Oracle
-- permite crear un índice sobre la EXPRESIÓN misma
-- (CREATE INDEX ix ON lecturas (TRUNC(fecha_hora))), lo cual en
-- SQLite no es posible.


-- =====================================================================
-- PARTE B · El primer bloque
-- =====================================================================

-- B1. Anatomía
DECLARE
  v_total NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_total FROM lecturas;
  DBMS_OUTPUT.PUT_LINE('lecturas: ' || v_total);
END;
/
-- Esperado (documentado): lecturas: 8640

-- ¿Qué hace INTO? Toma el resultado de un SELECT que devuelve
-- exactamente una fila y lo guarda en una o más variables PL/SQL, para
-- poder seguir usándolo en el resto del bloque. ¿Por qué un SELECT
-- suelto no sirve adentro de PL/SQL? Porque PL/SQL no tiene una
-- consola donde "mostrar" filas como hace una herramienta de consulta
-- interactiva (el worksheet de FreeSQL, SQL*Plus, etc.): un SELECT
-- dentro de un bloque necesita un destino explícito para sus columnas,
-- y ese destino es INTO. Sin INTO, el compilador ni siquiera deja
-- crear el bloque. ¿Qué pasaría si le sacás la / del final? La barra
-- sola en su propia línea es la señal que le dice al cliente (el
-- worksheet, SQL*Plus, SQLcl) "el bloque terminó, mándalo al servidor
-- para que lo ejecute". Sin ella, muchos clientes se quedan esperando
-- más líneas de código sin ejecutar nada, o directamente no reconocen
-- dónde termina el bloque.

-- B2. %TYPE, y por qué importa
DECLARE
  v_tipo sensores.tipo%TYPE;
  v_n    NUMBER;
BEGIN
  SELECT tipo INTO v_tipo FROM sensores WHERE sensor_id = 1;
  SELECT COUNT(*) INTO v_n FROM lecturas WHERE sensor_id = 1;
  DBMS_OUTPUT.PUT_LINE('sensor 1 (' || v_tipo || '): ' || v_n || ' lecturas');
END;
/
-- Esperado (documentado en el ejercicio): sensor 1 (temperatura): 1440 lecturas

-- sensores.tipo hoy es VARCHAR2(20). Si mañana alguien lo agranda a
-- VARCHAR2(40), ¿qué pasa con mi bloque si usé %TYPE? No pasa nada:
-- %TYPE toma el tipo de la columna en el momento en que el bloque se
-- COMPILA (o recompila), así que automáticamente hereda el nuevo
-- tamaño sin que yo tenga que tocar una letra de mi código. ¿Y si
-- hubiera escrito VARCHAR2(20) a mano? Ese tamaño queda fijo,
-- congelado en mi declaración. Si algún valor futuro de
-- sensores.tipo superara los 20 caracteres (porque la columna ahora
-- permite hasta 40), mi SELECT ... INTO fallaría al intentar meter
-- ese valor más largo en mi variable de 20, con un error como
-- ORA-06502: character string buffer too small.

-- B3. La excepción que se conoce a las malas
DECLARE
  v_nombre fincas.nombre%TYPE;
BEGIN
  SELECT nombre INTO v_nombre FROM fincas WHERE finca_id = 99;
  DBMS_OUTPUT.PUT_LINE(v_nombre);
END;
/
-- Error esperado (documentado en las diapositivas):
-- ORA-01403: no data found
-- (la finca 99 no existe: cero filas para un INTO que exige una)

DECLARE
  v_nombre fincas.nombre%TYPE;
BEGIN
  SELECT nombre INTO v_nombre FROM fincas;
  DBMS_OUTPUT.PUT_LINE(v_nombre);
END;
/
-- Error esperado (documentado en las diapositivas):
-- ORA-01422: exact fetch returns more than requested number of rows
-- (hay 3 fincas en la tabla, y el WHERE que las devolvía todas hace
-- que el SELECT INTO reciba 3 filas en vez de 1)

-- SELECT ... INTO exige exactamente una fila. ¿Qué pasa con cero?
-- Lanza la excepción NO_DATA_FOUND (ORA-01403). ¿Y con dos o más?
-- Lanza la excepción TOO_MANY_ROWS (ORA-01422).

-- B4. Atajarla
DECLARE
  v_nombre fincas.nombre%TYPE;
BEGIN
  SELECT nombre INTO v_nombre FROM fincas WHERE finca_id = 99;
  DBMS_OUTPUT.PUT_LINE(v_nombre);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('finca 99: no existe');
END;
/
-- Esperado: el bloque termina bien (PL/SQL procedure successfully
-- completed) y muestra "finca 99: no existe" en vez de explotar con
-- ORA-01403.

-- B5. En la clase 8, CREATE VIEW IF NOT EXISTS no daba error y tampoco
-- hacía lo que se quería. ¿En qué se parece a lo de B4? Se parecen en
-- que las dos situaciones terminan "sin error visible" pese a que el
-- resultado no fue el que uno esperaba a simple vista: en ambos casos
-- el motor evita el fallo estridente. ¿En qué se diferencian? En
-- CREATE VIEW IF NOT EXISTS, el motor decide por su cuenta no hacer
-- nada (no reemplaza la vista) y no le da a quien escribió el código
-- ninguna oportunidad de reaccionar distinto: es un comportamiento fijo
-- e implícito. En B4, en cambio, YO decidí explícitamente qué hacer
-- ante la ausencia de datos (con WHEN NO_DATA_FOUND), y ese
-- comportamiento queda visible y documentado en el propio código: no
-- es que el error desaparezca solo, es que yo escribí a propósito qué
-- pasa en ese caso, y lo dejé por escrito para que cualquiera que lea
-- el bloque lo entienda.


-- =====================================================================
-- PARTE C · Fila por fila es lento por lento
-- =====================================================================

-- C1. El bucle que parece razonable
DECLARE
  t0 NUMBER := DBMS_UTILITY.GET_TIME;
BEGIN
  DELETE FROM resumen_diario;

  FOR s IN (SELECT sensor_id FROM sensores ORDER BY sensor_id) LOOP
    FOR d IN (SELECT DISTINCT TRUNC(fecha_hora) AS dia FROM lecturas ORDER BY 1) LOOP
      INSERT INTO resumen_diario (sensor_id, dia, n_lecturas, valor_min, valor_max, valor_prom)
      SELECT s.sensor_id, d.dia, COUNT(*), MIN(valor), MAX(valor), ROUND(AVG(valor), 2)
        FROM lecturas
       WHERE sensor_id = s.sensor_id
         AND TRUNC(fecha_hora) = d.dia;
    END LOOP;
  END LOOP;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('fila por fila: ' ||
      (DBMS_UTILITY.GET_TIME - t0) || ' centesimas de segundo');
END;
/
-- [VERIFICAR EN FREESQL] tiempo real observado: ____ centésimas de
-- segundo (reemplazar antes de entregar, corriendo este bloque en
-- freesql.oracle.com con la pestaña "Salida DBMS" habilitada).

SELECT COUNT(*) FROM resumen_diario;
-- Esperado: 180

SELECT * FROM resumen_diario WHERE sensor_id = 1 AND dia = DATE '2026-04-01';
-- Esperado: 48 | 18 | 28 | 22.59

-- C2. La misma tarea, una sentencia
DECLARE
  t0 NUMBER := DBMS_UTILITY.GET_TIME;
BEGIN
  DELETE FROM resumen_diario;

  INSERT INTO resumen_diario (sensor_id, dia, n_lecturas, valor_min, valor_max, valor_prom)
  SELECT sensor_id, TRUNC(fecha_hora), COUNT(*), MIN(valor), MAX(valor), ROUND(AVG(valor), 2)
    FROM lecturas
   GROUP BY sensor_id, TRUNC(fecha_hora);

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('de una sola vez: ' ||
      (DBMS_UTILITY.GET_TIME - t0) || ' centesimas de segundo');
END;
/
-- [VERIFICAR EN FREESQL] tiempo real observado: ____ centésimas de
-- segundo (reemplazar antes de entregar).

SELECT COUNT(*) FROM resumen_diario;
-- Esperado: 180 otra vez

SELECT * FROM resumen_diario WHERE sensor_id = 1 AND dia = DATE '2026-04-01';
-- Esperado: 48 | 18 | 28 | 22.59, idéntico a C1

-- C3. La cuenta, con números
-- ¿Cuántas veces se ejecutó un INSERT en C1? 6 sensores × 30 días =
-- 180 veces (una vez por cada combinación sensor/día del doble bucle).
-- ¿Y en C2? 1 vez — una sola sentencia INSERT ... SELECT ... GROUP BY.
--
-- Cada INSERT de C1 lleva adentro un SELECT sobre lecturas con
-- TRUNC(fecha_hora) en el WHERE, y como no hay ningún índice que le
-- sirva a esa expresión, cada uno de esos SELECT recorre la tabla
-- lecturas completa (8.640 filas) de punta a punta. ¿Cuántas filas de
-- lecturas lee C1 en total? 180 ejecuciones × 8.640 filas por
-- ejecución = 1.555.200 filas leídas en total.
-- ¿Cuántas lee C2? Como es una sola sentencia con un solo recorrido
-- completo de la tabla: 8.640 filas leídas en total (un solo TABLE
-- ACCESS FULL).
-- Razón entre las dos: 1.555.200 / 8.640 = 180. Coincide exactamente
-- con la cantidad de iteraciones del doble bucle: cada iteración de
-- más significa un recorrido completo de más sobre la misma tabla.

-- C4. El porqué, que no es "el bucle es lento"
-- ¿Cuántos cambios de contexto hubo en C1? 180 — uno por cada
-- sentencia SQL (el INSERT...SELECT) que el bloque PL/SQL le entrega
-- al motor SQL dentro del doble bucle. ¿Y en C2? 1 — una sola
-- sentencia SQL entregada una sola vez.
-- Si el bucle de C1 no tuviera SQL adentro (si solo sumara números en
-- memoria), ¿seguiría siendo lento? No. Un bucle de 180 iteraciones
-- que solo asigna o suma variables PL/SQL, sin ninguna sentencia SQL
-- adentro, corre por completo dentro del motor PL/SQL, sin ningún
-- cambio de contexto, y tardaría un tiempo despreciable.
-- Entonces, ¿el problema es el LOOP o lo que pusiste adentro del LOOP?
-- Es lo que hay adentro del LOOP. El LOOP en sí mismo no cuesta nada
-- relevante; lo que cuesta es que cada vuelta del LOOP dispara una
-- llamada al motor SQL, y esa llamada (el cambio de contexto más el
-- recorrido completo de la tabla) es lo que se repite 180 veces de
-- más.

-- C5. El plan, que sigue siendo la evidencia
EXPLAIN PLAN FOR
SELECT COUNT(*), MIN(valor), MAX(valor), AVG(valor)
  FROM lecturas WHERE sensor_id = 1 AND TRUNC(fecha_hora) = DATE '2026-04-01';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

EXPLAIN PLAN FOR
SELECT sensor_id, TRUNC(fecha_hora), COUNT(*), MIN(valor), MAX(valor), AVG(valor)
  FROM lecturas GROUP BY sensor_id, TRUNC(fecha_hora);
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
-- [VERIFICAR EN FREESQL] confirmar que ambos planes muestran
-- TABLE ACCESS FULL | LECTURAS (documentado como esperado en las
-- diapositivas: "los dos aviones son iguales. Los dos leen la tabla
-- entera").

-- Los dos planes dicen TABLE ACCESS FULL: mirados solos, parecen
-- igual de caros. ¿Qué información no está en el plan y explica toda
-- la diferencia? Cuántas VECES se va a ejecutar esa sentencia. El plan
-- describe el costo de UNA sola ejecución de la consulta que tiene
-- delante; no tiene ninguna forma de saber que el código que la rodea
-- (el doble bucle de C1) la va a invocar 180 veces en vez de una sola.
-- Esa multiplicación por 180 es información que vive en el código
-- PL/SQL, no en el plan de la sentencia SQL aislada.

-- C6. ¿Se contradicen la clase 9 y la de hoy?
-- No se contradicen: cada una contesta una pregunta distinta. El plan
-- (EXPLAIN QUERY PLAN / EXPLAIN PLAN) contesta "¿esta consulta,
-- ejecutada una vez, está bien resuelta? ¿usa un índice o recorre todo?".
-- El reloj (y, mejor todavía, contar cuántas veces se invoca esa
-- consulta) contesta una pregunta distinta: "¿cuántas veces se repite
-- este mismo costo?". La regla de la clase 9 ("el reloj es una
-- anécdota, el plan es la evidencia") sigue valiendo para la primera
-- pregunta. Lo que se agrega hoy es que, para la segunda pregunta, el
-- plan solo no alcanza: hace falta mirar también cuántas veces se
-- repite la ejecución, cosa que sí varía según el código que rodea a
-- la consulta.


-- =====================================================================
-- PARTE D · El error que pediste que te ignoren
-- =====================================================================

-- D1. El procedimiento sospechoso
CREATE OR REPLACE PROCEDURE cargar_labor (
  p_siembra_id  NUMBER,
  p_tipo        VARCHAR2,
  p_fecha       DATE,
  p_responsable VARCHAR2,
  p_costo       NUMBER
) AS
  v_id NUMBER;
BEGIN
  SELECT MAX(labor_id) + 1 INTO v_id FROM labores;
  INSERT INTO labores (labor_id, siembra_id, tipo_labor, fecha, responsable, costo_mano_obra)
  VALUES (v_id, p_siembra_id, p_tipo, p_fecha, p_responsable, p_costo);
EXCEPTION
  WHEN OTHERS THEN NULL;      -- "para que no moleste"
END;
/

-- D2. El lote de la mañana
SELECT COUNT(*) FROM labores;
-- Esperado: 19

BEGIN
  cargar_labor(1,  'riego',         DATE '2026-05-02', 'Marta Ruiz',  55);
  cargar_labor(99, 'riego',         DATE '2026-05-03', 'Marta Ruiz',  60);
  cargar_labor(3,  'fertilizacion', DATE '2026-05-04', 'Jorge Mina',  70);
  cargar_labor(2,  'poda',          DATE '2026-05-05', 'Jorge Mina', -10);
  COMMIT;
END;
/

SELECT COUNT(*) FROM labores;
-- Esperado: 21 (19 + 2). Se cargaron cuatro llamadas, pero solo dos
-- filas nuevas quedaron en la tabla.

-- ¿Cuántas se perdieron? Dos de las cuatro. ¿Cuál fue el error de cada
-- una que se perdió?
--   - cargar_labor(99, ...): siembra_id = 99 no existe en la tabla
--     siembras. Viola la clave foránea labores -> siembras.
--     Error real (atrapado y tapado por WHEN OTHERS): ORA-02291
--     (integrity constraint violated - parent key not found).
--   - cargar_labor(2, 'poda', ..., -10): costo_mano_obra = -10 viola
--     el CHECK (costo_mano_obra >= 0) de la tabla labores.
--     Error real (atrapado y tapado): ORA-02290 (check constraint
--     violated).
-- ¿Cómo me enteré? De ninguna manera por un mensaje de Oracle: el
-- bloque completo terminó reportando éxito ("PL/SQL procedure
-- successfully completed"), sin un solo error visible, porque
-- WHEN OTHERS THEN NULL absorbió ambos. Me enteré únicamente
-- comparando el conteo de labores ANTES (19) contra el conteo
-- DESPUÉS (21): la diferencia es 2, no 4, y esa diferencia es la
-- única pista de que algo falló. Si no hubiera anotado el conteo de
-- antes, jamás me habría enterado de que dos de las cuatro cargas
-- fallaron — habría dado por sentado, incorrectamente, que las cuatro
-- entraron bien.

-- D3. El diagnóstico
-- En la clase 8, CREATE VIEW IF NOT EXISTS corría sin error y no
-- hacía nada. En la clase 10, una fila mala entró sin error (con
-- PRAGMA foreign_keys = OFF). Hoy, un INSERT falla sin error (con
-- WHEN OTHERS THEN NULL). Lo que tienen en común las tres: en las tres
-- situaciones, la operación reporta éxito hacia afuera (ningún
-- mensaje de error, ningún código de salida distinto de "completado
-- con éxito"), mientras que por dentro no ocurrió lo que la persona
-- que ejecutó el comando esperaba que ocurriera. Esa frase es el
-- resumen del curso entero porque en las diez clases el motor solo
-- avisa activamente de lo que viola una regla que alguien le escribió
-- explícitamente (una FK, un CHECK, un UNIQUE); de todo lo demás
-- —incluyendo cuando el propio desarrollador le pide expresamente que
-- ignore el error, como hoy— el motor se queda callado y deja
-- exactamente la misma "cara de éxito" tanto si todo salió bien como
-- si no.

-- D4. El arreglo
CREATE OR REPLACE PROCEDURE cargar_labor (
  p_siembra_id  NUMBER,
  p_tipo        VARCHAR2,
  p_fecha       DATE,
  p_responsable VARCHAR2,
  p_costo       NUMBER
) AS
  v_id           NUMBER;
  e_fk_invalida  EXCEPTION;
  e_check_roto   EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_fk_invalida, -2291);
  PRAGMA EXCEPTION_INIT(e_check_roto,  -2290);
BEGIN
  SELECT MAX(labor_id) + 1 INTO v_id FROM labores;
  INSERT INTO labores (labor_id, siembra_id, tipo_labor, fecha, responsable, costo_mano_obra)
  VALUES (v_id, p_siembra_id, p_tipo, p_fecha, p_responsable, p_costo);
EXCEPTION
  WHEN e_fk_invalida THEN
    INSERT INTO bitacora (tabla, operacion, detalle)
    VALUES ('LABORES', 'ERROR',
            'siembra inexistente (' || p_siembra_id || '): ' || SQLERRM);
    RAISE_APPLICATION_ERROR(-20001, 'La siembra ' || p_siembra_id || ' no existe');

  WHEN e_check_roto THEN
    INSERT INTO bitacora (tabla, operacion, detalle)
    VALUES ('LABORES', 'ERROR',
            'costo invalido (' || p_costo || '): ' || SQLERRM);
    RAISE_APPLICATION_ERROR(-20002, 'El costo de mano de obra no puede ser negativo');

  WHEN OTHERS THEN
    INSERT INTO bitacora (tabla, operacion, detalle)
    VALUES ('LABORES', 'ERROR', SQLCODE || ' ' || SQLERRM);
    RAISE;
END;
/

-- Cuidado con el orden (lo pide el enunciado): el INSERT INTO bitacora
-- que hago DENTRO del mismo bloque EXCEPTION que después dispara
-- RAISE_APPLICATION_ERROR sigue formando parte de la MISMA transacción
-- que el INSERT fallido sobre labores. Si el bloque que llamó a
-- cargar_labor no atrapa ese error y el cliente (o el desarrollador)
-- termina haciendo ROLLBACK, ese ROLLBACK deshace tanto el intento
-- fallido de INSERT sobre labores como la fila que acabo de escribir
-- en bitacora dentro del manejador de excepción — la auditoría
-- desaparece junto con el error que se supone que debía documentar.
-- [VERIFICAR EN FREESQL] la solución real a esto es
-- PRAGMA AUTONOMOUS_TRANSACTION en un procedimiento aparte que solo
-- escriba en bitacora, para que ese INSERT viva en su propia
-- transacción independiente y sobreviva a un ROLLBACK del llamador.
-- El enunciado pide solo notar el problema, no resolverlo hoy.

-- Vuelvo a correr el lote de D2:
BEGIN
  cargar_labor(1,  'riego',         DATE '2026-05-06', 'Marta Ruiz',  55);
  cargar_labor(99, 'riego',         DATE '2026-05-07', 'Marta Ruiz',  60);
  cargar_labor(3,  'fertilizacion', DATE '2026-05-08', 'Jorge Mina',  70);
  cargar_labor(2,  'poda',          DATE '2026-05-09', 'Jorge Mina', -10);
  COMMIT;
END;
/
-- [VERIFICAR EN FREESQL] esperado según el enunciado: el bloque se
-- corta en la SEGUNDA llamada (siembra 99, que no existe). Como
-- cargar_labor ahora hace RAISE_APPLICATION_ERROR ante esa FK
-- inválida, y el bloque anónimo que la invoca no tiene su propio
-- manejador de excepciones, el error se propaga hacia arriba y aborta
-- el bloque completo: la tercera y la cuarta llamada (siembra 3 y
-- siembra 2) nunca llegan a ejecutarse. La primera llamada (siembra 1)
-- sí alcanzó a insertarse, pero como el bloque se cortó antes de
-- llegar a COMMIT, esa fila queda pendiente sin confirmar dentro de
-- la transacción — y, por el problema de orden que se advirtió arriba,
-- si en algún momento se hace ROLLBACK, se pierden juntas tanto esa
-- carga válida como la fila de bitacora que documentaba el error de
-- la siembra 99.

-- ¿Es peor que antes? Antes (con WHEN OTHERS THEN NULL), las cuatro
-- llamadas "terminaban bien" sin ningún aviso, y solo entraban 2 de 4
-- sin dejar ningún rastro de qué pasó ni por qué: el problema quedaba
-- totalmente oculto. Ahora el bloque se corta a la mitad y muestra un
-- error real de inmediato. En apariencia parece peor (menos filas
-- cargadas, un error visible en pantalla), pero es preferible: el
-- error es visible en el momento, no seis meses después comparando
-- conteos, y quien llamó al bloque sabe EXACTAMENTE en qué llamada y
-- por qué falló. Cortar temprano con un aviso fuerte es mejor que
-- seguir en silencio con datos incompletos y sin ninguna pista.

-- D5. La regla
-- WHEN OTHERS está bien puesto SIEMPRE QUE sea el último manejador de
-- una cadena que ya atrapó por separado, con su propio nombre, los
-- errores puntuales que se esperan de verdad (como e_fk_invalida y
-- e_check_roto arriba), Y SIEMPRE QUE dentro de él se deje un rastro
-- del error real (con SQLCODE/SQLERRM, por ejemplo escribiéndolo en
-- una bitácora) Y se vuelva a levantar el error con RAISE o
-- RAISE_APPLICATION_ERROR — nunca para absorberlo en silencio como en
-- la versión original de D1.


-- =====================================================================
-- PARTE E · El QUIÉN que SQLite no podía dar
-- =====================================================================

-- E1.
SELECT USER AS quien, SYSTIMESTAMP AS cuando FROM dual;
-- [VERIFICAR EN FREESQL] "quien" va a mostrar el usuario de la sesión
-- de FreeSQL (por ejemplo el nombre de la cuenta/workspace asignado al
-- conectarse), y "cuando" el timestamp exacto del momento de la
-- consulta. Confirma que la columna "quien" NO sale vacía ni da
-- error, a diferencia de SQLite con CURRENT_USER.

-- E2. El trigger que la clase 10 no pudo escribir
CREATE OR REPLACE TRIGGER trg_cosechas_bitacora
AFTER INSERT OR UPDATE OR DELETE ON cosechas
FOR EACH ROW
BEGIN
  INSERT INTO bitacora (tabla, operacion, clave, detalle, usuario)
  VALUES ('COSECHAS',
          CASE WHEN INSERTING THEN 'INSERT'
               WHEN UPDATING  THEN 'UPDATE' ELSE 'DELETE' END,
          TO_CHAR(NVL(:NEW.cosecha_id, :OLD.cosecha_id)),
          'kg: ' || NVL(TO_CHAR(:OLD.kg),'-') || ' -> ' || NVL(TO_CHAR(:NEW.kg),'-'),
          USER);
END;
/

-- E3. Prueba
INSERT INTO cosechas VALUES (10, 6, DATE '2026-05-10', 750, 'segunda', 'mercado local');
UPDATE cosechas SET kg = 800 WHERE cosecha_id = 10;
DELETE FROM cosechas WHERE cosecha_id = 10;
COMMIT;

SELECT operacion, clave, detalle, usuario, cuando FROM bitacora ORDER BY bitacora_id;
-- Esperado: 3 filas, una por operación, las tres con el mismo usuario
-- de sesión.
--   INSERT | 10 | kg: - -> 750  | (mi usuario de FreeSQL) | (timestamp)
--   UPDATE | 10 | kg: 750 -> 800 | (mi usuario de FreeSQL) | (timestamp)
--   DELETE | 10 | kg: 800 -> -   | (mi usuario de FreeSQL) | (timestamp)
-- [VERIFICAR EN FREESQL] confirmar las 3 filas y que "usuario" no
-- sale NULL en ninguna.

-- E4. Ahora la bitácora sabe quién. ¿Significa que ya se puede
-- auditar de verdad? Solo a medias: sabe qué CUENTA de base de datos
-- estaba conectada, no qué PERSONA física hizo el cambio. Si dos
-- personas comparten el mismo usuario de base (algo común, por
-- ejemplo cuando una aplicación se conecta siempre con un único
-- usuario técnico), la bitácora va a mostrar el mismo "quién" para
-- cambios hechos por personas distintas, y no hay forma de
-- distinguirlas a partir de esa columna. ¿Qué pasa si alguien hace
-- DROP TRIGGER trg_cosechas_bitacora? Deja de auditarse cualquier
-- cambio futuro, sin ningún rastro de que el trigger fue eliminado ni
-- de quién lo eliminó — la bitácora vuelve a quedar completamente
-- ciega, exactamente el mismo agujero que ya existía en la clase 10.
-- La respuesta de la clase 10 sigue valiendo: una bitácora es una
-- facilidad, no una garantía. Lo que cambió hoy es que tiene una
-- facilidad más (el quién), no que ahora sea infalible.


-- =====================================================================
-- PARTE F · Cierre
-- =====================================================================

-- 1) ¿Qué porcentaje de lo escrito en diez clases de SQLite corrió sin
-- cambios en Oracle? Diría que alrededor de un 70-80% del SQL
-- "puro" —SELECT, JOIN, GROUP BY, funciones de ventana, CTE, vistas,
-- índices— corrió idéntico, sin tocar una letra. Por ejemplo, la
-- consulta con RANK()/LAG() sobre un CTE que se muestra en las
-- diapositivas corre igual en Oracle que en SQLite. Del otro lado, una
-- porción más chica pero muy repetida tuvo que reescribirse siempre:
-- todo lo que dependía de sintaxis específica de SQLite, como
-- SELECT 1; (que se rompe con ORA-00923 y hay que convertir en
-- SELECT 1 FROM dual;) o DATE(fecha_hora) (que hay que convertir en
-- TRUNC(fecha_hora)).

-- 2) ¿Cuándo vale la pena escribir PL/SQL en vez de una sola sentencia
-- SQL? Cuando la lógica necesita de verdad ramificarse (IF), repetir
-- algo con una condición de corte que un solo SELECT no puede
-- expresar, manejar errores de forma controlada, o encadenar varias
-- operaciones dependientes entre sí (como el trigger de auditoría) —
-- nunca solo para hacer un cálculo que un SELECT ya resuelve solo,
-- como quedó demostrado hoy con resumen_diario.

-- 3) ¿Por qué la gente escribe WHEN OTHERS THEN NULL, con honestidad
-- y no con moral? Porque en el momento de escribirlo, lo que se
-- necesita es que el programa no se caiga frente al usuario o no
-- interrumpa un proceso más grande que sigue corriendo, y silenciar el
-- error es la forma más rápida y barata de conseguir eso bajo presión
-- de tiempo o de entrega. No es que nadie sepa que está mal: es que
-- hacerlo bien (excepciones con nombre, dejar rastro, volver a
-- levantar el error) cuesta más tiempo del que la persona tiene en ese
-- momento, y el costo de esa decisión lo termina pagando otra persona,
-- mucho después, cuando ya nadie se acuerda de que ese bloque existe.


-- =====================================================================
-- EXTRA · BULK COLLECT + FORALL
-- =====================================================================

DECLARE
  t0 NUMBER := DBMS_UTILITY.GET_TIME;

  TYPE t_sensor_tab IS TABLE OF sensores.sensor_id%TYPE;
  TYPE t_dia_tab    IS TABLE OF DATE;
  v_sensores t_sensor_tab;
  v_dias     t_dia_tab;

  TYPE t_num_arr IS TABLE OF NUMBER;
  TYPE t_dia_arr IS TABLE OF DATE;
  v_par_sensor t_num_arr := t_num_arr();
  v_par_dia    t_dia_arr := t_dia_arr();
BEGIN
  DELETE FROM resumen_diario;

  SELECT sensor_id BULK COLLECT INTO v_sensores FROM sensores ORDER BY sensor_id;
  SELECT DISTINCT TRUNC(fecha_hora) BULK COLLECT INTO v_dias FROM lecturas ORDER BY 1;

  FOR i IN v_sensores.FIRST .. v_sensores.LAST LOOP
    FOR j IN v_dias.FIRST .. v_dias.LAST LOOP
      v_par_sensor.EXTEND; v_par_sensor(v_par_sensor.LAST) := v_sensores(i);
      v_par_dia.EXTEND;    v_par_dia(v_par_dia.LAST)       := v_dias(j);
    END LOOP;
  END LOOP;

  FORALL k IN v_par_sensor.FIRST .. v_par_sensor.LAST
    INSERT INTO resumen_diario (sensor_id, dia, n_lecturas, valor_min, valor_max, valor_prom)
    SELECT v_par_sensor(k), v_par_dia(k), COUNT(*), MIN(valor), MAX(valor), ROUND(AVG(valor),2)
      FROM lecturas
     WHERE sensor_id = v_par_sensor(k) AND TRUNC(fecha_hora) = v_par_dia(k);

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('bulk collect + forall: ' ||
      (DBMS_UTILITY.GET_TIME - t0) || ' centesimas de segundo');
END;
/
-- [VERIFICAR EN FREESQL] tiempo real observado: ____ centésimas de
-- segundo. Verificar también: SELECT COUNT(*) FROM resumen_diario;
-- debe seguir dando 180, y la fila del sensor 1 / 2026-04-01 debe
-- seguir dando 48 | 18 | 28 | 22.59.

-- ¿Por qué esta versión queda ENTRE C1 y C2, ni tan lenta como el
-- bucle fila por fila ni tan rápida como la sentencia única?
-- FORALL le entrega al motor SQL las 180 combinaciones sensor/día de
-- una sola vez, como un lote — eso reduce los cambios de contexto de
-- 180 (uno por INSERT en C1) a 1 solo, igual que en C2. Pero por
-- dentro, el motor SQL sigue ejecutando 180 sentencias INSERT...SELECT
-- individuales (una por cada par sensor/día del lote), cada una
-- todavía con TRUNC(fecha_hora) en el WHERE sin índice que le sirva,
-- así que sigue leyendo la tabla lecturas completa 180 veces (los
-- mismos 1.555.200 registros leídos que en C1). En resumen: BULK
-- COLLECT + FORALL ahorra el costo del CAMBIO DE CONTEXTO repetido
-- (esa parte queda igual de barata que C2), pero no ahorra el costo
-- de RECORRER LA TABLA 180 veces (esa parte sigue igual de cara que
-- C1) — por eso el tiempo final cae en un punto intermedio entre las
-- dos.
