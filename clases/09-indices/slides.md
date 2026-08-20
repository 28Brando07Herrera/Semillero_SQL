---
marp: true
paginate: true
theme: default
title: "Clase 9 · Índices: lo que cuesta encontrar algo"
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
footer: "Curso de SQL · AgroDB · Clase 9"
---

<!-- _class: lead -->

# Lo que cuesta encontrar algo

## Índices, planes de ejecución, y la consulta que escriben desde la clase 6

Clase 9 · 20 de agosto

---

# Ayer terminamos con una deuda

Slide 17 de la clase 8:

> *"Una vista **no acelera nada**. Cada consulta vuelve a correr los cuatro `JOIN`.
> Sobre 973 lecturas no se nota; sobre medio millón, sí."*

<br>

Y el ejercicio 6 preguntaba, hace tres días:

> *"Nombrá **una** cosa que va a dejar de funcionar bien a esa escala."*

<br>

**Hoy se cobran las dos.**

---

# Primero, la base tardó

Hasta ayer el script base se pegaba y aparecía el resultado. Hoy hubo que esperar.

```
lecturas              973
lecturas_historico    105.120
```

Un año entero, cada 30 minutos, seis sensores.
`365 × 48 × 6 = 105.120`

<br>

> Y `lecturas_historico` **no tiene ningún índice propio**. Eso no es un olvido: es el ejercicio de hoy.

---

# La consulta que ayer era gratis

Un tablero que muestra, día por día, cuántas mediciones hubo en junio:

```sql
WITH RECURSIVE dia(n) AS (SELECT 0 UNION ALL SELECT n+1 FROM dia WHERE n < 29)
SELECT n + 1 AS dia_de_junio,
  (SELECT COUNT(*) FROM lecturas_historico l
    WHERE l.sensor_id = 1
      AND l.fecha_hora >= datetime('2026-06-01','+'||n||' days')
      AND l.fecha_hora <  datetime('2026-06-01','+'||(n+1)||' days')) AS n_lecturas
FROM dia;
```

Treinta filas. Cuarenta y ocho mediciones cada una.

**Y se siente.** Sobre 973 filas esto era instantáneo.

---

# Por qué tarda

SQLite no sabe **dónde** están las filas del sensor 1 en junio.

Así que hace lo único que puede: **las mira todas**.

```
105.120 filas  ×  30 días  =  3.153.600 filas leídas
```

<br>

Y no lo esconde. Se lo podés preguntar:

```sql
EXPLAIN QUERY PLAN <tu consulta>;
```

---

# `EXPLAIN QUERY PLAN`: la herramienta del día

No ejecuta la consulta: te dice **cómo la pensaba ejecutar**.

```
SCAN l
```

Una palabra, y es la que importa.

| Palabra | Qué significa |
|---|---|
| **`SCAN`** | recorre la tabla entera, fila por fila |
| **`SEARCH`** | va directo, usando un índice |
| `USE TEMP B-TREE` | además tuvo que **ordenar a mano** |

<br>

> **El reloj es una anécdota; el plan es la evidencia.** El reloj cambia según la máquina, el navegador y quién más esté usando el CPU. El plan es el mismo siempre.

---

# Ya crearon un índice. Hace tres días.

```sql
SELECT name, tbl_name FROM sqlite_master WHERE type = 'index';
```
```
sqlite_autoindex_fincas_1        fincas
sqlite_autoindex_lotes_1         lotes
sqlite_autoindex_insumos_1       insumos
sqlite_autoindex_labor_insumo_1  labor_insumo
sqlite_autoindex_lecturas_1      lecturas      <- este
```

`sqlite_autoindex_lecturas_1` salió del `UNIQUE (sensor_id, fecha_hora)` que **ustedes escribieron en el ejercicio 6**.

> Todo `UNIQUE` y todo `PRIMARY KEY` crea un índice, porque para garantizar que algo no se repite hay que poder buscarlo rápido. Vienen usando índices desde la clase 3 sin llamarlos así.

---

# Qué es un índice

Una copia de **una o más columnas**, ordenada, con un puntero a la fila.

