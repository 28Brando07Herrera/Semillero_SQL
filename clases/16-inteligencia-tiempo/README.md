# Clase 16 · Comparar contra el año pasado
**Martes 8 de septiembre**

**50 minutos de clase** y el resto de práctica. Segunda clase seguida del lado de Power BI: **hoy tampoco se prende Oracle.**

## Material

| Qué | Dónde |
|---|---|
| Diapositivas | [slides.md](slides.md) · [versión web](https://negatix092.github.io/Semillero_SQL/16-inteligencia-tiempo.html) |
| Ejercicio práctico | [ejercicio.md](ejercicio.md) |
| Datos del día | [`datos/csv_clase16/`](../../datos/csv_clase16/) — cuatro archivos CSV, **dos de ellos cambiaron** |

> **Los CSV no son los de la clase 15.** `dim_tiempo.csv` pasó de 365 a **730 filas** y `h_cosecha.csv` de 9 a **25**. Los otros dos son idénticos. Que empiecen un `.pbix` nuevo: sale más barato que repuntar rutas.

## Qué hace falta tener listo

| | |
|---|---|
| Power BI Desktop | y nada más |
| Oracle, Docker, el OCMT | **no**, hoy tampoco |
| Los cuatro CSV | descargados a `C:\agrodb\csv16\` — carpeta **nueva** |

## De qué se trata

Ayer escribieron sus primeras medidas y descubrieron que **una medida no tiene un valor: tiene un valor por celda**. Hoy esa idea se cobra en el terreno donde más dinero se pierde por un número mal leído: **la comparación contra el año pasado.**

Llega el histórico —la campaña **2025** completa, 16 cosechas— y con él la primera tabla de hechos del curso que cubre **dos años**. El calendario pasa a 730 días, y `dim_tiempo` por fin hace el trabajo para el que se construyó en la clase 14.

Con eso ya se puede escribir la medida más pedida del mundo:

```
Kilos AA     = CALCULATE( [Kilos] , SAMEPERIODLASTYEAR( dim_tiempo[fecha] ) )
Variacion AA = DIVIDE( [Kilos] - [Kilos AA] , [Kilos AA] )
```

Está bien escrita. No tiene un error de sintaxis ni de lógica. Y la tarjeta dice **−35,00 %**: *«la cosecha cayó 35 % contra el año pasado.»*

**Estamos en septiembre y 2026 tiene cosechas hasta el 30 de abril.** Se comparó cuatro meses contra doce.

## El giro de hoy

En la clase 15 el arreglo fue cambiar una función: `COUNTROWS` por `DISTINCTCOUNT`. **Hoy no se cambia nada.**

El mismo `[Variacion AA]`, con el mismo texto, sin un carácter distinto, dice **−35,00 %** con el segmentador de año en 2026 y **+30,00 %** cuando además se recortan los meses 1 a 4. Sesenta y cinco puntos de diferencia y el signo cambiado, **sin editar una fórmula**.

> Eso es lo de ayer llevado hasta el final: *una medida no tiene un valor.* La medida nunca estuvo mal. Estaba contestando bien **una pregunta que nadie hizo**.

## Lo que hay que saber al terminar

- Que un calendario se dimensiona **por el hecho**, no por el año en curso, y que un calendario corto no da error: manda las filas sobrantes a una fila en blanco
- **Marcar como tabla de fechas**, y por qué se apaga la fecha/hora automática
- **Ordenar por columna**: que `nombre_mes` es texto y que Abril va antes que Marzo hasta que alguien lo arregla
- Que el eje de tiempo sale **siempre** de `dim_tiempo` y nunca de la fecha del hecho, porque el eje del hecho **esconde los meses vacíos**
- `TOTALYTD`: qué acumula y por qué no se cae a cero en un mes sin cosecha
- `SAMEPERIODLASTYEAR`, que hace **una sola cosa**: mover el contexto un año atrás, ni un día más ni uno menos
- Que el año en curso **se diluye solo**, un mes cada mes, sin que nadie toque el tablero
- Sacar las **dos fechas de corte** a la pantalla: `MAX(dim_tiempo[fecha])` contra `MAX(h_cosecha[fecha])`
- Que el arreglo de un número puede ser **el contexto y no la fórmula**

## La idea del día

**El año en curso siempre va perdiendo, y no es culpa del campo.**

## Las cuatro cosas que son la clase

Si el día se complica y hay que recortar, estas no se recortan:

1. **`SAMEPERIODLASTYEAR` mueve lo que hay en el contexto.** 365 días entran, 365 días salen.
2. **El −35,00 %**, y que no dio un solo mensaje de error.
3. **31/12/2026 contra 30/04/2026.** Las dos fechas de corte, que son el «6 contra 4» de ayer con otra ropa.
4. **El +30,00 % sin tocar una fórmula.** La misma medida, otro contexto, otro número, y las dos veces bien.

## Los números de control

| Dónde | Qué debe decir |
|---|---|
| `[Kilos]` sin filtros | **77 550** en **25** cosechas |
| `[Kilos]` con `anio = 2026` | **30 550** ← el de siempre, intacto |
| `[Kilos]` con `anio = 2025` | **47 000** |
| `[Kilos YTD]` en Abril 2026 | **30 550** |
| `[Kilos YTD]` en Abril 2025 | **23 500** ← el número del día |
| `[Kilos AA]` en Marzo 2026 / Abril 2026 | **8 200** · **9 500** |
| `[Variacion AA]` en Marzo 2026 / Abril 2026 | **+31,71 %** · **+107,89 %** |
| **Tarjeta con `anio = 2026`** | **−35,00 %** ← el error del día |
| Últimas fechas: contexto / con cosecha | **31/12/2026** y **30/04/2026** |
| **La misma tarjeta con `mes` en 1–4** | **+30,00 %** |

Y la columna que baja sola, `[Variacion YTD]` mes a mes en 2026:
Marzo **−22,86 %** · Abril **+30,00 %** · Junio **−0,81 %** · Septiembre **−25,58 %** · Diciembre **−35,00 %**.

Por finca, año contra año y a la misma fecha: Hacienda Santa Rosa **−32,38 % → +15,45 %** · Finca El Guayabo **−17,15 % → +54,89 %** · Agricola La Union **−76,14 % → +5,00 %**. **Las tres cambian de signo.**

> Banano y Café **siguen sin cosechar un kilo**, en 2025 tampoco. El hallazgo de la clase 15 —seis cultivos en la dimensión contra cuatro con cosecha— sigue siendo cierto hoy.

## Entrega

En `entregas/apellido-nombre/`, por *pull request*, **dos archivos**:

| Archivo | Qué lleva |
|---|---|
| `Ejercicio16_Apellido_Nombre.md` | cada medida en un bloque de código con **su resultado anotado debajo**, y las respuestas de la parte F |
| `clase16-tablero.png` | captura del tablero, con **las dos tarjetas de variación juntas**: −35,00 % y +30,00 % |

> El `.pbix` no se entrega: el repositorio lo ignora a propósito.

## Nota sobre el material

Los números de esta clase —el 77 550, el 47 000, el 23 500, los acumulados mes a mes, el −35,00 %, el +30,00 %, la columna que baja sola y las tres fincas— están **verificados contra los CSV publicados** con `docente/clase16_verificacion_docente.py`, que rehace la aritmética de cada medida a partir de los archivos, no de una copia a mano. Los CSV, a su vez, se generan desde `datos/agrodb_oracle_clase14.sql` más el histórico declarado en `docente/clase16_generar_csv.py`.

Lo que **ningún script puede verificar** es el comportamiento del motor de DAX y los nombres de menú de Power BI en tu versión y tu idioma. Si en tu máquina algo se llama distinto, o si un decimal sale con punto en vez de coma, **anótalo en la entrega: eso puntúa**, igual que documentar una discrepancia del enunciado.
