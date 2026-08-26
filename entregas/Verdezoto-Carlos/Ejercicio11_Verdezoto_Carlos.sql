-- =====================================================================
-- CURSO DE BASE DE DATOS  |  AgroDB  |  Ejercicio 11 (Oracle PL/SQL)
-- Alumno: Verdezoto, Carlos
-- Fecha: 24/08/2026
--
-- Este archivo se ejecuta DESPUES de datos/agrodb_oracle_clase11.sql,
-- en la MISMA sesion de Oracle FreeSQL / Oracle Database.
-- =====================================================================


-- =====================================================================
-- PARTE A · Lo que se rompe al cruzar la calle
-- =====================================================================

-- A1. Pruebas de compatibilidad:
-- 1. SELECT 1; 
--    Error: ORA-00923: FROM keyword not found where expected
--    Versión Oracle: SELECT 1 FROM dual;

-- 2. SELECT COUNT(*) FROM lecturas LIMIT 5;
--    Error: ORA-00933: SQL command not properly ended
--    Versión Oracle: SELECT COUNT(*) FROM lecturas FETCH FIRST 5 ROWS ONLY;

-- 3. DROP TABLE IF EXISTS basura;
--    Error: ORA-00933: SQL command not properly ended
--    Versión Oracle: DROP TABLE basura; (o usando un bloque PL/SQL condicional con EXECUTE IMMEDIATE).

-- 4. SELECT DATE(fecha_hora) FROM lecturas WHERE ROWNUM = 1;
--    Error: ORA-00904: "DATE": invalid identifier
--    Versión Oracle: SELECT TRUNC(fecha_hora) FROM lecturas WHERE ROWNUM = 1;

-- 5. SELECT sensor_id, COUNT(*) FROM lecturas GROUP BY sensor_id;
--    Resultado: Corre igual que en SQLite sin errores. Es un estándar ANSI SQL soportado por ambos motores.


-- A2. Comprobación de cadena vacía:
SELECT CASE WHEN '' IS NULL THEN 'la vacia ES null' ELSE 'la vacia NO es null' END AS resultado
  FROM dual;

/*
Respuesta A2:
En Oracle, las cadenas de longitud cero ('') son tratadas exactamente igual que un valor NULL. 
Si se quisiera distinguir «no anotó nada» de «anotó explícitamente que no hay nada», NO se podría usar '' en Oracle. 
En su lugar, se tendría que establecer una convención mediante un valor centinela explícito (por ejemplo, la cadena 'N/A' o 'SIN_OBSERVACION') o agregar una columna booleana/flag auxiliar que especifique el estado de la anotación.
*/


-- A3. Cicatriz del * 1.0:
SELECT SUM(c.kg) AS kg, SUM(c.kg) / l.hectareas AS kg_ha
  FROM cosechas c
  JOIN siembras s ON s.siembra_id = c.siembra_id
  JOIN lotes    l ON l.lote_id    = s.lote_id
 WHERE l.lote_id = 1
 GROUP BY l.hectareas;

/*
Respuesta A3:
Acá no hace falta el `* 1.0` porque en Oracle el tipo de dato NUMBER implementa aritmética de coma flotante/decimal de precisión fija real, por lo que la división produce decimales de forma nativa. 
El `* 1.0` no era una regla general de SQL, sino una defensa contra la división entera por defecto de SQLite cuando ambos operandos son enteros.
*/


-- A4. TRUNC(fecha_hora):
SELECT TRUNC(fecha_hora) AS dia, COUNT(*) AS n
  FROM lecturas
 WHERE sensor_id = 1
 GROUP BY TRUNC(fecha_hora)
 ORDER BY dia
 FETCH FIRST 3 ROWS ONLY;

/*
Respuesta A4:
Hipótesis: Sí, al igual que en SQLite, aplicar una función escalar como TRUNC() sobre una columna indexada en el WHERE evita que Oracle pueda utilizar un índice B-tree estándar sobre fecha_hora (a menos que se cree explícitamente un índice basado en funciones / Function-Based Index).
*/


-- =====================================================================
-- PARTE B · El primer bloque
-- =====================================================================

-- B1. Bloque básico
DECLARE
  v_total NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_total FROM lecturas;
  DBMS_OUTPUT.PUT_LINE('lecturas: ' || v_total);
END;
/