```
tabla (105.120 filas, en el orden en que entraron)
  ...  1 | 2026-06-14 03:30 | 22.5  ...

índice (sensor_id, fecha_hora)  -- ordenado
  1 | 2026-01-01 00:00 -> fila 1
  1 | 2026-01-01 00:30 -> fila 7
  ...
```

Es el índice del final de un libro. Sin él, para encontrar "fan-out" hay que leer el libro entero.

> Y como todo índice de libro: **ocupa páginas** y **hay que rehacerlo cada vez que cambia el texto**.

---

# `CREATE INDEX`

```sql
CREATE INDEX ix_hist_sensor_fecha
    ON lecturas_historico (sensor_id, fecha_hora);
```

Una línea. Sobre 105.120 filas tarda un momento — bastante menos que la consulta que arregla.

<br>

Ahora la misma consulta del tablero, sin cambiarle **una sola letra**:

```
antes:  SCAN l
ahora:  SEARCH l USING COVERING INDEX ix_hist_sensor_fecha
        (sensor_id=? AND fecha_hora>? AND fecha_hora<?)
```

**Más de dos mil veces más rápido.** Mismo SQL, mismas 30 filas, mismos 48 por día.

---

<!-- _class: lead -->

# Y ahora la mala noticia

## El índice está bien. La consulta, no.

---

# La consulta que escriben desde la clase 6

*"El promedio diario del sensor 1 en junio."* Así la vienen escribiendo:

```sql
SELECT DATE(fecha_hora) AS dia, COUNT(*) AS n, ROUND(AVG(valor),2) AS prom
FROM lecturas_historico
WHERE sensor_id = 1
  AND DATE(fecha_hora) BETWEEN '2026-06-01' AND '2026-06-30'
GROUP BY dia;
```

Devuelve las 30 filas correctas. El índice ya está creado.

**Y el plan dice:**

```
SEARCH lecturas_historico USING INDEX ix_hist_sensor_fecha (sensor_id=?)
```

---

# Falta media condición

```
(sensor_id=?)                                   <- lo que usó
(sensor_id=? AND fecha_hora>? AND fecha_hora<?) <- lo que podría haber usado
```

El índice le sirvió para el **sensor**. Para la **fecha**, no.

<br>

Porque el índice guarda `fecha_hora`. Y la consulta no pregunta por `fecha_hora`: pregunta por **`DATE(fecha_hora)`**, que es otra cosa.

> Un índice ordena **la columna**, no **una función de la columna**. En cuanto envolvés la columna en `DATE()`, `UPPER()`, `SUBSTR()` o lo que sea, el orden del índice deja de servir y SQLite tiene que abrir fila por fila para calcular la función.

---

# El arreglo: preguntar por la columna

```sql
WHERE sensor_id = 1
  AND fecha_hora >= '2026-06-01'
  AND fecha_hora <  '2026-07-01'
```
```
SEARCH ... (sensor_id=? AND fecha_hora>? AND fecha_hora<?)
```

**Las mismas 30 filas, los mismos promedios.** Otro plan.

| | |
|---|---|
| `DATE(fecha_hora) = '2026-06-01'` | el índice no puede |
| `fecha_hora >= '2026-06-01' AND fecha_hora < '2026-06-02'` | el índice sí |

> Funciona porque el formato es ISO-8601: ordenado como texto queda ordenado como fecha. Es lo mismo que hacía andar el `ORDER BY fecha_hora` de la clase 7.

---

# Ojo con el reloj

En junio esa diferencia se ve **apenas** en el cronómetro: son 17.520 filas contra 1.440.

<br>

| | 1 mes | 1 año | 10 años |
|---|---|---|---|
| con `DATE()` | apenas | se nota | inusable |
| con rango | instantáneo | instantáneo | instantáneo |

<br>

> Por eso el plan es la evidencia. **En la escala de hoy el error casi no se siente, y aun así ya está.** Cuando se sienta va a ser tarde y la base va a tener millones de filas.

---

# El orden de las columnas importa

`ix_hist_sensor_fecha (sensor_id, fecha_hora)` sirve para:

