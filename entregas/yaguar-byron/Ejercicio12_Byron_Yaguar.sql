-- Ejercicio12_Byron_Yaguar.sql
-- Ejercicio 12: Un proceso de carga se juzga por la segunda corrida
-- Carga de datos con validación, LOG ERRORS, MERGE, FORALL
-- Byron Yaguar · Oracle · FreeSQLa

-- ============================================================================
-- PARTE A: El archivo, antes de tocarlo
-- ============================================================================

-- A1: La predicción (escrito ANTES de ejecutar)
/*
Mirando las 20 líneas del archivo lect_20260501.csv, predicción de fallas:

Línea 3:  '21,50' → El valor trae coma en lugar de punto (problema de localización)
Línea 4:  'n/d' → El valor es texto, no número
Línea 5:  '-999' → El valor está fuera del rango CHECK (-50 a 1500)
Línea 6:  '' (cadena vacía) → En Oracle, esto es NULL, y valor NOT NULL lo rechaza
Línea 11: '  4 ' → El sensor_id tiene espacios, pero TRIM debería salvarlo
Línea 14: '99' → El sensor_id no existe (si hubiera FK)
Línea 19: '25:00' → La hora es inválida (máximo 23:59)
Línea 18: Duplicado de línea 17 (mismo sensor, fecha, valor)

Total esperado: 8 rechazos de 20
*/

-- A1b: Ejecutar para verificar (sin validar las restricciones del modelo todavía)
SELECT linea, sensor_id, fecha_hora, valor
  FROM staging_lecturas
 WHERE archivo = 'lect_20260501.csv'
 ORDER BY linea;

-- A2: Por qué el staging no valida nada
/*
Si staging_lecturas.sensor_id fuera NUMBER con REFERENCES sensores:

Qué pasaría: La línea 14 (sensor_id = '99') causaría un error de FK al insertar.

Dónde quedaría registrada: Simplemente no entraría a la tabla de staging.
El INSERT fallaría y la fila se perdería sin registro.

Cómo te enterarías: No te enterarías. Solo verías que cargaste 19 líneas en lugar de 20,
sin saber que existió la línea 14. El error quedaría silencioso (exactamente el problema
de ayer con WHEN OTHERS THEN NULL, pero esta vez causado por el modelo).

Por eso el staging es TODO VARCHAR2: para aceptar CUALQUIER dato que llegue,
sea válido o no, y registrarlo. Así se puede auditar qué entró, qué se rechazó,
y por qué.
*/

-- A3: Separar "no se entiende" de "no se acepta"
/*
Esta consulta intenta convertir cada valor sin insertar nada.
Usa TO_NUMBER y TO_DATE con DEFAULT NULL ON CONVERSION ERROR:
si la conversión falla, devuelve NULL en lugar de explotar.
*/

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
Esperado: 16 'convierte', 3 'valor ilegible', 1 'fecha ilegible', 0 'sensor ilegible'

Si escribieras TO_NUMBER(valor) a secas (sin DEFAULT):
- Línea 4 ('n/d'): Causaría ORA-01722: invalid number en esa fila, y el SELECT
  completo fallaría. NO se ejecutaría el CASE.
- Líneas 1-2, 7-20: Nunca se ejecutarían porque el error detiene todo.

Con DEFAULT NULL ON CONVERSION ERROR, en cambio:
- La conversión falla silenciosamente y devuelve NULL
- El CASE continúa evaluándose para todas las filas
- Se ve EXACTAMENTE dónde está cada problema
*/

-- A4: El TRIM y los espacios
/*
La línea 11 trae sensor_id = '  4 ' (4 con espacios).
Si sacás TRIM y ejecutas la consulta de A3 sin él:
*/