/*
Respuesta B1:
- `INTO` asigna el valor devuelto por la consulta SQL a una variable local de PL/SQL.
- Un `SELECT` suelto no sirve adentro de PL/SQL porque el motor procedural exige un destino en memoria (variable o cursor) para almacenar los datos retornados.
- Si le sacás la `/` al final, el cliente SQL (Worksheet/SQL*Plus) no ejecuta el bloque, ya que la barra diagonal es la orden explícita para enviar el bloque acumulado en el búfer al motor PL/SQL.
*/


-- B2. Uso de %TYPE
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
Respuesta B2:
Al usar %TYPE, si mañana la columna `sensores.tipo` se agranda a VARCHAR2(40), el bloque se recompila adaptando automáticamente el tamaño de la variable sin fallar. 
Si se hubiera escrito VARCHAR2(20) a mano y entra una cadena de mayor longitud, el bloque fallaría en tiempo de ejecución con un error de desbordamiento de búfer (ORA-06502).
*/


-- B3. Excepciones provocadas
-- Caso 0 filas:
DECLARE
  v_nombre fincas.nombre%TYPE;
BEGIN
  SELECT nombre INTO v_nombre FROM fincas WHERE finca_id = 99;
  DBMS_OUTPUT.PUT_LINE(v_nombre);
END;
/
-- Error: ORA-01403: no data found

-- Caso múltiples filas:
DECLARE
  v_nombre fincas.nombre%TYPE;
BEGIN
  SELECT nombre INTO v_nombre FROM fincas WHERE finca_id > 0;
  DBMS_OUTPUT.PUT_LINE(v_nombre);
END;
/
-- Error: ORA-01422: exact fetch returns more than requested number of rows

/*
Respuesta B3:
`SELECT ... INTO` exige estrictamente una fila devuelta. 
Si devuelve cero filas se dispara la excepción `NO_DATA_FOUND`. 
Si devuelve dos o más filas se dispara la excepción `TOO_MANY_ROWS`.
*/


-- B4. Captura de excepción NO_DATA_FOUND
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


-- B5. Reflexión B4 vs Clase 8:
/*
Respuesta B5:
Se parece en que ambas estructuraciones evitan que el flujo se interrumpa bruscamente con un error no controlado en la consola. 
Se diferencia en que `CREATE VIEW IF NOT EXISTS` silenciaba la acción sin ejecutarla ni dar aviso (comportamiento declarativo), mientras que el bloque EXCEPTION atrapa el evento excepcional de forma procedural y permite ejecutar una lógica de rescate o enviar un mensaje informativo controlado.
*/


-- =====================================================================
-- PARTE C · Fila por fila es lento por lento
-- =====================================================================

-- C1. Carga por iteración (Fila por fila)
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

SELECT COUNT(*) FROM resumen_diario;
SELECT * FROM resumen_diario WHERE sensor_id = 1 AND dia = DATE '2026-04-01';


-- C2. Carga directa (Set-based)
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

SELECT COUNT(*) FROM resumen_diario;
SELECT * FROM resumen_diario WHERE sensor_id = 1 AND dia = DATE '2026-04-01';


-- C3. La cuenta:
/*
Respuesta C3:
1. En C1 se ejecutó INSERT un total de 180 veces (6 sensores x 30 días). En C2 se ejecutó INSERT 1 sola vez.
2. C1 lee 180 veces la tabla completa (180 x 8.640 = 1.555.200 filas leídas en total).
3. C2 lee la tabla `lecturas` 1 sola vez (8.640 filas leídas en total).
4. Razón entre las dos: C1 lee la información 180 veces más datos que C2 (1.555.200 / 8.640 = 180).
*/


-- C4. Context Switch:
/*
Respuesta C4:
En C1 ocurrieron al menos 360 context switches (180 pasajes PL/SQL a SQL para las consultas/inserts y sus retornos), mientras que en C2 hubo únicamente 1 context switch. 
If el bucle C1 se ejecutara en memoria sin SQL no sería lento, por lo que el problema no es la estructura LOOP sino las llamadas SQL iterativas dentro del LOOP (intercambios entre motores).
*/


-- C5. Análisis del Plan de Ejecución:
EXPLAIN PLAN FOR
SELECT COUNT(*), MIN(valor), MAX(valor), AVG(valor)
  FROM lecturas WHERE sensor_id = 1 AND TRUNC(fecha_hora) = DATE '2026-04-01';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

EXPLAIN PLAN FOR
SELECT sensor_id, TRUNC(fecha_hora), COUNT(*), MIN(valor), MAX(valor), AVG(valor)
  FROM lecturas GROUP BY sensor_id, TRUNC(fecha_hora);
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

