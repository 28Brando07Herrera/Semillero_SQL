# Ejercicio práctico 9 · Cien mil filas y un plan que dice SCAN
**Duración: 2 horas · Individual · sqliteonline.com (o tu SQLite local) · Entrega: un archivo `.sql`**

---

## La situación

Hasta ayer la base tenía 973 lecturas y todo era instantáneo. Hoy tiene **105.120** y hay consultas que se sienten.

El ejercicio 6 les preguntaba, hace tres días, qué iba a dejar de funcionar a esa escala. Hoy lo ven. Y la respuesta no es "comprar un servidor más grande": es que **SQLite no sabe dónde están las filas que le pedís**, así que las mira todas.

Hoy aprenden a preguntárselo, a arreglarlo, y a descubrir que la costumbre que traen de tres clases atrás es la que impide el arreglo.

## Antes de empezar

1. **Pestaña nueva** en sqliteonline.com → SQLite.
2. Pegá `datos/agrodb_clase9.sql` completo y ejecutalo. **Va a tardar unos segundos**: está generando cien mil filas. Deben salir **3, 6, 8, 10, 7, 19, 16, 6, 9, 973, 7, 105120**.
3. Trabajá en `Ejercicio9_Apellido_Nombre.sql`.

> **Hoy es el día para probar el entorno local.** La guía está en [`recursos/entorno-local-sqlite.md`](../../recursos/entorno-local-sqlite.md). Con `sqlite3` local tenés `.timer on`, que te dice cuánto tardó cada consulta. En el navegador se puede hacer todo el ejercicio igual, pero midiendo a ojo.

## La regla del día

> **El reloj es una anécdota. El plan es la evidencia.**
>
> El cronómetro cambia según tu máquina, tu navegador y qué más esté abierto. `EXPLAIN QUERY PLAN` devuelve lo mismo siempre. Toda afirmación sobre rendimiento que entregues hoy va acompañada del plan que la sostiene.

Y sigue vigente la de ayer: **una vista es una opinión con nombre**.

---

## Parte A · Mirar antes de tocar (20 min)

**A1.** Contá lo que hay. Esperado: **105.120** filas, **6** sensores, **17.520** por sensor.

```sql
SELECT COUNT(*) FROM lecturas_historico;
SELECT sensor_id, COUNT(*) FROM lecturas_historico GROUP BY sensor_id;
```

**A2 — los índices que ya existen.** Antes de crear ninguno, corré:

```sql
SELECT name, tbl_name FROM sqlite_master WHERE type = 'index';
```

Esperado: **5 filas**, todas con nombres que empiezan en `sqlite_autoindex_`.

En un comentario, tres líneas:
1. Nadie escribió nunca un `CREATE INDEX` en este curso. ¿De dónde salieron?
2. `sqlite_autoindex_lecturas_1` es de la tabla `lecturas`. **Ustedes lo crearon**, en el ejercicio 6, sin saberlo. ¿Con qué línea?
3. ¿Por qué un `UNIQUE` necesita un índice para funcionar?

**A3.** ¿Aparece `lecturas_historico` en esa lista? ¿Por qué no? *(Pista: `lectura_id INTEGER PRIMARY KEY` en SQLite es el `rowid`, y el `rowid` no crea un índice aparte.)*

---

## Parte B · Medir, indexar, volver a medir (30 min)

**B1 — la consulta lenta.** Es un tablero que pide, día por día, cuántas mediciones hubo en junio:

```sql
WITH RECURSIVE dia(n) AS (SELECT 0 UNION ALL SELECT n+1 FROM dia WHERE n < 29)
SELECT n + 1 AS dia_de_junio,
  (SELECT COUNT(*) FROM lecturas_historico l
    WHERE l.sensor_id = 1
      AND l.fecha_hora >= datetime('2026-06-01','+'||n||' days')
      AND l.fecha_hora <  datetime('2026-06-01','+'||(n+1)||' days')) AS n_lecturas
FROM dia;
```

Esperado: **30 filas**, todas con **48**.

Correla y anotá en un comentario **cuánto tardó** (con `.timer on` si estás en local, o "se sintió / no se sintió" si estás en el navegador).

**B2 — preguntarle a SQLite por qué.** Poné `EXPLAIN QUERY PLAN` adelante de la misma consulta.

La última línea del plan tiene que decir exactamente:

```
SCAN l
```

En un comentario: ¿qué significa `SCAN`? Y con 30 días y 105.120 filas, **¿cuántas filas está leyendo en total?**

**B3 — el índice.**

```sql
CREATE INDEX ix_hist_sensor_fecha
    ON lecturas_historico (sensor_id, fecha_hora);
```

**B4.** Volvé a correr B1 **sin cambiarle una letra**, y volvé a medir. Después volvé a correr el `EXPLAIN QUERY PLAN`.

La última línea ahora tiene que decir:

