---
marp: true
paginate: true
theme: default
title: "Clase 31 · El promedio de los promedios"
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
footer: "Curso de SQL · AgroDB · Clase 31"
---

<!-- _class: lead -->

# El promedio de los promedios

## Agrupar por en Power Query: una llave de más que partió cosechas y un promedio guardado que no se podía volver a promediar

Clase 31 · 2 de octubre

---

# Lo que llega hoy

La báscula cambió otra vez. Ya no manda un archivo por mes: manda **una fila por camión**, `pesadas.csv`:

| `pesada_id` | `cosecha_id` | `finca_id` | `fecha` | `calidad` | `camion` | `kg` |
|---|---|---|---|---|---|---|
| 1 | 1 | 1 | 2026-03-20 | primera | LRA-1101 | 1 500 |
| 2 | 1 | 1 | 2026-03-20 | primera | LRA-1102 | 1 500 |
| 3 | 1 | 1 | 2026-03-20 | primera | LRA-1101 | 1 200 |
| 4 | 2 | 1 | 2026-04-18 | segunda | LRA-1101 | 1 600 |
| … | … | … | … | … | … | … |

> *«Son **los mismos kilos de siempre**, camión por camión. Y logística pregunta: **¿cuánto lleva en promedio un camión?**»*

---

# Una cosecha, varios camiones

| | `h_cosecha` de siempre | `pesadas.csv` |
|---|---|---|
| Una fila es | **una cosecha** | **un camión** |
| Filas | 25 | **54** |
| `SUM( kg )` | 77 550 | 77 550 |
| `COUNTROWS` cuenta | cosechas | **camiones** |

<br>

Para que `[Cosechas]` vuelva a contar cosechas, hay que pasar de un camión por fila a **una cosecha por fila**. En SQL era `GROUP BY`. En Power Query se llama **Agrupar por**.

> Agrupar es **resumir**. Lo que no guardes al resumir, no se recupera después.

---

# El modelo de hoy

Un `.pbix` nuevo con tres CSV de `datos/csv_clase31/`: `dim_tiempo`, `dim_finca` y `h_meta`, y sus dos relaciones.

```
Meta = SUM( h_meta[kg_meta] )
```

`h_cosecha` no está entre los CSV: hoy **sale de agrupar las pesadas**. Si son los mismos kilos, la tabla de control tiene que decir:

| Finca | `[Kilos]` | `[Meta]` | `[Cumplimiento]` | `[Cosechas]` |
|---|---|---|---|---|
| Agricola La Union | 2 100 | 5 000 | 42,00 % | 2 |
| Finca El Guayabo | 14 250 | 9 440 | 150,95 % | 3 |
| Hacienda Santa Rosa | 14 200 | 10 000 | 142,00 % | 4 |
| **Total** | **30 550** | **24 440** | **125,00 %** | **9** |

---

# Cargar tal cual

`pesadas.csv` con **Transformar datos**, la consulta se renombra **`h_cosecha`**, **Cerrar y aplicar**, las relaciones con `dim_finca` y `dim_tiempo`, y las medidas de siempre:

```
Kilos = SUM( h_cosecha[kg] )
Cosechas = COUNTROWS( h_cosecha )
Cumplimiento = DIVIDE( [Kilos] , [Meta] )
Cosechas repetidas = [Cosechas] - DISTINCTCOUNT( h_cosecha[cosecha_id] )
```

| Finca | `[Kilos]` | `[Cumplimiento]` | `[Cosechas]` | `[Cosechas repetidas]` |
|---|---|---|---|---|
| Agricola La Union | 2 100 | 42,00 % | 2 | 0 |
| Finca El Guayabo | 14 250 | 150,95 % | <span class="rojo">7</span> | <span class="rojo">4</span> |
| Hacienda Santa Rosa | 14 200 | 142,00 % | <span class="rojo">10</span> | <span class="rojo">6</span> |
| **Total** | **30 550** | **125,00 %** | <span class="rojo">**19**</span> | <span class="rojo">**10**</span> |

Los kilos se suman igual. **`COUNTROWS` cuenta camiones.**

---

# Agrupar por, básico

**Transformar datos** → `h_cosecha` → **Inicio → Agrupar por** → **Básico** → `cosecha_id` → **Aceptar**:

| `cosecha_id` | `Recuento` |
|---|---|
| 1 | 3 |
| 2 | 2 |
| 3 | 4 |
| … | … |

**25 filas** y **2 columnas**. Están las 25 cosechas… y no está nada más: ni `finca_id`, ni `fecha`, ni **`kg`**.

> **Agrupar por se queda con las columnas que agrupas y con las que calculas. Todas las demás desaparecen.** Borra ese paso.

