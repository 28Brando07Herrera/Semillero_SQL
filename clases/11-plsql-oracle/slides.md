---
marp: true
paginate: true
theme: default
title: "Clase 11 · PL/SQL sobre Oracle"
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
footer: "Curso de SQL · AgroDB · Clase 11"
---

<!-- _class: lead -->

# Fila por fila es lento por lento

## PL/SQL sobre Oracle, y las cuatro cosas que se rompen al cruzar la calle

Clase 11 · 24 de agosto

---

# La finca compró Oracle

No les preguntaron.

<br>

| Lo que cambia | Lo que no |
|---|---|
| el tipo de dato | el modelo |
| cómo se escribe una fecha | los datos, hasta el último kilo |
| cómo se limita el resultado | `SELECT`, `WHERE`, `GROUP BY`, `JOIN` |
| cómo se borra una tabla | ventanas, CTE, vistas, índices |

<br>

> Lo importante de hoy no es aprender Oracle. Es descubrir **cuánto de lo que saben era SQL y cuánto era SQLite**, sin haberlo elegido nunca.

---

# Empecemos por el golpe

```sql
SELECT 1;
```

```
ORA-00923: FROM keyword not found where expected
```

<br>

En Oracle, todo `SELECT` sale de algo. Si no sale de una tabla, sale de `dual`:

```sql
SELECT 1 FROM dual;
```

> `dual` es una tabla con una fila y una columna que existe para esto. Es fea, es histórica, y la van a escribir mil veces.

---

# Las cuatro que se rompen

| Escribiste | Oracle dice | Se escribe |
|---|---|---|
| `SELECT 1;` | ORA-00923 | `SELECT 1 FROM dual;` |
| `... LIMIT 5` | ORA-00933 | `FETCH FIRST 5 ROWS ONLY` |
| `DROP TABLE IF EXISTS x` | ORA-00933 | preguntarle a `user_tables` |
| `DATE(fecha_hora)` | ORA-00936 | `TRUNC(fecha_hora)` |

<br>

Y una quinta, que corre **exactamente igual**:

```sql
SELECT sensor_id, COUNT(*) FROM lecturas GROUP BY sensor_id;
```

> Esa última es la mitad de la lección del día.

---

# La que no da error y muerde

```sql
SELECT CASE WHEN '' IS NULL THEN 'ES null' ELSE 'NO es null' END FROM dual;
```

<br>

| | SQLite | Oracle |
|---|---|---|
| `'' IS NULL` | falso | **verdadero** |
| `'' = ''` | verdadero | ni verdadero ni falso |

<br>

En Oracle **la cadena vacía es `NULL`**. No hay forma de guardar «un texto de cero caracteres» distinto de «no hay dato».

> Si tu aplicación distinguía las dos cosas, al migrar **perdiste esa distinción y nadie te avisó**. Es el error silencioso de siempre, con ropa nueva.

---

# La cicatriz del `* 1.0`

Desde la clase 5 vienen escribiendo esto:

```sql
ROUND(SUM(c.kg) * 1.0 / l.hectareas, 2)
```

En Oracle:

```sql
SUM(c.kg) / l.hectareas    -- 256.140350877192982456...
```

<br>

Da decimales solo. **`NUMBER` es un tipo de verdad**, no una afinidad.

> El `* 1.0` nunca fue una regla de SQL. Era una defensa contra la división entera de SQLite. Diez clases escribiendo un parche cuyo motivo era del motor, no del lenguaje.

---

# Lo que sí es SQL de verdad

Todo esto corre en Oracle sin tocar una letra:

<br>

```sql
WITH kg AS (SELECT lote_id, SUM(kg) AS total FROM ... GROUP BY lote_id)
SELECT f.nombre, l.codigo,
       RANK() OVER (PARTITION BY f.finca_id ORDER BY kg.total DESC) AS puesto,
       LAG(kg.total) OVER (ORDER BY kg.total)                       AS anterior
  FROM kg JOIN lotes l ON ... LEFT JOIN fincas f ON ...
```

<br>

> CTE, ventanas, `LAG`, `RANK`, `LEFT JOIN`, vistas, índices: **lo caro de aprender es lo que se transfiere.** Lo que se rompe es lo barato.

---

<!-- _class: lead -->

# Ahora sí: PL/SQL

## Lo que SQL solo no puede hacer

---

# ¿Qué le falta a SQL?

```sql
SELECT ...   -- decís QUÉ querés, no CÓMO
```

