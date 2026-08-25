---
marp: true
paginate: true
theme: default
title: "Clase 7 · Funciones de ventana: mirar sin agrupar"
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
footer: "Curso de SQL · AgroDB · Clase 7"
---

<!-- _class: lead -->

# Mirar sin agrupar

## Funciones de ventana, y el podio que nadie revisó

Clase 7 · 18 de agosto

---

# La pregunta que `GROUP BY` no sabe contestar

*"Dame cada lote con sus kilos **y al lado** cuánto pesa eso sobre el total de su finca."*

<br>

Con `GROUP BY` podés tener **una cosa o la otra**:

- agrupás por lote → perdés el total de la finca
- agrupás por finca → perdés el lote

**El total y el detalle no caben en la misma consulta.** Hasta hoy.

---

# Por qué no caben

```sql
SELECT f.nombre, lo.codigo, SUM(c.kg)
FROM cosechas c ... GROUP BY f.nombre, lo.codigo;
```

`GROUP BY` **colapsa**: mete N filas adentro de una y devuelve una sola.

```
9 filas de cosecha  ─────GROUP BY─────>  3 filas de finca
```

Lo que entró ya no se puede mirar. Es un embudo de una sola dirección.

> Una función de ventana hace la cuenta **sin colapsar nada**. Las filas siguen ahí, y cada una recibe además el resultado del grupo al que pertenece.

---

# La misma pregunta, resuelta

```sql
SELECT f.nombre AS finca, lo.codigo AS lote, SUM(c.kg) AS kg,
       SUM(SUM(c.kg)) OVER (PARTITION BY f.nombre) AS kg_finca,
       ROUND(100.0 * SUM(c.kg)
             / SUM(SUM(c.kg)) OVER (PARTITION BY f.nombre), 1) AS pct
FROM cosechas c ...
GROUP BY f.nombre, lo.codigo;
```
```
Hacienda Santa Rosa  L-01  7300  14200  51.4
Hacienda Santa Rosa  L-02  5400  14200  38.0
Hacienda Santa Rosa  L-03  1500  14200  10.6
```

El detalle **y** el total, en la misma fila. La columna `pct` no se podía escribir hasta hoy.

---

# La anatomía

```sql
FUNCION() OVER (PARTITION BY ... ORDER BY ...)
   │              │                 │
   │              │                 └─ en qué orden mira dentro del grupo
   │              └─ cómo parte las filas en grupos
   └─ qué calcula
```

<br>

| Se parece a | Pero |
|---|---|
| `PARTITION BY` ≈ `GROUP BY` | **no colapsa** las filas |
| `ORDER BY` de adentro | ordena **el cálculo**, no el resultado |

`OVER ()` vacío = una sola ventana con toda la tabla adentro.

---

# Ranking dentro de cada grupo

```sql
SELECT f.nombre AS finca, lo.codigo AS lote,
       ROUND(SUM(c.kg) * 1.0 / lo.hectareas, 2) AS kg_ha,
       RANK() OVER (PARTITION BY f.nombre
                    ORDER BY SUM(c.kg) * 1.0 / lo.hectareas DESC) AS puesto
FROM cosechas c ... GROUP BY f.nombre, lo.codigo, lo.hectareas;
```
```
Agricola La Union     A-1   38.18   1
Finca El Guayabo      L-02  529.73  1
Finca El Guayabo      L-01  202.27  2
Hacienda Santa Rosa   L-01  256.14  1
Hacienda Santa Rosa   L-02  174.19  2
Hacienda Santa Rosa   L-03  77.92   3
```

**El puesto vuelve a empezar en cada finca.** Eso lo hace `PARTITION BY`.

---

# El `* 1.0` no es decoración

```sql
SUM(c.kg) / lo.hectareas        -- 4450 / 22   -> 202
SUM(c.kg) * 1.0 / lo.hectareas  -- 4450 / 22.0 -> 202.27
```

