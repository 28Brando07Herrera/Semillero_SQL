---
marp: true
paginate: true
theme: default
title: "Clase 23 · El rojo que sí cumplía"
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
footer: "Curso de SQL · AgroDB · Clase 23"
---

<!-- _class: lead -->

# El rojo que sí cumplía

## Formato condicional y KPI, y un semáforo que pintaba según los demás

Clase 23 · 21 de septiembre

---

# Lo que llega hoy

**Nada.** Los CSV son los de la clase 17 y el `.pbix` es el de la semana pasada.

Llega **un pedido de la gerencia**:

> *«No quiero leer números. Quiero ver de un vistazo quién cumple: **verde o rojo**. Y arriba del tablero, **un KPI**.»*

<br>

Segmentadores en `anio` = 2026, `mes` en 1–4, y `tipo` **sin nada marcado**:

| Finca | `[Kilos]` | `[Meta]` | `[Cumplimiento]` |
|---|---|---|---|
| Agricola La Union | 2 100 | 5 000 | 42,00 % |
| Finca El Guayabo | 14 250 | 9 440 | 150,95 % |
| Hacienda Santa Rosa | 14 200 | 10 000 | 142,00 % |
| **Total** | **30 550** | **24 440** | **125,00 %** |

---

# Dónde vive el formato condicional

En el panel **Visualizaciones**, la flechita junto al campo en el pozo **Columnas** → **Formato condicional** → **Color de fondo**.

<br>

| Estilo de formato | Qué hace | Contra qué compara |
|---|---|---|
| **Degradado** | una escala de un color a otro | el **mínimo** y el **máximo** de lo que se ve |
| **Reglas** | «si el valor está entre esto y esto, este color» | lo que tú escribas… **y cómo lo escribas** |
| **Valor del campo** | el color lo dice **una medida** | lo que diga la medida |

<br>

> Hoy se usan los tres. Guárdense la columna de la derecha.

---

# Un degradado en los kilos

Tabla nueva: `dim_cultivo[cultivo]` y `[Kilos]`. Formato condicional → **Color de fondo** → **Degradado**, de blanco a verde.

| Cultivo | `[Kilos]` | Dónde cae en la escala |
|---|---|---|
| Mango | 12 700 | 100 % · el más oscuro |
| Maiz | 9 800 | 72,64 % |
| Guayaba | 5 950 | 36,32 % |
| Cacao | 2 100 | 0 % · blanco |

<br>

El Cacao queda en blanco **no porque sea poco**: porque **es el mínimo de la tabla**.

> El degradado pinta según **el mínimo y el máximo de lo que se ve**. Si mañana entra un cultivo con 500 kilos, el Cacao cambia de color **sin cambiar de número**.

---

# Una regla: 5 000 kilos

«Arriba de 5 000 kilos, verde; abajo, rojo.» Formato condicional → **Color de fondo** → **Reglas**:

| Si el valor | y | Tipo | Color |
|---|---|---|---|
| `>=` 0 | `<` 5000 | **Número** | rojo |
| `>=` 5000 | `<=` 100000 | **Número** | verde |

| Cultivo | `[Kilos]` | Color |
|---|---|---|
| Mango | 12 700 | <span class="verde">verde</span> |
| Maiz | 9 800 | <span class="verde">verde</span> |
| Guayaba | 5 950 | <span class="verde">verde</span> |
| Cacao | 2 100 | <span class="rojo">rojo</span> |

> Con **Número**, la regla compara contra **el número que escribiste**. Funciona.

---

# Verde si cumple

Ahora la tabla por finca, en `[Cumplimiento]`. «Cumplir es llegar al 100 %.» La columna está en **porcentaje**, así que el tipo que se escoge es… **Porcentaje**:

| Si el valor | y | Tipo | Color |
|---|---|---|---|
| `>=` 0 | `<` 100 | **Porcentaje** | rojo |
| `>=` 100 | `<=` 200 | **Porcentaje** | verde |

| Finca | `[Cumplimiento]` | Color |
|---|---|---|
| Agricola La Union | 42,00 % | <span class="rojo">rojo</span> |
| Finca El Guayabo | 150,95 % | <span class="verde">verde</span> |
| Hacienda Santa Rosa | **142,00 %** | <span class="rojo">**rojo**</span> |

<br>

> Santa Rosa **pasó la meta por 42 puntos**. Y está en rojo.

---

# ¿Y qué error dio?

## Ninguno. Otra vez.

<br>

- La regla **se guardó sin quejarse**.
- La columna dice **142,00 %**, bien calculado: el número **no está mal**.
- La Unión en rojo y El Guayabo en verde **son justo lo esperado**: dos de tres se ven bien.

<br>

