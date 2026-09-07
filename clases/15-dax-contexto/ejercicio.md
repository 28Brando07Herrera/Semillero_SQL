# Ejercicio práctico 15 · Escribe las medidas, y rompe el promedio a propósito
**Duración: 2 horas · Individual · Sólo Power BI Desktop · Entrega: un archivo `.md` y una captura**

---

## Qué vas a lograr hoy

1. Cargar la estrella de AgroDB en Power BI **desde cuatro CSV**, sin Oracle, sin driver y sin `GRANT`.
2. Escribir tus primeras **medidas** de DAX en vez de arrastrar campos.
3. Ver con tus ojos la diferencia entre una **medida** y una **columna calculada**: una reacciona al segmentador y la otra se quedó congelada al cargar.
4. Entender **contexto de filtro** por la vía dolorosa: un porcentaje que dice 100 % en todas las filas.
5. Provocar, a propósito, el número silencioso del día: un promedio de **5 091,67** que está mal y que **se puede defender en una junta**.
6. Detectarlo con dos medidas de una línea y arreglarlo a **7 637,50**.

**El número que prueba que la carga salió bien sigue siendo 30 550.** El que prueba que entendiste la clase es **7 637,50**.

---

## Antes de empezar

Hoy **no** hace falta nada de lo de las dos clases pasadas:

| | |
|---|---|
| Oracle | **no**, hoy no se prende |
| Docker | **no** |
| El driver OCMT | **no**, los CSV no necesitan driver |
| `bi_agro`, `GRANT`, `sqlplus` | **no** |
| Power BI Desktop | **sí**, y es lo único |

> Si en la clase 13 te quedaste sin conectar porque no pudiste instalar el OCMT: **hoy nada de eso te frena.** Empiezas parejo con todos.

### Descarga los cuatro archivos

Están en [`datos/csv_clase15/`](../../datos/csv_clase15/):

```
dim_finca.csv     3 filas
dim_cultivo.csv   6 filas
dim_tiempo.csv    365 filas
h_cosecha.csv     9 filas
```

En GitHub se abre cada uno y se baja con el botón **Download raw file**.

