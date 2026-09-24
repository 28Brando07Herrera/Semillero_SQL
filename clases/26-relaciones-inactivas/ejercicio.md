# Ejercicio práctico 26 · Los kilos entregados

**Duración: 2 horas · Individual · Solo Power BI Desktop · Entrega: un archivo `.md` y dos capturas**

---

## Qué vas a lograr hoy

1. Armar el modelo con los CSV de la clase 26, donde `h_cosecha` trae **dos fechas**: la del corte y la de la entrega.
2. Dibujar **una segunda relación** entre `h_cosecha` y `dim_tiempo`, y ver que Power BI la deja **inactiva**.
3. Escribir la medida obvia de «kilos entregados» y ver que sale **idéntica** a `[Kilos]`, sin un solo aviso.
4. Arreglarla con **`USERELATIONSHIP`**, y ver qué meses cambian y por qué.
5. Cambiar la relación activa **para ver qué se mueve**, y regresarla.
6. Usar las dos fechas dentro de la misma fila con `DATEDIFF`.

**El número que prueba que el tablero quedó bien: `[Kilos entregados]` de enero a abril es 21 050, no 30 550.** El que prueba que entendiste la clase es que sepas por qué la primera versión dio 30 550.

---

## Antes de empezar

De nuevo solo Power BI: hoy tampoco se prende Oracle, ni Docker, ni el driver.

| | |
|---|---|
| Oracle, Docker, OCMT, `GRANT` | **no** |
| Power BI Desktop | **sí**, y es lo único |

### Lo que se baja hoy

**Hoy sí se baja algo:** [`datos/csv_clase26/`](../../datos/csv_clase26/). Son los seis CSV de la clase 19; cinco llegan idénticos y **`h_cosecha.csv` trae una columna nueva al final, `fecha_entrega`**.

