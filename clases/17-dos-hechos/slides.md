---
marp: true
paginate: true
theme: default
title: "Clase 17 · La meta que no sabe de cultivos"
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
footer: "Curso de SQL · AgroDB · Clase 17"
---

<!-- _class: lead -->

# La meta que no sabe de cultivos

## Dos tablas de hechos, dos granularidades, y una medida que se calla

Clase 17 · 9 de septiembre

---

# Lo que llega hoy

Un quinto archivo: **`h_meta.csv`**. La meta de kilos que la gerencia fijó para 2026.

<br>

| | `h_cosecha` | `h_meta` |
|---|---|---|
| Qué guarda | lo que pasó | lo que se prometió |
| Filas | 25 | **36** |
| Una fila es… | una cosecha | **un mes de una finca** |
| Tiene fecha | sí, el día exacto | sí, **el día 1 del mes** |
| Tiene finca | sí | sí |
| Tiene cultivo | **sí** | **no** |

<br>

> La meta anual suma **47 000 kilos**, que es exactamente lo que se cosechó en 2025. No es pereza del ejemplo: **así se fija una meta cuando lo único que hay es el año pasado.**

---

# Dos hechos en la misma estrella

La clase 14 dejó una tabla de hechos rodeada de dimensiones. Hoy son **dos**, y comparten las dimensiones que pueden compartir:

```
dim_tiempo   ──►  h_cosecha          dim_tiempo   ──►  h_meta
dim_finca    ──►  h_cosecha          dim_finca    ──►  h_meta
dim_cultivo  ──►  h_cosecha          dim_cultivo       (nada)
```

<br>

Cinco relaciones, no seis. **La que falta no se puede crear**: `h_meta` no tiene columna de cultivo, porque la meta se fijó por finca.

<br>

> Esto no es un defecto del ejemplo. **Es lo normal**: los presupuestos casi nunca se capturan al mismo detalle que la operación. Se fijan por sucursal, por región, por mes. Y después alguien los quiere ver por producto.

---

# Cómo se cuelga un hecho mensual de un calendario diario

`dim_tiempo` tiene **un día por fila**. `h_meta` tiene **un mes por fila**. No se pueden relacionar así nada más.

<br>

La solución estándar, y la que trae el CSV: la meta de marzo lleva **`fecha_mes = 2026-03-01`**.

<br>

| `meta_id` | `finca_id` | `fecha_mes` | `kg_meta` |
|---|---|---|---|
| 7 | 1 | 2026-03-01 | 3 000 |
| 8 | 2 | 2026-03-01 | 2 500 |
| 9 | 3 | 2026-03-01 | 1 400 |

<br>

> Funciona, y hay que saber **con qué se paga**: la meta del mes entero queda pegada al día 1. Al nivel de mes suma bien; al nivel de día, miente de forma. Guarden ese cabo, que se jala en veinte minutos.

---

# Las dos medidas del día

```
Meta         = SUM( h_meta[kg_meta] )
Cumplimiento = DIVIDE( [Kilos] , [Meta] )
```

<br>

`[Meta]` es la primera medida del curso que **no lee `h_cosecha`**. `[Cumplimiento]` es la primera que **cruza las dos tablas de hechos**: el numerador sale de una y el denominador de la otra.

<br>

Y sin ningún filtro puesto, la tarjeta dice:

## **165,00 %**

> Setenta y siete mil quinientos cincuenta kilos contra cuarenta y siete mil de meta. **Dos años de cosecha contra la meta de un año.** El error de ayer, otra vez, en una medida que nació hace treinta segundos.

---

# La misma medida, tres contextos

| Filtros | Kilos | Meta | `[Cumplimiento]` |
|---|---|---|---|
| ninguno | 77 550 | 47 000 | **165,00 %** |
| `anio` = 2026 | 30 550 | 47 000 | **65,00 %** |
| `anio` = 2026 y `mes` en 1–4 | 30 550 | 24 440 | **125,00 %** |

<br>

Y ese **65,00 %** ya lo conocen: ayer lo escribieron como **−35,00 %**. Es la misma división. *Cumplí el 65 % de la meta* y *caí 35 % contra el año pasado* **son el mismo número** cuando la meta es el año pasado.

<br>

> Esto lo arreglaron ayer y hoy les tomó dos minutos. **Perfecto: no es el error de hoy.** El de hoy todavía no se ve.

---

# Por finca: funciona

Segmentador `anio` = 2026 y `mes` en 1–4. Tabla con `dim_finca[finca]`:

<br>

| Finca | `[Kilos]` | `[Meta]` | `[Cumplimiento]` |
|---|---|---|---|
| Agricola La Union | 2 100 | 5 000 | **42,00 %** |
| Finca El Guayabo | 14 250 | 9 440 | **150,95 %** |
| Hacienda Santa Rosa | 14 200 | 10 000 | **142,00 %** |
| **Total** | **30 550** | **24 440** | **125,00 %** |

<br>

Fíjense en la columna de la meta: **5 000 + 9 440 + 10 000 = 24 440**. Se parte entre las tres fincas y suma su propio total.

