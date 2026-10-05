# Ejercicio práctico 30 · La carpeta de la báscula

**Duración: 2 horas · Individual · Solo Power BI Desktop · Entrega: un archivo `.md` y dos capturas**

---

## Qué vas a lograr hoy

1. Armar el modelo de siempre **sin** `h_cosecha.csv`.
2. Construir `h_cosecha` combinando **todos los archivos de una carpeta**.
3. Encontrar el archivo que sobra con **`Source.Name`**, ver por qué **Quitar duplicados** no lo quita, y filtrarlo.
4. Revisar **los dos años**, no solo el control de enero–abril, y encontrar el mes que perdió sus kilos.
5. Caer en el segundo arreglo obvio, **quitar los `null`**, y contar lo que se llevó.
6. Arreglar el mes en el **archivo de ejemplo**, para que el arreglo valga para cada archivo.

**El número que prueba que el tablero quedó bien: 125,00 % con 30 550 en la tabla de control, y los dos años en 77 550 con 25 cosechas, `[Cosechas repetidas]` en 0 y `[Cosechas sin kilos]` vacía.** El que prueba que entendiste la clase es que sepas por qué julio no dio ningún `Error`.

---

## Antes de empezar

De nuevo solo Power BI: hoy tampoco se prende Oracle, ni Docker, ni el driver.

| | |
|---|---|
| Oracle, Docker, OCMT, `GRANT` | **no** |
| Power BI Desktop | **sí**, y es lo único |

### Lo que se baja hoy

**Hoy sí se baja algo:** [`datos/csv_clase30/`](../../datos/csv_clase30/). Son tres CSV de la clase 19, **idénticos** (`dim_tiempo`, `dim_finca` y `h_meta`), y una carpeta nueva: **`bascula/`**, con las cosechas como las manda la báscula, un archivo por mes. **`h_cosecha.csv` no viene**: hoy la construyes tú.

