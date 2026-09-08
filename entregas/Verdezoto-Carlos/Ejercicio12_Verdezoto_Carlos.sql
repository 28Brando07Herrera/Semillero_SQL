-- =====================================================================
-- CURSO DE SQL / PLSQL | AgroDB | Ejercicio Práctico 12
-- Alumno: [Tu Nombre y Apellido]
-- Fecha: 26/08/2026
--
-- Entorno: Oracle FreeSQL / Oracle Database
-- =====================================================================

-- =====================================================================
-- PARTE A · El archivo, antes de tocarlo
-- =====================================================================

-- A1 — Predicción previa
/*
Líneas que creo que van a fallar y razón:
- Línea 3:  '21,50' tiene coma decimal en lugar de punto (falla al convertir a NUMBER).
- Línea 4:  'n/d' no es una cadena numérica válida (falla al convertir a NUMBER).
- Línea 5:  '-999' viola la restricción CHECK ck_lecturas_valor (está fuera de -50 y 1500).
- Línea 6:  Cadena vacía/NULL en valor (viola NOT NULL en lecturas.valor).
- Línea 11: Espacios '  4 ' y ' 512.00 ' (podría fallar si el parser no hace TRIM implícito, aunque el TRIM explícito lo arregla).
- Línea 14: Sensor '99' no existe en la tabla sensores (viola FK).
- Línea 18: Duplicado exacto de la línea 17 para el sensor 6 en la misma fecha_hora (viola restricción UNIQUE/PK).
- Línea 19: '2026-05-01 25:00' hora inválida 25:00 (falla al convertir a DATE).
*/

-- A2 — Por qué el staging no valida nada
/*
Si staging_lecturas.sensor_id fuera NUMBER con FK a sensores, el INSERT en la tabla staging
fallaría inmediatamente al procesar la línea 14 (sensor 99). La transacción completa abortaría
(o se saltaría la fila), por lo que la línea NUNCA quedaría registrada en la base de datos.
Sin un registro persistente del dato crudo entrante, no habría forma de auditar el error ni de
enterarnos de que el origen transmitió un sensor inexistente.
*/

-- A3 — Separar "no se entiende" de "no se acepta"
SELECT linea,
       CASE
         WHEN TO_NUMBER(TRIM(sensor_id) DEFAULT NULL ON CONVERSION ERROR) IS NULL
           THEN 'sensor ilegible'
         WHEN TO_DATE(TRIM(fecha_hora) DEFAULT NULL ON CONVERSION ERROR,
                      'YYYY-MM-DD HH24:MI') IS NULL
           THEN 'fecha ilegible'
         WHEN TO_NUMBER(TRIM(valor) DEFAULT NULL ON CONVERSION ERROR) IS NULL
           THEN 'valor ilegible'
         ELSE 'convierte'
       END AS diagnostico
  FROM staging_lecturas
 WHERE archivo = 'lect_20260501.csv'
 ORDER BY linea;

/*
Si escribiera TO_NUMBER(valor) a secas, la línea 4 arrojaría la excepción ORA-01722: invalid number.
Esto interrumpiría abruptamente la ejecución del script, impidiendo que las 19 líneas restantes
puedan procesarse o analizarse.
*/

-- A4 — El TRIM
/*
Al quitar el TRIM a la consulta A3, el diagnóstico de la línea 11 NO cambia (sigue marcando 'convierte').
Esto sucede porque Oracle realiza un casteo implícito de limpieza de espacios al aplicar TO_NUMBER
sobre cadenas con espacios en blanco.
*/

-- A5 — Rechazo: ¿Archivo o Modelo?
/*
Las 4 inconsistencias de conversión fueron rechazadas por la estructura del ARCHIVO (formato ilegible),
incluso antes de llegar a validar las reglas de negocio del modelo relacional.
*/


-- =====================================================================
-- PARTE B · Cargar sin perder los errores
-- =====================================================================

-- B1 — Dónde van a vivir los rechazos
BEGIN
  DBMS_ERRLOG.CREATE_ERROR_LOG(dml_table_name     => 'LECTURAS',
                               err_log_table_name => 'ERR_LECTURAS');
END;
/

/*
La tabla ERR_LECTURAS almacena los datos como VARCHAR2(4000) para poder recibir cualquier tipo
de dato malformado que haya provocado el fallo (como texto en campos numéricos o fechas inválidas).
Si tuviera los tipos originales, la propia tabla de errores fallaría al intentar insertar el dato corrupto.
*/

