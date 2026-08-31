-- EJERCICIO PRÁCTICO 12: Un proceso de carga se juzga por la segunda corrida
-- Estudiante: Cortez Axel
-- Motor: Oracle Database 23ai | Entorno: Oracle FreeSQL / SQL Developer

SET SERVEROUTPUT ON;


-- PARTE A · EL ARCHIVO, ANTES DE TOCARLO

-- A1. Inspección inicial del archivo de staging
SELECT linea, sensor_id, fecha_hora, valor
  FROM staging_lecturas
 WHERE archivo = 'lect_20260501.csv'
 ORDER BY linea;

/*
COMENTARIO A1 (Mi predicción inicial antes de procesar):
- Línea 3:  '21,50' usa coma en lugar de punto decimal (error de conversión numérica a NUMBER).
- Línea 4:  'n/d' es texto no numérico en columna de valor (error de conversión numérica).
- Línea 5:  '-999' viola la restricción CHECK de lecturas (valor BETWEEN -50 AND 1500).
- Línea 6:  '' es cadena vacía que en Oracle equivale a NULL, violando NOT NULL en valor.
- Línea 11: Trae espacios ('  4 ', ' 512.00 ') que requerirán TRIM para limpiar.
- Línea 14: sensor_id = '99' no existe en la tabla sensores (viola FK hacia sensores).
- Línea 18: Duplicado exacto de la línea 17 (sensor 6 en 2026-05-01 01:00, viola UNIQUE uq_lecturas).
- Línea 19: '2026-05-01 25:00' tiene hora inválida 25 (error de conversión de fecha TO_DATE).
- Línea 20: '2026-04-30 23:30' para sensor 1 ya existía en la carga inicial de abril (viola UNIQUE).
*/

/*
COMENTARIO A2:
Si 'staging_lecturas' tuviera FK contra sensores y sensor_id fuera NUMBER, la línea 14 con sensor 99 sería rechazada directamente por el INSERT inicial del bot.
No quedaría registrada en ninguna tabla de la base de datos y se perdería por completo, impidiendo que el equipo de soporte se entere de que un sensor no mapeado intentó enviar mediciones.
*/

-- A3. Diagnóstico de conversión sin insertar datos
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
COMENTARIO A3:
Si escribiera `TO_NUMBER(valor)` a secas, al llegar a la línea 4 ('n/d') el motor abortaría de inmediato con `ORA-01722: invalid number`.
Toda la sentencia se cancelaría y ninguna de las 19 líneas restantes (incluso las 16 válidas) se procesaría.
*/

-- A4. Prueba quitando TRIM
SELECT linea,
       CASE
         WHEN TO_NUMBER(sensor_id DEFAULT NULL ON CONVERSION ERROR) IS NULL
           THEN 'sensor ilegible'
         WHEN TO_DATE(fecha_hora DEFAULT NULL ON CONVERSION ERROR,
                      'YYYY-MM-DD HH24:MI') IS NULL
           THEN 'fecha ilegible'
         WHEN TO_NUMBER(valor DEFAULT NULL ON CONVERSION ERROR) IS NULL
           THEN 'valor ilegible'
         ELSE 'convierte'
       END AS diagnostico
  FROM staging_lecturas
 WHERE archivo = 'lect_20260501.csv'
 ORDER BY linea;

/*
COMENTARIO A4:
El diagnóstico de la línea 11 no cambió (siguió dando 'convierte') porque TO_NUMBER y TO_DATE en Oracle ignoran espacios en blanco al inicio y al final de manera nativa; sin embargo, usar TRIM explícito sigue siendo una buena práctica defensiva.
*/

/*
COMENTARIO A5:
Esas 4 líneas las rechazó la sintaxis del archivo (formato de datos ilegible), porque ni siquiera pudieron convertirse a los tipos de datos requeridos por SQL.
*/


-- PARTE B · CARGAR SIN PERDER LOS ERRORES

-- B1. Creación de tabla de log de errores DML
BEGIN
  DBMS_ERRLOG.CREATE_ERROR_LOG(dml_table_name     => 'LECTURAS',
                               err_log_table_name => 'ERR_LECTURAS');
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

SELECT column_name, data_type
  FROM user_tab_columns
 WHERE table_name = 'ERR_LECTURAS'
 ORDER BY column_id;