SQL no tiene:

- **variables** — no podés guardar un resultado para usarlo tres líneas después
- **`IF`** — no podés decidir si hacer algo o no
- **bucles** — no podés repetir con una condición de corte
- **manejo de errores** — si algo falla, se corta y listo

<br>

> PL/SQL es SQL **más** todo eso. Y lo que trae de bueno trae lo mismo de peligroso, que es de lo que va la segunda mitad de la clase.

---

# El bloque

```sql
DECLARE                       -- opcional: variables
  v_total NUMBER;
BEGIN                         -- obligatorio: el código
  SELECT COUNT(*) INTO v_total FROM lecturas;
  DBMS_OUTPUT.PUT_LINE('lecturas: ' || v_total);
EXCEPTION                     -- opcional: qué hacer si falla
  WHEN NO_DATA_FOUND THEN DBMS_OUTPUT.PUT_LINE('nada');
END;
/
```

<br>

| Detalle | Por qué importa |
|---|---|
| `INTO` | un `SELECT` suelto no existe en PL/SQL: hay que guardarlo |
| `/` sola en una línea | le dice al cliente «terminó el bloque, mandalo» |
| `DBMS_OUTPUT` | necesita `SET SERVEROUTPUT ON` o **no ves nada** |

---

# La media hora que pierde todo el mundo

```sql
BEGIN
  DBMS_OUTPUT.PUT_LINE('hola');
END;
/
```
```
PL/SQL procedure successfully completed.
```

**¿Y el «hola»?**

<br>

No lo imprimió: lo dejó en un buffer que nadie pidió leer.

```sql
SET SERVEROUTPUT ON
```

> Corrió bien, hizo lo que le pediste, y no ves el resultado. **Éxito silencioso**, otra vez. Live SQL lo trae prendido; SQL*Plus y SQLcl, no.

---

# `%TYPE`: la declaración que no envejece

```sql
DECLARE
  v_nombre VARCHAR2(60);          -- hoy anda
  v_nombre fincas.nombre%TYPE;    -- anda siempre
```

<br>

Si mañana alguien agranda `fincas.nombre` a `VARCHAR2(120)`:

- la primera versión revienta con `ORA-06502: character string buffer too small`
- la segunda se entera sola

<br>

> Y `%ROWTYPE` hace lo mismo con una fila entera: `v_fila fincas%ROWTYPE;`

---

# `SELECT ... INTO` quiere exactamente una fila

```sql
SELECT nombre INTO v_nombre FROM fincas WHERE finca_id = 99;
```
```
ORA-01403: no data found
```

```sql
SELECT nombre INTO v_nombre FROM fincas;      -- hay 3
```
```
ORA-01422: exact fetch returns more than requested number of rows
```

<br>

| Filas | Excepción |
|---|---|
| 0 | `NO_DATA_FOUND` |
| 1 | ✔ |
| 2 o más | `TOO_MANY_ROWS` |

> Las dos son **errores de verdad**: cortan el bloque. Eso es bueno.

---

# Bucles: el cursor FOR LOOP

La forma larga (declarar, abrir, hacer fetch, cerrar) casi nunca hace falta:

```sql
FOR r IN (SELECT sensor_id, tipo FROM sensores WHERE activo = 1) LOOP
  DBMS_OUTPUT.PUT_LINE(r.sensor_id || ': ' || r.tipo);
END LOOP;
```

<br>

Oracle declara `r` solo, abre el cursor, itera y lo cierra. **No hay que cerrar nada.**

> Es el 90 % de los bucles que van a escribir. Y también es el 90 % de los bucles que **no deberían haber escrito**. Siguiente lámina.

---

<!-- _class: lead -->

# El corazón del día

## Row by row is slow by slow

---

# Dos motores en el mismo servidor

Adentro de Oracle hay dos cosas distintas:

| | Ejecuta |
|---|---|
| **motor SQL** | `SELECT`, `INSERT`, `UPDATE`, `DELETE` |
| **motor PL/SQL** | `IF`, `LOOP`, variables, asignaciones |

<br>

Cada vez que tu bloque PL/SQL ejecuta una sentencia SQL, **hay que cambiar de motor**. Eso se llama *context switch* y no es gratis.

> Un bucle de 180 vueltas con un `INSERT` adentro no hace un `INSERT`: hace **180 viajes de ida y vuelta** entre dos motores.

---

# La misma tarea, dos veces

**Llenar `resumen_diario`: 6 sensores × 30 días = 180 filas.**

