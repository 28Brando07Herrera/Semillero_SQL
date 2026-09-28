# Ejercicio práctico 28 · El precio de cada cosecha

**Duración: 2 horas · Individual · Solo Power BI Desktop · Entrega: un archivo `.md` y dos capturas**

---

## Qué vas a lograr hoy

1. Armar el modelo de siempre y cargar una tabla de **precios** sin relacionarla.
2. Llevar el precio a cada cosecha con **Combinar consultas**, y escribir `[Ingresos]`.
3. Caer en la combinación obvia, **por el cultivo**, y encontrar las cosechas que se duplicaron.
4. Caer en el segundo arreglo obvio, **Quitar duplicados**, y encontrar los **990** dólares que cobró de más.
5. Combinar por la **llave completa**: el cultivo **y** la calidad.
6. Hacer la misma búsqueda con `LOOKUPVALUE` y con una relación, y comparar quién avisa.

**El número que prueba que el tablero quedó bien: 17 120 en ingresos, con el control en 30 550 y `[Filas repetidas]` en 0.** El que prueba que entendiste la clase es que sepas por qué `Quitar duplicados` pasó las tres pruebas y siguió mal.

---

## Antes de empezar

De nuevo solo Power BI: hoy tampoco se prende Oracle, ni Docker, ni el driver.

| | |
|---|---|
| Oracle, Docker, OCMT, `GRANT` | **no** |
| Power BI Desktop | **sí**, y es lo único |

### Lo que se baja hoy

**Hoy sí se baja algo:** [`datos/csv_clase28/`](../../datos/csv_clase28/). Son los seis CSV de la clase 19, **idénticos**, más uno nuevo: **`precios.csv`**, siete filas con el precio por kilo de cada cultivo según su calidad.