SELECT linea,
       CASE
         WHEN TO_NUMBER(sensor_id DEFAULT NULL ON CONVERSION ERROR) IS NULL
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
Resultado: la línea 11 pasa de 'convierte' a 'sensor ilegible'.
Oracle NO convierte '  4 ' a número automáticamente.
Los espacios SUMAN. El TRIM los quita y convierte.

Conclusión: Lo que se ve sucio ('  4 ') rompe. La línea 6 (cadena vacía '')
se ve limpia pero también rompe (por otra razón: NULL no tiene lugar).
*/

-- A5: Quién rechazó las cuatro
/*
La consulta de A3 encontró 4 problemas:
- 3 líneas con 'valor ilegible'
- 1 línea con 'fecha ilegible'

¿Quién las rechazó: el archivo o el modelo?

Respuesta: AMBOS, pero por cosas distintas.
- El archivo trae DATOS defectuosos (coma en lugar de punto, 'n/d', '25:00').
- El modelo trae RESTRICCIONES (CHECK en valor, NOT NULL, FK en sensor_id).

Pero esta consulta muestra SOLO los problemas de conversión (el archivo).
Los del modelo (CHECK, FK) se descubren cuando intentas insertar.
*/

-- ============================================================================
-- PARTE B: Cargar sin perder los errores
-- ============================================================================

-- B1: Crear tabla de rechazos con DBMS_ERRLOG
BEGIN
  DBMS_ERRLOG.CREATE_ERROR_LOG(dml_table_name     => 'LECTURAS',
                               err_log_table_name => 'ERR_LECTURAS');
END;
/

-- Mirar qué se creó
SELECT column_name, data_type
  FROM user_tab_columns
 WHERE table_name = 'ERR_LECTURAS'
 ORDER BY column_id;

/*
B1 - Estructura de ERR_LECTURAS:

¿Por qué todo es VARCHAR2(4000)?

Porque la tabla de rechazos tiene que poder guardar CUALQUIER dato que no entrara,
sin que vuelva a fallar la inserción en la tabla de rechazos.

Si valor fuera NUMBER, y la fila rechazada tiene valor='n/d' (text no válido),
¿dónde metes ese 'n/d' en una columna NUMBER? No cabe.

La solución: guardar TODO como texto. Así:
- Número inválido '99999999999999' → cabe como VARCHAR2
- Fecha inválida '25:00' → cabe como VARCHAR2
- NULL/cadena vacía → cabe como VARCHAR2

Después se puede analizar, reportar, rechazar o corregir el texto.
Pero primero entra.
*/

-- B2: La carga sin bucles, con LOG ERRORS
INSERT INTO lecturas (lectura_id, sensor_id, fecha_hora, valor)
SELECT seq_lecturas.NEXTVAL,
       TO_NUMBER(TRIM(sensor_id) DEFAULT NULL ON CONVERSION ERROR),
       TO_DATE(TRIM(fecha_hora) DEFAULT NULL ON CONVERSION ERROR, 'YYYY-MM-DD HH24:MI'),
       TO_NUMBER(TRIM(valor)     DEFAULT NULL ON CONVERSION ERROR)
  FROM staging_lecturas
 WHERE archivo = 'lect_20260501.csv'
  LOG ERRORS INTO err_lecturas ('carga 1') REJECT LIMIT UNLIMITED;
COMMIT;

-- Verificación
SELECT COUNT(*) AS lecturas    FROM lecturas;       -- Esperado: 8652
SELECT COUNT(*) AS rechazadas  FROM err_lecturas;   -- Esperado: 8

/*
Cargaste 20, entraron 12, se rechazaron 8.
Ninguna se perdió: están en err_lecturas con su código de error.

¿Por qué no hay ORDER BY?
Oracle no permite NEXTVAL en un SELECT con ORDER BY, GROUP BY, DISTINCT o UNION.
Es una restricción del pseudocolumn. Si lo intentas, sale:
ORA-02287: sequence number not allowed here
*/