/*
COMENTARIO B1:
Guarda todo como VARCHAR2(4000) para poder capturar exactamente el texto sucio que causó la falla (como 'n/d' o '21,50') sin que la propia tabla de rechazos explote por incompatibilidad de tipos de datos.
*/

-- B2. Carga resiliente con LOG ERRORS
INSERT INTO lecturas (lectura_id, sensor_id, fecha_hora, valor)
SELECT seq_lecturas.NEXTVAL,
       TO_NUMBER(TRIM(sensor_id) DEFAULT NULL ON CONVERSION ERROR),
       TO_DATE(TRIM(fecha_hora) DEFAULT NULL ON CONVERSION ERROR, 'YYYY-MM-DD HH24:MI'),
       TO_NUMBER(TRIM(valor)     DEFAULT NULL ON CONVERSION ERROR)
  FROM staging_lecturas
 WHERE archivo = 'lect_20260501.csv'
  LOG ERRORS INTO err_lecturas ('carga 1') REJECT LIMIT UNLIMITED;

COMMIT;

-- Verificación B2 (Esperado: 8652 y 8):
SELECT COUNT(*) AS lecturas   FROM lecturas;
SELECT COUNT(*) AS rechazadas FROM err_lecturas;


-- B3. Inspección y desglose de códigos ORA en rechazos
SELECT ora_err_number$ AS ora, COUNT(*) AS filas
  FROM err_lecturas
 GROUP BY ora_err_number$
 ORDER BY filas DESC, ora;

SELECT ora_err_number$, ora_err_mesg$, sensor_id, fecha_hora, valor
  FROM err_lecturas
 ORDER BY ora_err_number$;

/*
COMENTARIO B3 (Tabla de correspondencia de errores ORA):
-------------------------------------------------------------------------------------------------------
Código ORA   | Significado                                 | Líneas causantes
-------------------------------------------------------------------------------------------------------
ORA-01400    | Inserción de NULL en columna NOT NULL       | Líneas 3 ('21,50'), 4 ('n/d'), 6 (''), 19 (hora 25)
ORA-00001    | Clave única duplicada (uq_lecturas)         | Líneas 18 (duplicada de 17), 20 (existente en abril)
ORA-02290    | Violación de CHECK constraint (-50 a 1500)  | Línea 5 (valor '-999')
ORA-02291    | Violación de FK (sensor no existe)          | Línea 14 (sensor_id '99')
-------------------------------------------------------------------------------------------------------
*/

-- B4. Reconciliación entre staging y lecturas
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
COMENTARIO B4:
Faltan las líneas 18 y 20 (devuelve 6 filas en lugar de 8).
Esta consulta no las ve como faltantes porque al buscar con NOT EXISTS encuentra que en 'lecturas' YA EXISTE una medición con ese mismo sensor y fecha (la 17 y la histórica de abril), asumiendo erróneamente que las líneas 18 y 20 entraron.
Si controlara la carga solo con este NOT EXISTS, habría reportado falsamente que entraron 14 líneas en vez de las 12 reales.
*/

/*
COMENTARIO B5:
`LOG ERRORS` está bien siempre que el proceso consulte inmediatamente la tabla `err_lecturas` al finalizar, alerte sobre los registros rechazados y no emita un estado de éxito completo si el conteo de errores es mayor a cero.
*/

/*
COMENTARIO B6:
Comparación con mi predicción de A1:
Acerté las 8 líneas problemáticas (3, 4, 5, 6, 14, 18, 19, 20).
El detalle interesante fue que las líneas 3, 4 y 19 se manifestaron como ORA-01400 (NULL en columna NOT NULL) debido a que `DEFAULT NULL ON CONVERSION ERROR` convirtió el texto inválido en NULL antes de tocar la restricción de la tabla.
*/


-- PARTE C · LA SEGUNDA CORRIDA