-- B2 — La carga masiva
INSERT INTO lecturas (lectura_id, sensor_id, fecha_hora, valor)
SELECT seq_lecturas.NEXTVAL,
       TO_NUMBER(TRIM(sensor_id) DEFAULT NULL ON CONVERSION ERROR),
       TO_DATE(TRIM(fecha_hora) DEFAULT NULL ON CONVERSION ERROR, 'YYYY-MM-DD HH24:MI'),
       TO_NUMBER(TRIM(valor)     DEFAULT NULL ON CONVERSION ERROR)
  FROM staging_lecturas
 WHERE archivo = 'lect_20260501.csv'
  LOG ERRORS INTO err_lecturas ('carga 1') REJECT LIMIT UNLIMITED;

COMMIT;

SELECT COUNT(*) AS lecturas    FROM lecturas;     -- Esperado: 8652
SELECT COUNT(*) AS rechazadas  FROM err_lecturas; -- Esperado: 8

-- B3 — Leer los rechazos
SELECT ora_err_number$ AS ora, COUNT(*) AS filas
  FROM err_lecturas
 GROUP BY ora_err_number$
 ORDER BY filas DESC, ora;

SELECT ora_err_number$, ora_err_mesg$, sensor_id, fecha_hora, valor
  FROM err_lecturas
 ORDER BY ora_err_number$;

/*
Tabla de códigos ORA:
--------------------------------------------------------------------------------------------------
| Código ORA | Significado                               | Líneas del archivo causantes          |
--------------------------------------------------------------------------------------------------
| ORA-01400  | Inserción de valor NULL en columna NOT NULL| Líneas 3, 4, 6 y 19 (Conversión NULL) |
| ORA-00001  | Violación de restricción única (UNIQUE)   | Línea 18 (Duplicado de la línea 17)   |
| ORA-02290  | Violación de restricción CHECK            | Línea 5 (Valor -999 fuera de rango)   |
| ORA-02291  | Violación de Clave Foránea (FK)           | Línea 14 (Sensor 99 no existe)        |
--------------------------------------------------------------------------------------------------
Nota NLS: Si NLS_NUMERIC_CHARACTERS usa coma, la línea 3 ('21,50') convierte correctamente a número
en lugar de dar NULL, pero luego falla con ORA-02290 o procesa distinto al interpretar la coma.
*/

-- B4 — Reconciliar
SELECT s.linea, s.sensor_id, s.fecha_hora, s.valor
  FROM staging_lecturas s
 WHERE s.archivo = 'lect_20260501.csv'
   AND NOT EXISTS (
         SELECT 1
           FROM lecturas l
          WHERE l.sensor_id  = TO_NUMBER(TRIM(s.sensor_id) DEFAULT NULL ON CONVERSION ERROR)
            AND l.fecha_hora = TO_DATE(TRIM(s.fecha_hora) DEFAULT NULL ON CONVERSION ERROR,
                                       'YYYY-MM-DD HH24:MI'))
 ORDER BY s.linea;

/*
Las 2 filas faltantes son las líneas 3 y 19. NOT EXISTS no las ve como "pendientes" porque
sus expresiones convertidas devuelven NULL (por TO_NUMBER/TO_DATE con DEFAULT NULL ON ERROR),
y en SQL la comparación 'columna = NULL' evalúa a UNKNOWN.
Si esta fuera la única forma de control, se habría reportado erróneamente que solo 6 filas fallaron,
ignorando las que fallaron por conversión a NULL.
*/

-- B5 — La trampa del día
/*
LOG ERRORS convierte fallos en no-errores a nivel de ejecución bajo la condición de que:
"Siempre que exista un mecanismo explícito de auditoría y revisión automática que procese
y alerte sobre los registros caídos en ERR_LECTURAS inmediatamente después del proceso".
*/

-- B6 — Comparación de predicción
/*
Aciertos: Se predijeron correctamente las fallas de formato, rango, FK y duplicados.
Comparación realizada con éxito frente a los diagnósticos del motor.
*/


-- =====================================================================
-- PARTE C · La segunda corrida
-- =====================================================================