> La gerencia pidió un tablero **para no leer números**. El gerente de Santa Rosa llega a la junta **a dar explicaciones** por una finca que cumplió al 142 %.

---

# Porcentaje, ¿de qué?

En una regla, **Porcentaje** no es «el valor en porcentaje». Es **qué tan lejos está del mínimo, en el rango del mínimo al máximo** de lo que se ve:

| Finca | `[Cumplimiento]` | Porcentaje del rango |
|---|---|---|
| Agricola La Union | 42,00 % | **0 %** · es el mínimo |
| Hacienda Santa Rosa | 142,00 % | **91,78 %** |
| Finca El Guayabo | 150,95 % | **100 %** · es el máximo |

«De 100 a 200 % del rango» es **solo el máximo**. La regla no preguntaba quién cumple: preguntaba **quién es el primero**.

<br>

**La prueba:** marca **perenne** en el segmentador `tipo`. El Guayabo pierde el maíz y baja a 47,14 %; Santa Rosa sigue en **142,00 %**… y ahora **es verde**, porque ahora es el máximo.

> **El mismo 142,00 % cambia de color según quién más está en la tabla.** Quita la marca de perenne.

---

# El color como medida

Primer arreglo: en la regla, **Número** y **1** (el porcentaje es ropa: por dentro, 142,00 % es **1,42**). Segundo arreglo, el bueno: que el color **lo diga una medida**.

```
Color cumplimiento = IF( [Cumplimiento] >= 1 , "#1E8449" , "#C0392B" )
```

Formato condicional → **Color de fondo** → **Valor del campo** → `[Color cumplimiento]`. En **Aplicar a**: **Valores y totales**.

| Finca | `[Cumplimiento]` | Color |
|---|---|---|
| Agricola La Union | 42,00 % | <span class="rojo">rojo</span> |
| Finca El Guayabo | 150,95 % | <span class="verde">verde</span> |
| Hacienda Santa Rosa | 142,00 % | <span class="verde">verde</span> |
| **Total** | **125,00 %** | <span class="verde">verde</span> |

> La regla quedó **escrita en DAX**, con el mismo 1 que el cumplimiento. Se lee, se prueba, **no tiene techo** y no depende de quién más esté en la tabla.

---

# Tres objetos para un KPI

Un **KPI** es un número **contra una meta**, con una **dirección** (¿más es mejor?) y, a veces, una **tendencia**.

<br>

| Objeto visual | Qué enseña | Qué le falta |
|---|---|---|
| **Tarjeta** | un número | no sabe de metas |
| **Medidor** | un número contra una meta | no sabe del tiempo |
| **KPI** | un número, una meta y la tendencia | … |

<br>

> Los tres se arman arrastrando dos o tres campos. Los tres **se ven profesionales al primer intento**.

---

# La tarjeta y el medidor

**Tarjeta** con `[Kilos]`: **30 550**. Otra con `[Cumplimiento]`: **125,00 %**.

**Medidor**: `[Kilos]` en **Valor**, `[Meta]` en **Valor de destino**.

- La barra llega a **30 550**, la aguja de la meta en **24 440**.
- Sin máximo, Power BI pone **el doble del valor**: 61 100. La barra queda **siempre a la mitad**, cumplas o no.

```
Tope del medidor = [Meta] * 1.5
```

`[Tope del medidor]` en **Valor máximo**: **36 660**, el 150 % de la meta de la clase 22.

> El máximo del medidor también es **un número que alguien tiene que escoger**. Si no lo escoges tú, lo escoge Power BI.

---

# El objeto visual KPI

**KPI**: `[Kilos]` en **Valor**, `dim_tiempo[nombre_mes]` en **Eje de tendencia**, `[Meta]` en **Destino**.

<br>

| Lo que dibuja | |
|---|---|
| El número grande | **19 750** |
| El objetivo | **8 300** · **+137,95 %** |
| El color | verde |
| El fondo | una línea que sube de marzo a abril |

<br>

> Verde, con una flecha para arriba, **137 % arriba de la meta**. El tablero más optimista del curso.

---

# Tres objetos, dos respuestas

En la misma pantalla, con los mismos segmentadores:

| Objeto | Kilos | Meta | Distancia |
|---|---|---|---|
| Tarjeta | **30 550** | — | — |
| Medidor | **30 550** | 24 440 | +25,00 % |
| KPI | **19 750** | **8 300** | **+137,95 %** |

<br>

¿Qué error dio? **Ninguno.** El KPI está verde, el medidor también, y los dos «dicen que cumplimos».

> Uno dice que vamos **25 %** arriba. El otro, **138 %**. ¿Cuál se lleva a la junta?

---

# El último punto del eje

El KPI **no enseña el total**: enseña **el último punto de su eje de tendencia**.