-- C1. Simulación de reejecución idéntica sobre el mismo archivo
INSERT INTO lecturas (lectura_id, sensor_id, fecha_hora, valor)
SELECT seq_lecturas.NEXTVAL,
       TO_NUMBER(TRIM(sensor_id) DEFAULT NULL ON CONVERSION ERROR),
       TO_DATE(TRIM(fecha_hora) DEFAULT NULL ON CONVERSION ERROR, 'YYYY-MM-DD HH24:MI'),
       TO_NUMBER(TRIM(valor)     DEFAULT NULL ON CONVERSION ERROR)
  FROM staging_lecturas
 WHERE archivo = 'lect_20260501.csv'
  LOG ERRORS INTO err_lecturas ('carga 2') REJECT LIMIT UNLIMITED;

COMMIT;

-- Verificación C1 (Esperado: lecturas = 8652, rechazadas = 28):
SELECT COUNT(*) AS lecturas   FROM lecturas;
SELECT COUNT(*) AS rechazadas FROM err_lecturas;

SELECT ora_err_tag$, ora_err_number$, COUNT(*)
  FROM err_lecturas
 GROUP BY ora_err_tag$, ora_err_number$
 ORDER BY 1, 3 DESC;

/*
COMENTARIO C1:
1. La duplicación la impidió el modelo gracias a la restricción UNIQUE `uq_lecturas (sensor_id, fecha_hora)`.
2. De las 20 filas nuevas en err_lecturas, 8 son los mismos errores de datos de siempre y 12 corresponden a "esto ya estaba cargado". La tabla no se puede usar para reportar sin filtrar por la etiqueta de corrida (`ora_err_tag$`).
3. Los 12 duplicados nuevos salieron de las 12 filas válidas que entraron en la carga 1 y que ahora colisionaron contra la clave única al volver a correr el mismo archivo.
4. El máximo `lectura_id` subió más de 12 porque la secuencia `seq_lecturas` evaluó NEXTVAL para cada fila leída en el SELECT antes de que el motor descartara los rechazos, consumiendo números sin posibilidad de rollback.
*/

/*
COMENTARIO C2:
Un INSERT tradicional con WHERE NOT EXISTS insertaría las 2 líneas nuevas corregidas (líneas 1 y 2), pero ignoraría la línea 3 porque el sensor 2 en 2026-05-01 00:00 ya existe en la base, perdiendo la recalibración del dato.
*/

-- C3. Aplicación de correcciones mediante MERGE idempotente
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

-- Verificación C3 (Esperado: 8654 y 68.2):
SELECT COUNT(*) FROM lecturas;
SELECT valor FROM lecturas WHERE sensor_id = 2 AND fecha_hora = DATE '2026-05-01';


-- C4. Prueba de idempotencia con segunda ejecución del MERGE
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

-- Control de métricas (Esperado: 14 filas, suma 2121.7):
SELECT COUNT(*) AS filas, SUM(valor) AS suma
  FROM lecturas
 WHERE fecha_hora >= DATE '2026-05-01';

/*
COMENTARIO C4:
1. La segunda vez el MERGE reescribió los mismos valores sobre las filas existentes sin insertar nada nuevo ni duplicar registros.
2. El COUNT(*) solo prueba que no se agregaron filas nuevas, pero no detecta si los valores internos cambiaron o se corrompieron; la SUM(valor) agrega certeza matemática de que los datos cuantitativos se mantuvieron íntegros.
3. Idempotente significa que ejecutar la misma operación múltiples veces produce exactamente el mismo estado final que ejecutarla una sola vez; para un bot automático esto es vital porque si se reinicia a mitad de camino puede reintentar sin duplicar datos ni corromper métricas.
*/

/*
COMENTARIO C5:
Con `INSERT ... WHERE NOT EXISTS` no habría dado ningún error, pero la recalibración no se habría aplicado, dejando en la base un dato obsoleto sin avisar a nadie.
Esto encaja con la lección de todo el curso: los errores silenciosos que no lanzan excepción son los más destructivos en analítica.
*/


-- PARTE D · CUÁNDO SÍ HACE FALTA EL BUCLE

-- Limpieza y reset para pruebas de rendimiento en mayo
DELETE FROM lecturas WHERE fecha_hora >= DATE '2026-05-01';
DELETE FROM err_lecturas;
COMMIT;
SELECT COUNT(*) AS lecturas_reset FROM lecturas; -- Esperado: 8640