```sql
FOR s IN (SELECT sensor_id FROM sensores) LOOP
  FOR d IN (SELECT DISTINCT TRUNC(fecha_hora) dia FROM lecturas) LOOP
    INSERT INTO resumen_diario ...
    SELECT COUNT(*), MIN(valor), MAX(valor), AVG(valor) FROM lecturas
     WHERE sensor_id = s.sensor_id AND TRUNC(fecha_hora) = d.dia;
  END LOOP;
END LOOP;
```

```sql
INSERT INTO resumen_diario ...
SELECT sensor_id, TRUNC(fecha_hora), COUNT(*), MIN(valor), MAX(valor), AVG(valor)
  FROM lecturas GROUP BY sensor_id, TRUNC(fecha_hora);
```

> Las dos dan **exactamente** las mismas 180 filas. Con los mismos números.

---

# La cuenta

| | Bucle | Una sentencia |
|---|---|---|
| sentencias SQL ejecutadas | **180** | **1** |
| context switches | 180 | 1 |
| pasadas sobre `lecturas` | 180 | 1 |
| **filas leídas** | **180 × 8.640 = 1.555.200** | **8.640** |

<br>

**180 veces más trabajo, para el mismo resultado.**

> Y con un año entero de datos en vez de un mes, el bucle hace 12 veces más pasadas sobre una tabla 12 veces más grande: **144 veces peor**. La otra, 12.

---

# El plan no lo muestra

```
EXPLAIN PLAN FOR SELECT ... WHERE sensor_id = 1 AND TRUNC(fecha_hora) = ...
```
```
TABLE ACCESS FULL | LECTURAS
```
```
EXPLAIN PLAN FOR SELECT ... GROUP BY sensor_id, TRUNC(fecha_hora)
```
```
TABLE ACCESS FULL | LECTURAS
```

<br>

**Los dos planes son iguales.** Los dos leen la tabla entera. Ninguno miente.

> El plan te dice **cómo** se resuelve una ejecución. No te dice **cuántas veces** la vas a ejecutar. Eso lo pone tu bucle, y el optimizador no lo ve.

---

# La clase 9 y la clase 11 no se contradicen

<br>

| Pregunta | Quién la contesta |
|---|---|
| ¿esta consulta está bien resuelta? | **el plan** |
| ¿cuántas veces la estoy corriendo? | **el reloj**, y tu propio código |

<br>

> «El reloj es una anécdota» seguía valiendo: el reloj no te dice por qué. Lo que hoy se agrega es que **el plan tampoco alcanza solo**. Se miran los dos, y se cuenta.

---

# Y el `TRUNC` es el `DATE()` de la clase 9

```sql
WHERE TRUNC(fecha_hora) = DATE '2026-04-01'     -- el índice no sirve
WHERE fecha_hora >= DATE '2026-04-01'
  AND fecha_hora <  DATE '2026-04-02'           -- el índice sirve
```

<br>

Mismo problema, otro motor, otra función. Un índice ordenado por `fecha_hora` no sabe nada de `TRUNC(fecha_hora)`.

> Oracle tiene una salida que SQLite no: **índices sobre expresiones**.
> `CREATE INDEX ix ON lecturas (TRUNC(fecha_hora));`
> Existe, funciona, y sigue siendo mejor no necesitarlo.

---

<!-- _class: lead -->

# Excepciones

## El error que pediste que te ignoren

---

# Las que tienen nombre

```sql
EXCEPTION
  WHEN NO_DATA_FOUND    THEN ...   -- ORA-01403
  WHEN TOO_MANY_ROWS    THEN ...   -- ORA-01422
  WHEN DUP_VAL_ON_INDEX THEN ...   -- ORA-00001
  WHEN ZERO_DIVIDE      THEN ...   -- ORA-01476
```

Y las que no. La clave foránea y el `CHECK` **no tienen nombre**: hay que bautizarlas.

```sql
e_fk EXCEPTION;
PRAGMA EXCEPTION_INIT(e_fk, -2291);   -- ORA-02291
```

> Es más trabajo, y ese trabajo es exactamente lo que separa «atrapé el error que esperaba» de «atrapé todo lo que pase».

---

# La línea más cara de la industria

```sql
EXCEPTION
  WHEN OTHERS THEN NULL;
```

<br>

Traducido: **«pase lo que pase, no me avises».**

