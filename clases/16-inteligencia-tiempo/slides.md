---
marp: true
paginate: true
theme: default
title: "Clase 16 · Comparar contra el año pasado"
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
footer: "Curso de SQL · AgroDB · Clase 16"
---

<!-- _class: lead -->

# Comparar contra el año pasado

## Inteligencia de tiempo, y el año que todavía no termina

Clase 16 · 8 de septiembre

---

# Lo que cambió desde ayer

Llegó el histórico. La campaña **2025** por fin está cargada.

<br>

| | Ayer | Hoy |
|---|---|---|
| `h_cosecha` | 9 filas | **25 filas** |
| Años | solo 2026 | **2025 y 2026** |
| `dim_tiempo` | 365 días | **730 días** |

<br>

Las 16 filas nuevas no salieron del sistema operativo de AgroDB: **el operativo arranca en 2026**. Son histórico, y el histórico es exactamente lo que un almacén guarda y un sistema de captura tira.

> Los `cosecha_id` del histórico van del **10 al 25**, no del 1 al 16. El id es orden de carga, no orden de calendario. Ese detalle incomoda y está bien que incomode.

---

# El 30 550 ya no es el total

Por primera vez en once clases, **el número de siempre deja de ser el total**.

<br>

| Medida | Valor |
|---|---|
| `[Kilos]`, sin filtros | **77 550** |
| `[Kilos]` con `anio = 2026` | **30 550** ← el de siempre |
| `[Kilos]` con `anio = 2025` | **47 000** |
| `[Cosechas]` | **25** = 9 + 16 |

<br>

> No se perdió nada y no se rompió nada. **El 30 550 sigue exacto, ahora vive adentro de un total más grande.** Y esa es la primera cosa que hay que comprobar hoy antes de escribir una sola medida.

---

# El calendario de ayer ya no alcanza

Si cargas el `dim_tiempo.csv` de la clase pasada —el de 365 días, solo 2026— y encima le pones las 25 cosechas:

<br>

| | |
|---|---|
| ¿Da error? | **no** |
| ¿Se pierden kilos del total? | **no**, siguen siendo 77 550 |
| ¿Dónde quedan las 16 filas de 2025? | en una fila **en blanco** de la relación |

<br>

Power BI no tira las filas cuya fecha no existe en la dimensión. Las manda a una fila sin nombre, que en la mayoría de los visuales **no se ve**.

> Es el golpe de la clase 14 con otra ropa: allá el calendario no cubría marzo y el tablero decía 19 750. **Hoy el calendario cubre dos años porque el hecho cubre dos años.** Un calendario se dimensiona por el hecho, no por el año en curso.

---

# Marcar como tabla de fechas

Dos pasos que no son adorno, y los dos van hoy en la parte A:

<br>

**1. Apagar la fecha/hora automática.**
`Archivo → Opciones → Carga de datos → Inteligencia de tiempo`

Power BI fabrica un calendario oculto por cada columna de fecha. Tenemos el nuestro. Dos calendarios compitiendo es la receta del número raro.

<br>

**2. Marcar `dim_tiempo` como tabla de fechas**, con la columna `fecha`.

<br>

> Sin ese paso, `TOTALYTD` y `SAMEPERIODLASTYEAR` pueden contestar cualquier cosa. **Es el único requisito técnico del día**, y se hace una vez.

---

# Abril va antes que Marzo

Pon `dim_tiempo[nombre_mes]` en un eje y mira el orden:

<br>

**Abril · Agosto · Diciembre · Enero · Febrero · Julio · Junio · Marzo · Mayo · Noviembre · Octubre · Septiembre**

<br>

Es texto. El texto se ordena alfabéticamente, y **alfabéticamente Abril va primero**.

<br>

Se arregla en un menú: selecciona la columna `nombre_mes`, **Herramientas de columnas → Ordenar por columna → `mes`**.

> El número no está mal. **El orden está mal, y una serie de tiempo desordenada es una serie de tiempo inútil.** Nadie audita el eje horizontal: por eso este error vive años en los tableros.

---

# El eje sale del calendario, no del hecho

Los dos ejes existen. Los dos «funcionan». No dicen lo mismo:

<br>

| Eje | Qué meses dibuja |
|---|---|
| `h_cosecha[fecha]` | **solo los meses que tuvieron cosecha** |
| `dim_tiempo[anio_mes]` | **los 24 meses**, con o sin cosecha |

<br>

Con el eje del hecho, 2026 se dibuja con **dos puntos**: marzo y abril. La gráfica sube y se ve sanísima. Los diez meses en cero **no existen** en ese eje.

<br>

> Regla, y va al cuaderno: **el eje de tiempo sale siempre de la dimensión de tiempo.** Para eso se construyó. Un mes sin ventas es información; un mes que no aparece es un mes que nadie va a preguntar.

---

# El acumulado

La primera función de inteligencia de tiempo, y es de una línea:

```
Kilos YTD = TOTALYTD( [Kilos] , dim_tiempo[fecha] )
```

<br>