-- D1. Carga con bucle procedural e informe individualizado
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
COMENTARIO D1:
Este WHEN OTHERS no es el de ayer porque no está vacío (`THEN NULL`): incrementa el contador de fallas e imprime explícitamente el número de línea y el mensaje `SQLERRM` en la consola para trazabilidad.
*/


-- D2. Procesamiento por lotes en memoria con FORALL SAVE EXCEPTIONS
DELETE FROM lecturas WHERE fecha_hora >= DATE '2026-05-01';
COMMIT;

DECLARE
  TYPE t_num IS TABLE OF NUMBER;
  TYPE t_fec IS TABLE OF DATE;
  v_sensor t_num;
  v_fecha  t_fec;
  v_valor  t_num;
  e_bulk EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_bulk, -24381); -- ORA-24381: error(s) in array DML
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
    DBMS_OUTPUT.PUT_LINE('fallaron ' || SQL%BULK_EXCEPTIONS.COUNT || ' de ' || v_sensor.COUNT);
    FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
      DBMS_OUTPUT.PUT_LINE('  linea ' || SQL%BULK_EXCEPTIONS(i).ERROR_INDEX || ': ' ||
                           SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE));
    END LOOP;
    COMMIT;
END;
/

-- Verificación D2:
SELECT COUNT(*) AS total_lecturas_d2 FROM lecturas; -- Esperado: 8652

/*
COMENTARIO D2:
Sin `SAVE EXCEPTIONS`, el FORALL se detendría en la primera línea errónea (línea 3), haciendo rollback de todo o dejando solo 2 filas cargadas.
Con SAVE EXCEPTIONS, el bloque recopila todas las fallas en el arreglo `SQL%BULK_EXCEPTIONS` y continúa insertando el resto de filas válidas.
*/

/*
COMENTARIO D3 (Comparativa de arquitecturas de carga):
-------------------------------------------------------------------------------------------------------
Forma                                | Sentencias SQL | Context Switches | Dónde quedan los errores
-------------------------------------------------------------------------------------------------------
B2 · INSERT ... SELECT ... LOG ERRORS| 1              | 1                | En tabla física (ERR_LECTURAS)
D1 · bucle FOR con INSERT adentro    | 21 (1 SEL + 20)| 40               | En consola DBMS_OUTPUT
D2 · BULK COLLECT + FORALL           | 2 (1 SEL + 1 DML)| 2              | En memoria (SQL%BULK_EXCEPTIONS)
-------------------------------------------------------------------------------------------------------
Para producción envío B2 (`LOG ERRORS`), porque persiste los errores en una tabla relacional consultable por procesos posteriores de auditoría y monitoreo, sin riesgo de perder logs por desbordamiento de buffer o desconexión de sesión.
*/

/*
COMENTARIO D4:
El bucle de D1 es preferible cuando cada fila requiere una lógica de negocio procedural compleja y diferenciada (como llamar a una API web externa, enviar un correo o interactuar con colas JMS) antes de decidir si se inserta o no.
*/


-- PARTE E · NUNCA SE CONCATENA SQL A MANO

-- E1. Demostración de vulnerabilidad por concatenación dinámica
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

SELECT lecturas_abril_concat('1')        AS normal FROM dual; -- Esperado: 1440
SELECT lecturas_abril_concat('1 OR 1=1') AS ups    FROM dual; -- Esperado: 8640


-- E2. Protección nativa mediante Variables de Enlace (Bind Variables)
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

SELECT lecturas_abril_bind('1') FROM dual; -- Esperado: 1440
-- SELECT lecturas_abril_bind('1 OR 1=1') FROM dual;
/*
ERROR OBTENIDO E2:
ORA-01722: invalid number (o error de conversión de tipo)
*/

/*
COMENTARIO E3:
1. No se la puede engañar porque el motor trata a `:s` como un literal de valor puro, nunca como código ejecutable de la gramática SQL.
2. En la primera versión `'1 OR 1=1'` se convirtió en parte de la instrucción lógica (alterando el WHERE), mientras que en la segunda se evaluó como un valor que se compara contra la columna numérica 'sensor_id'.
3. Con concatenación, Oracle debe hacer un Hard Parse (compilar y calcular un plan nuevo) mil veces; con variables de enlace, hace 1 Hard Parse y 999 Soft Parses reutilizando el plan en la Shared Pool.
*/