```sql
BEGIN
  cargar_labor(1,  'riego', DATE '2026-05-02', 'Marta Ruiz',  55);
  cargar_labor(99, 'riego', DATE '2026-05-03', 'Marta Ruiz',  60);
  cargar_labor(3,  'fert.', DATE '2026-05-04', 'Jorge Mina',  70);
  cargar_labor(2,  'poda',  DATE '2026-05-05', 'Jorge Mina', -10);
END;
```

**Cargaste 4. Entraron 2. No hubo ni un error.**

---

# Es la misma historia de siempre

| Clase | Qué pasó | Qué avisó |
|---|---|---|
| 8 | `CREATE VIEW IF NOT EXISTS` no reemplazó nada | nada |
| 9 | el `SEARCH` leía media tabla | nada |
| 10 | entraron cinco filas imposibles | nada |
| **11** | **dos `INSERT` fallaron** | **nada** |

<br>

> **Los errores que dan error son los baratos.** El curso entero se trata de los otros. Hoy tiene nombre de línea: `WHEN OTHERS THEN NULL`.

---

# Cómo se escribe bien

```sql
EXCEPTION
  WHEN e_fk_invalida THEN
    INSERT INTO bitacora (tabla, operacion, detalle)
    VALUES ('LABORES', 'ERROR', 'siembra inexistente: ' || SQLERRM);
    RAISE_APPLICATION_ERROR(-20001, 'La siembra no existe');

  WHEN OTHERS THEN
    INSERT INTO bitacora (tabla, operacion, detalle)
    VALUES ('LABORES', 'ERROR', SQLCODE || ' ' || SQLERRM);
    RAISE;                      -- y lo vuelve a levantar
```

<br>

> Tres cosas: **atrapar lo que esperás por separado**, **dejar rastro**, y **volver a levantarlo**. `WHEN OTHERS` sin `RAISE` (o sin `RAISE_APPLICATION_ERROR`) casi siempre es un bug.

---

# Procedimientos y funciones

```sql
CREATE OR REPLACE PROCEDURE cargar_labor (
  p_siembra_id NUMBER,                 -- IN por omisión
  p_costo      NUMBER,
  p_id_nuevo   OUT NUMBER              -- devuelve algo
) AS
BEGIN
  ...
END;
/
```

| | Devuelve | Se usa en |
|---|---|---|
| `PROCEDURE` | por parámetros `OUT` | una sentencia propia |
| `FUNCTION` | con `RETURN` | **adentro de un `SELECT`** |

> `CREATE OR REPLACE`: Oracle no tiene `IF NOT EXISTS`, pero sí tiene esto — que hace lo que uno esperaba que hiciera aquel.

---

# Triggers: casi igual, y una diferencia enorme

```sql
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
```

> `:NEW` y `:OLD` con dos puntos. `INSERTING` / `UPDATING` / `DELETING` para saber cuál fue.

---

# La deuda de la clase 10, cobrada

En la clase 10 escribimos:

> *«SQLite no tiene `CURRENT_USER`: el cuándo sale gratis, el quién no existe en el motor.»*

<br>

```sql
SELECT USER FROM dual;
```

<br>

Oracle **sí sabe quién es**. La bitácora que quedó coja hace tres días, hoy se completa sola con una palabra.

> Con la misma advertencia de entonces: sigue sin ver lo anterior al trigger, sigue sin sobrevivir a un `DROP TRIGGER`, y si dos personas comparten usuario, sabe **el usuario**, no la persona.

---

# Lo de hoy en una línea

**En SQL le pedís un resultado. En PL/SQL le dictás un procedimiento — y lo hace, incluidas las vueltas de más y el error que le dijiste que ignore.**

| Quiero | Uso |
|---|---|
| una fila en una variable | `SELECT ... INTO` + `%TYPE` |
| recorrer un resultado | cursor `FOR` loop |
| **procesar un conjunto** | **una sola sentencia SQL, sin bucle** |
| si de verdad hace falta el bucle | `BULK COLLECT` + `FORALL` |
| que un error no pase desapercibido | excepción con nombre + `RAISE` |
| saber quién | `USER` |

---

<!-- _class: lead -->

# A trabajar

## `ejercicio.md`

Cuatro sentencias que se rompen, dos cargas que dan lo mismo y tardan 180 veces distinto, y una bitácora que por fin sabe quién.

Antes de empezar: `datos/agrodb_oracle_clase11.sql` en **Run Script**
Tiene que dar **3, 6, 8, 10, 7, 19, 16, 6, 9, 8640, 0, 0**
