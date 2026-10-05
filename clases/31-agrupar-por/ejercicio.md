# Ejercicio práctico 31 · Las pesadas de la báscula

**Duración: 2 horas · Individual · Solo Power BI Desktop · Entrega: un archivo `.md` y dos capturas**

---

## Qué vas a lograr hoy

1. Armar el modelo de siempre **sin** `h_cosecha.csv`.
2. Cargar `pesadas.csv` tal cual y ver qué cuenta `COUNTROWS` cuando una fila es un camión.
3. Construir `h_cosecha` con **Agrupar por**: lo que hace **Básico**, lo que hace **Avanzado**, y qué columnas van en las **llaves**.
4. Contestar la pregunta de logística, **cuánto lleva en promedio un camión**, y caer en el promedio de los promedios.
5. Caer en el segundo arreglo obvio, `[Kilos]` entre `[Cosechas]`, y ver qué contesta en realidad.
6. Arreglarlo con **la cuenta que guardaste al agrupar**.

**El número que prueba que el tablero quedó bien: 125,00 % con 30 550 en 9 cosechas en la tabla de control, y la carga por camión 1 607,89 con 19 camiones.** El que prueba que entendiste la clase es que sepas por qué La Unión dio lo mismo con las tres medidas.

---

## Antes de empezar

De nuevo solo Power BI: hoy tampoco se prende Oracle, ni Docker, ni el driver.

| | |
|---|---|
| Oracle, Docker, OCMT, `GRANT` | **no** |
| Power BI Desktop | **sí**, y es lo único |

### Lo que se baja hoy

**Hoy sí se baja algo:** [`datos/csv_clase31/`](../../datos/csv_clase31/). Son tres CSV de la clase 19, **idénticos** (`dim_tiempo`, `dim_finca` y `h_meta`), y uno nuevo: **`pesadas.csv`**, las cosechas como las registra la báscula, **una fila por camión**. **`h_cosecha.csv` no viene**: hoy la construyes tú.