Copia la carpeta completa a `C:\agrodb30\` y trabaja sobre esa copia. Tiene que quedar `C:\agrodb30\bascula\` con **15 archivos**.

> **Hoy se empieza con un `.pbix` vacío**, como en la 24 y de la 26 a la 29.

### El correo de la báscula

> *«Ya no les mandamos `h_cosecha.csv`. Son **las mismas cosechas de siempre**, un archivo por mes. Cada mes que pesemos, cae uno nuevo en la carpeta.»*

---

## Cómo se entrega

En `entregas/apellido-nombre/`, por *pull request*, **tres archivos**:

| Archivo | Qué lleva |
|---|---|
| `Ejercicio30_Apellido_Nombre.md` | cada medida en un bloque de código **con su resultado anotado debajo**, las tablas que se piden y las respuestas a las preguntas |
| `clase30-archivos.png` | la **tabla por `Source.Name`** con la copia de abril a la vista, **antes** de filtrarla |
| `clase30-anios.png` | la **tabla de los dos años** en **77 550 / 25**, con tarjetas de `[Cosechas repetidas]` en **0** y `[Cosechas sin kilos]` vacía |

> El `.pbix` no se entrega: el repositorio lo ignora a propósito.

---

## Parte A · El modelo sin cosechas (15 min)

### A0. La configuración regional, antes de cargar nada

Como de la 27 a la 29: **Archivo → Opciones y configuración → Opciones → Archivo actual → Configuración regional** → **Español (México)** → **Aceptar**.

### A1. Cargar

1. En **Archivo actual → Carga de datos**, apaga **«Detectar automáticamente nuevas relaciones después de cargar los datos»**.
2. **Inicio → Obtener datos → Texto o CSV**, uno por uno, con **Cargar**: `dim_tiempo`, `dim_finca` y `h_meta`. **La carpeta `bascula` todavía no.**

### A2. Las dos relaciones de las metas

| # | De | A |
|---|---|---|
| 1 | `h_meta[finca_id]` | `dim_finca[finca_id]` |
| 2 | `h_meta[fecha_mes]` | `dim_tiempo[fecha]` |

### A3. El calendario y la meta

1. `dim_tiempo` → **Marcar como tabla de fechas** → `fecha`. `nombre_mes` → **Ordenar por columna** → `mes`.
2. Con `h_meta` seleccionada, **Nueva medida**:

```
Meta = SUM( h_meta[kg_meta] )
```

Segmentadores `dim_tiempo[anio]` = **2026** y `dim_tiempo[mes]` de **1 a 4**. Tabla con `dim_finca[finca]` y `[Meta]`: La Union **5 000**, El Guayabo **9 440**, Santa Rosa **10 000**, total **24 440**.

**A4.** Abre `C:\agrodb30\bascula\` en el Explorador de archivos, con la vista **Detalles**. Contesta **antes** de seguir: ¿cuántos archivos hay? ¿Cuántas filas tiene que tener `h_cosecha`, según el correo? ¿Cuántos kilos en 2025? (La clase 16 lo dijo: 47 000.) En la parte E vas a volver a estas respuestas.

---

## Parte B · Combinar la carpeta (20 min)

**B1.** **Inicio → Obtener datos → Más… → Carpeta → Conectar** → `C:\agrodb30\bascula` → **Aceptar**. Sale la lista de archivos. Abajo, **Combinar → Combinar y transformar datos** (no *Cargar*, no *Transformar datos*).

**B2.** En la ventana **Combinar archivos**, deja **Archivo de ejemplo: Primer archivo**. Anota qué archivo es el primero y qué columnas enseña la vista previa. **Aceptar**.

**B3.** En el panel de consultas, a la izquierda, anota **todo** lo que apareció: la consulta `bascula` y lo que quedó adentro de la carpeta de ayuda. En `bascula`, anota cuántas **filas** y **columnas** dice abajo a la izquierda, y el nombre de la **primera** columna.

**B4.** Revisa los tipos: `fecha` como **Fecha** y `kg` como **Número entero**. Si alguna no, cámbiala. Clic derecho sobre `bascula` → **Cambiar nombre** → **`h_cosecha`**. **Inicio → Cerrar y aplicar.**

**B5.** Las dos relaciones de las cosechas:

| # | De | A |
|---|---|---|
| 3 | `h_cosecha[finca_id]` | `dim_finca[finca_id]` |
| 4 | `h_cosecha[fecha]` | `dim_tiempo[fecha]` |

Y con `h_cosecha` seleccionada, **Nueva medida**:

```
Kilos = SUM( h_cosecha[kg] )
```

```
Cosechas = COUNTROWS( h_cosecha )
```

```
Cumplimiento = DIVIDE( [Kilos] , [Meta] )
```

---

## Parte C · La copia de abril (20 min)

**C1.** Agrega a la tabla de A3 `[Kilos]`, `[Cumplimiento]` y `[Cosechas]`. Copia la tabla completa. Tiene que salir La Union **3 000 / 60,00 %**, El Guayabo **28 500 / 301,91 %**, Santa Rosa **18 800 / 188,00 %**, total **50 300 / 24 440 / 205,81 % / 15**.

**C2.** Al lado, una tabla con `h_cosecha[Source.Name]`, `[Kilos]` y `[Cosechas]`. Copia la tabla. Tiene que salir `bascula_2026-03.csv` **10 800 / 3**, y **dos** archivos de abril con **19 750 / 6** cada uno.

> **Toma aquí la captura `clase30-archivos.png`**: la tabla por `Source.Name` con la copia a la vista.

**C3.** **Transformar datos** → `h_cosecha` → **Ctrl + A** → clic derecho sobre un encabezado → **Quitar duplicados**. Anota cuántas filas quedan. En una línea: ¿por qué? Luego **borra ese paso**.

**C4.** Con `h_cosecha` seleccionada, **Nueva medida**:

```
Cosechas repetidas = [Cosechas] - DISTINCTCOUNT( h_cosecha[cosecha_id] )
```

Ponla en una tarjeta junto a la tabla de control. Tiene que decir **6**.

**C5.** **Transformar datos** → `h_cosecha` → filtro de `Source.Name` → **Filtros de texto → No contiene** → `copia` → **Aceptar**. Anota cuántas filas quedan: tiene que salir **25**. **Cerrar y aplicar.** La tabla de control: **30 550 / 24 440 / 125,00 % / 9**, y `[Cosechas repetidas]` en **0**.

**C6.** En dos líneas: el filtro de C5 quita la copia de hoy. El mes que viene alguien deja `bascula_2026-05 (2).csv` en la carpeta. ¿Lo quita? ¿Cuál de tus medidas lo atraparía?

---

## Parte D · El mes sin kilos (25 min) — es la parte que más vale

**D1.** Página nueva, **sin segmentadores**. Tabla con `dim_tiempo[anio]`, `[Kilos]` y `[Cosechas]`. Copia la tabla. Tiene que salir 2025 **44 150 / 16**, 2026 **30 550 / 9**, total **74 700 / 25**. Compárala con tu respuesta de A4.

**D2.** Otra tabla con `dim_tiempo[anio_mes]`, `[Kilos]` y `[Cosechas]`. Copia los meses de **2025**. ¿Qué mes tiene cosechas y no tiene kilos?

**D3.** **Transformar datos** → `h_cosecha` → **Vista → Calidad de columna**. Anota lo que dice debajo de `kg`: **válido**, **error** y **vacío**. Tiene que salir **8 %** vacío. Filtro de `kg` → deja solo **`(null)`**: anota las filas que quedan, con su `Source.Name`. Luego **borra ese paso de filtro**.

**D4.** Abre en el Bloc de notas el archivo que salió en D3 y copia **literal** su primera línea. Abre también `bascula_2025-06.csv` y copia la suya. En dos líneas: ¿qué cambió, y por qué Power Query no dio ningún `Error`?

**D5.** El segundo arreglo obvio. En `h_cosecha`, filtro de `kg` → desmarca **`(null)`** → **Aceptar**. **Cerrar y aplicar.** Anota:

| Prueba | Tiene que decir |
|---|---|
| Calidad de columna de `kg` | 100 % válido |
| Control de enero–abril | 30 550 / 125,00 % |
| La tabla de D1, 2025 | 44 150 / 14 |
| La tabla de D1, total | 74 700 / 23 |

Con `h_cosecha` seleccionada, **Nueva medida**:

```
Cosechas sin kilos = COUNTROWS( FILTER( h_cosecha , ISBLANK( h_cosecha[kg] ) ) )
```

En una tarjeta, en la página de los años: anota lo que dice. Luego **borra el filtro de `(null)`** y vuelve a anotarlo: tiene que decir **2**.

**D6.** Con los archivos abiertos en el Bloc de notas, saca **a mano** los kilos de mayo a agosto de 2025. Copia esta tabla y llénala:

| Archivo | Filas | Kilos en el archivo | `[Kilos]` en Power BI | `[Cosechas]` en Power BI |
|---|---|---|---|---|
| `bascula_2025-05.csv` | | | | |
| `bascula_2025-06.csv` | | | | |
| `bascula_2025-07.csv` | | | | |
| `bascula_2025-08.csv` | | | | |
| **Total** | **6** | | | **6** |

Tiene que salir **4 200 / 3 100 / 2 850 / 5 600**, y Power BI con **12 900** donde el archivo dice **15 750**.

**D7.** En una línea: el control de enero–abril dijo **125,00 %** con julio roto, antes y después de D5. ¿Por qué nunca lo vio? En otra: el martes quitar los `null` de `finca_id` fue el arreglo, y hoy quitar los de `kg` no. ¿Qué era el `null` cada vez?

---

## Parte E · El arreglo, en el archivo de ejemplo (20 min)

**E1.** Revisa que el filtro de `(null)` de D5 esté borrado: `[Cosechas sin kilos]` en **2**, y la tabla de D1 en **74 700 / 25**.

**E2.** **Transformar datos** → en la carpeta de ayuda, clic en **Transformar archivo de ejemplo**. Anota sus **Pasos aplicados**. Clic en **fx**, junto a la barra de fórmulas: aparece un paso nuevo que dice `= #"Encabezados promovidos"`. Cámbialo por:

