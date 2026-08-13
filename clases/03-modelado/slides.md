---
marp: true
paginate: true
theme: default
title: "Clase 3 · Del requerimiento al modelo de datos"
style: |
  section {
    font-family: system-ui, -apple-system, "Segoe UI", sans-serif;
    font-size: 26px;
    background: #fbfbfa;
    color: #1f2933;
    padding: 60px 70px;
  }
  section.lead {
    background: #16324f;
    color: #f4f7fa;
  }
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
footer: "Curso de SQL · AgroDB · Clase 3"
---

<!-- _class: lead -->

# Del requerimiento al modelo de datos

## Entidades, cardinalidad y la relación que no existe

Clase 3 · 11 de agosto

---

# Lo que ya saben (sin saber que lo saben)

En el Proyecto 1 escribieron `CREATE TABLE`, eligieron claves primarias y conectaron tablas.

Lo hicieron **por intuición**, mirando videos.

Hoy le ponemos método, nombre y reglas.

> Y agregamos la pieza que faltó, que es justo la que el proyecto real necesita.

---

# El contexto real

Una empresa agrícola quiere dejar de gestionar sus fincas en planillas.

Cada supervisor lleva la suya, con sus propias columnas y sus propios nombres. Nadie sabe cuál es la buena.

Nosotros no vamos a construir el sistema que reemplaza eso.

**Vamos a construir la base de datos que va debajo**, que es la parte donde ustedes van a trabajar de verdad.

---

# Tres errores del Proyecto 1

1. **La tabla que era una columna.** Si una entidad no tiene atributos propios ni se relaciona con nada, es un valor.

2. **La clave foránea del lado equivocado.** `pedido_id` dentro de `clientes` = un cliente, un pedido.

3. **La fecha como `'12/03/2026'`.** Ordena mal, compara mal, y **no da ningún error**.

---

# ¿De dónde salen las tablas?

De leer el requerimiento y subrayar.

> *"Hay que registrar cada actividad que se hace en el campo —siembra, fertilización, control de plagas, cosecha— con su fecha, quién la hizo y qué insumos usó."*
> — Requerimiento de ejemplo, módulo Labores

---

# La técnica del subrayado

| En el texto aparece… | En el modelo es… |
|---|---|
| Sustantivo concreto y contable | **Entidad** → tabla |
| Sustantivo que describe a otro | **Atributo** → columna |
| Verbo que une dos sustantivos | **Relación** → clave foránea |
| Sustantivo de lista corta y fija | **Categoría** → columna |

---

# La pregunta que decide

## ¿Esto tiene vida propia?

**Un insumo** existe en bodega aunque nadie lo haya aplicado nunca.
→ Tabla.

**El color de una etiqueta** no existe sin la etiqueta.
→ Columna.

---

# Cardinalidad: 1 a N

Una finca tiene **muchos** lotes. Un lote pertenece a **una** finca.

```sql
CREATE TABLE lotes (
    lote_id  INTEGER PRIMARY KEY,
    finca_id INTEGER NOT NULL REFERENCES fincas(finca_id),
    codigo   TEXT NOT NULL
);
```

> **La regla:** la clave foránea vive del lado "muchos". Siempre.

¿Y si la ponemos al revés? Cada finca tendría exactamente un lote.

---

# Cardinalidad: N a M

Una labor usa **varios** insumos.
Un insumo se usa en **varias** labores.

## ¿Dónde ponemos la clave foránea?

<br>

*(pensarlo treinta segundos antes de pasar)*

---

# Las dos respuestas equivocadas

**`insumo_id` dentro de `labores`**
→ una labor solo podría llevar un insumo.

**`labor_id` dentro de `insumos`**
→ un insumo solo se podría usar una vez en la vida.

---

# La respuesta

## En el modelo relacional, la relación N:M no existe.

Se convierte en **dos relaciones 1:N**, con una tabla en el medio.

```
  labores  ──1:N──►  labor_insumo  ◄──1:N──  insumos
                          ▲
                (labor_id, insumo_id)
                 clave primaria compuesta
```

---

# La tabla puente tiene columnas propias

