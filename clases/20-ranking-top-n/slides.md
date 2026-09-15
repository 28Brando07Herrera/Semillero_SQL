---
marp: true
paginate: true
theme: default
title: "Clase 20 · El Top 3 que tenía dos"
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
footer: "Curso de SQL · AgroDB · Clase 20"
---

<!-- _class: lead -->

# El Top 3 que tenía dos

## Rankings con RANKX, y un podio que competía contra lo que no se veía

Clase 20 · 15 de septiembre

---

# Lo que llega hoy

**Nada.** Los CSV son los mismos de la clase 17 y el `.pbix` es el de ayer.

Llega **una pregunta**, la más pedida después de *«¿cuánto?»*:

> *«¿Cuáles son los tres cultivos que más cosecharon?»*

<br>

Segmentadores en `anio` = 2026 y `mes` en 1–4, como siempre:

| Cultivo | `[Kilos]` | `[Cosechas]` |
|---|---|---|
| Mango | 12 700 | 3 |
| Maiz | 9 800 | 1 |
| Guayaba | 5 950 | 3 |
| Cacao | 2 100 | 2 |
| **Total** | **30 550** | **9** |

---

# Ordenar no es rankear

Clic en el encabezado de `[Kilos]` y la tabla ya sale **de mayor a menor**. ¿Para qué una medida?

<br>

| Ordenar la tabla | Una medida de ranking |
|---|---|
| cambia **cómo se dibuja** | es **un número** |
| se pierde si alguien reordena | no depende del orden |
| no se puede filtrar | se filtra: *«lugar ≤ 3»* |
| no se puede usar en otra medida | sí |

<br>

> «Top 3» es un **filtro** sobre un lugar. Y para filtrar por un lugar, el lugar tiene que existir como número.

---

# RANKX, pieza por pieza

```
RANKX( tabla , expresión )
```

<br>

1. Toma **cada fila** de la `tabla`.
2. Calcula la `expresión` para esa fila: los kilos del Mango, los del Maíz…
3. Calcula la `expresión` **para la fila donde estás** en el objeto visual.
4. Te dice **en qué lugar** quedó la tuya en esa lista. De mayor a menor, y los empates comparten lugar.

<br>

> Es una carrera: la `tabla` dice **quién corre**, la `expresión` dice **qué se mide**. Todo lo de hoy es decidir **quién corre**.

---

# Primer intento: todos en primer lugar

**Inicio → Nueva medida**:

```
Ranking = RANKX( dim_cultivo , [Kilos] )
```

Agrégala a la tabla:

| Cultivo | `[Kilos]` | `[Ranking]` |
|---|---|---|
| Mango | 12 700 | **1** |
| Maiz | 9 800 | **1** |
| Guayaba | 5 950 | **1** |
| Cacao | 2 100 | **1** |
| **Total** | **30 550** | **1** |

<br>

> Cuatro cultivos, cuatro primeros lugares. **Y ni una advertencia.**

---

# Por qué todos son primero

Es la clase 15 otra vez: **la medida se calcula en el contexto de la fila.**

<br>

En la fila del Mango, el objeto visual ya filtró `dim_cultivo` a **una fila**: el Mango. Entonces:

```
RANKX( dim_cultivo , [Kilos] )
       └── en esta fila, dim_cultivo = { Mango }
```

**Una carrera con un solo corredor.** Gana siempre.

<br>

> Para que el Mango compita, la tabla de la carrera tiene que **ignorar el filtro de la fila**. Eso ya lo hicimos en la 18: `ALL`.

---

# Con ALL: seis lugares para cuatro cultivos

```
Ranking = RANKX( ALL( dim_cultivo ) , [Kilos] )
```

| Cultivo | `[Kilos]` | `[Ranking]` |
|---|---|---|
| Mango | 12 700 | 1 |
| Maiz | 9 800 | 2 |
| Guayaba | 5 950 | 3 |
| Cacao | 2 100 | 4 |
| **Banano** | *(vacío)* | **5** |
| **Cafe** | *(vacío)* | **5** |
| **Total** | **30 550** | **1** |

<br>

Los lugares ya están bien. Pero **Banano y Café volvieron a la tabla**, empatados en quinto sin un kilo, y el total dice que la empresa **quedó en primer lugar**.

---

# El ranking que se calla

`RANKX` trata el vacío **como cero**: el que no cosechó igual corre, y llega último. Y como el ranking ya no está vacío, **la fila se dibuja**. Es Banano y Café apareciendo con meta en la clase 17.

El arreglo también es el de la 17: **enseñarle a callarse.**

```
Ranking =
IF(
    HASONEVALUE( dim_cultivo[cultivo] ) && NOT ISBLANK( [Kilos] ),
    RANKX( ALL( dim_cultivo ) , [Kilos] )
)
```