```
= Table.RenameColumns( #"Encabezados promovidos" , {{"kg_neto", "kg"}} , MissingField.Ignore )
```

y **Enter**. Si el paso anterior tiene otro nombre en tu versión, usa ese nombre.

**E3.** Regresa a `h_cosecha`. Anota la calidad de columna de `kg`: tiene que salir **0 %** vacío, y **25** filas. **Cerrar y aplicar.**

**E4.** La tabla de los dos años: tiene que decir 2025 **47 000 / 16**, 2026 **30 550 / 9**, total **77 550 / 25**. Julio de 2025: **2 850 / 2**. `[Cosechas repetidas]` **0**, `[Cosechas sin kilos]` **vacía**. Y la tabla de control, con sus segmentadores: **30 550 / 24 440 / 125,00 % / 9**.

> **Toma aquí la captura `clase30-anios.png`**: la tabla de los dos años y las dos tarjetas.

**E5.** Completa la última columna de tu tabla de D6 con lo que dice Power BI ahora: los cuatro meses tienen que cuadrar con el archivo.

**E6.** Vuelve a tus respuestas de A4. ¿Acertaste las tres?

---

## Parte F · La fórmula del paso, y preguntas de cierre (20 min)

**F1.** **Transformar datos** → `h_cosecha` → **Inicio → Editor avanzado**. Copia **literal** la línea de `Table.ExpandTableColumn`. ¿De dónde saca la lista de columnas que expande?

**F2.** En dos líneas: ¿qué habría pasado si en B2 el **archivo de ejemplo** hubiera sido `bascula_2025-07.csv`? ¿Cuántas cosechas habrían salido sin kilos?

**F3.** Preguntas de cierre:

