---
marp: true
paginate: true
theme: default
title: "Clase 26 · Los kilos que llegaron en otro mes"
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
footer: "Curso de SQL · AgroDB · Clase 26"
---

<!-- _class: lead -->

# Los kilos que llegaron en otro mes

## Relaciones inactivas y `USERELATIONSHIP`, y una fecha que el modelo tenía pero no usaba

Clase 26 · 24 de septiembre

---

# Lo que llega hoy

`h_cosecha` trae **una columna nueva al final**: `fecha_entrega`, el día en que la cosecha **se entregó al comprador**.

| `cosecha_id` | cultivo | `fecha` | `fecha_entrega` | `kg` |
|---|---|---|---|---|
| 1 | Mango | 2026-03-20 | 2026-03-22 | 4 200 |
| 7 | Maiz | 2026-04-30 | **2026-05-12** | 9 800 |
| 8 | Cacao | 2026-03-28 | **2026-04-24** | 1 200 |
| 25 | Cacao | **2025-12-05** | **2026-01-01** | 1 200 |

Y llega **un pedido de finanzas**:

> *«Nosotros cobramos cuando se entrega, no cuando se corta. Queremos los **kilos entregados por mes**, en el mismo tablero.»*

---

# Por qué hay dos fechas

Entre el corte y la entrega pasa lo que cada cultivo necesita antes de venderse:

| Cultivo | Días a la entrega | Por qué |
|---|---|---|
| Mango, Guayaba | 2 | fruta fresca: se empaca y sale |
| Maiz | 12 | secado del grano |
| Cacao | 27 | fermentado y secado de la almendra |

<br>

Casi siempre caen en el mismo mes. **Casi.** El maíz del 30 de abril se entrega en mayo, y el cacao que se cortó el **5 de diciembre de 2025** se entregó el **1 de enero de 2026**: es de un año para campo y del otro para finanzas.

> Las dos fechas son ciertas. Contestan **preguntas distintas**.

---

# El modelo de hoy

Un `.pbix` nuevo con cinco CSV de `datos/csv_clase26/` (todos menos `seguridad.csv`). Las **cinco relaciones de siempre**, dibujadas a mano como en la clase 24:

| De | A |
|---|---|
| `h_cosecha[finca_id]` | `dim_finca[finca_id]` |
| `h_cosecha[cultivo_id]` | `dim_cultivo[cultivo_id]` |
| `h_cosecha[fecha]` | `dim_tiempo[fecha]` |
| `h_meta[finca_id]` | `dim_finca[finca_id]` |
| `h_meta[fecha_mes]` | `dim_tiempo[fecha]` |

Segmentadores `anio` = 2026 y `mes` en 1–4. La tabla por finca de siempre:

| Finca | `[Kilos]` | `[Meta]` | `[Cumplimiento]` |
|---|---|---|---|
| Agricola La Union | 2 100 | 5 000 | 42,00 % |
| Finca El Guayabo | 14 250 | 9 440 | 150,95 % |
| Hacienda Santa Rosa | 14 200 | 10 000 | 142,00 % |
| **Total** | **30 550** | **24 440** | **125,00 %** |

---

# La segunda relación

En la vista de modelo, arrastra `h_cosecha[fecha_entrega]` sobre `dim_tiempo[fecha]`.

<br>

Power BI **la crea**, pero la dibuja con **línea punteada**.

<br>

| Relación | Cómo se ve | Estado |
|---|---|---|
| `h_cosecha[fecha]` → `dim_tiempo[fecha]` | línea continua | **activa** |
| `h_cosecha[fecha_entrega]` → `dim_tiempo[fecha]` | línea punteada | **inactiva** |

<br>

> Entre dos tablas puede haber varias relaciones, pero **solo una activa**. Si no, un filtro de `dim_tiempo` no sabría por cuál camino llegar a `h_cosecha`.

---

# La medida obvia

La relación ya está dibujada. La medida parece de una línea:

```
Kilos entregados = SUM( h_cosecha[kg] )
```

Tabla nueva: `dim_tiempo[nombre_mes]`, `[Kilos]` y `[Kilos entregados]`.