**Guárdalos en `C:\agrodb\csv\`.** Los cuatro juntos, en esa carpeta y sin renombrarlos. Si los dejas en Descargas te vas a equivocar de archivo a la tercera vez que los cargues.

> Estos cuatro archivos **no se escribieron a mano**: salen del mismo AgroDB de siempre. Son la estrella que construyeron ayer en Oracle, con el calendario ya completo, los 365 días.

---

## Cómo se entrega

En `entregas/apellido-nombre/`, por *pull request*, **dos archivos**:

| Archivo | Qué lleva |
|---|---|
| `Ejercicio15_Apellido_Nombre.md` | **cada medida escrita en un bloque de código**, y debajo el valor que te dio, más las respuestas de la parte F |
| `clase15-tablero.png` | captura del tablero terminado |

> Hoy la entrega es un `.md` y no un `.sql`, porque hoy no escribiste una línea de SQL. Vale la misma regla de siempre: **una medida sin su resultado anotado abajo no cuenta.**

Formato de cada respuesta, para que se pueda corregir:

````
### B1 · Kilos

```
Kilos = SUM(h_cosecha[kg])
```

Resultado: 30550
````

**El `.pbix` no se entrega.** El repositorio ignora los `.pbix` a propósito: pesan y no se pueden revisar en un *pull request*.

---

## Parte A · La estrella, sin Oracle (15 min)

### A1. Carga los cuatro CSV

**Inicio → Obtener datos → Texto/CSV**, uno por uno. Los cuatro.

En la ventana de vista previa, antes de dar **Cargar**, revisa la fila de tipos:

| Tabla | Columna | Tiene que ser |
|---|---|---|
| `h_cosecha` | `kg` | Número entero |
| `h_cosecha` | `fecha` | Fecha |
| `dim_tiempo` | `fecha` | Fecha |

Si `kg` o `fecha` llegaron como **Texto**, entra a **Transformar datos** y cámbiales el tipo ahí. Los CSV vienen con fecha en formato `AAAA-MM-DD` y con los kilos sin decimales, justamente para que esto no pase; pero depende de la configuración regional de tu máquina.

**A2.** En un comentario, una línea: **¿qué tipo llegó mal en tu máquina, si es que llegó alguno?** Si llegaron los tres bien, escríbelo también. Es un dato del curso.

### A3. Las relaciones

Ve a la vista **Modelo**. Power BI intenta adivinar; **revisa las tres a mano**:

| De | A | Cardinalidad | Dirección |
|---|---|---|---|
| `h_cosecha[finca_id]` | `dim_finca[finca_id]` | muchos a uno | simple |
| `h_cosecha[cultivo_id]` | `dim_cultivo[cultivo_id]` | muchos a uno | simple |
| `h_cosecha[fecha]` | `dim_tiempo[fecha]` | muchos a uno | simple |

Las que falten, se arrastran de un campo al otro.

> ### ✅ Punto de control 1
> Las **tres** relaciones, todas **muchos a uno** apuntando hacia la dimensión.
> **Anota en tu archivo cuántas adivinó Power BI solo y cuántas tuviste que dibujar tú.**

---

## Parte B · Tus primeras medidas (15 min)

### B1. `Kilos`

**Inicio → Nueva medida**:

```
Kilos = SUM(h_cosecha[kg])
```

### B2. `Cosechas`

```
Cosechas = COUNTROWS(h_cosecha)
```

### B3. El punto de control de siempre

Inserta una **tabla** (el visual «Tabla», no una matriz) con:

- **Columnas:** `dim_finca[finca]`, `[Kilos]`, `[Cosechas]`

> ### ✅ Punto de control 2
> | Finca | Kilos | Cosechas |
> |---|---|---|
> | Finca El Guayabo | **14 250** | 3 |
> | Hacienda Santa Rosa | **14 200** | 4 |
> | Agricola La Union | **2 100** | 2 |
> | **Total** | **30 550** | **9** |
>
> **Pega la tabla completa en tu archivo.** Si el total no da 30 550, no sigas: revisa la parte A.

**B4.** Fíjate en la columna `Cosechas`: 3 + 4 + 2 = 9, y el total dice 9. Ahora fíjate en `Kilos`: 14 250 + 14 200 + 2 100 = 30 550, y el total dice 30 550. En un comentario, una línea: **¿el total de una tabla es siempre la suma de las filas de arriba?** Contesta ahora y no lo borres: la parte E te va a decir si acertaste.

---

## Parte C · Medida contra columna calculada (20 min)

### C1. Una columna calculada, bien usada

En la tabla `h_cosecha`, **Nueva columna**:

```
tamano = IF( h_cosecha[kg] >= 3000, "grande", "chica" )
```

Esto **sí** es una columna: es un dato de cada cosecha, y sirve para agrupar y filtrar.

Ponla en el eje de un gráfico de barras con `[Kilos]`:

> ### ✅ Punto de control 3
> | tamano | Kilos | Cosechas |
> |---|---|---|
> | grande | **22 500** | 4 |
> | chica | **8 050** | 5 |
> | **Total** | **30 550** | **9** |

### C2. Una columna calculada, mal usada

Ahora, en la misma tabla `h_cosecha`, otra **columna**:

```
pct_columna = h_cosecha[kg] / SUM(h_cosecha[kg])
```

Y al lado, una **medida**:

```
Pct medida = DIVIDE( [Kilos] , CALCULATE( [Kilos] , ALL(h_cosecha) ) )
```

Arma una tabla con `h_cosecha[cosecha_id]`, `[Kilos]`, la **suma** de `pct_columna` y `[Pct medida]`. Dale formato de porcentaje a las dos.

**Sin ningún filtro puesto, las dos columnas dicen exactamente lo mismo.** Anótalo.

### C3. Ahora pon el segmentador

Inserta un **segmentador** con `dim_finca[finca]` y selecciona **Agricola La Union**.

> ### ✅ Punto de control 4
> La tabla se queda con **dos cosechas**: la 8 (1 200 kg) y la 9 (900 kg).
>
> | | `pct_columna` | `[Pct medida]` |
> |---|---|---|
> | cosecha 8 | **3,93 %** | **57,14 %** |
> | cosecha 9 | **2,95 %** | **42,86 %** |
> | **Total** | **6,87 %** | **100,00 %** |
>
> **Pega los seis números.**

**C4.** En dos líneas: la columna siguió dividiendo entre 30 550 y la medida dividió entre 2 100. **¿Por qué?** ¿En qué momento se calculó cada una?

**C5.** En una línea: de las dos, **¿cuál contesta la pregunta «qué parte de esta finca aporta cada cosecha»** y cuál contesta otra pregunta distinta?

---

## Parte D · Contexto de filtro (20 min)

### D1. El porcentaje escrito como sale

Quita el segmentador de la parte C (o deja todo seleccionado) y escribe esta medida **tal cual está**, aunque ya sepas que va a salir mal:

```
Pct mal = DIVIDE( [Kilos] , [Kilos] )
```

Ponla en una tabla junto a `dim_finca[finca]` y `[Kilos]`.

> ### ✅ Punto de control 5
> Las tres fincas dicen **100,00 %**. **Pégalo.**

**D2.** En dos líneas, y sin buscarlo en internet: las dos `[Kilos]` de esa fórmula son idénticas. **¿Por qué el resultado no es un número distinto arriba y abajo?**

### D3. La versión correcta

```
Pct del total = DIVIDE( [Kilos] , CALCULATE( [Kilos] , ALL(dim_finca) ) )
```

> ### ✅ Punto de control 6
> | Finca | Kilos | Pct del total |
> |---|---|---|
> | Finca El Guayabo | 14 250 | **46,64 %** |
> | Hacienda Santa Rosa | 14 200 | **46,48 %** |
> | Agricola La Union | 2 100 | **6,87 %** |
> | **Total** | 30 550 | **100,00 %** |
>
> **Pega la tabla.** Los tres porcentajes con dos decimales.

**D4.** Cambia `ALL(dim_finca)` por `ALL(dim_cultivo)` y mira qué pasa. En una línea: **¿por qué vuelven a dar 100 %?**

(Después regrésala a `ALL(dim_finca)`.)

---

## Parte E · La trampa del día (30 min) — es la parte que más vale

### E1. El promedio, escrito como lo escribiría cualquiera

Llegó la pregunta por correo: **«¿cuántos kilos da en promedio cada cultivo?»**

```
Promedio por cultivo MAL = DIVIDE( [Kilos] , COUNTROWS(dim_cultivo) )
```

Ponla en una **Tarjeta**. Formato → **Unidades de presentación: Ninguna**, **Posiciones decimales: 2**.

> ### ✅ Punto de control 7
> La tarjeta dice **5 091,67**. **Pégalo.**

**E2.** Antes de seguir leyendo, contesta en un comentario: **¿qué mensaje de error dio Power BI?**

(La respuesta es incómoda a propósito.)

**E3.** En un comentario: en la parte B comprobaste que `[Kilos]` da 30 550 y `[Cosechas]` da 9. Nada se perdió. Entonces, **¿de dónde sale el 5 091,67?** Haz la división a mano y escribe los dos números que usó Power BI.

### E4. Saca el denominador a la pantalla

Dos medidas de una línea cada una:

```
Cultivos en la dimension = COUNTROWS(dim_cultivo)
Cultivos con cosecha     = DISTINCTCOUNT(h_cosecha[cultivo_id])
```

Ponlas en dos tarjetas, una al lado de la otra.

> ### ✅ Punto de control 8
> **6** y **4**. **Ese par de números es el hallazgo del día.** Pégalo.

**E5.** En una línea: **¿cuáles son los dos cultivos que sobran en el denominador**, y por qué están en `dim_cultivo` si nunca cosecharon nada?

### E6. La versión correcta

```
Promedio por cultivo = DIVIDE( [Kilos] , DISTINCTCOUNT(h_cosecha[cultivo_id]) )
```

> ### ✅ Punto de control 9
> La tarjeta dice **7 637,50**.
> **Deja las dos tarjetas juntas en el tablero**, la mala y la buena. Van en la captura.

### E7. Y ahora con un segmentador encima

Inserta un segmentador con `dim_cultivo[tipo]` y selecciona **perenne**.

> ### ✅ Punto de control 10
> | Medida | Valor |
> |---|---|
> | `[Kilos]` | **20 750** |
> | Cultivos en la dimensión | **5** |
> | Cultivos con cosecha | **3** |
> | Promedio por cultivo MAL | **4 150,00** |
> | Promedio por cultivo | **6 916,67** |
>
> **Pega los cinco.**

**E8.** En dos líneas: las dos medidas **se movieron** cuando pusiste el segmentador, o sea que las dos respetan el contexto de filtro. **Entonces la mala no está mal por no filtrar. ¿Por qué está mal?**

**E9.** En una línea, y es la pregunta de la clase: ayer les dije que **una dimensión con filas que el hecho no usa está bien**. Hoy esas mismas dos filas rompieron un número. **¿Cuándo deja de estar bien?**

---

## Parte F · Preguntas de cierre (10 min)

1. En una línea: **¿cuál es la diferencia entre una medida y una columna calculada**, dicha en términos de *cuándo* se calcula cada una?
2. En dos líneas: en la parte B4 contestaste si el total de una tabla es siempre la suma de las filas de arriba. Con `[Kilos]` daba lo mismo; con `[Promedio por cultivo]` no. **¿Qué está calculando en realidad la fila del total?**
3. En una línea: `ALL(dim_finca)` no significa «todas las fincas». **¿Qué significa?**
4. Hoy el número malo fue **5 091,67**. En la clase 5 fue un `SUM` inflado por fan-out; en la 6, un `-99` disfrazado de temperatura; en la 8, una vista que no se reemplazó; en la 14, un calendario sin marzo. En una línea: **¿qué tienen todos en común?**
5. En dos líneas: hoy cambiamos la fuente de datos —de Oracle a cuatro CSV— y el tablero salió igual. **¿Qué dice eso del trabajo de la clase 14?** ¿Y qué habría pasado si en vez de la estrella hubiéramos exportado la vista plana `v_bi_produccion`?

---

## Si algo falla

| Síntoma | Qué pasó | Qué haces |
|---|---|---|
| `[Kilos]` da 30 550 en **todas** las filas | falta una relación | vista **Modelo**, dibújala muchos a uno |
| Los kilos salen inflados o duplicados | la relación quedó al revés, o en la columna equivocada | la flecha va **del hecho hacia la dimensión** |
| No encuentro «Nueva medida» | estás en la vista **Modelo** o en la de **Tabla** | vuelve a **Informe**, pestaña **Inicio** |
| La medida aparece con el ícono de columna | la creaste con **Nueva columna** | bórrala y créala con **Nueva medida** |
| `kg` no deja hacer `SUM` | llegó como texto | Power Query → tipo **Número entero** |
| La tarjeta dice «5,09 mil» | unidades de presentación automáticas | Formato → Unidades: **Ninguna**, decimales **2** |
| El porcentaje sale `0,4664` | falta el formato | Herramientas de medidas → **%** |
| Los decimales llevan punto y no coma | es la configuración regional de tu Windows | **no es un error**, anótalo y sigue |
| El segmentador no filtra la tarjeta | están en páginas distintas, o hay una interacción apagada | **Formato → Editar interacciones** |

> ### La regla de los 20 minutos sigue vigente
> Veinte minutos atorado en lo mismo: lo escribes en tu archivo empezando con `DUDA`, o abres un *issue*, y sigues con lo siguiente. **Atorarse no baja la nota. Quedarse callado sí.**

---

## Plan B · Si Power BI Desktop no abre en tu máquina

Hoy no hay driver que instalar ni motor que levantar, así que el único bloqueo posible es que Power BI Desktop no arranque.

1. Ponte con un compañero: el tablero se arma en una sola máquina.
2. **Tú escribes todas las medidas** en tu propio archivo `.md`, con su resultado, y anotas con quién trabajaste.
3. La captura es la misma para los dos, y los dos lo dicen en un comentario.

**Con el Plan B completo se llega a 100 de 100.** Hoy lo que se califica es el DAX que escribiste y el número que atrapaste, no de quién era la laptop.

---

## Rúbrica (100 puntos)

| Criterio | Pts |
|---|---|
| Parte A: los cuatro CSV cargados, los tipos revisados y las tres relaciones | 10 |
| Parte B: `Kilos` y `Cosechas`, la tabla por finca con 30 550, y B4 contestada | 15 |
| Parte C: la columna y la medida, los seis números del segmentador, y C4 y C5 | 15 |
| Parte D: el 100 % provocado, `ALL` aplicado, y los tres porcentajes correctos | 20 |
| **Parte E: el 5 091,67 provocado, el 6 contra 4 detectado, el 7 637,50 y el caso con segmentador** | **30** |
| Parte F: las cinco preguntas con criterio | 10 |

Los criterios suman **100** exactos.

> **Lo que más se califica hoy no es que hayas escrito DAX.** Es la parte E: que hayas visto un promedio equivocarse **sin que nada avisara**, y que sepas cuál es el par de medidas de una línea que lo atrapa.