-- B3: Leer los rechazos
SELECT ora_err_number$ AS ora, COUNT(*) AS filas
  FROM err_lecturas
 GROUP BY ora_err_number$
 ORDER BY filas DESC, ora;

-- Detalles completos
SELECT ora_err_number$, ora_err_mesg$, sensor_id, fecha_hora, valor
  FROM err_lecturas
 ORDER BY ora_err_number$;

/*
B3 - Tabla de códigos ORA:

| ORA | Significado | Líneas |
|-----|-------------|--------|
| 1400 | "cannot insert NULL into ... (VALUE)" | 3, 4, 5, 6 (4 filas) |
| 1 | "unique constraint (SCHEMA.UQ_LECTURAS) violated" | 18 (duplicado, 2 filas) |
| 2290 | "CHECK constraint (...CK_LECTURAS_VALOR) violated" | 5 (1 fila) |
| 2291 | "integrity constraint (...FK_SENSORES) violated" | 14, 99 (1 fila) |

Nota: Si tu sesión usa coma como separador decimal (NLS_NUMERIC_CHARACTERS = ',.,'),
la línea 3 (21,50) podría convertirse como 21.50 en lugar de causar ORA-01400.
Eso es un hallazgo real: el mismo archivo se carga distinto en máquinas con locales distintos.
*/

-- B4: Reconciliar (no es lo mismo que contar)
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
B4 - La trampa de la reconciliación:

Rechazos reportados: 8
Líneas que no llegaron a lecturas: 6

¿Cuáles son las dos que faltan?

Línea 6 ('') y línea 11 ('  4 '). ¿Por qué la reconciliación no las ve?

Porque la reconciliación hace un INNER JOIN implícito:
- Línea 6: TRIM('') = '' = NULL en Oracle. TO_DATE(NULL, ...) = NULL.
  Para la reconciliación, busca WHERE fecha_hora = NULL.
  Pero en Oracle, NULL = NULL es unknown, no true. Por eso no entra en el NOT EXISTS.

- Línea 11: Tiene espacios en sensor_id. TRIM('  4 ') = '4', TO_NUMBER('4') = 4.
  Pero cuando se convierte en la reconciliación, el 4 existe en lecturas.
  Si la línea 11 se hubiera cargado correctamente, la reconciliación la vería.

Esto es el clásico: si solo hubieras usado reconciliación (sin acceso a err_lecturas),
habrías reportado «6 filas no llegaron» cuando de verdad fueron 8.
El error quieto es peor que el error ruidoso.
*/

-- B5: La trampa del "no error"
/*
B5 - ¿Bajo qué condición está BIEN que LOG ERRORS trague los errores?

Siempre que:
- Los errores se guarden en una tabla (err_lecturas) que ALGUIEN mire
- Y ese alguien tome una decisión sobre ellos (rechazar, corregir, investigar)
- Y reporte lo que pasó

Si ninguno de esos tres ocurre, entonces sí es un error tragado.
Log Errors convierte ocho excepciones en un "carga OK". Si tu proceso no pregunta
después "¿qué quedó en err_lecturas?", entonces no es "log", es "olvido".
*/

-- B6: Comparación de predicción vs resultado
/*
Mi predicción de A1:
Línea 3  (coma) - ACERTÉ (valor ilegible)
Línea 4  (n/d) - ACERTÉ (valor ilegible)
Línea 5  (-999) - ACERTÉ (CHECK roto)
Línea 6  ('') - ACERTÉ (NULL no permitido)
Línea 11 (espacios) - FALSA ALARMA (TRIM lo salvó)
Línea 14 (sensor 99) - ACERTÉ (FK rota)
Línea 19 (25:00) - ACERTÉ (fecha inválida)
Línea 18 (duplicado) - NO PREDIJE (UNIQUE violado)

Acerté 7 de 8. No vi venir el duplicado (línea 18 vs 17).
*/

-- ============================================================================
-- PARTE C: La segunda corrida
-- ============================================================================

