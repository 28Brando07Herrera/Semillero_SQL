-- EJERCICIO PRÁCTICO 11: Fila por fila es lento por lento
-- Estudiante: Cortez Axel
-- Motor: Oracle Database 23ai | Entorno: Oracle FreeSQL / SQL Developer

-- Configuración para visualizar salidas en consolas SQL*Plus / SQLcl (en FreeSQL activar pestaña DBMS Output)
SET SERVEROUTPUT ON;


-- PARTE A · LO QUE SE ROMPE AL CRUZAR LA CALLE

/*
A1. ANÁLISIS DE LAS CINCO CONSULTAS:

1) SELECT 1;
   - Error en Oracle: ORA-00923: FROM keyword not found where expected
   - Versión corregida en Oracle:
     SELECT 1 FROM dual;

2) SELECT COUNT(*) FROM lecturas LIMIT 5;
   - Error en Oracle: ORA-00933: SQL command not properly ended
   - Versión corregida en Oracle (ANSI SQL:2008 / Oracle 12c+):
     SELECT COUNT(*) FROM lecturas FETCH FIRST 5 ROWS ONLY;

3) DROP TABLE IF EXISTS basura;
   - Error en Oracle: ORA-00933: SQL command not properly ended (Oracle 23ai soporta IF EXISTS en DDL, pero en versiones previas o sin sintaxis nativa estricta se usa bloque PL/SQL condicional).
   - Versión canónica en PL/SQL:
     BEGIN
       EXECUTE IMMEDIATE 'DROP TABLE basura CASCADE CONSTRAINTS';
     EXCEPTION
       WHEN OTHERS THEN
         IF SQLCODE != -942 THEN RAISE; END IF;
     END;
     /

4) SELECT DATE(fecha_hora) FROM lecturas WHERE ROWNUM = 1;
   - Error en Oracle: ORA-00904: "DATE": invalid identifier (DATE no es una función en Oracle, es una palabra clave de tipo/literal).
   - Versión corregida en Oracle:
     SELECT TRUNC(fecha_hora) FROM lecturas WHERE ROWNUM = 1;

5) SELECT sensor_id, COUNT(*) FROM lecturas GROUP BY sensor_id;
   - Resultado: CORRE EXACTAMENTE IGUAL sin errores.
   - Lección: Las cláusulas estándar de agregación y agrupamiento ANSI SQL (GROUP BY, COUNT, SUM, etc.) son universales y se preservan intactas entre motores.
*/


-- A2. Comportamiento de la cadena vacía
SELECT CASE WHEN '' IS NULL THEN 'la vacia ES null' ELSE 'la vacia NO es null' END AS resultado
  FROM dual;

/*
COMENTARIO A2:
En Oracle, la cadena vacía ('') es semánticamente equivalente a NULL por diseño histórico del motor.
Si tuviera una columna 'observacion' y quisiera distinguir "no anotó nada" (NULL) de "anotó explícitamente que no hay nada", en Oracle no podría usar '' para la segunda; tendría que guardar un valor centinela explícito (como 'SIN_OBSERVACION' o 'N/A') o manejar una columna booleana auxiliar como 'tiene_observacion NUMBER(1)'.
*/


-- A3. La división en Oracle sin necesidad de * 1.0
SELECT SUM(c.kg) AS kg, SUM(c.kg) / l.hectareas AS kg_ha
  FROM cosechas c
  JOIN siembras s ON s.siembra_id = c.siembra_id
  JOIN lotes    l ON l.lote_id    = s.lote_id
 WHERE l.lote_id = 1
 GROUP BY l.hectareas;

/*
COMENTARIO A3:
Acá no hace falta el `* 1.0` porque el tipo NUMBER en Oracle maneja aritmética de punto flotante/decimal nativa de alta precisión en todas las divisiones.
El `* 1.0` que usábamos en SQLite era una defensa contra la división entera que SQLite aplica cuando divide dos enteros, no una regla del estándar SQL.
*/


-- A4. TRUNC(fecha_hora) para agrupar por día
SELECT TRUNC(fecha_hora) AS dia, COUNT(*) AS n
  FROM lecturas
 WHERE sensor_id = 1
 GROUP BY TRUNC(fecha_hora)
 ORDER BY dia
 FETCH FIRST 3 ROWS ONLY;

/*
COMENTARIO A4 (Mi hipótesis):
Al igual que en SQLite con DATE(), aplicar `TRUNC(fecha_hora)` en la cláusula WHERE de Oracle impide que el optimizador utilice un índice estándar B-Tree sobre 'fecha_hora' (salvo que se cree un índice basado en funciones: FUNCTION-BASED INDEX).
*/