Copia la carpeta a `C:\agrodb31\` y trabaja sobre esa copia. Tienen que quedar **cuatro archivos**.

> **Hoy se empieza con un `.pbix` vacío**, como en la 24 y de la 26 a la 30.

### El correo de la báscula

> *«Son **los mismos kilos de siempre**, camión por camión. Y logística pregunta: **¿cuánto lleva en promedio un camión?**»*

---

## Cómo se entrega

En `entregas/apellido-nombre/`, por *pull request*, **tres archivos**:

| Archivo | Qué lleva |
|---|---|
| `Ejercicio31_Apellido_Nombre.md` | cada medida en un bloque de código **con su resultado anotado debajo**, las tablas que se piden y las respuestas a las preguntas |
| `clase31-llaves.png` | la **tabla de control** con `camion` en las llaves: `[Cosechas]` en **14** y `[Cosechas repetidas]` en **5**, **antes** de arreglar las llaves |
| `clase31-carga.png` | la **tabla por finca** con `[Carga promedio]`, `[Carga promedio 2]`, `[Camiones]` y `[Carga por camión]`, el total en **1 607,89** |

> El `.pbix` no se entrega: el repositorio lo ignora a propósito.

---

## Parte A · El modelo sin cosechas (15 min)

### A0. La configuración regional, antes de cargar nada

Como de la 27 a la 30: **Archivo → Opciones y configuración → Opciones → Archivo actual → Configuración regional** → **Español (México)** → **Aceptar**.

### A1. Cargar

1. En **Archivo actual → Carga de datos**, apaga **«Detectar automáticamente nuevas relaciones después de cargar los datos»**.
2. **Inicio → Obtener datos → Texto o CSV**, uno por uno, con **Cargar**: `dim_tiempo`, `dim_finca` y `h_meta`. **`pesadas.csv` todavía no.**

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

**A4.** Abre `C:\agrodb31\pesadas.csv` en el Bloc de notas. Contesta **antes** de seguir: ¿cuántas filas de datos tiene? ¿Cuántas cosechas distintas? ¿En cuántos camiones se pesó la cosecha 7? En la parte E vas a volver a estas respuestas.

---

## Parte B · Tal cual, y Agrupar por básico (20 min)

**B1.** **Inicio → Obtener datos → Texto o CSV** → `pesadas.csv` → **Transformar datos**. Revisa los tipos: `fecha` como **Fecha**, `kg` como **Número entero**. Clic derecho sobre `pesadas` → **Cambiar nombre** → **`h_cosecha`**. **Inicio → Cerrar y aplicar.**

**B2.** Las dos relaciones de las cosechas:

| # | De | A |
|---|---|---|
| 3 | `h_cosecha[finca_id]` | `dim_finca[finca_id]` |
| 4 | `h_cosecha[fecha]` | `dim_tiempo[fecha]` |

Y con `h_cosecha` seleccionada, **Nueva medida**, una por una:

```
Kilos = SUM( h_cosecha[kg] )
Cosechas = COUNTROWS( h_cosecha )
Cumplimiento = DIVIDE( [Kilos] , [Meta] )
Cosechas repetidas = [Cosechas] - DISTINCTCOUNT( h_cosecha[cosecha_id] )
```

**B3.** Agrega las cuatro a la tabla de A3. Copia la tabla completa. Tiene que salir el total en **30 550 / 24 440 / 125,00 %**, `[Cosechas]` **19** y `[Cosechas repetidas]` **10**. En una línea: ¿qué está contando `[Cosechas]`?

**B4.** **Transformar datos** → `h_cosecha` → **Inicio → Agrupar por** → **Básico** → `cosecha_id` → deja lo que propone → **Aceptar**. Anota: cuántas **filas** y **columnas** dice abajo a la izquierda, el **nombre** y la **operación** de la columna nueva, y qué columnas desaparecieron. Luego **borra ese paso** con la **X** en **Pasos aplicados**.

---

## Parte C · Las llaves (20 min)

**C1.** **Inicio → Agrupar por** → **Avanzado**. Con **Agregar agrupación**, agrupa por **todas las columnas menos `pesada_id` y `kg`**: `cosecha_id`, `finca_id`, `cultivo_id`, `fecha`, `calidad` y `camion`. Una sola agregación: nombre **`kg`**, operación **Suma**, columna `kg`. **Aceptar**. Anota cuántas filas quedan: tiene que salir **36**. **Cerrar y aplicar.**

**C2.** La tabla de control. Copia la tabla. Tiene que salir el total en **30 550 / 125,00 %**, `[Cosechas]` **14** y `[Cosechas repetidas]` **5**.

> **Toma aquí la captura `clase31-llaves.png`**: la tabla de control con `[Cosechas]` en 14 y `[Cosechas repetidas]` en 5.

**C3.** En Power Query, filtra `cosecha_id` = **1** y copia las filas que quedan (`camion` y `kg`). Abre `pesadas.csv` y copia las tres filas de la cosecha 1. En una línea: ¿por qué tres camiones dieron dos filas? Luego **borra ese filtro**.

**C4.** En **Pasos aplicados**, clic en el **engrane** de **Filas agrupadas**. Quita `camion` de las llaves, y deja tres agregaciones:

| Nuevo nombre de columna | Operación | Columna |
|---|---|---|
| `kg` | **Suma** | `kg` |
| `pesadas` | **Recuento de filas** | |
| `carga_promedio` | **Promedio** | `kg` |

**Aceptar.** Anota cuántas filas quedan: tiene que salir **25**. **Cerrar y aplicar.** La tabla de control: **30 550 / 24 440 / 125,00 % / 9**, y `[Cosechas repetidas]` en **0**.

**C5.** En dos líneas: escribe con tus palabras qué columna puede ir en las llaves y cuál no. ¿Habría pasado lo mismo con `pesada_id` en las llaves? ¿Cuántas filas habrían salido?

---

## Parte D · Cuánto lleva un camión (25 min) — es la parte que más vale

**D1.** Con `h_cosecha` seleccionada, **Nueva medida**:

```
Carga promedio = AVERAGE( h_cosecha[carga_promedio] )
```

Agrégala a la tabla de control, con su formato en **Número decimal** con dos decimales. Copia la tabla: tiene que salir La Union **1 050,00**, El Guayabo **1 866,67**, Santa Rosa **1 450,00** y total **1 500,00**.

**D2.** En una tabla nueva, con los mismos segmentadores: `h_cosecha[cosecha_id]`, `h_cosecha[pesadas]`, `h_cosecha[kg]` y `h_cosecha[carga_promedio]` (en cada una, **No resumir**). Copia las filas de **El Guayabo**.

**D3.** Con `pesadas.csv` abierto en el Bloc de notas, saca **a mano** los camiones y los kilos de El Guayabo en enero–abril de 2026. Copia esta tabla y llénala:

| `cosecha_id` | Camiones | Kilos | Kilos entre camiones |
|---|---|---|---|
| 5 | | | |
| 6 | | | |
| 7 | | | |
| **El Guayabo** | **7** | | |

Tiene que salir **14 250 / 7 = 2 035,71**, donde `[Carga promedio]` dice **1 866,67**.

**D4.** En dos líneas: en Santa Rosa `[Carga promedio]` se pasa (**1 450,00** contra **1 420,00**) y en El Guayabo se queda corta. ¿Qué cosecha jala cada promedio, y por qué?

**D5.** El segundo arreglo obvio. **Nueva medida**:

```
Carga promedio 2 = DIVIDE( [Kilos] , [Cosechas] )
```

Agrégala a la tabla de control. Copia la tabla: tiene que salir El Guayabo **4 750,00**, Santa Rosa **3 550,00** y total **3 394,44**. En una línea: ¿qué contesta en realidad esta medida?

**D6.** En una línea: `[Cosechas]` dijo **19** en B3 y dice **9** ahora, con la misma fórmula. ¿Qué cambió? En otra: ¿por qué La Unión dio **1 050,00** con las dos medidas?

---

## Parte E · El arreglo: la cuenta que guardaste (20 min)

**E1.** Con `h_cosecha` seleccionada, **Nueva medida**, una por una:

```
Camiones = SUM( h_cosecha[pesadas] )
Carga por camión = DIVIDE( [Kilos] , [Camiones] )
```

**E2.** Agrégalas a la tabla de control. Copia la tabla: `[Camiones]` **2 / 7 / 10 / 19**, `[Carga por camión]` La Union **1 050,00**, El Guayabo **2 035,71**, Santa Rosa **1 420,00**, total **1 607,89**. Compárala con tu tabla de D3.

> **Toma aquí la captura `clase31-carga.png`**: la tabla por finca con `[Carga promedio]`, `[Carga promedio 2]`, `[Camiones]` y `[Carga por camión]`.

**E3.** Página nueva, **sin segmentadores**. Tarjetas con `[Kilos]`, `[Cosechas]`, `[Camiones]` y `[Carga por camión]`. Tienen que decir **77 550**, **25**, **54** y **1 436,11**. Vuelve a tus respuestas de A4: ¿cuadran?

**E4.** En una línea: si en C4 no hubieras guardado `pesadas`, ¿de dónde sacarías los camiones sin volver a Power Query?

---

## Parte F · La fórmula del paso, y preguntas de cierre (20 min)

**F1.** **Transformar datos** → `h_cosecha` → **Inicio → Editor avanzado**. Copia **literal** la línea de `Table.Group`. Señala en ella las llaves y las tres agregaciones.

**F2.** En dos líneas: logística pide además **cuántos camiones distintos** trabajaron cada mes. Con la `h_cosecha` agrupada de hoy, ¿se puede? ¿Por qué no sirve guardar un **Recuento de filas distintas** de `camion` por cosecha y sumarlo?

**F3.** Preguntas de cierre:

1. En una línea: ¿qué hace **Agrupar por**, dicho en filas y columnas?
2. En una línea: escribe la **regla de detección** del día, tomando como base la de la 30: *«una carpeta se combina con las columnas del primer archivo»*.
3. En dos líneas: la llave de más la atrapó `[Cosechas repetidas]`; el promedio de los promedios no lo atrapó ninguna prueba que ya tuviéramos. ¿Por qué?
4. En una línea: ¿por qué `[Camiones]` es un `SUM` y no un `COUNTROWS`?
5. En dos líneas: antes de agrupar, en B3, ¿qué habría dado `AVERAGE( h_cosecha[kg] )`? ¿Por qué ahí sí estaba bien?

---

## Si algo falla

| Síntoma | Qué pasó | Qué haces |
|---|---|---|
| No aparece **Agrupar por** en **Inicio** | tu versión lo tiene en otra pestaña | búscalo en **Transformar → Agrupar por** |
| Solo **2 columnas** después de agrupar | usaste **Básico** | borra el paso y usa **Avanzado** |
| `[Kilos]` da error: no encuentra `kg` | la agregación se llama `Recuento` o `Suma` | en el engrane, renómbrala **`kg`** |
| `[Kilos]` da **19** en el control | la operación quedó en **Recuento de filas** | **Suma** de `kg` |
| No aparece **Suma** en la lista de operaciones | `kg` es texto | antes de agrupar, tipo **Número entero** |
| En C1 no salen **36 filas** | te faltó o te sobró una llave | revisa que sean las seis de C1, ni `pesada_id` ni `kg` |
| Las relaciones 3 y 4 desaparecieron | agrupaste sin `finca_id` o sin `fecha` | regresa las llaves y vuelve a dibujarlas |
| `[Camiones]` da **9** | escribiste `COUNTROWS` | `SUM( h_cosecha[pesadas] )` |
| La carga sale sin decimales | formato de la medida | **Número decimal**, dos decimales |
| Los decimales o los miles salen distintos | configuración regional de tu Windows | **no es un error**, anótalo y sigue |

> ### La regla de los 20 minutos sigue vigente
> Veinte minutos atorado en lo mismo: lo escribes en tu archivo empezando con `DUDA`, o abres un *issue*, y sigues con lo siguiente. **Atorarse no baja la nota. Quedarse callado sí.**

---

## Plan B · Si Power BI Desktop no abre en tu máquina

1. Ponte con un compañero: el modelo se arma en una sola máquina.
2. **Tú escribes todas las medidas** en tu propio archivo `.md`, con sus resultados, y anotas con quién trabajaste.
3. **La tabla de D3 y las respuestas de A4, B3, C3, C5, D4, D6, E4, F2 y F3 las haces tú**, con tus propias palabras y con `pesadas.csv` abierto: se contestan leyendo el archivo.
4. Las capturas son las mismas para los dos, y los dos lo dicen en un comentario.

**Con el Plan B completo se llega a 100 de 100.** Lo que se califica es que sepas qué va en las llaves, qué se guarda al agrupar y por qué un promedio no se vuelve a promediar, no de quién era la laptop.

---

## Rúbrica (100 puntos)

| Criterio | Pts |
|---|---|
| Parte A: el modelo con sus dos relaciones, la meta en 24 440 y A4 | 10 |
| Parte B: la carga tal cual con `[Cosechas]` en 19, las relaciones 3 y 4, y lo que dejó **Básico** | 15 |
| Parte C: las 36 filas con `camion` y su captura, C3, las 25 filas con las tres agregaciones, el control en 9 y C5 | 15 |
| **Parte D: el 1 500,00, la tabla de D2, la cuenta a mano de El Guayabo en D3, D4, el 3 394,44 de D5 y D6** | **25** |
| Parte E: `[Camiones]` y `[Carga por camión]`, el 1 607,89 y su captura, las cuatro tarjetas y E4 | 20 |
| Parte F: la línea literal de F1, F2, y las cinco preguntas con criterio | 15 |

Los criterios suman **100** exactos.

> **Lo que más se califica hoy no es el clic en «Agrupar por»**, que se copia del enunciado. Es la tabla de D3: que hayas contado a mano los camiones de El Guayabo, y que sepas explicar por qué un promedio que estaba bien en cada fila daba mal en el total.
