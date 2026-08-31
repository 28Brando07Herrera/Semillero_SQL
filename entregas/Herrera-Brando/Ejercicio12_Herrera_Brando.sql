-- =====================================================================
-- EJERCICIO 12 · Un proceso de carga se juzga por la segunda corrida
-- Brando Herrera
-- Correr DESPUES de agrodb_oracle_clase12.sql (Run Script, F5)
-- =====================================================================


-- =====================================================================
-- PARTE A · El archivo, antes de tocarlo
-- =====================================================================

-- A1 — la predicción
SELECT linea, sensor_id, fecha_hora, valor
  FROM staging_lecturas
 WHERE archivo = 'lect_20260501.csv'
 ORDER BY linea;

/*
A1 - Predicción antes de ejecutar nada:
  linea 3  -> valor '21,50' usa coma como separador decimal, sospecho
              que puede romper la conversión a NUMBER
  linea 4  -> valor 'n/d' no es numérico, no convierte
  linea 5  -> valor '-999' convierte bien como número, pero probablemente
              viola el CHECK (valor BETWEEN -50 AND 1500)
  linea 6  -> valor vacío ('') -> en Oracle '' IS NULL, así que
              TO_NUMBER('') devuelve NULL sin error de conversión;
              el problema real va a aparecer después, al insertar,
              porque valor es NOT NULL
  linea 11 -> sensor_id ' 4 ' y valor ' 512.00 ' traen espacios, pero
              con TRIM debería convertir bien
  linea 14 -> sensor_id '99' no existe en la tabla sensores, va a
              fallar por la clave foránea al insertar
  linea 18 -> mismo sensor_id, misma fecha_hora que la línea 17
              (2026-05-01 01:00) -> duplicado, viola el UNIQUE
              (sensor_id, fecha_hora)
  linea 19 -> fecha_hora '2026-05-01 25:00' no es una hora válida,
              no debería convertir con TO_DATE
*/

-- A2 — por qué el staging no valida nada
/*
A2:
Si staging_lecturas.sensor_id fuera NUMBER con REFERENCES sensores,
la línea del sensor 99 no entraría nunca a staging_lecturas: el propio
INSERT del script base fallaría por la clave foránea antes de que
esa fila quedara registrada en ningún lado.
Esa línea no quedaría anotada en ninguna tabla.
Nunca me enteraría de que existió, salvo que alguien revise el archivo
original línea por línea a mano fuera de la base — se pierde en silencio.
*/

-- A3 — separar "no se entiende" de "no se acepta"
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
A3:
Si escribiera TO_NUMBER(valor) a secas (sin el DEFAULT ... ON CONVERSION
ERROR), la línea 4 ('n/d') tiraría ORA-01722 y cortaría toda la consulta
ahí mismo — ni siquiera vería el diagnóstico de las 19 líneas restantes,
porque el error de una sola fila revienta la sentencia completa
(no hay manejo fila por fila en un SELECT plano).
*/

-- A4 — el TRIM
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
A4:
Sin el TRIM, la línea 11 (sensor_id ' 4 ', valor ' 512.00 ', con
espacios) sigue marcando "convierte": TO_NUMBER tolera espacios en
blanco alrededor del número aunque no se haga TRIM explícito. No cambió
el diagnóstico de esa línea. No todo lo que se ve sucio (con espacios)
rompe la conversión.
*/

-- A5
/*
A5:
La consulta de A3 encontró 4 problemas de conversión (sensor/fecha/valor
ilegibles) y todavía no cargué nada. A esas 4 las rechazó el ARCHIVO
(el texto en sí no se puede interpretar como número o fecha), no el
modelo — el modelo (las tablas con sus CHECK y FK) todavía no entró
en juego en esta consulta.
*/


-- =====================================================================
-- PARTE B · Cargar sin perder los errores
-- =====================================================================