-- C1 — Re-ejecución del bot
INSERT INTO lecturas (lectura_id, sensor_id, fecha_hora, valor)
SELECT seq_lecturas.NEXTVAL,
       TO_NUMBER(TRIM(sensor_id) DEFAULT NULL ON CONVERSION ERROR),
       TO_DATE(TRIM(fecha_hora) DEFAULT NULL ON CONVERSION ERROR, 'YYYY-MM-DD HH24:MI'),
       TO_NUMBER(TRIM(valor)     DEFAULT NULL ON CONVERSION ERROR)
  FROM staging_lecturas
 WHERE archivo = 'lect_20260501.csv'
  LOG ERRORS INTO err_lecturas ('carga 2') REJECT LIMIT UNLIMITED;

COMMIT;

SELECT COUNT(*) AS lecturas   FROM lecturas;
SELECT COUNT(*) AS rechazadas FROM err_lecturas;

SELECT ora_err_tag$, ora_err_number$, COUNT(*)
  FROM err_lecturas
 GROUP BY ora_err_tag$, ora_err_number$
 ORDER BY 1, 3 DESC;

/*
Respuestas C1:
1. Lo impidió el modelo mediante las restricciones de clave primaria y restricciones UNIQUE.
2. De las 20 nuevas, 12 son "esto ya estaba" (duplicados por re-ejecución) y 8 son errores reales.
   La tabla ya no refleja solo errores de origen, sino contaminación por reintento.
3. Los 12 nuevos ORA-00001 corresponden a las 12 filas válidas de la primera corrida que ahora chocan contra la base.
4. El MAX(lectura_id) es mayor porque la secuencia generó números secuenciales para TODAS las filas leídas en el SELECT,
   incluidas las que posteriormente fueron rechazadas y no se insertaron. Las secuencias no revierten valores con ROLLBACK.
*/

-- C2 — Análisis previo de corrección
/*
Análisis para archivo lect_20260501_rev2.csv con INSERT que solo inserta lo que falta:
- Línea 1 (Sensor 1, 01:00): Se insertaría correctamente (era ilegible en carga 1).
- Línea 2 (Sensor 1, 01:30): Se insertaría correctamente (era ilegible en carga 1).
- Línea 3 (Sensor 2, 00:00, valor 68.20): Sería ignorada por existir ya una fila para ese sensor/fecha, perdiendo la recalibración.
*/

-- C3 — MERGE
MERGE INTO lecturas l
USING (
  SELECT TO_NUMBER(TRIM(sensor_id) DEFAULT NULL ON CONVERSION ERROR)  AS sensor_id,
         TO_DATE(TRIM(fecha_hora) DEFAULT NULL ON CONVERSION ERROR,
                 'YYYY-MM-DD HH24:MI')                                AS fecha_hora,
         TO_NUMBER(TRIM(valor)     DEFAULT NULL ON CONVERSION ERROR)  AS valor
    FROM staging_lecturas
   WHERE archivo = 'lect_20260501_rev2.csv'
) s
ON (l.sensor_id = s.sensor_id AND l.fecha_hora = s.fecha_hora)
WHEN MATCHED THEN
  UPDATE SET l.valor = s.valor
WHEN NOT MATCHED THEN
  INSERT (l.lectura_id, l.sensor_id, l.fecha_hora, l.valor)
  VALUES (seq_lecturas.NEXTVAL, s.sensor_id, s.fecha_hora, s.valor);

COMMIT;

SELECT COUNT(*) FROM lecturas;                         -- Esperado: 8654
SELECT valor FROM lecturas
 WHERE sensor_id = 2 AND fecha_hora = DATE '2026-05-01';-- Esperado: 68.2

-- C4 — Prueba de Idempotencia
-- Re-ejecución del MERGE
MERGE INTO lecturas l
USING (
  SELECT TO_NUMBER(TRIM(sensor_id) DEFAULT NULL ON CONVERSION ERROR)  AS sensor_id,
         TO_DATE(TRIM(fecha_hora) DEFAULT NULL ON CONVERSION ERROR,
                 'YYYY-MM-DD HH24:MI')                                AS fecha_hora,
         TO_NUMBER(TRIM(valor)     DEFAULT NULL ON CONVERSION ERROR)  AS valor
    FROM staging_lecturas
   WHERE archivo = 'lect_20260501_rev2.csv'
) s
ON (l.sensor_id = s.sensor_id AND l.fecha_hora = s.fecha_hora)
WHEN MATCHED THEN
  UPDATE SET l.valor = s.valor
WHEN NOT MATCHED THEN
  INSERT (l.lectura_id, l.sensor_id, l.fecha_hora, l.valor)
  VALUES (seq_lecturas.NEXTVAL, s.sensor_id, s.fecha_hora, s.valor);

