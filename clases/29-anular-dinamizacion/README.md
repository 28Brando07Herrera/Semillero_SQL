# Clase 29 · La finca que se llamaba Total
**Martes 29 de septiembre**

**50 minutos de clase** y el resto de práctica. Tercera clase seguida **adentro de Power Query**: **hoy tampoco se prende Oracle.**

## Material

| Qué | Dónde |
|---|---|
| Diapositivas | [slides.md](slides.md) · [versión web](https://negatix092.github.io/Semillero_SQL/29-anular-dinamizacion.html) |
| Ejercicio práctico | [ejercicio.md](ejercicio.md) |
| Datos del día | [`datos/csv_clase29/`](../../datos/csv_clase29/): cuatro CSV de la clase 19, **idénticos** (`h_cosecha`, `dim_tiempo`, `dim_finca`, `dim_cultivo`), más **`metas_planeacion.csv`**, la hoja de metas de 2026 a lo ancho. **`h_meta.csv` no viene**: se construye en clase |

> **Hoy sí se baja algo.** Copia `datos/csv_clase29/` a `C:\agrodb29\` y empieza con un **`.pbix` vacío**, como en la 24, la 26, la 27 y la 28.

## Qué hace falta tener listo

| | |
|---|---|
| Power BI Desktop | y nada más |
| Oracle, Docker, el OCMT | **no**, hoy tampoco |
| El `.pbix` de clases anteriores | **no**: hoy se arma uno nuevo, y `h_meta` sale de Power Query |

## De qué se trata

Planeación cambió de sistema y ya no manda `h_meta.csv`, la tabla larga de 36 filas que el modelo usa desde la clase 17. Manda **su hoja**: una fila por finca y **una columna por mes**, como se lee a ojo. El correo dice que son **las mismas metas de siempre**, 47 000 kg en el año.

Un modelo no puede usar los meses como encabezados: la relación con `dim_tiempo` necesita **una columna de fecha**, y `[Meta]` necesita **una columna de kilos**. La herramienta es **Anular dinamización de otras columnas**: se marcan las columnas que se quedan (`finca_id` y `finca`) y cada celda de la hoja se vuelve una fila, con su encabezado al lado.

## El giro de hoy

La hoja trae dos totales, como cualquier hoja hecha para leerse: **una columna Total** al final y **una fila Total** abajo, con `finca_id` vacío.

La columna se delata sola: después de anular la dinamización es un «mes» que se llama `Total`, y al cambiar `fecha_mes` a Fecha da **cuatro `Error`**. Con la regla de la 27 —**los `Error` se leen antes de quitarlos**— se encuentra y se filtra por su nombre. Quedan **48 filas** y cero errores.

La fila no da ningún error: para Power Query es **una finca más**, con doce meses válidos. En la tabla de control cada finca sale exacta —42,00, 150,95 y 142,00 %—, aparece una fila **`(En blanco)`** con **24 440** de meta, y la empresa baja de **125,00 %** a **62,50 %**: la meta se sumó **dos veces**. En todo el año, **94 000** en vez de 47 000.

Y hay un segundo arreglo obvio: filtrar el `(En blanco)` **en el objeto visual**. La tabla regresa a **125,00 %** y pasa la prueba del número viejo… porque la prueba se hizo en esa misma tabla. Una tarjeta al lado dice **48 880**, y la tabla por mes cobra cada meta dos veces: marzo en **78,26 %** en vez de **156,52 %**. El filtro quitó la fila **de una tabla**, no del modelo.

El arreglo va en Power Query: filtrar `finca_id` sin `(null)`. **36 filas**, **24 440**, **125,00 %**, y el año en **47 000**, que es justo el Total de la hoja: **el total sirve para comprobar, no para cargar**.

> La hoja no estaba mal. Estaba hecha **para leerse**, y la cargamos **para sumarse**.

## Lo que hay que saber al terminar

- **A lo ancho** contra **a lo largo**, y por qué un modelo necesita la segunda
- **Anular dinamización de otras columnas**: `Atributo` y `Valor`, y cuántas filas salen (filas × columnas anuladas)
- Por qué **«otras columnas»** es la que aguanta una hoja que crece, y por qué por lo mismo **se trae el Total**
- Que la **columna** Total avisa con `Error` y la **fila** Total no avisa nada
- **Vista → Calidad de columna**: un `finca_id` con **25 %** vacío
- Que un **filtro en el objeto visual** arregla esa tabla y deja el error en el modelo
- `[Meta sin finca]` con `ISBLANK`, y la prueba de **filas = fincas × meses**

## La idea del día

**Un total escrito en la hoja es, para Power Query, una finca más.**

## Las cuatro cosas que son la clase

Si el día se complica y hay que recortar, estas no se recortan:

1. **Anular dinamización de otras columnas**: 4 filas × 13 columnas = **52 filas**, y los cuatro `Error` de la columna Total, leídos.
2. **La fila Total**: `(En blanco)` con **24 440**, la empresa en **62,50 %** y ni un error.
3. **El filtro del objeto visual**: la tabla en **125,00 %**, la tarjeta en **48 880** y marzo en **78,26 %**.
4. **El arreglo en Power Query**: **36 filas**, **125,00 %**, y el año en **47 000**, igual que el Total de la hoja.

## Los números de control

Con segmentadores en `anio` = 2026 y `mes` de 1 a 4, salvo donde se dice.

| Dónde | Qué debe decir |
|---|---|
| La tabla por finca, antes de las metas | La Union **2 100 / 2** · El Guayabo **14 250 / 3** · Santa Rosa **14 200 / 4** · total **30 550 / 9** |
| Power Query, la hoja | **4 filas, 15 columnas**; anulada con «otras columnas», **52 filas**; `fecha_mes` como Fecha, **4 `Error`** |
| Sin la columna Total | **48 filas**, cero `Error`; `finca_id` con **25 %** vacío |
| La tabla de control con la fila Total | cada finca **42,00 / 150,95 / 142,00 %**; `(En blanco)` **24 440**; total **30 550 / 48 880 / 62,50 %**; `[Filas de meta]` **16** |
| Con la fila Total, solo `anio` = 2026 | total **30 550 / 94 000 / 32,50 %** |
| Con el filtro en el objeto visual | tabla **30 550 / 24 440 / 125,00 %**, `[Filas de meta]` **12**; tarjeta `[Meta]` **48 880**; `[Meta sin finca]` **24 440** |
| Por mes, con la fila Total | Enero **8 080** · Febrero **10 400** · Marzo **10 800 / 13 800 / 78,26 %** · Abril **19 750 / 16 600 / 118,98 %** |
| Por mes, bien | Enero **4 040** · Febrero **5 200** · Marzo **6 900 / 156,52 %** · Abril **8 300 / 237,95 %** |
| Sin la fila Total | **36 filas**; control **30 550 / 24 440 / 125,00 % / 9**; `[Meta]` **24 440**; `[Meta sin finca]` vacía |
| El año 2026, bien | Santa Rosa **20 000 / 71,00 %** · El Guayabo **19 000 / 75,00 %** · La Union **8 000 / 26,25 %** · total **47 000 / 65,00 %**, con **36** filas de meta |

## Entrega

En `entregas/apellido-nombre/`, por *pull request*, **tres archivos**:

| Archivo | Qué lleva |
|---|---|
| `Ejercicio29_Apellido_Nombre.md` | cada medida con **su resultado anotado debajo**, las tablas que se piden y las respuestas |
| `clase29-calidad.png` | Power Query con la **calidad de columna** de `finca_id` en **25 %** vacío |
| `clase29-metas.png` | la tabla de control en **125,00 %** sin filtros en el objeto visual, con `[Meta]` en **24 440** y `[Meta sin finca]` vacía |

> El `.pbix` no se entrega: el repositorio lo ignora a propósito.

## Nota sobre el material

Los números de esta clase —las 52, 48 y 36 filas, las tablas de control con y sin la fila Total, el filtro del objeto visual, la tabla por mes y el año— están **verificados contra los CSV publicados en `datos/csv_clase29/`** con `docente/clase29_verificacion_docente.py`, que modela la anulación de la dinámica (cada celda, una fila), el cambio de tipo con sus `Error`, la fila sin finca como `(En blanco)` y el filtro del objeto visual. Además comprueba que, bien construida, `h_meta` es **fila por fila** la `h_meta.csv` de la clase 19.

Lo que **ningún script puede verificar** es lo que hace Power Query en tu versión: los nombres literales de las opciones de **Anular dinamización**, que los encabezados con forma de fecha se promuevan solos, que las columnas nuevas se llamen `Atributo` y `Valor`, y que la fila sin finca aparezca como `(En blanco)`. Si en tu máquina algo sale distinto, **anótalo en la entrega: eso puntúa**.
