-- Ejercicio11_Byron_Yaguar.sql
-- Ejercicio 11: Fila por fila es lento por lento
-- PL/SQL en Oracle · FreeSQLa
-- Byron Yaguar

-- ============================================================================
-- PARTE A: Lo que se rompe al cruzar la calle
-- ============================================================================

-- A1: Sentencias que se rompen
/*
Ejecutando cada una:

1. SELECT 1;
   Resultado: OK, corre igual (1)

2. SELECT COUNT(*) FROM lecturas LIMIT 5;
   Error: ORA-00933: SQL command not properly ended
   Versión Oracle: SELECT COUNT(*) FROM lecturas FETCH FIRST 5 ROWS ONLY;
   (LIMIT no existe en Oracle; se usa FETCH FIRST ... ROWS ONLY en Oracle 12+)

3. DROP TABLE IF EXISTS basura;
   Error: ORA-00903: invalid table name
   Versión Oracle:
   BEGIN
     EXECUTE IMMEDIATE 'DROP TABLE basura';
   EXCEPTION
     WHEN OTHERS THEN NULL;
   END;
   (Oracle no tiene DROP IF EXISTS; requiere PL/SQL con EXCEPTION)

4. SELECT DATE(fecha_hora) FROM lecturas WHERE ROWNUM = 1;
   Error: ORA-00904: "DATE": invalid identifier
   Versión Oracle: SELECT TRUNC(fecha_hora) FROM lecturas WHERE ROWNUM = 1;
   (DATE() es función de SQLite; Oracle usa TRUNC() o DATE literal)

5. SELECT sensor_id, COUNT(*) FROM lecturas GROUP BY sensor_id;
   Resultado: OK, corre igual (lista de 6 sensores con sus conteos)
   Esta es la mitad de la lección: SQL estándar corre en los dos.
*/

-- A2: La cadena vacía
/*
SELECT CASE WHEN '' IS NULL THEN 'la vacia ES null' ELSE 'la vacia NO es null' END AS resultado
  FROM dual;

Resultado en Oracle: "la vacia ES null"
Resultado en SQLite: "la vacia NO es null"

En Oracle, la cadena vacía '' es NULL. Para distinguir "no anotó" de "anotó que no hay nada":
- NO se puede hacerlo igual que en SQLite, porque '' se trata como NULL automáticamente
- Tendrías que usar un valor especial (ej. '*sin datos*' o un número -1 para banderas)
  o manejar el NULL explícitamente en la aplicación, sabiendo que en Oracle
  una columna vacía y una columna NULL son lo mismo.
*/

SELECT CASE WHEN '' IS NULL THEN 'la vacia ES null' ELSE 'la vacia NO es null' END AS resultado
  FROM dual;

-- A3: La cicatriz del * 1.0
/*
SELECT SUM(c.kg) AS kg, SUM(c.kg) / l.hectareas AS kg_ha
  FROM cosechas c
  JOIN siembras s ON s.siembra_id = c.siembra_id
  JOIN lotes    l ON l.lote_id    = s.lote_id
 WHERE l.lote_id = 1
 GROUP BY l.hectareas;

Resultado: 7300, 256.14

¿Por qué acá no hace falta el * 1.0?
El * 1.0 era una defensa contra algo particular de SQLite: en SQLite, la división entre
dos INTEGER devuelve un entero truncado. En Oracle, NUMBER es un tipo numérico universal
que ya maneja decimales por defecto. El SUM() devuelve NUMBER, no INTEGER, así que la
división siempre tiene decimales. El * 1.0 era una regla de SQLite, no de SQL en general.
*/

SELECT SUM(c.kg) AS kg, SUM(c.kg) / l.hectareas AS kg_ha
  FROM cosechas c
  JOIN siembras s ON s.siembra_id = c.siembra_id
  JOIN lotes    l ON l.lote_id    = s.lote_id
 WHERE l.lote_id = 1
 GROUP BY l.hectareas;

