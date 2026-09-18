# Clase 22 · La meta que nadie marcó
**Jueves 17 de septiembre**

**50 minutos de clase** y el resto de práctica. Octava clase seguida del lado de Power BI: **hoy tampoco se prende Oracle.**

## Material

| Qué | Dónde |
|---|---|
| Diapositivas | [slides.md](slides.md) · [versión web](https://negatix092.github.io/Semillero_SQL/22-tablas-desconectadas.html) |
| Ejercicio práctico | [ejercicio.md](ejercicio.md) |
| Datos del día | **ninguno nuevo**: los cinco CSV de la clase 17, los mismos de [`datos/csv_clase19/`](../../datos/csv_clase19/). La tabla nueva se escribe con una fórmula |

> **Hoy no se baja nada.** Se trabaja sobre el `.pbix` de la clase 21, **con Ver como apagado** y **el segmentador `tipo` sin nada marcado**.

## Qué hace falta tener listo

| | |
|---|---|
| Power BI Desktop | y nada más |
| Oracle, Docker, el OCMT | **no**, hoy tampoco |
| El `.pbix` de la clase 21 | con `[Kilos]`, `[Meta]`, `[Cumplimiento]` y las relaciones de `h_meta` con `dim_finca` y `dim_tiempo` |

## De qué se trata

La gerencia pregunta **qué pasa si sube la meta**: al 110, al 120, hasta el 150 %. Esos niveles no están en ningún CSV, así que se escriben a mano en una tabla que **no se relaciona con nada**:

```
escenario = DATATABLE( "nivel" , INTEGER , { { 100 } , { 110 } , { 120 } , { 130 } , { 140 } , { 150 } } )
```

Un segmentador sobre esa tabla **no mueve ningún número**: el filtro viaja por las relaciones, y `escenario` no tiene. Hace falta una medida que **pregunte** qué nivel quedó marcado:

```
Nivel elegido = SELECTEDVALUE( escenario[nivel] , 100 )
Meta ajustada = [Meta] * [Nivel elegido] / 100
```

Funciona: al 130 la meta de la empresa es **31 772** y el cumplimiento baja a **96,15 %**. Se prueba nivel por nivel, y los seis salen bien.

## El giro de hoy

El gerente marca **130 y 150** para compararlos, y la tabla dice **24 440** y **125,00 %**: la meta de siempre. `SELECTEDVALUE` con **dos** valores no escoge ninguno, devuelve **el alternativo**, y el alternativo es 100, **un nivel que nadie marcó**. No hay aviso, y el número es uno que todos conocen, así que se ve bien. Sin nada marcado pasa lo mismo, y por eso la primera prueba —abrir el tablero— no lo atrapa.

Y en la matriz con los seis niveles en columnas vuelve a pasar: cada columna está bien, pero la **columna Total** de La Unión dice **5 000** cuando sus columnas suman **37 500**. Es la clase 21: el total vuelve a hacer la cuenta con los seis niveles, y con seis niveles contesta el alternativo.

El arreglo es enseñarle a la medida a **callarse** cuando no sabe qué nivel usar:

```
Meta del escenario =
IF(
    HASONEVALUE( escenario[nivel] ) ,
    [Meta] * SELECTEDVALUE( escenario[nivel] ) / 100
)
```

Con dos niveles marcados, y en la columna Total, la medida queda **vacía**. La **selección única** en el segmentador ayuda, pero no arregla la matriz: ahí los niveles llegan por las columnas.

> La respuesta a la gerencia: la empresa cumple **hasta el 120** (104,17 %) y cae a **96,15 %** en el 130, pero **dos fincas** aguantan hasta el 140 y **una** hasta el 150. La meta de la empresa no es la de ninguna finca.

## Lo que hay que saber al terminar

- Qué es una **tabla desconectada**, y cómo se escribe una con `DATATABLE`
- Que un segmentador sobre ella **no filtra nada** por sí solo, porque el filtro viaja por las relaciones (clase 18)
- `SELECTEDVALUE( columna , alternativo )`: el valor si queda **uno**, el alternativo si quedan **varios o ninguno**
- Que el alternativo es **una respuesta con buena cara**: si es un valor plausible, el error no se ve
- Que la **columna Total** de una matriz también recibe varios valores, y también contesta con el alternativo (clase 21)
- `IF( HASONEVALUE( … ) , … )` para que la medida **se calle**, como el `BLANK()` de la clase 17
- Que la **selección única** evita marcar dos en el segmentador, pero **no** arregla los totales
- Que `FILTER( dim_finca , … )` recorre fincas **una a la vez**, como `SUMX`, y que `[Kilos]` no cambia de un nivel a otro porque la tabla **sigue desconectada**

## La idea del día

**Un segmentador de una tabla desconectada no filtra nada: la medida pregunta qué quedó marcado, y si le marcan dos, el valor alternativo contesta por ella.**

## Las cuatro cosas que son la clase

Si el día se complica y hay que recortar, estas no se recortan:

1. **El segmentador que no mueve nada**, y `SELECTEDVALUE` leyéndolo: el 96,15 % al 130.
2. **El 125,00 % con 130 y 150 marcados**, y la tarjeta que dice 100.
3. **La columna Total de la matriz**: 5 000 contra 37 500.
4. **`HASONEVALUE`** y la medida que se queda vacía.

## Los números de control

Todos con segmentadores en `anio` = 2026, `mes` en 1–4 y `tipo` **sin nada marcado**.

| Dónde | Qué debe decir |
|---|---|
| La tabla por finca | La Union **2 100 / 5 000 / 42,00 %** · El Guayabo **14 250 / 9 440 / 150,95 %** · Santa Rosa **14 200 / 10 000 / 142,00 %** · total **30 550 / 24 440 / 125,00 %** |
| `escenario` | **6 filas**, sin relaciones |
| Con **130** marcado | `[Meta ajustada]` 6 500 · 12 272 · 13 000 · total **31 772** · `[Cumplimiento ajustado]` 32,31 · 116,12 · 109,23 · total **96,15 %** |
| Total por nivel, de uno en uno | 125,00 % · 113,64 % · 104,17 % · **96,15 %** · 89,29 % · 83,33 % |
| Con **130 y 150** marcados, o sin nada | `[Nivel elegido]` **100** · total **24 440** y **125,00 %** |
| Matriz de `[Meta ajustada]`, La Unión | 5 000 · 5 500 · 6 000 · 6 500 · 7 000 · 7 500 · columna Total **5 000** ← las columnas suman **37 500** |
| Matriz, renglón Total | 24 440 · 26 884 · 29 328 · 31 772 · 34 216 · 36 660 · Total **24 440** |
| `[Meta del escenario]` | las mismas columnas · columna Total **vacía** · con 130 y 150 marcados, **vacía** |
| `[Fincas que cumplen]` por nivel | 2 · 2 · 2 · 2 · 2 · **1** |
| Al 150, El Guayabo | **100,64 %**, la única que cumple |

## Entrega

En `entregas/apellido-nombre/`, por *pull request*, **dos archivos**:

| Archivo | Qué lleva |
|---|---|
| `Ejercicio22_Apellido_Nombre.md` | cada fórmula en un bloque de código con **su resultado anotado debajo**, la suma a mano de la parte D y las respuestas de la parte G |
| `clase22-escenarios.png` | captura de **la matriz** por finca y nivel con `[Meta del escenario]` y la columna Total vacía, junto a **la tabla por nivel** con `[Fincas que cumplen]` |

> El `.pbix` no se entrega: el repositorio lo ignora a propósito.

## Nota sobre el material

Los números de esta clase —el 96,15 % al 130, los seis niveles, el 125,00 % con dos marcados, el 5 000 contra 37 500 de la columna Total y el 2 y el 1 de `[Fincas que cumplen]`— están **verificados contra los CSV publicados en `datos/csv_clase19/`** con `docente/clase22_verificacion_docente.py`, que modela el contexto de cada celda como un conjunto de fincas y de niveles, y lo que devuelven `SELECTEDVALUE` y `HASONEVALUE` en cada uno.

Lo que **ningún script puede verificar** es lo que dibuja Power BI en tu versión: si la medida vacía se ve en blanco, cómo se llaman los menús de la selección única y de los subtotales, y si el segmentador en selección única te deja quitar la marca. Si en tu máquina algo sale distinto, **anótalo en la entrega: eso puntúa**, igual que documentar una discrepancia del enunciado.
