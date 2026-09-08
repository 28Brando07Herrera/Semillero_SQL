# Ejercicio práctico 16 · Haz que el tablero diga que la finca se cayó, y después arréglalo
**Duración: 2 horas · Individual · Solo Power BI Desktop · Entrega: un archivo `.md` y una captura**

---

## Qué vas a lograr hoy

1. Cargar **dos campañas** —2025 y 2026— con un calendario de **730 días**, y comprobar que el 30 550 de siempre sigue exacto adentro de un total más grande.
2. Dejar `dim_tiempo` **marcada como tabla de fechas**, que es el único requisito técnico del día.
3. Ver por qué **Abril va antes que Marzo** cuando nadie ordena el eje.
4. Escribir tu primer acumulado con `TOTALYTD` y tu primera comparación con `SAMEPERIODLASTYEAR`.
5. Provocar, a propósito, el número silencioso del día: una caída de **−35,00 %** que es aritmética correcta sobre datos completos y **que se defiende en una junta**.
6. Detectarlo con dos medidas de una línea, y verlo cambiar de signo a **+30,00 %** sin tocar una sola fórmula.

**El número que prueba que la carga salió bien es 77 550.** El que prueba que entendiste la clase es que **la misma medida** diga −35,00 % y +30,00 % y las dos veces esté bien.

---

## Antes de empezar

Lo mismo que la clase pasada: hoy **no** se prende Oracle, ni Docker, ni el driver.

| | |
|---|---|
| Oracle, Docker, OCMT, `GRANT` | **no** |
| Power BI Desktop | **sí**, y es lo único |

### Descarga los cuatro archivos

Están en [`datos/csv_clase16/`](../../datos/csv_clase16/):

```
dim_finca.csv       3 filas
dim_cultivo.csv     6 filas
dim_tiempo.csv    730 filas   <- 2025 y 2026
h_cosecha.csv      25 filas   <- 9 de 2026 + 16 de 2025
```