| `nombre_mes` | `[Kilos]` | `[Kilos entregados]` |
|---|---|---|
| Marzo | 10 800 | 10 800 |
| Abril | 19 750 | 19 750 |
| **Total** | **30 550** | **30 550** |

<br>

> Las dos columnas son **idénticas**. Y el maíz del 30 de abril, que se entregó en mayo, está **en abril**.

---

# ¿Y qué error dio?

## Ninguno. Otra vez.

<br>

- La relación se creó sin quejarse.
- La medida se guardó sin quejarse.
- Los números **no están mal**: son los kilos **cosechados** por mes, bien sumados.

<br>

> Finanzas recibe un reporte de «entregados» que dice **10 800 en marzo**. Por marzo cobró **9 600**. Y nadie ve la diferencia, porque la columna se llama «entregados».

---

# La línea punteada

Un filtro de `dim_tiempo` viaja a `h_cosecha` **solo por la relación activa**. La punteada está dibujada, pero **no filtra nada**.

<br>

| Qué hace la medida | Por dónde llega el mes |
|---|---|
| `SUM( h_cosecha[kg] )` | por `fecha`, la activa. **Siempre.** |

<br>

`[Kilos entregados]` no dice nada de `fecha_entrega`. El nombre de la medida **no elige el camino**: lo elige el modelo.

> Una relación inactiva es un camino **cerrado**, y solo lo abre la medida que lo pide.

---

# `USERELATIONSHIP`

La medida pide el camino, **mientras se calcula**:

```
Kilos entregados = CALCULATE( [Kilos] , USERELATIONSHIP( h_cosecha[fecha_entrega] , dim_tiempo[fecha] ) )
```

| `nombre_mes` | `[Kilos]` | `[Kilos entregados]` |
|---|---|---|
| Enero | | **1 200** |
| Marzo | 10 800 | **9 600** |
| Abril | 19 750 | **10 250** |
| **Total** | **30 550** | **21 050** |

<br>

- **Enero** aparece: es el cacao que se cortó en diciembre de 2025.
- **Marzo** baja 1 200: el cacao del 28 de marzo se entregó en abril.
- **Abril** gana ese cacao de marzo, y pierde el maíz y el cacao que salieron en mayo.

> Solo esa medida usa `fecha_entrega`. **`[Kilos]`, `[Meta]` y todo lo demás siguen igual.**

---

# El mismo segmentador, dos preguntas

Quita el segmentador de `mes`: `anio` = 2026, el año completo.

| `nombre_mes` | `[Kilos]` | `[Kilos entregados]` |
|---|---|---|
| Enero | | 1 200 |
| Marzo | 10 800 | 9 600 |
| Abril | 19 750 | 10 250 |
| Mayo | | **10 700** |
| **Total** | **30 550** | **31 750** |

<br>

El segmentador dice **2026** para las dos medidas. Para `[Kilos]`, «2026» es **el año del corte**; para `[Kilos entregados]`, **el año de la entrega**. Los 1 200 de diciembre cuentan en 2026 para una y en 2025 para la otra.

> Vuelve a poner `mes` en 1–4.

---

# ¿Y si activo la otra?

El arreglo tentador: **Modelado → Administrar relaciones**, desactivar la de `fecha` y activar la de `fecha_entrega`. Así `SUM` «ya da» los entregados.

La tabla por finca, **sin tocar una sola medida**:

| Finca | `[Kilos]` | `[Meta]` | `[Cumplimiento]` |
|---|---|---|---|
| Agricola La Union | 2 400 | 5 000 | 48,00 % |
| Finca El Guayabo | 4 450 | 9 440 | <span class="rojo">**47,14 %**</span> |
| Hacienda Santa Rosa | 14 200 | 10 000 | 142,00 % |
| **Total** | **21 050** | **24 440** | <span class="rojo">**86,13 %**</span> |

<br>

> El Guayabo pasa de **150,95 %** a **47,14 %**, y la empresa de 125,00 % a **86,13 %**. El semáforo de la clase 23 se pone **rojo**. Nadie abrió una medida.

---

# Cuál va activa

La activa es **la que contesta por omisión**: la usan `[Kilos]`, `[Meta]`, el `TOTALYTD`, los roles, el semáforo, todo lo que ya existe.