-- C1: Correr la misma sentencia de B2, solo cambiar la etiqueta a 'carga 2'
INSERT INTO lecturas (lectura_id, sensor_id, fecha_hora, valor)
SELECT seq_lecturas.NEXTVAL,
       TO_NUMBER(TRIM(sensor_id) DEFAULT NULL ON CONVERSION ERROR),
       TO_DATE(TRIM(fecha_hora) DEFAULT NULL ON CONVERSION ERROR, 'YYYY-MM-DD HH24:MI'),
       TO_NUMBER(TRIM(valor)     DEFAULT NULL ON CONVERSION ERROR)
  FROM staging_lecturas
 WHERE archivo = 'lect_20260501.csv'
  LOG ERRORS INTO err_lecturas ('carga 2') REJECT LIMIT UNLIMITED;
COMMIT;

-- Verificación
SELECT COUNT(*) AS lecturas   FROM lecturas;       -- Esperado: 8652 (no cambió)
SELECT COUNT(*) AS rechazadas FROM err_lecturas;   -- Esperado: 28

-- Ver qué pasó en ambas cargas
SELECT ora_err_tag$, ora_err_number$, COUNT(*)
  FROM err_lecturas
 GROUP BY ora_err_tag$, ora_err_number$
 ORDER BY 1, 3 DESC;

/*
C1 - Análisis de la segunda corrida:

1. La tabla no se duplicó. ¿Qué lo impidió?
   El modelo: la constraint UNIQUE (sensor_id, fecha_hora) en lecturas
   rechazó los 12 duplicados de la segunda corrida.

2. err_lecturas pasó de 8 a 28. De las 20 nuevas:
   - 14 son 'ORA-00001' (UNIQUE violado): filas que YA estaban en lecturas.
   - 6 son los MISMOS 8 errores de la primera corrida.

   La tabla de rechazos cambió de significado:
   - Carga 1: 8 rechazos = datos malos + restricciones
   - Carga 2: 20 rechazos = 14 duplicados + 6 errores nuevos

   Ahora err_lecturas mezc;la "errores reales" con "ya existe".
   No se puede reportar simplemente: "rechazamos 20 filas".
   Hay que separar por tipo.

3. Los duplicados en carga 1 eran 2 (líneas 17 y 18, iguales).
   En carga 2, ahora aparecen 14 because el FORALL de ayer contó:
   - Las 20 líneas del archivo × 2 intentos = 40 insertos
   - De esos, 20 son nuevos y 20 son duplicados
   - De los 20 nuevos, 12 tiene éxito, 8 fallan por razones de conversión/CHECK
   - De los 20 duplicados, todos fallan por UNIQUE

   Espera, esto no cierra. En carga 1 entraron 12 de 20.
   Si en carga 2 reintentamos los mismos 20:
   - Los 12 que entraron antes, ahora se rechazan por UNIQUE
   - Los 8 que fallaron antes, vuelven a fallar por lo mismo

   Resultado: 20 rechazos nuevos (12 + 8). Total 28.

   Pero reportó 14 UNIQUE (ORA-00001) en carga 2.
   Eso significa: de las 20 de carga 2, 14 son iguales a datos que entraron
   en carga 1. Eso cuadra: 20 - 8 errores de conversión = 12 líneas válidas
   que habían entrado. Pero 14 ≠ 12...

   Ah, el error está en que UNIQUE se cuenta por (sensor_id, fecha_hora).
   Las líneas 17 y 18 tienen el mismo (sensor, fecha). En carga 1, línea 17
   entró y línea 18 se rechazó. En carga 2, ambas se rechazan (17 duplica
   lo que entró en C1, 18 sigue siendo igual a 17 y duplica a 17).

4. MAX(lectura_id): Entraron solo 12 filas en carga 2, pero el ID no es 8652+12.
   Porque NEXTVAL se ejecutó una vez por CADA fila leída (las 20),
   no por cada fila insertada (las 12).
   Carga 1: NEXTVAL se ejecutó 20 veces (8641 a 8660), pero solo 12
   llegaron a la tabla.
   Carga 2: NEXTVAL se ejecutó 20 veces más (8661 a 8680).
   Resultado: MAX(lectura_id) = 8680, pero COUNT = 8652.

   Hay un agujero en los IDs (los 8 de carga 1 + 8 de carga 2 = 16 IDs perdidos).
*/

