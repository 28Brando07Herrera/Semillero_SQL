# Clase 31 · El promedio de los promedios
**Viernes 2 de octubre**

**50 minutos de clase** y el resto de práctica. Quinta clase seguida **adentro de Power Query**: **hoy tampoco se prende Oracle.**

## Material

| Qué | Dónde |
|---|---|
| Diapositivas | [slides.md](slides.md) · [versión web](https://negatix092.github.io/Semillero_SQL/31-agrupar-por.html) |
| Ejercicio práctico | [ejercicio.md](ejercicio.md) |
| Datos del día | [`datos/csv_clase31/`](../../datos/csv_clase31/): tres CSV de la clase 19, **idénticos** (`dim_tiempo`, `dim_finca`, `h_meta`), más **`pesadas.csv`**, las cosechas como las registra la báscula: **una fila por camión**. **`h_cosecha.csv` no viene**: se construye en clase |

> **Hoy sí se baja algo.** Copia `datos/csv_clase31/` a `C:\agrodb31\` y empieza con un **`.pbix` vacío**, como en la 24 y de la 26 a la 30.

## Qué hace falta tener listo

| | |
|---|---|
| Power BI Desktop | y nada más |
| Oracle, Docker, el OCMT | **no**, hoy tampoco |
| El `.pbix` de clases anteriores | **no**: hoy se arma uno nuevo, y `h_cosecha` sale de agrupar las pesadas |

## De qué se trata

La báscula cambió otra vez: ya no manda una fila por cosecha, manda **una por camión**. El correo dice que son **los mismos kilos de siempre**, y trae una pregunta de logística: **¿cuánto lleva en promedio un camión?**

Cargadas tal cual, las 54 pesadas dan los kilos bien —**30 550** y **125,00 %**— porque una suma no sabe de filas, pero `[Cosechas]` dice **19**: `COUNTROWS` cuenta camiones. Para volver a una cosecha por fila hace falta el `GROUP BY` de SQL con botones: **Agrupar por**. Se elige por qué columnas se agrupa (las **llaves**) y qué se calcula para cada grupo (las **agregaciones**), y todo lo demás desaparece.

## El giro de hoy

**Básico** agrupa por `cosecha_id` y cuenta filas: quedan las 25 cosechas en **dos columnas**, sin finca, sin fecha y sin kilos.

Para no perder nada, el obvio en **Avanzado** es agrupar por todo lo que no son kilos, y eso mete **`camion`** en las llaves. Una cosecha que usó dos placas queda en dos filas: **36 filas**, los kilos siguen en 30 550 y el control en 125,00 %, pero `[Cosechas]` dice **14**. Lo atrapa la prueba de ayer: `[Cosechas repetidas]` en **5**. Una llave es lo que es igual en todo el grupo, y `camion` cambia dentro de la cosecha. Con las cinco llaves de la cosecha, **25 filas** y tres agregaciones: la **Suma** de `kg`, el **Recuento de filas** como `pesadas` y el **Promedio** de `kg` como `carga_promedio`.

Y la pregunta de logística. La columna `carga_promedio` ya está calculada, así que `AVERAGE` sobre ella dice **1 500,00**. Cada fila está bien; el total no: en enero–abril se pesaron 19 camiones con 30 550 kilos, **1 607,89** por camión. `AVERAGE` le dio el mismo peso a una cosecha de un camión que a una de cuatro: es **el promedio de los promedios**. En Santa Rosa se pasa (1 450,00 contra 1 420,00), en El Guayabo se queda corto (1 866,67 contra 2 035,71), y en La Unión da igual, porque cada cosecha suya fue un camión.

El segundo arreglo obvio, «el total entre cuántos», es `[Kilos]` entre `[Cosechas]`: **3 394,44**. Ya no promedia promedios, pero contesta otra cosa, **kilos por cosecha**: después de agrupar una fila es una cosecha, y `COUNTROWS` ya no tiene camiones que contar. Los camiones se guardaron al agrupar, en `pesadas`, y esa es la pieza: `[Camiones]` es su **suma**, y la carga por camión, **1 607,89**.

> El promedio de cada cosecha estaba bien. **Lo que estaba mal era resumir un resumen.**

## Lo que hay que saber al terminar

- **Agrupar por**, **Básico** contra **Avanzado**: las **llaves**, las **agregaciones** y las columnas que desaparecen
- Que en las llaves solo va lo que es **igual en todo el grupo**, y que una de más **parte** los grupos sin mover los kilos
- Las operaciones: **Suma**, **Recuento de filas**, **Promedio**, **Mín.**, **Máx.**, **Recuento de filas distintas**, y cuáles se pueden volver a resumir
- Que después de agrupar `COUNTROWS` cuenta **grupos**, y lo que contaba antes hay que **guardarlo** y sumarlo
- El **promedio de los promedios**, y por qué La Unión no lo enseña
- `[Cosechas repetidas]` en 0, `[Kilos]` igual que antes de agrupar y `[Camiones]` igual a las filas del archivo

## La idea del día

**Al agrupar se guardan sumas y cuentas; el promedio se calcula después, nunca se promedia.**

## Las cuatro cosas que son la clase

Si el día se complica y hay que recortar, estas no se recortan:

1. **Tal cual y Básico**: los kilos bien y **19** «cosechas»; Básico deja **dos columnas**.
2. **La llave de más**: `camion` en las llaves, **36 filas**, `[Cosechas repetidas]` en **5**; con las cinco llaves, **25**.
3. **El promedio de los promedios**: **1 500,00** contra la cuenta a mano, **30 550 / 19 = 1 607,89**; y `[Kilos]` entre `[Cosechas]`, **3 394,44**.
4. **La cuenta que se guardó**: `[Camiones]` = `SUM` de `pesadas`, **1 607,89** con **19** camiones.

## Los números de control

Con segmentadores en `anio` = 2026 y `mes` de 1 a 4, salvo donde se dice.

| Dónde | Qué debe decir |
|---|---|
| La meta por finca, antes de las cosechas | La Union **5 000** · El Guayabo **9 440** · Santa Rosa **10 000** · total **24 440** |
| `pesadas.csv` | **54** filas de datos, **25** cosechas; la cosecha 7 en **4** camiones |
| Tal cual | total **30 550 / 24 440 / 125,00 %**; `[Cosechas]` **2 / 7 / 10 / 19**; `[Cosechas repetidas]` **10** |
| Agrupar por, básico | **25 filas** y **2 columnas**: `cosecha_id` y `Recuento` |
| Con `camion` en las llaves | **36 filas**; control **30 550 / 125,00 %**; `[Cosechas]` **2 / 5 / 7 / 14**; `[Cosechas repetidas]` **5** |
| Con las cinco llaves | **25 filas**; control **30 550 / 24 440 / 125,00 % / 9**; `[Cosechas repetidas]` **0** |
| `[Carga promedio]` (promedio de promedios) | La Union **1 050,00** · El Guayabo **1 866,67** · Santa Rosa **1 450,00** · total **1 500,00** |
| `[Carga promedio 2]` (kilos por cosecha) | **1 050,00 / 4 750,00 / 3 550,00** · total **3 394,44** |
| El Guayabo, a mano | cosechas 5, 6, 7 en **2 / 1 / 4** camiones; **14 250 / 7 = 2 035,71** |
| Bien: `[Camiones]` y `[Carga por camión]` | **2 / 7 / 10 / 19**; **1 050,00 / 2 035,71 / 1 420,00** · total **1 607,89** |
| Sin segmentadores | **77 550** kilos, **25** cosechas, **54** camiones, **1 436,11** por camión |

## Entrega

En `entregas/apellido-nombre/`, por *pull request*, **tres archivos**:

| Archivo | Qué lleva |
|---|---|
| `Ejercicio31_Apellido_Nombre.md` | cada medida con **su resultado anotado debajo**, las tablas que se piden y las respuestas |
| `clase31-llaves.png` | la tabla de control con `camion` en las llaves: `[Cosechas]` **14** y `[Cosechas repetidas]` **5** |
| `clase31-carga.png` | la tabla por finca con las cuatro medidas de carga, el total en **1 607,89** |

> El `.pbix` no se entrega: el repositorio lo ignora a propósito.

## Nota sobre el material

Los números de esta clase —las 54, 36 y 25 filas, la tabla de control tal cual, con `camion` y bien, las tres medidas de carga por finca, la cuenta a mano de El Guayabo y las tarjetas sin segmentadores— están **verificados contra los archivos publicados en `datos/csv_clase31/`** con `docente/clase31_verificacion_docente.py`, que modela **Agrupar por** (básico, con `camion` y con las cinco llaves) y cada medida con su contexto de filtro. Además comprueba que, bien agrupada, `h_cosecha` es **fila por fila** la `h_cosecha.csv` de la clase 19.

Lo que **ningún script puede verificar** es lo que hace Power Query en tu versión: dónde está el botón **Agrupar por**, los nombres literales de **Básico**, **Avanzado**, **Recuento de filas**, **Agregar agregación**, el nombre por omisión `Recuento` y el paso **Filas agrupadas**, y que las relaciones sobrevivan al agrupar. Si en tu máquina algo sale distinto, **anótalo en la entrega: eso puntúa**.
