# Ejercicio práctico 12 · Un proceso de carga se juzga por la segunda corrida
**Duración: 2 horas · Individual · [Oracle FreeSQL](https://freesql.com), en el navegador (o tu Oracle local) · Entrega: un archivo `.sql`**

---

## La situación

Todas las mañanas a las 6:00, un bot deja un archivo en una carpeta. Adentro vienen las mediciones que los sensores acumularon durante la noche. Nadie mira ese archivo: entra solo.

Esta mañana entró. El bot registró *«carga OK»*. Y de las veinte líneas que traía el archivo, **ocho no llegaron a la base**.

Nadie se enteró.

Después, a las 9:40, el bot se colgó y alguien lo volvió a arrancar. Corrió otra vez sobre el mismo archivo.

Hoy escriben el proceso que tendría que haber estado ahí. Y la prueba no es que cargue: es que **se pueda correr dos veces sin romper nada y sin perder nada**.

## Antes de empezar

**Todo esto se hace en el navegador. No hace falta instalar Oracle.** Es el mismo entorno de ayer.

1. Entrá a **<https://freesql.com>** y abrí el **Worksheet**.
2. **Guardá primero tu archivo del ejercicio 11.** El script de hoy borra y vuelve a crear las tablas: si tenías `cargar_labor` o el trigger de la bitácora ahí adentro, se van.
3. Pegá `datos/agrodb_oracle_clase12.sql` **completo** en el worksheet.
4. **Clic en el editor para que no quede nada seleccionado.** Si hay selección, se ejecuta solo eso.
5. **Run Script** (`F5`). **No** `Run Statement` (`Ctrl+Enter`), que ejecuta una sola sentencia.
6. Deben salir **trece** números: **3, 6, 8, 10, 7, 19, 16, 6, 9, 8640, 0, 0, 23**.
7. Trabajá en `Ejercicio12_Apellido_Nombre.sql`.

> **Si te sale `ORA-00942`:** es lo mismo de ayer. Corriste la verificación del final sin haber creado las tablas. Deseleccioná y `Run Script` otra vez.

> **`DBMS_OUTPUT`:** la pestaña **DBMS output** hay que **abrirla y habilitarla antes** de correr el bloque. En local es `SET SERVEROUTPUT ON`.

## La regla del día

> **El dato que llega de afuera no es un dato: es una propuesta.**
>
> Y un proceso de carga no se juzga por la primera corrida. Se juzga por la segunda.

---

## Parte A · El archivo, antes de tocarlo (15 min)

**A1 — la predicción.** Mirá las veinte líneas, sin ejecutar nada todavía:

```sql
SELECT linea, sensor_id, fecha_hora, valor
  FROM staging_lecturas
 WHERE archivo = 'lect_20260501.csv'
 ORDER BY linea;
```

En un comentario, escribí **qué líneas creés que van a fallar y por qué**. Una lista, con el número de línea y una razón corta.

> **Guardá esa lista y no la edites después.** Al final de la parte B la vas a comparar contra la que dio el motor. La diferencia entre las dos listas es lo que se puntúa acá, no el acierto.

**A2 — por qué el staging no valida nada.** Mirá el `CREATE TABLE staging_lecturas` en el script base: todo es `VARCHAR2`, no hay `CHECK`, no hay `NOT NULL` sobre el contenido, y **no hay clave foránea contra `sensores`**.

En un comentario, tres líneas: si `staging_lecturas.sensor_id` fuera `NUMBER` con `REFERENCES sensores`, ¿qué pasaría al cargar la línea del sensor 99? ¿Dónde quedaría **registrada** esa línea? ¿Y cómo te enterarías de que existió?

**A3 — separar «no se entiende» de «no se acepta».** Esta consulta no inserta nada: solo lee el texto e intenta convertirlo.

```sql
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
```

Esperado: **16 `convierte`, 3 `valor ilegible`, 1 `fecha ilegible`, 0 `sensor ilegible`.**

`TO_NUMBER(x DEFAULT NULL ON CONVERSION ERROR)` es la contracara exacta del `WHEN OTHERS THEN NULL` de ayer: **acá vos decidís qué devolver cuando no se puede convertir, y lo decidís en la expresión, a la vista.** Ayer el `NULL` estaba escondido en un manejador de excepciones a treinta líneas de distancia.

En un comentario, dos líneas: si escribieras `TO_NUMBER(valor)` a secas, ¿qué pasaría con la línea 4? ¿Y con las diecinueve restantes?

**A4 — el `TRIM`.** Una de las líneas trae espacios de más. Sacale el `TRIM` a la consulta de A3 y corrella de nuevo.

En un comentario: ¿cambió el diagnóstico de esa línea? Anotá el resultado real, sea el que sea. *(No todo lo que se ve sucio rompe, y no todo lo que rompe se ve sucio. Cuál de las dos cosas pasó acá lo decide el motor, no la intuición.)*

**A5.** En un comentario, una línea: la consulta de A3 encontró 4 problemas. Todavía no cargaste nada. **¿Quién rechazó esas cuatro: el archivo o el modelo?**

---

## Parte B · Cargar sin perder los errores (30 min)

**B1 — dónde van a vivir los rechazos.** Antes de cargar, hay que darle a las filas malas un lugar donde caer:

```sql
BEGIN
  DBMS_ERRLOG.CREATE_ERROR_LOG(dml_table_name     => 'LECTURAS',
                               err_log_table_name => 'ERR_LECTURAS');
END;
/

SELECT column_name, data_type
  FROM user_tab_columns
 WHERE table_name = 'ERR_LECTURAS'
 ORDER BY column_id;
```

Mirá la estructura que armó: están **las columnas de `lecturas`, pero todas como `VARCHAR2(4000)`**, más cinco columnas propias que empiezan con `ORA_ERR_`.

En un comentario, dos líneas: ¿por qué la tabla de rechazos guarda todo como texto y no con los tipos originales? *(Pensá qué tipo tendría que tener `valor` para poder guardar la fila que falló **porque `valor` no era un número**.)*

> **Si tu entorno no te deja usar `DBMS_ERRLOG`,** creala a mano y seguí igual:
>
> ```sql
> CREATE TABLE err_lecturas (
>   ora_err_number$  NUMBER,
>   ora_err_mesg$    VARCHAR2(2000),
>   ora_err_rowid$   ROWID,
>   ora_err_optyp$   VARCHAR2(2),
>   ora_err_tag$     VARCHAR2(2000),
>   lectura_id       VARCHAR2(4000),
>   sensor_id        VARCHAR2(4000),
>   fecha_hora       VARCHAR2(4000),
>   valor            VARCHAR2(4000)
> );
> ```

**B2 — la carga.** Una sola sentencia. Sin bucle, sin `WHEN OTHERS`, sin PL/SQL:

```sql
INSERT INTO lecturas (lectura_id, sensor_id, fecha_hora, valor)
SELECT seq_lecturas.NEXTVAL,
       TO_NUMBER(TRIM(sensor_id) DEFAULT NULL ON CONVERSION ERROR),
       TO_DATE(TRIM(fecha_hora) DEFAULT NULL ON CONVERSION ERROR, 'YYYY-MM-DD HH24:MI'),
       TO_NUMBER(TRIM(valor)     DEFAULT NULL ON CONVERSION ERROR)
  FROM staging_lecturas
 WHERE archivo = 'lect_20260501.csv'
  LOG ERRORS INTO err_lecturas ('carga 1') REJECT LIMIT UNLIMITED;

COMMIT;
```

```sql
SELECT COUNT(*) AS lecturas    FROM lecturas;       -- esperado: 8652
SELECT COUNT(*) AS rechazadas  FROM err_lecturas;   -- esperado: 8
```

Cargaste **20**, entraron **12**, quedaron **8** registradas. Ninguna se perdió.

> **Por qué no hay `ORDER BY` ahí adentro:** Oracle no deja usar `NEXTVAL` en un `SELECT` que tenga `ORDER BY` (ni `GROUP BY`, ni `DISTINCT`, ni `UNION`). Es una restricción del pseudocolumn, no un capricho del ejercicio. Anotala: tiene una consecuencia en B4.

**B3 — leer los rechazos.** Esta es la consulta que el bot tendría que haber corrido y no corrió:

```sql
SELECT ora_err_number$ AS ora, COUNT(*) AS filas
  FROM err_lecturas
 GROUP BY ora_err_number$
 ORDER BY filas DESC, ora;
```

Esperado: **`1400` → 4 · `1` → 2 · `2290` → 1 · `2291` → 1.** Ocho en total.

Y ahora los mensajes completos, que dicen mucho más que el número:

```sql
SELECT ora_err_number$, ora_err_mesg$, sensor_id, fecha_hora, valor
  FROM err_lecturas
 ORDER BY ora_err_number$;
```

En un comentario, una tabla de cuatro filas: para cada código `ORA`, **qué significa** y **qué línea o líneas del archivo lo causaron**. El mensaje de `ORA-01400` te dice hasta la columna.

> **Si tu sesión usa la coma como separador decimal** (`NLS_NUMERIC_CHARACTERS`), una de las líneas te va a salir con `ORA-02290` en vez de `ORA-01400`. **Anotalo: es un hallazgo mejor que el ejercicio.** Comprobalo con `SELECT * FROM nls_session_parameters WHERE parameter = 'NLS_NUMERIC_CHARACTERS';` y escribí en un comentario por qué el mismo archivo se carga distinto en dos máquinas.

**B4 — reconciliar, que no es lo mismo que contar.** Ahora buscá las líneas del archivo que **no** quedaron en `lecturas`:

```sql
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
```

Esperado: **6 filas.**

Pero los rechazos eran **8**.

En un comentario, tres líneas: **¿cuáles son las dos que faltan?** ¿Por qué esta consulta no las ve, si de verdad no entraron? Y la que importa: si esta hubiera sido tu única forma de controlar la carga, **¿qué habrías reportado?**

**B5 — la trampa del día.** La sentencia de B2 **terminó sin error**. No hubo excepción. Un proceso que solo pregunta *«¿falló?»* recibe **no**, y escribe *«carga OK»* en su log.

En un comentario, dos líneas: `LOG ERRORS` convirtió ocho errores en no-errores **a propósito**, y eso está bien. ¿Bajo qué condición está bien? Escribila empezando con «siempre que…».

> **La regla:** un error que guardaste en una tabla que nadie mira es un error que tiraste a la basura, con más pasos.

**B6.** Comparate con vos mismo: pegá al lado tu lista de A1 y la lista real. ¿Cuántas acertaste? ¿Cuál no viste venir, y por qué?

---

## Parte C · La segunda corrida (30 min)

Esta es la parte del día.

**C1 — el bot se colgó y lo volvieron a arrancar.** Corré **exactamente la misma sentencia de B2**, sin cambiarle una letra. Cambiá solo la etiqueta a `'carga 2'`.

```sql
SELECT COUNT(*) AS lecturas   FROM lecturas;       -- esperado: 8652 (no se movió)
SELECT COUNT(*) AS rechazadas FROM err_lecturas;   -- esperado: 28

SELECT ora_err_tag$, ora_err_number$, COUNT(*)
  FROM err_lecturas
 GROUP BY ora_err_tag$, ora_err_number$
 ORDER BY 1, 3 DESC;
```

De las 20 líneas de la segunda corrida, **14 salieron con `ORA-00001`**.

En un comentario, cuatro líneas:

1. La tabla no se duplicó. ¿Qué lo impidió: tu código o el modelo?
2. `err_lecturas` pasó de 8 a 28 filas. De esas 20 nuevas, ¿cuántas son **errores de verdad** y cuántas son *«esto ya estaba»*? **La tabla de rechazos ya no significa lo mismo que hace cinco minutos.** ¿Se puede seguir usando para reportar?
3. En la primera corrida los duplicados eran 2 y ahora son 14. Explicá de dónde salieron los 12 nuevos.
4. Mirá el máximo `lectura_id`: `SELECT MAX(lectura_id) FROM lecturas;`. Entraron 12 filas, pero el número es más alto que `8640 + 12`. ¿Por qué? *(Pista: la secuencia avanzó una vez por cada fila leída, no por cada fila insertada. Y las secuencias no vuelven atrás con el `ROLLBACK`.)*

**C2 — la corrección que llegó después.** El gateway reenvió tres líneas: dos que venían ilegibles, y **una que ya había entrado bien** y ahora trae otro valor porque recalibraron el sensor.

```sql
SELECT linea, sensor_id, fecha_hora, valor
  FROM staging_lecturas
 WHERE archivo = 'lect_20260501_rev2.csv'
 ORDER BY linea;
```

Antes de escribir nada: en un comentario, contestá **qué haría con esas tres líneas un `INSERT` que solo inserta lo que falta**. Las tres, una por una.

**C3 — `MERGE`.** Una sentencia que decide por fila si actualiza o inserta:

```sql
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
```

Esperado: **3 filas afectadas** — 2 insertadas y 1 actualizada, aunque Oracle te las reporte juntas.

```sql
SELECT COUNT(*) FROM lecturas;                          -- esperado: 8654
SELECT valor FROM lecturas
 WHERE sensor_id = 2 AND fecha_hora = DATE '2026-05-01'; -- esperado: 68.2
```

> **Si tu versión no acepta `seq_lecturas.NEXTVAL` adentro del `INSERT` del `MERGE`,** escribilo como las dos sentencias que el `MERGE` reemplaza: un `UPDATE ... WHERE EXISTS` y después un `INSERT ... WHERE NOT EXISTS`. **Anotá que tuviste que hacerlo así y qué diferencia hay** — no es solo estética: son dos pasadas sobre la tabla en vez de una, y entre las dos hay un instante en que el estado no es ni el viejo ni el nuevo.

**C4 — la prueba de verdad.** Corré **el mismo `MERGE` otra vez**, sin cambiar nada.

```sql
SELECT COUNT(*) AS filas, SUM(valor) AS suma
  FROM lecturas
 WHERE fecha_hora >= DATE '2026-05-01';
```

Esperado, **las dos veces**: **14 filas, suma 2121.7**.

En un comentario, tres líneas:

1. El `MERGE` volvió a decir «3 filas». ¿Hizo algo la segunda vez?
2. El `COUNT(*)` no se movió. **¿Alcanza el `COUNT(*)` para probar que no cambió nada?** ¿Por qué la suma sí agrega información y el conteo solo no?
3. Escribí con tus palabras qué quiere decir **idempotente**, y por qué a un bot que se puede reiniciar solo le importa más que a vos.

**C5 — lo que el `INSERT` no habría hecho.** Volvé a tu respuesta de C2. La línea 3 de `rev2` corregía un valor que **ya estaba cargado**.

En un comentario, dos líneas: con `INSERT ... WHERE NOT EXISTS`, esa corrección no se aplicaba. ¿Habría dado error? ¿Y cómo entra eso en la lista de la clase 8, la 9, la 10 y la 11?

---

## Parte D · Cuándo sí hace falta el bucle (20 min)

Ayer alguien preguntó: *«¿entonces nunca hay que usar bucles?»*. Hoy se contesta.

**Antes de empezar, anotá los números de la parte C.** Esta parte borra lo de mayo y vuelve a cargar desde cero, tres veces.

```sql
DELETE FROM lecturas WHERE fecha_hora >= DATE '2026-05-01';
DELETE FROM err_lecturas;
COMMIT;
SELECT COUNT(*) FROM lecturas;   -- esperado: 8640, como al principio
```

**D1 — el bucle, pero honesto.** Es el bucle de ayer con el `WHEN OTHERS` que **sí** cumple la regla que escribiste en D5 del ejercicio 11:

```sql
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
```

Esperado: **`ok=12 mal=8`**, y ocho líneas antes con su número de línea y su error.

En un comentario, dos líneas: este `WHEN OTHERS` no es el de ayer. ¿Qué le cambió, exactamente? ¿Sigue tragándose algo?

**D2 — la misma tarea, un solo viaje.** Reseteá otra vez (el `DELETE` de arriba) y corré:

```sql
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
```

Esperado: **`fallaron 8 de 20`**, y los ocho `ERROR_INDEX` son **3, 4, 5, 6, 14, 18, 19, 20** — porque el `BULK COLLECT` trajo las filas `ORDER BY linea`, así que el índice de la colección **es** el número de línea. Comprobá que `SELECT COUNT(*) FROM lecturas` volvió a dar **8652**.

En un comentario, dos líneas: `SAVE EXCEPTIONS` hace que el `FORALL` **no se detenga** en el primer error. Sin él, ¿cuántas filas habrían entrado? ¿Y cómo se entera el bloque de las que fallaron?

**D3 — la cuenta que cierra la clase de ayer.** Tres formas de cargar el mismo archivo, con el mismo resultado: 12 adentro, 8 afuera.

En un comentario, completá la tabla con números:

| Forma | Sentencias SQL ejecutadas | Context switches | Dónde quedan los errores |
|---|---|---|---|
| B2 · `INSERT … SELECT … LOG ERRORS` | | | |
| D1 · bucle `FOR` con `INSERT` adentro | | | |
| D2 · `BULK COLLECT` + `FORALL` | | | |

Y abajo, en dos líneas: **si las tres dan lo mismo, ¿cuál mandás a producción?** La respuesta no es «la más rápida»: mirá la última columna.

**D4 — la respuesta a la pregunta de ayer.** En un comentario, dos líneas: *«¿entonces nunca hay que usar bucles?»*. Contestá ahora que tenés `FORALL`, y nombrá **un** caso concreto en el que el bucle de D1 sea preferible al `FORALL` de D2.

---

## Parte E · Nunca se concatena SQL a mano (15 min)

El archivo del bot es texto que viene de afuera. Los parámetros de una API también.

**E1 — la versión que se usa en todos lados.**

```sql
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
```

Pegá los dos números como comentario. La función devolvió **el mes entero** cuando le pediste un sensor, y no dio ningún error.

**E2 — la versión con variable de enlace.** Cambia una sola cosa:

```sql
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
```

Pegá el error tal cual.

**E3.** En un comentario, tres líneas:

1. La segunda no validó nada. No revisó el parámetro, no buscó palabras prohibidas, no escapó comillas. **¿Por qué entonces no se la puede engañar?**
2. ¿En qué se convirtió `'1 OR 1=1'` en cada una de las dos versiones: en **instrucción** o en **valor**?
3. Además de la seguridad: si un tablero llama a esta función mil veces por día con mil sensores distintos, ¿cuántas sentencias distintas tiene que analizar el motor en cada versión?

**E4 — el cierre del día.** En un comentario, dos líneas: `TO_NUMBER(... DEFAULT NULL ON CONVERSION ERROR)` y una variable de enlace parecen dos temas distintos. **Escribí la frase que los une.** *(Empieza por «el dato que viene de afuera…».)*

---

## Parte F · Cierre (10 min, comentarios en el archivo)

1. La carga de B terminó **sin error** con ocho filas rechazadas. En dos líneas: ¿qué tendría que hacer el proceso que la llamó, y qué pasa en la finca si no lo hace?
2. En **una frase**: ¿cuándo un proceso de carga está terminado? *(No vale «cuando carga».)*
3. El hilo del curso dice que los errores que dan error son los baratos. Mirá la tabla del [README del repo](../../README.md) y escribí **la fila de la clase 12**: qué pasó, y qué avisó.

---

## Rúbrica (100 puntos)

| Criterio | Pts |
|---|---|
| Parte A: la predicción escrita antes de ejecutar, y los 4 problemas de conversión separados de los del modelo | 10 |
| Parte B: la carga con `LOG ERRORS`, los 12 / 8, los cuatro códigos `ORA` explicados y las 2 filas que la reconciliación no ve | 25 |
| **Parte C: la segunda corrida, el `MERGE`, y la prueba de idempotencia con suma y no solo con conteo** | **30** |
| Parte D: `FORALL SAVE EXCEPTIONS` con los 8 `ERROR_INDEX`, y la tabla de las tres formas completa | 20 |
| Parte E: las dos funciones, el 8640 de la inyección, y el error de la versión con bind | 10 |
| Preguntas de cierre con criterio | 5 |

Los criterios suman **100** exactos.

**Extra (+5):** llevalo a escala. Generá el resto de mayo en el staging con `CONNECT BY` (mirá cómo se generan las lecturas de abril en el script base), cargalo con el bucle de D1 y con el `FORALL` de D2, y medí los dos con `DBMS_UTILITY.GET_TIME`. **Reportá siempre la cantidad de filas junto al tiempo**: la regla de ayer sigue en pie.

El archivo debe correr **completo** de arriba abajo después de `datos/agrodb_oracle_clase12.sql`. Usá `CREATE OR REPLACE` en las funciones.

**Y una advertencia sobre el orden:** las partes C y D dependen del estado que dejó la anterior. Si volvés atrás a rehacer algo, volvé a correr el script base desde cero. Un archivo de entrega que corre limpio de arriba abajo es parte de la nota — es exactamente el problema de la segunda corrida, aplicado a tu propio trabajo.
