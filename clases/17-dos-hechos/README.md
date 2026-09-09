# Clase 17 · La meta que no sabe de cultivos
**Miércoles 9 de septiembre**

**50 minutos de clase** y el resto de práctica. Tercera clase seguida del lado de Power BI: **hoy tampoco se prende Oracle.**

## Material

| Qué | Dónde |
|---|---|
| Diapositivas | [slides.md](slides.md) · [versión web](https://negatix092.github.io/Semillero_SQL/17-dos-hechos.html) |
| Ejercicio práctico | [ejercicio.md](ejercicio.md) |
| Datos del día | [`datos/csv_clase17/`](../../datos/csv_clase17/) — cinco archivos, **cuatro idénticos a los de ayer** y uno nuevo |

> **Al revés que ayer: hoy sí conviene reutilizar el `.pbix` de la clase 16.** Los cuatro CSV no cambiaron ni un byte y las medidas de ayer se usan hoy. Lo único que hay que bajar es `h_meta.csv` y dejarlo junto a los otros cuatro. Quien tenga el archivo de ayer roto, que baje los cinco a `C:\agrodb\csv17\` y rehaga la clase 16 en veinte minutos.

## Qué hace falta tener listo

| | |
|---|---|
| Power BI Desktop | y nada más |
| Oracle, Docker, el OCMT | **no**, hoy tampoco |
| El `.pbix` de la clase 16 | funcionando: `[Kilos]` = 77 550, la tabla de fechas marcada |
| `h_meta.csv` | descargado junto a los otros cuatro |

## De qué se trata

Hasta ayer el modelo tenía **una** tabla de hechos rodeada de dimensiones. Hoy llega la segunda: **`h_meta`**, la meta de kilos que la gerencia fijó para 2026, con **36 filas** —una por finca y por mes— y **47 000 kilos** en total, que es exactamente lo que se cosechó en 2025.

Y trae dos cosas que `h_cosecha` no tiene:

- **Granularidad de mes**, no de día. Se cuelga del calendario diario poniéndole la fecha del **día 1** del mes, que es la forma estándar y tiene su precio.
- **No tiene cultivo.** La meta se fijó por finca, como se fija en la vida real.

La medida del día cruza las dos tablas de hechos por primera vez en el curso:

```
Meta         = SUM( h_meta[kg_meta] )
Cumplimiento = DIVIDE( [Kilos] , [Meta] )
```

Partida por finca funciona: **42,00 %**, **150,95 %**, **142,00 %**, y la columna de la meta suma su propio total. Partida por cultivo —la misma medida, cambiando nada más la dimensión de las filas— la meta dice **24 440 en las seis filas**, Banano y Café aparecen con meta sin haber cosechado un kilo en dos años, y no hay un solo mensaje de error.

## El giro de hoy

En la clase 15 el arreglo fue cambiar una función. En la 16 no se cambió nada: se recortó el contexto. **Hoy el arreglo es enseñarle a la medida a no contestar.**

```
Meta valida = IF(
    ISFILTERED( dim_cultivo[cultivo] ) || ISFILTERED( dim_tiempo[fecha] ),
    BLANK(),
    [Meta]
)
```

La tabla por cultivo queda con **la columna vacía y el total lleno**. Se ve rara, y tiene que verse rara: está diciendo *por finca sí, por cultivo no*.

> Y ahí se cierra la columna que arrastramos desde la clase 5. Once clases diciendo *qué avisó — nada*. **Hoy el aviso aparece, porque lo escribimos nosotros.**

## Lo que hay que saber al terminar

- Que un modelo puede tener **dos tablas de hechos** compartiendo dimensiones, y que **no todas las dimensiones le llegan a las dos**
- Cómo se cuelga un hecho **mensual** de un calendario **diario**, y qué se paga por hacerlo: la meta del mes queda pegada al día 1
- Que una medida cruzada se lee **al nivel al que se capturó el hecho más grueso**, o más arriba, nunca más abajo
- Que una dimensión que no llega **no da error**: devuelve el total en cada fila
- La regla de detección: **si una medida vale lo mismo en todas las filas, esa dimensión no le llega**
- Que la comprobación de «¿suman los porcentajes?» **aprueba** este error, y por eso hay que mirar la columna cruda
- `ISFILTERED` + `BLANK()`: **una medida que no puede contestar tiene que quedarse callada**
- Que el **filtro cruzado bidireccional** parece el arreglo y es lo contrario: borra la evidencia y deja números plausibles

## La idea del día

**Si nada avisa, el aviso lo escribes tú.**

## Las cuatro cosas que son la clase

Si el día se complica y hay que recortar, estas no se recortan:

1. **La relación que falta**, y que no se puede crear: `h_meta` no tiene cultivo.
2. **El 24 440 repetido en las seis filas**, con Banano y Café incluidos, y sin un solo error.
3. **Que los cuatro porcentajes suman 125,00 exacto.** La revisión obvia lo aprueba.
4. **La columna vacía con el total lleno.** El `BLANK()` escrito a mano.

## Los números de control

| Dónde | Qué debe decir |
|---|---|
| `h_meta` | **36 filas**, `SUM(kg_meta)` = **47 000** |
| `[Kilos]` sin filtros / con `anio` = 2026 | **77 550** · **30 550** ← intactos |
| `[Cumplimiento]` sin filtros | **165,00 %** ← dos años contra una meta |
| `[Cumplimiento]` con `anio` = 2026 | **65,00 %** ← el −35,00 % de ayer, al revés |
| `[Cumplimiento]` con `mes` en 1–4 | **125,00 %** ← el único que contesta |
| Por finca, a la misma fecha | La Union **42,00 %** · El Guayabo **150,95 %** · Santa Rosa **142,00 %** |
| Por finca, año completo | **26,25 %** · **75,00 %** · **71,00 %** |
| Por mes de 2026 | marzo **156,52 %** · abril **237,95 %** |
| **Por cultivo: `[Meta]`** | **24 440 en las seis filas y en el total** ← el error del día |
| Por cultivo: `[Cumplimiento]` | Mango **51,96 %** · Guayaba **24,35 %** · Maiz **40,10 %** · Cacao **8,59 %** |
| La suma de esos cuatro | **125,00**, exactamente el total ← por eso pasa las revisiones |
| Si sumas la columna de meta | **146 640** kilos de meta en una empresa que se propuso 47 000 |
| `[Filas de meta]` por cultivo | **12** en las seis filas y **12** en el total, contra **9** cosechas repartidas |
| Marzo por día | la meta, **6 900**, aparece toda el **01/03/2026** |
| **Con `[Meta valida]`** | **columna vacía, total 24 440 y 125,00 %** |

> Banano y Café **siguen sin cosechar un kilo**, igual que en la 15 y en la 16. Lo nuevo es que hoy **aparecen en pantalla**, sostenidos por una meta que no es suya.

## Entrega

En `entregas/apellido-nombre/`, por *pull request*, **dos archivos**:

| Archivo | Qué lleva |
|---|---|
| `Ejercicio17_Apellido_Nombre.md` | cada medida en un bloque de código con **su resultado anotado debajo**, y las respuestas de la parte G |
| `clase17-tablero.png` | captura con **las dos matrices por cultivo juntas**: la de la meta repetida y la de la columna vacía |

> El `.pbix` no se entrega: el repositorio lo ignora a propósito.

## Nota sobre el material

Los números de esta clase —el 47 000 de meta, el 24 440, los tres porcentajes de la misma medida, los seis de las fincas, el 24 440 repetido, la suma de 125,00 y el 146 640— están **verificados contra los CSV publicados** con `docente/clase17_verificacion_docente.py`, que rehace la aritmética de cada medida a partir de los archivos y modela el contexto de filtro de cada visual, incluida la dimensión que no llega. Los CSV, a su vez, se generan con `docente/clase17_generar_csv.py`: los cuatro de ayer se copian byte a byte desde `datos/csv_clase16/` y se les vuelven a comprobar los totales, y la meta se declara ahí, en un solo lugar.

Lo que **ningún script puede verificar** es el comportamiento del motor de DAX y los nombres de menú de Power BI en tu versión y tu idioma. En particular, si `[Cumplimiento]` sale **vacío o 0,00 %** en las filas sin cosecha depende de tu versión: **anota cuál te salió, eso puntúa**, igual que documentar una discrepancia del enunciado.
