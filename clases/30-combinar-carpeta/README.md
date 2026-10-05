# Clase 30 · Todo lo que cae en la carpeta
**Jueves 1 de octubre**

**50 minutos de clase** y el resto de práctica. Cuarta clase seguida **adentro de Power Query**: **hoy tampoco se prende Oracle.**

## Material

| Qué | Dónde |
|---|---|
| Diapositivas | [slides.md](slides.md) · [versión web](https://negatix092.github.io/Semillero_SQL/30-combinar-carpeta.html) |
| Ejercicio práctico | [ejercicio.md](ejercicio.md) |
| Datos del día | [`datos/csv_clase30/`](../../datos/csv_clase30/): tres CSV de la clase 19, **idénticos** (`dim_tiempo`, `dim_finca`, `h_meta`), más la carpeta **`bascula/`**, las cosechas como las manda la báscula: un archivo por mes. **`h_cosecha.csv` no viene**: se construye en clase |

> **Hoy sí se baja algo.** Copia `datos/csv_clase30/` a `C:\agrodb30\` y empieza con un **`.pbix` vacío**, como en la 24 y de la 26 a la 29. Tiene que quedar `C:\agrodb30\bascula\` con 15 archivos.

## Qué hace falta tener listo

| | |
|---|---|
| Power BI Desktop | y nada más |
| Oracle, Docker, el OCMT | **no**, hoy tampoco |
| El `.pbix` de clases anteriores | **no**: hoy se arma uno nuevo, y `h_cosecha` sale de una carpeta |

## De qué se trata

La báscula ya no manda `h_cosecha.csv`. Deja **un archivo por mes** en una carpeta compartida, y el correo dice que son **las mismas cosechas de siempre**: cada mes que pesen, cae uno nuevo.

Anexar catorce consultas a mano, como en la 27, no aguanta el mes que viene. La herramienta es **Combinar archivos** sobre una **carpeta**: Power Query toma un **archivo de ejemplo**, arma con él los pasos para leer uno, se los aplica **a cada archivo de la carpeta** y los pone uno debajo de otro, con una columna nueva, **`Source.Name`**, que dice de qué archivo salió cada fila. Al **Actualizar**, el mes nuevo entra solo.

## El giro de hoy

La carpeta trae lo que trae cualquier carpeta compartida.

Una **copia**: `bascula_2026-04 - copia.csv`. Alguien abrió abril para revisarlo y Windows la dejó. Para Power Query es un mes más: abril entra dos veces, y la tabla de control salta de 30 550 a **50 300** y **205,81 %**. El número viejo lo atrapa, y una tabla por **`Source.Name`** dice de dónde salió. **Quitar duplicados**, el botón de la 28, no quita nada: las filas son iguales en todo menos en `Source.Name`. Se filtra el archivo por su nombre, y `[Cosechas repetidas]` queda en **0**.

Y **un mes que perdió sus kilos**. Julio de 2025 se pesó con la báscula de repuesto, que escribe la columna como **`kg_neto`**. Combinar toma las columnas **del archivo de ejemplo**, que dice `kg`: julio entra con sus **dos cosechas** y los kilos **vacíos**, y sin un solo `Error`. El control de enero–abril dice **125,00 %** y no lo ve nunca, porque julio no está en enero–abril. Lo ven los dos años: **74 700** en vez de 77 550, con 2025 en **44 150**.

El segundo arreglo obvio es el que funcionó el martes: **quitar los `null`**. La calidad de columna se pone en **100 % válido**, el control sigue en 125,00 %, y 2025 se queda en 44 150… con **14** cosechas en vez de 16. El martes el `null` era una fila que no debía existir; hoy es **una cosecha que existe** y a la que se le perdió el número.

El arreglo va en **Transformar archivo de ejemplo**, porque lo que se le hace al ejemplo se le hace a cada archivo: renombrar `kg_neto` a `kg`, con **`MissingField.Ignore`** para los archivos que no lo traen. **77 550** en **25** cosechas, julio en **2 850**.

> La carpeta no estaba mal. **Se leyó entera**, y con las columnas de un solo archivo.

## Lo que hay que saber al terminar

- **Combinar archivos** de una carpeta: el **archivo de ejemplo**, **Transformar archivo de ejemplo**, la función, y **`Source.Name`**
- Que la consulta lee **todo lo que esté en la carpeta**, incluidas las copias
- Por qué **Quitar duplicados** no quita una copia mientras exista `Source.Name`
- Que las columnas salen **del archivo de ejemplo**, y un archivo con otro encabezado entra **vacío**, sin `Error`
- **Vista → Calidad de columna**: un `kg` con **8 %** vacío
- Que quitar los `null` de una columna de datos **borra cosechas**
- `[Cosechas repetidas]` en 0, `[Cosechas sin kilos]` vacía, y la prueba de **todos los años**, no solo la del control

## La idea del día

**Una carpeta se combina con las columnas del primer archivo, y con todos los archivos que caigan en ella.**

## Las cuatro cosas que son la clase

Si el día se complica y hay que recortar, estas no se recortan:

1. **Combinar la carpeta**: **31 filas**, `Source.Name`, y la copia de abril encontrada por su nombre (**50 300** → **30 550**).
2. **Los dos años**: **74 700** y julio con dos cosechas sin kilos, con el control de enero–abril en 125,00 %.
3. **Quitar los `null`**: `kg` al **100 %** válido y 2025 con **14** cosechas.
4. **El arreglo en el archivo de ejemplo**: **77 550** en **25** cosechas, julio en **2 850**.

## Los números de control

Con segmentadores en `anio` = 2026 y `mes` de 1 a 4, salvo donde se dice.

| Dónde | Qué debe decir |
|---|---|
| La meta por finca, antes de las cosechas | La Union **5 000** · El Guayabo **9 440** · Santa Rosa **10 000** · total **24 440** |
| Power Query, la carpeta | **15 archivos**; combinada, **31 filas** y **7 columnas**, la primera `Source.Name` |
| La tabla de control con la copia | La Union **3 000 / 60,00 %** · El Guayabo **28 500 / 301,91 %** · Santa Rosa **18 800 / 188,00 %** · total **50 300 / 24 440 / 205,81 % / 15** |
| Por `Source.Name` | `bascula_2026-03.csv` **10 800 / 3** · las dos de abril **19 750 / 6** cada una |
| Quitar duplicados con `Source.Name` | **31** filas: no quita ninguna |
| Sin la copia | **25 filas**; control **30 550 / 24 440 / 125,00 % / 9**; `[Cosechas repetidas]` **6** → **0** |
| Los dos años, sin segmentadores | 2025 **44 150 / 16** · 2026 **30 550 / 9** · total **74 700 / 25**; julio de 2025 sin kilos y **2** cosechas |
| Calidad de columna de `kg` | **8 %** vacío: las dos filas de `bascula_2025-07.csv` |
| Con los `(null)` quitados | `kg` **100 %** válido; 2025 **44 150 / 14**; total **74 700 / 23**; control 125,00 % |
| Mayo a agosto de 2025, a mano | **4 200 / 3 100 / 2 850 / 5 600** = **15 750**; Power BI con julio vacío, **12 900** |
| Bien | 2025 **47 000 / 16** · total **77 550 / 25** · julio **2 850 / 2** · `[Cosechas sin kilos]` vacía · control **125,00 %** |

## Entrega

En `entregas/apellido-nombre/`, por *pull request*, **tres archivos**:

| Archivo | Qué lleva |
|---|---|
| `Ejercicio30_Apellido_Nombre.md` | cada medida con **su resultado anotado debajo**, las tablas que se piden y las respuestas |
| `clase30-archivos.png` | la tabla por **`Source.Name`** con la copia de abril a la vista |
| `clase30-anios.png` | la tabla de los dos años en **77 550 / 25**, con `[Cosechas repetidas]` en **0** y `[Cosechas sin kilos]` vacía |

> El `.pbix` no se entrega: el repositorio lo ignora a propósito.

## Nota sobre el material

Los números de esta clase —las 31 y 25 filas, la tabla de control con y sin la copia, la tabla por `Source.Name`, los dos años con julio vacío, con los `null` quitados y bien, y la tabla de mayo a agosto— están **verificados contra los archivos publicados en `datos/csv_clase30/`** con `docente/clase30_verificacion_docente.py`, que modela la combinación de la carpeta (cada archivo leído con las columnas del archivo de ejemplo, y `Source.Name`), el filtro de la copia, el de los `null` y el renombrado del ejemplo. Además comprueba que, bien construida, `h_cosecha` es **fila por fila** la `h_cosecha.csv` de la clase 19.

Lo que **ningún script puede verificar** es lo que hace Power Query en tu versión: que el primer archivo sea `bascula_2025-01.csv`, los nombres literales de las consultas de ayuda y del paso `Encabezados promovidos`, que la columna se llame `Source.Name`, y sobre todo que julio entre **vacío** y no con `Error`. Si en tu máquina algo sale distinto, **anótalo en la entrega: eso puntúa**.