-- PARTE B · EL PRIMER BLOQUE

-- B1. Estructura básica de un bloque anónimo
DECLARE
  v_total NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_total FROM lecturas;
  DBMS_OUTPUT.PUT_LINE('lecturas: ' || v_total);
END;
/

/*
COMENTARIO B1:
- La cláusula `INTO` captura el resultado devuelto por la consulta SQL y lo asigna a la variable local de PL/SQL en memoria.
- Un `SELECT` suelto no sirve en PL/SQL porque el motor procedural exige saber explícitamente en qué variable alojar los datos para poder manipularlos.
- Si le saco la barra `/` al final, el cliente SQL (SQLcl/FreeSQL) no sabe que el bloque terminó y se queda esperando más líneas sin enviar nada al servidor para su compilación.
*/


-- B2. Declaración con %TYPE
DECLARE
  v_tipo sensores.tipo%TYPE;
  v_n    NUMBER;
BEGIN
  SELECT s.tipo, COUNT(l.lectura_id)
    INTO v_tipo, v_n
    FROM sensores s
    JOIN lecturas l ON s.sensor_id = l.sensor_id
   WHERE s.sensor_id = 1
   GROUP BY s.tipo;

  DBMS_OUTPUT.PUT_LINE('sensor 1 (' || v_tipo || '): ' || v_n || ' lecturas');
END;
/

/*
COMENTARIO B2:
Si mañana alguien cambia 'sensores.tipo' de VARCHAR2(20) a VARCHAR2(40), el bloque con `%TYPE` hereda automáticamente el nuevo tamaño sin romperse.
Si hubiera puesto VARCHAR2(20) a mano, cuando entre un texto de más de 20 caracteres el bloque fallará con `ORA-06502: PL/SQL: numeric or value error: character string buffer too small`.
*/


-- B3. Excepciones provocadas a propósito
/*
1) Caso cero filas:
DECLARE
  v_nombre fincas.nombre%TYPE;
BEGIN
  SELECT nombre INTO v_nombre FROM fincas WHERE finca_id = 99;
  DBMS_OUTPUT.PUT_LINE(v_nombre);
END;
/
-- ERROR OBTENIDO: ORA-01403: no data found

2) Caso múltiples filas:
DECLARE
  v_nombre fincas.nombre%TYPE;
BEGIN
  SELECT nombre INTO v_nombre FROM fincas;
  DBMS_OUTPUT.PUT_LINE(v_nombre);
END;
/
-- ERROR OBTENIDO: ORA-01422: exact fetch returns more than requested number of rows

COMENTARIO B3:
`SELECT ... INTO` exige estrictamente devolver EXACTAMENTE 1 fila.
Si devuelve 0 filas lanza la excepción `NO_DATA_FOUND` (ORA-01403).
Si devuelve 2 o más filas lanza la excepción `TOO_MANY_ROWS` (ORA-01422).
*/


-- B4. Manejo controlado con bloque EXCEPTION
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

/*
COMENTARIO B5:
Se parece a `CREATE VIEW IF NOT EXISTS` en que ambos evitan que el programa aborte con una pantalla de error visible.
Se diferencia en que `IF NOT EXISTS` oculta silenciosamente que la acción no se realizó (enmascara un estado viejo), mientras que el bloque `EXCEPTION` aquí captura conscientemente el caso previsto y ejecuta una acción controlada de negocio informando lo sucedido.
*/


-- PARTE C · FILA POR FILA ES LENTO POR LENTO

-- C1. Carga iterativa (Fila por fila / Slow by Slow)
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
  DBMS_OUTPUT.PUT_LINE('fila por fila: ' || (DBMS_UTILITY.GET_TIME - t0) || ' centesimas de segundo');
END;
/

-- Verificación C1:
SELECT COUNT(*) AS total_resumen FROM resumen_diario;
SELECT * FROM resumen_diario WHERE sensor_id = 1 AND dia = DATE '2026-04-01';


-- C2. Carga en un solo paso (Set-based SQL)
DECLARE
  t0 NUMBER := DBMS_UTILITY.GET_TIME;
BEGIN
  DELETE FROM resumen_diario;

  INSERT INTO resumen_diario (sensor_id, dia, n_lecturas, valor_min, valor_max, valor_prom)
  SELECT sensor_id, TRUNC(fecha_hora), COUNT(*), MIN(valor), MAX(valor), ROUND(AVG(valor), 2)
    FROM lecturas
   GROUP BY sensor_id, TRUNC(fecha_hora);

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('de una sola vez: ' || (DBMS_UTILITY.GET_TIME - t0) || ' centesimas de segundo');
END;
/