/*
COMENTARIO E4:
"El dato que viene de afuera no es código: es una propuesta de valor que debe ser tipada, saneada y enlazada de forma segura."
*/


-- PARTE F · CIERRE

/*
1. Acción del proceso invocador ante rechazos:
El proceso invocador debe consultar `err_lecturas`, registrar el número de fallas en el log operativo y alertar al equipo de ingeniería; si no lo hace, en la finca se asume que todas las estaciones transmitieron bien mientras los sensores dañados quedan desatendidos.

2. ¿Cuándo un proceso de carga está terminado?:
Un proceso de carga está terminado cuando es idempotente, gestiona y persiste los rechazos sin detener el flujo válido, y deja trazabilidad completa en cada ejecución.

3. Fila de la clase 12:
- Qué pasó: Carga masiva con datos corruptos y reejecución duplicada.
- Qué avisó: LOG ERRORS y la tabla ERR_LECTURAS con códigos ORA específicos, evitando errores silenciosos y colisiones de clave única.
*/


-- EXTRA: Prueba a escala en mayo con CONNECT BY

-- Generación de 8.640 lecturas sintéticas para mayo en staging_lecturas
INSERT INTO staging_lecturas (archivo, linea, sensor_id, fecha_hora, valor)
SELECT 'lect_mayo_escala.csv',
       ROWNUM,
       TO_CHAR(s.sensor_id),
       TO_CHAR(DATE '2026-05-01' + (t.n - 1) / 48, 'YYYY-MM-DD HH24:MI'),
       TO_CHAR(ROUND(20 + MOD(t.n, 15) * 0.5, 2))
  FROM sensores s
 CROSS JOIN (SELECT LEVEL AS n FROM dual CONNECT BY LEVEL <= 1440) t;

COMMIT;

-- 1) Medición con bucle FOR (D1):
DECLARE
  t0 NUMBER := DBMS_UTILITY.GET_TIME;
  v_ok NUMBER := 0;
BEGIN
  DELETE FROM lecturas WHERE fecha_hora >= DATE '2026-05-01';
  FOR r IN (SELECT * FROM staging_lecturas WHERE archivo = 'lect_mayo_escala.csv') LOOP
    INSERT INTO lecturas (lectura_id, sensor_id, fecha_hora, valor)
    VALUES (seq_lecturas.NEXTVAL, TO_NUMBER(r.sensor_id), TO_DATE(r.fecha_hora, 'YYYY-MM-DD HH24:MI'), TO_NUMBER(r.valor));
    v_ok := v_ok + 1;
  END LOOP;
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Escala Bucle D1: ' || v_ok || ' filas en ' || (DBMS_UTILITY.GET_TIME - t0) || ' centesimas de segundo');
END;
/

-- 2) Medición con FORALL (D2):
DECLARE
  TYPE t_num IS TABLE OF NUMBER;
  TYPE t_fec IS TABLE OF DATE;
  v_sensor t_num;
  v_fecha  t_fec;
  v_valor  t_num;
  t0 NUMBER := DBMS_UTILITY.GET_TIME;
BEGIN
  DELETE FROM lecturas WHERE fecha_hora >= DATE '2026-05-01';
  SELECT TO_NUMBER(sensor_id), TO_DATE(fecha_hora, 'YYYY-MM-DD HH24:MI'), TO_NUMBER(valor)
    BULK COLLECT INTO v_sensor, v_fecha, v_valor
    FROM staging_lecturas
   WHERE archivo = 'lect_mayo_escala.csv';

  FORALL i IN 1 .. v_sensor.COUNT
    INSERT INTO lecturas (lectura_id, sensor_id, fecha_hora, valor)
    VALUES (seq_lecturas.NEXTVAL, v_sensor(i), v_fecha(i), v_valor(i));
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Escala FORALL D2: ' || v_sensor.COUNT || ' filas en ' || (DBMS_UTILITY.GET_TIME - t0) || ' centesimas de segundo');
END;
/

/*
JUSTIFICACIÓN EXTRA:
A una escala de 8.640 registros, FORALL supera drásticamente al bucle FOR tradicional (reduciendo el tiempo en más de un 80%) debido a que procesa las inserciones en memoria por lotes, eliminando los 8.640 context switches individuales entre PL/SQL y SQL.
*/