`lotes.hectareas` tiene **22**, **31** y **55** guardados como enteros.

Entero dividido entero da **entero**, y SQLite no avisa.

> Es la misma trampa de la clase 5. Hoy es peor: si el ranking se arma sobre un número truncado, **el orden del podio puede cambiar** y el error queda escondido adentro de un puesto.

---

<!-- _class: lead -->

# Y ahora el podio

## Primer puesto: 20 de abril, 27.33 °C

---

# El día más caluroso de abril

```sql
WITH dia AS (
  SELECT DATE(fecha_hora) AS d, COUNT(*) AS n, ROUND(AVG(valor),2) AS prom
  FROM lecturas WHERE sensor_id = 1 GROUP BY d)
SELECT d, n, prom, RANK() OVER (ORDER BY prom DESC) AS puesto
FROM dia ORDER BY puesto;
```
```
2026-04-20   6   27.33   1      <- el campeón
2026-04-05   8   25.63   2
2026-04-10   8   25.63   2
...
2026-04-19   7   24.86   7
```

**Miren la columna `n`.**

---

# El campeón tiene seis lecturas

El 20 de abril el sensor 1 midió **6 veces**, no 8. El 19, **7 veces**.

¿Por qué? Porque **ayer las borramos nosotros**. Eran los `-99`.

```
19 abr 21:00   -99   borrada
20 abr 00:00   -99   borrada
20 abr 03:00   -99   borrada
```

Las tres eran **de noche**. Al sacarlas, esos dos días se quedaron **sin sus horas frías**.

> El promedio subió, y el día trepó al primer puesto. **No fue el día más caluroso: fue el día al que le borramos la madrugada.**

---

# La regla de ayer, del otro lado

Ayer: *ningún promedio se entrega sin su `COUNT(*)` al lado.*

Hoy esa misma columna es lo único que separa un hallazgo de un papelón.

<br>

| | |
|---|---|
| Limpiar datos malos | **no** devuelve datos buenos |
| Deja | un agujero |
| Y si el agujero no es al azar | **sesga** lo que queda |

Borramos tres lecturas nocturnas. Nos quedó un abril más caluroso de lo que fue.

---

# Tres formas de numerar, y no dan lo mismo

```sql
ROW_NUMBER() OVER (ORDER BY prom DESC)   -- 1 2 3 4 5 6 7
RANK()       OVER (ORDER BY prom DESC)   -- 1 2 2 2 2 2 7
DENSE_RANK() OVER (ORDER BY prom DESC)   -- 1 2 2 2 2 2 3
```
```
2026-04-20  27.33   1   1   1
2026-04-05  25.63   2   2   2
2026-04-10  25.63   3   2   2
2026-04-15  25.63   4   2   2
2026-04-25  25.63   5   2   2
2026-04-30  25.63   6   2   2
2026-04-19  24.86   7   7   3
```

Cinco días empatados en 25.63. Ahí es donde las tres se separan.

---

# Cuál usar

| Función | Con empate | Sirve para |
|---|---|---|
| `ROW_NUMBER` | **inventa** un orden | quedarte con **una** fila por grupo |
| `RANK` | empata y **salta** (1,2,2,7) | un podio honesto |
| `DENSE_RANK` | empata y **no salta** (1,2,2,3) | *"¿cuántos niveles distintos hay?"* |

<br>

> `ROW_NUMBER` con empates **es no determinista**: dos ejecuciones pueden darte distinto ganador. Si te importa cuál sale, desempatá vos: `ORDER BY prom DESC, d`.

---

# El mejor lote de cada finca

Lo que **no** se puede hacer:

```sql
SELECT ... RANK() OVER (...) AS puesto
FROM ... WHERE puesto = 1;   -- ERROR: misuse of aliased window function
```

`WHERE` corre **antes** que la ventana. La columna todavía no existe.