*YTD* es *year to date*: **del 1 de enero de ese año hasta el último día del contexto actual.**

<br>

| En la celda de… | `TOTALYTD` suma desde… | hasta… |
|---|---|---|
| Marzo 2026 | 1 de enero de 2026 | 31 de marzo de 2026 |
| Abril 2026 | 1 de enero de 2026 | 30 de abril de 2026 |
| Diciembre 2026 | 1 de enero de 2026 | 31 de diciembre de 2026 |

> Vuelve a ser lo de ayer: **una medida, un valor por celda.** Lo único que hace `TOTALYTD` es estirar el contexto de filtro hacia atrás, hasta el 1 de enero.

---

# Punto de control

Matriz: filas `dim_tiempo[anio]` y `dim_tiempo[nombre_mes]` · valores `[Kilos]` y `[Kilos YTD]`

<br>

| Año | Mes | `[Kilos]` | `[Kilos YTD]` |
|---|---|---|---|
| 2026 | Marzo | 10 800 | **10 800** |
| 2026 | Abril | 19 750 | **30 550** |
| 2026 | Mayo … Diciembre | *(vacío)* | **30 550** |
| 2025 | Abril | 9 500 | **23 500** |
| 2025 | Diciembre | 1 200 | **47 000** |

<br>

> Fíjate en la fila de mayo de 2026: **`[Kilos]` está vacío y `[Kilos YTD]` dice 30 550.** El acumulado no se cae cuando el mes no tuvo cosecha: se queda quieto. Anota ese 23 500 de abril de 2025, que en diez minutos es el número del día.

---

# El año pasado, en una función

```
Kilos AA = CALCULATE( [Kilos] , SAMEPERIODLASTYEAR( dim_tiempo[fecha] ) )
```

<br>

`SAMEPERIODLASTYEAR` hace **una sola cosa**: agarra las fechas que hay en el contexto de filtro y las **mueve un año hacia atrás**.

<br>

| Si el contexto tiene… | devuelve… |
|---|---|
| abril de 2026 (30 días) | abril de 2025 (30 días) |
| todo 2026 (**365 días**) | todo 2025 (**365 días**) |

<br>

> Esa segunda fila es toda la clase de hoy, y todavía no se nota. **Mueve lo que hay en el contexto.** Ni un día más, ni un día menos.

---

# La variación

```
Variacion AA = DIVIDE( [Kilos] - [Kilos AA] , [Kilos AA] )
```

<br>

`DIVIDE` y no la diagonal, por lo mismo de ayer: si el año pasado no tuvo nada, la diagonal devuelve infinito y `DIVIDE` devuelve vacío.

<br>

Ponla en una tarjeta, con el segmentador de `anio` en **2026**, y formato de porcentaje con dos decimales.

<br>

> Esta es la medida más pedida del mundo y la más copiada de internet. Está bien escrita. **No tiene un solo error de sintaxis ni de lógica.**

---

# La tarjeta del día

Segmentador `dim_tiempo[anio]` = **2026**:

<br>

| Medida | Valor |
|---|---|
| `[Kilos]` | 30 550 |
| `[Kilos AA]` | 47 000 |
| **`[Variacion AA]`** | **−35,00 %** |

<br>

## *«La cosecha cayó 35 % contra el año pasado.»*

<br>

> Esa frase se manda por correo, se pone en una lámina y se defiende en una junta. Es aritmética correcta sobre datos completos. **Y está mal.**

---

# ¿Y qué error dio?

## Ninguno. Otra vez.

<br>

- El modelo está bien: las tres relaciones, correctas.
- El calendario está completo: los 730 días, los dos años.
- `dim_tiempo` está marcada como tabla de fechas.
- `[Kilos]` da **30 550** en 2026 y **47 000** en 2025. Nada se perdió.
- Las 25 cosechas están cargadas.
- `SAMEPERIODLASTYEAR` hizo exactamente lo que promete.

<br>

**Estamos en septiembre. El año 2026 tiene cosechas hasta el 30 de abril.**

> Comparamos **cuatro meses contra doce**. No es un error de fórmula: es un error de pregunta, y por eso ninguna herramienta lo puede avisar.

---

# Cómo se detecta

La pregunta no es «¿está bien la variación?». Es **«¿desde cuándo hasta cuándo comparé?»**.

Las dos fechas de corte se sacan a la pantalla, como dos medidas más:

```
Ultimo dia del contexto = MAX( dim_tiempo[fecha] )
Ultimo dia con cosecha  = MAX( h_cosecha[fecha] )
```

<br>

| Medida | Valor |
|---|---|
| Último día del contexto | **31/12/2026** |
| Último día con cosecha | **30/04/2026** |

<br>

> Ahí está el hallazgo, otra vez en dos números de una línea. **Es el 6 contra el 4 de ayer, con fechas en vez de conteos**: dos valores que deberían coincidir y no coinciden.

---

# Ocho meses de cero

Lo que `SAMEPERIODLASTYEAR` movió fueron **365 días**, porque 365 días había en el contexto.

<br>

