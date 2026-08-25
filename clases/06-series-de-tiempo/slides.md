---
marp: true
paginate: true
theme: default
title: "Clase 6 · Datos de sensores: el tiempo como problema"
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
footer: "Curso de SQL · AgroDB · Clase 6"
---

<!-- _class: lead -->

# El tiempo como problema

## 977 lecturas, cuatro mentiras y ningún mensaje de error

Clase 6 · 17 de agosto

---

# Lo que cambia hoy

Hasta ayer, todas las tablas de AgroDB **cabían en la pantalla**.

`fincas` tiene 3 filas. `labores` tiene 19. Cuando algo estaba mal, se veía mirando.

<br>

Hoy entra `lecturas`: **977 filas**, y creciendo cada 3 horas para siempre.

> **A partir de hoy no podés verificar mirando.** Si no escribís una consulta que audite los datos, no sabés qué tenés.

---

# La tabla nueva

```sql
CREATE TABLE lecturas (
    lectura_id INTEGER PRIMARY KEY,
    sensor_id  INTEGER NOT NULL REFERENCES sensores(sensor_id),
    fecha_hora TEXT    NOT NULL,
    valor      NUMERIC(10,2) NOT NULL
);
```

Una fila por medición. Cada sensor mide **cada 3 horas**: 8 por día, 240 por mes.

**Miren lo que NO tiene.** En dos slides vuelve.

---

# El mapa, ahora completo

```
fincas ──< lotes ──< siembras ──< labores ──< labor_insumo >── insumos
                 │              │
                 └──< sensores  └──< cosechas
                       │
                       └──< lecturas        ← la de hoy
```

`lecturas` cuelga de `sensores`, que cuelga de `lotes`.

Para decir *"la temperatura del lote L-01 de Santa Rosa"* hay que recorrer **cuatro tablas**.

---

# SQLite no tiene tipo fecha

```sql
CREATE TABLE lecturas ( ... fecha_hora TEXT NOT NULL ... );
```

Una fecha en SQLite es **texto**. `'2026-04-07 12:00:00'` es una cadena de 19 caracteres, igual que `'Marta Ruiz'` es una de 10.

<br>

Funciona **solo** porque el formato `AAAA-MM-DD HH:MM:SS` ordena igual como texto que como fecha.

> Ese es el motivo real de la regla del formato ISO que vimos en la clase 4. No era estética.

---

# Cuatro funciones y ya

| Función | Qué hace |
|---|---|
| `DATE(x)` | corta la hora, deja `AAAA-MM-DD` |
| `strftime('%H', x)` | saca una parte (`%Y %m %d %H %w`) |
| `julianday(x)` | la vuelve **número**, para restar |
| `datetime(x,'+3 hours')` | la mueve |

```sql
SELECT DATE('2026-04-07 12:00:00');            -- 2026-04-07
SELECT strftime('%H', '2026-04-07 12:00:00');  -- 12
SELECT julianday('2026-04-08') - julianday('2026-04-07');  -- 1.0
```

---

# Agrupar por día

```sql
SELECT DATE(fecha_hora) AS dia,
       COUNT(*)         AS n,
       ROUND(AVG(valor), 2) AS promedio
FROM lecturas
WHERE sensor_id = 1
GROUP BY dia
ORDER BY dia;
```

```
2026-04-01   8   21.63
2026-04-02   8   22.63
2026-04-03   8   23.63
```

**`COUNT(*)` va siempre al lado del promedio.** Ya vamos a ver por qué.

---

# Agrupar por hora del día

```sql
SELECT strftime('%H', fecha_hora) AS hora,
       ROUND(AVG(valor), 2)
FROM lecturas WHERE sensor_id = 1
GROUP BY hora ORDER BY hora;
```

```
00  18.9     12  29.0
03  17.9     15  30.0      ← el pico
06  20.0     18  26.0
09  25.0     21  22.0
```

Treinta días colapsados en **un día promedio**. Eso es una serie de tiempo.

---

<!-- _class: lead -->

# Y ahora las cuatro mentiras

## Ninguna da error

---

# Mentira 1 · El `BETWEEN` que se come un día