-- A4: TRUNC en Oracle
/*
SELECT TRUNC(fecha_hora) AS dia, COUNT(*) AS n
  FROM lecturas
 WHERE sensor_id = 1
 GROUP BY TRUNC(fecha_hora)
 ORDER BY dia
 FETCH FIRST 3 ROWS ONLY;

Esperado: 3 filas, días 1, 2, 3 de abril, 48 cada uno.
Resultado: 48, 48, 48 (correcto)

Hipótesis: En el ejercicio 9 aprendieron que DATE(fecha_hora) en el WHERE anula el índice
porque ejecuta la función en cada fila ANTES de filtrar. ¿Vale lo mismo para TRUNC()?
Sí, vale lo mismo. TRUNC es una función y se ejecuta row-by-row, no puede usar índices.
Si hay índice en fecha_hora, un TRUNC() en el WHERE lo hace inútil.
(Esto se verificará en C5.)
*/

SELECT TRUNC(fecha_hora) AS dia, COUNT(*) AS n
  FROM lecturas
 WHERE sensor_id = 1
 GROUP BY TRUNC(fecha_hora)
 ORDER BY dia
 FETCH FIRST 3 ROWS ONLY;

-- ============================================================================
-- PARTE B: El primer bloque
-- ============================================================================

-- B1: Anatomía de un bloque
/*
¿Qué hace INTO?
INTO lleva el resultado del SELECT a una variable PL/SQL. Sin INTO, el SELECT no
devuelve nada al bloque (en SQL puro, devolveríamos un cursor; en PL/SQL es más directo).

¿Por qué un SELECT suelto no sirve adentro de PL/SQL?
Porque PL/SQL no es SQL: es un lenguaje procedural que CONTIENE SQL. Un SELECT suelto
en PL/SQL (sin INTO, sin FOR, sin cursor) es un error: no sabe qué hacer con las filas
que devuelve. Tiene que mandarlas a algún lado (una variable, un cursor, imprimir).

¿Qué pasaría si le sacás la / del final?
La barra / sola es la que le dice al cliente SQL*Plus o FreeSQLa: "acá termina el bloque,
mandalo al servidor". Sin ella, el cliente espera más líneas. El bloque nunca se ejecuta.
(En algunos clientes gráficos puedes usar Ctrl+Enter, pero la barra es la forma estándar.)
*/

DECLARE
  v_total NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_total FROM lecturas;
  DBMS_OUTPUT.PUT_LINE('lecturas: ' || v_total);
END;
/

-- B2: %TYPE, y por qué importa
/*
¿Qué pasa si mañana alguien agranda sensores.tipo a VARCHAR2(40)?
Con %TYPE: el bloque se adapta automáticamente. La variable v_tipo seguirá siendo
VARCHAR2(40) sin que toques el código.
Sin %TYPE (VARCHAR2(20) a mano): tendrías un bug latente. Si la columna crece a 40,
tu variable se queda en 20, y datos que cabían en la columna no caben en la variable.
*/

DECLARE
  v_tipo    sensores.tipo%TYPE;
  v_n       NUMBER;
BEGIN
  SELECT tipo INTO v_tipo FROM sensores WHERE sensor_id = 1;
  SELECT COUNT(*) INTO v_n FROM lecturas WHERE sensor_id = 1;
  DBMS_OUTPUT.PUT_LINE('sensor 1 (' || v_tipo || '): ' || v_n || ' lecturas');
END;
/

-- B3: La excepción que te van a hacer conocer a las malas
/*
Primero, ejecutar con finca_id = 99 (no existe):
Error: ORA-01403: no data found
Excepción: NO_DATA_FOUND

Después, con un WHERE que devuelva tres filas (ej. WHERE finca_id IN (1, 2, 3)):
Error: ORA-01422: exact fetch returns more than requested number of rows
Excepción: TOO_MANY_ROWS

Regla: SELECT ... INTO exige exactamente una fila.
- Cero filas → NO_DATA_FOUND
- Dos o más filas → TOO_MANY_ROWS
*/

DECLARE
  v_nombre fincas.nombre%TYPE;
BEGIN
  SELECT nombre INTO v_nombre FROM fincas WHERE finca_id = 99;
  DBMS_OUTPUT.PUT_LINE(v_nombre);
END;
/

DECLARE
  v_nombre fincas.nombre%TYPE;
BEGIN
  SELECT nombre INTO v_nombre FROM fincas WHERE finca_id IN (1, 2, 3);
  DBMS_OUTPUT.PUT_LINE(v_nombre);
END;
/

-- B4: Atajarlas
/*
Manejo de NO_DATA_FOUND para finca 99:
*/