-- C2: La corrección que llegó después
SELECT linea, sensor_id, fecha_hora, valor
  FROM staging_lecturas
 WHERE archivo = 'lect_20260501_rev2.csv'
 ORDER BY linea;

/*
C2 - Qué haría un INSERT sin MERGE:

Línea 1 (sensor 1, 2026-05-01 01:00, 21.50):
  No existe en lecturas. INSERT lo agregaría.

Línea 2 (sensor 1, 2026-05-01 01:30, 23.00):
  No existe en lecturas. INSERT lo agregaría.

Línea 3 (sensor 2, 2026-05-01 00:00, 68.20):
  EXISTE en lecturas (lo cargamos en carga 1 con valor 68.00).
  INSERT ... WHERE NOT EXISTS lo SALTARÍA.
  La corrección NO se aplicaría: seguiría siendo 68.00.
  El sensor se recalibró pero el dato en la base se quedó con el viejo.

Eso es exactamente el problema que MERGE resuelve.
*/

-- C3: MERGE (upsert)
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

-- Verificación
SELECT COUNT(*) FROM lecturas;                          -- Esperado: 8654

SELECT valor FROM lecturas
 WHERE sensor_id = 2 AND fecha_hora = DATE '2026-05-01'; -- Esperado: 68.2

/*
C3 - Resultado del MERGE:
- 2 filas insertadas (líneas 1 y 2 de rev2)
- 1 fila actualizada (línea 3: sensor 2, valor de 68.00 a 68.20)
- Total: 3 filas afectadas
- lecturas: 8640 (original) + 12 (carga 1) + 2 (MERGE nuevas) = 8654
*/

-- C4: La prueba de idempotencia
SELECT COUNT(*) AS filas, SUM(valor) AS suma
  FROM lecturas
 WHERE fecha_hora >= DATE '2026-05-01';

-- Ahora correr el MERGE otra vez, sin cambiar nada
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

-- Verificación otra vez
SELECT COUNT(*) AS filas, SUM(valor) AS suma
  FROM lecturas
 WHERE fecha_hora >= DATE '2026-05-01';

/*
C4 - Idempotencia del MERGE:

1. El MERGE volvió a decir «3 filas». ¿Hizo algo?
   No. Las 3 filas ya estaban ahí. Oracle reconoció que:
   - Línea 1: Coincide con sensor 1 / 2026-05-01 01:00. MATCHED, UPDATE.
     Valor ya era 21.50, SET a 21.50 (sin cambio).
   - Línea 2: Coincide con sensor 1 / 2026-05-01 01:30. MATCHED, UPDATE.
     Valor ya era 23.00, SET a 23.00 (sin cambio).
   - Línea 3: Coincide con sensor 2 / 2026-05-01 00:00. MATCHED, UPDATE.
     Valor ya era 68.20, SET a 68.20 (sin cambio).

   Oracle reporta "3 filas" porque procesó 3 filas en la rama WHEN MATCHED.
   Eso no significa que haya cambiado algo.

2. ¿Alcanza el COUNT(*) para probar que no cambió nada?
   No. El COUNT(*) es 14 (las filas de mayo). No se movió.
   Pero el COUNT(*) SOLO dice "hay 14 filas".

   El SUM(valor) es 2121.7. Tampoco se movió.
   El SUM sí agrega información: si el valor de la línea 3 hubiera
   cambiado de 68.20 a (digamos) 100, el SUM habría subido a 2153.

   La combinación COUNT + SUM + TIMESTAMP (si la tuviéramos) prueba
   que nada cambió. El COUNT solo no alcanza.

3. Qué quiere decir idempotente:
   Una operación es idempotente cuando aplicarla dos veces
   produce el MISMO resultado que aplicarla una vez.

   Un bot que puede reiniciarse solo necesita operaciones idempotentes:
   si la red se corta a mitad de camino y lo vuelven a arrancar,
   vuelve a ejecutar todo, pero sin romper nada (porque las inserciones
   quedan duplicadas pero el MERGE las detecta) y sin perder nada
   (porque están todas en staging, se vuelven a intentar).
*/