```sql
SELECT COUNT(*) FROM lecturas
WHERE fecha_hora BETWEEN '2026-04-01' AND '2026-04-30';   -- 905

SELECT COUNT(*) FROM lecturas
WHERE fecha_hora >= '2026-04-01' AND fecha_hora < '2026-05-01';  -- 937
```

**Faltan 32 lecturas.** Son todas las del 30 de abril.

---

# Por qué

Comparación de **texto**, carácter por carácter:

```
'2026-04-30'            ← 10 caracteres, el tope del BETWEEN
'2026-04-30 03:00:00'   ← 19 caracteres, una lectura real
```

Los primeros 10 son idénticos. Después, el de arriba **se termina**.

Una cadena más corta es **menor** que una que la contiene. Entonces `'2026-04-30 03:00:00' > '2026-04-30'` y queda fuera del rango.

> `BETWEEN` sí es inclusivo. El problema no es `BETWEEN`: es que `'2026-04-30'` no significa *"todo el día 30"*, significa *"el 30 a las cero horas"*.

---

# La regla, para siempre

```sql
-- MAL
WHERE fecha_hora BETWEEN '2026-04-01' AND '2026-04-30'

-- BIEN
WHERE fecha_hora >= '2026-04-01' AND fecha_hora < '2026-05-01'
```

**Con horas, nunca `BETWEEN`. Siempre `>=` inicio y `<` el inicio del siguiente período.**

Se lee: *"desde el 1 de abril, hasta antes del 1 de mayo"*.

---

# Mentira 2 · El valor imposible

```sql
SELECT MIN(valor), MAX(valor), ROUND(AVG(valor),2)
FROM lecturas WHERE sensor_id = 1;
```
```
-99      32      22.15
```

El sensor se averió y escribió su **código de falla** en la columna del valor.

`-99` no es una temperatura. Es un sensor diciendo *"no sé"*.

---

# Y la base lo aceptó

```sql
valor NUMERIC(10,2) NOT NULL      -- eso es todo lo que pedimos
```

Sin `CHECK`, `-99` es un número perfectamente válido.

| | promedio |
|---|---|
| crudo | **22.15** |
| sin las 3 lecturas averiadas | **23.68** |

Un grado y medio. **Suficientemente chico para que nadie lo cuestione, suficientemente grande para decidir mal.**

---

# El día que llegó al tablero

```sql
SELECT DATE(fecha_hora) AS dia, ROUND(AVG(valor),2)
FROM lecturas WHERE sensor_id = 1
GROUP BY dia HAVING dia IN ('2026-04-19','2026-04-20');
```
```
2026-04-19     9.38
2026-04-20    -4.25
```

**Menos cuatro grados. En abril. En Los Ríos.**

Tres filas malas de 241 movieron el promedio del día 26 grados.

---

# Mentira 3 · El hueco

El sensor 2 tiene **216** lecturas de abril. Debería tener 240.

Faltan 24 = **3 días enteros**. Buscándolos por el camino obvio:

```sql
SELECT DATE(fecha_hora) AS dia, COUNT(*) AS n
FROM lecturas WHERE sensor_id = 2
GROUP BY dia HAVING n <> 8;
```
```
(0 filas)
```

---

# Un `GROUP BY` solo agrupa lo que existe

Un día sin ninguna fila **no es un grupo vacío**. No es un grupo.

La única forma de encontrar lo que falta es **traer un calendario propio** y restarle lo que hay:

```sql
WITH RECURSIVE dias(d) AS (
    SELECT '2026-04-01'
    UNION ALL
    SELECT DATE(d,'+1 day') FROM dias WHERE d < '2026-04-30'
)
SELECT d FROM dias
WHERE d NOT IN (SELECT DATE(fecha_hora) FROM lecturas WHERE sensor_id = 2);
```
```
2026-04-11   2026-04-12   2026-04-13
```

---

# El mismo hueco, mirando hacia atrás

