# Ejercicio 22 · AgroDB

## PARTE A - UNA TABLA QUE NO VIENE DE NINGÚN ARCHIVO

**A2. Punto de control 1:**

| Finca | `[Kilos]` | `[Meta]` | `[Cumplimiento]` |
| --- | --- | --- | --- |
| Agricola La Union | 2 100 | 5 000 | 42,00 % |
| Finca El Guayabo | 14 250 | 9 440 | 150,95 % |
| Hacienda Santa Rosa | 14 200 | 10 000 | 142,00 % |
| **Total** | **30 550** | **24 440** | **125,00 %** |

### A3 · La tabla escenario

```dax
escenario = DATATABLE( "nivel" , INTEGER , { { 100 } , { 110 } , { 120 } , { 130 } , { 140 } , { 150 } } )

```

**Punto de control 2:**

* En la vista de tabla, `escenario` tiene 6 filas y una columna, `nivel`: 100, 110, 120, 130, 140 y 150.
* En la vista de modelo, `escenario` no tiene ninguna línea (relación) hacia otra tabla.

**A5.** No le pasó absolutamente nada. La tabla no se mueve ni se filtra porque la tabla `escenario` no tiene ninguna **relación** creada en el modelo hacia `dim_finca` o las tablas de hechos, por lo que su segmentador está desconectado y sus filtros no viajan a ningún lado.

---

## PARTE B - LA MEDIDA PREGUNTA

### B1 · Tres medidas

```dax
Nivel elegido = SELECTEDVALUE( escenario[nivel] , 100 )

Meta ajustada = [Meta] * [Nivel elegido] / 100

Cumplimiento ajustado = DIVIDE( [Kilos] , [Meta ajustada] )

```

**Punto de control 3:**

| Finca | `[Kilos]` | `[Meta ajustada]` | `[Cumplimiento ajustado]` |
| --- | --- | --- | --- |
| Agricola La Union | 2 100 | 6 500 | 32,31 % |
| Finca El Guayabo | 14 250 | 12 272 | 116,12 % |
| Hacienda Santa Rosa | 14 200 | 13 000 | 109,23 % |
| **Total** | **30 550** | **31 772** | **96,15 %** |

**B2. Punto de control 4:**

| Nivel | `[Meta ajustada]` | `[Cumplimiento ajustado]` |
| --- | --- | --- |
| 100 | 24 440 | 125,00 % |
| 110 | 26 884 | 113,64 % |
| 120 | 29 328 | 104,17 % |
| 130 | 31 772 | 96,15 % |
| 140 | 34 216 | 89,29 % |
| 150 | 36 660 | 83,33 % |

**B3.** La empresa cumple (más del 100%) hasta el nivel **120** (104,17 %). La Unión no cumple en ninguno; su máximo es 42,00 % en el nivel base (100).

---

## PARTE C - DOS NIVELES A LA VEZ

**C1. Punto de control 5:**

| Finca | `[Kilos]` | `[Meta ajustada]` | `[Cumplimiento ajustado]` |
| --- | --- | --- | --- |
| Agricola La Union | 2 100 | 5 000 | 42,00 % |
| Finca El Guayabo | 14 250 | 9 440 | 150,95 % |
| Hacienda Santa Rosa | 14 200 | 10 000 | 142,00 % |
| **Total** | **30 550** | **24 440** | **125,00 %** |

**C2.** Ninguno. Power BI procesa la medida y muestra el resultado de 125,00 % de manera completamente silenciosa, sin arrojar errores o advertencias.

**C3.** Ese 125,00 % corresponde exactamente al nivel **100**. No, el nivel 100 no está marcado en el segmentador (están marcados 130 y 150).

**C4. Punto de control 6:**

| Qué hay marcado en el segmentador | `[Nivel elegido]` | Total de `[Cumplimiento ajustado]` |
| --- | --- | --- |
| solo 130 | 130 | 96,15 % |
| 130 y 150 | 100 | 125,00 % |
| nada (borra la selección) | 100 | 125,00 % |

**C5.** El 100 sale del segundo argumento de la función `SELECTEDVALUE( escenario[nivel] , 100 )`. Cuando en el contexto de filtro activo hay más de un valor (en este caso dos: 130 y 150), la función no sabe con cuál quedarse y devuelve automáticamente su valor alternativo (el 100).

**C6.** Porque las pruebas de la parte B se hicieron marcando cuidadosamente de a un solo nivel a la vez, donde `SELECTEDVALUE` se comporta perfectamente. El 125,00 % no se ve raro porque es el porcentaje de cumplimiento real e histórico de la empresa, un número válido y creíble para el negocio.

**C7.** Debió leer **83,33 %** (que es el cumplimiento real al nivel 150). Una simple **Tarjeta** mostrando la medida `[Nivel elegido]` le habría avisado de inmediato que el sistema estaba calculando con el nivel 100 y no con el 150.

---

## PARTE D - LOS SEIS A LA VEZ

**D1. Punto de control 7:**

| Finca | 100 | 110 | 120 | 130 | 140 | 150 | **Total** |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Agricola La Union | 5 000 | 5 500 | 6 000 | 6 500 | 7 000 | 7 500 | **5 000** |
| Finca El Guayabo | 9 440 | 10 384 | 11 328 | 12 272 | 13 216 | 14 160 | **9 440** |
| Hacienda Santa Rosa | 10 000 | 11 000 | 12 000 | 13 000 | 14 000 | 15 000 | **10 000** |
| **Total** | 24 440 | 26 884 | 29 328 | 31 772 | 34 216 | 36 660 | **24 440** |