-- B1 — dónde van a vivir los rechazos
BEGIN
  DBMS_ERRLOG.CREATE_ERROR_LOG(dml_table_name     => 'LECTURAS',
                               err_log_table_name => 'ERR_LECTURAS');
END;
/

SELECT column_name, data_type
  FROM user_tab_columns
 WHERE table_name = 'ERR_LECTURAS'
 ORDER BY column_id;

/*
B1:
La tabla de rechazos guarda todo como texto (VARCHAR2) porque tiene que
poder guardar justamente la fila que falló por no cumplir el tipo
original. Si la columna valor en err_lecturas fuera NUMBER, guardar el
rechazo de la línea 4 ('n/d') fallaría por la misma razón exacta por la
que falló el INSERT original: 'n/d' tampoco cabe en un NUMBER. Una
tabla de errores tipada no puede guardar los errores de tipo.
*/

-- B2 — la carga
INSERT INTO lecturas (lectura_id, sensor_id, fecha_hora, valor)
SELECT seq_lecturas.NEXTVAL,
       TO_NUMBER(TRIM(sensor_id) DEFAULT NULL ON CONVERSION ERROR),
       TO_DATE(TRIM(fecha_hora) DEFAULT NULL ON CONVERSION ERROR, 'YYYY-MM-DD HH24:MI'),
       TO_NUMBER(TRIM(valor)     DEFAULT NULL ON CONVERSION ERROR)
  FROM staging_lecturas
 WHERE archivo = 'lect_20260501.csv'
  LOG ERRORS INTO err_lecturas ('carga 1') REJECT LIMIT UNLIMITED;

COMMIT;

SELECT COUNT(*) AS lecturas   FROM lecturas;       -- esperado: 8652
SELECT COUNT(*) AS rechazadas FROM err_lecturas;    -- esperado: 8

-- B3 — leer los rechazos
SELECT ora_err_number$ AS ora, COUNT(*) AS filas
  FROM err_lecturas
 GROUP BY ora_err_number$
 ORDER BY filas DESC, ora;

SELECT ora_err_number$, ora_err_mesg$, sensor_id, fecha_hora, valor
  FROM err_lecturas
 ORDER BY ora_err_number$;

/*
B3 - tabla de códigos ORA:

ORA      | significado                          | línea(s) del archivo
---------|--------------------------------------|----------------------
ORA-01400| no se puede insertar NULL en VALOR    | línea 4 ('n/d'),
         |                                        | línea 6 (vacío),
         |                                        | y las que fallan
         |                                        | conversión de fecha
         |                                        | o sensor (línea 19,
         |                                        | según entorno)
ORA-00001| restricción UNIQUE violada             | línea 18 (mismo
         | (sensor_id, fecha_hora duplicados)    | sensor+hora que la 17)
ORA-02290| restricción CHECK violada              | línea 5 ('-999',
         | (valor fuera de -50..1500)             | fuera de rango)
ORA-02291| clave foránea: no existe el padre      | línea 14 (sensor_id
         | (sensor_id 99 no existe en sensores)  | 99 no existe)

Nota: si mi sesión usa coma como separador decimal
(NLS_NUMERIC_CHARACTERS), la línea 3 ('21,50') puede convertir como
2150 en vez de fallar la conversión, y en ese caso el error que sale
es distinto (posible ORA-02290 si ese valor cae fuera del rango del
CHECK, en vez de un error de conversión).
*/

-- B4 — reconciliar
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
B4:
Los rechazos eran 8, pero esta consulta muestra solo 6. Las dos que
faltan son la línea 6 (valor vacío, que SÍ convierte a
sensor_id=1 y fecha_hora válida, pero el NULL del valor lo rechazó el
INSERT por el NOT NULL) y la línea 18 (duplicado exacto de sensor_id y
fecha_hora de la línea 17: como la línea 17 SÍ entró, el NOT EXISTS
encuentra esa combinación sensor+fecha en lecturas y la línea 18 queda
"tapada" por su gemela que sí cargó). El NOT EXISTS compara solo
sensor_id+fecha_hora, no ve que hay una fila EXTRA con esos mismos
valores que se perdió. Si esta hubiera sido mi única forma de
controlar la carga, habría reportado solo 6 problemas en vez de 8.
*/