| | 2026 | 2025 |
|---|---|---|
| Días en el contexto | 365 | 365 |
| Meses con cosecha | **2** | **12** |
| Kilos | 30 550 | 47 000 |

<br>

De mayo a diciembre de 2026 no hay cosecha **porque todavía no ha pasado**, no porque la finca haya fallado. Y esos ocho meses de nada entran completos en el numerador.

> El denominador de ayer contaba cultivos que no cosecharon. **El numerador de hoy cuenta meses que no han ocurrido.** Es el mismo oficio.

---

# El arreglo no es una fórmula más lista

Es lo de ayer: **recortar el contexto de filtro.**

<br>

Agrega un segmentador de `dim_tiempo[mes]` y deja **1, 2, 3 y 4**. No toques ninguna medida.

<br>

| Medida | Antes | Después |
|---|---|---|
| `[Kilos]` | 30 550 | **30 550** *(igual: no hay nada después de abril)* |
| `[Kilos AA]` | 47 000 | **23 500** |
| **`[Variacion AA]`** | **−35,00 %** | **+30,00 %** |

<br>

> **La medida nunca estuvo mal.** Estaba contestando bien una pregunta que nadie hizo. Ayer lo dijimos así: *una medida no tiene un valor.* Hoy se cobra.

---

# El signo se dio la vuelta

<br>

| | Kilos 2026 | Kilos 2025 | Variación |
|---|---|---|---|
| Año contra año | 30 550 | 47 000 | **−35,00 %** |
| A la misma fecha | 30 550 | **23 500** | **+30,00 %** |

<br>

Sesenta y cinco puntos de diferencia, **y el signo cambiado**. Una versión dice que la finca se cayó; la otra, que va creciendo a buen ritmo.

<br>

> Y la que se manda por correo es la primera, porque es la que sale de arrastrar la medida a una tarjeta y no tocar nada.

---

# La columna que baja sola

`[Variacion AA]` calculada sobre el acumulado, leída mes por mes de 2026:

<br>

| Mes de corte | 2026 YTD | 2025 YTD | Variación |
|---|---|---|---|
| Marzo | 10 800 | 14 000 | −22,86 % |
| **Abril** | **30 550** | **23 500** | **+30,00 %** ← aquí acaban los datos |
| Junio | 30 550 | 30 800 | −0,81 % |
| Septiembre | 30 550 | 41 050 | −25,58 % |
| Diciembre | 30 550 | 47 000 | **−35,00 %** |

<br>

> La tarjeta del día **no inventó nada**: estaba leyendo la fila de diciembre. El problema es que hoy es septiembre. **El año en curso se diluye solo**, un mes cada mes, sin que nadie toque el tablero.

---

# Las dos contestan una pregunta

<br>

| Comparación | ¿Qué contesta? |
|---|---|
| 30 550 contra **47 000** | *cuánto llevamos este año contra **todo** lo del año pasado* |
| 30 550 contra **23 500** | ***vamos mejor o peor que el año pasado a estas alturas*** |

<br>

La primera se contesta sola en enero, y la respuesta siempre es que vamos peor.

<br>

> Igual que ayer con los dos promedios: **las dos son ciertas.** La de arriba contesta una pregunta que nadie hizo, y encima la contesta con un número que asusta.

---

# Los errores que van a ver hoy

| Síntoma | Qué pasó | Arreglo |
|---|---|---|
| Los meses van Abril, Agosto, Diciembre… | `nombre_mes` es texto | Ordenar por columna → `mes` |
| 2026 se dibuja con dos puntos | el eje sale de `h_cosecha[fecha]` | eje desde `dim_tiempo` |
| `[Kilos AA]` sale vacío en todo | falta marcar la tabla de fechas | Marcar como tabla de fechas → `fecha` |
| `[Kilos AA]` sale vacío solo en 2025 | correcto: **2024 no existe** en el calendario | no es un error |
| Aparece una fila sin nombre | el calendario no cubre todas las fechas | los 730 días, los dos años |
| El total no da 77 550 | cargaste el `h_cosecha.csv` de la clase 15 | son los CSV de `csv_clase16` |
| `[Kilos]` da 77 550 en cada fila | falta la relación con `dim_tiempo` | vista Modelo, muchos a uno |
| La variación sale `-0,35` | falta el formato | Herramientas de medidas → **%** |
| Enero y Febrero de 2026 no aparecen | todas sus medidas están vacías | normal, no lo persigas |

---

<!-- _class: lead -->

# La idea del día

## El año en curso siempre va perdiendo, y no es culpa del campo.

<br>

Ayer el número malo dividía entre seis cultivos cuando solo cuatro cosecharon. Hoy compara contra doce meses cuando solo han pasado cuatro. **Los dos son el mismo error: un pedazo del cálculo abarca más de lo que debería, y nada avisa.**

<br>

**Práctica:** carga los dos años, provoca el **−35,00 %**, saca las dos fechas de corte y déjalo en **+30,00 %**.

**`[Kilos]` de 2026 tiene que seguir diciendo 30 550.**