-- Verificación C2 (Mismos resultados exactos):
SELECT COUNT(*) AS total_resumen FROM resumen_diario;
SELECT * FROM resumen_diario WHERE sensor_id = 1 AND dia = DATE '2026-04-01';

/*
COMENTARIO C3 (La cuenta matemática):
1. En C1 se ejecutan 180 sentencias INSERT individuales (6 sensores * 30 días). En C2 se ejecuta exactamente 1 solo INSERT.
2. Cada iteración de C1 ejecuta un SELECT con `TRUNC(fecha_hora) = d.dia` que recorre las 8.640 filas de lecturas mediante TABLE ACCESS FULL. En total, C1 lee: 180 * 8.640 = 1.555.200 filas.
3. C2 lee la tabla 'lecturas' una sola vez: 8.640 filas.
4. Razón entre lecturas: 1.555.200 / 8.640 = 180 a 1. C1 trabaja 180 veces más volumen de datos.
*/

/*
COMENTARIO C4:
En C1 ocurren al menos 360 context switches (cambios de contexto entre el motor procedural de PL/SQL y el motor relacional de SQL para enviar consultas y recibir resultados). En C2 solo hay 1 context switch.
Si el bucle sumara números en memoria no sería lento; el cuello de botella no es el LOOP en sí, sino cruzar la frontera entre PL/SQL y SQL 180 veces ejecutando consultas pesadas adentro.
*/

-- C5. Comparación de planes de ejecución
EXPLAIN PLAN FOR
SELECT COUNT(*), MIN(valor), MAX(valor), AVG(valor)
  FROM lecturas WHERE sensor_id = 1 AND TRUNC(fecha_hora) = DATE '2026-04-01';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

EXPLAIN PLAN FOR
SELECT sensor_id, TRUNC(fecha_hora), COUNT(*), MIN(valor), MAX(valor), AVG(valor)
  FROM lecturas GROUP BY sensor_id, TRUNC(fecha_hora);
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

/*
COMENTARIO C5:
Ambos planes muestran `TABLE ACCESS FULL`. 
La información que no está en el plan individual es la cantidad de VECES que se repite la operación: el plan describe el costo de 1 ejecución aislada, pero C1 corre ese plan 180 veces seguidas mientras que C2 lo corre solo 1 vez.
*/

/*
COMENTARIO C6:
No se contradicen. El plan contesta "¿cómo va a acceder el motor a los datos en una sentencia?", mientras que el reloj y las mediciones contestan "¿cuánto cuesta en total cuando esa sentencia se invoca cientos de veces dentro de un flujo procedural?".
*/


-- PARTE D · EL ERROR QUE PEDISTE QUE TE IGNOREN

-- D1. Procedimiento con la mala práctica WHEN OTHERS THEN NULL
CREATE OR REPLACE PROCEDURE cargar_labor (
  p_siembra_id  NUMBER,
  p_tipo        VARCHAR2,
  p_fecha       DATE,
  p_responsable VARCHAR2,
  p_costo       NUMBER
) AS
  v_id NUMBER;
BEGIN
  SELECT NVL(MAX(labor_id), 0) + 1 INTO v_id FROM labores;
  INSERT INTO labores (labor_id, siembra_id, tipo_labor, fecha, responsable, costo_mano_obra)
  VALUES (v_id, p_siembra_id, p_tipo, p_fecha, p_responsable, p_costo);
EXCEPTION
  WHEN OTHERS THEN NULL; -- Se traga cualquier error
END;
/

-- D2. Prueba del lote
SELECT COUNT(*) AS labores_antes FROM labores;

BEGIN
  cargar_labor(1,  'riego',         DATE '2026-05-02', 'Marta Ruiz',  55);
  cargar_labor(99, 'riego',         DATE '2026-05-03', 'Marta Ruiz',  60);
  cargar_labor(3,  'fertilizacion', DATE '2026-05-04', 'Jorge Mina',  70);
  cargar_labor(2,  'poda',          DATE '2026-05-05', 'Jorge Mina', -10);
  COMMIT;
END;
/

SELECT COUNT(*) AS labores_despues FROM labores;

/*
COMENTARIO D2:
Se enviaron 4 labores pero solo entraron 2 (el conteo pasó de 19 a 21).
Se perdieron 2: la de siembra_id = 99 (violó FK de siembras) y la de costo = -10 (violó CHECK de costo no negativo).
Me enteré únicamente porque conté antes y después; si nadie revisa el conteo, el sistema reporta éxito y los datos se pierden en silencio sin dejar rastro.
*/