> Es lo que uno espera de una columna, y por eso nadie lo mira. **Míralo hoy, que es la última vez que se va a portar bien.**

---

# Y ahora por cultivo

Misma tabla, mismos filtros, misma medida. Solo cambia la dimensión de las filas:

| Cultivo | `[Kilos]` | `[Meta]` | `[Cumplimiento]` |
|---|---|---|---|
| Banano | *(vacío)* | **24 440** | *(vacío)* |
| Cacao | 2 100 | **24 440** | 8,59 % |
| Cafe | *(vacío)* | **24 440** | *(vacío)* |
| Guayaba | 5 950 | **24 440** | 24,35 % |
| Maiz | 9 800 | **24 440** | 40,10 % |
| Mango | 12 700 | **24 440** | 51,96 % |
| **Total** | **30 550** | **24 440** | **125,00 %** |

> *«Ningún cultivo llega a la meta.»* Esa frase se dice sola al ver esta tabla. Y es mentira: **no hay ninguna meta por cultivo.**

---

# ¿Y qué error dio?

## Ninguno. Van cuatro clases seguidas.

<br>

- Las cinco relaciones están bien hechas, todas muchos a uno.
- `dim_tiempo` sigue marcada como tabla de fechas.
- La meta suma **24 440** en el total, que es correcto.
- Los kilos por cultivo suman **30 550**, que es correcto.
- Ninguna celda está en rojo, ninguna advertencia, ningún triángulo amarillo.

<br>

**Y dos filas nuevas:** Banano y Café, que no han cosechado **un solo kilo en dos años**, aparecen hoy en la tabla con una meta de 24 440 kilos cada uno.

> En la clase 15 esos dos cultivos no salían en ningún visual. Hoy salen. **La medida rota es la que los invitó.**

---

# La trampa aguanta una revisión

Alguien prudente revisa que los porcentajes cuadren:

<br>

| | |
|---|---|
| 51,96 + 24,35 + 40,10 + 8,59 | **125,00** |
| Total de la tabla | **125,00 %** |

<br>

**Cuadra exacto.** Porque todos los porcentajes se dividieron entre el mismo número, y las partes de arriba sí suman el total de arriba.

<br>

> Por eso este error es peor que los de las clases pasadas: **la comprobación obvia lo aprueba.** Si sumas la columna de la meta, en cambio, te salen **146 640 kilos** de meta anual en una empresa que se propuso 47 000.

---

# Cómo se detecta

Una medida de una línea, al lado de la que ya tienen:

```
Filas de meta = COUNTROWS( h_meta )
```

| Cultivo | `[Cosechas]` | `[Filas de meta]` |
|---|---|---|
| Banano | *(vacío)* | **12** |
| Cacao | 2 | **12** |
| Cafe | *(vacío)* | **12** |
| Guayaba | 3 | **12** |
| Maiz | 1 | **12** |
| Mango | 3 | **12** |
| **Total** | **9** | **12** |

> Nueve cosechas repartidas en cuatro filas. Doce metas **enteras en las seis**. Es el «6 contra 4» de la clase 15 y el «31/12 contra 30/04» de la 16: **dos conteos que deberían comportarse igual y no lo hacen.**

---

# La regla, y va al cuaderno

## Si una medida vale lo mismo en todas las filas, esa dimensión no le llega.

<br>

No es un empate. No es casualidad. **Es que no hay relación**, y lo que estás viendo repetido es el total disfrazado de detalle.

<br>

La comprobación cabe en una frase: **pon la medida cruda al lado del porcentaje.** El porcentaje sabe disimular; la columna que lo alimenta, no.

<br>

> Y al revés también sirve: si una columna **sí** se parte y **sí** suma su total, esa dimensión sí le llega. Eso fue la tabla por finca de hace cinco minutos.

---

# Por qué se repite

El filtro viaja por las relaciones, **y solo por las relaciones**:

```
dim_cultivo  ──►  h_cosecha            [Kilos] se parte    ✔
dim_cultivo  ──►  ??? ──►  h_meta      no hay camino       ✘
```

<br>

Cuando filtras por Mango, `h_cosecha` se queda con tres filas. **`h_meta` no se entera de nada**: sigue con sus doce filas y sus 24 440 kilos, y contesta lo mismo que contestaría sin filtro.

<br>

> Una medida sin filtro que la alcance **no se queja: devuelve el total.** Es lo mismo que hace `[Kilos]` en la fila de Total, con la diferencia de que ahí sí lo esperábamos.

---

# El arreglo que empeora las cosas

Alguien va a proponerlo hoy, y hay que verlo venir: **prender el filtro cruzado bidireccional** entre `dim_finca` y `h_cosecha`.

<br>

Con eso el filtro de cultivo llega a `h_meta` dando la vuelta por la finca, y la columna **deja de repetirse**. Se ve arreglada.

<br>

Lo que estarías diciendo es: *«la meta de una finca es la meta de todos los cultivos que esa finca sembró»*. Que no es cierto, y ahora **cada fila trae un número distinto y plausible**.