DECLARE
  v_nombre fincas.nombre%TYPE;
BEGIN
  BEGIN
    SELECT nombre INTO v_nombre FROM fincas WHERE finca_id = 99;
    DBMS_OUTPUT.PUT_LINE(v_nombre);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      DBMS_OUTPUT.PUT_LINE('finca 99: no existe');
  END;
END;
/

-- B5: IF NOT EXISTS vs manejo de excepciones
/*
En la clase 8, CREATE VIEW IF NOT EXISTS no daba error y tampoco hacía lo que querías.
Hoy, WHEN OTHERS THEN NULL también no da error y tampoco hace lo que querías.

Se parecen en: los dos silencian un error sin intentar manejar la situación real.
Se diferencian en: IF NOT EXISTS es una sintaxis SQL que Oracle no tiene (SQLite sí);
WHEN OTHERS es Oracle PL/SQL que oculta el error adrede. La raíz es la misma: evitar
que el código explote, pero sin resolver el problema. La clase 8 lo notó en SQL; hoy
lo vemos en PL/SQL.
*/

-- ============================================================================
-- PARTE C: Fila por fila es lento por lento
-- ============================================================================

-- C1: El bucle que parece razonable
-- Ejecutar y anotar el tiempo que imprime
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

-- Verificar resultados
SELECT COUNT(*) FROM resumen_diario;
-- Esperado: 180

SELECT * FROM resumen_diario WHERE sensor_id = 1
   AND dia = DATE '2026-04-01';
-- Esperado: 48 | 18 | 28 | 22.59

-- C2: La misma tarea, una sentencia
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

-- Verificar que dan lo mismo
SELECT COUNT(*) FROM resumen_diario;
-- 180 otra vez

SELECT * FROM resumen_diario WHERE sensor_id = 1
   AND dia = DATE '2026-04-01';
-- 48 | 18 | 28 | 22.59, idéntico

-- C3: La cuenta
/*
1. ¿Cuántas veces se ejecutó un INSERT?
   C1: 180 veces (6 sensores × 30 días)
   C2: 1 vez

2. Cada INSERT de C1 lleva un SELECT con TRUNC(fecha_hora) en WHERE.
   ¿Cuántas filas de lecturas lee C1 en total?
   Cada uno de los 180 INSERTs hace un TABLE FULL SCAN de 8.640 filas.
   Total: 180 × 8.640 = 1.555.200 filas leídas

3. ¿Cuántas lee C2?
   Un solo GROUP BY sobre 8.640 filas: 8.640 filas leídas

4. Razón:
   C1 lee 1.555.200 / 8.640 = 180 veces más filas que C2
*/

-- C4: El porqué, que no es «el bucle es lento»
/*
Context switches en C1: 180 INSERTs × 2 (una por SELECT adentro) = 360 cambios de motor
Context switches en C2: 1 INSERT + 1 SELECT (dentro del INSERT) = 2 cambios de motor

Si el bucle de C1 no tuviera SQL adentro (si solo sumara números en memoria),
seguiría iterando 180 veces, pero NO tendría context switches. Sería rápido.

Entonces, ¿el problema es el LOOP o lo que pusiste adentro?
El problema no es el LOOP: es el SQL adentro del LOOP. El LOOP mismo es gratis.
Lo caro es cruzar la frontera entre PL/SQL y SQL 180 veces en lugar de hacerlo 2 veces.
*/

-- C5: El plan, que sigue siendo la evidencia
EXPLAIN PLAN FOR
SELECT COUNT(*), MIN(valor), MAX(valor), AVG(valor)
  FROM lecturas WHERE sensor_id = 1 AND TRUNC(fecha_hora) = DATE '2026-04-01';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

EXPLAIN PLAN FOR
SELECT sensor_id, TRUNC(fecha_hora), COUNT(*), MIN(valor), MAX(valor), AVG(valor)
  FROM lecturas GROUP BY sensor_id, TRUNC(fecha_hora);
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

/*
Los dos planes dicen TABLE ACCESS FULL. Los dos leen la tabla entera.
Mirando solo el plan, parecen igual de caros.

¿Qué información NO está en el plan?
El plan NO dice cuántas VECES se ejecuta cada sentencia. El primer plan se ejecuta 180 veces;
el segundo, una sola vez. El plan muestra el costo unitario; el reloj muestra el costo total
(unitario × cantidad de veces). Eso es la información que falta: la palabra "veces".
*/