COMMIT;

SELECT COUNT(*) AS filas, SUM(valor) AS suma
  FROM lecturas
 WHERE fecha_hora >= DATE '2026-05-01';

/*
Respuestas C4:
1. La segunda vez ejecutó UPDATEs con los mismos valores que ya existían (operación redundante), sin alterar el estado.
2. El COUNT(*) solo valida cantidad de filas, no la integridad de los datos. La SUMA verifica que los valores numéricos
   no se hayan alterado, duplicado o sobrescrito con datos erróneos.
3. Idempotente significa que ejecutar un proceso una o múltiples veces produce exactamente el mismo resultado en la base de datos.
   Es vital para un bot autónomo para garantizar consistencia ante reintentos por fallas de red o caídas.
*/

-- C5 — Lo que el INSERT no habría hecho
/*
Con un 'INSERT ... WHERE NOT EXISTS', la actualización de la línea 3 habría sido omitida silenciosamente.
No habría dado error, pero habría dejado un dato desactualizado/incorrecto en la base (violación de consistencia silenciosa).
*/


-- =====================================================================
-- PARTE D · Cuándo sí hace falta el bucle
-- =====================================================================

-- Reset de datos para pruebas
DELETE FROM lecturas WHERE fecha_hora >= DATE '2026-05-01';
DELETE FROM err_lecturas;
COMMIT;

-- D1 — Bucle con manejo de excepciones
DECLARE
  v_ok  NUMBER := 0;
  v_mal NUMBER := 0;
BEGIN
  FOR r IN (SELECT * FROM staging_lecturas
             WHERE archivo = 'lect_20260501.csv' ORDER BY linea) LOOP
    BEGIN
      INSERT INTO lecturas (lectura_id, sensor_id, fecha_hora, valor)
      VALUES (seq_lecturas.NEXTVAL,
              TO_NUMBER(TRIM(r.sensor_id) DEFAULT NULL ON CONVERSION ERROR),
              TO_DATE(TRIM(r.fecha_hora) DEFAULT NULL ON CONVERSION ERROR,
                      'YYYY-MM-DD HH24:MI'),
              TO_NUMBER(TRIM(r.valor)     DEFAULT NULL ON CONVERSION ERROR));
      v_ok := v_ok + 1;
    EXCEPTION
      WHEN OTHERS THEN
        v_mal := v_mal + 1;
        DBMS_OUTPUT.PUT_LINE('linea ' || r.linea || ': ' || SQLERRM);
    END;
  END LOOP;
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('ok=' || v_ok || ' mal=' || v_mal);
END;
/

/*
Este WHEN OTHERS no es incorrecto porque REGISTRA de inmediato la línea y el error específico mediante DBMS_OUTPUT,
impidiendo que el fallo se oculte sin traza.
*/

-- Reset para D2
DELETE FROM lecturas WHERE fecha_hora >= DATE '2026-05-01';
DELETE FROM err_lecturas;
COMMIT;

-- D2 — BULK COLLECT + FORALL SAVE EXCEPTIONS
DECLARE
  TYPE t_num IS TABLE OF NUMBER;
  TYPE t_fec IS TABLE OF DATE;
  v_sensor t_num;
  v_fecha  t_fec;
  v_valor  t_num;
  e_bulk EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_bulk, -24381);
BEGIN
  SELECT TO_NUMBER(TRIM(sensor_id) DEFAULT NULL ON CONVERSION ERROR),
         TO_DATE(TRIM(fecha_hora) DEFAULT NULL ON CONVERSION ERROR, 'YYYY-MM-DD HH24:MI'),
         TO_NUMBER(TRIM(valor)     DEFAULT NULL ON CONVERSION ERROR)
    BULK COLLECT INTO v_sensor, v_fecha, v_valor
    FROM staging_lecturas
   WHERE archivo = 'lect_20260501.csv'
   ORDER BY linea;

  FORALL i IN 1 .. v_sensor.COUNT SAVE EXCEPTIONS
    INSERT INTO lecturas (lectura_id, sensor_id, fecha_hora, valor)
    VALUES (seq_lecturas.NEXTVAL, v_sensor(i), v_fecha(i), v_valor(i));

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('entraron las ' || v_sensor.COUNT);
EXCEPTION
  WHEN e_bulk THEN
    DBMS_OUTPUT.PUT_LINE('fallaron ' || SQL%BULK_EXCEPTIONS.COUNT ||
                         ' de ' || v_sensor.COUNT);
    FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
      DBMS_OUTPUT.PUT_LINE('  linea ' || SQL%BULK_EXCEPTIONS(i).ERROR_INDEX || ': ' ||
                           SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE));
    END LOOP;
    COMMIT;
