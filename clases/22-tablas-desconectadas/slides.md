---
marp: true
paginate: true
theme: default
title: "Clase 22 · La meta que nadie marcó"
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
footer: "Curso de SQL · AgroDB · Clase 22"
---

<!-- _class: lead -->

# La meta que nadie marcó

## Tablas desconectadas, y un segmentador que el tablero no obedecía

Clase 22 · 17 de septiembre

---

# Lo que llega hoy

**Nada.** Los CSV son los de la clase 17 y el `.pbix` es el de ayer.

Llega **una pregunta de la gerencia** para 2027:

> *«¿Y si subimos la meta? Quiero ver qué pasa al 110, al 120… hasta el 150 %.»*

<br>

Segmentadores en `anio` = 2026, `mes` en 1–4, y `tipo` **sin nada marcado**:

| Finca | `[Kilos]` | `[Meta]` | `[Cumplimiento]` |
|---|---|---|---|
| Agricola La Union | 2 100 | 5 000 | 42,00 % |
| Finca El Guayabo | 14 250 | 9 440 | 150,95 % |
| Hacienda Santa Rosa | 14 200 | 10 000 | 142,00 % |
| **Total** | **30 550** | **24 440** | **125,00 %** |

---

# Una tabla que no viene de ningún archivo

Los niveles de meta **no están en ningún CSV**. Se escriben a mano.

**Modelado → Nueva tabla**:

```
escenario = DATATABLE( "nivel" , INTEGER , { { 100 } , { 110 } , { 120 } , { 130 } , { 140 } , { 150 } } )
```

<br>

- Seis filas, una columna: `escenario[nivel]`.
- En la **vista de modelo**, `escenario` queda **sola**: ninguna línea la une a nada.

> Es una **tabla desconectada**. No tiene fincas, ni fechas, ni kilos. Tiene **opciones**.

---

# El segmentador que no mueve nada

Segmentador nuevo con `escenario[nivel]`. **Marca 130.**

| Finca | `[Kilos]` | `[Meta]` | `[Cumplimiento]` |
|---|---|---|---|
| Agricola La Union | 2 100 | 5 000 | 42,00 % |
| Finca El Guayabo | 14 250 | 9 440 | 150,95 % |
| Hacienda Santa Rosa | 14 200 | 10 000 | 142,00 % |
| **Total** | **30 550** | **24 440** | **125,00 %** |

<br>

**La misma tabla.** Marca 150: **la misma tabla.**

- El filtro viaja **por las relaciones** (clase 18). `escenario` no tiene ninguna.
- Marcar un nivel filtra `escenario`… **y a nadie más**.

> Una tabla desconectada **no filtra nada por sí sola**. Alguien le tiene que **preguntar** qué quedó marcado.

---

# La medida pregunta

```
SELECTEDVALUE( columna , alternativo )
```

- Si en el contexto queda **un solo valor** de la columna, lo devuelve.
- Si quedan **varios, o ninguno**, devuelve el **alternativo**.

<br>

```
Nivel elegido = SELECTEDVALUE( escenario[nivel] , 100 )
```

Con **130** marcado, `[Nivel elegido]` = **130**. Sin nada marcado, **100**: la meta tal como está.

> La tabla no filtra; **la medida lee el segmentador** y hace la cuenta.

---

# La meta ajustada

```
Meta ajustada = [Meta] * [Nivel elegido] / 100
```

```
Cumplimiento ajustado = DIVIDE( [Kilos] , [Meta ajustada] )
```

Con **130** marcado:

| Finca | `[Kilos]` | `[Meta ajustada]` | `[Cumplimiento ajustado]` |
|---|---|---|---|
| Agricola La Union | 2 100 | 6 500 | 32,31 % |
| Finca El Guayabo | 14 250 | 12 272 | 116,12 % |
| Hacienda Santa Rosa | 14 200 | 13 000 | 109,23 % |
| **Total** | **30 550** | **31 772** | **96,15 %** |

> Al 130 %, **la empresa ya no cumple**. Y dos fincas **sí**.

---

# Seis metas, un clic cada una

Mueve el segmentador de uno en uno y anota el total:

| Nivel | `[Meta ajustada]` | `[Cumplimiento ajustado]` |
|---|---|---|
| 100 | 24 440 | 125,00 % |
| 110 | 26 884 | 113,64 % |
| 120 | 29 328 | 104,17 % |
| 130 | 31 772 | **96,15 %** |
| 140 | 34 216 | 89,29 % |
| 150 | 36 660 | 83,33 % |

<br>

La empresa aguanta **hasta el 120**. Funciona, y se probó **seis veces**.

---

# El gerente quiere comparar dos

**Ctrl+clic** en el segmentador: **130 y 150** marcados.