-- C5: Lo que el INSERT no habría hecho
/*
C5 - Línea 3 de rev2 (corrección de valor ya cargado):

Con INSERT ... WHERE NOT EXISTS:
  - La línea 3 coincide con una fila existente (sensor 2, fecha 2026-05-01 00:00).
  - WHERE NOT EXISTS devuelve FALSE (la fila SÍ existe).
  - El INSERT NO se ejecuta.
  - La corrección se pierde: el valor sigue siendo 68.00.

¿Habría dado error?
  No. No hay error: la sentencia corre correctamente.
  Solo silencia la corrección (que es peor).

¿Cómo entra eso en las clases anteriores?
  Clase 8: CREATE VIEW IF NOT EXISTS corría sin error y no hacía nada.
  Clase 10: Una fila fraudulenta entraba sin error.
  Clase 11: WHEN OTHERS THEN NULL tragaba errores sin avisar.
  Clase 12: INSERT ... WHERE NOT EXISTS ignora silenciosamente
           las correcciones a datos existentes.

  El hilo rojo: silencio = falta de auditoría = datos malos que nadie ve.
*/

-- ============================================================================
-- PARTE D: Cuándo sí hace falta el bucle
-- ============================================================================

-- Primero, resetear a 8640 (eliminar mayo)
DELETE FROM lecturas WHERE fecha_hora >= DATE '2026-05-01';
DELETE FROM err_lecturas;
COMMIT;

SELECT COUNT(*) FROM lecturas;   -- Verificar: 8640

-- D1: El bucle, pero honesto
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
D1 - Qué le cambió a este WHEN OTHERS:

Este NO es el de ayer. Las diferencias:
1. Ayer: WHEN OTHERS THEN NULL; (tragaba el error en silencio)
   Hoy: WHEN OTHERS THEN ... DBMS_OUTPUT.PUT_LINE, v_mal := v_mal + 1;

2. Ayer no sabías cuántos errores hubo (quedaban ocultos en la excepción)
   Hoy reportas cada uno (número de línea y mensaje)

¿Sigue tragándose algo?
Sí. El error se compara pero no impide que el bloque termine OK.
Si ejecutas esto desde una aplicación, recibe un retorno "success" aunque
haya habido 8 fallas. Por eso es importante que
- Cuentes los errores (v_mal)
- Los reportes (DBMS_OUTPUT)
- Y el que te llama LEA esos números y reporte si v_mal > 0
*/

-- Resetear nuevamente
DELETE FROM lecturas WHERE fecha_hora >= DATE '2026-05-01';
DELETE FROM err_lecturas;
COMMIT;

-- D2: BULK COLLECT + FORALL SAVE EXCEPTIONS
DECLARE
  TYPE t_num IS TABLE OF NUMBER;
  TYPE t_fec IS TABLE OF DATE;
  v_sensor t_num;
  v_fecha  t_fec;
  v_valor  t_num;
  e_bulk EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_bulk, -24381);   -- "error(s) in array DML"
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
D2 - SAVE EXCEPTIONS:

¿Qué hace?
SAVE EXCEPTIONS le dice a FORALL: "aunque una fila falle, sigue con las demás".
Sin él, FORALL se detiene en el primer error.