---

# Agrupar por todo lo que no son kilos

**Agrupar por → Avanzado**. Para no perder columnas, se agrupa por todas menos `pesada_id` y `kg`: `cosecha_id`, `finca_id`, `cultivo_id`, `fecha`, `calidad` y `camion`. Una agregación: **`kg`**, **Suma** de `kg`.

| Finca | `[Kilos]` | `[Cumplimiento]` | `[Cosechas]` | `[Cosechas repetidas]` |
|---|---|---|---|---|
| Agricola La Union | 2 100 | 42,00 % | 2 | 0 |
| Finca El Guayabo | 14 250 | 150,95 % | <span class="rojo">5</span> | <span class="rojo">2</span> |
| Hacienda Santa Rosa | 14 200 | 142,00 % | <span class="rojo">7</span> | <span class="rojo">3</span> |
| **Total** | **30 550** | **125,00 %** <span class="verde">✓</span> | <span class="rojo">**14**</span> | <span class="rojo">**5**</span> |

<br>

Abajo a la izquierda, **36 filas**. El control de kilos pasó. **La prueba de ayer, no.**

---

# Las llaves

Cosecha 1: tres camiones, dos placas. Agrupada **con** `camion`:

| `cosecha_id` | `camion` | `kg` |
|---|---|---|
| 1 | LRA-1101 | 2 700 |
| 1 | LRA-1102 | 1 500 |

> **Una llave es lo que es igual en todo el grupo.** `camion` cambia dentro de la cosecha: no es llave.

En **Pasos aplicados**, el engrane de **Filas agrupadas**. Llaves: `cosecha_id`, `finca_id`, `cultivo_id`, `fecha`, `calidad`. **Agregar agregación**, tres:

| Nuevo nombre de columna | Operación | Columna |
|---|---|---|
| `kg` | **Suma** | `kg` |
| `pesadas` | **Recuento de filas** | |
| `carga_promedio` | **Promedio** | `kg` |

**25 filas**. Control: **30 550 / 24 440 / 125,00 % / 9**, `[Cosechas repetidas]` **0** <span class="verde">✓</span>

---

# Cuánto lleva un camión

La pregunta de logística. La columna ya está calculada, una por cosecha: se promedia.

```
Carga promedio = AVERAGE( h_cosecha[carga_promedio] )
```

| Finca | `[Kilos]` | `[Cosechas]` | `[Carga promedio]` |
|---|---|---|---|
| Agricola La Union | 2 100 | 2 | 1 050,00 |
| Finca El Guayabo | 14 250 | 3 | 1 866,67 |
| Hacienda Santa Rosa | 14 200 | 4 | 1 450,00 |
| **Total** | **30 550** | **9** | **1 500,00** |

<br>

Un número redondo, cada fila con sentido, ningún aviso. Logística ya va a pedir camiones con esto.

---

# La cuenta a mano

En enero–abril de 2026 se pesaron **19 camiones** con **30 550 kilos**. Un camión lleva, en promedio:

**30 550 / 19 = 1 607,89**, no 1 500,00.

Santa Rosa, cosecha por cosecha:

| `cosecha_id` | `pesadas` | `kg` | `carga_promedio` |
|---|---|---|---|
| 1 | 3 | 4 200 | 1 400 |
| 2 | 2 | 3 100 | 1 550 |
| 3 | 4 | 5 400 | 1 350 |
| 4 | **1** | 1 500 | 1 500 |
| **Santa Rosa** | **10** | **14 200** | <span class="rojo">1 450</span> contra **1 420** |

`AVERAGE` le da **el mismo peso** a la cosecha de un camión que a la de cuatro. Es **el promedio de los promedios**.

> Y La Unión da **1 050** de las dos formas: cada cosecha suya fue un camión.

---

# El segundo arreglo obvio

«Un promedio es **el total entre cuántos**». El total ya es una medida:

```
Carga promedio 2 = DIVIDE( [Kilos] , [Cosechas] )
```

| Finca | `[Carga promedio]` | `[Carga promedio 2]` |
|---|---|---|
| Agricola La Union | 1 050,00 | 1 050,00 |
| Finca El Guayabo | 1 866,67 | <span class="rojo">4 750,00</span> |
| Hacienda Santa Rosa | 1 450,00 | <span class="rojo">3 550,00</span> |
| **Total** | 1 500,00 | <span class="rojo">**3 394,44**</span> |

<br>

Ya no es un promedio de promedios. Es **kilos por cosecha**: después de agrupar, **una fila es una cosecha**, y `COUNTROWS` ya no tiene camiones que contar.

> Antes de agrupar contaba 19. **Los camiones se perdieron al agrupar… salvo que los hayas guardado.**