-- C6: ¿Se contradicen?
/*
¿Se contradicen las dos clases?
No. El plan contesta "¿esta operación es cara?" (respuesta: sí, TABLE FULL SCAN).
El reloj contesta "¿cuánto cuesta TODO?" (respuesta: cuántas veces la ejecutás).
El plan es la evidencia del costo unitario. El reloj es la evidencia del costo total.
La clase 9 (el plan) muestra qué hacer. La clase 11 (el reloj) muestra cuándo.
*/

-- ============================================================================
-- PARTE D: El error que pediste que te ignoren
-- ============================================================================

-- D1-D2: El procedimiento sospechoso y el lote de la mañana
-- (Versión temporal, solo para ver el problema)

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
  WHEN OTHERS THEN NULL;
END;
/

-- Contar labores antes
SELECT COUNT(*) FROM labores;
-- Esperado: 19

-- Cargar cuatro
BEGIN
  cargar_labor(1,  'riego',         DATE '2026-05-02', 'Marta Ruiz',  55);
  cargar_labor(99, 'riego',         DATE '2026-05-03', 'Marta Ruiz',  60);
  cargar_labor(3,  'fertilizacion', DATE '2026-05-04', 'Jorge Mina',  70);
  cargar_labor(2,  'poda',          DATE '2026-05-05', 'Jorge Mina', -10);
  COMMIT;
END;
/

-- Contar después
SELECT COUNT(*) FROM labores;
-- Se esperaba 23 (19 + 4), pero entra solo 1 o 2

/*
D2: ¿Cuántas se perdieron?
Entraron solo 2 de las 4 (la primera y la tercera sí, la segunda y cuarta no).
Se perdieron 2.

¿Cuál fue el error de cada una?
- Primera (siembra_id=1, costo=55): OK, entra
- Segunda (siembra_id=99, costo=60): ERROR - siembra_id 99 no existe (FK inválida)
- Tercera (siembra_id=3, costo=70): OK, entra
- Cuarta (siembra_id=2, costo=-10): ERROR - costo_mano_obra es negativo (CHECK roto)

¿Cómo te enteraste?
Contando antes y después. Si no contabas, jamás te enterarías: el WHEN OTHERS
silencia los errores sin avisar. No hay mensaje, no hay ROLLBACK, no hay bitácora.
El error simplemente desaparece.
*/

-- D3: El diagnóstico
/*
Clase 8: CREATE VIEW IF NOT EXISTS corría sin error y no hacía nada.
Clase 10: Una fila mala entraba sin error.
Hoy: Un INSERT falla sin error.

¿Qué tienen en común?
Que en los tres casos: la operación falló pero nadie se enteró, porque NO hubo error
visible. No hubo un mensaje de alerta; solo el silencio.

Eso es el resumen del curso entero: los datos y los procesos pueden estar mal
sin que la base de datos te lo diga. Tienes que preguntar. Tienes que contar.
Tienes que auditar. Porque el default es el silencio.
*/

-- D4: El arreglo (versión completa con bitácora y RAISE)
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
  SELECT MAX(labor_id) + 1 INTO v_id FROM labores;
  INSERT INTO labores (labor_id, siembra_id, tipo_labor, fecha, responsable, costo_mano_obra)
  VALUES (v_id, p_siembra_id, p_tipo, p_fecha, p_responsable, p_costo);
EXCEPTION
  WHEN e_fk_invalida THEN
    INSERT INTO bitacora (tabla, operacion, clave, detalle, usuario, cuando)
    VALUES ('LABORES', 'ERROR', 'labor_id=' || v_id, 'FK inválida: siembra_id=' || p_siembra_id || ' no existe', USER, SYSTIMESTAMP);
    COMMIT;
    RAISE_APPLICATION_ERROR(-20001, 'Error: la siembra ' || p_siembra_id || ' no existe');
  WHEN e_check_roto THEN
    INSERT INTO bitacora (tabla, operacion, clave, detalle, usuario, cuando)
    VALUES ('LABORES', 'ERROR', 'labor_id=' || v_id, 'CHECK violado: costo_mano_obra=' || p_costo || ' debe ser > 0', USER, SYSTIMESTAMP);
    COMMIT;
    RAISE_APPLICATION_ERROR(-20001, 'Error: el costo ' || p_costo || ' no es válido');
  WHEN OTHERS THEN
    INSERT INTO bitacora (tabla, operacion, clave, detalle, usuario, cuando)
    VALUES ('LABORES', 'ERROR', 'labor_id=' || v_id, 'Otro error: ' || SQLERRM, USER, SYSTIMESTAMP);
    COMMIT;
    RAISE_APPLICATION_ERROR(-20001, 'Error no manejado: ' || SQLERRM);