-- B5 — la trampa del día
/*
B5:
LOG ERRORS convirtió ocho errores en no-errores a propósito, y eso está
bien SIEMPRE QUE alguien efectivamente consulte la tabla err_lecturas
después de cada carga como parte del proceso (por ejemplo, revisando
COUNT(*) o el detalle de ora_err_mesg$), y no solo confíe en que la
sentencia terminó "sin excepción".
*/

-- B6
/*
B6:
Comparando mi lista de A1 contra los resultados reales de B3:
acerté las líneas 3, 4, 5, 6, 14, 18 y 19. No anticipé bien el motivo
exacto de la línea 19 (esperaba que fallara la conversión de fecha por
'25:00', lo cual sí ocurrió, coincide con lo esperado).
Lo que no vi venir del todo fue el mecanismo exacto de por qué B4 no
detecta la línea 6 y la 18 como rechazos (la reconciliación con
NOT EXISTS), algo que solo quedó claro corriendo la consulta.
*/


-- =====================================================================
-- PARTE C · La segunda corrida
-- =====================================================================

-- C1 — el bot se colgó y lo volvieron a arrancar
INSERT INTO lecturas (lectura_id, sensor_id, fecha_hora, valor)
SELECT seq_lecturas.NEXTVAL,
       TO_NUMBER(TRIM(sensor_id) DEFAULT NULL ON CONVERSION ERROR),
       TO_DATE(TRIM(fecha_hora) DEFAULT NULL ON CONVERSION ERROR, 'YYYY-MM-DD HH24:MI'),
       TO_NUMBER(TRIM(valor)     DEFAULT NULL ON CONVERSION ERROR)
  FROM staging_lecturas
 WHERE archivo = 'lect_20260501.csv'
  LOG ERRORS INTO err_lecturas ('carga 2') REJECT LIMIT UNLIMITED;

COMMIT;

SELECT COUNT(*) AS lecturas   FROM lecturas;       -- esperado: 8652 (no se movió)
SELECT COUNT(*) AS rechazadas FROM err_lecturas;    -- esperado: 28

SELECT ora_err_tag$, ora_err_number$, COUNT(*)
  FROM err_lecturas
 GROUP BY ora_err_tag$, ora_err_number$
 ORDER BY 1, 3 DESC;

SELECT MAX(lectura_id) FROM lecturas;

/*
C1:
1. La tabla no se duplicó por el modelo, no por mi código: el
   CONSTRAINT uq_lecturas UNIQUE (sensor_id, fecha_hora) de la clase 6
   es lo que rechaza los intentos de reinsertar filas que ya existen.
   Mi sentencia no tiene ninguna lógica para detectar que ya corrió
   antes.
2. err_lecturas pasó de 8 a 28 filas. De las 20 nuevas, 14 son
   ORA-00001 (duplicados: "esto ya estaba", no errores nuevos de
   verdad) y las 6 restantes son los mismos errores reales de siempre
   (conversión/CHECK/FK) repetidos porque el archivo original sigue
   teniendo esos mismos defectos. La tabla ya no representa solo
   "problemas": ahora mezcla problemas reales con ruido de repetición,
   así que no se puede seguir usando tal cual para reportar sin primero
   filtrar los ORA-00001 de la segunda corrida.
3. En la primera corrida los duplicados eran 2 (la línea 18 contra la
   17). En la segunda corrida, las 12 filas que sí habían entrado bien
   en la primera corrida (12 buenas) ahora chocan todas contra sí
   mismas al reintentar el INSERT completo, sumando los 12 duplicados
   nuevos a los 2 de antes = 14.
4. El MAX(lectura_id) es mayor que 8640+12 porque seq_lecturas.NEXTVAL
   se evalúa una vez por cada fila LEÍDA del staging (20 en la primera
   corrida + 20 en la segunda = 40 números consumidos), no una vez por
   cada fila efectivamente insertada (solo 12). Las secuencias no
   participan de la transacción: un valor "gastado" en una fila
   rechazada no se recupera, ni siquiera con ROLLBACK.
*/

