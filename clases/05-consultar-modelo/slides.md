---
marp: true
paginate: true
theme: default
title: "Clase 5 · Consultar el modelo propio"
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
footer: "Curso de SQL · AgroDB · Clase 5"
---

<!-- _class: lead -->

# Consultar el modelo propio

## JOIN de cinco tablas, y el `SUM` que miente

Clase 5 · 14 de agosto

---

# Tres clases para llegar hasta acá

**Clase 3:** diseñaron el modelo.
**Clase 4:** lo cargaron y lo limpiaron.
**Hoy:** le hacen las preguntas que hace un jefe de finca.

<br>

> Hasta la clase 2 consultaban tablas que les daba yo. Desde hoy consultan **su propio modelo**. Si algo no se puede preguntar, es porque el diseño no lo permite.

---

# El mapa de AgroDB

```
fincas ──< lotes ──< siembras ──< labores ──< labor_insumo >── insumos
                 │              │
                 └──< sensores  └──< cosechas
```

| Símbolo | Qué significa |
|---|---|
| `A ──< B` | una fila de A tiene muchas de B |
| `>── ` | la tabla puente cierra el N:M |

**Toda consulta de hoy es un camino sobre este dibujo.**

---

# Tabla nueva: `cosechas`

```sql
CREATE TABLE cosechas (
    cosecha_id INTEGER PRIMARY KEY,
    siembra_id INTEGER NOT NULL REFERENCES siembras(siembra_id),
    fecha      DATE    NOT NULL,
    kg         NUMERIC(10,2) NOT NULL CHECK (kg > 0),
    calidad    TEXT    NOT NULL DEFAULT 'primera',
    destino    TEXT
);
```

Una siembra puede rendir **varias** cosechas: pasadas sucesivas sobre el mismo lote.

Retengan eso. En cuatro slides va a ser el problema.

---

# Un JOIN de cinco tablas se lee como una frase

```sql
SELECT f.nombre, l.codigo, cu.nombre, s.fecha_siembra, lb.tipo_labor
FROM labores  lb
JOIN siembras s  ON s.siembra_id = lb.siembra_id
JOIN lotes    l  ON l.lote_id    = s.lote_id
JOIN fincas   f  ON f.finca_id   = l.finca_id
JOIN cultivos cu ON cu.cultivo_id = s.cultivo_id;
```

*"Cada labor pertenece a una siembra, que está en un lote, que está en una finca, y es de un cultivo."*

**No hay que pensarlo como cinco tablas. Es un camino de cinco pasos.**

---

# Un detalle que muerde: `L-01` no es único

```sql
SELECT codigo, hectareas FROM lotes WHERE codigo = 'L-01';
```
```
L-01   28.50     ← Hacienda Santa Rosa
L-01   22.00     ← Finca El Guayabo
```

El `UNIQUE` del modelo es `(finca_id, codigo)`, no `codigo` solo. **Y está bien así.**

> Consecuencia práctica: si un reporte dice "L-01" sin decir la finca, ese reporte no sirve. Siempre traigan el nombre de la finca.

---

# La pregunta del jefe de finca

## ¿Cuántos kilos cosechó cada finca?

```sql
SELECT f.nombre, SUM(c.kg) AS kg
FROM fincas f
JOIN lotes    l ON l.finca_id   = f.finca_id
JOIN siembras s ON s.lote_id    = l.lote_id
JOIN cosechas c ON c.siembra_id = s.siembra_id
GROUP BY f.finca_id;
```
```
Hacienda Santa Rosa   14200
Finca El Guayabo      14250
Agricola La Union      2100
```

---

# Ahora quiero ver también las labores

```sql
JOIN labores lb ON lb.siembra_id = s.siembra_id   -- una línea más
```
```
Hacienda Santa Rosa   41100      (era 14200)
Finca El Guayabo      32950      (era 14250)
Agricola La Union      4200      (era  2100)
```

<br>

**Nadie tocó la tabla `cosechas`.** No entró ni un kilo nuevo.

Y el reporte ahora dice que la empresa produjo el triple.

---

# Por qué: cada cosecha se repite una vez por labor

La siembra 1 tiene **3 labores** y **2 cosechas**.

| | cosecha 1 (4200) | cosecha 2 (3100) |
|---|---|---|
| **labor 1** | fila | fila |
| **labor 2** | fila | fila |
| **labor 13** | fila | fila |

3 × 2 = **6 filas**. Los 4200 kg aparecen **tres veces**.

`SUM` no se equivoca: suma lo que le dan. Le dieron seis filas.

---

# La regla del *fan-out*

## Cuando unís dos tablas hijas del mismo padre, las filas se multiplican entre sí.

<br>

Y no hay ningún error. La consulta corre, devuelve un número, y el número es falso.

> Este es **el** error de reporting. No lo detecta el motor, no lo detecta la sintaxis, y en un tablero se ve exactamente igual de bien que el número correcto.

---

# Cómo detectarlo antes de mandar el reporte

```sql
SELECT COUNT(*)                 AS filas,      -- 11
       COUNT(DISTINCT c.cosecha_id) AS cosechas   --  4
FROM fincas f
JOIN lotes l ON ... JOIN siembras s ON ...
JOIN cosechas c ON ... JOIN labores lb ON ...
WHERE f.finca_id = 1;
```

