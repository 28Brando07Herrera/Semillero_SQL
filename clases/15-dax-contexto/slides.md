---
marp: true
paginate: true
theme: default
title: "Clase 15 · La medida y el contexto"
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
footer: "Curso de SQL · AgroDB · Clase 15"
---

<!-- _class: lead -->

# La medida y el contexto

## DAX, contexto de filtro, y el denominador que nadie mira

Clase 15 · 4 de septiembre

---

# Hoy no se prende Oracle

Y no es una concesión: es el punto.

<br>

Dos clases seguidas peleando con el motor —el contenedor, el puerto, el driver, los `GRANT`— y hoy nada de eso se toca. **La fuente de datos de hoy son cuatro archivos CSV.**

<br>

| Ayer | Hoy |
|---|---|
| Oracle en un contenedor | cuatro archivos en `C:\agrodb\csv\` |
| OCMT, `GRANT`, `bi_agro` | **Obtener datos → Texto/CSV** |
| El modelo se construye con SQL | el modelo **ya está**, y es el mismo |

> Cambiar la fuente y que el tablero no se entere **es la prueba de que el modelo estaba bien hecho.** Un tablero no depende del motor: depende del modelo.

---

# Lo que ya está armado

Los cuatro archivos son la estrella de ayer, exportada tal cual:

| Archivo | Qué es | Filas |
|---|---|---|
| `dim_finca.csv` | dimensión | 3 |
| `dim_cultivo.csv` | dimensión | 6 |
| `dim_tiempo.csv` | dimensión (2026 completo) | 365 |
| `h_cosecha.csv` | **el hecho** | 9 |

<br>

Los kilos siguen siendo **30 550**, y el desglose por finca sigue siendo **14 250 / 14 200 / 2 100**.

> El calendario de hoy viene con los **365 días**, ya arreglado. El 19 750 de ayer no vuelve. Hoy el número se va a equivocar por otro lado.

---

# Lo que arrastraste ayer ya era DAX

Cuando pusiste `kg` en el gráfico y Power BI escribió **«Suma de kg»**, no fue un botón. Fue esta fórmula, escrita por él:

```
SUM(h_cosecha[kg])
```

<br>

Eso se llama **medida implícita**: existe mientras el campo esté en ese visual, no tiene nombre propio y no se puede reusar.

<br>

| | Implícita | Explícita |
|---|---|---|
| Quién la escribe | Power BI | tú |
| Dónde vive | dentro del visual | en el modelo |
| ¿Se puede reusar? | no | sí |
| ¿Se puede meter dentro de otra? | **no** | sí |

> Esa última fila es la que va a doler en veinte minutos.

---

# La primera medida escrita a mano

**Inicio → Nueva medida**, y en la barra de fórmulas:

```
Kilos = SUM(h_cosecha[kg])
```

<br>

Tres detalles que no son adorno:

1. El nombre va **antes** del `=`, y es el nombre que va a salir en el visual.
2. La medida **no pertenece a una columna**: pertenece al modelo. Se guarda dentro de una tabla porque hay que guardarla en algún lado.
3. `h_cosecha[kg]` lleva **tabla y columna**. Una medida se escribe `[Kilos]`, **sin tabla**. Se lee de un vistazo cuál es cuál.

<br>

> Ahora quita `kg` del gráfico y pon `[Kilos]` en su lugar. **Tiene que verse exactamente igual.**

---

# Punto de control

Barras: **Eje Y** `dim_finca[finca]` · **Valores** `[Kilos]`

<br>

| Finca | Kilos |
|---|---|
| Finca El Guayabo | **14 250** |
| Hacienda Santa Rosa | **14 200** |
| Agricola La Union | **2 100** |
| **Total** | **30 550** |

<br>

> El mismo número desde la clase 5, ahora pasando por un CSV y por una medida escrita a mano. **Si aquí no da 30 550, no sigas: algo se rompió al cargar.**

---

# ¿Para qué escribirla, si arrastrar funcionaba?

| | Arrastrar `kg` | Escribir `[Kilos]` |
|---|---|---|
| En diez visuales | diez veces lo mismo | una definición |
| Cambiar la regla | diez cambios | uno |
| Ponerle formato | visual por visual | una vez |
| Meterla adentro de otra fórmula | **imposible** | natural |

<br>

La cuarta fila es la única que importa de verdad. Todo lo que sigue —porcentajes, promedios, comparaciones— es **una medida que usa otra medida adentro**.

> Regla de la casa, desde hoy: **si un número va a aparecer en un visual, es una medida.** Aunque sea un `SUM` de una sola línea.

---

# Medida o columna calculada

Las dos se escriben en DAX y ahí se acaba el parecido.

| | **Columna calculada** | **Medida** |
|---|---|---|
| Cuándo se calcula | al cargar o actualizar | **al dibujar cada celda** |
| Qué ve | **una fila** | un conjunto de filas |
| Dónde se guarda | ocupa espacio en el modelo | no ocupa nada |
| ¿Reacciona al segmentador? | **no**, ya está calculada | **sí**, se recalcula |
| ¿Se puede poner en un eje? | sí | no |

<br>

> Una columna calculada es **un dato más** de la tabla. Una medida es **una pregunta** que se contesta cada vez que la miras.

---

# La regla de las dos preguntas

Es la misma regla de ayer, con otras palabras.

<br>

| Si el resultado… | Entonces es… |
|---|---|
| tiene sentido **sumarlo** | una **medida** |
| tiene sentido **agruparlo o filtrarlo** | una **columna** |

<br>

Ayer decía así: *si tiene sentido sumarla es un hecho, si tiene sentido ponerla en un `GROUP BY` es una dimensión.*

<br>

> Es la misma frase. **Hecho y dimensión del lado de la base; medida y columna del lado del tablero.** Quien entendió una entiende la otra.

---

# Una medida no tiene un valor

Esta es la idea que cuesta, y es toda la clase.

<br>

`[Kilos]` **no vale 30 550.** No vale nada por sí sola.

<br>

`[Kilos]` es una instrucción: *«suma la columna `kg` de las filas que queden después de aplicar los filtros»*. Y los filtros cambian **en cada celda de cada visual**.

<br>

> El conjunto de filtros que aplica en el momento de evaluar se llama **contexto de filtro**. No es jerga: es el nombre de lo único que hay que mirar cuando un número no cuadra.

---

# El mismo DAX, cuatro resultados

Una sola medida, `[Kilos]`, evaluada **cuatro veces** en la misma tabla:

| Fila del visual | Contexto de filtro | Resultado |
|---|---|---|
| Finca El Guayabo | `finca = "Finca El Guayabo"` | 14 250 |
| Hacienda Santa Rosa | `finca = "Hacienda Santa Rosa"` | 14 200 |
| Agricola La Union | `finca = "Agricola La Union"` | 2 100 |
| **Total** | **ningún filtro de finca** | **30 550** |

<br>

**El total no es la suma de las tres celdas de arriba.** Es una cuarta evaluación, sin el filtro de finca. Con `SUM` da lo mismo de casualidad; con un promedio o un porcentaje, **no**.

> Y si además hay un segmentador de cultivo puesto en «Mango», las cuatro celdas se recalculan con **ese filtro encima**.

---

# `CALCULATE`

Es la única función de DAX que **cambia** el contexto de filtro. Con eso ya sabes por qué aparece en todas las fórmulas del mundo.

```
CALCULATE( <la expresión> , <filtro> , <filtro> , ... )
```

<br>

| Escribes | Significa |
|---|---|
| `CALCULATE([Kilos], dim_cultivo[cultivo]="Mango")` | *lo que valga `[Kilos]`, pero sólo Mango* |
| `CALCULATE([Kilos], ALL(dim_finca))` | *lo que valga `[Kilos]`, **ignorando** el filtro de finca* |

<br>

> `ALL` no significa «todo». Significa **«quita ese filtro»**. Es la diferencia entre *cuánto llevo yo* y *cuánto lleva el total*, y sin eso no hay un solo porcentaje bien escrito.

---

# Primer intento: el % del total

Se escribe lo obvio, y lo obvio está mal:

```
% del total = DIVIDE( [Kilos] , [Kilos] )
```

<br>

| Finca | Kilos | % del total |
|---|---|---|
| Finca El Guayabo | 14 250 | **100,00 %** |
| Hacienda Santa Rosa | 14 200 | **100,00 %** |
| Agricola La Union | 2 100 | **100,00 %** |

<br>

**Las dos `[Kilos]` se evalúan en el mismo contexto de filtro.** En la fila de El Guayabo, la de arriba vale 14 250 y la de abajo también. Catorce mil doscientos cincuenta entre catorce mil doscientos cincuenta.

> Este error **sí se ve**. Anótalo: es el único de hoy que se ve.

---

# `ALL`: la versión correcta

Al denominador hay que quitarle el filtro de finca:

```
% del total =
DIVIDE( [Kilos] , CALCULATE( [Kilos] , ALL(dim_finca) ) )
```

<br>

| Finca | Kilos | % del total |
|---|---|---|
| Finca El Guayabo | 14 250 | **46,64 %** |
| Hacienda Santa Rosa | 14 200 | **46,48 %** |
| Agricola La Union | 2 100 | **6,87 %** |

<br>

> **`DIVIDE` y no `/`.** Si el denominador da cero, `/` devuelve un error de infinito y `DIVIDE` devuelve vacío. Un vacío se ve en la tarjeta; un infinito se mete en la siguiente cuenta.

---

# Y ahora la trampa del día

Pregunta de negocio, de las que llegan por correo:

## *«¿Cuántos kilos da en promedio cada cultivo?»*

<br>

Se escribe lo natural: los kilos totales entre cuántos cultivos hay.

```
Kilos promedio por cultivo =
DIVIDE( [Kilos] , COUNTROWS(dim_cultivo) )
```

<br>

Y la tarjeta dice: **5 091,67**

<br>

> Nadie va a discutir ese número. Es defendible, se explica en una junta en diez segundos, y **está mal**.

---

# ¿Y qué error dio?

## Ninguno.

<br>

- La medida se guardó sin una advertencia.
- El modelo está bien: las tres relaciones, correctas.
- El calendario está completo, los 365 días.
- Las nueve cosechas están cargadas y `[Kilos]` sigue dando **30 550**.
- La tarjeta se dibujó y se ve preciosa.

<br>

**`dim_cultivo` tiene 6 filas y sólo 4 cultivos cosecharon algo.** Banano y Café nunca produjeron un kilo, y están en el denominador repartiéndose kilos que no cosecharon.

> 30 550 entre **6** en vez de entre **4**. El promedio de verdad es **la mitad más alto**.

---

# Cómo se detecta

La pregunta no es «¿está bien el promedio?». Es **«¿entre cuántos dividí?»**.

El denominador se saca a la pantalla, como una medida más:

```
Cultivos en la dimension = COUNTROWS(dim_cultivo)
Cultivos con cosecha     = DISTINCTCOUNT(h_cosecha[cultivo_id])
```

<br>

| Medida | Valor |
|---|---|
| Cultivos en la dimensión | **6** |
| Cultivos con cosecha | **4** |

<br>

> Ahí está el hallazgo, en dos números. **Es el `LEFT JOIN … IS NULL` de la clase 5 y la consulta de control de la clase 14**, con otra ropa: dos conteos que deberían coincidir y no coinciden.

---

# La versión correcta

```
Kilos promedio por cultivo =
DIVIDE( [Kilos] , DISTINCTCOUNT(h_cosecha[cultivo_id]) )
```

<br>

Y la tarjeta dice: **7 637,50**

<br>

| Denominador | Promedio | ¿Qué contesta? |
|---|---|---|
| 6 · cultivos que existen | 5 091,67 | *cuánto tocaría por cultivo si repartiéramos* |
| **4 · cultivos que cosecharon** | **7 637,50** | ***cuánto rinde un cultivo que produce*** |

<br>

> Y fíjate en lo incómodo: **las dos contestan una pregunta.** La primera contesta una que nadie hizo.

---

# Ayer les dije que estaba bien

Ayer, hablando de `dim_cultivo` con Banano y Café sin cosechas, la frase fue esta:

> *«Que la dimensión tenga filas que el hecho no usa está bien.»*

<br>

Y es cierto: **está bien para agrupar y para filtrar.** Un reporte que muestra «Café: 0 kg» es mejor que uno que esconde el Café.

<br>

**Deja de estar bien en el momento exacto en que esa dimensión entra en un denominador.**

<br>

> La regla del día, y va al cuaderno: **toda medida que divide lleva su denominador al lado, como medida propia, hasta que le creas.** Se quita después, si se quita.

---

# Los errores que van a ver hoy

| Síntoma | Qué pasó | Arreglo |
|---|---|---|
| Todos los porcentajes dicen 100 % | numerador y denominador en el mismo contexto | `CALCULATE(..., ALL(...))` en el denominador |
| El promedio sale **5 091,67** | el denominador cuenta filas de la dimensión | `DISTINCTCOUNT` sobre el hecho |
| La medida no reacciona al segmentador | es una **columna calculada**, no una medida | reescríbela como medida |
| `[Kilos]` da 30 550 en **todas** las filas | falta la relación, o está al revés | vista **Modelo**, muchos a uno hacia la dimensión |
| Los kilos salen inflados | la relación quedó en la columna equivocada | revisa que sea `finca_id` contra `finca_id` |
| `kg` llegó como texto | el CSV se cargó con otra configuración regional | Power Query → tipo **Número entero** |
| `fecha` llegó como texto | lo mismo, con la fecha | tipo **Fecha**, y el CSV viene en `AAAA-MM-DD` |
| La tarjeta dice «30,55 mil» | unidades de presentación automáticas | Formato → Unidades de presentación: **Ninguna** |

---

<!-- _class: lead -->

# La idea del día

## Una medida mal escrita no da error. Da un número que se puede defender.

<br>

Hoy el modelo estaba bien, las relaciones estaban bien, los 30 550 kilos estaban completos, y la tarjeta decía **5 091,67**.

<br>

**Práctica:** escribe las medidas, provoca el 5 091,67 a propósito, saca el denominador a la pantalla y arréglalo.

**El número que tiene que salir es 7 637,50. Y `[Kilos]` sigue siendo 30 550.**