/*
COMENTARIO D3:
Lo que tienen en común es que enmascaran el fallo y devuelven una falsa sensación de éxito: el motor no avisa de un error si tú le pides explícitamente que lo ignore.
*/


-- D4. Procedimiento corregido con registro autónomo y relanzamiento del error
CREATE OR REPLACE PROCEDURE registrar_error_bitacora (
  p_tabla   VARCHAR2,
  p_detalle VARCHAR2
) AS
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  INSERT INTO bitacora (tabla, operacion, clave, detalle, usuario, cuando)
  VALUES (p_tabla, 'ERROR', NULL, SUBSTR(p_detalle, 1, 400), USER, SYSTIMESTAMP);
  COMMIT;
END;
/

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
  SELECT NVL(MAX(labor_id), 0) + 1 INTO v_id FROM labores;
  
  INSERT INTO labores (labor_id, siembra_id, tipo_labor, fecha, responsable, costo_mano_obra)
  VALUES (v_id, p_siembra_id, p_tipo, p_fecha, p_responsable, p_costo);

EXCEPTION
  WHEN e_fk_invalida THEN
    registrar_error_bitacora('LABORES', 'FK Invalida: La siembra ' || p_siembra_id || ' no existe en el sistema.');
    RAISE_APPLICATION_ERROR(-20001, 'ERROR DE NEGOCIO: La siembra ' || p_siembra_id || ' no existe.');

  WHEN e_check_roto THEN
    registrar_error_bitacora('LABORES', 'CHECK Roto: El costo de mano de obra no puede ser negativo (' || p_costo || ').');
    RAISE_APPLICATION_ERROR(-20002, 'ERROR DE NEGOCIO: Costo de mano de obra invalido (' || p_costo || ').');

  WHEN OTHERS THEN
    registrar_error_bitacora('LABORES', 'Error no clasificado: ' || SQLCODE || ' - ' || SQLERRM);
    RAISE;
END;
/

-- Prueba D4:
/*
BEGIN
  cargar_labor(1,  'riego',         DATE '2026-05-02', 'Marta Ruiz',  55);
  cargar_labor(99, 'riego',         DATE '2026-05-03', 'Marta Ruiz',  60);
  cargar_labor(3,  'fertilizacion', DATE '2026-05-04', 'Jorge Mina',  70);
  cargar_labor(2,  'poda',          DATE '2026-05-05', 'Jorge Mina', -10);
  COMMIT;
END;
/
-- El bloque se corta en la segunda sentencia con: ORA-20001: ERROR DE NEGOCIO: La siembra 99 no existe.

COMENTARIO D4:
Que el lote se corte a la mitad NO es peor; al contrario, es lo correcto porque evita persistir datos inconsistentes a medias (infracción de atomicidad) y le avisa inmediatamente a quien envió la carga para que corrija el archivo de origen.
*/

/*
COMENTARIO D5:
`WHEN OTHERS` está bien puesto siempre que registre el error original (con SQLCODE/SQLERRM o en una bitácora) y termine obligatoriamente con `RAISE` o `RAISE_APPLICATION_ERROR` para no silenciar la excepción.
*/


-- PARTE E · EL QUIÉN QUE SQLITE NO PODÍA DAR

-- E1. Identificación del usuario de sesión en Oracle
SELECT USER AS quien, SYSTIMESTAMP AS cuando FROM dual;


-- E2. Trigger de auditoría con USER y evaluación de operaciones DML
CREATE OR REPLACE TRIGGER trg_cosechas_bitacora
AFTER INSERT OR UPDATE OR DELETE ON cosechas
FOR EACH ROW
BEGIN
  IF INSERTING THEN
    INSERT INTO bitacora (tabla, operacion, clave, detalle, usuario, cuando)
    VALUES (
      'COSECHAS',
      'INSERT',
      'cosecha_id=' || :NEW.cosecha_id,
      'Siembra=' || :NEW.siembra_id || ', Kg=' || :NEW.kg || ', Calidad=' || :NEW.calidad,
      USER,
      SYSTIMESTAMP
    );
  ELSIF UPDATING THEN
    INSERT INTO bitacora (tabla, operacion, clave, detalle, usuario, cuando)
    VALUES (
      'COSECHAS',
      'UPDATE',
      'cosecha_id=' || :OLD.cosecha_id,
      'Kg anterior=' || :OLD.kg || ' -> Kg nuevo=' || :NEW.kg,
      USER,
      SYSTIMESTAMP
    );
  ELSIF DELETING THEN
    INSERT INTO bitacora (tabla, operacion, clave, detalle, usuario, cuando)
    VALUES (
      'COSECHAS',
      'DELETE',
      'cosecha_id=' || :OLD.cosecha_id,
      'Fila eliminada: Siembra=' || :OLD.siembra_id || ', Kg=' || :OLD.kg,
      USER,
      SYSTIMESTAMP
    );
  END IF;