```sql
CREATE TABLE labor_insumo (
    labor_id       INTEGER NOT NULL REFERENCES labores(labor_id),
    insumo_id      INTEGER NOT NULL REFERENCES insumos(insumo_id),
    cantidad       NUMERIC(10,2) NOT NULL CHECK (cantidad > 0),
    costo_unitario NUMERIC(10,2) NOT NULL,
    PRIMARY KEY (labor_id, insumo_id)
);
```

`cantidad` **no** pertenece a `labores` ni a `insumos`.

Pertenece a **la relación entre los dos**. Por eso existe la tabla puente.

---

# Ya se lo cruzaron antes

| Situación | La tabla del medio |
|---|---|
| Alumnos ↔ materias | inscripciones (con la nota) |
| Pedidos ↔ productos | `detalle_pedidos` (con la cantidad) |
| Labores ↔ insumos | `labor_insumo` (con la cantidad) |

`detalle_pedidos`, de la clase 1, **era esto todo el tiempo**.

---

# Ahora miren esta tabla

`registro_campo_plano`: el Excel del jefe de campo, importado tal cual.

```
id | finca | provincia | lote | cultivo | fecha | tipo_labor |
insumo_1 | cantidad_1 | unidad_1 | costo_unit_1 |
insumo_2 | cantidad_2 | unidad_2 | costo_unit_2 | costo_total
```

## ¿Qué hacemos cuando llega una labor con tres insumos?

---

# Cuatro problemas con nombre

| Lo que se ve | Cómo se llama |
|---|---|
| `insumo_1`, `insumo_2`… y no hay tercero | Viola **1FN** (grupo repetido) |
| `provincia` depende de `finca`, no de la fila | Viola **3FN** (dep. transitiva) |
| `Hacienda Sta. Rosa` vs `Hacienda Santa Rosa` | Anomalía de actualización |
| `costo_total` significa dos cosas distintas | Columna ambigua |

---

# Demo

```sql
SELECT finca, COUNT(*)
FROM registro_campo_plano
GROUP BY finca;
```

<br>

Devuelve **4 fincas**. En la realidad hay **3**.

## ¿Qué error dio SQLite?

Ninguno. Ese es el punto.

---

# Normalizar, en una frase

## Lograr que cada dato viva en un solo lugar.

Si un dato está en dos lugares, tarde o temprano van a decir cosas distintas.
Y nadie va a saber cuál de los dos tiene razón.

---

# Las restricciones defienden el modelo

```sql
PRAGMA foreign_keys = ON;   -- sin esto SQLite ignora las FK EN SILENCIO

CREATE TABLE lotes (
    lote_id   INTEGER PRIMARY KEY,
    finca_id  INTEGER NOT NULL REFERENCES fincas(finca_id),
    codigo    TEXT NOT NULL,
    hectareas NUMERIC(10,2) NOT NULL CHECK (hectareas > 0),
    estado    TEXT NOT NULL DEFAULT 'activo',
    UNIQUE (finca_id, codigo)
);
```

`UNIQUE` sobre **dos columnas juntas**: `L-01` se repite entre fincas, pero no dentro de una.

---

# El modelo, defendiéndose solo

```sql
INSERT INTO labores
VALUES (99, 999, 'riego', '2026-05-01', 'X', 0, NULL);
```

```
FOREIGN KEY constraint failed
```

La siembra 999 no existe.

En Excel, ese dato entraba sin que nadie se enterara.

---

<!-- _class: lead -->

# Práctica · 2 horas

## Convertir el Excel del jefe de campo en un modelo que aguante

4 tablas nuevas · 12 filas migradas · sin perder un solo dato

`clases/03-modelado/ejercicio.md`

---

# Antes de arrancar

1. **sqliteonline.com** → SQLite
2. Pegar `datos/agrodb_nucleo.sql` **completo** y ejecutar
   → deben salir **3, 6, 8, 10 y 12**
3. **No abrir otra pestaña.** Se pierde la base.

<br>

> **Regla de los 20 minutos:** si llevás ese tiempo trabado, escribís `DUDA` como comentario y seguís. No baja la nota.