Copia la carpeta completa a `C:\agrodb28\` y trabaja sobre esa copia.

> **Hoy se empieza con un `.pbix` vacío**, como en la 24, la 26 y la 27.

### El correo de comercial

> *«Es la lista 2026. El kilo nos sale en promedio a **cincuenta y tantos centavos**. Quiero los **ingresos por finca**.»*

---

## Cómo se entrega

En `entregas/apellido-nombre/`, por *pull request*, **tres archivos**:

| Archivo | Qué lleva |
|---|---|
| `Ejercicio28_Apellido_Nombre.md` | cada medida en un bloque de código **con su resultado anotado debajo**, las tablas que se piden y las respuestas a las preguntas |
| `clase28-distribucion.png` | **Power Query** con `h_cosecha` abierta, combinada solo por `cultivo_id`, y la **distribución de columnas** de `cosecha_id` en **25 distintos, 4 únicos** |
| `clase28-ingresos.png` | la **tabla de ingresos por finca** con la llave completa: total **17 120**, y una tarjeta de `[Filas repetidas]` en **0** |

> El `.pbix` no se entrega: el repositorio lo ignora a propósito.

---

## Parte A · El modelo (20 min)

### A0. La configuración regional, antes de cargar nada

Como el viernes: **Archivo → Opciones y configuración → Opciones → Archivo actual → Configuración regional** → **Español (México)** → **Aceptar**.

Hoy importa por otra razón: `precios.csv` trae `0.50` con **punto** decimal. Con una configuración que usa coma, ese `0.50` se lee como **50**.

### A1. Cargar

1. En **Archivo actual → Carga de datos**, apaga **«Detectar automáticamente nuevas relaciones después de cargar los datos»**.
2. **Inicio → Obtener datos → Texto o CSV**, uno por uno, con **Cargar**: `h_cosecha`, `h_meta`, `dim_tiempo`, `dim_finca`, `dim_cultivo` **y `precios`**. **`seguridad.csv` no se carga hoy.**

### A2. Las cinco relaciones

| # | De | A |
|---|---|---|
| 1 | `h_cosecha[finca_id]` | `dim_finca[finca_id]` |
| 2 | `h_cosecha[cultivo_id]` | `dim_cultivo[cultivo_id]` |
| 3 | `h_cosecha[fecha]` | `dim_tiempo[fecha]` |
| 4 | `h_meta[finca_id]` | `dim_finca[finca_id]` |
| 5 | `h_meta[fecha_mes]` | `dim_tiempo[fecha]` |

**`precios` se queda sin relaciones.** Su precio va a llegar a `h_cosecha` por Power Query.

### A3. El calendario y las medidas

1. `dim_tiempo` → **Marcar como tabla de fechas** → `fecha`. `nombre_mes` → **Ordenar por columna** → `mes`.
2. Con `h_cosecha` seleccionada, **Nueva medida**, una por una:

```
Kilos = SUM( h_cosecha[kg] )
```

```
Meta = SUM( h_meta[kg_meta] )
```

```
Cumplimiento = DIVIDE( [Kilos] , [Meta] )
```

```
Cosechas = COUNTROWS( h_cosecha )
```

```
Filas repetidas = COUNTROWS( h_cosecha ) - DISTINCTCOUNT( h_cosecha[cosecha_id] )
```

### A4. La tabla de control

Segmentadores `dim_tiempo[anio]` = **2026** y `dim_tiempo[mes]` de **1 a 4**. Tabla con `dim_finca[finca]`, `[Kilos]`, `[Meta]`, `[Cumplimiento]` y `[Cosechas]`, y una tarjeta con `[Filas repetidas]`:

| Finca | `[Kilos]` | `[Meta]` | `[Cumplimiento]` | `[Cosechas]` |
|---|---|---|---|---|
| Agricola La Union | 2 100 | 5 000 | 42,00 % | 2 |
| Finca El Guayabo | 14 250 | 9 440 | 150,95 % | 3 |
| Hacienda Santa Rosa | 14 200 | 10 000 | 142,00 % | 4 |
| **Total** | **30 550** | **24 440** | **125,00 %** | **9** |

`[Filas repetidas]` tiene que decir **0**. Si el total no dice **125,00 %**, no sigas: revisa las relaciones 3 y 5.

**A5.** Abre `precios.csv` en el Bloc de notas. En una línea: ¿qué columnas hacen falta para encontrar **un solo** precio? Contesta **antes** de seguir; en la parte D vas a volver a esta respuesta.

---

## Parte B · La combinación obvia (20 min)

**B1.** **Inicio → Transformar datos**. En el panel de la izquierda selecciona la consulta **`h_cosecha`** y anota cuántas **filas** dice abajo a la izquierda.

**B2.** **Inicio → Combinar consultas** (no *como nuevas*). Arriba está `h_cosecha`: clic en el encabezado **`cultivo_id`**. Abajo elige `precios`: clic en **`cultivo_id`**. Tipo de combinación: **Externa izquierda**. Copia **literal** lo que dice Power Query abajo del cuadro, y da **Aceptar**.

**B3.** Aparece una columna `precios` con la palabra `Table` en cada celda. Clic en el ícono de las dos flechas del encabezado → deja marcado **solo `precio_kg`** → **Aceptar**. Revisa que el ícono de `precio_kg` sea **número decimal** (`1.2`); si es **ABC**, cámbialo.

**B4.** **Inicio → Cerrar y aplicar.** Con `h_cosecha` seleccionada:

```
Ingresos = SUMX( h_cosecha , h_cosecha[kg] * h_cosecha[precio_kg] )
```

```
Precio por kilo = DIVIDE( [Ingresos] , [Kilos] )
```

**B5.** **Página nueva**, con los mismos segmentadores (`anio` 2026, `mes` 1–4). Tabla con `dim_finca[finca]`, `[Ingresos]` y `[Precio por kilo]`. Copia la tabla. Tiene que salir La Union **9 030**, El Guayabo **7 390**, Santa Rosa **11 660**, total **28 080**, y el kilo a **0,55**.

**B6.** En una línea, contra el correo de comercial: ¿algo de esa tabla te habría hecho sospechar?

---

## Parte C · El número que no debía moverse (20 min)

**C1.** Regresa a la página de control. Copia la tabla. Tiene que salir **51 300 / 209,90 % / 17**, con La Union en **84,00 %**, y `[Filas repetidas]` en **8**.

**C2.** **Transformar datos** → `h_cosecha`. ¿Cuántas filas dice ahora abajo a la izquierda? Tiene que salir **46**.

**C3.** **Vista → Distribución de columnas.** Anota lo que dice debajo de `cosecha_id`: **distintos** y **únicos**. Tiene que salir **25 distintos, 4 únicos**.

> **Toma aquí la captura `clase28-distribucion.png`**: Power Query con la distribución de `cosecha_id` a la vista.

**C4.** En la cuadrícula de Power Query, filtra `cosecha_id` = **2**. Copia las filas que salen, con su `calidad` y su `precio_kg`. ¿Cuál de los dos precios es el que le toca?

**C5.** ¿Cuáles son las **4** cosechas que siguen siendo únicas? ¿Qué tienen en común, y por qué a ellas no les pasó?

**C6.** B2 dijo **25 de 25**. En una línea: ¿qué cuenta ese número, y qué **no** cuenta?

**C7.** El precio por kilo pasó de 0,56 (lo vas a ver en la parte E) a 0,55. En dos líneas: ¿por qué **casi no se movió**, si los ingresos se inflaron 64 %?

---

## Parte D · El segundo arreglo obvio (20 min)

**D1.** En `h_cosecha`, selecciona la columna `cosecha_id` → **Inicio → Quitar filas → Quitar duplicados**. **Cerrar y aplicar.**

**D2.** Las tres pruebas. Anota cada una:

| Prueba | Tiene que decir |
|---|---|
| Filas de `h_cosecha` en Power Query | 25 |
| Tabla de control | 30 550 / 125,00 % / 9 |
| `[Filas repetidas]` | 0 |

**D3.** Página de ingresos. Copia la tabla. Tiene que salir La Union **5 250**, El Guayabo **5 610**, Santa Rosa **7 250**, total **18 110**. Si te sale **12 910**, anótalo: en tu versión sobrevivió la otra fila (lee la nota del final).

**D4.** Con `precios.csv` y `h_cosecha.csv` abiertos, calcula **a mano** el ingreso de las nueve cosechas de enero–abril 2026, con **el precio que le toca a cada una**. Copia esta tabla y llénala:

| `cosecha_id` | Cultivo | Calidad | Kilos | Precio que toca | Ingreso |
|---|---|---|---|---|---|
| 1 | Mango | primera | 4 200 | | |
| 2 | Mango | segunda | 3 100 | | |
| 3 | Mango | primera | 5 400 | | |
| 4 | Guayaba | primera | 1 500 | | |
| 5 | Guayaba | primera | 2 600 | | |
| 6 | Guayaba | segunda | 1 850 | | |
| 7 | Maiz | primera | 9 800 | | |
| 8 | Cacao | primera | 1 200 | | |
| 9 | Cacao | primera | 900 | | |
| | | | **30 550** | | **17 120** |

**D5.** ¿Qué **dos** cosechas explican la diferencia entre 18 110 y 17 120? Escribe la cuenta de cada una. Tienen que sumar **990**.

**D6.** En una línea: ¿qué hizo `Quitar duplicados` con cada cosecha repetida, y quién escogió el precio que quedó?

---

## Parte E · La llave completa (25 min) — es la parte que más vale

**E1.** **Transformar datos** → `h_cosecha` → **Pasos aplicados**: borra de abajo hacia arriba **Duplicados quitados**, **precios expandido** (o como se llame en tu versión) y **Consultas combinadas**. Anota los nombres que tenían en la tuya.

**E2.** **Combinar consultas** otra vez. Arriba: clic en **`cultivo_id`** y **Ctrl** + clic en **`calidad`**. Abajo, `precios`: **`cultivo_id`** y **Ctrl** + **`calidad`**, **en el mismo orden**. Tienen que aparecer un **1** y un **2** en los encabezados. Copia lo que dice Power Query abajo del cuadro.

**E3.** Expande solo **`precio_kg`**. ¿Cuántas filas tiene ahora `h_cosecha`, y qué dice la distribución de `cosecha_id`? Tiene que salir **25** filas, **25 distintos, 25 únicos**. **Cerrar y aplicar.**

**E4.** La tabla de control y `[Filas repetidas]`: tienen que decir **30 550 / 125,00 % / 9** y **0**.

**E5.** La tabla de ingresos por finca. Tiene que salir La Union **5 250**, El Guayabo **5 240**, Santa Rosa **6 630**, total **17 120**, y el kilo a **0,56**. Agrega **`[Filas repetidas]`** en una tarjeta al lado.

> **Toma aquí la captura `clase28-ingresos.png`**: la tabla de ingresos con 17 120 y la tarjeta en 0.

**E6.** Tabla por cultivo con `dim_cultivo[cultivo]` e `[Ingresos]`. Tiene que salir Mango **5 730**, Guayaba **3 200**, Cacao **5 250**, Maiz **2 940**. Compárala contra la de la parte B: ¿cuál es el **único** cultivo que dio lo mismo con las dos combinaciones, y por qué?

**E7.** Vuelve a tu respuesta de A5. ¿Acertaste? En una línea: ¿cuál es la **llave** de `precios`?

---

## Parte F · Quién avisa, y preguntas de cierre (15 min)

**F1.** En `h_cosecha`, **Nueva columna**:

```
Precio incompleto = LOOKUPVALUE( precios[precio_kg] , precios[cultivo_id] , h_cosecha[cultivo_id] )
```

Copia **literal** el error. Luego **borra la columna**.

**F2.** **Nueva columna**, con la llave completa:

```
Precio buscado = LOOKUPVALUE( precios[precio_kg] ,
    precios[cultivo_id] , h_cosecha[cultivo_id] ,
    precios[calidad] , h_cosecha[calidad] )
