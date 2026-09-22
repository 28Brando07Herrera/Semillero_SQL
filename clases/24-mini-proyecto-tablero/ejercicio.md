# Ejercicio práctico 24 · Mini proyecto: el tablero de la gerencia

**Duración: entre 90 minutos y 2 horas, en clase · Individual y autoguiado · Solo Power BI Desktop · Entrega: un archivo `.md` y seis capturas, hoy**

---

## Qué vas a lograr hoy

Un tablero completo, **desde un `.pbix` vacío**, con todo lo de las clases 14 a 23:

1. **El modelo**: seis tablas y **seis relaciones que dibujas tú** en la vista de modelo.
2. **Las medidas** de siempre: kilos, meta, cumplimiento y sus acumulados.
3. **Un semáforo** que pinta según el dato, y un **degradado**.
4. **Los KPI**: tarjetas y el objeto visual KPI del año, con un título que diga qué periodo enseña.
5. **Un rol dinámico**, probado **como gerente, como regional y como practicante**.
6. **El alta de un permiso** sin tocar el modelo.

**Hoy no hay tema nuevo ni trampa nueva.** Están todas las de antes, esperando en el mismo lienzo. Por eso la calificación es un **checklist de diez números**: cada uno solo sale si esquivaste una trampa del curso.

**El número que prueba que el tablero quedó bien es el del regional: viendo como `regional.norte@agrodb.test`, 113,23 % en verde.**

---

## Así se califica: el checklist

Diez puntos, **10 puntos cada uno**. Cada punto se comprueba **mirando una captura**. Para cada uno: **10** si se ve completo, **5** si se ve pero un número o un color no es el esperado y el `.md` lo explica, **0** si no está.

| # | Captura | Qué se tiene que ver | Qué trampa descarta |
|---|---|---|---|
| 1 | `clase24-1-modelo.png` | **seis tablas y seis relaciones**, todas `*` → `1`, y `h_meta[fecha_mes]` unida a `dim_tiempo[fecha]` | la relación que falta (clases 14 y 17) |
| 2 | `clase24-2-tablero.png` | tabla por finca: metas **5 000 / 9 440 / 10 000** y total **30 550 / 24 440 / 125,00 %** | la meta sin fecha (**65,00 %**) o sin finca (**24 440** en cada fila) (clase 17) |
| 3 | `clase24-2-tablero.png` | La Union **rojo** · El Guayabo **verde** · Santa Rosa **verde** · total **verde** | la regla con Porcentaje, que pinta a Santa Rosa de rojo (clase 23) |
| 4 | `clase24-2-tablero.png` | tabla por cultivo, cuatro filas: Mango **12 700** el más oscuro, Cacao **2 100** en blanco | el color que no se sabe contra qué compara (clase 23) |
| 5 | `clase24-2-tablero.png` | KPI del año **30 550** contra **24 440**, **+25,00 %**, con título que dice el periodo; tarjetas **30 550** y **125,00 %** | el KPI que enseña abril (**19 750**) o marzo (**10 800**) (clases 16 y 23) |
| 6 | `clase24-3-gerente.png` | `[Quien mira]` = gerente.launion · **una fila**: **2 100 / 5 000 / 42,00 %** en rojo · KPI **−58,00 %** · por cultivo solo **Cacao** | el rol en `h_cosecha` (**8,59 %**) o en `seguridad` (**125,00 %**) (clases 18 y 19) |
| 7 | `clase24-4-regional.png` | `[Quien mira]` = regional.norte · **dos filas** · total **16 350 / 14 440 / 113,23 %** en verde · KPI **+13,23 %** | el `LOOKUPVALUE` que truena con dos fincas (clase 19) |
| 8 | `clase24-5-practicante.png` | `[Quien mira]` = practicante · **ninguna fila**, tarjetas y KPI vacíos | la puerta abierta: el practicante viendo **30 550** (clase 19) |
| 9 | `clase24-6-alta.png` | `[Quien mira]` = practicante · **una fila**: Santa Rosa **14 200 / 10 000 / 142,00 %** en verde · KPI **+42,00 %** | el rol que hay que reabrir para dar un permiso (clase 19) |
| 10 | el `.md` | el checklist lleno con **lo que salió en tu pantalla**, las siete medidas y el rol en bloques de código, y **una línea por punto** diciendo qué trampa descarta | llegar al número sin saber por qué |