Copia la carpeta completa a `C:\agrodb26\` y trabaja sobre esa copia.

> **Hoy se empieza con un `.pbix` vacío**, como en la clase 24. No reuses el de antes: Power BI recuerda cuántas columnas tenía `h_cosecha` y la columna nueva podría no entrar.

---

## Cómo se entrega

En `entregas/apellido-nombre/`, por *pull request*, **tres archivos**:

| Archivo | Qué lleva |
|---|---|
| `Ejercicio26_Apellido_Nombre.md` | cada medida en un bloque de código **con su resultado anotado debajo**, las tablas que se piden y las respuestas a las preguntas |
| `clase26-modelo.png` | la **vista de modelo** con las seis relaciones: **cinco continuas y una punteada** |
| `clase26-entregas.png` | la **tabla por mes** con `[Kilos]` y `[Kilos entregados]`, enero a abril: **1 200 / 9 600 / 10 250** y total **21 050** |

> El `.pbix` no se entrega: el repositorio lo ignora a propósito.

---

## Parte A · El modelo (20 min)

### A1. Cargar

1. **Archivo → Opciones y configuración → Opciones → Carga de datos**: apaga **«Detectar automáticamente nuevas relaciones después de cargar los datos»** (en **Archivo actual**). Como en la clase 24.
2. **Inicio → Obtener datos → Texto o CSV**, uno por uno: `h_cosecha`, `h_meta`, `dim_tiempo`, `dim_finca` y `dim_cultivo`. **`seguridad.csv` no se carga hoy.**

**A1a.** En la vista de tabla, abre `h_cosecha`. ¿De qué **tipo** quedó `fecha_entrega`? Tiene que ser **Fecha**. Si quedó como texto, cámbialo antes de seguir y anótalo.

### A2. Las cinco relaciones

En la **vista de modelo**, arrastra cada columna sobre la otra:

| # | De | A |
|---|---|---|
| 1 | `h_cosecha[finca_id]` | `dim_finca[finca_id]` |
| 2 | `h_cosecha[cultivo_id]` | `dim_cultivo[cultivo_id]` |
| 3 | `h_cosecha[fecha]` | `dim_tiempo[fecha]` |
| 4 | `h_meta[finca_id]` | `dim_finca[finca_id]` |
| 5 | `h_meta[fecha_mes]` | `dim_tiempo[fecha]` |

**Todavía no** dibujes nada con `fecha_entrega`: eso es la parte B. Las cinco tienen que salir **continuas** y de muchos a uno.

### A3. El calendario y las medidas

1. `dim_tiempo` → **Marcar como tabla de fechas** → `fecha`.
2. `nombre_mes` → **Ordenar por columna** → `mes`.
3. Con `h_cosecha` seleccionada en el panel **Datos**, **Nueva medida**, una por una:

```
Kilos = SUM( h_cosecha[kg] )
```

```
Meta = SUM( h_meta[kg_meta] )
```

```
Cumplimiento = DIVIDE( [Kilos] , [Meta] )
```

### A4. La tabla de control

Segmentadores `dim_tiempo[anio]` = **2026** y `dim_tiempo[mes]` de **1 a 4**. Tabla con `dim_finca[finca]`, `[Kilos]`, `[Meta]` y `[Cumplimiento]`:

| Finca | `[Kilos]` | `[Meta]` | `[Cumplimiento]` |
|---|---|---|---|
| Agricola La Union | 2 100 | 5 000 | 42,00 % |
| Finca El Guayabo | 14 250 | 9 440 | 150,95 % |
| Hacienda Santa Rosa | 14 200 | 10 000 | 142,00 % |
| **Total** | **30 550** | **24 440** | **125,00 %** |

Si el total no dice **125,00 %**, no sigas: revisa las relaciones 3 y 5.

---

## Parte B · La segunda relación (10 min)

**B1.** En la vista de modelo, arrastra `h_cosecha[fecha_entrega]` sobre `dim_tiempo[fecha]`.

**B2.** ¿Cómo se ve la línea nueva, comparada con la de `fecha`? Descríbela en una línea.

**B3.** Abre **Modelado → Administrar relaciones**. Anota las dos relaciones entre `h_cosecha` y `dim_tiempo` y cuál aparece como **activa**.

**B4.** En una línea: ¿por qué Power BI no deja que las dos estén activas a la vez? Piensa en qué pasaría con un filtro de `dim_tiempo[mes]` = 4.

> **Toma aquí la captura `clase26-modelo.png`**: las seis relaciones, cinco continuas y una punteada.

---

## Parte C · La medida obvia (15 min)

**C1.** Finanzas quiere los kilos entregados por mes. Crea la medida:

```
Kilos entregados = SUM( h_cosecha[kg] )
```

**C2.** Tabla nueva con `dim_tiempo[nombre_mes]`, `[Kilos]` y `[Kilos entregados]`. Copia la tabla completa en tu `.md`.

**C3.** Busca en `h_cosecha.csv` la cosecha **7** (el maíz del 30 de abril). ¿En qué mes se **entregó**? ¿En qué mes la está contando `[Kilos entregados]`?

**C4.** ¿Qué error dio Power BI? En una línea, ¿por qué la medida no usa `fecha_entrega` si la relación ya está dibujada?

---

## Parte D · `USERELATIONSHIP` (25 min) — es la parte que más vale

**D1.** Edita `[Kilos entregados]` (clic en la medida y cambia la fórmula en la barra):

```
Kilos entregados = CALCULATE( [Kilos] , USERELATIONSHIP( h_cosecha[fecha_entrega] , dim_tiempo[fecha] ) )
```

**D2.** La misma tabla por mes, con `mes` de 1 a 4. Copia la tabla. Tiene que salir:

| `nombre_mes` | `[Kilos]` | `[Kilos entregados]` |
|---|---|---|
| Enero | | 1 200 |
| Marzo | 10 800 | 9 600 |
| Abril | 19 750 | 10 250 |
| **Total** | **30 550** | **21 050** |

> **Toma aquí la captura `clase26-entregas.png`.**

**D3.** Busca en `h_cosecha.csv` **qué cosecha** es el **1 200 de enero**. ¿En qué año se cortó? ¿En qué año cuenta para `[Kilos]`, y en cuál para `[Kilos entregados]`?

**D4.** Los entregados de enero a abril son **9 500 menos** que los cosechados. Explica los 9 500 **con números de `cosecha_id`**: cuáles salen y cuál entra.

**D5.** Quita el segmentador de `mes` (el año 2026 completo). Anota el total de las dos medidas y el mes nuevo que aparece. Tiene que salir **30 550** contra **31 750**, y **Mayo** con **10 700**. Vuelve a poner `mes` en 1–4.

**D6.** Agrega `[Kilos entregados]` a la tabla por finca de A4. Anota las tres filas. ¿Cambió `[Kilos]`? ¿Cambió `[Cumplimiento]`?

---

## Parte E · ¿Y si activo la otra? (20 min)

Un compañero propone algo más fácil: activar la relación de `fecha_entrega` y dejar `[Kilos entregados]` como un `SUM`.

**E1.** **Modelado → Administrar relaciones**: desactiva la de `h_cosecha[fecha]` y activa la de `h_cosecha[fecha_entrega]`. Si Power BI pide desactivar una antes de activar la otra, hazlo en ese orden y anótalo.

**E2.** Copia la tabla por finca de A4, **sin tocar ninguna medida**. Tiene que salir:

| Finca | `[Kilos]` | `[Meta]` | `[Cumplimiento]` |
|---|---|---|---|
| Agricola La Union | 2 400 | 5 000 | 48,00 % |
| Finca El Guayabo | 4 450 | 9 440 | 47,14 % |
| Hacienda Santa Rosa | 14 200 | 10 000 | 142,00 % |
| **Total** | **21 050** | **24 440** | **86,13 %** |

**E3.** ¿Por qué El Guayabo baja de 150,95 % a 47,14 %? Nómbrala **por cosecha**: ¿cuál de sus cosechas dejó de contar en enero–abril?

**E4.** ¿Por qué `[Meta]` **no** cambió?

**E5.** **Regrésala**: desactiva `fecha_entrega` y activa `fecha`. La tabla tiene que volver a **125,00 %**. Anota que volvió.

**E6.** En dos líneas: ¿qué **otras** cosas del curso habrían cambiado solas con la activa en `fecha_entrega`? Nombra al menos dos (piensa en el semáforo de la 23 y en el KPI del año).

---

## Parte F · Días a la entrega (20 min)

**F1.** Crea la medida:

```
Dias a la entrega = AVERAGEX( h_cosecha , DATEDIFF( h_cosecha[fecha] , h_cosecha[fecha_entrega] , DAY ) )
```

Formato: **Número decimal** con **dos decimales**.

**F2.** Tabla con `dim_cultivo[cultivo]` y `[Dias a la entrega]`, con los segmentadores de siempre. Tiene que salir Mango **2**, Guayaba **2**, Maiz **12**, Cacao **27**, y el total **8,67**.

**F3.** En una línea: ¿por qué el total es 8,67 y no el promedio de los cuatro cultivos, 10,75?

**F4.** `DATEDIFF` no usa ninguna relación: compara dos columnas **de la misma fila**. Entonces, ¿por qué el segmentador de `mes` sí cambia el resultado? ¿Por cuál fecha está filtrando?

---

## Parte G · Preguntas de cierre (10 min)

1. En una línea: ¿qué hace **una relación inactiva** mientras ninguna medida la pide?
2. En una línea: ¿cuándo conviene **cambiar la relación activa** y cuándo usar `USERELATIONSHIP`?
3. En una línea: escribe la **regla de detección** del día, tomando como base la de la clase 23: *«si un color cambia y su número no, el color no estaba midiendo ese número»*.
4. En dos líneas: un banco tiene `fecha_solicitud` y `fecha_aprobacion` en la misma tabla de créditos. El tablero dice «créditos aprobados en marzo». ¿Qué revisarías primero?
5. En una línea: **¿qué fecha usa la meta?** ¿Tendría sentido una «meta de entregas» con la misma `h_meta`?

---

## Si algo falla

| Síntoma | Qué pasó | Qué haces |
|---|---|---|
| `h_cosecha` no trae `fecha_entrega` | usaste el CSV de la clase 19, o el `.pbix` de antes | carga `h_cosecha.csv` de `datos/csv_clase26/` en un `.pbix` nuevo |
| No deja crear la relación con `fecha_entrega` | quedó como **texto** | vista de tabla → `fecha_entrega` → tipo **Fecha** |
| La relación con `fecha_entrega` salió **continua** y la de `fecha` punteada | la dibujaste **antes** | Administrar relaciones: desactiva `fecha_entrega`, activa `fecha` |
| El total de A4 no es 125,00 % | falta la relación 3 o la 5, o la activa está en `fecha_entrega` | revisa la vista de modelo |
| **Error** al guardar `[Kilos entregados]` con `USERELATIONSHIP` | la relación con `fecha_entrega` no está dibujada | es la parte B: dibújala |
| `[Kilos entregados]` sigue igual a `[Kilos]` en D2 | la medida quedó con el `SUM` de la parte C | revisa la fórmula en la barra |
| Power BI creó relaciones solo | la detección automática quedó prendida | bórralas y dibuja las cinco |
| `[Dias a la entrega]` sale entero | formato sin decimales | **Herramientas de medición → Formato → Número decimal**, dos decimales |
| Los decimales o los miles salen distintos | configuración regional de tu Windows | **no es un error**, anótalo y sigue |

> ### La regla de los 20 minutos sigue vigente
> Veinte minutos atorado en lo mismo: lo escribes en tu archivo empezando con `DUDA`, o abres un *issue*, y sigues con lo siguiente. **Atorarse no baja la nota. Quedarse callado sí.**

---

## Plan B · Si Power BI Desktop no abre en tu máquina

1. Ponte con un compañero: el modelo se arma en una sola máquina.
2. **Tú escribes todas las medidas** en tu propio archivo `.md`, con sus resultados, y anotas con quién trabajaste.
3. **Las respuestas de C3, D3, D4, E3 y F3 las haces tú**, con tus propias palabras y con `h_cosecha.csv` abierto: se contestan leyendo el CSV.
4. Las capturas son las mismas para los dos, y los dos lo dicen en un comentario.

**Con el Plan B completo se llega a 100 de 100.** Lo que se califica es por cuál fecha contaba cada medida y por qué, no de quién era la laptop.

---

## Rúbrica (100 puntos)

| Criterio | Pts |
|---|---|
| Parte A: el modelo con sus cinco relaciones, las medidas, y la tabla de control en 125,00 % | 10 |
| Parte B: la relación punteada, la captura del modelo, y B2, B3 y B4 | 10 |
| Parte C: `[Kilos entregados]` con `SUM` idéntica a `[Kilos]`, y C3 y C4 | 15 |
| **Parte D: `USERELATIONSHIP` con 1 200 / 9 600 / 10 250 y total 21 050, la captura, y D3, D4, D5 y D6** | **25** |
| Parte E: la tabla con 86,13 %, E3, E4, la relación regresada, y E6 | 15 |
| Parte F: `[Dias a la entrega]` por cultivo con 8,67, y F3 y F4 | 15 |
| Parte G: las cinco preguntas con criterio | 10 |

Los criterios suman **100** exactos.

> **Lo que más se califica hoy no es la fórmula con `USERELATIONSHIP`**, que se copia del enunciado. Es que hayas visto `[Kilos entregados]` idéntica a `[Kilos]` sin un solo aviso, y que sepas explicar con `cosecha_id` **de dónde salen** los 9 500 kilos de diferencia.