```

Y una medida que lo compara contra lo que trajo Power Query:

```
Diferencia de precio = SUMX( h_cosecha , ABS( h_cosecha[precio_kg] - h_cosecha[Precio buscado] ) )
```

Tiene que decir **0**. Anótalo.

**F3.** En la **vista de modelo**, arrastra `h_cosecha[cultivo_id]` sobre `precios[cultivo_id]`. **No la guardes**: anota qué **cardinalidad** propone Power BI y copia el aviso que muestra. Luego **Cancelar**.

**F4.** Preguntas de cierre:

1. En una línea: ¿qué diferencia hay entre **Anexar** y **Combinar**, dicha en filas y columnas?
2. En una línea: escribe la **regla de detección** del día, tomando como base la del viernes: *«si al cargar datos nuevos se mueve un número viejo, los datos nuevos no dicen lo que crees»*.
3. En dos líneas: `Quitar errores` (clase 27) y `Quitar duplicados` (hoy). ¿En qué se parecen, y por qué `Quitar duplicados` es más peligroso?
4. En una línea: la clase 5 tuvo un `SUM` inflado por *fan-out*. ¿Qué tabla hizo hoy el papel de la tabla con varias filas por llave?
5. En dos líneas: el año que viene comercial manda precios **por cultivo, calidad y mes**. ¿Qué cambia en la combinación, y qué prueba harías primero?

---

## Si algo falla

| Síntoma | Qué pasó | Qué haces |
|---|---|---|
| `precio_kg` sale **50**, **30**, **250** | configuración regional con coma decimal | haz A0 y vuelve a crear la consulta `precios` |
| La combinación dice **0 de 25** | `cultivo_id` tiene tipos distintos en las dos consultas | mismo ícono en las dos: **número entero** |
| No aparece **Combinar consultas** | estás en la vista de informe | **Inicio → Transformar datos** primero |
| La columna expandida se llama `precios.precio_kg` | quedó marcado el prefijo al expandir | no afecta; úsala así en la medida |
| En C1 el control **no** se movió | combinaste por dos columnas desde el principio | bien visto: anótalo, haz la parte C con **una** sola |
| En E3 siguen saliendo **46** filas | seleccionaste la segunda columna sin **Ctrl** | tienen que verse el **1** y el **2** en los dos encabezados |
| En E3 salen **25** filas pero `precio_kg` vacío en algunas | el orden de las columnas no es el mismo arriba y abajo | primero `cultivo_id`, después `calidad`, en las dos |
| `[Ingresos]` da error de tipo | `precio_kg` quedó como texto | cámbialo a **número decimal** en Power Query |
| F1 **no** da error | `precios` quedó con un solo precio por cultivo | revisa que `precios` tenga **7** filas y que no le hayas quitado duplicados |
| Los decimales o los miles salen distintos | configuración regional de tu Windows | **no es un error**, anótalo y sigue |

> ### La regla de los 20 minutos sigue vigente
> Veinte minutos atorado en lo mismo: lo escribes en tu archivo empezando con `DUDA`, o abres un *issue*, y sigues con lo siguiente. **Atorarse no baja la nota. Quedarse callado sí.**

---

## Plan B · Si Power BI Desktop no abre en tu máquina

1. Ponte con un compañero: el modelo se arma en una sola máquina.
2. **Tú escribes todas las medidas** en tu propio archivo `.md`, con sus resultados, y anotas con quién trabajaste.
3. **La tabla de D4 y las respuestas de A5, C4, C5, C6, C7, D5, D6 y E7 las haces tú**, con tus propias palabras y con los CSV abiertos: se contestan leyendo `precios.csv` y `h_cosecha.csv`.
4. Las capturas son las mismas para los dos, y los dos lo dicen en un comentario.

**Con el Plan B completo se llega a 100 de 100.** Lo que se califica es qué precio le tocó a cada cosecha y por qué, no de quién era la laptop.

---

## Rúbrica (100 puntos)

| Criterio | Pts |
|---|---|
| Parte A: el modelo con sus cinco relaciones, las medidas, la tabla de control en 125,00 % y A5 | 10 |
| Parte B: el «coincide con» literal, la tabla de ingresos en 28 080, y B6 | 10 |
| Parte C: el 51 300 y las 46 filas, la captura de la distribución, y C4 a C7 | 20 |
| **Parte D: las tres pruebas, el 18 110, la tabla de D4 a mano, y los 990 de D5** | **25** |
| Parte E: la llave completa, 25 filas, 17 120, E6 y E7, y la captura | 20 |
| Parte F: el error de F1, la diferencia en 0, la cardinalidad de F3, y las cinco preguntas con criterio | 15 |

Los criterios suman **100** exactos.

> **Lo que más se califica hoy no es el Ctrl + clic**, que se copia del enunciado. Es la tabla de D4: que hayas calculado a mano el precio de cada cosecha, y que sepas explicar con `cosecha_id` **de dónde salieron** los 990 que `Quitar duplicados` dejó pasar con las tres pruebas en verde.

---

> **Nota sobre `Quitar duplicados`.** Power Query se queda con **la primera fila que encuentra** de cada `cosecha_id`, y el orden depende de cómo llegaron las filas de la combinación. Con estos archivos suele sobrevivir la del precio de **primera**, y salen 18 110. Si te sobrevive la de **segunda**, salen **12 910** (las cosechas 1, 3, 4, 5, 8 y 9 cobradas a precio de segunda). Las dos están mal, y **las dos pasan las tres pruebas**: eso es lo que importa.