> Cambiaste un error que se detecta —una columna repetida— por uno que no. **Nunca prendas el bidireccional para tapar un número raro.** Es el arreglo que borra la evidencia.

---

# La medida que se calla

El arreglo de verdad es aceptar que **hay preguntas que esta medida no puede contestar**, y decirlo:

```
Meta valida = IF(
    ISFILTERED( dim_cultivo[cultivo] ) || ISFILTERED( dim_tiempo[fecha] ),
    BLANK(),
    [Meta]
)

Cumplimiento valido = DIVIDE( [Kilos] , [Meta valida] )
```

<br>

`ISFILTERED` contesta una sola cosa: **¿alguien está filtrando esta columna ahora mismo?** Ponerla en las filas de una matriz cuenta. Un segmentador también.

> Si te preguntan la meta a un detalle al que la meta no se capturó, la respuesta honesta **no es un número: es nada.**

---

# Así se ve una medida que se calla

Misma matriz por cultivo, con las medidas nuevas:

<br>

| Cultivo | `[Kilos]` | `[Meta valida]` | `[Cumplimiento valido]` |
|---|---|---|---|
| Cacao | 2 100 | *(vacío)* | *(vacío)* |
| Guayaba | 5 950 | *(vacío)* | *(vacío)* |
| Maiz | 9 800 | *(vacío)* | *(vacío)* |
| Mango | 12 700 | *(vacío)* | *(vacío)* |
| **Total** | **30 550** | **24 440** | **125,00 %** |

<br>

Banano y Café **desaparecieron**: ya no hay ninguna medida que los sostenga.

> Una columna vacía con un total lleno se ve rara, y **tiene que verse rara**. Está diciendo: *por finca sí, por cultivo no.* Un tablero que no puede contestar algo debería incomodar, no inventar.

---

# El otro lado de la granularidad

Pon `dim_tiempo[fecha]` en el eje y filtra marzo de 2026:

<br>

| Día | `[Kilos]` | `[Meta]` |
|---|---|---|
| 01/03/2026 | *(vacío)* | **6 900** |
| 20/03/2026 | 4 200 | *(vacío)* |
| 22/03/2026 | 5 400 | *(vacío)* |
| 28/03/2026 | 1 200 | *(vacío)* |
| **Marzo** | **10 800** | **6 900** |

<br>

La meta del mes entero aparece **el día 1**, como si ese día se hubieran esperado 6 900 kilos. Y `[Cumplimiento]` **no contesta nada útil ningún día del mes** —los días con cosecha no tienen meta—, mientras el total dice **156,52 %**.

> El total está bien. El detalle es una caricatura. **Mismo problema, otra dimensión.**

---

# Una se defiende sola y la otra no

<br>

| Por el lado del **tiempo** | Por el lado del **cultivo** |
|---|---|
| la relación existe pero no llega al día | **no hay relación** |
| bajo del mes, la meta se queda vacía | la meta **se repite** |
| el número desaparece | el número **se multiplica** |
| se nota | **no se nota** |

<br>

Cuando la relación existe y no alcanza, el motor deja el hueco a la vista. Cuando **no hay relación**, el motor devuelve el total con toda naturalidad.

> Por eso hay que escribir el `BLANK()` a mano. **El silencio no viene de fábrica: hay que ponerlo.**

---

# Los errores que van a ver hoy

| Síntoma | Qué pasó | Arreglo |
|---|---|---|
| `[Meta]` da 47 000 en todas las filas de finca | falta la relación con `dim_finca` | vista Modelo, muchos a uno |
| Aparece una fila en blanco en la meta | `fecha_mes` no se leyó como Fecha | tipo de la columna en Power Query |
| `[Cumplimiento]` da 165,00 % | no hay filtro de año | es correcto, y por eso asusta |
| `[Cumplimiento]` sale vacío en 2025 | **no hay meta de 2025** | no es un error |
| `[Meta]` repetida por cultivo | `h_meta` no tiene cultivo | `[Meta valida]` |
| La meta ya no se repite y cada fila es distinta | prendieron el bidireccional | apáguenlo |
| La meta aparece toda el día 1 | granularidad de mes | no se lee al nivel de día |
| `[Cumplimiento valido]` vacío **también** por finca | la condición del `IF` está de más | solo cultivo y fecha |
| Los seis cultivos aparecen de repente | los sostiene `[Meta]` | es el síntoma, no el error |

---

<!-- _class: lead -->

# La idea del día

## Si nada avisa, el aviso lo escribes tú.

<br>

Llevamos once clases con la misma columna: *qué avisó — nada*. Hoy se acaba, y no porque la herramienta haya mejorado. **Se acaba porque el aviso lo escribimos nosotros, en la medida, con un `BLANK()`.**

<br>

**Práctica:** conecta la segunda tabla de hechos, provoca la meta repetida, atrápala con `[Filas de meta]` y **haz que la medida se calle** donde no puede contestar.

**Y el `[Kilos]` de 2026 tiene que seguir diciendo 30 550.**