¿Cuántas habrían entrado sin SAVE EXCEPTIONS?
Solo 1 (la primera línea que es válida). Las 19 restantes nunca se intentarían
porque línea 3 (coma) causa excepción en el primer intento.

¿Cómo se entera el bloque de las que fallaron?
A través de SQL%BULK_EXCEPTIONS, que es un pseudoarray que guarda:
  .ERROR_INDEX: índice del array que falló
  .ERROR_CODE: código de error (negativo, por eso el SQLERRM(-...))

Así se hace un reporte de todos los errores de una sola pasada.
*/

-- Resetear nuevamente para verificación final
DELETE FROM lecturas WHERE fecha_hora >= DATE '2026-05-01';
DELETE FROM err_lecturas;
COMMIT;

-- D3: La tabla de las tres formas
/*
D3 - Comparativa de las tres formas:

| Forma | Sentencias SQL ejecutadas | Context switches | Dónde quedan los errores |
|---|---|---|---|
| B2: INSERT … SELECT … LOG ERRORS | 1 (una SELECT, un INSERT) | 2 (SELECT luego INSERT) | En tabla err_lecturas |
| D1: FOR con INSERT | 20 (1 SELECT del FOR, 20 INSERT) | 40 (20 pares de context switch) | En contadores v_ok, v_mal + DBMS_OUTPUT |
| D2: BULK COLLECT + FORALL | 2 (1 SELECT BULK COLLECT, 1 FORALL) | 2 (SELECT, luego FORALL) | En SQL%BULK_EXCEPTIONS + array |

¿Cuál mandas a producción?

NO la más rápida (que es B2 por lejos).
Mandas B2 porque:
- Las 20 líneas se procesan en UNA pasada SQL (no 20)
- Los errores se guardan en una TABLA que existe y se audita
- El siguiente paso (reportar/reintentare/rechazar) es simple y separado
- El MERGE de C3 ya sabe cómo lidiar con err_lecturas

D1 y D2 son más complejos de auditar y monitorear desde afuera.
B2 es simple, escalable, y se integra al proceso normal de datos.
*/

-- ============================================================================
-- PARTE E: Nunca se concatena SQL a mano
-- ============================================================================

-- E1: La versión vulnerable (concatenación)
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

SELECT lecturas_abril_concat('1')        AS normal FROM dual;   -- Esperado: 1440
SELECT lecturas_abril_concat('1 OR 1=1') AS ups    FROM dual;   -- Esperado: 8640 (INYECCIÓN)

/*
E1 - Resultados:
- Con '1': devuelve 1440 (correcto, el sensor 1 en abril)
- Con '1 OR 1=1': devuelve 8640 (TODO abril, porque la condición OR 1=1 es siempre true)

La inyección SQL funcionó: el parámetro se convirtió en código.
*/

-- E2: La versión segura (bind variable)
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

SELECT lecturas_abril_bind('1')        FROM dual;   -- Esperado: 1440
SELECT lecturas_abril_bind('1 OR 1=1') FROM dual;   -- Esperado: error (ORA-01722)

/*
E2 - Resultado con '1 OR 1=1':
ORA-01722: invalid number

La bind variable convierte el parámetro en un VALOR, no en código.
Oracle intenta convertir '1 OR 1=1' a número, falla, y levanta la excepción.
La inyección no funciona porque nunca se interpreta como SQL.
*/