Los diez suman **100** exactos.

---

## Hoy trabajas por tu cuenta

**Hoy no hay clase en vivo.** Las [diapositivas](https://negatix092.github.io/Semillero_SQL/24-mini-proyecto-tablero.html) y este ejercicio son la clase: tienen cada clic, cada número esperado y qué hacer cuando no sale. Ábrelos en una ventana y Power BI en otra.

### El reloj

| Minuto | Deberías ir en | Captura | Si vas tarde |
|---|---|---|---|
| 0 → 10 | leer hasta «Antes de empezar» y copiar la carpeta | | |
| 10 → 35 | **Parte A**: el modelo | 1 | a los **45** sin captura 1: tómala con las relaciones que tengas y sigue |
| 35 → 50 | **Parte B**: medidas y tabla por finca | | la tabla de B3 te dice qué relación falta |
| 50 → 73 | **Parte C**: semáforo y KPI | 2 | |
| 73 → 93 | **Parte D**: el rol y los tres correos | 3, 4 y 5 | |
| 93 → 101 | **Parte E**: el alta del practicante | 6 | |
| 101 → 120 | **Parte F**: revisión y *pull request* | | lo que falte, como `DUDA` |

### Cuando te atores, en este orden

1. La tabla **«Si algo falla»**, al final de este archivo. Está hecha con los atoros de las clases 15 a 23.
2. Pregúntale a un compañero: **ayudar no está prohibido**, copiar capturas sí.
3. A los **20 minutos** en lo mismo: escribe `DUDA` en tu `.md` con lo que intentaste, o abre un *issue* con la plantilla **Duda**, **y sigue con la parte siguiente**. Casi todas las partes se pueden hacer aunque la anterior haya quedado a medias.

### Cómo se toma una captura

`Win + Shift + S` → **Recorte rectangular** → selecciona la ventana de Power BI → clic en el aviso **«Recorte copiado en el Portapapeles»** que sale abajo a la derecha → botón **Guardar** (el disquete) → guárdala **con el nombre exacto** que pide el punto de control, en una carpeta a la mano (por ejemplo `C:\agrodb24\capturas\`).

> Si el aviso no sale, pega con `Ctrl + V` en **Paint** y guarda como PNG.

---

## Antes de empezar

| | |
|---|---|
| Oracle, Docker, OCMT | **no** |
| Power BI Desktop | **sí**, y es lo único |
| El `.pbix` de la clase 23 | **no**: hoy se empieza **de cero** |

### Lo que se baja hoy

**Nada nuevo.** Los seis CSV de [`datos/csv_clase19/`](../../datos/csv_clase19/): los cinco de la clase 17 y `seguridad.csv`.

**Copia la carpeta completa a `C:\agrodb24\`** y trabaja sobre esa copia. En la parte E vas a editar `seguridad.csv`: **el del repositorio no se toca**, y el modificado **no se entrega**.

---

## Cómo se entrega

En `entregas/apellido-nombre/`, por *pull request*, **siete archivos**:

| Archivo | Qué lleva |
|---|---|
| `Ejercicio24_Apellido_Nombre.md` | el checklist lleno, las medidas y el rol, y las respuestas de A3a, A3b, D5 y E1 |
| `clase24-1-modelo.png` | la vista de modelo (parte A) |
| `clase24-2-tablero.png` | el tablero sin Ver como (parte C) |
| `clase24-3-gerente.png` | Ver como gerente.launion (parte D) |
| `clase24-4-regional.png` | Ver como regional.norte (parte D) |
| `clase24-5-practicante.png` | Ver como practicante, **antes** del alta (parte D) |
| `clase24-6-alta.png` | Ver como practicante, **después** del alta (parte E) |

El `.md` empieza con esta tabla, llena con **lo que salió en tu pantalla**, no con lo que dice este enunciado:

````
## Checklist

| # | Lo que salió en mi pantalla | Qué trampa descarta |
|---|---|---|
| 1 | 6 tablas, 6 relaciones, todas * a 1 | ... |
| 2 | 5 000 / 9 440 / 10 000, total 30 550 / 24 440 / 125,00 % | ... |
| ... | | |
| 9 | Santa Rosa 14 200 / 10 000 / 142,00 %, verde | ... |
````

> **Si un número de tu captura no es el del checklist, no lo corrijas en el `.md`.** Anótalo tal como salió y di qué crees que pasó: eso vale **5 de 10**; copiar el número bueno sin que salga en la captura vale **0**. El `.pbix` no se entrega: el repositorio lo ignora a propósito.

---

## Parte A · El modelo, desde cero (25 min)

### A1. Un archivo nuevo, con dos opciones apagadas

1. Power BI Desktop → **archivo nuevo**. Guárdalo de una vez como `C:\agrodb24\clase24-tablero.pbix`.
2. **Archivo → Opciones y configuración → Opciones → Archivo actual → Carga de datos**:
   - **desmarca Fecha/hora automática** (la de la clase 16),
   - **desmarca Detectar automáticamente nuevas relaciones** después de cargar los datos.

> Hoy las relaciones **las dibujas tú**. Si tu versión no trae la segunda opción o se llama distinto, **anótalo** y en A3 borra las relaciones que Power BI haya creado solo antes de dibujar las tuyas.

### A2. Los seis CSV

**Inicio → Obtener datos → Texto/CSV**, uno por uno, desde `C:\agrodb24\`: `dim_finca`, `dim_cultivo`, `dim_tiempo`, `h_cosecha`, `h_meta` y `seguridad`.

Antes de dar **Cargar**, revisa los tipos:

| Tabla | Columna | Tiene que ser |
|---|---|---|
| `h_cosecha` | `fecha` | **Fecha** |
| `h_cosecha` | `kg` | Número entero |
| `h_meta` | `fecha_mes` | **Fecha** |
| `h_meta` | `kg_meta` | Número entero |
| `dim_tiempo` | `fecha` | **Fecha** |

Si alguno llegó como **Texto**, entra a **Transformar datos** y cámbiale el tipo ahí.

### A3. Las seis relaciones

**Vista de modelo**: el tercer ícono de la barra de la izquierda. Acomoda las tres dimensiones arriba y los tres hechos abajo, y arrastra el campo del hecho sobre el campo de la dimensión. Las seis son **muchos a uno** (`*` del lado del hecho, `1` del lado de la dimensión), con dirección de filtro cruzado **Único**:

| # | Del lado muchos | Al lado uno |
|---|---|---|
| 1 | `h_cosecha[finca_id]` | `dim_finca[finca_id]` |
| 2 | `h_cosecha[cultivo_id]` | `dim_cultivo[cultivo_id]` |
| 3 | `h_cosecha[fecha]` | `dim_tiempo[fecha]` |
| 4 | `h_meta[finca_id]` | `dim_finca[finca_id]` |
| 5 | `h_meta[fecha_mes]` | `dim_tiempo[fecha]` |
| 6 | `seguridad[finca_id]` | `dim_finca[finca_id]` |

Si al soltar se abre el cuadro **Nueva relación**, revisa **Cardinalidad: Varios a uno (\*:1)** y **Dirección del filtro cruzado: Único**, y **Guardar**. Si una línea sale `1` → `1` o con dirección **Ambas**: doble clic sobre la línea y corrígela en el cuadro **Editar relación**.

Para revisar las seis de un jalón: **Inicio → Administrar relaciones**. Tienen que salir **seis filas**, todas activas. Si Power BI había creado alguna sola, bórrala desde ahí y dibújala tú.

**A3a.** En una línea, en tu `.md`: la relación 5 es la única con **nombres distintos** en sus dos puntas. **¿Qué habría pasado con ella si dejabas prendida la detección automática?**

**A3b.** En una línea: **¿por qué no hay relación entre `dim_cultivo` y `h_meta`?**

### A4. El calendario

1. Selecciona `dim_tiempo` en el panel **Datos** → **Herramientas de tabla → Marcar como tabla de fechas** → columna `fecha`.
2. Vista **Datos** → columna `nombre_mes` → **Herramientas de columnas → Ordenar por columna → `mes`**.

> ### ✅ Punto de control 1 · Captura 1
> **Revisa antes de tomarla:** cuenta las líneas. `h_cosecha` tiene **tres**, `h_meta` **dos**, `seguridad` **una**, y `dim_cultivo` solo toca a `h_cosecha`.
>
> La **Vista de modelo** completa, con las **seis tablas y las seis líneas**, y el `1` y el `*` visibles en cada línea. Acomoda las tablas para que no se encimen: las dimensiones arriba, los hechos abajo.
>
> Guárdala como `clase24-1-modelo.png`.

---

## Parte B · Las medidas y la tabla que prueba el modelo (15 min)

### B1. Las siete medidas

**Inicio → Nueva medida**, con `h_cosecha` seleccionada en el panel **Datos**. **Una por una**, cada línea es una medida:

```
Kilos = SUM( h_cosecha[kg] )
Meta = SUM( h_meta[kg_meta] )
Cumplimiento = DIVIDE( [Kilos] , [Meta] )
Kilos YTD = TOTALYTD( [Kilos] , dim_tiempo[fecha] )
Meta YTD = TOTALYTD( [Meta] , dim_tiempo[fecha] )
Color cumplimiento = IF( [Cumplimiento] >= 1 , "#1E8449" , "#C0392B" )
Quien mira = USERPRINCIPALNAME()
```

Formato: `[Cumplimiento]` en **Porcentaje** con dos decimales; `[Kilos]`, `[Meta]`, `[Kilos YTD]` y `[Meta YTD]` en **Número entero** con separador de miles. `[Color cumplimiento]` y `[Quien mira]` son texto: no llevan formato.

### B2. Los segmentadores

Dos objetos visuales **Segmentación de datos**: uno con `dim_tiempo[anio]`, marca **2026**; otro con `dim_tiempo[mes]`, marca **1, 2, 3 y 4** con `Ctrl + clic`. **No los muevas en todo el proyecto.**

### B3. La tabla por finca

Objeto visual **Tabla** con `dim_finca[finca]`, `[Kilos]`, `[Meta]` y `[Cumplimiento]`.

> ### ✅ Punto de control 2
> | Finca | `[Kilos]` | `[Meta]` | `[Cumplimiento]` |
> |---|---|---|---|
> | Agricola La Union | 2 100 | 5 000 | 42,00 % |
> | Finca El Guayabo | 14 250 | 9 440 | 150,95 % |
> | Hacienda Santa Rosa | 14 200 | 10 000 | 142,00 % |
> | **Total** | **30 550** | **24 440** | **125,00 %** |

**No sigas a la parte C hasta que te salga exactamente eso.** Si no te sale, **la tabla te dice qué relación falta**:

| Si ves… | Te falta la relación |
|---|---|
| `[Meta]` **47 000** y el total en **65,00 %** | 5 · `h_meta[fecha_mes]` → `dim_tiempo[fecha]` |
| `[Meta]` **24 440** en las tres fincas | 4 · `h_meta[finca_id]` → `dim_finca[finca_id]` |
| `[Kilos]` **77 550** en el total | 3 · `h_cosecha[fecha]` → `dim_tiempo[fecha]` |
| `[Kilos]` **30 550** en las tres fincas | 1 · `h_cosecha[finca_id]` → `dim_finca[finca_id]` |

---

## Parte C · El semáforo y los KPI (25 min)

### C1. El semáforo

En la tabla por finca: flechita junto a `Cumplimiento` en el pozo **Columnas** → **Formato condicional → Color de fondo**. **Estilo de formato: Valor del campo**. En **¿En qué campo debemos basarnos?** escoge `[Color cumplimiento]`, y en **Aplicar a**: **Valores y totales**.

> **No uses una regla con Porcentaje.** Ya sabes lo que pasa (clase 23).

> ### ✅ Punto de control 3
> | Finca | `[Cumplimiento]` | Color |
> |---|---|---|
> | Agricola La Union | 42,00 % | rojo |
> | Finca El Guayabo | 150,95 % | verde |
> | Hacienda Santa Rosa | 142,00 % | **verde** |
> | **Total** | **125,00 %** | **verde** |

### C2. El degradado

Tabla nueva con `dim_cultivo[cultivo]` y `[Kilos]`. Flechita junto a `Kilos` → **Formato condicional → Color de fondo → Degradado**, del blanco (mínimo) al verde (máximo).

> ### ✅ Punto de control 4
> | Cultivo | `[Kilos]` | Color |
> |---|---|---|
> | Mango | 12 700 | el más oscuro |
> | Maiz | 9 800 | |
> | Guayaba | 5 950 | |
> | Cacao | 2 100 | blanco |
>
> Banano y Café no salen: no tienen kilos en 2026.

### C3. Las tarjetas

Tres objetos visuales **Tarjeta**: `[Kilos]` (**30 550**), `[Cumplimiento]` (**125,00 %**) y `[Quien mira]` (tu propia cuenta, o tu usuario de Windows).

### C4. El KPI del año

Objeto visual **KPI**: `[Kilos YTD]` en **Valor**, `dim_tiempo[nombre_mes]` en **Eje de tendencia**, `[Meta YTD]` en **Destino**.

Ponle **título**: **Formato → General → Título**, uno que diga **qué periodo** enseña. Por ejemplo, «Acumulado del año contra meta».

> ### ✅ Punto de control 5 · Captura 2
> | Lo que dibuja el KPI | |
> |---|---|
> | El número grande | **30 550** |
> | El objetivo | **24 440** |
> | La distancia | **+25,00 %** |
>
> Si dice **19 750**, pusiste `[Kilos]` en vez de `[Kilos YTD]`: enseña abril. Si dice **10 800**, `nombre_mes` no está ordenada por `mes`.
>
> **Toma aquí la captura 2**, `clase24-2-tablero.png`: el lienzo completo **sin Ver como**, con los segmentadores, las tres tarjetas, el KPI con su título y las dos tablas pintadas.

---

## Parte D · Un rol para todos, y tres correos (20 min)

### D1. El rol

**Modelado → Administrar roles → Nuevo**. Nómbralo `Por correo`, escoge la tabla **`dim_finca`** y usa **Cambiar al editor DAX**:

```
Rol:       Por correo
Tabla:     dim_finca
Condición: [finca_id] IN
               CALCULATETABLE(
                   VALUES( seguridad[finca_id] ),
                   seguridad[correo] = USERPRINCIPALNAME()
               )
```

En el editor se escribe **solo la condición**, desde `[finca_id]` hasta el último paréntesis. Guarda.

### D2. Ver como el gerente de La Unión

**Modelado → Ver como →** marca **Otro usuario**, escribe `gerente.launion@agrodb.test` y **marca también el rol `Por correo`** → Aceptar. Son **dos marcas**, no una.

> ### ✅ Punto de control 6 · Captura 3
> | | |
> |---|---|
> | `[Quien mira]` | gerente.launion@agrodb.test |
> | Tabla por finca | **una fila**: Agricola La Union, **2 100 / 5 000 / 42,00 %**, en **rojo** |
> | Tabla por cultivo | **una fila**: Cacao, 2 100 |
> | KPI del año | **2 100** contra **5 000**, **−58,00 %** |
>
> Guárdala como `clase24-3-gerente.png`.

### D3. Ver como el regional

**Ver como →** Otro usuario: `regional.norte@agrodb.test`, rol `Por correo`.

> ### ✅ Punto de control 7 · Captura 4
> | Finca | `[Kilos]` | `[Meta]` | `[Cumplimiento]` |
> |---|---|---|---|
> | Agricola La Union | 2 100 | 5 000 | 42,00 % · rojo |
> | Finca El Guayabo | 14 250 | 9 440 | 150,95 % · verde |
> | **Total** | **16 350** | **14 440** | **113,23 % · verde** |
>
> KPI del año: **16 350** contra **14 440**, **+13,23 %**. Guárdala como `clase24-4-regional.png`.

### D4. Ver como el practicante

**Ver como →** Otro usuario: `practicante@agrodb.test`, rol `Por correo`. Ese correo **no está** en `seguridad.csv`.

> ### ✅ Punto de control 8 · Captura 5
> `[Quien mira]` dice practicante@agrodb.test, las dos tablas **sin filas**, y las tarjetas de kilos y cumplimiento y el KPI **vacíos**.
>
> Guárdala como `clase24-5-practicante.png`.

> **Si Ver como no recorta nada** y ya revisaste las dos marcas y el correo en «Si algo falla»: **toma las tres capturas igual**, con lo que salga, y en el `.md` escribe qué intentaste. Con el rol bien escrito en tu `.md` y la explicación, cada punto vale 5. **No te quedes aquí más de 20 minutos**: la parte E se puede hacer igual.

**D5.** En dos líneas: si el rol estuviera en la tabla `seguridad`, **¿qué vería el practicante?** ¿Y por qué eso es peor que un error?

---

## Parte E · El alta del practicante (10 min)

El practicante entra a apoyar en **Hacienda Santa Rosa** (`finca_id` 1). Eso **no se hace en el modelo**.

1. **Quita Ver como.**
2. Abre `C:\agrodb24\seguridad.csv` con el **Bloc de notas** y agrega **al final, en su propio renglón**:

```
practicante@agrodb.test,1
```

3. Guarda. En Power BI: **Inicio → Actualizar**. **No abras Administrar roles.**
4. **Ver como →** Otro usuario: `practicante@agrodb.test`, rol `Por correo`.

> ### ✅ Punto de control 9 · Captura 6
> | Finca | `[Kilos]` | `[Meta]` | `[Cumplimiento]` |
> |---|---|---|---|
> | Hacienda Santa Rosa | 14 200 | 10 000 | **142,00 %** · **verde** |
>
> KPI del año: **14 200** contra **10 000**, **+42,00 %**. Guárdala como `clase24-6-alta.png`, y **quita Ver como**.

**E1.** En una línea: para darle el permiso **no abriste el rol**. ¿Quién decide entonces lo que ve cada persona, y por qué ese archivo es tan delicado como los kilos?

---

## Parte F · Revisión y entrega (10 min)

1. Abre tus seis capturas y compáralas, **una por una**, con la tabla de «Así se califica».
2. Llena la tabla del checklist en tu `.md` con **lo que salió en tu pantalla**, y una línea por punto con la trampa que descarta.
3. Pega las siete medidas y el rol en bloques de código, y contesta A3a, A3b, D5 y E1.
4. Sube los siete archivos a `entregas/apellido-nombre/` y abre el *pull request* **hoy, al terminar**, aunque falte algo. **Ni el `.pbix` ni el `seguridad.csv` modificado.**

---

## Si algo falla

| Síntoma | Qué pasó | Qué haces |
|---|---|---|
| No encuentras la opción de detectar relaciones | tu versión la llama distinto | anótalo, y en A3 borra las relaciones que Power BI creó solo |
| No deja crear la relación 5 | `fecha_mes` se cargó como texto | **Transformar datos** → tipo **Fecha** |
| La relación sale `1` → `1` | la arrastraste entre dos dimensiones o al revés | bórrala y arrastra del hecho a la dimensión |
| `[Meta]` dice 47 000, o 24 440 en cada finca | falta la relación 5, o la 4 | la tabla de la parte B3 dice cuál |
| Marcar como tabla de fechas se queja | `fecha` no es tipo **Fecha** | cámbialo en **Transformar datos** |
| El KPI dice **19 750** | pusiste `[Kilos]` y `[Meta]` | cámbialos por `[Kilos YTD]` y `[Meta YTD]` |
| El KPI dice **10 800** | `nombre_mes` no está ordenada | **Ordenar por columna → `mes`** |
| En **Valor del campo** no aparece `[Color cumplimiento]` | la medida tiene un error | revisa las comillas y el `#` |
| El total de la tabla no se pinta | **Aplicar a** quedó en solo valores | **Valores y totales** |
| `[Quien mira]` cambia pero nada se recorta | marcaste Otro usuario **y no el rol** | marca los dos |
| Con el rol, **todo** vacío, también con el gerente | el correo va mal escrito | cópialo del CSV |
| Con el regional, los objetos visuales dan error | escribiste `=` o `LOOKUPVALUE` en vez de `IN` | copia la condición de D1 |
| Agregaste el practicante y sigue vacío | falta **Actualizar**, o editaste otro archivo | edita el de `C:\agrodb24\` y **Actualizar** |
| **Actualizar** da error de archivo | el CSV sigue abierto en Excel | ciérralo y vuelve a **Actualizar** |
| No sabes cómo quitar Ver como | | **Modelado → Ver como** otra vez → desmarca todo, o el botón **Detener** de la barra amarilla |
| Los decimales o los miles salen distintos | configuración regional de tu Windows | **no es un error**, anótalo y sigue |

> ### La regla de los 20 minutos sigue vigente
> Veinte minutos atorado en lo mismo: lo escribes en tu archivo empezando con `DUDA`, o abres un *issue*, y sigues con lo siguiente. **Atorarse no baja la nota. Quedarse callado sí.**

---

## Si terminas antes

No puntúa, pero es lo que la gerencia va a pedir después:

- Un **medidor** con `[Kilos]`, `[Meta]` en **Valor de destino** y `Tope del medidor = [Meta] * 1.5` en **Valor máximo** (36 660).
- Un segundo KPI con `[Kilos]` y `[Meta]`, titulado «Abril: kilos contra meta del mes»: **19 750** contra **8 300**.
- Un semáforo de tres colores con `SWITCH( TRUE() , … )`, con amarillo entre el 90 y el 100 %.

---

## Plan B · Si Power BI Desktop no abre en tu máquina

1. Ponte con un compañero: el tablero se arma en una sola máquina.
2. **Tú escribes las medidas y el rol** en tu propio archivo `.md`, y anotas con quién trabajaste.
3. **La columna «Qué trampa descarta» y las respuestas de A3a, A3b, D5 y E1 las escribes tú**, con tus propias palabras.
4. Las capturas son las mismas para los dos, y los dos lo dicen en un comentario.

**Con el Plan B completo se llega a 100 de 100.**

---

## Rúbrica (100 puntos)

Es el checklist de arriba: diez puntos, uno por captura o por el `.md`.

| Criterio | Pts |
|---|---|
| 1 · Modelo: seis tablas, seis relaciones `*` → `1` (captura 1) | 10 |
| 2 · Tabla por finca y total 125,00 % (captura 2) | 10 |
| 3 · Semáforo: Santa Rosa y el total en verde (captura 2) | 10 |
| 4 · Degradado por cultivo (captura 2) | 10 |
| 5 · KPI del año 30 550 contra 24 440 con título, y las tarjetas (captura 2) | 10 |
| 6 · Gerente de La Unión: una fila, 42,00 % (captura 3) | 10 |
| 7 · Regional: dos fincas, 113,23 % (captura 4) | 10 |
| 8 · Practicante sin permiso: nada (captura 5) | 10 |
| 9 · Practicante con permiso: Santa Rosa, 142,00 % (captura 6) | 10 |
| 10 · El `.md`: checklist lleno, medidas, rol, la trampa de cada punto, A3a, A3b, D5 y E1 | 10 |

Los criterios suman **100** exactos.

> **Lo que más se nota hoy no es que el tablero se vea bonito.** Es que cada número de tus capturas sea el que dice el checklist, y que sepas **qué trampa habría puesto otro en su lugar**.