END;
/

/*
SAVE EXCEPTIONS permite procesar todo el lote omitiendo la fila con falla. Sin él, el bloque abortaría
en el primer error procesando 0 filas.
*/

-- D3 — Cuadro Comparativo
/*
--------------------------------------------------------------------------------------------------------
| Forma                                 | Sentencias SQL | Context Switches | Dónde quedan los errores |
--------------------------------------------------------------------------------------------------------
| B2 · INSERT ... SELECT LOG ERRORS     | 1              | 1                | Tabla ERR_LECTURAS       |
| D1 · Bucle FOR con INSERT             | 20             | 20               | Consola / DBMS_OUTPUT    |
| D2 · BULK COLLECT + FORALL            | 2              | 2                | Colección SQL%BULK_EXCEPTIONS|
--------------------------------------------------------------------------------------------------------

A producción se envía B2 (o D2 según la arquitectura), priorizando la persistencia estructurada y auditable de los errores.
*/

-- D4 — Elección de arquitectura
/*
El bucle D1 es preferible únicamente cuando cada iteración requiere lógica condicional compleja no realizable en SQL puro,
o cuando se necesita invocar servicios / APIs externas por cada fila procesada.
*/


-- =====================================================================
-- PARTE E · Nunca se concatena SQL a mano
-- =====================================================================

-- E1 — Concatenación (Vulnerable)
CREATE OR REPLACE FUNCTION lecturas_abril_concat (p_sensor VARCHAR2) RETURN NUMBER AS
  v_n NUMBER;
BEGIN
  EXECUTE IMMEDIATE
    'SELECT COUNT(*) FROM lecturas WHERE fecha_hora < DATE ''2026-05-01''
       AND sensor_id = ' || p_sensor
    INTO v_n;
  RETURN v_n;
END;
/

SELECT lecturas_abril_concat('1')        AS normal FROM dual;   -- Resultado: 1440
SELECT lecturas_abril_concat('1 OR 1=1') AS ups    FROM dual;   -- Resultado: 8640

-- E2 — Variable de Enlace (Segura)
CREATE OR REPLACE FUNCTION lecturas_abril_bind (p_sensor VARCHAR2) RETURN NUMBER AS
  v_n NUMBER;
BEGIN
  EXECUTE IMMEDIATE
    'SELECT COUNT(*) FROM lecturas WHERE fecha_hora < DATE ''2026-05-01''
       AND sensor_id = :s'
    INTO v_n USING p_sensor;
  RETURN v_n;
END;
/

SELECT lecturas_abril_bind('1')        FROM dual;   -- Resultado: 1440
-- SELECT lecturas_abril_bind('1 OR 1=1') FROM dual; -- Error ORA-01722: invalid number

/*
Respuestas E3:
1. No se la puede engañar porque el motor trata el parámetro como un literal de datos estricto, no como código ejecutable.
2. En E1 se convirtió en INSTRUCCIÓN (código SQL). En E2 se convirtió en VALOR (literal).
3. Con BIND variables el motor parsea la sentencia 1 sola vez (Hard Parse) y la reusa. Con concatenación parsea 1000 veces distintas.
*/

-- E4 — Cierre sintético
/*
"El dato que viene de afuera nunca debe ser tratado como código ejecutable ni confiado ciegamente, debe tratarse siempre como un valor a validar o parametrizar."
*/


-- =====================================================================
-- PARTE F · Cierre
-- =====================================================================

/*
1. El proceso llamador debe consultar la tabla ERR_LECTURAS y notificar/alertar las filas anómalas. Si no lo hace, los sensores
   quedarán sin lecturas registradas en la finca, distorsionando promedios y reportes agronómicos.
2. Un proceso de carga está terminado cuando es completamente idempotente, maneja y audita los errores sin detener la operación
   y puede re-ejecutarse de forma segura.
3. Fila Clase 12: "Carga de archivos en Staging sin auditoría -> Pérdida silenciosa de mediciones -> Detección por auditoría de errores con LOG ERRORS / MERGE".
*/