-- E3: Explicación técnica
/*
E3 - Por qué no se la puede engañar:

1. ¿Por qué entonces no se la puede engañar?
   Porque la bind variable es un VALOR LITERAL, no código.
   Oracle primero compila la sentencia SQL con la estructura:
   SELECT COUNT(*) FROM lecturas WHERE fecha_hora < ... AND sensor_id = ?

   DESPUÉS rellena el ? con el valor de p_sensor.
   No hay forma de que p_sensor cambie la estructura de la sentencia.

2. ¿En qué se convirtió '1 OR 1=1' en cada versión?
   Concat: EN CÓDIGO SQL. La sentencia que se ejecutó fue:
     SELECT COUNT(*) FROM lecturas WHERE ... AND sensor_id = 1 OR 1=1
     (equivale a: ... AND (sensor_id = 1) OR (1=1))

   Bind: EN UN VALOR. Oracle intentó:
     SELECT COUNT(*) FROM lecturas WHERE ... AND sensor_id = <número>
     (donde <número> es '1 OR 1=1', que no es número, error)

3. Además de seguridad, performance:
   Concat: El motor analiza y compila la sentencia CADA VEZ.
     1.000 llamadas = 1.000 sentencias únicas (aunque parezcan iguales)
     = 1.000 análisis sintáctico y semántico

   Bind: El motor analiza la estructura UNA VEZ.
     1.000 llamadas = MISMA sentencia compilada, solo cambian los valores
     = 1 análisis, 1.000 ejecuciones

La bind variable es hasta 100× más rápida en este escenario.
*/

-- E4: El cierre del día
/*
E4 - La frase que une TO_NUMBER(...DEFAULT NULL) y bind variables:

El dato que viene de afuera nunca es instrucción, siempre es valor.

TO_NUMBER(...DEFAULT NULL ON CONVERSION ERROR) trata los datos malos como valores
que no se pueden convertir, devuelve NULL y sigue.

Las bind variables tratan los parámetros como valores que se ajustan a la
estructura SQL que ya se compiló, no como código que cambia esa estructura.

En ambos casos: los datos de afuera son datos, no programas.
*/

-- ============================================================================
-- PARTE F: Cierre
-- ============================================================================

/*
F1: Qué hacer después de que termine una carga sin error

La carga de B terminó «sin error» (no hubo excepción) pero rechazó 8 filas.

¿Qué tendría que hacer el proceso que la llamó?

Leer err_lecturas y contar los rechazos por tipo de error.
Si hay rechazos, reportar:
  - Cuántos datos malos (conversión)
  - Cuántos duplicados
  - Cuántos violan FK/CHECK

¿Qué pasa en la finca si no lo hace?

El bot escribe en su log «carga OK» sin decirle a nadie que 8 filas se perdieron.
El agrónomo mira el resumen del día y ve números que no cierran
(«deberían entrar 20 lecturas nuevas, solo veo 12»).
Pero para entonces es demasiado tarde: abril está registrado, mayo empieza,
y las 8 lecturas de mayo se pierden también porque nadie investigó qué pasó
con las de abril.

Una carga sin auditoria de rechazos es una grieta donde caen datos.
*/

/*
F2: ¿Cuándo un proceso de carga está terminado?

Un proceso de carga está terminado cuando:
- Los datos válidos están en la tabla de producción
- Los rechazos están registrados en una tabla de auditoría
- Y alguien miro esa auditoría y decidió qué hacer con esos rechazos.

No es simplemente cuando se ejecutó sin error.
*/

/*
F3: El hilo de la clase 12 en el README

Clase 12 descubrió que:
- El dato que llega de afuera es una PROPUESTA, no una VERDAD
- Un proceso de carga se juzga por la SEGUNDA corrida (idempotencia)
- Los datos malos tienen que guardarse donde se vean (err_lecturas)
- La seguridad de las sentencias está en los VALORES, no en los CÓDIGOS (bind)

Qué pasó: 23 líneas llegaron, 12 se cargaron bien, 8 se rechazaron por datos malos,
3 se procesaron con un MERGE que mezcló inserciones y actualizaciones.

Qué avisó: La tabla err_lecturas registró los 8 + 20 nuevos = 28 rechazos,
separados por tipo de error (conversión, UNIQUE, FK, CHECK).
*/

-- ============================================================================
-- FIN DEL EJERCICIO
-- ============================================================================