| `nombre_mes` | `[Kilos]` | `[Meta]` | Distancia |
|---|---|---|---|
| Enero | *(vacío)* | 4 040 | |
| Febrero | *(vacío)* | 5 200 | |
| Marzo | 10 800 | 6 900 | +56,52 % |
| **Abril** | **19 750** | **8 300** | **+137,95 %** |
| **Total** | **30 550** | **24 440** | +25,00 % |

<br>

El 19 750 **es abril**. Es el mismo 19 750 de la clase 14, cuando el calendario no cubría marzo: otra vez **abril solo, haciéndose pasar por el año**.

> El KPI contestaba bien **una pregunta que nadie hizo**: *¿cómo nos fue en el último mes?*

---

# El KPI del año

Si la pregunta es **¿cómo vamos en el año?**, el valor tiene que **acumular**. El `TOTALYTD` de la clase 16:

```
Kilos YTD = TOTALYTD( [Kilos] , dim_tiempo[fecha] )
```

```
Meta YTD = TOTALYTD( [Meta] , dim_tiempo[fecha] )
```

KPI con `[Kilos YTD]` en **Valor** y `[Meta YTD]` en **Destino**:

| `nombre_mes` | `[Kilos YTD]` | `[Meta YTD]` | Distancia |
|---|---|---|---|
| Marzo | 10 800 | 16 140 | **−33,09 %** |
| **Abril** | **30 550** | **24 440** | **+25,00 %** |

> Ahora el último punto **es** el año. Y la tendencia cuenta algo que el total escondía: **a fin de marzo íbamos 33 % abajo**.

---

# Qué pregunta contesta cada uno

| Objeto | Pregunta que contesta | Título que le toca |
|---|---|---|
| Tarjeta con `[Kilos]` | ¿cuánto, en lo que está filtrado? | «Kilos 2026, enero a abril» |
| Medidor | ¿cuánto contra la meta, en lo filtrado? | «Kilos contra meta, enero a abril» |
| KPI con `[Kilos]` | ¿cómo nos fue **en el último mes**? | «Abril: kilos contra meta del mes» |
| KPI con `[Kilos YTD]` | ¿cómo vamos **en el año**? | «Acumulado del año contra meta» |

<br>

Los cuatro están **bien calculados**. Lo que estaba mal era el título, **que no decía la pregunta**.

> **Ponle a cada KPI un título que diga qué periodo está enseñando.**

---

# La prueba de un semáforo

Una medida se prueba moviendo el contexto. Un color y un KPI, igual:

<br>

| Qué revisas | Qué atrapa |
|---|---|
| mueve un segmentador: ¿**cambió un color** sin que cambiara su número? | la regla relativa: Porcentaje, degradado |
| pon **el número al lado del color** | el rojo que sí cumplía |
| pon una **tarjeta junto al KPI** | el KPI que enseña el último mes |
| abre el eje del KPI en una **tabla por mes** | cuál es el último punto, y qué vale |

<br>

> **Si un color cambia y su número no, el color no estaba midiendo ese número.**

---

# Los errores que van a ver hoy

| Síntoma | Qué pasó | Arreglo |
|---|---|---|
| todo sale en rojo | regla con **Número** y **100**: por dentro, 142 % es 1,42 | Número y **1** |
| Santa Rosa en rojo con 142 % | regla con **Porcentaje**: del rango, no del valor | `[Color cumplimiento]` con Valor del campo |
| el total no se pinta | **Aplicar a** quedó en solo valores | **Valores y totales** |
| la barra del medidor siempre a la mitad | el máximo es el doble del valor | `[Tope del medidor]` en Valor máximo |
| el KPI dice **10 800** | `nombre_mes` sin ordenar: el último es **Marzo** (alfabético) | Ordenar por columna → `mes` (clase 16) |
| el KPI no dibuja tendencia | falta el campo en **Eje de tendencia** | arrastra `nombre_mes` |
| `[Kilos YTD]` da lo mismo que `[Kilos]` | `dim_tiempo` no está marcada como tabla de fechas | Marcar como tabla de fechas (clase 16) |

---

<!-- _class: lead -->

# La idea del día

## Un color también es una cuenta: si no sabes contra qué compara, no sabes qué dice.

<br>

Santa Rosa cumplió al **142,00 %** y salió en **rojo**, porque «Porcentaje» comparaba contra el rango. Y el KPI dijo **+137,95 %** porque enseñaba **abril**, no el año. **Un semáforo se audita como cualquier medida.**

<br>

**Práctica:** pinta las tablas con degradado y con reglas, cae en la de Porcentaje, arréglala con `[Color cumplimiento]`, y arma la tarjeta, el medidor y los dos KPI.

**Y el KPI del año tiene que decir 30 550 contra 24 440.**
