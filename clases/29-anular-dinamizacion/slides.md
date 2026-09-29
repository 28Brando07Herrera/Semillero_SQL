---
marp: true
paginate: true
theme: default
title: "Clase 29 · La finca que se llamaba Total"
style: |
  section { font-family: system-ui, -apple-system, "Segoe UI", sans-serif; font-size: 26px; background: #fbfbfa; color: #1f2933; padding: 60px 70px; }
  section.lead { background: #16324f; color: #f4f7fa; }
  section.lead h1 { color: #ffffff; font-size: 54px; line-height: 1.1; }
  section.lead h2 { color: #7fb3d5; font-weight: 400; font-size: 30px; }
  h1 { color: #16324f; font-size: 40px; border-bottom: 3px solid #f2a104; padding-bottom: 10px; }
  h2 { color: #1c7293; font-size: 32px; }
  strong { color: #b3541e; }
  code { background: #eef2f6; padding: 1px 6px; border-radius: 4px; }
  pre { background: #16324f; border-radius: 8px; font-size: 20px; }
  pre code { background: transparent; color: #e8eef4; }
  table { font-size: 23px; }
  th { background: #16324f; color: #fff; }
  blockquote { border-left: 5px solid #f2a104; color: #4a5568; font-style: normal; }
  footer { color: #8a99a8; font-size: 16px; }
  .verde { background: #1E8449; color: #fff; padding: 2px 10px; border-radius: 4px; }
  .rojo { background: #C0392B; color: #fff; padding: 2px 10px; border-radius: 4px; }
footer: "Curso de SQL · AgroDB · Clase 29"
---

<!-- _class: lead -->

# La finca que se llamaba Total

## Anular dinamización en Power Query, y un total de la hoja que se sumó otra vez

Clase 29 · 29 de septiembre

---

# Lo que llega hoy

Planeación cambió de sistema. Ya no manda `h_meta.csv`: manda **su hoja**, `metas_planeacion.csv`.

| `finca_id` | `finca` | `2026-01-01` | `2026-02-01` | … | `2026-12-01` | `Total` |
|---|---|---|---|---|---|---|
| 1 | Hacienda Santa Rosa | 1500 | 2000 | … | 300 | 20000 |
| 2 | Finca El Guayabo | 1440 | 2000 | … | 400 | 19000 |
| 3 | Agricola La Union | 1100 | 1200 | … | 300 | 8000 |
| | Total | 4040 | 5200 | … | 1000 | 47000 |

> *«Son **las mismas metas de siempre**: 47 000 kg en el año. Solo cambió el formato.»*

---

# A lo ancho contra a lo largo

| | La hoja de planeación | Lo que el modelo necesita |
|---|---|---|
| Una fila por | finca | finca **y mes** |
| Los meses están en | **los encabezados** | **una columna**, `fecha_mes` |
| Los kilos están en | doce columnas | **una columna**, `kg_meta` |
| Forma | 3 filas × 12 meses | **36 filas** |

<br>

- Una relación con `dim_tiempo` necesita **una columna de fecha**. Un encabezado no se puede relacionar con nada.
- `[Meta]` es un `SUM` de **una columna de kilos**, no de doce.

> **Anular dinamización**: cada celda se vuelve una fila, con su encabezado al lado. Es lo contrario de una tabla dinámica.

---

# El modelo de hoy

Un `.pbix` nuevo con cuatro CSV de `datos/csv_clase29/` y **tres relaciones**: `h_cosecha` con la finca, el cultivo y la fecha.

```
Kilos = SUM( h_cosecha[kg] )
```

```
Cosechas = COUNTROWS( h_cosecha )
```

`h_meta` no está en la carpeta: hoy **se construye** con la hoja de planeación. Si las metas son las mismas, la tabla de control tiene que volver a decir:

| Finca | `[Kilos]` | `[Meta]` | `[Cumplimiento]` | `[Cosechas]` |
|---|---|---|---|---|
| Agricola La Union | 2 100 | 5 000 | 42,00 % | 2 |
| Finca El Guayabo | 14 250 | 9 440 | 150,95 % | 3 |
| Hacienda Santa Rosa | 14 200 | 10 000 | 142,00 % | 4 |
| **Total** | **30 550** | **24 440** | **125,00 %** | **9** |

---

# Anular dinamización

**Obtener datos → Texto o CSV** → `metas_planeacion.csv` → **Transformar datos**. Dice **4 filas** y **15 columnas**.

1. Clic en **`finca_id`**, **Ctrl** + clic en **`finca`**: las columnas que **se quedan**.
2. Clic derecho → **Anular dinamización de otras columnas**.
3. Aparecen **`Atributo`** y **`Valor`**. Renómbralas: **`fecha_mes`** y **`kg_meta`**.

La barra de fórmulas dice:

```
Table.UnpivotOtherColumns( … , {"finca_id", "finca"} , "Atributo" , "Valor" )
```

Abajo a la izquierda: **52 filas**. Son 4 filas × 13 columnas: cada celda de la hoja, una fila.

---

# La columna Total

`fecha_mes` es texto. Clic en su ícono → **Fecha**. Aparecen **cuatro** celdas con `Error`.

La clase 27 dejó una regla: **los `Error` se leen antes de quitarlos**. Antes del cambio de tipo, las cuatro decían lo mismo:

| `finca` | `fecha_mes` | `kg_meta` |
|---|---|---|
| Hacienda Santa Rosa | **Total** | 20000 |
| Finca El Guayabo | **Total** | 19000 |
| Agricola La Union | **Total** | 8000 |
| Total | **Total** | 47000 |

Es la **columna** Total de la hoja. Borra el paso del tipo, **filtra `fecha_mes` sin `Total`** y cambia a **Fecha** otra vez: **48 filas, cero errores**.

> Esta vez el `Error` avisó, y **sí lo leímos**.

---

# Las metas cargadas

La consulta se renombra **`h_meta`**. **Cerrar y aplicar**, las relaciones 4 y 5 (`finca_id` y `fecha_mes`), y:

```
Meta = SUM( h_meta[kg_meta] )
```

```
Cumplimiento = DIVIDE( [Kilos] , [Meta] )
```

```
Filas de meta = COUNTROWS( h_meta )
```

| Finca | `[Kilos]` | `[Meta]` | `[Cumplimiento]` | `[Cosechas]` |
|---|---|---|---|---|
| Agricola La Union | 2 100 | 5 000 | 42,00 % | 2 |
| Finca El Guayabo | 14 250 | 9 440 | 150,95 % | 3 |
| Hacienda Santa Rosa | 14 200 | 10 000 | 142,00 % | 4 |
| <span class="rojo">(En blanco)</span> | | **24 440** | | |
| **Total** | **30 550** | <span class="rojo">**48 880**</span> | <span class="rojo">**62,50 %**</span> | **9** |

---

# ¿Y qué error dio?

## Ninguno. Las 48 filas tienen fecha válida y kilos válidos.

<br>

- **Cada finca** da exactamente lo de siempre: 42,00, 150,95 y 142,00 %.
- Los cuatro `Error` eran **de la columna** Total, y ya los filtramos.
- La única pista estaba en **Vista → Calidad de columna**, debajo de `finca_id`: **25 % vacío**.

<br>

> El número viejo lo atrapó otra vez: la empresa estaba en **125,00 %** y ahora está en **62,50 %**, con las mismas cosechas y, según el correo, las mismas metas.

---

# La finca que se llamaba Total

En Power Query, filtra `finca_id` = **null**: **12 filas**, todas con `finca` = **Total**.

| `fecha_mes` | 2026-01-01 | 2026-02-01 | 2026-03-01 | 2026-04-01 | … | Año |
|---|---|---|---|---|---|---|
| `kg_meta` | 4 040 | 5 200 | 6 900 | 8 300 | … | **47 000** |

<br>

Es la **fila** Total de la hoja. Para Power Query, **una finca más**: doce meses, todos válidos, sin un solo `Error`.

De enero a abril suma **24 440**: la meta de la empresa **otra vez**. Por eso el total se fue a 48 880.

> La columna Total dio `Error`. **La fila Total, no.**

---

# El segundo arreglo obvio

El `(En blanco)` está en la tabla. **Filtros en este objeto visual** → `finca` → marca todo **menos `(En blanco)`**.

| | |
|---|---|
| La fila `(En blanco)` | desapareció <span class="verde">✓</span> |
| Total de la tabla | **30 550 / 24 440 / 125,00 %** <span class="verde">✓</span> |
| `[Filas de meta]` en el total | **12** <span class="verde">✓</span> |

<br>

Pasa **las tres pruebas**.

> Y la fila de planeación **sigue en `h_meta`**. El filtro no la quitó del modelo: la quitó **de esa tabla**.

---

# Lo que el filtro no tapó

En la misma página, una tarjeta con `[Meta]`: <span class="rojo">**48 880**</span>. Y una tabla por mes, sin el filtro:

| Mes | `[Kilos]` | `[Meta]` | `[Cumplimiento]` | Era |
|---|---|---|---|---|
| Enero | | **8 080** | | 4 040 |
| Febrero | | **10 400** | | 5 200 |
| Marzo | 10 800 | **13 800** | <span class="rojo">**78,26 %**</span> | 156,52 % |
| Abril | 19 750 | **16 600** | <span class="rojo">**118,98 %**</span> | 237,95 % |

<br>

Por mes **no hay** `(En blanco)` que filtrar: la fila Total **tiene** fecha. Cada mes lleva su meta **dos veces**, y la tabla se ve sana.

---

# La prueba de la fila sin finca

Una medida que tiene que estar **vacía**, siempre:

```
Meta sin finca = CALCULATE( [Meta] , ISBLANK( h_meta[finca_id] ) )
```

| | Enero–abril 2026 | Año 2026 |
|---|---|---|
| Con la fila Total | <span class="rojo">**24 440**</span> | <span class="rojo">**47 000**</span> |
| Sin ella | vacía | vacía |

<br>

Y la de filas: `[Filas de meta]` en todo el año tiene que ser **36 = 3 fincas × 12 meses**. Con la fila Total dice **48**.

> Toda meta es **de una finca**. Una meta sin finca no es una meta: es una suma.

---

# El arreglo: en Power Query, no en el objeto visual

Quita el filtro del objeto visual. **Transformar datos** → `h_meta` → filtra `finca_id` y desmarca **`(null)`**. **36 filas**.

| Finca | `[Kilos]` | `[Meta]` | `[Cumplimiento]` | `[Cosechas]` |
|---|---|---|---|---|
| Agricola La Union | 2 100 | 5 000 | 42,00 % | 2 |
| Finca El Guayabo | 14 250 | 9 440 | 150,95 % | 3 |
| Hacienda Santa Rosa | 14 200 | 10 000 | 142,00 % | 4 |
| **Total** | **30 550** | <span class="verde">**24 440**</span> | <span class="verde">**125,00 %**</span> | **9** |

Tarjeta `[Meta]` **24 440**, `[Meta sin finca]` **vacía**. Sin el segmentador de mes: **30 550 / 47 000 / 65,00 %**.

> Y **47 000** es el Total de la hoja. El total **sirve**: para comprobar, no para cargar.

---

# ¿Por qué «otras columnas»?

| Opción | La fórmula nombra | Si el año que viene llega `2027-01-01` |
|---|---|---|
| Anular dinamización de **otras columnas** | las que **se quedan**: `finca_id`, `finca` | entra sola |
| Anular **solo** la dinamización de las columnas **seleccionadas** | los doce meses de 2026 | **se queda fuera, sin aviso** |

<br>

Un paso de Power Query que **nombra columnas** es una foto de la hoja de hoy. «Otras columnas» nombra lo que no cambia.

> Y por la misma razón entró `Total`: «otras columnas» quiere decir **todo lo que no nombraste es un mes**.

---

# La prueba de cada hoja a lo ancho

| Qué revisas | Qué atrapa |
|---|---|
| **filas** = fincas × meses: **36** | la fila Total (48) |
| **distintos** de `fecha_mes` antes del tipo: **12** | la columna Total (13) |
| **Calidad de columna** de `finca_id`: **0 % vacío** | la fila sin finca (25 %) |
| **`[Meta sin finca]`** vacía | lo mismo, en el tablero |
| el **Total de la hoja** contra la meta del año | 47 000 contra 94 000 |
| el número viejo **sin filtros en el objeto visual** | el arreglo que solo tapó |

<br>

> El filtro del objeto visual pasa la prueba del número viejo **porque la prueba se hizo en esa misma tabla**.

---

# Los errores que van a ver hoy

| Síntoma | Qué pasó | Arreglo |
|---|---|---|
| los encabezados son `Column1`, `Column2`… | la primera fila no se promovió | **Usar la primera fila como encabezado** |
| **8 filas** y los meses siguen de columnas | seleccionaste los meses y usaste «otras columnas» | selecciona **`finca_id` y `finca`** |
| `fecha_mes` con **4 `Error`** | la columna Total | filtra `Total` **antes** del tipo |
| la relación 5 no se deja crear | `fecha_mes` quedó como texto | cámbiala a **Fecha** |
| `[Meta]` da error | `kg_meta` quedó como texto | **Número entero** |
| aparece **`(En blanco)`** y el total en **62,50 %** | la fila Total | filtra `finca_id` sin `(null)` en Power Query |
| la tabla dice 125,00 % y la tarjeta **48 880** | filtraste el objeto visual | quita el filtro; el arreglo va en Power Query |
| sigue el **62,50 %** después del arreglo | faltó **Cerrar y aplicar** | aplícalo, y revisa que el filtro sea el último paso |

---

<!-- _class: lead -->

# La idea del día

## Un total escrito en la hoja es, para Power Query, una finca más.

<br>

La columna Total dio **cuatro `Error`** y los leímos. La fila Total no dio ninguno: entró como finca, con doce meses válidos, y la empresa bajó a **62,50 %**. El filtro del objeto visual regresó el **125,00 %** a una tabla y dejó **48 880** en todas las demás. Quitándola en Power Query: **36 filas**, **24 440** y **125,00 %**.

<br>

**Práctica:** construye `h_meta` desde la hoja, filtra la columna Total, encuentra la finca que se llamaba Total, cae en el filtro del objeto visual y quita la fila donde se debe.

**Y la tabla de control tiene que decir 125,00 % sin filtros en el objeto visual, con 36 filas de meta en el año y `[Meta sin finca]` vacía.**
