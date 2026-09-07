# Clase 15 · La medida y el contexto
**Viernes 4 de septiembre**

**50 minutos de clase** y el resto de práctica. Es la primera clase que vive entera del lado de Power BI: **hoy no se prende Oracle.**

## Material

| Qué | Dónde |
|---|---|
| Diapositivas | [slides.md](slides.md) · [versión web](https://negatix092.github.io/Semillero_SQL/15-dax-contexto.html) |
| Ejercicio práctico | [ejercicio.md](ejercicio.md) |
| Datos del día | [`datos/csv_clase15/`](../../datos/csv_clase15/) — cuatro archivos CSV |

> **Hoy no hay script `.sql`.** Por primera vez en quince clases, el material del día no es SQL: son cuatro archivos de texto que Power BI lee sin driver, sin contenedor y sin `GRANT`.

## Qué hace falta tener listo

| | |
|---|---|
| Power BI Desktop | y nada más |
| Oracle, Docker, el OCMT | **no**, hoy no se usan |
| Los cuatro CSV | descargados a `C:\agrodb\csv\` |

> **El que no pudo instalar el driver en la clase 13 empieza hoy parejo con todos.** Los CSV no necesitan proveedor de datos.

## De qué se trata

Ayer construyeron la estrella en Oracle y Power BI leyó cuatro tablas relacionadas. Pero todo lo que hicieron del lado del tablero fue **arrastrar campos**: `finca` al eje, `kg` a los valores, y Power BI escribió el DAX por ustedes.

Hoy lo escriben ustedes. Y con la primera fórmula que no sea un `SUM` aparece la idea que sostiene toda la herramienta:

**Una medida no tiene un valor. Tiene un valor por celda.**

El conjunto de filtros que aplica en el momento de evaluar se llama **contexto de filtro**, y es lo único que hay que mirar cuando un número del tablero no cuadra.

## Por qué hoy la fuente es un CSV y no Oracle

No es una concesión, y conviene decirlo en voz alta el primer minuto:

1. **Dos clases seguidas peleando con el motor son suficientes.** El tema de hoy es DAX, y no aguanta compartir la hora con un `ORA-12541`.
2. **Cambiar la fuente y que el tablero no se entere es la prueba de que el modelo estaba bien hecho.** El mismo modelo, la misma estrella, los mismos 30 550 kilos, con los datos llegando por otro lado.
3. **Nadie queda fuera.** El OCMT pedía administrador y no todos pudieron. Un CSV no pide nada.

Los cuatro archivos no se escribieron a mano: se generan desde `datos/agrodb_oracle_clase14.sql` con `docente/clase15_generar_csv.py`, así que son el mismo AgroDB de la clase 5, con el calendario ya completo.

## Las dos palabras del día

| | **Medida** | **Columna calculada** |
|---|---|---|
| Cuándo se calcula | al dibujar cada celda | al cargar o actualizar |
| Qué ve | un conjunto de filas | una fila |
| Reacciona al segmentador | **sí** | **no** |
| Ocupa espacio | no | sí |
| Va en un eje | no | sí |

Regla práctica, y es la misma de ayer con otras palabras: **si el resultado tiene sentido sumarlo, es una medida. Si tiene sentido agruparlo o filtrarlo, es una columna.**

## Lo que hay que saber al terminar

- Que arrastrar un campo **ya era DAX**, y qué es una **medida implícita**
- Escribir una medida explícita, y por qué se escribe aunque arrastrar funcione
- La diferencia entre **medida** y **columna calculada**, dicha en términos de *cuándo* se calcula cada una
- Qué es el **contexto de filtro**, y por qué el total de una tabla no es la suma de las filas de arriba
- Qué hace `CALCULATE`, y que `ALL` no significa «todo» sino **«quita ese filtro»**
- Por qué `DIVIDE` y no `/`
- Que un promedio es una división, y que **el denominador no se ve en la tarjeta**
- Sacar el denominador a la pantalla como medida propia: `COUNTROWS` contra `DISTINCTCOUNT`
- Que cambiar la fuente de datos sin tocar el tablero **es un resultado del modelo**, no una casualidad

## La idea del día

**Una medida mal escrita no da error. Da un número que se puede defender.**

## Las cuatro cosas que son la clase

Si el día se complica y hay que recortar, estas no se recortan:

1. **Medida contra columna calculada.** Cuándo se calcula cada una. Todo lo demás sale de ahí.
2. **Contexto de filtro.** Que la misma medida da cuatro resultados en una tabla de cuatro renglones.
3. **El 5 091,67.** Ver un promedio equivocarse sin un solo mensaje de error, y que además suene bien.
4. **El 6 contra el 4.** Las dos medidas de una línea que lo atrapan.

## Los números de control

| Dónde | Qué debe decir |
|---|---|
| `[Kilos]` | **30 550** |
| Por finca | 14 250 · 14 200 · 2 100 |
| `[Cosechas]` | 9 |
| % del total, con `ALL(dim_finca)` | 46,64 % · 46,48 % · 6,87 % |
| Promedio por cultivo, denominador `COUNTROWS(dim_cultivo)` | **5 091,67** ← el error del día |
| Cultivos en la dimensión / con cosecha | **6** y **4** |
| Promedio por cultivo, denominador `DISTINCTCOUNT` | **7 637,50** |

Y con el segmentador en `tipo = perenne`: `[Kilos]` **20 750**, denominadores **5** y **3**, promedios **4 150,00** y **6 916,67**.

> Los dos cultivos que sobran en el denominador son **Banano y Café**: están en `dim_cultivo` desde la clase 5 y nunca cosecharon un kilo. Ayer eso estaba bien. Hoy rompió un número.

## Entrega

En `entregas/apellido-nombre/`, por *pull request*, **dos archivos**:

| Archivo | Qué lleva |
|---|---|
| `Ejercicio15_Apellido_Nombre.md` | cada medida en un bloque de código con **su resultado anotado debajo**, y las respuestas de la parte F |
| `clase15-tablero.png` | captura del tablero terminado, con **las dos tarjetas juntas**: 5 091,67 y 7 637,50 |

> Hoy la entrega es un `.md` y no un `.sql`, porque hoy no se escribe una línea de SQL. **El `.pbix` no se entrega**: el repositorio lo ignora a propósito, porque pesa y no se puede revisar en un *pull request*.

## Nota sobre el material

Los números de esta clase —30 550, el desglose por finca, los 22 500 / 8 050 de la parte C, los porcentajes, el 5 091,67, el 6 contra 4, el 7 637,50 y el caso con `tipo = perenne`— están **verificados contra los CSV publicados** con `docente/clase15_verificacion_docente.py`, que rehace la aritmética de cada medida a partir de los archivos, no de una copia a mano.

Lo que **ningún script puede verificar** es el comportamiento del motor de DAX y los nombres de menú de Power BI en tu versión y tu idioma. Si en tu máquina algo se llama distinto, o si un decimal sale con punto en vez de coma, **anótalo en la entrega: eso puntúa**, igual que documentar una discrepancia del enunciado.