/*
Respuesta C5:
La información que no está explícita en el plan individual y explica toda la diferencia es la cantidad de veces que se ejecuta dicho plan de ejecución durante la tarea completa (180 veces en el primer método contra 1 sola vez en el segundo).
*/


-- C6. Plan vs Reloj:
/*
Respuesta C6:
Las dos clases no se contradicen, sino que evalúan aspectos complementarios del rendimiento de la base de datos. 
El plan contesta cómo accede el motor a los datos en una ejecución, y el reloj contesta el costo real acumulado por el impacto de la frecuencia de ejecuciones e intercambios de contexto.
*/


-- =====================================================================
-- PARTE D · El error que pediste que te ignoren
-- =====================================================================

-- D1. Procedimiento inicial
CREATE OR REPLACE PROCEDURE cargar_labor (
  p_siembra_id  NUMBER,
  p_tipo        VARCHAR2,
  p_fecha       DATE,
  p_responsable VARCHAR2,
  p_costo       NUMBER
) AS
  v_id NUMBER;
BEGIN
  SELECT COALESCE(MAX(labor_id), 0) + 1 INTO v_id FROM labores;
  INSERT INTO labores (labor_id, siembra_id, tipo_labor, fecha, responsable, costo_mano_obra)
  VALUES (v_id, p_siembra_id, p_tipo, p_fecha, p_responsable, p_costo);
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/


-- D2. Ejecución del lote
SELECT COUNT(*) FROM labores;

BEGIN
  cargar_labor(1,  'riego',         DATE '2026-05-02', 'Marta Ruiz',  55);
  cargar_labor(99, 'riego',         DATE '2026-05-03', 'Marta Ruiz',  60);
  cargar_labor(3,  'fertilizacion', DATE '2026-05-04', 'Jorge Mina',  70);
  cargar_labor(2,  'poda',          DATE '2026-05-05', 'Jorge Mina', -10);
  COMMIT;
END;
/

SELECT COUNT(*) FROM labores;

/*
Respuesta D2:
Entraron 2 labores. 
Se perdieron 2 labores:
- La 2da (siembra_id = 99, violación de FK ORA-02291).
- La 4ta (costo = -10, violación de CHECK constraint ORA-02290).
Nos enteramos únicamente porque contamos las filas antes y después; de lo contrario, el bloque responde con éxito ficticio ocultando la pérdida de datos.
*/


-- D3. Diagnóstico:
/*
Respuesta D3:
Las tres prácticas ocultan fallas de integridad o ejecución al usuario haciéndole creer que todo funcionó correctamente cuando en realidad los datos se corrompieron o no se guardaron.
*/


-- D4. Arreglo de cargar_labor
CREATE OR REPLACE PROCEDURE cargar_labor (
  p_siembra_id  NUMBER,
  p_tipo        VARCHAR2,
  p_fecha       DATE,
  p_responsable VARCHAR2,
  p_costo       NUMBER
) AS
  v_id NUMBER;
  
  e_fk_invalida  EXCEPTION;
  e_check_roto   EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_fk_invalida, -2291);
  PRAGMA EXCEPTION_INIT(e_check_roto,  -2290);
BEGIN
  SELECT COALESCE(MAX(labor_id), 0) + 1 INTO v_id FROM labores;
  INSERT INTO labores (labor_id, siembra_id, tipo_labor, fecha, responsable, costo_mano_obra)
  VALUES (v_id, p_siembra_id, p_tipo, p_fecha, p_responsable, p_costo);
EXCEPTION
  WHEN e_fk_invalida THEN
    INSERT INTO bitacora (tabla, operacion, clave, detalle)
    VALUES ('LABORES', 'ERROR', 'SIEMBRA ' || p_siembra_id, 'FK no existe: ' || SQLERRM);
    RAISE_APPLICATION_ERROR(-20001, 'Error: La siembra especificada no existe en la base de datos.');
    
  WHEN e_check_roto THEN
    INSERT INTO bitacora (tabla, operacion, clave, detalle)
    VALUES ('LABORES', 'ERROR', 'COSTO ' || p_costo, 'Check violado: ' || SQLERRM);
    RAISE_APPLICATION_ERROR(-20002, 'Error: El costo asignado viola la restriccion de valor no negativo.');
    
  WHEN OTHERS THEN
    INSERT INTO bitacora (tabla, operacion, clave, detalle)
    VALUES ('LABORES', 'ERROR', 'GENERAL', SQLERRM);
    RAISE_APPLICATION_ERROR(-20009, 'Error no esperado: ' || SQLERRM);
END;
/