```sql
WHERE sensor_id = 1                          -- si
WHERE sensor_id = 1 AND fecha_hora > '...'   -- si
```

Y **no** sirve para:

```sql
WHERE fecha_hora > '2026-06-01'              -- SCAN
```

<br>

Es la guía telefónica ordenada por **apellido, nombre**: buscar "todos los Pérez" es directo; buscar "todos los que se llaman Juan" es leerla entera.

> **Regla del prefijo izquierdo:** un índice compuesto sirve desde la primera columna hacia la derecha, nunca desde el medio.

---

# `COVERING INDEX`: un scan que sigue siendo un scan

```
SCAN lecturas_historico USING COVERING INDEX ix_hist_sensor_fecha
```

Dice `SCAN`, así que **recorre todo**. Pero recorre el **índice** y no la tabla.

Es más rápido —el índice es más chico y no tiene el resto de las columnas— pero sigue siendo lineal.

<br>

| Lo que querés ver | Lo que no |
|---|---|
| `SEARCH ... USING INDEX` | `SCAN tabla` |
| | `SCAN ... USING COVERING INDEX` |

> "Covering" significa que el índice tenía **todas** las columnas que la consulta pedía, así que ni se molestó en ir a la tabla.

---

# Un `ORDER BY` gratis

```sql
SELECT fecha_hora, valor FROM lecturas_historico
WHERE sensor_id = 1 ORDER BY fecha_hora LIMIT 10;
```

```
sin índice:  SCAN lecturas_historico
             USE TEMP B-TREE FOR ORDER BY     <- ordenó 17.520 filas
con índice:  SEARCH ... USING INDEX (sensor_id=?)
```

**El `USE TEMP B-TREE` desapareció.**

> El índice ya está ordenado por `fecha_hora`. No hay nada que ordenar: se lee de corrido. Un índice no solo sirve para el `WHERE`, también para el `ORDER BY` y para el `GROUP BY`.

---

# Lo que cuesta

Un índice no es gratis. Se paga en tres monedas:

| Moneda | Cuánto |
|---|---|
| **Espacio** | otra copia de esas columnas, ordenada |
| **Escrituras** | cada `INSERT`, `UPDATE` y `DELETE` tiene que actualizarlo también |
| **Mantenimiento** | alguien tiene que saber por qué está y si todavía sirve |

<br>

En una tabla de sensores que recibe mediciones todo el día, **la segunda moneda es la cara**.

> Un índice de más no rompe nada y no se nota. Diez índices de más en la tabla que más escribe, sí.

---

# Cuándo un índice no sirve para nada

| Situación | Por qué |
|---|---|
| La tabla es chica | recorrer 973 filas ya es instantáneo |
| La columna tiene pocos valores distintos | `activo` es 0 o 1: el índice apunta a media tabla |
| La consulta devuelve casi todo | si vas a leer el 80 %, escanear es más barato |
| La columna va envuelta en una función | `DATE(fecha_hora)`, `UPPER(nombre)` |
| `LIKE '%algo'` | el comodín al principio mata el orden |

<br>

> **No se indexa "por las dudas".** Se indexa una consulta concreta que está lenta, y se comprueba con el plan que ahora dice `SEARCH`.

---

# Lo de hoy en una línea

**Un índice cambia el plan, no el resultado — y solo si la consulta pregunta por la columna tal como está guardada.**

| Quiero | Hago |
|---|---|
| saber por qué tarda | `EXPLAIN QUERY PLAN` |
| ver los índices que hay | `SELECT name FROM sqlite_master WHERE type='index'` |
| crear uno | `CREATE INDEX ix ON tabla(col1, col2)` |
| filtrar por fecha | rango `>=` / `<`, **nunca** `DATE(col) =` |
| que sirva | poner primero la columna del `=` |
| borrarlo | `DROP INDEX ix` |

---

<!-- _class: lead -->

# A trabajar

## `ejercicio.md`

Cien mil filas, un plan que dice `SCAN`, y una costumbre de tres clases que hay que romper.

Antes de empezar: `datos/agrodb_clase9.sql`
Tiene que dar **3, 6, 8, 10, 7, 19, 16, 6, 9, 973, 7, 105120**
