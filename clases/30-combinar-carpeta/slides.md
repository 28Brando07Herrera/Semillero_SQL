---
marp: true
paginate: true
theme: default
title: "Clase 30 · Todo lo que cae en la carpeta"
style: |
  section { font-family: system-ui, -apple-system, "Segoe UI", sans-serif; font-size: 26px; background: #fbfbfa; color: #1f2933; padding: 60px 70px; }
  section.lead { background: #16324f; color: #f4f7fa; }
  section.lead h1 { color: #ffffff; font-size: 54px; line-height: 1.1; }
  section.lead h2 { color: #7fb3d5; font-weight: 400; font-size: 30px; }
  h1 { color: #16324f; font-size: 40px; border-bottom: 3px solid #f2a104; padding-bottom: 10px; }
  h2 { color: #1c7293; font-size: 32px; }
  strong { color: #b3541e; }
  code { background: #eef2f6; padding: 1px 6px; border-radius: 4px; }
  pre { background: #16324f; border-radius: 8px; font-size: 20px; }
  pre code { background: transparent; color: #e8eef4; }
  table { font-size: 23px; }
  th { background: #16324f; color: #fff; }
  blockquote { border-left: 5px solid #f2a104; color: #4a5568; font-style: normal; }
  footer { color: #8a99a8; font-size: 16px; }
  .verde { background: #1E8449; color: #fff; padding: 2px 10px; border-radius: 4px; }
  .rojo { background: #C0392B; color: #fff; padding: 2px 10px; border-radius: 4px; }
footer: "Curso de SQL · AgroDB · Clase 30"
---

<!-- _class: lead -->

# Todo lo que cae en la carpeta

## Combinar los archivos de una carpeta en Power Query: una copia que se sumó y un mes que perdió sus kilos

Clase 30 · 1 de octubre

---

# Lo que llega hoy

La báscula ya no manda `h_cosecha.csv`. Deja **un archivo por mes** en una carpeta compartida:

| Nombre | Filas |
|---|---|
| `bascula_2025-01.csv` | 1 |
| `bascula_2025-02.csv` | 1 |
| … | … |
| `bascula_2025-12.csv` | 1 |
| `bascula_2026-03.csv` | 3 |
| `bascula_2026-04 - copia.csv` | 6 |
| `bascula_2026-04.csv` | 6 |

> *«Son **las mismas cosechas de siempre**, un archivo por mes. Cada mes que pesemos, cae uno nuevo en la carpeta.»*

---

# Un archivo por mes contra una carpeta

| | Anexar consultas (clase 27) | **Combinar una carpeta** |
|---|---|---|
| Cuántas consultas | una por archivo: **14** | **una** |
| Llega mayo de 2026 | otra consulta y otro anexar, a mano | **Actualizar**, y entra solo |
| Qué se carga | los archivos que elegiste | **todo lo que esté en la carpeta** |
| Las columnas salen de | cada consulta | **el archivo de ejemplo** |

<br>

> Las dos últimas filas son la clase. Guárdalas.

---

# El modelo de hoy

Un `.pbix` nuevo con tres CSV de `datos/csv_clase30/`: `dim_tiempo`, `dim_finca` y `h_meta`, y sus dos relaciones.

```
Meta = SUM( h_meta[kg_meta] )
```

`h_cosecha` no está entre los CSV: hoy **sale de la carpeta**. Si son las mismas cosechas, la tabla de control tiene que volver a decir:

| Finca | `[Kilos]` | `[Meta]` | `[Cumplimiento]` | `[Cosechas]` |
|---|---|---|---|---|
| Agricola La Union | 2 100 | 5 000 | 42,00 % | 2 |
| Finca El Guayabo | 14 250 | 9 440 | 150,95 % | 3 |
| Hacienda Santa Rosa | 14 200 | 10 000 | 142,00 % | 4 |
| **Total** | **30 550** | **24 440** | **125,00 %** | **9** |

Y los dos años, sin segmentadores: **77 550** en **25** cosechas, 47 000 de 2025.

---

# Combinar archivos

**Obtener datos → Carpeta** → `C:\agrodb30\bascula` → **Combinar → Combinar y transformar datos** → **Archivo de ejemplo: Primer archivo** → **Aceptar**.

Power Query arma **cuatro** cosas en una carpeta aparte:

| Qué | Para qué |
|---|---|
| **Archivo de ejemplo** | el primer archivo de la carpeta: `bascula_2025-01.csv` |
| **Transformar archivo de ejemplo** | los pasos que se le aplican **a cada archivo** |
| **Transformar archivo** | esos pasos, como función |
| el parámetro | por dónde entra cada archivo |

Y la consulta `bascula`, con una columna nueva al principio: **`Source.Name`**, el archivo de donde salió cada fila. Abajo a la izquierda: **31 filas**.

---

# La tabla de control

La consulta se renombra **`h_cosecha`**. **Cerrar y aplicar**, las relaciones con `dim_finca` y `dim_tiempo`, y:

```
Kilos = SUM( h_cosecha[kg] )
```

```
Cosechas = COUNTROWS( h_cosecha )
```

```
Cumplimiento = DIVIDE( [Kilos] , [Meta] )
```

| Finca | `[Kilos]` | `[Meta]` | `[Cumplimiento]` | `[Cosechas]` |
|---|---|---|---|---|
| Agricola La Union | <span class="rojo">3 000</span> | 5 000 | <span class="rojo">60,00 %</span> | 3 |
| Finca El Guayabo | <span class="rojo">28 500</span> | 9 440 | <span class="rojo">301,91 %</span> | 6 |
| Hacienda Santa Rosa | <span class="rojo">18 800</span> | 10 000 | <span class="rojo">188,00 %</span> | 6 |
| **Total** | <span class="rojo">**50 300**</span> | **24 440** | <span class="rojo">**205,81 %**</span> | **15** |

---

# ¿De qué archivo viene?

El número viejo lo atrapó: **30 550** contra **50 300**. Una tabla con `h_cosecha[Source.Name]`, `[Kilos]` y `[Cosechas]`, con los mismos segmentadores:

| `Source.Name` | `[Kilos]` | `[Cosechas]` |
|---|---|---|
| `bascula_2026-03.csv` | 10 800 | 3 |
| <span class="rojo">`bascula_2026-04 - copia.csv`</span> | **19 750** | **6** |
| `bascula_2026-04.csv` | 19 750 | 6 |
| **Total** | **50 300** | **15** |

<br>

Alguien abrió abril para revisarlo y Windows dejó **la copia**. Para Power Query, **un mes más**.

> `Source.Name` no se borra: es **la etiqueta de origen** de cada fila.

---

# Quitar duplicados no quita nada

La clase 28 dejó el botón a la mano. En Power Query, `h_cosecha` → **Ctrl + A** → clic derecho → **Quitar duplicados**:

| | Filas |
|---|---|
| Antes | 31 |
| Después | **31** |

<br>

Las seis filas de abril son iguales en todo… **menos en `Source.Name`**. Para Power Query no hay ni un duplicado.

> Y aunque quitaras `Source.Name` y entonces sí funcionara, **el problema no son las filas: es el archivo**. Borra ese paso.

---

# El arreglo: filtrar el archivo

En `h_cosecha`, filtro de **`Source.Name`** → **Filtros de texto → No contiene** → `copia` → **Aceptar**. **25 filas**.

Y una prueba que tiene que dar **cero**, siempre:

```
Cosechas repetidas = [Cosechas] - DISTINCTCOUNT( h_cosecha[cosecha_id] )
```

| | `[Cosechas repetidas]` | Control |
|---|---|---|
| Con la copia | <span class="rojo">**6**</span> | 50 300 / 205,81 % |
| Sin ella | **0** | **30 550 / 24 440 / 125,00 % / 9** <span class="verde">✓</span> |

> Cada cosecha se pesa **una vez**. Si `cosecha_id` se repite, entró un archivo de más.

---

# Los dos años

El control de enero–abril ya está bien. Quita los dos segmentadores. Tabla con `dim_tiempo[anio]`, `[Kilos]` y `[Cosechas]`:

| Año | `[Kilos]` | `[Cosechas]` | Era |
|---|---|---|---|
| 2025 | <span class="rojo">**44 150**</span> | 16 | 47 000 |
| 2026 | 30 550 | 9 | 30 550 |
| **Total** | <span class="rojo">**74 700**</span> | **25** | 77 550 |

<br>

Las **25** cosechas están. Faltan **2 850 kilos**. Por mes, 2025:

| Mes | Junio | **Julio** | Agosto |
|---|---|---|---|
| `[Kilos]` | 3 100 | <span class="rojo">*(vacío)*</span> | 5 600 |
| `[Cosechas]` | 1 | **2** | 1 |

---

# Julio sin kilos

**Transformar datos** → `h_cosecha` → **Vista → Calidad de columna**: `kg` con **8 % vacío**. Son 2 de 25.

Filtro de `kg` → solo **`(null)`**:

| `Source.Name` | `cosecha_id` | `fecha` | `kg` |
|---|---|---|---|
| `bascula_2025-07.csv` | 19 | 08/07/2025 | **null** |
| `bascula_2025-07.csv` | 20 | 25/07/2025 | **null** |

Y en el Bloc de notas, `bascula_2025-07.csv`:

```
cosecha_id,finca_id,cultivo_id,fecha,calidad,kg_neto
```

Julio se pesó con la **báscula de repuesto**, que escribe **`kg_neto`**. Combinar tomó las columnas **del archivo de ejemplo**, que dice `kg`. En julio, `kg` no existe: **vacío**. Y `kg_neto` no se expandió. **Ni un `Error`.**

---

# El segundo arreglo obvio

El martes, en la 29, el arreglo fue **quitar los `(null)`** de `finca_id`, y quedó perfecto. Hoy, lo mismo: filtro de `kg` → desmarca **`(null)`**.

| | |
|---|---|
| **Calidad de columna** de `kg` | **100 % válido** <span class="verde">✓</span> |
| Julio en la tabla por mes | ya no sale vacío <span class="verde">✓</span> |
| Control de enero–abril | **30 550 / 125,00 %** <span class="verde">✓</span> |

<br>

Y la tabla de los dos años: 2025 sigue en <span class="rojo">**44 150**</span>, ahora con <span class="rojo">**14**</span> cosechas. Total **74 700** en **23**.

> El martes el `null` era **una fila que no debía existir**. Hoy era **una cosecha que existe** y a la que se le perdió el número. Quitarla no regresa los kilos: **borra las cosechas**.

---

# La prueba de la cosecha sin kilos

Una medida que tiene que estar **vacía**, siempre:

```
Cosechas sin kilos = COUNTROWS( FILTER( h_cosecha , ISBLANK( h_cosecha[kg] ) ) )
```

| | `[Cosechas sin kilos]` | `[Cosechas]`, los dos años |
|---|---|---|
| Sin arreglar | <span class="rojo">**2**</span> | 25 |
| Con los `(null)` quitados | vacía | <span class="rojo">**23**</span> |
| Bien | vacía | **25** |

<br>

> Las dos pruebas juntas: **cero cosechas sin kilos** y **25 cosechas**. Quitar los `null` pasa la primera y truena la segunda.

---

# El arreglo: en el archivo de ejemplo

Borra el filtro de `(null)`. Abre **Transformar archivo de ejemplo** → clic en **fx** junto a la barra de fórmulas. Dice `= #"Encabezados promovidos"`. Cámbiala por:

```
= Table.RenameColumns( #"Encabezados promovidos" , {{"kg_neto", "kg"}} , MissingField.Ignore )
```

Lo que se le hace al ejemplo, **se le hace a cada archivo**. `MissingField.Ignore`: si el archivo no trae `kg_neto`, no pasa nada.

| Año | `[Kilos]` | `[Cosechas]` |
|---|---|---|
| 2025 | <span class="verde">**47 000**</span> | 16 |
| 2026 | 30 550 | 9 |
| **Total** | <span class="verde">**77 550**</span> | **25** |

Julio **2 850**, `kg` **0 % vacío**, `[Cosechas sin kilos]` **vacía**, y el control en **125,00 %**.

---

# La prueba de cada carpeta

| Qué revisas | Qué atrapa |
|---|---|
| **`Source.Name`** en una tabla, con `[Cosechas]` | el archivo que no es de un mes (la copia) |
| **`[Cosechas repetidas]`** en 0 | cualquier archivo que entre dos veces |
| **Calidad de columna** de cada columna de datos: **0 % vacío** | el archivo con otro encabezado |
| **`[Cosechas sin kilos]`** vacía | lo mismo, en el tablero |
| el **número viejo de todos los años**, no solo el del control | julio: el control de enero–abril nunca lo vio |
| **filas = cosechas**: **25** | el arreglo que borró lo que no entendía |

<br>

> El control de enero–abril pasó **dos veces** con julio roto: julio no estaba en enero–abril.

---

# Los errores que van a ver hoy

| Síntoma | Qué pasó | Arreglo |
|---|---|---|
| no aparece **Carpeta** en Obtener datos | está en **Más…** | **Obtener datos → Más… → Carpeta** |
| una consulta por archivo, sin `Source.Name` | usaste **Cargar** o **Transformar datos** en vez de **Combinar** | borra y usa **Combinar → Combinar y transformar datos** |
| **31 filas** y **50 300** | la copia de abril | filtra `Source.Name` **No contiene** `copia` |
| **Quitar duplicados** no quitó nada | `Source.Name` es distinto en cada archivo | borra el paso; el arreglo es el archivo |
| **74 700** y julio vacío | `kg_neto` en julio | **Transformar archivo de ejemplo** → el paso de renombrar |
| el renombrar da **Error** en todos los meses | faltó **`MissingField.Ignore`** | agrégalo como tercer argumento |
| sigue en **74 700** después del arreglo | lo escribiste en `h_cosecha`, no en el **ejemplo** | el paso va en **Transformar archivo de ejemplo** |
| **23 cosechas** | quitaste los `(null)` de `kg` | borra ese filtro |

---

<!-- _class: lead -->

# La idea del día

## Una carpeta se combina con las columnas del primer archivo, y con todos los archivos que caigan en ella.

<br>

La copia de abril entró como un mes más y el control saltó a **50 300**: se filtró por **`Source.Name`**, y `[Cosechas repetidas]` quedó en **0**. Julio traía **`kg_neto`**: entró con los kilos vacíos, sin un `Error`, y el control de enero–abril **ni lo vio**. Quitar los `null`, como el martes, borró **dos cosechas**. Renombrando en el **archivo de ejemplo**: **77 550** en **25** cosechas.

<br>

**Práctica:** combina la carpeta, encuentra la copia por su nombre, revisa los dos años, cae en el filtro de los `null` y arregla julio donde se arreglan todos los archivos.

**Y la tabla de control tiene que decir 125,00 % con 30 550, y los dos años 77 550 en 25 cosechas, con `[Cosechas sin kilos]` vacía.**
