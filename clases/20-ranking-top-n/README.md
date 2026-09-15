# Clase 20 · El Top 3 que tenía dos
**Martes 15 de septiembre**

**50 minutos de clase** y el resto de práctica. Sexta clase seguida del lado de Power BI: **hoy tampoco se prende Oracle.**

## Material

| Qué | Dónde |
|---|---|
| Diapositivas | [slides.md](slides.md) · [versión web](https://negatix092.github.io/Semillero_SQL/20-ranking-top-n.html) |
| Ejercicio práctico | [ejercicio.md](ejercicio.md) |
| Datos del día | **ninguno nuevo**: los cinco CSV de la clase 17, los mismos de [`datos/csv_clase19/`](../../datos/csv_clase19/) |

> **Hoy no se baja nada.** Se trabaja sobre el `.pbix` de la clase 19, **con Ver como apagado**.

## Qué hace falta tener listo

| | |
|---|---|
| Power BI Desktop | y nada más |
| Oracle, Docker, el OCMT | **no**, hoy tampoco |
| El `.pbix` de la clase 19 | con `[Kilos]`, `[Cosechas]` y la relación `dim_cultivo` → `h_cosecha` |

## De qué se trata

Después de *«¿cuánto?»*, la pregunta más pedida es *«¿quiénes son los primeros?»*. Ordenar una tabla no la contesta: un **Top 3** es un filtro sobre un lugar, y para filtrar por un lugar el lugar tiene que existir como número. Eso es una medida de **ranking**, con `RANKX`.

La primera versión pone **a todos en primer lugar**, porque en cada fila la tabla de la carrera ya viene filtrada a un solo cultivo. Se arregla con `ALL`, que trae de vuelta a Banano y Café empatados en quinto y un total que dice 1, y eso se calla con `HASONEVALUE` e `ISBLANK`:

```
Ranking =
IF(
    HASONEVALUE( dim_cultivo[cultivo] ) && NOT ISBLANK( [Kilos] ),
    RANKX( ALL( dim_cultivo ) , [Kilos] )
)
```

Con un filtro de objeto visual `[Ranking]` ≤ 3 sale el Top 3: Mango, Maíz y Guayaba, **28 450** kilos. Y en cuanto el gerente marca **perenne** en un segmentador, el Top 3 **se queda con dos filas**: Mango en 1, Guayaba en **3**, y el Cacao fuera, con ranking 4.

## El giro de hoy

`ALL( dim_cultivo )` quita **todos** los filtros de la dimensión: el de la fila, que era la idea, **y el del segmentador**, que no. El maíz, escondido en la pantalla, **sigue compitiendo y se queda con el segundo lugar**. Con **ciclo corto**, la tabla tiene un solo cultivo y dice **2**.

El arreglo es decidir **contra quién se compite**:

```
Ranking visible =
IF(
    HASONEVALUE( dim_cultivo[cultivo] ) && NOT ISBLANK( [Kilos] ),
    RANKX( ALLSELECTED( dim_cultivo ) , [Kilos] )
)
```

`ALLSELECTED` quita el filtro de la fila y **respeta los segmentadores**: con perenne, Mango 1, Guayaba 2, Cacao 3, y el Top 3 suma **20 750**.

> El `ALL` que arregló los cuatro primeros lugares **es el mismo** que dejó al maíz invisible en segundo lugar. Las dos medidas están bien escritas: una contesta *«¿en qué lugar va en la empresa?»* y la otra *«¿en qué lugar va entre lo que estoy viendo?»*. Un Top 3 casi siempre es la segunda.

## Lo que hay que saber al terminar

- Que **ordenar no es rankear**: un Top 3 necesita el lugar como número
- `RANKX( tabla , expresión )`: la tabla dice **quién compite**, la expresión **qué se mide**
- Por qué `RANKX( dim_cultivo , … )` pone a todos en primer lugar: **el contexto de la fila**
- Que `RANKX` cuenta el vacío **como cero**, y que por eso reaparecen filas sin kilos
- `HASONEVALUE` e `ISBLANK` para que el ranking **se calle** en el total y en lo que no cosechó
- El **filtro de objeto visual** sobre una medida, y que **también filtra el total**
- **`ALL` contra `ALLSELECTED`**: toda la empresa contra lo que estoy viendo, y que sin segmentadores dan lo mismo
- Que `ALL( dim_cultivo )` y `ALL( dim_cultivo[cultivo] )` **no hacen lo mismo** con un segmentador en otra columna
- **N principales** en el panel Filtros, sin fórmula
- Que un ranking **esconde la distancia**: 50 kilos y 12 100 kilos se escriben igual, «uno más»

## La idea del día

**Un ranking siempre es contra alguien: ALL compite contra toda la empresa, ALLSELECTED contra lo que estás viendo, y el tablero no te dice cuál escogiste.**

## Las cuatro cosas que son la clase

Si el día se complica y hay que recortar, estas no se recortan:

1. **Los cuatro primeros lugares** sin `ALL`, y por qué: el contexto de la fila.
2. **El Top 3 con dos filas** en cuanto se marca perenne, sin un solo aviso.
3. **El maíz invisible en segundo lugar**: `ALL` también quita el segmentador.
4. **`ALLSELECTED` y el 20 750.** Y cuál de los dos rankings contesta qué.

## Los números de control

Todos con segmentadores en `anio` = 2026 y `mes` en 1–4.

| Dónde | Qué debe decir |
|---|---|
| La tabla por cultivo | Mango **12 700** · Maiz **9 800** · Guayaba **5 950** · Cacao **2 100** · total **30 550** y **9** cosechas |
| `RANKX( dim_cultivo , … )` | **1** en las cuatro filas y en el total |
| `RANKX( ALL( dim_cultivo ) , … )` | 1, 2, 3, 4 · Banano y Café **5** · total **1** |
| Con `HASONEVALUE` e `ISBLANK` | 1, 2, 3, 4 · total vacío |
| Top 3 (`[Ranking]` ≤ 3), sin segmentador `tipo` | Mango, Maiz, Guayaba · **28 450** · 7 cosechas |
| **…con perenne** | **Mango 1, Guayaba 3** · **18 650** · dos filas ← el error del día |
| …con ciclo corto | **Maiz 2**, solo |
| **`[Ranking visible]` con perenne** | Mango 1, Guayaba 2, Cacao 3 · **20 750** · 8 cosechas |
| …con ciclo corto | Maiz **1** |
| N principales 3 por `[Kilos]` | sin segmentador **28 450** · con perenne **20 750** |
| `[Ranking finca]`, 2026 | El Guayabo **1** (14 250) · Santa Rosa **2** (14 200) · La Union **3** (2 100) |
| …2025, meses 1–4 | Santa Rosa **1** (12 300) · El Guayabo **2** (9 200) · La Union **3** (2 000) |

## Entrega

En `entregas/apellido-nombre/`, por *pull request*, **dos archivos**:

| Archivo | Qué lleva |
|---|---|
| `Ejercicio20_Apellido_Nombre.md` | cada medida en un bloque de código con **su resultado anotado debajo**, la tabla de los tres segmentadores de la parte E, y las respuestas de la parte G |
| `clase20-top3.png` | captura con **perenne** marcado: la tabla del Top 3 con **tres filas**, `[Ranking]` y `[Ranking visible]`, y el total **20 750** |

> El `.pbix` no se entrega: el repositorio lo ignora a propósito.

## Nota sobre el material

Los números de esta clase —los cuatro primeros lugares, el quinto de Banano y Café, el Top 3 de 28 450, las dos filas con perenne, el Maíz en segundo con ciclo corto, el 20 750 con `ALLSELECTED` y los rankings por finca— están **verificados contra los CSV publicados en `datos/csv_clase19/`** con `docente/clase20_verificacion_docente.py`, que modela `RANKX` con el vacío como cero y los empates compartiendo lugar, y distingue lo que quita `ALL` de lo que respeta `ALLSELECTED`.

Lo que **ningún script puede verificar** son los nombres de menú de Power BI en tu versión y tu idioma: **Filtros en este objeto visual**, *es menor o igual que*, **N principales**, **Segmentación de datos**. Si en tu máquina algo se llama distinto, **anótalo en la entrega: eso puntúa**, igual que documentar una discrepancia del enunciado.