**Guárdalos en `C:\agrodb\csv16\`.** En una carpeta **nueva**, no encima de los de la clase 15.

> ### ⚠ Dos de los cuatro archivos cambiaron
> `dim_tiempo.csv` y `h_cosecha.csv` **no son los de la clase pasada**. Si reutilizas el `.pbix` de ayer sin volver a apuntar las rutas, el total te va a dar 30 550 en vez de 77 550 y vas a perder media hora. **Empieza un `.pbix` nuevo.** Es más rápido.

### De dónde salieron las 16 filas nuevas

De un histórico, no del sistema operativo: **AgroDB arranca en 2026**. La campaña 2025 existía en papel y en una hoja de cálculo, y hoy entra al almacén. Por eso sus `cosecha_id` van del **10 al 25** y no del 1 al 16: el id es orden de carga, no orden de calendario.

---

## Cómo se entrega

En `entregas/apellido-nombre/`, por *pull request*, **dos archivos**:

| Archivo | Qué lleva |
|---|---|
| `Ejercicio16_Apellido_Nombre.md` | **cada medida en un bloque de código**, y debajo el valor que te dio, más las respuestas de la parte F |
| `clase16-tablero.png` | captura del tablero terminado, con **las dos tarjetas de variación juntas**: −35,00 % y +30,00 % |

Formato de cada respuesta, para que se pueda corregir:

````
### C1 · Kilos YTD

```
Kilos YTD = TOTALYTD( [Kilos] , dim_tiempo[fecha] )
```

Resultado en la celda de Abril 2026: 30550
````

> **Una medida sin su resultado anotado abajo no cuenta.** Y el `.pbix` no se entrega: el repositorio lo ignora a propósito.

---

## Parte A · Dos años y un calendario que alcance (20 min)

### A1. Carga los cuatro CSV

**Inicio → Obtener datos → Texto/CSV**, uno por uno, desde `C:\agrodb\csv16\`.

Antes de dar **Cargar**, revisa los tipos:

| Tabla | Columna | Tiene que ser |
|---|---|---|
| `h_cosecha` | `kg` | Número entero |
| `h_cosecha` | `fecha` | Fecha |
| `dim_tiempo` | `fecha` | Fecha |
| `dim_tiempo` | `anio`, `mes`, `trimestre` | Número entero |
| `dim_tiempo` | `anio_mes`, `nombre_mes` | Texto |

### A2. Apaga la fecha/hora automática

**Archivo → Opciones y configuración → Opciones → Carga de datos → Inteligencia de tiempo**, y **desmarca** la fecha/hora automática *(en el archivo actual)*.

Power BI fabrica un calendario oculto por cada columna de fecha. Ya tenemos el nuestro, y dos calendarios compitiendo es la receta del número raro.

**A2b.** En un comentario, una línea: **¿estaba prendida o apagada en tu máquina?**

### A3. Marca `dim_tiempo` como tabla de fechas

Selecciona la tabla `dim_tiempo` → **Herramientas de tabla → Marcar como tabla de fechas** → columna **`fecha`**.

> **Este es el único requisito técnico del día.** Sin él, `TOTALYTD` y `SAMEPERIODLASTYEAR` pueden contestar cualquier cosa. Si Power BI te reclama, es porque la columna tiene huecos o repetidos: los 730 días tienen que estar completos y sin repetir.

### A4. Las relaciones

Vista **Modelo**. Las tres, todas **muchos a uno** hacia la dimensión:

| De | A |
|---|---|
| `h_cosecha[finca_id]` | `dim_finca[finca_id]` |
| `h_cosecha[cultivo_id]` | `dim_cultivo[cultivo_id]` |
| `h_cosecha[fecha]` | `dim_tiempo[fecha]` |

### A5. Las dos medidas de siempre

```
Kilos    = SUM(h_cosecha[kg])
Cosechas = COUNTROWS(h_cosecha)
```

Arma una **tabla** con `dim_tiempo[anio]`, `[Kilos]` y `[Cosechas]`.

> ### ✅ Punto de control 1
> | Año | Kilos | Cosechas |
> |---|---|---|
> | 2025 | **47 000** | 16 |
> | 2026 | **30 550** | 9 |
> | **Total** | **77 550** | **25** |
>
> **Pega la tabla completa.** Si el total no da 77 550, no sigas: cargaste los CSV de la clase 15.
>
> Y si aparece **una fila sin nombre**, tu `dim_tiempo` no cubre los dos años. Vuelve a A1.

**A6.** En una línea: el `[Kilos]` de 2026 sigue dando 30 550, el mismo número desde la clase 5. **¿Se perdió algo al agregar 2025?**

---

## Parte B · El eje de tiempo (15 min)

### B1. Abril antes que Marzo

Inserta un **gráfico de columnas** con **Eje X** `dim_tiempo[nombre_mes]` y **Valores** `[Kilos]`. Míralo antes de arreglar nada.

**B2.** En un comentario: **escribe el orden en que salieron los meses.** Es texto, y el texto se ordena alfabéticamente.

### B3. Arréglalo

Vista **Datos** → selecciona la columna `nombre_mes` → **Herramientas de columnas → Ordenar por columna → `mes`**.

> ### ✅ Punto de control 2
> El mismo gráfico ahora va de Enero a Diciembre. Los dos años están sumados en cada barra, así que Marzo dice **19 000** (10 800 + 8 200) y Abril dice **29 250** (19 750 + 9 500).
>
> **Pega esos dos números.**

**B4.** En una línea: los números de las barras **no cambiaron** al ordenar el eje. **¿Por qué entonces importa el orden?**

### B5. El eje del hecho contra el eje de la dimensión

Haz dos gráficos de líneas, uno al lado del otro, los dos con `[Kilos]` en valores y con el segmentador de `anio` en **2026**:

| Gráfico | Eje X |
|---|---|
| izquierda | `h_cosecha[fecha]` |
| derecha | `dim_tiempo[anio_mes]` |

> ### ✅ Punto de control 3
> El de la izquierda dibuja **solo los meses con cosecha**. El de la derecha dibuja **los doce meses de 2026**, ocho de ellos vacíos.
>
> **Anota cuántos puntos tiene cada gráfico.**

**B6.** En dos líneas: los dos gráficos usan los mismos datos y ninguno miente. **¿Cuál de los dos le esconde algo a quien lo mira, y qué le esconde?**

---

## Parte C · El acumulado (20 min)

### C1. `Kilos YTD`

```
Kilos YTD = TOTALYTD( [Kilos] , dim_tiempo[fecha] )
```

Arma una **matriz**: **Filas** `dim_tiempo[anio]` y debajo `dim_tiempo[nombre_mes]` · **Valores** `[Kilos]` y `[Kilos YTD]`. Expande los dos años.

> **Antes de leer los números: limpia el segmentador de `anio` que dejaste en 2026 en la parte B**, o haz esta matriz en una **página nueva**. Si el segmentador sigue puesto no vas a ver 2025 y vas a pensar que la medida está rota.

> ### ✅ Punto de control 4
> | Año | Mes | `[Kilos]` | `[Kilos YTD]` |
> |---|---|---|---|
> | 2025 | Enero | 2 000 | **2 000** |
> | 2025 | Marzo | 8 200 | **14 000** |
> | 2025 | **Abril** | 9 500 | **23 500** |
> | 2025 | Diciembre | 1 200 | **47 000** |
> | 2026 | Marzo | 10 800 | **10 800** |
> | 2026 | **Abril** | 19 750 | **30 550** |
> | 2026 | Mayo | *(vacío)* | **30 550** |
> | 2026 | Diciembre | *(vacío)* | **30 550** |
>
> **Pega las ocho filas.** Ese **23 500** de abril de 2025 es el número del día; ya lo tienes y todavía no sabes para qué.

**C2.** En una línea: en mayo de 2026 `[Kilos]` está vacío y `[Kilos YTD]` dice 30 550. **¿Por qué el acumulado no se cae a cero?**

**C3.** Enero y Febrero de 2026 probablemente **no aparecen** en la matriz. En una línea: **¿por qué?** (Pista: las dos medidas están vacías ahí, y una matriz no dibuja filas totalmente vacías.)

---

## Parte D · El año pasado (20 min)

### D1. `Kilos AA`

```
Kilos AA = CALCULATE( [Kilos] , SAMEPERIODLASTYEAR( dim_tiempo[fecha] ) )
```

Agrégala a la matriz de la parte C.

> ### ✅ Punto de control 5
> | Año | Mes | `[Kilos]` | `[Kilos AA]` |
> |---|---|---|---|
> | 2025 | Abril | 9 500 | *(vacío)* |
> | 2026 | Marzo | 10 800 | **8 200** |
> | 2026 | Abril | 19 750 | **9 500** |
> | 2026 | Agosto | *(vacío)* | **5 600** |
>
> **Pega las cuatro filas.**

**D2.** En una línea: en 2025 la columna `[Kilos AA]` sale **vacía entera**. **¿Es un error?** ¿Qué año tendría que estar en el calendario para que no lo estuviera?

### D3. La variación

```
Variacion AA = DIVIDE( [Kilos] - [Kilos AA] , [Kilos AA] )
```

Dale formato de **porcentaje con dos decimales**.

> ### ✅ Punto de control 6
> En la matriz, la fila de **Marzo 2026** dice **+31,71 %** y la de **Abril 2026** dice **+107,89 %**.
>
> **Pega los dos.** Anótalos bien, porque en cinco minutos vas a leer que la finca se cayó 35 %.

**D4.** En una línea: **¿por qué `DIVIDE` y no la diagonal?** (Ya lo contestaste ayer; contéstalo otra vez sin buscarlo.)

---

## Parte E · La trampa del día (35 min) — es la parte que más vale

### E1. La tarjeta que se manda por correo

Quita la matriz de en medio. Inserta un **segmentador** con `dim_tiempo[anio]` y selecciona **solo 2026**.

Ahora tres **Tarjetas**, una al lado de la otra: `[Kilos]`, `[Kilos AA]` y `[Variacion AA]`.
Formato → **Unidades de presentación: Ninguna**, y dos decimales.

> ### ✅ Punto de control 7
> | Medida | Valor |
> |---|---|
> | `[Kilos]` | **30 550** |
> | `[Kilos AA]` | **47 000** |
> | `[Variacion AA]` | **−35,00 %** |
>
> **Pégalo.** *«La cosecha cayó 35 % contra el año pasado.»*

**E2.** Antes de seguir leyendo, contesta en un comentario: **¿qué mensaje de error dio Power BI?**

(La respuesta es incómoda a propósito, igual que ayer.)

**E3.** En un comentario: en la parte A comprobaste que 2026 son 30 550 kilos y 2025 son 47 000. Los dos números son correctos y la resta está bien hecha. **Entonces, ¿qué es exactamente lo que está mal?** Escríbelo antes de hacer E4.

### E4. Saca las dos fechas de corte

Dos medidas de una línea cada una:

```
Ultimo dia del contexto = MAX( dim_tiempo[fecha] )
Ultimo dia con cosecha  = MAX( h_cosecha[fecha] )
```

Ponlas en dos tarjetas, una al lado de la otra, con el segmentador todavía en 2026.

> ### ✅ Punto de control 8
> | Medida | Valor |
> |---|---|
> | Último día del contexto | **31/12/2026** |
> | Último día con cosecha | **30/04/2026** |
>
> **Ese par de fechas es el hallazgo del día.** Pégalo.

**E5.** En dos líneas: `SAMEPERIODLASTYEAR` movió hacia atrás **365 días**, porque 365 días había en el contexto. **¿Cuántos días tenía que haber movido?** ¿Y cuántos meses de 2026 entraron en el numerador sin haber ocurrido todavía?

### E6. El arreglo, sin tocar una sola fórmula

Agrega un segundo **segmentador** con `dim_tiempo[mes]` y selecciona **1, 2, 3 y 4**. Deja el de `anio` en 2026.

**No escribas ninguna medida nueva. No edites ninguna. Solo mira las tres tarjetas.**

> ### ✅ Punto de control 9
> | Medida | Antes | Después |
> |---|---|---|
> | `[Kilos]` | 30 550 | **30 550** |
> | `[Kilos AA]` | 47 000 | **23 500** |
> | `[Variacion AA]` | **−35,00 %** | **+30,00 %** |
>
> **Pega las seis celdas.** Y deja **las dos tarjetas de variación juntas** en el tablero: van en la captura.
>
> (Para tener las dos a la vez: duplica la página, o pon las dos tarjetas y usa **Formato → Editar interacciones** para que el segmentador de mes no toque la primera.)

**E7.** En dos líneas, y es la pregunta de la clase: `[Variacion AA]` es **la misma medida**, con el mismo texto, sin un carácter cambiado, y dio **−35,00 %** y **+30,00 %**. **¿Cuál de las dos está mal?** Piénsalo antes de contestar.

**E8.** En una línea: `[Kilos]` no se movió cuando pusiste el segmentador de mes, y `[Kilos AA]` sí. **¿Por qué?**

### E9. La columna que baja sola

Vuelve a la matriz de la parte C —**con los dos segmentadores limpios**, o en su página propia— y agrégale **dos** medidas más. Fíjate en que la primera mete `[Kilos YTD]` adentro de `CALCULATE`: es una medida usando otra medida adentro, justo lo que ayer dijimos que era la única razón de escribirlas.

```
Kilos AA YTD  = CALCULATE( [Kilos YTD] , SAMEPERIODLASTYEAR( dim_tiempo[fecha] ) )
Variacion YTD = DIVIDE( [Kilos YTD] - [Kilos AA YTD] , [Kilos AA YTD] )
```

Lee la columna hacia abajo, en las filas de 2026:

> ### ✅ Punto de control 10
> | Mes de corte | `[Kilos YTD]` | `[Kilos AA YTD]` | `[Variacion YTD]` |
> |---|---|---|---|
> | Marzo | 10 800 | 14 000 | **−22,86 %** |
> | **Abril** | **30 550** | **23 500** | **+30,00 %** |
> | Junio | 30 550 | 30 800 | **−0,81 %** |
> | Septiembre | 30 550 | 41 050 | **−25,58 %** |
> | Diciembre | 30 550 | 47 000 | **−35,00 %** |
>
> **Pega las cinco filas.**

**E10.** En dos líneas: la tarjeta de E1 decía −35,00 %, que es **exactamente** la fila de Diciembre de esta tabla. **¿Qué mes está leyendo esa tarjeta, y en qué mes estamos hoy?**

### E11. Y ahora por finca

Quita el segmentador de mes, deja el de `anio` en 2026, y arma una tabla con `dim_finca[finca]`, `[Kilos]`, `[Kilos AA]` y `[Variacion AA]`. Después vuelve a poner el segmentador de meses 1 a 4 y anota la misma tabla otra vez.

> ### ✅ Punto de control 11
> | Finca | Año contra año | A la misma fecha |
> |---|---|---|
> | Hacienda Santa Rosa | **−32,38 %** | **+15,45 %** |
> | Finca El Guayabo | **−17,15 %** | **+54,89 %** |
> | Agricola La Union | **−76,14 %** | **+5,00 %** |
>
> **Pega los seis porcentajes.**

**E12.** En una línea: **las tres fincas cambiaron de signo.** ¿Qué te dice eso sobre si el −35 % era «un caso raro»?

---

## Parte F · Preguntas de cierre (10 min)

1. En una línea: `SAMEPERIODLASTYEAR` hace una sola cosa. **¿Cuál?** (Y con eso se explica todo lo de hoy.)
2. En dos líneas: en E6 arreglaste el número **sin tocar una fórmula**. En la clase 15 dijimos que *una medida no tiene un valor*. **¿Qué tiene que ver una cosa con la otra?**
3. En una línea: el eje de tiempo de un gráfico **siempre** sale de `dim_tiempo` y nunca de `h_cosecha[fecha]`. **¿Por qué?**
4. En dos líneas: hoy el arreglo fue un segmentador de meses **puesto a mano en 1, 2, 3 y 4**. En mayo llegan cosechas nuevas. **¿Qué le pasa a ese tablero, y qué habría que hacer para que no dependa de que alguien se acuerde?**
5. En una línea: el número malo de la clase 14 fue **19 750**; el de la 15, **5 091,67**; el de hoy, **−35,00 %**. Los tres eran aritmética correcta. **¿Qué tenían mal los tres?**

---

## Si algo falla

| Síntoma | Qué pasó | Qué haces |
|---|---|---|
| El total da 30 550 y no 77 550 | cargaste los CSV de la clase 15 | son los de `datos/csv_clase16/` |
| Aparece una fila sin nombre en los visuales | el calendario no cubre 2025 | `dim_tiempo` tiene que tener 730 filas |
| `[Kilos AA]` sale vacío en todos lados | no marcaste la tabla de fechas | Herramientas de tabla → Marcar como tabla de fechas |
| Power BI no deja marcar la tabla de fechas | la columna tiene huecos, repetidos o vacíos | revisa que sean los 730 días completos |
| `[Kilos AA]` sale vacío solo en 2025 | **no es un error**: 2024 no está en el calendario | anótalo y sigue |
| Los meses salen Abril, Agosto, Diciembre… | falta ordenar por columna | `nombre_mes` → Ordenar por columna → `mes` |
| Al ordenar por columna, Power BI se queja | hay más de un `mes` por `nombre_mes` | no debería pasar con estos datos; anótalo |
| La variación sale `-0,35` | falta el formato | Herramientas de medidas → **%** |
| La tarjeta dice «30,55 mil» | unidades de presentación automáticas | Formato → Unidades: **Ninguna**, decimales **2** |
| Un segmentador no afecta a una tarjeta | interacción apagada, o páginas distintas | **Formato → Editar interacciones** |
| Enero y Febrero de 2026 no salen en la matriz | todas sus medidas están vacías | es normal, no lo persigas |
| Los decimales llevan punto y no coma | configuración regional de tu Windows | **no es un error**, anótalo y sigue |

> ### La regla de los 20 minutos sigue vigente
> Veinte minutos atorado en lo mismo: lo escribes en tu archivo empezando con `DUDA`, o abres un *issue*, y sigues con lo siguiente. **Atorarse no baja la nota. Quedarse callado sí.**

---

## Plan B · Si Power BI Desktop no abre en tu máquina

1. Ponte con un compañero: el tablero se arma en una sola máquina.
2. **Tú escribes todas las medidas** en tu propio archivo `.md`, con su resultado, y anotas con quién trabajaste.
3. La captura es la misma para los dos, y los dos lo dicen en un comentario.

**Con el Plan B completo se llega a 100 de 100.** Lo que se califica es el DAX que escribiste y el número que atrapaste, no de quién era la laptop.

---

## Rúbrica (100 puntos)

| Criterio | Pts |
|---|---|
| Parte A: los cuatro CSV, la fecha/hora automática apagada, la tabla de fechas marcada, las tres relaciones y el 77 550 | 10 |
| Parte B: el orden del eje arreglado, los dos gráficos comparados, y B4 y B6 contestadas | 15 |
| Parte C: `Kilos YTD`, las ocho filas de la matriz, y C2 y C3 | 15 |
| Parte D: `Kilos AA`, `Variacion AA`, el +31,71 % y el +107,89 %, y D2 | 20 |
| **Parte E: el −35,00 % provocado, las dos fechas de corte, el +30,00 % sin tocar fórmulas, la columna que baja sola y las tres fincas** | **30** |
| Parte F: las cinco preguntas con criterio | 10 |

Los criterios suman **100** exactos.

> **Lo que más se califica hoy no es que hayas escrito inteligencia de tiempo.** Es la parte E: que hayas visto **la misma medida, sin cambiar un carácter**, dar −35,00 % y +30,00 %, y que sepas explicar cuál de las dos contesta la pregunta que hicieron.