END;
/

/*
Nota sobre el orden y ROLLBACK:
Si el INSERT a bitácora está en el mismo EXCEPTION que después hace RAISE_APPLICATION_ERROR,
y el que te llamó hace ROLLBACK, la fila de bitácora se pierda (se revierte también).

Eso es un problema real: la auditoría se borra cuando se revierten los cambios.
La solución de verdad es PRAGMA AUTONOMOUS_TRANSACTION, que abre una transacción
separada para la bitácora. Para hoy, la solución de medio pelo es hacer COMMIT
inmediatamente después de insertar en bitácora (lo que hacemos arriba).

Así: aunque el ROLLBACK externo revierte los cambios de labores, la bitácora
ya está committida en su propia transacción.
*/

-- Volver a correr el lote de D2
SELECT COUNT(*) FROM labores;
-- Esperado: 21 (19 + 2 que sí entraron antes)

BEGIN
  cargar_labor(1,  'riego',         DATE '2026-05-02', 'Marta Ruiz',  55);
  cargar_labor(99, 'riego',         DATE '2026-05-03', 'Marta Ruiz',  60);
  cargar_labor(3,  'fertilizacion', DATE '2026-05-04', 'Jorge Mina',  70);
  cargar_labor(2,  'poda',          DATE '2026-05-05', 'Jorge Mina', -10);
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Se cortó en: ' || SQLERRM);
END;
/

-- Ver bitácora
SELECT operacion, clave, detalle, usuario, cuando FROM bitacora
  WHERE operacion = 'ERROR' AND tabla = 'LABORES'
  ORDER BY bitacora_id DESC
  FETCH FIRST 2 ROWS ONLY;

/*
D4: El lote se corta a la mitad y las dos últimas no se cargan.

¿Es eso peor que antes?
No. Antes:
- Perdías filas SIN enterarte (silencio)
- No sabías qué había fallado
- No había bitácora

Ahora:
- Te enteras inmediatamente (error levantado)
- Sabes exactamente qué falló y por qué
- La bitácora tiene el registro
- Puedes decidir qué hacer (reintentar, abortar, avisar)

Pisar el freno es mejor que seguir conduciendo sin frenos.
*/

-- D5: La regla de WHEN OTHERS
/*
WHEN OTHERS está bien puesto siempre que:
- tengas un manejo explícito de las excepciones que SÍ sabes que pueden pasar
  (NO_DATA_FOUND, TOO_MANY_ROWS, las que defines con PRAGMA EXCEPTION_INIT)
- y WHEN OTHERS quede SOLO al final, como una red de seguridad para lo inesperado
- y eso inesperado se loguee (bitácora, DBMS_OUTPUT) y se relancem (RAISE_APPLICATION_ERROR)

Nunca: WHEN OTHERS THEN NULL, en silencio, tragando errores.
Nunca: WHEN OTHERS THEN sin DBMS_OUTPUT ni bitácora ni RAISE.
*/

-- ============================================================================
-- PARTE E: El QUIÉN que SQLite no podía dar
-- ============================================================================

-- E1: Probar que Oracle sabe quién está conectado
SELECT USER AS quien, SYSTIMESTAMP AS cuando FROM dual;