END;
/


-- E3. Prueba del trigger y verificación de auditoría completa
INSERT INTO cosechas VALUES (10, 6, DATE '2026-05-10', 750, 'segunda', 'mercado local');
UPDATE cosechas SET kg = 800 WHERE cosecha_id = 10;
DELETE FROM cosechas WHERE cosecha_id = 10;
COMMIT;

SELECT operacion, clave, detalle, usuario, cuando 
  FROM bitacora 
 WHERE tabla = 'COSECHAS'
 ORDER BY bitacora_id;

/*
COMENTARIO E4:
Saber el 'USER' de base de datos no garantiza auditoría absoluta si múltiples personas comparten el mismo usuario de conexión del pool de la aplicación web.
Además, si un administrador hace `DROP TRIGGER trg_cosechas_bitacora`, la auditoría queda deshabilitada sin aviso. La bitácora en BD es una gran herramienta técnica, pero la seguridad real requiere cuentas individuales y roles mínimos (Least Privilege).
*/


-- PARTE F · CIERRE

/*
1. Porcentaje de compatibilidad SQLite vs Oracle:
Aproximadamente un 70% del SQL estándar corrió sin cambios (SELECTs analíticos con agregaciones, GROUP BY, subconsultas y CTEs corrieron idénticos).
Lo que falló fue la sintaxis propietaria: por ejemplo, `LIMIT 10` y `DATE(columna)` en SQLite frente a `FETCH FIRST 10 ROWS ONLY` y `TRUNC(columna)` en Oracle.

2. ¿Cuándo escribir PL/SQL?:
Vale la pena escribir PL/SQL cuando se requiere orquestar flujos de lógica transaccional compleja, validaciones con reglas de negocio dinámicas, manejo estructurado de excepciones o tareas de procesamiento batch que no pueden resolverse en una sola sentencia SQL declarativa.

3. ¿Por qué la gente usa WHEN OTHERS THEN NULL?:
Porque en el corto plazo "apaga fuegos" permitiendo que los scripts de despliegue terminen en verde y los sistemas sigan operando sin reportar fallos visibles, postergando la deuda técnica a costa de corromper la integridad de los datos en silencio.
*/


-- EXTRA (+5 PUNTOS): Carga con BULK COLLECT + FORALL


DECLARE
  TYPE t_resumen IS RECORD (
    sensor_id  NUMBER,
    dia        DATE,
    n_lecturas NUMBER,
    valor_min  NUMBER(10,2),
    valor_max  NUMBER(10,2),
    valor_prom NUMBER(10,2)
  );
  TYPE t_tab_resumen IS TABLE OF t_resumen;
  v_datos t_tab_resumen;
  t0 NUMBER := DBMS_UTILITY.GET_TIME;
BEGIN
  DELETE FROM resumen_diario;

  -- Trae los registros en memoria en un solo viaje
  SELECT sensor_id, TRUNC(fecha_hora), COUNT(*), MIN(valor), MAX(valor), ROUND(AVG(valor), 2)
    BULK COLLECT INTO v_datos
    FROM lecturas
   GROUP BY sensor_id, TRUNC(fecha_hora);

  -- Inserta por lotes minimizando context switches
  FORALL i IN 1..v_datos.COUNT
    INSERT INTO resumen_diario VALUES v_datos(i);

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('bulk collect + forall: ' || (DBMS_UTILITY.GET_TIME - t0) || ' centesimas de segundo');
END;
/

-- Verificación Extra:
SELECT COUNT(*) AS total_bulk FROM resumen_diario;

/*
JUSTIFICACIÓN EXTRA:
BULK COLLECT + FORALL queda en rendimiento justo entre C1 y C2:
Es infinitamente más rápido que C1 porque reduce los 180 context switches a prácticamente 2 intercambios por lotes en memoria (uno para traer los datos y otro para enviarlos al motor SQL).
Sin embargo, sigue siendo ligeramente más lento que C2 (INSERT directo de una sola sentencia) debido al sobrecosto de asignar memoria en la PGA para la colección de PL/SQL antes de escribir en disco.
*/