-- C2 — la corrección que llegó después
SELECT linea, sensor_id, fecha_hora, valor
  FROM staging_lecturas
 WHERE archivo = 'lect_20260501_rev2.csv'
 ORDER BY linea;

/*
C2:
Con un INSERT que solo inserta lo que falta (NOT EXISTS):
  línea 1 -> corrige sensor 1, 2026-05-01 01:00 (antes 'n/d' en la
             línea 4 original, ahora corregida). Como esa combinación
             sensor+fecha nunca entró bien, NOT EXISTS no la encuentra
             en lecturas y SÍ se insertaría correctamente.
  línea 2 -> corrige sensor 1, 2026-05-01 01:30, mismo caso: nunca
             había entrado, así que SÍ se inserta.
  línea 3 -> sensor 2, 2026-05-01 00:00, valor 68.20. Esta combinación
             YA EXISTE en lecturas (entró en la carga original con
             valor 68.00). NOT EXISTS encuentra que ya existe esa
             combinación sensor+fecha y NO hace nada: el valor viejo
             (68.00) se queda tal cual, y la corrección (68.20) se
             descarta en silencio, sin ningún error.
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

SELECT COUNT(*) FROM lecturas;                            -- esperado: 8654
SELECT valor FROM lecturas
 WHERE sensor_id = 2 AND fecha_hora = DATE '2026-05-01';   -- esperado: 68.2

-- C4 — la prueba de verdad (correr el mismo MERGE otra vez)
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
 WHERE fecha_hora >= DATE '2026-05-01';   -- esperado, las dos veces: 14 filas, suma 2121.7

/*
C4:
1. El MERGE volvió a reportar "3 filas" (2 UPDATE + 1 UPDATE... en
   realidad las 3 ya existían, así que hizo 3 UPDATE con el mismo valor
   que ya tenían). Sí "hizo algo" en el sentido de que ejecutó las
   sentencias de actualización, pero el resultado final no cambió nada.
2. El COUNT(*) no alcanza para probar que no cambió nada, porque un
   COUNT solo mide cuántas filas hay, no qué valores tienen. Si el
   MERGE hubiera vuelto a pisar un valor con algo distinto, el COUNT
   seguiría igual mientras que la SUM sí lo habría detectado, porque
   agrega el contenido real de las filas, no solo su cantidad.
3. Idempotente quiere decir que correr la misma operación una vez o
   varias veces produce siempre el mismo estado final, aunque el
   proceso internamente "trabaje" en cada corrida. A un bot que se
   puede reiniciar solo esto le importa muchísimo más que a una
   persona, porque el bot no sabe (ni le importa) si ya corrió antes:
   simplemente puede volver a ejecutar la misma sentencia con
   confianza de que no va a romper ni duplicar nada.
*/

-- C5 — lo que el INSERT no habría hecho
/*
C5:
Con INSERT ... WHERE NOT EXISTS, la corrección del sensor 2 (línea 3
de rev2) NO se habría aplicado — no hubiera dado ningún error, la
sentencia habría terminado "bien" pero simplemente no habría tocado
esa fila, dejando el valor viejo (68.00) en vez del corregido (68.20).
Es exactamente el mismo patrón que venimos viendo desde la clase 8: un
CREATE VIEW IF NOT EXISTS que no reemplaza nada, un SEARCH que lee de
más sin avisar, claves apagadas que dejan pasar filas imposibles, un
WHEN OTHERS THEN NULL que traga errores — en todos los casos la
operación "termina bien" sin ningún aviso, mientras el dato real queda
silenciosamente desactualizado o incorrecto.
*/