<br>

| Pregunta | Qué fecha | Cómo |
|---|---|---|
| ¿cuánto se cosechó? ¿cumplimos la meta? | `fecha` | la relación **activa** |
| ¿cuánto se entregó? ¿cuánto se cobra? | `fecha_entrega` | `USERELATIONSHIP` en **la medida** |

<br>

La meta se fijó **por cosecha**: la activa es `fecha`. **Regrésala:** desactiva `fecha_entrega` y activa `fecha`. La tabla vuelve a **125,00 %**.

> Otra salida, cuando se necesitan **segmentadores por las dos fechas a la vez**: una segunda tabla de calendario solo para la entrega. Hoy no se arma.

---

# El error que sí avisa

Si la relación con `fecha_entrega` **no está dibujada**, la medida con `USERELATIONSHIP` **no se guarda**: Power BI dice que esas dos columnas no forman una relación.

<br>

| Qué falta | Qué pasa |
|---|---|
| la relación con `fecha_entrega` | **error** al guardar la medida |
| `USERELATIONSHIP` en la medida | nada: la medida suma **por `fecha`** |

<br>

> El error con mensaje es el de la relación que falta. El caro es el de la medida que **no la pidió**.

---

# Días a la entrega

Las dos fechas también sirven **dentro de la misma fila**, sin relaciones:

```
Dias a la entrega = AVERAGEX( h_cosecha , DATEDIFF( h_cosecha[fecha] , h_cosecha[fecha_entrega] , DAY ) )
```

| Cultivo | `[Dias a la entrega]` |
|---|---|
| Mango | 2 |
| Guayaba | 2 |
| Maiz | 12 |
| Cacao | 27 |
| **Total** | **8,67** |

<br>

> Un promedio de 8,67 días **no es de ningún cultivo**: es un promedio **por cosecha**, y seis de las nueve son fruta. Antes de leer un promedio, pregunta **entre qué** se dividió.

---

# La prueba de dos fechas

| Qué revisas | Qué atrapa |
|---|---|
| pon las dos medidas **lado a lado por mes**: ¿son idénticas? | la medida que no pidió la relación |
| en la vista de modelo, ¿cuál línea es **continua**? | la activa que alguien cambió |
| la tabla por finca de siempre, ¿sigue en **125,00 %**? | el cambio de activa que movió todo |
| quita el segmentador de mes: ¿**enero** y **mayo** aparecen? | que la medida sí va por la entrega |

<br>

> **Si dos fechas cuentan lo mismo en todos los meses, una de las dos no se está usando.**

---

# Los errores que van a ver hoy

| Síntoma | Qué pasó | Arreglo |
|---|---|---|
| `[Kilos entregados]` igual a `[Kilos]` | la medida no pide la relación | `USERELATIONSHIP` dentro de `CALCULATE` |
| error al guardar la medida | la relación con `fecha_entrega` no está dibujada | dibújala: sale punteada |
| **todo** cambió: 86,13 % | la activa quedó en `fecha_entrega` | Administrar relaciones: activa `fecha` |
| la relación con `fecha_entrega` sale **continua** | se dibujó **antes** que la de `fecha` | desactívala y activa la de `fecha` |
| no deja crear la relación | `fecha_entrega` quedó como **texto** | cambia el tipo a **Fecha** |
| Power BI creó relaciones solo | la detección automática quedó prendida | bórralas y dibuja las cinco (clase 24) |

---

<!-- _class: lead -->

# La idea del día

## Dos fechas, un calendario: si la medida no dice por cuál camino va, va por el de siempre.

<br>

`[Kilos entregados]` salió **idéntica** a `[Kilos]` porque la relación con `fecha_entrega` estaba dibujada, pero **inactiva**. Con `USERELATIONSHIP` dice **21 050**; y activar la otra relación, en vez de pedirla, movió **todo** el tablero a 86,13 %.

<br>

**Práctica:** arma el modelo, dibuja la segunda relación, cae en la medida obvia, arréglala con `USERELATIONSHIP`, cambia la activa para ver qué se mueve y regrésala.

**Y `[Kilos entregados]` de enero a abril tiene que decir 21 050, no 30 550.**
