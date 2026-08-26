---
marp: true
paginate: true
theme: default
title: "Clase 12 · Datos que llegan de afuera"
style: |
  section { font-family: system-ui, -apple-system, "Segoe UI", sans-serif; font-size: 26px; background: #fbfbfa; color: #1f2933; padding: 60px 70px; }
  section.lead { background: #16324f; color: #f4f7fa; }
  section.lead h1 { color: #ffffff; font-size: 58px; line-height: 1.1; }
  section.lead h2 { color: #7fb3d5; font-weight: 400; font-size: 30px; }
  h1 { color: #16324f; font-size: 42px; border-bottom: 3px solid #f2a104; padding-bottom: 10px; }
  h2 { color: #1c7293; font-size: 32px; }
  strong { color: #b3541e; }
  code { background: #eef2f6; padding: 1px 6px; border-radius: 4px; }
  pre { background: #16324f; border-radius: 8px; font-size: 21px; }
  pre code { background: transparent; color: #e8eef4; }
  table { font-size: 23px; }
  th { background: #16324f; color: #fff; }
  blockquote { border-left: 5px solid #f2a104; color: #4a5568; font-style: normal; }
  footer { color: #8a99a8; font-size: 16px; }
footer: "Curso de SQL · AgroDB · Clase 12"
---

<!-- _class: lead -->

# La segunda corrida

## Datos que llegan de afuera: staging, rechazos y el bot que se reinició

Clase 12 · 25 de agosto

---

# Ayer terminamos con esto

```sql
EXCEPTION
  WHEN OTHERS THEN NULL;      -- "para que no moleste"
```

Cargamos cuatro labores, entraron dos, y **no hubo ni un error**.

<br>

Hoy el problema es el mismo, pero ya no viene de una línea que escribió alguien con prisa. Viene de **afuera de la base**, y no lo escribió nadie: lo mandó un proceso.

---

# 6:00 de la mañana

Un bot deja un archivo en una carpeta. Adentro, las mediciones que los sensores acumularon durante la noche.

Nadie lo mira. Entra solo.

<br>

Hoy entró. El bot escribió en su log:

```
[06:00:04] lect_20260501.csv  ->  carga OK
```

<br>

**Veinte líneas traía el archivo. Ocho no llegaron a la base.**

---

# Y a las 9:40

El bot se colgó.

Alguien lo volvió a arrancar.

Corrió **otra vez** sobre el mismo archivo.

<br>

> Las dos cosas que pasaron hoy son las dos cosas que le pasan a todo proceso de carga que existe. La pregunta no es si van a pasar: es qué hace tu proceso cuando pasan.

---

# El archivo, tal cual llegó

| línea | sensor | fecha_hora | valor |
|---|---|---|---|
| 1 | `1` | `2026-05-01 00:00` | `21.50` |
| 3 | `1` | `2026-05-01 01:00` | `21,50` |
| 5 | `1` | `2026-05-01 02:00` | `-999` |
| 6 | `1` | `2026-05-01 02:30` | |
| 11 | `  4 ` | `2026-05-01 00:00` | ` 512.00 ` |
| 14 | `99` | `2026-05-01 00:00` | `30.00` |
| 19 | `1` | `2026-05-01 25:00` | `23.00` |
| 20 | `1` | `2026-04-30 23:30` | `20.00` |

Ocho de las veinte. **Ninguna viene marcada como mala.**

---

# La primera decisión: dónde se valida

<br>

| Validar contra la tabla final | Validar en una tabla aparte |
|---|---|
| la fila mala **no entra** | la fila mala **entra igual** |
| tampoco queda registro de ella | queda, con su número de línea |
| el proceso se cae, o la pierde | el proceso sigue |
| te enterás si alguien contó antes | te enterás mirando una tabla |

<br>

> La segunda tabla se llama **staging**. Y lo raro de un staging es lo que **no** tiene.

---

# El staging de hoy

```sql
CREATE TABLE staging_lecturas (
  archivo    VARCHAR2(40) NOT NULL,
  linea      NUMBER       NOT NULL,
  sensor_id  VARCHAR2(20),
  fecha_hora VARCHAR2(30),
  valor      VARCHAR2(20),
  CONSTRAINT pk_staging_lecturas PRIMARY KEY (archivo, linea)
);
```

Todo `VARCHAR2`. Sin `CHECK`. Sin `NOT NULL` sobre el contenido. **Sin clave foránea contra `sensores`.**

Parece una tabla mal hecha.

---

# Es exactamente al revés

El trabajo del staging es **aceptar todo**, incluida la basura, para que se pueda mirar antes de decidir.

<br>

Si el staging tuviera la clave foránea, la línea del sensor 99 **no entraría**.

Y entonces: ¿dónde queda anotado que existió?

<br>

> En ningún lado. Se pierde en silencio. Que es la única cosa que este curso no perdona.

<br>

Lo único con restricción es **de qué archivo y de qué línea** viene cada fila. Eso no es dato del sensor: es trazabilidad.

---

# Convertir texto sin explotar

`'n/d'` no es un número. `TO_NUMBER('n/d')` es `ORA-01722` y se cae la consulta entera.

<br>

```sql
TO_NUMBER(TRIM(valor) DEFAULT NULL ON CONVERSION ERROR)
```

<br>

*«Convertilo. Y si no se puede, devolvé `NULL`.»*

<br>

Igual para fechas:

```sql
TO_DATE(TRIM(fecha_hora) DEFAULT NULL ON CONVERSION ERROR,
        'YYYY-MM-DD HH24:MI')
```

---

# Y esto es la contracara exacta de ayer

<br>

| ayer | hoy |
|---|---|
| `WHEN OTHERS THEN NULL` | `DEFAULT NULL ON CONVERSION ERROR` |
| el `NULL` está a 30 líneas | el `NULL` está **en la expresión** |
| tapa **cualquier** error | tapa **un** error, el de conversión |
| no sabés cuál fue | sabés exactamente cuál fue |

<br>

> Los dos hacen que algo no explote. La diferencia es si podés leer, en el lugar donde pasa, **qué decidiste que pase**.

---

# La cadena vacía, otra vez

La línea 6 trae el valor vacío. Ayer lo vimos en la parte A del ejercicio:

```sql
SELECT CASE WHEN '' IS NULL THEN 'ES null' ELSE 'NO es null' END
  FROM dual;   -- en Oracle: ES null
```

<br>

Así que `TO_NUMBER` **no falla** con esa línea. Convierte perfecto: `NULL`.

Y la línea pasa el filtro de conversión sin un rasguño.

<br>

> El problema aparece después, y lo dice otro: `ORA-01400`.

---

# El diagnóstico, sin insertar nada

```sql
SELECT linea,
       CASE WHEN TO_NUMBER(TRIM(valor)
                   DEFAULT NULL ON CONVERSION ERROR) IS NULL
            THEN 'valor ilegible' ELSE 'convierte' END
  FROM staging_lecturas WHERE archivo = 'lect_20260501.csv';
```

<br>

**16 convierten. 4 no.**

<br>

Y acá está la mitad del día en una pregunta:

> Esas cuatro, ¿quién las rechazó? **No fue el modelo. Fue el archivo.**

---

# Ahora sí, cargar

```sql
INSERT INTO lecturas (lectura_id, sensor_id, fecha_hora, valor)
SELECT seq_lecturas.NEXTVAL,
       TO_NUMBER(TRIM(sensor_id) DEFAULT NULL ON CONVERSION ERROR),
       TO_DATE(TRIM(fecha_hora)  DEFAULT NULL ON CONVERSION ERROR,
               'YYYY-MM-DD HH24:MI'),
       TO_NUMBER(TRIM(valor)     DEFAULT NULL ON CONVERSION ERROR)
  FROM staging_lecturas
 WHERE archivo = 'lect_20260501.csv';
```

<br>

Una sentencia. Sin bucle. Es lo que aprendimos ayer.

**¿Qué pasa cuando la fila 3 falla?**

---

# Se cae entera

<br>

Una sentencia SQL es **atómica**: o entran las veinte o no entra ninguna.

```
ORA-01400: cannot insert NULL into ("LECTURAS"."VALOR")
0 rows inserted.
```

<br>

Doce filas perfectamente buenas no entraron **porque otras ocho estaban mal**.

<br>

> Y acá es donde el que tiene prisa escribe un bucle con `WHEN OTHERS`. No hace falta.

---

# Primero, dónde van a caer

**La tabla de rechazos hay que crearla. No aparece sola.**

```sql
BEGIN
  DBMS_ERRLOG.CREATE_ERROR_LOG(dml_table_name     => 'LECTURAS',
                               err_log_table_name => 'ERR_LECTURAS');
END;
/
```

<br>

Trae las columnas de `lecturas` **todas como `VARCHAR2(4000)`**, más cinco propias:

`ORA_ERR_NUMBER$` · `ORA_ERR_MESG$` · `ORA_ERR_ROWID$` · `ORA_ERR_OPTYP$` · `ORA_ERR_TAG$`

<br>

> **Si te la salteás:** `ORA-00942: table or view "ERR_LECTURAS" does not exist`. Y el `INSERT` no carga nada.

---

# ¿Por qué todo texto?

<br>

Porque esa tabla tiene que poder guardar la fila que falló **justamente porque `valor` no era un número**.

<br>

Si la columna `valor` fuera `NUMBER`, guardar el rechazo fallaría **por la misma razón** por la que falló el `INSERT`.

<br>

> Una tabla de errores tipada no puede guardar los errores de tipo. Es de esas cosas que parecen un chiste hasta que te pasa.

---

# `LOG ERRORS`

```sql
INSERT INTO lecturas (...)
SELECT ...
  FROM staging_lecturas
 WHERE archivo = 'lect_20260501.csv'
  LOG ERRORS INTO err_lecturas ('carga 1') REJECT LIMIT UNLIMITED;
```

<br>

*«Si una fila falla, guardala en `err_lecturas` con su error, y seguí.»*

<br>

```
12 rows inserted.
```

**Entraron 12. Las otras 8 están en una tabla, con su código y su mensaje.**

---

# Los ocho rechazos

| `ORA` | qué dice | cuántas |
|---|---|---|
| `01400` | no se puede insertar `NULL` en… | **4** |
| `00001` | restricción única violada | 2 |
| `02290` | restricción `CHECK` violada | 1 |
| `02291` | clave foránea: no existe el padre | 1 |

<br>

Veinte líneas: **12 adentro, 8 registradas, 0 perdidas.**

---

# Y mirá cómo se parten

<br>

| `ORA-01400` (4) | los otros tres (4) |
|---|---|
| el texto no se pudo convertir | el texto se convirtió bien |
| `21,50` · `n/d` · vacío · `25:00` | `-999` · sensor `99` · duplicada · duplicada |
| **el archivo estaba mal** | **el modelo dijo que no** |

<br>

> Son dos problemas distintos, con dos responsables distintos, y hay que llamar a dos personas distintas. El staging es lo que permite separarlos. Sin staging, son «la carga falló».

---

# Pero mirá bien qué pasó

<br>

La sentencia **terminó sin error**.

No hubo excepción. `SQLCODE` es `0`.

<br>

El proceso que la llamó preguntó *«¿falló?»*, recibió **no**, y escribió:

```
[06:00:04] lect_20260501.csv  ->  carga OK
```

<br>

**`LOG ERRORS` convirtió ocho errores en no-errores. A propósito. Y está bien.**

Siempre que alguien lea la tabla.

---

# La regla del día, primera mitad

<br>
<br>

> ## Un error que guardaste en una tabla que nadie mira es un error que tiraste a la basura, con más pasos.

<br>
<br>

Toda carga que usa `LOG ERRORS` **tiene** que terminar con una consulta a la tabla de rechazos. Si no la tiene, `LOG ERRORS` es `WHEN OTHERS THEN NULL` con una tabla de adorno.

---

# 9:40 — el bot se reinició

La misma sentencia. Sin cambiarle una letra.

<br>

```
0 rows inserted.
```

```sql
SELECT COUNT(*) FROM lecturas;   -- 8652. No se movió.
```

<br>

**No se duplicó nada.** ¿Está bien?

---

# Está bien, y algo se rompió igual

```sql
SELECT COUNT(*) FROM err_lecturas;   -- 28
```

<br>

De las 20 nuevas, **14 son `ORA-00001`**: son las filas que ya estaban.

<br>

| antes | después |
|---|---|
| 8 filas, las 8 son errores | 28 filas, **12 no son errores** |
| «hay 8 problemas» | «hay… ¿cuántos problemas?» |

<br>

> Lo que impidió el duplicado no fue tu código: fue el `UNIQUE (sensor_id, fecha_hora)` que está en el modelo desde la clase 6. Tu código no sabe que corrió dos veces.

---

# Y la secuencia no vuelve atrás

```sql
SELECT MAX(lectura_id) FROM lecturas;   -- más que 8640 + 12
```

<br>

`seq_lecturas.NEXTVAL` se evaluó **una vez por fila leída**, no por fila insertada.

Veinte números consumidos, doce usados. Y en la segunda corrida, veinte más.

<br>

> Las secuencias no participan de la transacción. Un `ROLLBACK` no devuelve los números. Si alguien alguna vez te pide *«que los ids no tengan huecos»*, esta lámina es la respuesta.

---

# Llega la corrección

El gateway reenvía tres líneas:

<br>

| línea | qué es |
|---|---|
| 1 | corrige la que venía `21,50` — **no estaba** |
| 2 | corrige la que venía `n/d` — **no estaba** |
| 3 | el sensor 2 se recalibró: `68.00` → `68.20` — **ya estaba** |

<br>

**La tercera es la que rompe todo lo fácil.**

---

# «Insertá lo que falta» no alcanza

```sql
INSERT INTO lecturas (...)
SELECT ... FROM staging_lecturas s
 WHERE NOT EXISTS (SELECT 1 FROM lecturas l
                    WHERE l.sensor_id = s.sensor_id
                      AND l.fecha_hora = s.fecha_hora);
```

<br>

Las dos primeras entran. La tercera **no hace nada**.

El valor viejo sigue ahí. La corrección se descartó.

<br>

> Y no hubo error. Otra vez. Ya van seis clases.

---

# `MERGE`

```sql
MERGE INTO lecturas l
USING ( SELECT ... FROM staging_lecturas
         WHERE archivo = 'lect_20260501_rev2.csv' ) s
   ON (l.sensor_id = s.sensor_id AND l.fecha_hora = s.fecha_hora)
 WHEN MATCHED THEN
   UPDATE SET l.valor = s.valor
 WHEN NOT MATCHED THEN
   INSERT (lectura_id, sensor_id, fecha_hora, valor)
   VALUES (seq_lecturas.NEXTVAL, s.sensor_id, s.fecha_hora, s.valor);
```

<br>

Una pasada. Por fila decide: **la encontré → actualizo. No la encontré → inserto.**

```
3 rows merged.       -- 2 insertadas + 1 actualizada
```

---

# Y ahora la prueba de verdad

Corré el mismo `MERGE` otra vez.

<br>

```
3 rows merged.
```

```sql
SELECT COUNT(*), SUM(valor) FROM lecturas
 WHERE fecha_hora >= DATE '2026-05-01';
```

| | primera vez | segunda vez |
|---|---|---|
| filas | **14** | **14** |
| suma | **2121.7** | **2121.7** |

<br>

Volvió a hacer el trabajo. **No volvió a cambiar el resultado.**

---

# Eso es idempotente

<br>
<br>

> ## Correlo otra vez y no pasa nada nuevo.

<br>
<br>

No quiere decir *«no hace nada la segunda vez»*. El `MERGE` hizo tres `UPDATE`. Quiere decir que **el estado final es el mismo**, corras una vez o siete.

<br>

Y por eso el `COUNT(*)` solo no alcanza como prueba: contar no ve que un valor cambió. **La suma sí.**

---

# La pregunta de ayer

> *«¿Entonces nunca hay que usar bucles?»*

<br>

Tres formas de cargar el mismo archivo. Las tres dan **12 adentro y 8 afuera**.

<br>

| | sentencias SQL | context switches | dónde quedan los errores |
|---|---|---|---|
| `INSERT … LOG ERRORS` | 1 | **1** | una tabla |
| bucle `FOR` | 20 | **20** | `DBMS_OUTPUT` |
| `BULK COLLECT` + `FORALL` | 1 | **1** | `SQL%BULK_EXCEPTIONS` |

---

# `FORALL … SAVE EXCEPTIONS`

```sql
FORALL i IN 1 .. v_sensor.COUNT SAVE EXCEPTIONS
  INSERT INTO lecturas (lectura_id, sensor_id, fecha_hora, valor)
  VALUES (seq_lecturas.NEXTVAL, v_sensor(i), v_fecha(i), v_valor(i));
```

<br>

**Un solo viaje al motor de SQL, con las veinte filas adentro.**

`SAVE EXCEPTIONS` hace que no se detenga en la primera que falla. Al terminar levanta `ORA-24381`, y ahí:

```sql
SQL%BULK_EXCEPTIONS.COUNT              -- 8
SQL%BULK_EXCEPTIONS(i).ERROR_INDEX     -- qué fila
SQL%BULK_EXCEPTIONS(i).ERROR_CODE      -- qué error
```

---

# ¿Cuál mandás a producción?

<br>

**No la más rápida. Mirá la última columna de la tabla.**

<br>

| forma | cuándo |
|---|---|
| `INSERT … LOG ERRORS` | por defecto. Los errores quedan en una tabla que sobrevive a la sesión |
| `BULK COLLECT` + `FORALL` | cuando cada fila necesita una **decisión** que SQL no puede expresar |
| bucle fila por fila | cuando la decisión de una fila **depende del resultado de la anterior** |

<br>

> El bucle no está prohibido. Está **último**.

---

# La otra cosa que llega de afuera

El archivo del bot es texto que viene de afuera.

**El parámetro de una consulta también.**

```sql
EXECUTE IMMEDIATE
  'SELECT COUNT(*) FROM lecturas WHERE sensor_id = ' || p_sensor
  INTO v_n;
```

<br>

```sql
lecturas_abril_concat('1')          -->  1440
```

---

# Y ahora con el mismo parámetro, distinto contenido

```sql
lecturas_abril_concat('1 OR 1=1')   -->  8640
```

<br>

Le pediste **un sensor**. Te devolvió **el mes entero**.

<br>

No hubo error. No hubo advertencia. La función hizo exactamente lo que le pediste: pegó ese texto adentro de la instrucción y ejecutó **la instrucción resultante**.

<br>

> Eso no es un bug de la función. Es la función funcionando.

---

# Una sola cosa cambia

```sql
EXECUTE IMMEDIATE
  'SELECT COUNT(*) FROM lecturas WHERE sensor_id = :s'
  INTO v_n USING p_sensor;
```

<br>

```sql
lecturas_abril_bind('1')          -->  1440
lecturas_abril_bind('1 OR 1=1')   -->  ORA-01722: invalid number
```

<br>

**No validó nada.** No revisó el texto, no buscó palabras prohibidas, no escapó comillas.

Simplemente el texto dejó de ser **instrucción** y pasó a ser **valor**.

---

# La frase que une el día

<br>
<br>

> ## El dato que viene de afuera no es un dato: es una propuesta.

<br>

`TO_NUMBER(... DEFAULT NULL ON CONVERSION ERROR)` y una variable de enlace parecen dos temas distintos.

Son el mismo: **los dos tratan lo que llegó como dato, y no como parte de la instrucción.**

<br>

*(Y el bind, de yapa, es una sola sentencia en el shared pool en vez de mil.)*

---

# El hilo del curso

| Clase | Qué pasó | Qué avisó |
|---|---|---|
| 5 | un `SUM` inflado por fan-out | nada |
| 8 | `CREATE VIEW IF NOT EXISTS` no reemplazó nada | nada |
| 9 | un `SEARCH` que leía media tabla | nada |
| 10 | cinco filas imposibles con las claves apagadas | nada |
| 11 | dos `INSERT` adentro de `WHEN OTHERS THEN NULL` | nada |
| **12** | **una carga que terminó «bien» con ocho filas rechazadas** | **nada** |

<br>

> Hoy es distinto en una cosa: los errores **existen y están guardados**. Lo único que falta es que alguien pregunte.

---

<!-- _class: lead -->

# La regla del día

## Un proceso de carga no se juzga por la primera corrida. Se juzga por la segunda.

<br>

Dos horas de práctica. FreeSQL, el mismo de ayer.

`datos/agrodb_oracle_clase12.sql` → **3, 6, 8, 10, 7, 19, 16, 6, 9, 8640, 0, 0, 23**

**La parte C vale 30 de los 100.**