```
SEARCH l USING COVERING INDEX ix_hist_sensor_fecha (sensor_id=? AND fecha_hora>? AND fecha_hora<?)
```

En un comentario: las 30 filas y los 48, ¿cambiaron? Entonces, **¿qué cambió un índice exactamente?** Contestá con la palabra "resultado" adentro.

---

## Parte C · La costumbre de tres clases (35 min)

Esta es la parte del día.

**C1.** Escribí el promedio diario del sensor 1 en junio **como lo venís escribiendo desde la clase 6**:

```sql
SELECT DATE(fecha_hora) AS dia, COUNT(*) AS n, ROUND(AVG(valor),2) AS prom
FROM lecturas_historico
WHERE sensor_id = 1
  AND DATE(fecha_hora) BETWEEN '2026-06-01' AND '2026-06-30'
GROUP BY dia;
```

Esperado: **30 filas**, cada una con **n = 48** y **prom = 23.88**.

El resultado es correcto. El índice de B3 ya está creado. Ahora mirá el plan:

```
SEARCH lecturas_historico USING INDEX ix_hist_sensor_fecha (sensor_id=?)
USE TEMP B-TREE FOR GROUP BY
```

**C2.** Comparalo con el plan de B4, que decía `(sensor_id=? AND fecha_hora>? AND fecha_hora<?)`.

En un comentario:
1. ¿Qué parte de la condición usó el índice, y cuál no?
2. Entonces, ¿sobre cuántas filas del sensor 1 está trabajando de verdad? *(Pista: el sensor 1 tiene 17.520 lecturas en total y junio tiene 1.440.)*

**C3 — por qué.** El índice guarda la columna `fecha_hora`. La consulta pregunta por `DATE(fecha_hora)`.

En un comentario, con tus palabras: ¿por qué un índice ordenado por `fecha_hora` **no** sirve para buscar por `DATE(fecha_hora)`? *(No vale "porque SQLite es así". Pensá en el índice del final de un libro, ordenado alfabéticamente, y en alguien que te pide "todas las palabras que empiezan con la tercera letra de su nombre".)*

**C4 — el arreglo.** Reescribí C1 preguntando por la columna tal como está guardada, con un rango:

```sql
WHERE sensor_id = 1
  AND fecha_hora >= '2026-06-01'
  AND fecha_hora <  '2026-07-01'
```

Esperado: **las mismas 30 filas, los mismos 48, los mismos 23.88.** Y este plan:

```
SEARCH lecturas_historico USING INDEX ix_hist_sensor_fecha (sensor_id=? AND fecha_hora>? AND fecha_hora<?)
USE TEMP B-TREE FOR GROUP BY
```

**C5.** Fijate que usé `< '2026-07-01'` y no `<= '2026-06-30'`.

En un comentario: si escribo `fecha_hora <= '2026-06-30'`, ¿qué lecturas del 30 de junio me pierdo, y por qué? *(Pensá en qué texto se guardó exactamente.)*

**C6 — la honesta.** Medí C1 y C4 con el cronómetro. La diferencia en un mes es **chica**: son 17.520 filas contra 1.440, y las dos tardan poco.

En un comentario, tres líneas: si el reloj casi no lo muestra, **¿por qué habría que arreglarlo igual?** ¿Qué pasa con esta misma consulta cuando la tabla tenga diez años de datos en vez de uno?

**C7.** Buscá en tus entregas del ejercicio 6 o del 7 una consulta tuya que use `DATE(fecha_hora)` en el `WHERE`. Pegala en un comentario y escribí al lado cómo la escribirías hoy.

*(Si no encontrás ninguna, decilo y pegá una del enunciado de la clase 6.)*

---

## Parte D · Cuándo el índice no alcanza (25 min)

**D1 — el prefijo izquierdo.** Con `ix_hist_sensor_fecha (sensor_id, fecha_hora)` ya creado, corré:

```sql
EXPLAIN QUERY PLAN
SELECT COUNT(*) FROM lecturas_historico
WHERE fecha_hora >= '2026-06-01' AND fecha_hora < '2026-07-01';
```

Esperado:

```
SCAN lecturas_historico USING COVERING INDEX ix_hist_sensor_fecha
```

En un comentario:
1. Dice `SCAN`, no `SEARCH`. ¿Por qué no puede usar el índice para ir directo, si `fecha_hora` **está** en el índice?
2. Dice `USING COVERING INDEX`. Si igual va a recorrer todo, ¿para qué le sirve el índice acá?

**D2.** Creá el índice que sí sirve para esa consulta y comprobá que el plan pasa a `SEARCH`:

```sql
CREATE INDEX ix_hist_fecha ON lecturas_historico (fecha_hora);
```

En un comentario: ahora hay dos índices sobre la misma tabla. ¿Está mal? ¿Cuándo empezaría a estar mal?

**D3 — el `ORDER BY` gratis.** Tres planes de la misma consulta, en este orden exacto.