-- =====================================================================
-- PARTE D · Cuándo sí hace falta el bucle
-- =====================================================================

-- Reset antes de D1
DELETE FROM lecturas WHERE fecha_hora >= DATE '2026-05-01';
DELETE FROM err_lecturas;
COMMIT;

SELECT COUNT(*) FROM lecturas;   -- esperado: 8640

-- D1 — el bucle, pero honesto
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
D1:
Este WHEN OTHERS no es el de ayer porque SÍ deja rastro: cada vez que
captura un error, registra el número de línea y el mensaje exacto con
DBMS_OUTPUT antes de continuar, y además lleva la cuenta de cuántas
filas entraron bien y cuántas mal. No se traga el error en silencio:
lo hace visible en el momento, solo que decide no detener todo el
proceso por una fila mala. Sigue "tragándose" la posibilidad de que
alguien no revise la salida de DBMS_OUTPUT, pero al menos la
información existe y quedó impresa.
*/

-- Reset antes de D2
DELETE FROM lecturas WHERE fecha_hora >= DATE '2026-05-01';
DELETE FROM err_lecturas;
COMMIT;

-- D2 — la misma tarea, un solo viaje
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

SELECT COUNT(*) FROM lecturas;   -- esperado: 8652

/*
D2:
Sin SAVE EXCEPTIONS, el FORALL se habría detenido en la primera fila
que falla (línea 3, si va en el orden del staging) y ninguna de las
filas posteriores a esa se habría intentado insertar siquiera —
probablemente solo las filas anteriores a la primera falla habrían
entrado. El bloque se entera de cuáles fallaron después, al terminar
todo el FORALL, revisando la colección SQL%BULK_EXCEPTIONS, que guarda
el índice (ERROR_INDEX) y el código de error (ERROR_CODE) de cada fila
que no pudo insertarse, sin haber interrumpido el resto de las filas
buenas.
*/

-- D3 — la cuenta que cierra la clase de ayer
/*
D3:

Forma                          | Sentencias SQL | Context switches | Dónde quedan los errores
--------------------------------|----------------|-------------------|---------------------------
B2 · INSERT...SELECT LOG ERRORS |       1        |         1         | tabla err_lecturas
D1 · bucle FOR con INSERT       |      20        |        20         | DBMS_OUTPUT (se pierde si
                                 |                |                   | nadie lo lee en el momento)
D2 · BULK COLLECT + FORALL      |       1        |         1         | SQL%BULK_EXCEPTIONS (en
                                 |                |                   | memoria, hay que capturarlo
                                 |                |                   | antes de que termine el bloque)

Si las tres dan el mismo resultado final (12 adentro, 8 afuera), no
mandaría a producción "la más rápida": mandaría B2, porque es la única
de las tres donde los errores quedan guardados en una TABLA que
sobrevive después de que termina la sesión — cualquiera puede
consultarla después, mientras que DBMS_OUTPUT y SQL%BULK_EXCEPTIONS se
pierden en cuanto se cierra la conexión si nadie los procesó antes.
*/

-- D4 — la respuesta a la pregunta de ayer
/*
D4:
No, no significa que nunca hay que usar bucles: significa que el
bucle es el último recurso, no el primero. Un caso concreto donde el
bucle fila-por-fila de D1 es preferible al FORALL de D2: cuando cada
fila necesita una decisión que depende del RESULTADO de la fila
anterior (por ejemplo, un saldo acumulado donde la fila 5 depende de
si la fila 4 se insertó con éxito o no) — ahí no se puede resolver con
una sola sentencia SQL ni con un FORALL, porque FORALL asume que cada
fila es independiente de las demás.
*/


-- =====================================================================
-- PARTE E · Nunca se concatena SQL a mano
-- =====================================================================

-- E1 — la versión que se usa en todos lados
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

SELECT lecturas_abril_concat('1')        AS normal FROM dual;   -- esperado: 1440
SELECT lecturas_abril_concat('1 OR 1=1') AS ups    FROM dual;   -- esperado: 8640

