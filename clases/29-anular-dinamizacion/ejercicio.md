# Ejercicio práctico 29 · Las metas a lo largo

**Duración: 2 horas · Individual · Solo Power BI Desktop · Entrega: un archivo `.md` y dos capturas**

---

## Qué vas a lograr hoy

1. Armar el modelo de siempre **sin** `h_meta.csv`.
2. Construir `h_meta` desde la hoja de planeación con **Anular dinamización de otras columnas**.
3. Encontrar la **columna** Total por sus `Error`, y filtrarla por su nombre.
4. Encontrar la **fila** Total, que no dio ningún error, y ver lo que le hizo al cumplimiento de la empresa.
5. Caer en el segundo arreglo obvio, **el filtro del objeto visual**, y encontrar dónde sigue la meta duplicada.
6. Quitar la fila Total **en Power Query**, y comprobar el año contra el Total de la hoja.

**El número que prueba que el tablero quedó bien: 125,00 % en la tabla de control, sin filtros en el objeto visual, con `[Filas de meta]` en 36 para el año y `[Meta sin finca]` vacía.** El que prueba que entendiste la clase es que sepas por qué la columna Total dio `Error` y la fila Total no.

---

## Antes de empezar

De nuevo solo Power BI: hoy tampoco se prende Oracle, ni Docker, ni el driver.

| | |
|---|---|
| Oracle, Docker, OCMT, `GRANT` | **no** |
| Power BI Desktop | **sí**, y es lo único |

### Lo que se baja hoy

**Hoy sí se baja algo:** [`datos/csv_clase29/`](../../datos/csv_clase29/). Son cuatro CSV de la clase 19, **idénticos** (`h_cosecha`, `dim_tiempo`, `dim_finca` y `dim_cultivo`), y uno nuevo: **`metas_planeacion.csv`**, la hoja de metas de 2026 como la manda planeación. **`h_meta.csv` no viene**: hoy la construyes tú.

