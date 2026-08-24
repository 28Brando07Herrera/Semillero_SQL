# Ejercicio práctico 11 · Fila por fila es lento por lento
**Duración: 2 horas · Individual · [Oracle Live SQL](https://livesql.oracle.com) (o tu Oracle local) · Entrega: un archivo `.sql`**

---

## La situación

La finca compró Oracle. No les preguntaron.

El modelo es el mismo, los datos son los mismos, y **la mitad del SQL que escribieron en diez clases no corre**. La otra mitad corre igual que siempre. Hoy averiguan cuál es cuál, y de paso aprenden a hacer algo que en SQLite no se podía: escribir un procedimiento.

Y hay una deuda vieja. En la clase 10 escribieron una bitácora que no podía contestar **quién**, porque SQLite no lo sabe. Oracle sí lo sabe. Hoy se cobra esa deuda.

## Antes de empezar

1. Entrá a **<https://livesql.oracle.com>** y creá una cuenta gratuita (o abrí tu Oracle local — [guía](../../recursos/entorno-local-oracle.md)).
2. **SQL Worksheet** → pegá `datos/agrodb_oracle_clase11.sql` completo → botón **Run Script** (el de la hoja, **no** el de "Run", que ejecuta una sola sentencia).
3. Deben salir: **3, 6, 8, 10, 7, 19, 16, 6, 9, 8640, 0, 0**.
4. Trabajá en `Ejercicio11_Apellido_Nombre.sql`.

> **Si estás en local:** poné `SET SERVEROUTPUT ON` una vez al principio de la sesión, o no vas a ver **nada** de lo que imprimas con `DBMS_OUTPUT`. En Live SQL ya viene prendido. Es la media hora que pierde todo el mundo la primera vez.

> **Para medir** (parte C) se usa `DBMS_UTILITY.GET_TIME`, que devuelve centésimas de segundo. Si tu instalación no te deja usarlo, reemplazalo por dos `SYSTIMESTAMP` y restalos:
> `v_ini := SYSTIMESTAMP;` … `DBMS_OUTPUT.PUT_LINE(TO_CHAR(SYSTIMESTAMP - v_ini));` con `v_ini TIMESTAMP`.

## La regla del día

> **En SQL le pedís un resultado. En PL/SQL le dictás un procedimiento.**
>
> Y todo lo que le dictás, lo hace: incluidas las diez mil vueltas que no hacían falta y el error que le pediste que ignore.

Y una que se hereda de la clase 9 con otro nombre: **el plan sigue siendo la evidencia.** Lo que cambia hoy es que el reloj también, porque hay una diferencia que el plan solo no muestra: cuántas veces se ejecuta.

---

## Parte A · Lo que se rompe al cruzar la calle (20 min)

**A1.** Corré esto y anotá qué pasa con cada una. **Se rompen cuatro de las cinco.**

```sql
SELECT 1;
SELECT COUNT(*) FROM lecturas LIMIT 5;
DROP TABLE IF EXISTS basura;
SELECT DATE(fecha_hora) FROM lecturas WHERE ROWNUM = 1;
SELECT sensor_id, COUNT(*) FROM lecturas GROUP BY sensor_id;
```

En un comentario, para cada una que falló: **el mensaje de error tal cual**, y la versión que sí corre en Oracle. La quinta corre igual que en SQLite: decilo también, porque es la mitad de la lección.

**A2 — la cadena vacía.** Ejecutá:

```sql
SELECT CASE WHEN '' IS NULL THEN 'la vacia ES null' ELSE 'la vacia NO es null' END AS resultado
  FROM dual;
```

En SQLite eso devuelve `NO es null`. En Oracle devuelve lo contrario. En un comentario: si tuvieras una columna `observacion` y quisieras distinguir *«no anotó nada»* de *«anotó explícitamente que no hay nada»*, ¿podrías hacerlo en Oracle? ¿Y qué tendrías que hacer en su lugar?

**A3 — la cicatriz del `* 1.0`.** Desde la clase 5 vienen escribiendo `* 1.0` para que la división no se coma los decimales. Corré esto **sin** el `* 1.0`:

```sql
SELECT SUM(c.kg) AS kg, SUM(c.kg) / l.hectareas AS kg_ha
  FROM cosechas c
  JOIN siembras s ON s.siembra_id = c.siembra_id
  JOIN lotes    l ON l.lote_id    = s.lote_id
 WHERE l.lote_id = 1
 GROUP BY l.hectareas;
```

Esperado: **7300** y **256.14…** (el mismo 256.14 del ejercicio 8).

En un comentario, dos líneas: ¿por qué acá no hace falta el `* 1.0`? ¿El `* 1.0` era una regla de SQL o una defensa contra algo particular de SQLite?

**A4.** `TRUNC(fecha_hora)` es el `DATE(fecha_hora)` de Oracle. Comprobalo:

```sql
SELECT TRUNC(fecha_hora) AS dia, COUNT(*) AS n
  FROM lecturas
 WHERE sensor_id = 1
 GROUP BY TRUNC(fecha_hora)
 ORDER BY dia
 FETCH FIRST 3 ROWS ONLY;
```

Esperado: **3 filas**, los días 1, 2 y 3 de abril, **48** cada uno.

En un comentario: en el ejercicio 9 aprendieron que `DATE(fecha_hora)` en el `WHERE` anula el índice. ¿Vale lo mismo para `TRUNC(fecha_hora)` en Oracle? Escribí tu hipótesis ahora; en la parte C la comprobás.

---

## Parte B · El primer bloque (25 min)

**B1 — anatomía.** Ejecutá este bloque tal cual. Ojo con la barra `/` sola al final: es la que le dice al cliente «acá termina el bloque, mandalo».

```sql
DECLARE
  v_total NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_total FROM lecturas;
  DBMS_OUTPUT.PUT_LINE('lecturas: ' || v_total);
END;
/
```

Esperado: `lecturas: 8640`.

En un comentario, tres líneas: ¿qué hace `INTO`? ¿Por qué un `SELECT` suelto no sirve adentro de PL/SQL? ¿Y qué pasaría si le sacás la `/` del final?

**B2 — `%TYPE`, y por qué importa.** Escribí un bloque que, para el sensor 1:

- declare `v_tipo` como `sensores.tipo%TYPE` y `v_n` como `NUMBER`;
- traiga el tipo del sensor y la cantidad de lecturas;
- imprima `sensor 1 (temperatura): 1440 lecturas`.

En un comentario: `sensores.tipo` hoy es `VARCHAR2(20)`. Si mañana alguien lo agranda a `VARCHAR2(40)`, ¿qué pasa con tu bloque si usaste `%TYPE`? ¿Y si hubieras escrito `VARCHAR2(20)` a mano?

**B3 — la excepción que te van a hacer conocer a las malas.** Ejecutá:

```sql
DECLARE
  v_nombre fincas.nombre%TYPE;
BEGIN
  SELECT nombre INTO v_nombre FROM fincas WHERE finca_id = 99;
  DBMS_OUTPUT.PUT_LINE(v_nombre);
END;
/
```

Pegá el error como comentario. Después hacé lo mismo, pero cambiando el `WHERE` por uno que devuelva **tres** filas. Pegá ese error también.

En un comentario, dos líneas: `SELECT ... INTO` exige **exactamente una fila**. ¿Qué pasa con cero? ¿Y con dos o más? Nombrá las dos excepciones.

**B4 — atajarlas.** Reescribí B3 con un bloque `EXCEPTION` que atrape `NO_DATA_FOUND` e imprima `finca 99: no existe` en vez de explotar.

Esperado: el bloque **termina bien** y muestra ese mensaje.

**B5.** En un comentario: en la clase 8, `CREATE VIEW IF NOT EXISTS` no daba error y tampoco hacía lo que vos querías. ¿En qué se parece eso a lo que acabás de escribir en B4? ¿Y en qué se diferencia?

---

## Parte C · Fila por fila es lento por lento (35 min)

Esta es la parte del día.

Hay que llenar `resumen_diario`: una fila por sensor y por día, con el conteo, el mínimo, el máximo y el promedio. **Seis sensores por treinta días de abril: 180 filas.**

Se puede escribir de dos maneras. Las dos dan exactamente el mismo resultado.

**C1 — el bucle que parece razonable.** Ejecutalo y anotá el tiempo que imprime:

```sql
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
```

```sql
SELECT COUNT(*) FROM resumen_diario;                      -- esperado: 180
SELECT * FROM resumen_diario WHERE sensor_id = 1
   AND dia = DATE '2026-04-01';                           -- esperado: 48 | 18 | 28 | 22.59
```

**C2 — la misma tarea, una sentencia.** Ejecutalo y anotá el tiempo:

```sql
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
```

**Verificá que dan lo mismo**, no que se parecen:

```sql
SELECT COUNT(*) FROM resumen_diario;                      -- 180 otra vez
SELECT * FROM resumen_diario WHERE sensor_id = 1
   AND dia = DATE '2026-04-01';                           -- 48 | 18 | 28 | 22.59, identico
```

**C3 — la cuenta.** En un comentario, contestá con números, no con adjetivos:

1. ¿Cuántas veces se ejecutó un `INSERT` en C1? ¿Y en C2?
2. Cada `INSERT` de C1 lleva adentro un `SELECT` sobre `lecturas` con `TRUNC(fecha_hora)` en el `WHERE`. **¿Cuántas filas de `lecturas` lee C1 en total?** (Pista: la tabla tiene 8.640 y no hay índice que sirva para `TRUNC`.)
3. ¿Cuántas lee C2?
4. Escribí la razón entre las dos.

**C4 — el porqué, que no es «el bucle es lento».** Un bloque PL/SQL corre en el motor de PL/SQL. Un `SELECT` o un `INSERT` corre en el motor de SQL. **Son dos motores distintos adentro del mismo servidor**, y pasar de uno a otro cuesta: eso se llama *context switch*.

En un comentario, tres líneas: ¿cuántos context switches hubo en C1 y cuántos en C2? Si el bucle de C1 no tuviera SQL adentro (si solo sumara números en memoria), ¿seguiría siendo lento? Entonces, ¿el problema es el `LOOP` o lo que pusiste adentro del `LOOP`?

**C5 — el plan, que sigue siendo la evidencia.** Pedí el plan del `SELECT` que está adentro del bucle de C1 y el del `SELECT` de C2:

```sql
EXPLAIN PLAN FOR
SELECT COUNT(*), MIN(valor), MAX(valor), AVG(valor)
  FROM lecturas WHERE sensor_id = 1 AND TRUNC(fecha_hora) = DATE '2026-04-01';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

EXPLAIN PLAN FOR
SELECT sensor_id, TRUNC(fecha_hora), COUNT(*), MIN(valor), MAX(valor), AVG(valor)
  FROM lecturas GROUP BY sensor_id, TRUNC(fecha_hora);
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
```

En un comentario: los dos planes dicen `TABLE ACCESS FULL`. **Los dos leen la tabla entera.** Entonces, mirando solo el plan, parecen igual de caros. ¿Qué información **no** está en el plan y explica toda la diferencia? Contestá con la palabra "veces" adentro.

**C6.** En la clase 9 la regla era «el reloj es una anécdota, el plan es la evidencia». Hoy midieron con el reloj y el plan no alcanzó.

En un comentario, dos líneas: ¿se contradicen las dos clases? ¿O el plan contesta una pregunta y el reloj otra? Decí cuál contesta cada uno.

---

## Parte D · El error que pediste que te ignoren (25 min)

**D1 — el procedimiento sospechoso.** Creá esto tal cual, con su `WHEN OTHERS THEN NULL` y todo:

```sql
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
  WHEN OTHERS THEN NULL;      -- "para que no moleste"
END;
/
```

**D2 — el lote de la mañana.** Contá las labores, cargá cuatro, volvé a contar:

```sql
SELECT COUNT(*) FROM labores;                                    -- esperado: 19

BEGIN
  cargar_labor(1,  'riego',         DATE '2026-05-02', 'Marta Ruiz',  55);
  cargar_labor(99, 'riego',         DATE '2026-05-03', 'Marta Ruiz',  60);
  cargar_labor(3,  'fertilizacion', DATE '2026-05-04', 'Jorge Mina',  70);
  cargar_labor(2,  'poda',          DATE '2026-05-05', 'Jorge Mina', -10);
  COMMIT;
END;
/

SELECT COUNT(*) FROM labores;
```

Cargaste **cuatro**. Anotá cuántas entraron.

En un comentario, tres líneas: ¿cuántas se perdieron? ¿Cuál fue el error de cada una que se perdió? ¿**Cómo te enteraste**, y cómo te habrías enterado si no hubieras contado antes y después?

*(Pista: la siembra 99 no existe, y hay un `CHECK` sobre `costo_mano_obra`.)*

**D3 — el diagnóstico.** `WHEN OTHERS THEN NULL` no es «manejar el error». Es taparlo.

En un comentario: en la clase 8, `CREATE VIEW IF NOT EXISTS` corría sin error y no hacía nada. En la clase 10, una fila mala entraba sin error. Hoy, un `INSERT` falla sin error. **Escribí en una frase qué tienen en común las tres**, y por qué esa frase es el resumen del curso entero.

**D4 — el arreglo.** Oracle trae nombre propio para un puñado de errores (`NO_DATA_FOUND`, `TOO_MANY_ROWS`, `DUP_VAL_ON_INDEX`…), pero **no** para los dos que acabás de provocar. La clave foránea es `ORA-02291` y el `CHECK` es `ORA-02290`, y a los dos hay que bautizarlos vos:

```sql
  e_fk_invalida  EXCEPTION;
  e_check_roto   EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_fk_invalida, -2291);
  PRAGMA EXCEPTION_INIT(e_check_roto,  -2290);
```

Reescribí `cargar_labor` para que:

- atrape esas dos **por separado**, cada una con su mensaje en castellano;
- deje `WHEN OTHERS` **solo al final**, y que ese sí use `SQLCODE` y `SQLERRM` en vez de tragarse el error;
- **escriba lo que pasó** en `bitacora` (tabla `'LABORES'`, operación `'ERROR'`, el detalle con `SQLERRM`);
- y **vuelva a levantar el error** con `RAISE_APPLICATION_ERROR(-20001, ...)`, para que el que la llamó se entere.

> **Cuidado con el orden:** si el `INSERT` a `bitacora` está en el mismo `EXCEPTION` que después hace `RAISE_APPLICATION_ERROR`, el `ROLLBACK` del que te llamó se puede llevar puesta también la fila de la bitácora. Probalo, mirá qué pasa, y anotalo. *(La solución de verdad se llama `PRAGMA AUTONOMOUS_TRANSACTION`; para hoy alcanza con que notes el problema.)*

Volvé a correr el lote de D2 y anotá qué pasa ahora. Esperado: **el bloque se corta en la segunda**, y `bitacora` tiene la fila del error.

En un comentario, dos líneas: ahora el lote se corta a la mitad y las dos últimas no se cargan. ¿Es eso peor que antes? ¿Por qué sí o por qué no?

**D5 — la regla.** Escribí, en un comentario, cuándo `WHEN OTHERS` está bien puesto. Tiene que haber una condición que empiece con «siempre que…».

---

## Parte E · El QUIÉN que SQLite no podía dar (15 min)

**E1.** En la clase 10 construyeron una bitácora de cosechas. Tenía el *cuándo*, el *qué* y el *cuánto*. No tenía el **quién**, porque SQLite no sabe quién está conectado.

Comprobá que Oracle sí:

```sql
SELECT USER AS quien, SYSTIMESTAMP AS cuando FROM dual;
```

**E2.** Escribí el trigger que la clase 10 no pudo escribir:

```sql
CREATE OR REPLACE TRIGGER trg_cosechas_bitacora
AFTER INSERT OR UPDATE OR DELETE ON cosechas
FOR EACH ROW
BEGIN
  ...
END;
/
```

Tiene que registrar en `bitacora` la operación (`'INSERT'`, `'UPDATE'`, `'DELETE'`), la clave de la fila, y un detalle con los kilos. Usá `INSERTING`, `UPDATING`, `DELETING` para saber cuál de las tres fue, y `:NEW` / `:OLD` para los valores.

> Ojo: en un `DELETE`, `:NEW` no existe. En un `INSERT`, `:OLD` no existe. Si mezclás los dos sin preguntar, tu trigger va a escribir `NULL` en la mitad de las filas y nadie te va a avisar.

**E3.** Probalo, y contestá la pregunta de la clase 10:

```sql
INSERT INTO cosechas VALUES (10, 6, DATE '2026-05-10', 750, 'segunda', 'mercado local');
UPDATE cosechas SET kg = 800 WHERE cosecha_id = 10;
DELETE FROM cosechas WHERE cosecha_id = 10;
COMMIT;

SELECT operacion, clave, detalle, usuario, cuando FROM bitacora ORDER BY bitacora_id;
```

Esperado: **3 filas**, una por operación, las tres con tu usuario.

**E4.** En un comentario, tres líneas: ahora la bitácora sabe *quién*. ¿Significa eso que ya se puede auditar de verdad? ¿Qué pasa si dos personas comparten el mismo usuario de base? ¿Y qué pasa si alguien hace `DROP TRIGGER trg_cosechas_bitacora`?

*(La respuesta de la clase 10 sigue valiendo: una bitácora es una facilidad, no una garantía. Lo que cambió hoy es cuánta facilidad.)*

---

## Parte F · Cierre (10 min, comentarios en el archivo)

1. De todo lo que escribieron en diez clases de SQLite, **¿qué porcentaje corrió sin cambios en Oracle?** No hace falta que sea exacto: da un número y justificalo con dos ejemplos, uno de cada lado.
2. En **una frase**: ¿cuándo vale la pena escribir PL/SQL en vez de una sentencia SQL sola?
3. `WHEN OTHERS THEN NULL` sigue estando en producción en miles de sistemas. En dos líneas: **¿por qué lo escribe la gente**, si es tan obviamente malo? Contestá con honestidad, no con moral.

---

## Rúbrica (100 puntos)

| Criterio | Pts |
|---|---|
| Parte A: las cuatro que se rompen, con su error transcripto y su versión Oracle | 15 |
| Parte B: el bloque, `%TYPE`, y las dos excepciones provocadas a propósito | 15 |
| **Parte C: las dos cargas escritas, medidas, verificadas idénticas y explicadas con números** | **30** |
| Parte D: el lote que pierde filas en silencio, y `cargar_labor` arreglada con bitácora y `RAISE_APPLICATION_ERROR` | 20 |
| Parte E: el trigger con `:NEW` / `:OLD`, `USER`, y las tres filas de bitácora | 15 |
| Preguntas de cierre con criterio | 5 |
| **Extra:** reescribí el bucle de C1 con `BULK COLLECT` + `FORALL`, medilo, y explicá por qué queda entre C1 y C2 | +5 |

Los criterios suman **100** exactos. *(Sí, esta línea está acá porque la rúbrica del ejercicio 8 sumaba 105. Ahora se verifica antes de publicar.)*

El archivo debe correr **completo** de arriba abajo después de `datos/agrodb_oracle_clase11.sql`. Usá `CREATE OR REPLACE` en procedimientos y triggers — Oracle sí lo tiene, y evita el problema del `DROP ... IF EXISTS` que no existe.

**Toda medición de tiempo sin la cuenta de filas que la explica se descuenta.** El reloj de tu máquina no es el de la mía; el número de filas leídas sí es el mismo para los dos.