/*
E1:
  normal (sensor '1') -> 1440
  ups ('1 OR 1=1')    -> 8640
No dio ningún error: la función devolvió el conteo del mes completo en
vez del conteo de un solo sensor.
*/

-- E2 — la versión con variable de enlace
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

SELECT lecturas_abril_bind('1')        FROM dual;   -- esperado: 1440
SELECT lecturas_abril_bind('1 OR 1=1') FROM dual;   -- esperado: se rompe

/*
E2:
  bind('1')          -> 1440
  bind('1 OR 1=1')   -> ORA-01722: invalid number
*/

-- E3
/*
E3:
1. La versión con bind no validó nada, no revisó el texto ni buscó
   palabras prohibidas, pero no se la puede engañar porque el texto
   '1 OR 1=1' nunca se convierte en parte de la instrucción SQL: se
   pasa completo como el VALOR del parámetro :s. El motor intenta
   comparar sensor_id (NUMBER) contra el texto completo '1 OR 1=1'
   como si fuera un solo valor a convertir a número, y como eso no es
   un número válido, tira ORA-01722 en vez de ejecutar nada raro.
2. En la versión concatenada, '1 OR 1=1' se convierte en INSTRUCCIÓN
   (queda pegado literalmente dentro del texto SQL que se ejecuta).
   En la versión con bind, se convierte en VALOR (un dato que se le
   pasa a una sentencia ya fija, sin poder alterar su estructura).
3. Con la versión concatenada, cada sensor distinto genera un texto
   SQL diferente ('...sensor_id = 1', '...sensor_id = 2', etc.), así
   que el motor tiene que analizar (parsear) mil sentencias distintas
   por día. Con la versión con bind, el texto SQL es siempre EL MISMO
   ('...sensor_id = :s'), solo cambia el valor que se le pasa, así que
   el motor puede reutilizar el mismo plan de ejecución ya analizado
   (queda en el shared pool) en vez de analizar mil sentencias nuevas.
*/

-- E4 — el cierre del día
/*
E4:
El dato que viene de afuera no es un dato: es una propuesta. Tanto
TO_NUMBER(... DEFAULT NULL ON CONVERSION ERROR) como una variable de
enlace tratan lo que llega desde afuera de la base como algo que hay
que interpretar con cuidado antes de confiar en ello — el primero
decidiendo explícitamente qué hacer si no se puede convertir, y el
segundo asegurando que ese texto externo nunca se convierta en parte
de la instrucción que se ejecuta, sino solo en un valor.
*/


-- =====================================================================
-- PARTE F · Cierre
-- =====================================================================

/*
F1:
El proceso que llamó a la carga de B tendría que, después de cada
INSERT ... LOG ERRORS, consultar automáticamente COUNT(*) FROM
err_lecturas (o algo similar) y avisar si ese número es mayor a cero,
en vez de solo revisar si la sentencia lanzó una excepción. Si no lo
hace, en la finca las ocho lecturas rechazadas simplemente desaparecen
del sistema sin que nadie lo note: decisiones de riego o fertilización
basadas en esos sensores quedarían tomadas con datos incompletos, sin
que el equipo tenga forma de saberlo.

F2:
Un proceso de carga está terminado cuando alguien (persona o proceso
automatizado) revisó explícitamente la tabla de rechazos y confirmó
que cada fila que no entró tiene una explicación conocida y aceptada
— no cuando la sentencia simplemente dejó de dar error.

F3:
Clase 12 — Una carga terminó "bien" (sin excepción) con ocho filas
rechazadas y guardadas en una tabla de errores que nadie consultó
automáticamente. El proceso avisó "carga OK" en su log a pesar de
haber perdido efectivamente el 40% de las líneas del archivo, y ese
"nada" es justo el patrón que se repite desde la clase 5: la sentencia
no avisa por sí sola, hay que preguntarle.
*/