---

# El arreglo: la cuenta que guardaste

La columna `pesadas` (**Recuento de filas**) es la que se suma:

```
Camiones = SUM( h_cosecha[pesadas] )
```

```
Carga por camión = DIVIDE( [Kilos] , [Camiones] )
```

| Finca | `[Kilos]` | `[Camiones]` | `[Carga por camión]` |
|---|---|---|---|
| Agricola La Union | 2 100 | 2 | 1 050,00 |
| Finca El Guayabo | 14 250 | 7 | <span class="verde">2 035,71</span> |
| Hacienda Santa Rosa | 14 200 | 10 | <span class="verde">1 420,00</span> |
| **Total** | **30 550** | **19** | <span class="verde">**1 607,89**</span> |

<br>

Sin segmentadores: **77 550** kilos, **25** cosechas, **54** camiones (las filas de `pesadas.csv`), **1 436,11** por camión.

---

# Lo que se guarda y lo que se pierde

| Operación al agrupar | ¿Se puede volver a resumir? | En el tablero |
|---|---|---|
| **Suma** | sí | `SUM` |
| **Recuento de filas** | sí | `SUM`, no `COUNTROWS` |
| **Mín.** / **Máx.** | sí | `MIN` / `MAX` |
| **Promedio** | <span class="rojo">no</span> | se calcula: suma entre recuento |
| **Recuento de filas distintas** | <span class="rojo">no</span> | se pierde |
| **Mediana** | <span class="rojo">no</span> | se pierde |

<br>

> El promedio de cada cosecha **está bien**. Lo que está mal es **resumir un resumen**. Se guardan las piezas, la suma y la cuenta, y el promedio se arma en el tablero.

---

# La prueba de cada agrupación

| Qué revisas | Qué atrapa |
|---|---|
| **filas = cosechas**: 25, y `[Cosechas repetidas]` en **0** | una llave de más (`camion`) |
| `[Kilos]` igual que antes de agrupar: **77 550** | una operación equivocada (**Recuento** donde iba **Suma**) |
| `[Camiones]` igual a las filas del archivo: **54** | la cuenta que no se guardó |
| ningún `AVERAGE` sobre una columna que ya era promedio | el promedio de los promedios |
| la cuenta a mano de **una** finca con más de un camión | lo mismo; La Unión no lo enseña |

<br>

> La Unión dio **1 050,00** con las tres medidas. Si hubieras revisado solo esa finca, las tres pasaban.

---

# Los errores que van a ver hoy

| Síntoma | Qué pasó | Arreglo |
|---|---|---|
| **2 columnas**: `cosecha_id` y `Recuento` | usaste **Básico** | **Avanzado**, con las cinco llaves |
| `[Kilos]` da error: no encuentra `kg` | la suma se llama `Recuento` o `Suma` | renombra la agregación a **`kg`** |
| `[Kilos]` da **19** | la operación quedó en **Recuento de filas**: contó camiones | **Suma** de `kg` |
| **36 filas**, `[Cosechas repetidas]` **5** | `camion` quedó en las llaves | quítalo en el engrane de **Filas agrupadas** |
| no aparece **Suma** en la lista | `kg` es texto | tipo **Número entero** antes de agrupar |
| `[Carga promedio]` **1 500,00** | promedio de promedios | `[Carga por camión]` |
| `[Carga promedio 2]` **3 394,44** | kilos por **cosecha** | `[Camiones]` = `SUM( h_cosecha[pesadas] )` |
| `[Camiones]` da **9** | escribiste `COUNTROWS` | `SUM( h_cosecha[pesadas] )` |

---

<!-- _class: lead -->

# La idea del día

## Al agrupar se guardan sumas y cuentas; el promedio se calcula después, nunca se promedia.

<br>

Cargadas tal cual, las pesadas daban los kilos bien y **19** «cosechas». **Básico** dejó dos columnas. Agrupar por todo metió **`camion`** en las llaves: **36** filas y `[Cosechas repetidas]` en **5**. Con las cinco llaves, **25** filas y el control en **125,00 %**. Y la pregunta de logística: `AVERAGE` sobre `carga_promedio` dijo **1 500,00**, `[Kilos]` entre `[Cosechas]` dijo **3 394,44**, y la verdad es **30 550 / 19 = 1 607,89**, con la cuenta que se guardó al agrupar.

<br>

**Práctica:** agrupa las pesadas, cae en la llave de más, saca a mano la carga de Santa Rosa y arma la medida con las piezas que guardaste.

**Y la tabla de control tiene que decir 125,00 % con 30 550 en 9 cosechas, y la carga por camión 1 607,89 con 19 camiones.**