1. En una línea: ¿qué hace **Combinar archivos** con una carpeta, dicho en archivos y filas?
2. En una línea: escribe la **regla de detección** del día, tomando como base la de la 29: *«un total escrito en la hoja es, para Power Query, una finca más»*.
3. En dos líneas: la copia de abril dio **50 300**; julio dio **74 700**. ¿Por qué una la atrapó el control de enero–abril y la otra no?
4. En una línea: ¿por qué el paso de renombrar va en **Transformar archivo de ejemplo** y no en `h_cosecha`?
5. En dos líneas: la báscula de repuesto vuelve en noviembre y esta vez escribe `kilos`. Con tu consulta de hoy, ¿qué pasa al **Actualizar**? ¿Cuál de tus medidas lo avisa?

---

## Si algo falla

| Síntoma | Qué pasó | Qué haces |
|---|---|---|
| No aparece **Carpeta** en Obtener datos | está en **Más…** | **Obtener datos → Más… → Carpeta** |
| Una consulta por archivo, o sin `Source.Name` | usaste **Cargar** o **Transformar datos** en B1 | borra las consultas y repite B1 con **Combinar → Combinar y transformar datos** |
| En B3 no salen **31 filas** | la carpeta no tiene los 15 archivos, o tiene otros | revisa `C:\agrodb30\bascula\` contra `datos/csv_clase30/bascula/` |
| Los encabezados son `Column1`, `Column2`… | el ejemplo no promovió encabezados | anótalo; en **Transformar archivo de ejemplo**, **Usar la primera fila como encabezado** |
| En C3 **sí** se quitaron filas | quitaste duplicados sin `Source.Name`, o solo sobre `cosecha_id` | anótalo cuántas, y **borra el paso** igual |
| En D2 julio sale con `Error` y no vacío | tu versión le puso tipo en el ejemplo | **anótalo, eso puntúa**; el arreglo de E2 es el mismo |
| En E2 todos los meses dan `Error` | faltó `MissingField.Ignore` | agrégalo como tercer argumento |
| En E4 sigue **74 700** | escribiste el paso en `h_cosecha`, o no diste **Cerrar y aplicar** | el paso va en **Transformar archivo de ejemplo** |
| En E4 salen **23** cosechas | quedó el filtro de `(null)` de D5 | bórralo en **Pasos aplicados** de `h_cosecha` |
| Los decimales o los miles salen distintos | configuración regional de tu Windows | **no es un error**, anótalo y sigue |

> ### La regla de los 20 minutos sigue vigente
> Veinte minutos atorado en lo mismo: lo escribes en tu archivo empezando con `DUDA`, o abres un *issue*, y sigues con lo siguiente. **Atorarse no baja la nota. Quedarse callado sí.**

---

## Plan B · Si Power BI Desktop no abre en tu máquina

1. Ponte con un compañero: el modelo se arma en una sola máquina.
2. **Tú escribes todas las medidas** en tu propio archivo `.md`, con sus resultados, y anotas con quién trabajaste.
3. **La tabla de D6 y las respuestas de A4, C3, C6, D4, D7, E6, F2 y F3 las haces tú**, con tus propias palabras y con los archivos de `bascula/` abiertos: se contestan leyendo los archivos.
4. Las capturas son las mismas para los dos, y los dos lo dicen en un comentario.

**Con el Plan B completo se llega a 100 de 100.** Lo que se califica es que sepas qué archivo sobraba, cuál cambió su encabezado y dónde se arregla cada uno, no de quién era la laptop.

---

## Rúbrica (100 puntos)

| Criterio | Pts |
|---|---|
| Parte A: el modelo con sus dos relaciones, la meta en 24 440 y A4 | 10 |
| Parte B: la combinación con su archivo de ejemplo, las cuatro cosas de ayuda, las 31 filas con `Source.Name`, y las relaciones 3 y 4 | 15 |
| Parte C: el 205,81 %, la tabla por `Source.Name` y su captura, C3, `[Cosechas repetidas]` en 6 y en 0, y C6 | 15 |
| **Parte D: los dos años en 74 700, julio sin kilos, la calidad de columna, los encabezados de D4, el filtro de D5 con sus cuatro pruebas, la tabla de D6 a mano y D7** | **25** |
| Parte E: el paso en el archivo de ejemplo, las 25 filas, los dos años en 77 550, las tarjetas, y la captura | 20 |
| Parte F: la línea literal de F1, F2, y las cinco preguntas con criterio | 15 |

Los criterios suman **100** exactos.

> **Lo que más se califica hoy no es el clic en «Combinar»**, que se copia del enunciado. Es la tabla de D6: que hayas sacado a mano los kilos de cada archivo, y que sepas explicar por qué el control de enero–abril dijo 125,00 % mientras a 2025 le faltaban 2 850 kilos.