/*
Observación sobre la ejecución del lote con D4:
Al correr nuevamente el lote de prueba, la ejecución se interrumpe inmediatamente al llegar a la segunda llamada (siembra_id = 99) lanzando la excepción ORA-20001. 
Esto interrumpe la transacción evitando inconsistencias. 
Es mucho mejor interrumpir el lote porque previene la inserción parcial de transacciones corruptas y notifica de inmediato la falla al usuario.
*/


-- D5. La regla de WHEN OTHERS:
/*
Respuesta D5:
WHEN OTHERS está bien puesto siempre que re-eleve el error (mediante RAISE o RAISE_APPLICATION_ERROR) o efectúe un registro de auditoría (logging) sin neutralizar el fallo de la transacción original.
*/


-- =====================================================================
-- PARTE E · El QUIÉN que SQLite no podía dar
-- =====================================================================

-- E1. Comprobación de usuario
SELECT USER AS quien, SYSTIMESTAMP AS cuando FROM dual;


-- E2. Trigger de bitácora
CREATE OR REPLACE TRIGGER trg_cosechas_bitacora
AFTER INSERT OR UPDATE OR DELETE ON cosechas
FOR EACH ROW
DECLARE
  v_op    VARCHAR2(10);
  v_clave VARCHAR2(60);
  v_det   VARCHAR2(400);
BEGIN
  IF INSERTING THEN
    v_op    := 'INSERT';
    v_clave := TO_CHAR(:NEW.cosecha_id);
    v_det   := 'Registrados ' || :NEW.kg || ' kg para la siembra ' || :NEW.siembra_id;
  ELSIF UPDATING THEN
    v_op    := 'UPDATE';
    v_clave := TO_CHAR(:NEW.cosecha_id);
    v_det   := 'Kilos modificado de ' || :OLD.kg || ' a ' || :NEW.kg;
  ELSIF DELETING THEN
    v_op    := 'DELETE';
    v_clave := TO_CHAR(:OLD.cosecha_id);
    v_det   := 'Eliminada cosecha de ' || :OLD.kg || ' kg pertenecientes a siembra ' || :OLD.siembra_id;
  END IF;

  INSERT INTO bitacora (tabla, operacion, clave, detalle, usuario, cuando)
  VALUES ('COSECHAS', v_op, v_clave, v_det, USER, SYSTIMESTAMP);
END;
/


-- E3. Prueba del trigger
INSERT INTO cosechas VALUES (10, 6, DATE '2026-05-10', 750, 'segunda', 'mercado local');
UPDATE cosechas SET kg = 800 WHERE cosecha_id = 10;
DELETE FROM cosechas WHERE cosecha_id = 10;
COMMIT;

SELECT operacion, clave, detalle, usuario, cuando FROM bitacora ORDER BY bitacora_id;


-- E4. Reflexión sobre auditoría
/*
Respuesta E4:
Que la bitácora registre el usuario de la base de datos mejora sustancialmente la rastreabilidad, pero no garantiza una auditoría infalible. 
Si múltiples usuarios comparten una única cuenta de conexión a nivel de aplicación (connection pooling sin contextualizar), todas las acciones quedan registradas bajo el mismo usuario técnico. 
Además, cualquier usuario con privilegios suficientes (como un DBA) podría deshabilitar o eliminar el trigger (`DROP TRIGGER`), eliminando la recolección de eventos.
*/


-- =====================================================================
-- PARTE F · Cierre
-- =====================================================================

/*
1. Aproximadamente el 80% del código SQL puro (DDL de tablas estándar, DML básico, INNER JOINs y funciones de agregación) corre sin cambios. 
   Por ejemplo, la sintaxis `SELECT sensor_id, COUNT(*) FROM lecturas GROUP BY sensor_id` funciona exactamente igual, mientras que funciones de manejo de fechas/paginación (como `LIMIT 5` o `DATE()`) requieren adaptación a las sintaxis propias de Oracle (`FETCH FIRST` y `TRUNC()`).

2. Vale la pena escribir PL/SQL únicamente cuando se requiere lógica procedural compleja (como validaciones transaccionales paso a paso, iteraciones procedurales complejas o triggers de auditoría) que no puede ser resuelta de forma eficiente o expresiva mediante una sentencia SQL puramente declarativa.

3. La gente escribe `WHEN OTHERS THEN NULL` principalmente por pragmatismo apresurado y pereza técnica, buscando evitar que los sistemas colapsen o interrumpan procesos en producción ante excepciones secundarias sin invertir tiempo en el diseño de una gestión de errores robusta.
*/