**D2.** Suma a mano de las columnas de La Unión: 5 000 + 5 500 + 6 000 + 6 500 + 7 000 + 7 500 = **37 500**. La columna Total dice **5 000**.

**D3.** Las columnas individuales tienen un **contexto** de filtro donde solo sobrevive un nivel (por ejemplo, 130), haciendo que la medida calcule bien. La columna Total tiene un contexto que incluye los seis niveles a la vez, por lo que `SELECTEDVALUE` falla y devuelve el 100 por defecto.

**D4.** No la copió. La calculó desde cero en ese cruce específico, multiplicando la meta original por 100 y dividiéndola entre 100, coincidiendo matemáticamente con la primera columna.

---

## PARTE E - QUE DIGA QUE NO SABE

### E1 · Meta y Cumplimiento del escenario

```dax
Meta del escenario = 
IF(
    HASONEVALUE( escenario[nivel] ) ,
    [Meta] * SELECTEDVALUE( escenario[nivel] ) / 100
)

Cumplimiento del escenario = DIVIDE( [Kilos] , [Meta del escenario] )

```

**Punto de control 8:**

| La Unión | Columna 130 | Columna **Total** |
| --- | --- | --- |
| `[Meta ajustada]` | 6 500 | 5 000 |
| `[Meta del escenario]` | 6 500 | *(vacío)* |

**E2. Punto de control 9:**

| Qué hay marcado | Total de `[Meta del escenario]` | Total de `[Cumplimiento del escenario]` |
| --- | --- | --- |
| solo 130 | 31 772 | 96,15 % |
| 130 y 150 | *(vacío)* | *(vacío)* |
| nada | *(vacío)* | *(vacío)* |

**E3.** Con "Selección única" activada (en mi versión de Power BI: Configuración de la segmentación → Selección → Selección única), el segmentador se convierte en botones de radio circulares. Obliga a tener siempre uno marcado, impidiendo marcar dos a la vez o desmarcarlos todos.

**E4.** Sí, la columna Total sigue diciendo 5 000. La selección única no alcanza porque solo restringe el comportamiento del usuario en el objeto visual (segmentador), pero la columna Total de la matriz sigue generando internamente un contexto múltiple que burla el segmentador.

---

## PARTE F - ¿HASTA DÓNDE SE PUEDE SUBIR?

### F1 · Fincas que cumplen

```dax
Fincas que cumplen = COUNTROWS( FILTER( dim_finca , [Cumplimiento del escenario] >= 1 ) )

```

**Punto de control 10:**

| `nivel` | `[Kilos]` | `[Meta del escenario]` | `[Cumplimiento del escenario]` | `[Fincas que cumplen]` |
| --- | --- | --- | --- | --- |
| 100 | 30 550 | 24 440 | 125,00 % | 2 |
| 110 | 30 550 | 26 884 | 113,64 % | 2 |
| 120 | 30 550 | 29 328 | 104,17 % | 2 |
| 130 | 30 550 | 31 772 | 96,15 % | 2 |
| 140 | 30 550 | 34 216 | 89,29 % | 2 |
| 150 | 30 550 | 36 660 | 83,33 % | 1 |
| **Total** | **30 550** |  |  |  |

**F2.** Porque la medida `[Kilos]` está conectada a `h_cosecha`, que no tiene ninguna relación con la tabla desconectada `escenario`. El nivel de escenario no puede filtrar a los kilos de ninguna manera.

**F3.** La que cumple al nivel 150 es **Finca El Guayabo**. Su meta ajustada al 150 es 14 160 kilos, logrando 14 250 kilos, lo que representa un **100,64 %** de cumplimiento.

**F4.** Para la **empresa** como grupo global, se puede subir hasta el **120** (104,17 %). Para las **fincas**, depende: El Guayabo aguanta hasta el 150, Santa Rosa hasta el 140, y La Unión no cumple ni en 100. No es el mismo número porque el total de la empresa promedia a todos, usando el sobrecumplimiento monstruoso del Guayabo para maquillar el desastre de La Unión.

---

## PARTE G - PREGUNTAS DE CIERRE

1. **¿Qué filtra un segmentador desconectado?** Por sí solo, no filtra absolutamente ninguna tabla en el modelo de datos; solo almacena una selección que debe ser leída expresamente mediante DAX.


2. **¿Qué devuelve SELECTEDVALUE?** Devuelve su segundo argumento (el valor alternativo) tanto cuando hay dos o más valores en el contexto, como cuando no hay ninguno marcado.


3. **Regla de detección:** Si al marcar múltiples opciones incompatibles en un simulador (o ninguna), la matriz o tarjeta devuelve un cálculo válido en lugar de vaciarse, la medida está inventando el escenario apoyándose en un valor por defecto.


4. **¿Qué dos pruebas harías?** 1) Marcar dos tipos de cambio simultáneamente para asegurar que el cálculo se vacíe en lugar de inventar un tipo base o promediarlos. 2) Validar que los totales de columna o fila en matrices también queden vacíos o reaccionen correctamente, en lugar de recalcular a un tipo base.


5. **¿Cuándo tiene sentido el alternativo?** Tiene perfecto sentido al diseñar un seleccionador de moneda para el reporte completo, donde el valor alternativo sea la moneda local (ej. 1 para USD), asegurando que si no tocan nada, el informe se dibuje correctamente en la moneda matriz por defecto.