| Finca | `[Kilos]` | `[Meta ajustada]` | `[Cumplimiento ajustado]` |
|---|---|---|---|
| Agricola La Union | 2 100 | 5 000 | 42,00 % |
| Finca El Guayabo | 14 250 | 9 440 | 150,95 % |
| Hacienda Santa Rosa | 14 200 | 10 000 | 142,00 % |
| **Total** | **30 550** | **24 440** | **125,00 %** |

<br>

El segmentador dice **130 y 150**. La tabla dice que la empresa cumple al **125,00 %**.

> Hace un minuto, al 130 solo, era **96,15 %**. Al 150, **83,33 %**.

---

# ¿Y qué error dio?

## Ninguno. Otra vez.

<br>

- El segmentador tiene **dos niveles marcados**, a la vista.
- La tabla **no dice** con qué nivel calculó.
- El 24 440 y el 125,00 % **son números que ya conocen**: se ven bien.

<br>

> El gerente sale de la junta diciendo que **con la meta al 150 % la empresa cumple al 125 %**. Nadie en la sala vio un aviso.

---

# El nivel que nadie marcó

`SELECTEDVALUE` con **dos** valores en el contexto no escoge uno: devuelve **el alternativo**.

```
Nivel elegido = SELECTEDVALUE( escenario[nivel] , 100 )
                                                  ───
                               con 130 y 150 marcados, esto
```

<br>

| Qué hay marcado | `[Nivel elegido]` |
|---|---|
| 130 | 130 |
| 130 y 150 | **100** |
| nada | **100** |

> Pon una **tarjeta** con `[Nivel elegido]` junto al segmentador. Dice **100**, un nivel que **nadie marcó**. El alternativo contestó por la medida.

---

# Por qué no se vio al probarla

| Qué probaste | Qué salió | ¿Atrapa el error? |
|---|---|---|
| sin nada marcado | 125,00 % | **no**: es el número de la clase 17 |
| cada nivel, de uno en uno | seis resultados correctos | **no**: siempre había uno solo |
| dos niveles a la vez | 125,00 % | **sí**, pero se ve igual que el primero |

<br>

El alternativo **no es un número raro**: es 100, **un nivel que está en la lista**. Por eso lo que devuelve se ve plausible.

> Un valor alternativo es **una respuesta con buena cara** para cuando la pregunta no tiene respuesta.

---

# El gerente quiere los seis a la vez

**Borra la selección** del segmentador. Objeto visual **Matriz**: filas `dim_finca[finca]`, columnas `escenario[nivel]`, valores `[Meta ajustada]`.

| Finca | 100 | 110 | 120 | 130 | 140 | 150 | **Total** |
|---|---|---|---|---|---|---|---|
| Agricola La Union | 5 000 | 5 500 | 6 000 | 6 500 | 7 000 | 7 500 | **5 000** |
| Finca El Guayabo | 9 440 | 10 384 | 11 328 | 12 272 | 13 216 | 14 160 | **9 440** |
| Hacienda Santa Rosa | 10 000 | 11 000 | 12 000 | 13 000 | 14 000 | 15 000 | **10 000** |
| **Total** | 24 440 | 26 884 | 29 328 | 31 772 | 34 216 | 36 660 | **24 440** |

<br>

Las seis columnas están **bien**: cada columna filtra `escenario` a **un** nivel. La columna **Total** dice 5 000 para La Unión.

---

# Un total que no es de ningún nivel

Es la clase 21 otra vez: **la columna del total vuelve a hacer la cuenta**, con su propio contexto.

```
Columna 130:    un nivel en el contexto    → SELECTEDVALUE = 130
Columna Total:  los seis niveles           → SELECTEDVALUE = 100 (el alternativo)
```

<br>

| La Unión | Lo que dice el total | Lo que suman las columnas |
|---|---|---|
| `[Meta ajustada]` | **5 000** | **37 500** |

> No es la suma, ni el promedio (6 250), ni el máximo. Es **el alternativo**, que coincide con la columna del 100 y por eso **parece copiado de ahí**.

---

# Que diga que no sabe

Si hay más de un nivel, la medida **no tiene nada que contestar**. Que lo diga:

```
Meta del escenario =
IF(
    HASONEVALUE( escenario[nivel] ) ,
    [Meta] * SELECTEDVALUE( escenario[nivel] ) / 100
)
```

```
Cumplimiento del escenario = DIVIDE( [Kilos] , [Meta del escenario] )
```

| Dónde | `[Meta ajustada]` | `[Meta del escenario]` |
|---|---|---|
| columna 130 de la matriz, La Unión | 6 500 | 6 500 |
| columna **Total** de la matriz, La Unión | **5 000** | *(vacío)* |
| la tabla por finca, con **130 y 150** marcados | **24 440** · 125,00 % | *(vacío)* · *(vacío)* |