```sql
EXPLAIN QUERY PLAN
SELECT fecha_hora, valor FROM lecturas_historico
WHERE sensor_id = 1 ORDER BY fecha_hora LIMIT 10;
```

**Paso 1 — con los dos índices creados.** Esperado, una sola línea:

```
SEARCH lecturas_historico USING INDEX ix_hist_sensor_fecha (sensor_id=?)
```

**Paso 2 — sin ningún índice.** Borrá los dos y volvé a pedir el plan:

```sql
DROP INDEX ix_hist_sensor_fecha;
DROP INDEX ix_hist_fecha;
```
```
SCAN lecturas_historico
USE TEMP B-TREE FOR ORDER BY
```

Apareció una línea que no estaba. En un comentario: ¿qué está haciendo SQLite ahí, y **sobre cuántas filas**, si al final solo devuelve 10?

**Paso 3 — solo con el índice sobre `fecha_hora`.** Creá **únicamente** ese:

```sql
CREATE INDEX ix_hist_fecha ON lecturas_historico (fecha_hora);
```
```
SCAN lecturas_historico USING INDEX ix_hist_fecha
```

Mirá bien: dice `SCAN`, o sea que recorre todo… **y sin embargo la línea del `USE TEMP B-TREE` ya no está.**

En un comentario, dos líneas: si igual está recorriendo la tabla entera, ¿por qué dejó de ordenar? *(Pensá en qué orden recorre las filas cuando las recorre por un índice.)*

**Paso 4.** Volvé a crear el índice compuesto antes de seguir:

```sql
CREATE INDEX ix_hist_sensor_fecha ON lecturas_historico (sensor_id, fecha_hora);
```

**D4 — un `SEARCH` que no sirve de mucho.** Creá un índice sobre `valor` y pedí el plan de una consulta que devuelve más de la mitad de la tabla:

```sql
CREATE INDEX ix_hist_valor ON lecturas_historico (valor);
EXPLAIN QUERY PLAN SELECT COUNT(*) FROM lecturas_historico WHERE valor > 28;
SELECT COUNT(*) FROM lecturas_historico WHERE valor > 28;
```

Esperado: el plan dice `SEARCH ... USING COVERING INDEX ix_hist_valor (valor>?)`, y la consulta devuelve **59.495** filas de 105.120.

En un comentario, y esta es la más fina del día:
1. El plan dice `SEARCH`. Según la regla del día, eso es lo que queríamos ver. **¿Está esta consulta bien resuelta?**
2. ¿Cuántas entradas del índice tuvo que recorrer para contar 59.495 filas?
3. Entonces: ¿alcanza con mirar si el plan dice `SEARCH`? ¿Qué más hay que mirar?

**D5.** Borrá el índice de `valor` (`DROP INDEX ix_hist_valor`) y explicá en una línea por qué lo borrás.

---

## Parte E · Lo que cuesta, y cierre (10 min)

**E1.** Un índice se paga en tres monedas. Nombralas, y decí cuál es la más cara en una tabla de sensores que recibe mediciones cada 30 minutos, y por qué.

**E2.** Ayer aprendieron que una vista **no acelera nada**. Hoy indexaron la tabla que está abajo. En una frase: ¿quién hace el trabajo, la vista o el índice?

**E3.** Escribí las **tres preguntas** que te vas a hacer, en orden, la próxima vez que una consulta esté lenta. La primera no puede ser "creo un índice".

---

## Rúbrica (100 puntos)

| Criterio | Pts |
|---|---|
| Parte A: los índices que ya existían y de dónde salieron | 10 |
| Parte B1–B2: la consulta lenta medida y su plan `SCAN` leído | 15 |
| Parte B3–B4: el índice creado y el plan `SEARCH` comparado | 10 |
| **Parte C1–C4: la trampa del `DATE()` — el plan incompleto, el porqué y el arreglo** | **25** |
| Parte C5–C7: el `<` contra el `<=`, la escala, y la consulta propia reescrita | 10 |
| Parte D1–D2: el prefijo izquierdo y el `COVERING INDEX` | 10 |
| Parte D3: el `ORDER BY` gratis, con el plan de antes y el de después | 5 |
| **Parte D4: el `SEARCH` que no sirve de mucho** | **10** |
| Cierre con criterio | 5 |
| **Extra:** encontrá **otra** consulta lenta en esta base, mostrá su plan, indexala y mostrá el plan nuevo. Vale el doble si el índice **no** ayuda y explicás por qué | +5 |

El archivo debe correr **completo** de arriba abajo después de `datos/agrodb_clase9.sql`. Poné `DROP INDEX IF EXISTS ...;` antes de cada `CREATE INDEX` tuyo, o la segunda corrida te va a fallar.

**Toda afirmación sobre rendimiento sin el plan que la sostiene se descuenta**, aunque el número del cronómetro sea cierto. Hoy el plan es la prueba.