<br>

**Si `COUNT(*)` es mayor que la cantidad real de filas del hijo que estás sumando, el `SUM` está inflado.**

Tres segundos. Es el mismo reflejo que el `SELECT` previo al `UPDATE` de ayer.

---

# Cómo se arregla: agregar *antes* de unir

```sql
WITH kg_por_siembra AS (
    SELECT siembra_id, SUM(kg) AS kg
    FROM cosechas GROUP BY siembra_id
)
SELECT f.nombre, SUM(k.kg) AS kg
FROM fincas f
JOIN lotes    l ON l.finca_id = f.finca_id
JOIN siembras s ON s.lote_id  = l.lote_id
JOIN kg_por_siembra k ON k.siembra_id = s.siembra_id
GROUP BY f.finca_id;
```

Cada siembra entra **una sola vez**, ya sumada. Ahora sí se puede unir lo que haga falta.

---

# El mismo error, al revés: el `JOIN` que borra filas

## ¿Cuánto se gastó en mano de obra?

```sql
SELECT SUM(costo_mano_obra) FROM labores;                       -- 2330.00
```
```sql
SELECT SUM(lb.costo_mano_obra)
FROM labores lb JOIN labor_insumo li ON li.labor_id = lb.labor_id;   -- 2035.00
```

Las 7 labores **sin insumos** (riegos, podas) desaparecieron del `JOIN`, y las que tienen dos insumos se contaron dos veces.

**Se perdieron 760 y se inflaron 465. El error neto casi se compensa.** Por eso nadie lo ve.

---

# Y una tercera que no avisa: la división entera

```sql
SELECT l.codigo, SUM(c.kg) / l.hectareas AS kg_ha ...
```

| lote | hectáreas | resultado | correcto |
|---|---|---|---|
| L-02 Guayabo | 18.5 | 529.73 | 529.73 |
| L-01 Guayabo | **22** | **202.0** | 202.27 |
| A-1 La Union | **55** | **38.0** | 38.18 |

Si los dos operandos son enteros, SQLite divide entero. **Tres de seis filas salen mal y las otras tres, bien.**

Se arregla con `* 1.0`.

---

# `LEFT JOIN` no es "por si acaso"

## Es la herramienta para preguntar por lo que **no** está

```sql
SELECT f.nombre, l.codigo
FROM lotes l
JOIN fincas f       ON f.finca_id = l.finca_id
LEFT JOIN sensores se ON se.lote_id = l.lote_id
WHERE se.sensor_id IS NULL;
```

El patrón es siempre el mismo: **`LEFT JOIN` + `WHERE hijo IS NULL`**.

Trae los padres a los que no les corresponde ningún hijo.

---

# Cuatro preguntas que solo responde un `LEFT JOIN`

| Pregunta de negocio | En AgroDB |
|---|---|
| ¿Qué lotes están a ciegas? | lotes sin sensor |
| ¿Qué siembras nadie trabajó? | siembras sin labores |
| ¿Qué compramos y no usamos? | insumos sin movimientos |
| ¿Qué está en producción y no rinde? | siembras sin cosecha |

<br>

> Un `JOIN` normal nunca las contesta: lo que falta **no tiene fila** para aparecer.

---

# La trampa del `WHERE` en un `LEFT JOIN`

```sql
LEFT JOIN sensores se ON se.lote_id = l.lote_id
WHERE se.activo = 1     -- ❌ 4 filas: aparecen 3 lotes de 8
```
```sql
LEFT JOIN sensores se ON se.lote_id = l.lote_id AND se.activo = 1
                        -- ✅ 9 filas: los 8 lotes, con NULL donde no hay
```

El `WHERE` se aplica **después** de unir: descarta los `NULL` que el `LEFT JOIN` acaba de crear y lo convierte en un `JOIN` común.

## La condición sobre la tabla de la derecha va en el `ON`.

---

# Ahora sí, los nombres

Lo hicieron en la clase 3 sin saber cómo se llamaba:

| Forma | Regla | Lo que arreglaron |
|---|---|---|
| **1FN** | un solo valor por celda | `insumo_1, insumo_2, insumo_3` → tabla `labor_insumo` |
| **2FN** | nada depende de *parte* de la clave | `unidad` dependía del insumo, no de la labor → tabla `insumos` |
| **3FN** | nada depende de otro no-clave | `provincia` dependía de la finca, no de la labor → tabla `fincas` |

> El vocabulario viene después de la experiencia. Ya normalizaron; hoy le ponen el nombre.

---

<!-- _class: lead -->

# Práctica · 2 horas

## 16 consultas de negocio sobre su propio modelo

Ninguna es difícil de escribir. Varias son fáciles de escribir **mal**.

`clases/05-consultar-modelo/ejercicio.md`

---

# Antes de arrancar

1. **Pestaña nueva** en sqliteonline.com
2. Pegar `datos/agrodb_clase5.sql` completo y ejecutar
   → **3, 6, 8, 10, 7, 19, 16, 6, 9**
3. Ese script trae el ejercicio 4 ya resuelto **y** la tabla `cosechas`

<br>

> **La regla de hoy:** antes de cada `SUM`, corré la misma consulta con `COUNT(*)`. Si hay más filas de las que esperabas, el `SUM` está mintiendo.