```sql
SELECT sensor_id, anterior, fecha_hora,
       ROUND((julianday(fecha_hora) - julianday(anterior)) * 24, 1) AS horas
FROM (
  SELECT sensor_id, fecha_hora,
         LAG(fecha_hora) OVER (PARTITION BY sensor_id
                               ORDER BY fecha_hora) AS anterior
  FROM lecturas
)
WHERE (julianday(fecha_hora) - julianday(anterior)) * 24 > 3;
```
```
2   2026-04-10 21:00:00   2026-04-14 00:00:00   75.0
```

`LAG()` es una **función de ventana**: mañana, en serio. Hoy: *"el valor de la fila anterior"*.

---

# Mentira 4 · La medición que entró dos veces

```sql
SELECT sensor_id, fecha_hora, COUNT(*) AS veces
FROM lecturas
GROUP BY sensor_id, fecha_hora
HAVING COUNT(*) > 1;
```
```
1    2026-04-07 12:00:00    2
```

El datalogger reenvió un paquete. La misma medición, dos filas.

**Es exactamente el mismo `GROUP BY … HAVING` de la clase 4.** Cambió la tabla, no la técnica.

---

# Lo que faltaba en el `CREATE TABLE`

```sql
CREATE TABLE lecturas (
    ...
    valor NUMERIC(10,2) NOT NULL
          CHECK (valor BETWEEN -50 AND 1500),   -- mata la mentira 2
    UNIQUE (sensor_id, fecha_hora)              -- mata la mentira 4
);
```

Dos líneas que no escribimos, y dos de los cuatro problemas del día.

> La pregunta incómoda: si las agregás **hoy**, ¿qué pasa con las filas malas que ya están cargadas?

---

# El reporte que sí se entrega

```sql
SELECT f.nombre, lo.codigo, s.tipo,
       COUNT(*) AS n, ROUND(AVG(le.valor),2) AS promedio
FROM lecturas le
JOIN sensores s ON s.sensor_id = le.sensor_id
JOIN lotes lo   ON lo.lote_id  = s.lote_id
JOIN fincas f   ON f.finca_id  = lo.finca_id
WHERE le.fecha_hora >= '2026-04-01'
  AND le.fecha_hora <  '2026-05-01'
  AND le.valor > -50
GROUP BY f.nombre, lo.codigo, s.tipo;
```

Tres defensas en el `WHERE`. **Y `COUNT(*)` al lado del promedio, siempre.**

---

# Alertas con `CASE`

```sql
SELECT DATE(fecha_hora) AS dia, MAX(valor) AS maxima,
       CASE WHEN MAX(valor) >= 32 THEN 'ALERTA CALOR'
            WHEN MAX(valor) >= 30 THEN 'atencion'
            ELSE 'normal' END AS estado
FROM lecturas WHERE sensor_id = 1 AND valor > -50
GROUP BY dia;
```

En abril: **6 días en alerta, 12 en atención, 12 normales.**

`CASE` es un `if` dentro del `SELECT`: convierte un número en una decisión.

---

# La regla del día

> ## Ningún promedio se entrega sin su `COUNT(*)` al lado.

Ayer el `COUNT(*)` servía para detectar filas **de más** (el fan-out).

Hoy sirve para detectar filas **de menos**.

<br>

Si un sensor mide cada 3 horas durante 30 días, tiene **240** lecturas.
El que tenga menos, perdió algo. El que tenga más, duplicó algo.

---

# Lo de hoy en una línea

**Un promedio es una afirmación sobre datos que no miraste.**

Antes de promediar: contá, buscá el mínimo y el máximo, y fijate qué falta.

<br>

| Problema | Cómo se encuentra |
|---|---|
| rango mal escrito | `>=` y `<`, nunca `BETWEEN` con horas |
| valor imposible | `MIN` / `MAX` antes que `AVG` |
| hueco en la serie | calendario propio, o `LAG` |
| duplicado | `GROUP BY` + `HAVING COUNT(*) > 1` |

---

<!-- _class: lead -->

# A trabajar

## `ejercicio.md`

977 lecturas. Cuatro problemas. Dos horas.

Antes de empezar: `datos/agrodb_clase6.sql`
Tiene que dar **3, 6, 8, 10, 7, 19, 16, 6, 9, 977**