- `HASONEVALUE`: *¿esta fila es **un** cultivo?* En el total hay seis: no.
- `NOT ISBLANK( [Kilos] )`: *¿cosechó algo?*
- Un `IF` sin tercer argumento devuelve **vacío**.

> Mango 1, Maíz 2, Guayaba 3, Cacao 4. **Cuatro filas y el total vacío.**

---

# El Top 3

**Panel Filtros → Filtros en este objeto visual →** arrastra `[Ranking]` → *es menor o igual que* **3** → **Aplicar filtro**.

<br>

| Cultivo | `[Kilos]` | `[Cosechas]` | `[Ranking]` |
|---|---|---|---|
| Mango | 12 700 | 3 | 1 |
| Maiz | 9 800 | 1 | 2 |
| Guayaba | 5 950 | 3 | 3 |
| **Total** | **28 450** | **7** | |

<br>

Tres filas. Listo.

> Fíjate en el total: **28 450**, no 30 550. El total de un objeto visual filtrado es el total **de lo que muestra**. Guárdalo para la diapositiva 16.

---

# El gerente quiere solo perennes

Un segmentador más: `dim_cultivo[tipo]`. El gerente marca **perenne**: el maíz es de ciclo corto y no le interesa.

<br>

| Cultivo | `[Kilos]` | `[Cosechas]` | `[Ranking]` |
|---|---|---|---|
| Mango | 12 700 | 3 | **1** |
| Guayaba | 5 950 | 3 | **3** |
| **Total** | **18 650** | **6** | |

<br>

El título dice **Top 3**. La tabla tiene **dos filas**.

> Y la Guayaba está **en tercer lugar** de una lista donde **no hay segundo**.

---

# ¿Y qué error dio?

## Ninguno. Otra vez.

<br>

- La medida es la de la diapositiva 8, que estaba bien.
- El filtro dice *menor o igual que 3*, y **las dos filas lo cumplen**.
- El segmentador filtró perennes, y **las dos filas son perennes**.
- Nadie puso una advertencia.

<br>

Falta el **Cacao**, que es el tercer perenne con **2 100** kilos. Tiene ranking **4**, y el filtro lo sacó.

> Un podio de tres con dos personas se ve raro **si lo cuentas**. En una junta, nadie cuenta.

---

# Por qué pasa

`ALL( dim_cultivo )` quita **todos** los filtros de `dim_cultivo`. El de la fila, que era la idea… **y el del segmentador**, que no.

<br>

```
Quién corre con ALL( dim_cultivo ):

  Mango     12 700   1
  Maiz       9 800   2   ← el segmentador lo escondió, pero sigue corriendo
  Guayaba    5 950   3
  Cacao      2 100   4   ← el filtro ≤ 3 lo saca
```

<br>

> El ranking compite contra **un corredor que no ves**. El maíz no está en la tabla, **y se quedó con el segundo lugar**.

---

# ALLSELECTED: contra lo que estás viendo

```
Ranking visible =
IF(
    HASONEVALUE( dim_cultivo[cultivo] ) && NOT ISBLANK( [Kilos] ),
    RANKX( ALLSELECTED( dim_cultivo ) , [Kilos] )
)
```

`ALLSELECTED` quita el filtro **de la fila**, pero respeta **lo que viene de afuera**: los segmentadores.

Cambia el filtro del objeto visual a `[Ranking visible]` ≤ 3. Con **perenne**:

| Cultivo | `[Kilos]` | `[Ranking]` | `[Ranking visible]` |
|---|---|---|---|
| Mango | 12 700 | 1 | **1** |
| Guayaba | 5 950 | 3 | **2** |
| Cacao | 2 100 | 4 | **3** |
| **Total** | **20 750** | | |

> Tres filas. El **20 750** es el mismo total de perennes de la clase 15.

---

# ¿Cuál de los dos está bien?

## Los dos. Contestan preguntas distintas.

<br>

| Medida | La pregunta que contesta | Guayaba con perenne |
|---|---|---|
| `[Ranking]`, con `ALL` | *¿en qué lugar va en **toda la empresa**?* | **3** |
| `[Ranking visible]`, con `ALLSELECTED` | *¿en qué lugar va **entre lo que estoy viendo**?* | **2** |

<br>

Sin segmentadores, **dan lo mismo**. Por eso el error no se ve hasta que alguien filtra.

> Es la clase 16 otra vez: la medida no estaba mal, **contestaba bien una pregunta que nadie hizo**. Un «Top 3» casi siempre es la segunda.

---

# Tres versiones, para el cuaderno

Segmentadores en 2026 y 1–4. Lugar de cada cultivo según **quién corre**:

| Segmentador `tipo` | Cultivo | `dim_cultivo` | `ALL` | `ALLSELECTED` |
|---|---|---|---|---|
| *(ninguno)* | Guayaba | 1 | 3 | 3 |
| perenne | Guayaba | 1 | **3** | **2** |
| perenne | Cacao | 1 | **4** | **3** |
| ciclo corto | Maiz | 1 | **2** | **1** |

<br>

> Con **ciclo corto** la tabla tiene **un solo cultivo**, y con `ALL` sale **en segundo lugar**. El primero es el Mango, que no está en la pantalla.

---

# El Top 3 sin fórmula

El panel Filtros también sabe hacer un Top N solo, sin medida de ranking:

**Filtros en este objeto visual →** `cultivo` → **Tipo de filtro: N principales** → **Superior, 3** → **Por valor:** `[Kilos]` → **Aplicar filtro**.

| Segmentador `tipo` | Filas | `[Kilos]` total |
|---|---|---|
| *(ninguno)* | Mango, Maiz, Guayaba | **28 450** |
| perenne | Mango, Guayaba, Cacao | **20 750** |

<br>

Se comporta como `ALLSELECTED`: respeta el segmentador. **Y su total tampoco es la empresa:** 28 450 son los kilos **del Top 3**.

> Si una tarjeta de «Total» se copia de esta tabla, dice **28 450**. Un filtro de objeto visual también filtra el total.

---

# Lo que un ranking no dice

El mismo patrón, por finca:

```
Ranking finca =
IF(
    HASONEVALUE( dim_finca[finca] ) && NOT ISBLANK( [Kilos] ),
    RANKX( ALLSELECTED( dim_finca ) , [Kilos] )
)
```

| Finca | `[Kilos]` | `[Ranking finca]` | Distancia al de arriba |
|---|---|---|---|
| Finca El Guayabo | 14 250 | 1 | — |
| Hacienda Santa Rosa | 14 200 | 2 | **50** |
| Agricola La Union | 2 100 | 3 | **12 100** |

<br>

Entre el 1 y el 2 hay **50 kilos**. Entre el 2 y el 3, **12 100**. El ranking escribe lo mismo: **uno más**.

> Con 2025 en el segmentador, Santa Rosa pasa a **primero**. Un lugar sin los kilos al lado **esconde la distancia**.

---

# La prueba de un ranking

Ayer la prueba de un rol era probar con tres correos. La de un ranking es **mover un segmentador**:

<br>

| Qué revisas | Qué atrapa |
|---|---|
| que el **total** del ranking esté vacío | el «la empresa quedó en primer lugar» |
| que **no aparezcan filas** sin kilos | el vacío corriendo como cero |
| con un segmentador puesto, que los lugares vayan **1, 2, 3 sin saltos** | el `ALL` compitiendo contra lo que no ves |
| con **un solo** elemento en la tabla, que diga **1** | lo mismo, en su forma más clara |

<br>

> **Si falta un número en el ranking, alguien que no ves se lo quedó.**

---

# Los errores que van a ver hoy

| Síntoma | Qué pasó | Arreglo |
|---|---|---|
| Todos en primer lugar | `RANKX( dim_cultivo , … )` sin `ALL` | `ALL( dim_cultivo )` |
| Banano y Café en quinto | el vacío cuenta como cero | `NOT ISBLANK( [Kilos] )` |
| El total dice 1 | falta `HASONEVALUE` | la medida de la diapositiva 8 |
| Con perenne, Guayaba en 3 y el Top 3 con dos filas | `ALL` compite contra el maíz | `ALLSELECTED` |
| Con perenne **no** reproduces el error | escribiste `ALL( dim_cultivo[cultivo] )` | es `ALL( dim_cultivo )`, la tabla entera |
| El filtro no ofrece «menor o igual que» | arrastraste una columna, no la medida | arrastra `[Ranking]` |
| El total dice 28 450 | el filtro del objeto visual | **no es error**: es el total del Top 3 |
| `[Ranking finca]` pone a Santa Rosa primero | quedó **perenne** en el segmentador | quítalo |

---

<!-- _class: lead -->

# La idea del día

## Un ranking siempre es contra alguien: ALL compite contra toda la empresa, ALLSELECTED contra lo que estás viendo, y el tablero no te dice cuál escogiste.

<br>

El `ALL` que arregló los cuatro primeros lugares fue el mismo que dejó al maíz, escondido por el segmentador, quedándose con el segundo lugar. **El Top 3 salió con dos filas y nadie avisó.**

<br>

**Práctica:** haz que todos queden primeros, arréglalo con `ALL`, cállalo con `HASONEVALUE`, rompe el Top 3 con **perenne** y arréglalo con `ALLSELECTED`.

**Y con perenne, el Top 3 tiene que sumar 20 750.**