> Es el `BLANK()` de la clase 17: **una medida que se calla es más honesta que una que inventa**.

---

# Selección única

La medida ya no miente. Ahora que **el segmentador no deje preguntar dos cosas**:

**Formato del segmentador → Configuración del segmentador → Selección → Selección única**

<br>

| Arreglo | Qué evita |
|---|---|
| `HASONEVALUE` en la medida | que **cualquier** objeto visual con varios niveles invente un número |
| **Selección única** en el segmentador | que el gerente **marque dos** |
| tarjeta con `[Nivel elegido]` | que alguien lea la tabla **sin saber con qué nivel** |

> La selección única **no arregla la matriz**: ahí los seis niveles llegan por las columnas, no por el segmentador. Lo que la arregla es la medida.

---

# ¿Hasta dónde se puede subir?

```
Fincas que cumplen = COUNTROWS( FILTER( dim_finca , [Cumplimiento del escenario] >= 1 ) )
```

Tabla nueva con `escenario[nivel]`, `[Kilos]`, `[Meta del escenario]`, `[Cumplimiento del escenario]` y `[Fincas que cumplen]`:

| `nivel` | `[Kilos]` | `[Meta del escenario]` | `[Cumplimiento del escenario]` | `[Fincas que cumplen]` |
|---|---|---|---|---|
| 100 | 30 550 | 24 440 | 125,00 % | 2 |
| 110 | 30 550 | 26 884 | 113,64 % | 2 |
| 120 | 30 550 | 29 328 | 104,17 % | 2 |
| 130 | 30 550 | 31 772 | **96,15 %** | **2** |
| 140 | 30 550 | 34 216 | 89,29 % | 2 |
| 150 | 30 550 | 36 660 | 83,33 % | **1** |
| **Total** | **30 550** | | | |

> La empresa deja de cumplir en el **130**; dos fincas aguantan **hasta el 140**. Y `[Kilos]` no se mueve: **la tabla sigue desconectada**.

---

# La prueba de un parámetro

Anteayer se probaba moviendo un segmentador; ayer, sumando la columna. Un parámetro se prueba **marcando lo que no debería marcarse**:

<br>

| Qué revisas | Qué atrapa |
|---|---|
| **dos valores** marcados a la vez | el alternativo que contesta por la medida |
| **ninguno** marcado | el alternativo que parece la meta de siempre |
| la **columna o fila del total** de una matriz | el total que no es de ningún nivel |
| una **tarjeta** con el valor que la medida está usando | el tablero que no dice con qué calculó |

<br>

> **Si el segmentador dice dos cosas y la tabla una, la tabla escogió por ti.**

---

# Los errores que van a ver hoy

| Síntoma | Qué pasó | Arreglo |
|---|---|---|
| el segmentador de `escenario` no cambia nada | la tabla está desconectada y ninguna medida la lee | `[Nivel elegido]` con `SELECTEDVALUE` |
| `DATATABLE` da error | falta un par de llaves, o usaste `;` | `{ { 100 } , { 110 } , … }`, con comas |
| la tabla dice 125,00 % con 130 y 150 marcados | `SELECTEDVALUE` devolvió el alternativo | `[Meta del escenario]` con `HASONEVALUE` |
| la columna Total de la matriz repite la del 100 | los seis niveles llegan al total | **no se suma**: la medida con `HASONEVALUE` la deja vacía |
| todo sale **vacío** al empezar | `[Meta del escenario]` sin nada marcado en el segmentador | **no es error**: marca un nivel |
| El Guayabo no cumple en ningún nivel | quedó **perenne** marcado de anteayer: el maíz no cuenta | quita la marca del segmentador `tipo` |
| apareció una línea entre `escenario` y otra tabla | la relacionaste a mano | bórrala: la tabla **tiene que** estar sola |

---

<!-- _class: lead -->

# La idea del día

## Un segmentador de una tabla desconectada no filtra nada: la medida pregunta qué quedó marcado, y si le marcan dos, el valor alternativo contesta por ella.

<br>

Con la meta al 130 % y al 150 % marcadas, el tablero dijo **125,00 %**: la meta de siempre, un nivel que **nadie marcó**. La columna Total de la matriz hizo lo mismo. **Una medida que no sabe qué nivel usar tiene que quedarse callada.**

<br>

**Práctica:** crea `escenario`, lee el segmentador con `SELECTEDVALUE`, márcale dos niveles, arma la matriz, y arréglala con `HASONEVALUE`.

**Y al 130 %, la empresa tiene que dar 96,15 %.**