```sql
WITH r AS ( SELECT ..., ROW_NUMBER() OVER (...) AS rn FROM ... )
SELECT finca, lote, kg_ha FROM r WHERE rn = 1;
```
```
Agricola La Union    A-1   38.18
Finca El Guayabo     L-02  529.73
Hacienda Santa Rosa  L-01  256.14
```

**Ventana adentro, filtro afuera.** Es el patrón más usado del día.

---

# `LAG`: la fila anterior

```sql
SELECT siembra_id, fecha, kg,
       LAG(kg) OVER (PARTITION BY siembra_id ORDER BY fecha) AS anterior,
       kg - LAG(kg) OVER (PARTITION BY siembra_id ORDER BY fecha) AS delta
FROM cosechas;
```
```
1   2026-03-20   4200   NULL    NULL
1   2026-04-18   3100   4200   -1100
4   2026-04-26   1850   2600    -750
6   2026-04-22    900   1200    -300
```

La primera fila de cada siembra tiene `NULL`: **no hay anterior**. Eso no es un error, es la respuesta correcta.

`LEAD()` es lo mismo mirando hacia adelante.

---

# Las tres cosechas que cayeron

**Los tres segundos cortes rindieron menos que el primero.** Sin excepción.

| siembra | de | a | delta |
|---|---|---|---|
| 1 | 4200 | 3100 | **−1100** |
| 4 | 2600 | 1850 | −750 |
| 6 | 1200 | 900 | −300 |

<br>

Esa consulta cabe en cinco líneas y es la primera del curso que **un jefe de finca leería sin traducción**.

> Sin `LAG`, esto sale con un `JOIN` de la tabla contra sí misma. Se puede. Es cuatro veces más largo y se rompe con el primer empate de fecha.

---

# `SUM() OVER`: el acumulado

Sin `ORDER BY` adentro → **el total del grupo** (lo del principio).
Con `ORDER BY` adentro → **el acumulado hasta esta fila**.

```sql
SELECT fecha, SUM(kg) AS kg_dia,
       SUM(SUM(kg)) OVER (ORDER BY fecha) AS acumulado
FROM cosechas GROUP BY fecha;
```
```
2026-03-20   4200    4200
2026-03-22   5400    9600
...
2026-04-30   9800   30550
```

Ese `30550` es el total de kilos del ejercicio 5. Ahora lo tienen **día a día**.

---

# El marco: media móvil de 7 días

```sql
AVG(prom) OVER (ORDER BY d ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)
```
```
2026-04-18   8   23.63   23.49
2026-04-19   7   24.86   23.81
2026-04-20   6   27.33   24.33     <- el pico se aplana
2026-04-21   8   21.63   23.91
```

La media móvil existe para **sacarle el ruido a una serie**.

El 20 de abril bajó de **27.33** a **24.33**.

> Le sacó el ruido a un dato que no era ruido. La media móvil **disimuló** el único día que había que mirar. Suavizar es perder información a propósito.

---

# Lo de hoy en una línea

**`GROUP BY` contesta sobre el grupo. `OVER` contesta sobre el grupo sin soltar la fila.**

<br>

| Quiero | Uso |
|---|---|
| el total al lado del detalle | `SUM(...) OVER (PARTITION BY ...)` |
| un puesto | `RANK` · `DENSE_RANK` · `ROW_NUMBER` |
| quedarme con el mejor de cada grupo | `ROW_NUMBER` en CTE + `WHERE rn = 1` |
| comparar con la fila anterior | `LAG` / `LEAD` |
| un acumulado | `SUM(...) OVER (ORDER BY ...)` |
| suavizar una serie | `AVG(...) OVER (... ROWS BETWEEN ...)` |

---

<!-- _class: lead -->

# A trabajar

## `ejercicio.md`

Un podio, tres caídas y un hueco que creamos nosotros.

Antes de empezar: `datos/agrodb_clase7.sql`
Tiene que dar **3, 6, 8, 10, 7, 19, 16, 6, 9, 973**