-- E2: El trigger con auditoría completa
CREATE OR REPLACE TRIGGER trg_cosechas_bitacora
AFTER INSERT OR UPDATE OR DELETE ON cosechas
FOR EACH ROW
BEGIN
  IF INSERTING THEN
    INSERT INTO bitacora (tabla, operacion, clave, detalle, usuario, cuando)
    VALUES ('COSECHAS', 'INSERT', 'cosecha_id=' || :NEW.cosecha_id,
            'kg=' || :NEW.kg || ' siembra_id=' || :NEW.siembra_id, USER, SYSTIMESTAMP);
  ELSIF UPDATING THEN
    INSERT INTO bitacora (tabla, operacion, clave, detalle, usuario, cuando)
    VALUES ('COSECHAS', 'UPDATE', 'cosecha_id=' || :OLD.cosecha_id,
            'kg: ' || :OLD.kg || ' -> ' || :NEW.kg, USER, SYSTIMESTAMP);
  ELSIF DELETING THEN
    INSERT INTO bitacora (tabla, operacion, clave, detalle, usuario, cuando)
    VALUES ('COSECHAS', 'DELETE', 'cosecha_id=' || :OLD.cosecha_id,
            'kg=' || :OLD.kg || ' siembra_id=' || :OLD.siembra_id, USER, SYSTIMESTAMP);
  END IF;
END;
/

-- E3: Probar el trigger
INSERT INTO cosechas VALUES (10, 6, DATE '2026-05-10', 750, 'segunda', 'mercado local');
UPDATE cosechas SET kg = 800 WHERE cosecha_id = 10;
DELETE FROM cosechas WHERE cosecha_id = 10;
COMMIT;

-- Ver la bitácora
SELECT operacion, clave, detalle, usuario, cuando FROM bitacora
  WHERE tabla = 'COSECHAS' AND clave = 'cosecha_id=10'
  ORDER BY bitacora_id;
-- Esperado: 3 filas, una por operación, las tres con tu usuario

-- E4: Reflexión final
/*
¿Significa que ya se puede auditar de verdad?
Parcialmente. Ahora la bitácora sabe QUIÉN (el usuario de BD). Pero:

¿Qué pasa si dos personas comparten el mismo usuario de base?
No se puede distinguir cuál de las dos fue. La bitácora dice "usuario SCOTT" pero
no sabe si fue Alice o Bob. Necesitarías un usuario de BD por persona.

¿Y qué pasa si alguien hace DROP TRIGGER trg_cosechas_bitacora?
La auditoría desaparece. El trigger se borra y el siguiente INSERT no se loguea.
La bitácora es una facilidad, no una garantía. Se puede desactivar.

La respuesta de la clase 10 sigue valiendo: una bitácora es una facilidad del database,
no una garantía de seguridad. Lo que cambió hoy es cuánta facilidad: antes no sabía quién;
ahora sí. Pero sigue siendo vulnerable a quien tenga permisos para borrar triggers.
*/

-- ============================================================================
-- PARTE F: Cierre
-- ============================================================================

/*
1. ¿Qué porcentaje de SQLite corrió sin cambios en Oracle?

Aproximadamente 50%.

Ejemplos que SÍ corrieron sin cambios:
- SELECT COUNT(*) FROM lecturas GROUP BY sensor_id
- JOIN, WHERE, ORDER BY, la mayoría de la lógica SQL
- Conceptos de índices, planes, GROUP BY

Ejemplos que NO corrieron:
- LIMIT → FETCH FIRST
- DATE() → TRUNC()
- DROP IF EXISTS → PL/SQL con EXCEPTION
- SELECT sin INTO adentro de PL/SQL

La regla: SQL estándar (ANSI SQL) corre en ambos. Extensiones de cada base de datos
no corre. Y PL/SQL es una extensión de Oracle que SQLite no tiene.
*/

/*
2. ¿Cuándo vale la pena escribir PL/SQL en vez de una sentencia SQL sola?

Cuando necesitas más de una operación SQL coordinada: lógica condicional, bucles,
manejo de errores que se relacionen, o transacciones complejas. Una sentencia SQL
sola (por rápida que sea) no puede hacer eso.
*/

/*
3. ¿Por qué la gente escribe WHEN OTHERS THEN NULL?

Porque un error detiene el programa. La gente tiene deadline, no quiere que el programa
explote, y sabe que "no falla a menudo". WHEN OTHERS THEN NULL es decir: "ignora los
problemas, sigue adelante". Es la defensa del que corre a contrarreloj. Y funciona
a corto plazo: el programa no explota. A largo plazo, acumula datos silenciosamente
malos que nadie se entera hasta que alguien cuenta.
*/

-- ============================================================================
-- FIN DEL EJERCICIO
-- ============================================================================