Copia la carpeta completa a `C:\agrodb29\` y trabaja sobre esa copia.

> **Hoy se empieza con un `.pbix` vacío**, como en la 24, la 26, la 27 y la 28.

### El correo de planeación

> *«Cambiamos de sistema y ahora les mandamos la hoja tal como la vemos. Son **las mismas metas de siempre**: 47 000 kg en el año. Solo cambió el formato.»*

---

## Cómo se entrega

En `entregas/apellido-nombre/`, por *pull request*, **tres archivos**:

| Archivo | Qué lleva |
|---|---|
| `Ejercicio29_Apellido_Nombre.md` | cada medida en un bloque de código **con su resultado anotado debajo**, las tablas que se piden y las respuestas a las preguntas |
| `clase29-calidad.png` | **Power Query** con `h_meta` abierta y la **calidad de columna** de `finca_id` en **25 % vacío** |
| `clase29-metas.png` | la **tabla de control** en **125,00 %** sin filtros en el objeto visual, con tarjetas de `[Meta]` en **24 440** y `[Meta sin finca]` vacía |

> El `.pbix` no se entrega: el repositorio lo ignora a propósito.

---

## Parte A · El modelo sin metas (20 min)

### A0. La configuración regional, antes de cargar nada

Como en la 27 y la 28: **Archivo → Opciones y configuración → Opciones → Archivo actual → Configuración regional** → **Español (México)** → **Aceptar**.

### A1. Cargar

1. En **Archivo actual → Carga de datos**, apaga **«Detectar automáticamente nuevas relaciones después de cargar los datos»**.
2. **Inicio → Obtener datos → Texto o CSV**, uno por uno, con **Cargar**: `h_cosecha`, `dim_tiempo`, `dim_finca` y `dim_cultivo`. **`metas_planeacion.csv` todavía no.**

### A2. Las tres relaciones de las cosechas

| # | De | A |
|---|---|---|
| 1 | `h_cosecha[finca_id]` | `dim_finca[finca_id]` |
| 2 | `h_cosecha[cultivo_id]` | `dim_cultivo[cultivo_id]` |
| 3 | `h_cosecha[fecha]` | `dim_tiempo[fecha]` |

### A3. El calendario y las medidas de cosecha

1. `dim_tiempo` → **Marcar como tabla de fechas** → `fecha`. `nombre_mes` → **Ordenar por columna** → `mes`.
2. Con `h_cosecha` seleccionada, **Nueva medida**:

```
Kilos = SUM( h_cosecha[kg] )
```

```
Cosechas = COUNTROWS( h_cosecha )
```

### A4. La tabla de control, sin metas todavía

Segmentadores `dim_tiempo[anio]` = **2026** y `dim_tiempo[mes]` de **1 a 4**. Tabla con `dim_finca[finca]`, `[Kilos]` y `[Cosechas]`. Tiene que salir La Union **2 100 / 2**, El Guayabo **14 250 / 3**, Santa Rosa **14 200 / 4**, total **30 550 / 9**.

**A5.** Abre `metas_planeacion.csv` en el Bloc de notas. Contesta **antes** de seguir: ¿cuántas filas tiene que tener `h_meta` para guardar una meta por finca y por mes? ¿Y cuánto tiene que sumar el año, según el correo? En la parte E vas a volver a estas dos respuestas.

---

## Parte B · Anular dinamización (20 min)

**B1.** **Inicio → Obtener datos → Texto o CSV** → `metas_planeacion.csv` → **Transformar datos** (no *Cargar*). Anota cuántas **filas** y **columnas** dice abajo a la izquierda. Si los encabezados salen como `Column1`, `Column2`…, usa **Inicio → Usar la primera fila como encabezado**.

**B2.** Clic en el encabezado **`finca_id`** y **Ctrl** + clic en **`finca`**. Clic derecho sobre uno de los dos → **Anular dinamización de otras columnas**. Anota cuántas filas quedan: tiene que salir **52**. Si no ves la barra de fórmulas, **Vista → Barra de fórmulas**, y copia **literal** la fórmula del paso.

**B3.** Renombra **`Atributo`** → **`fecha_mes`** y **`Valor`** → **`kg_meta`** (doble clic en el encabezado).

**B4.** Clic en el ícono de tipo de `fecha_mes` → **Fecha**. ¿Cuántas celdas dicen `Error`? Tiene que salir **4**. Antes de tocarlas: en **Pasos aplicados**, clic en el paso **anterior** al cambio de tipo y anota qué decía `fecha_mes` en esas cuatro filas, con su `finca` y su `kg_meta`.

**B5.** Borra el paso del cambio de tipo (la **X** en **Pasos aplicados**). Abre el filtro de `fecha_mes`, desmarca **`Total`** y **Aceptar**. Ahora sí: `fecha_mes` → **Fecha**, y `kg_meta` → **Número entero**. Tienen que quedar **48 filas** y **cero** `Error`.

**B6.** En el panel de consultas, clic derecho sobre `metas_planeacion` → **Cambiar nombre** → **`h_meta`**. **Inicio → Cerrar y aplicar.**

**B7.** Las dos relaciones de las metas:

| # | De | A |
|---|---|---|
| 4 | `h_meta[finca_id]` | `dim_finca[finca_id]` |
| 5 | `h_meta[fecha_mes]` | `dim_tiempo[fecha]` |

Y con `h_meta` seleccionada, **Nueva medida**:

```
Meta = SUM( h_meta[kg_meta] )
```

```
Cumplimiento = DIVIDE( [Kilos] , [Meta] )
```

```
Filas de meta = COUNTROWS( h_meta )
```

---

## Parte C · La finca que se llamaba Total (20 min)

**C1.** Agrega a la tabla de control `[Meta]`, `[Cumplimiento]` y `[Filas de meta]`. Copia la tabla completa. Tiene que salir cada finca como siempre (**42,00 / 150,95 / 142,00 %**), una fila **`(En blanco)`** con meta **24 440**, y el total en **30 550 / 48 880 / 62,50 %**, con `[Filas de meta]` en **16**.

**C2.** **Transformar datos** → `h_meta` → **Vista → Calidad de columna**. Anota lo que dice debajo de `finca_id`: **válido**, **error** y **vacío**. Tiene que salir **25 %** vacío.

> **Toma aquí la captura `clase29-calidad.png`**: Power Query con `h_meta` abierta y la calidad de columna de `finca_id` a la vista.

**C3.** Abre el filtro de `finca_id` y deja marcado **solo `(null)`**. ¿Cuántas filas quedan, y qué dice la columna `finca`? Copia los doce valores de `kg_meta` y compáralos contra la última fila de `metas_planeacion.csv`. Luego **borra ese paso de filtro**: todavía no es el arreglo.

**C4.** En dos líneas: la columna Total de la hoja dio `Error` en B4. La fila Total no dio ninguno. ¿Por qué?

**C5.** Quita el segmentador de `mes` (deja `anio` = 2026). Copia el total de la tabla: tiene que salir **30 550 / 94 000 / 32,50 %**. ¿Por qué **94 000**, si el correo dice 47 000?

**C6.** B5 quitó la columna Total por su nombre, **antes** del cambio de tipo, y no con **Quitar errores**. En una línea: si hubieras usado **Quitar errores**, ¿habría dado lo mismo **hoy**? ¿Y qué habría pasado si, además de la columna Total, una celda de verdad hubiera traído un error?

---

## Parte D · El segundo arreglo obvio (25 min) — es la parte que más vale

**D1.** Regresa el segmentador de `mes` a **1–4**. Selecciona la tabla de control → panel **Filtros** → **Filtros en este objeto visual** → `finca` → marca todo **menos `(En blanco)`**.

**D2.** Las tres pruebas. Anota cada una:

| Prueba | Tiene que decir |
|---|---|
| La fila `(En blanco)` | ya no sale |
| Total de la tabla de control | 30 550 / 24 440 / 125,00 % |
| `[Filas de meta]` en el total de esa tabla | 12 |

**D3.** En la **misma página**, una **tarjeta** con `[Meta]`. Anota lo que dice: tiene que salir **48 880**.

**D4.** Con `h_meta` seleccionada, **Nueva medida**:

```
Meta sin finca = CALCULATE( [Meta] , ISBLANK( h_meta[finca_id] ) )
```

Ponla en una tarjeta al lado. Tiene que decir **24 440**.

**D5.** **Página nueva**, con los mismos segmentadores (`anio` 2026, `mes` 1–4). Tabla con `dim_tiempo[nombre_mes]`, `[Kilos]`, `[Meta]` y `[Cumplimiento]`. Copia la tabla. Tiene que salir Enero **8 080**, Febrero **10 400**, Marzo **10 800 / 13 800 / 78,26 %**, Abril **19 750 / 16 600 / 118,98 %**. ¿Aparece alguna fila `(En blanco)`? ¿Por qué no?

**D6.** Con `metas_planeacion.csv` abierto, calcula **a mano** la meta de la empresa en cada mes sumando **solo las tres fincas**, y el cumplimiento que le toca a marzo y a abril. Copia esta tabla y llénala:

| Mes | Santa Rosa | El Guayabo | La Union | Meta del mes | Kilos | Cumplimiento |
|---|---|---|---|---|---|---|
| Enero | | | | | — | — |
| Febrero | | | | | — | — |
| Marzo | | | | | 10 800 | |
| Abril | | | | | 19 750 | |
| **Total** | **10 000** | **9 440** | **5 000** | **24 440** | **30 550** | **125,00 %** |

Tiene que salir **4 040 / 5 200 / 6 900 / 8 300**, y marzo en **156,52 %**, abril en **237,95 %**.

**D7.** En una línea: ¿qué arregló el filtro de D1, y qué **no** arregló? En otra: ¿por qué la prueba del número viejo **pasó**?

---

## Parte E · El arreglo, en Power Query (20 min)

**E1.** Quita el filtro de `finca` del objeto visual (la goma de borrar del filtro, o desmarca la casilla).

**E2.** **Transformar datos** → `h_meta` → filtro de `finca_id` → desmarca **`(null)`** → **Aceptar**. Anota cuántas filas quedan y la calidad de columna de `finca_id`: tiene que salir **36** filas y **0 %** vacío. **Cerrar y aplicar.**

**E3.** La tabla de control, **sin filtros en el objeto visual**: tiene que decir **30 550 / 24 440 / 125,00 % / 9**, sin fila `(En blanco)`. Las tarjetas: `[Meta]` **24 440** y `[Meta sin finca]` **vacía**.

> **Toma aquí la captura `clase29-metas.png`**: la tabla de control en 125,00 % y las dos tarjetas.

**E4.** La tabla por mes de D5. Tiene que salir **4 040 / 5 200 / 6 900 / 8 300**, y marzo **156,52 %**, abril **237,95 %**: los mismos de tu tabla a mano.

**E5.** Quita el segmentador de `mes` (deja `anio` = 2026). Tabla por finca con `[Kilos]`, `[Meta]`, `[Cumplimiento]` y `[Filas de meta]`. Tiene que salir Santa Rosa **14 200 / 20 000 / 71,00 %**, El Guayabo **14 250 / 19 000 / 75,00 %**, La Union **2 100 / 8 000 / 26,25 %**, total **30 550 / 47 000 / 65,00 %**, con **36** filas de meta. Compara cada `[Meta]` contra la columna Total de la hoja.

**E6.** Vuelve a tus respuestas de A5. ¿Acertaste las dos?

---

## Parte F · La fórmula del paso, y preguntas de cierre (15 min)

**F1.** **Transformar datos** → `h_meta` → **Inicio → Editor avanzado**. Copia **literal** la línea de `Table.UnpivotOtherColumns`. ¿Qué columnas nombra: las que se quedan o las que se anulan?

**F2.** El año que viene planeación agrega a la misma hoja las columnas `2027-01-01` a `2027-12-01`. En dos líneas: ¿qué pasa con tu consulta al **Actualizar**? ¿Y qué pasaría si hubieras usado **Anular solo la dinamización de las columnas seleccionadas** con los doce meses de 2026?

**F3.** Preguntas de cierre:

1. En una línea: ¿qué hace **Anular dinamización**, dicho en filas y columnas?
2. En una línea: escribe la **regla de detección** del día, tomando como base la de la 28: *«una combinación que cambia el número de filas no agregó columnas: agregó cosechas»*.
3. En dos líneas: el filtro del objeto visual (hoy) y `Quitar duplicados` (clase 28). ¿En qué se parecen, y cuál de los dos deja el error **dentro del modelo**?
4. En una línea: la clase 21 tuvo una fila de total que **no** era la suma de las filas. Hoy la hoja traía una fila de total que **sí** lo era. ¿Por qué hoy eso fue el problema?
5. En dos líneas: planeación agrega una columna **`Observaciones`** con texto al final de la hoja. Con «otras columnas», ¿dónde aparece, y qué te avisaría?

---

## Si algo falla

| Síntoma | Qué pasó | Qué haces |
|---|---|---|
| Los encabezados son `Column1`, `Column2`… | la primera fila no se promovió | **Inicio → Usar la primera fila como encabezado** |
| En B2 salen **8 filas** y los meses siguen de columnas | seleccionaste los meses y usaste «otras columnas» | borra el paso; selecciona **`finca_id` y `finca`** |
| En B2 salen **48 filas** y `Total` sigue de columna | seleccionaste solo los doce meses y usaste **Anular dinamización de columnas** | está bien: sigue desde B3 y en B4 no vas a ver `Error`; anótalo |
| En B4 salen **más de 4** `Error` | `fecha_mes` no estaba en formato `2026-01-01` | revisa que el CSV sea el de `datos/csv_clase29/` |
| No se puede crear la relación 5 | `fecha_mes` quedó como texto | cámbiala a **Fecha** en Power Query |
| `[Meta]` da error | `kg_meta` quedó como texto (**ABC**) | **Número entero** en Power Query |
| Las medidas dicen que no existe `h_meta` | la consulta se sigue llamando `metas_planeacion` | B6: cámbiale el nombre y vuelve a **Cerrar y aplicar** |
| En C1 **no** sale `(En blanco)` | quitaste la fila Total antes de tiempo | bien visto: anótalo, y haz C y D con la fila puesta |
| En E3 sigue el **62,50 %** | no diste **Cerrar y aplicar**, o el filtro de E2 quedó antes de un paso que lo deshace | revisa **Pasos aplicados**: el filtro de `finca_id` tiene que ser el último |
| Los decimales o los miles salen distintos | configuración regional de tu Windows | **no es un error**, anótalo y sigue |

> ### La regla de los 20 minutos sigue vigente
> Veinte minutos atorado en lo mismo: lo escribes en tu archivo empezando con `DUDA`, o abres un *issue*, y sigues con lo siguiente. **Atorarse no baja la nota. Quedarse callado sí.**

---

## Plan B · Si Power BI Desktop no abre en tu máquina

1. Ponte con un compañero: el modelo se arma en una sola máquina.
2. **Tú escribes todas las medidas** en tu propio archivo `.md`, con sus resultados, y anotas con quién trabajaste.
3. **La tabla de D6 y las respuestas de A5, C4, C5, C6, D7, E6, F2 y F3 las haces tú**, con tus propias palabras y con `metas_planeacion.csv` abierto: se contestan leyendo la hoja.
4. Las capturas son las mismas para los dos, y los dos lo dicen en un comentario.

**Con el Plan B completo se llega a 100 de 100.** Lo que se califica es que sepas qué fila de la hoja se sumó dos veces y dónde se quita, no de quién era la laptop.

---

## Rúbrica (100 puntos)

| Criterio | Pts |
|---|---|
| Parte A: el modelo con sus tres relaciones, la tabla en 30 550 y A5 | 10 |
| Parte B: las 52 filas, la fórmula literal, los cuatro `Error` leídos antes de quitarlos, las 48 filas y las relaciones 4 y 5 | 15 |
| Parte C: el `(En blanco)` y el 62,50 %, la captura de la calidad de columna, y C3 a C6 | 15 |
| **Parte D: las tres pruebas, el 48 880 de la tarjeta, `[Meta sin finca]`, la tabla por mes, la tabla de D6 a mano y D7** | **25** |
| Parte E: las 36 filas, el 125,00 % sin filtros, las tarjetas, el año en 47 000 contra la hoja, y la captura | 20 |
| Parte F: la línea literal de F1, F2, y las cinco preguntas con criterio | 15 |

Los criterios suman **100** exactos.

> **Lo que más se califica hoy no es el clic en «otras columnas»**, que se copia del enunciado. Es la tabla de D6: que hayas sacado a mano la meta de cada mes con las tres fincas, y que sepas explicar por qué la tabla de control decía 125,00 % mientras la tabla por mes cobraba cada meta dos veces.
