# Ejercicio 20 · AgroDB

## PARTE A - LA TABLA DE SIEMPRE

**A2. Punto de control 1:**[cite: 9]
| Cultivo | `[Kilos]` | `[Cosechas]` |
|---|---|---|
| Mango | 12 700 | 3 |
| Maiz | 9 800 | 1 |
| Guayaba | 5 950 | 3 |
| Cacao | 2 100 | 2 |
| **Total** | **30 550** | **9** |

**A3.** No salen porque no tienen ningún registro de cosecha en la tabla de hechos. Al devolver un valor en blanco (BLANK), el objeto visual matriz oculta automáticamente esas filas[cite: 9].

**A4.** Aunque la tabla ya ordene visualmente los elementos, la medida de ranking es indispensable para aislar, filtrar (como en un Top N) o utilizar esa posición matemática dentro de otros cálculos o lógicas condicionales[cite: 9].

---

## PARTE B - TODOS EN PRIMER LUGAR

### B1 · Ranking (primera versión)
```dax
Ranking = RANKX( dim_cultivo , [Kilos] )


Resultado: Mango 1 · Maiz 1 · Guayaba 1 · Cacao 1 · Total 1

**B2.** Ninguno. Power BI procesa la fórmula porque la sintaxis de DAX es perfectamente correcta, aunque el resultado lógico de negocio no lo sea.

**B3.** Tiene exactamente **una sola fila**. Por el **contexto de filtro** de la matriz, cuando `RANKX` intenta evaluar, la tabla `dim_cultivo` ya está filtrada exclusivamente a "Mango", por lo que compite contra sí mismo y queda en primer lugar.

---

## PARTE C - CON ALL, Y EL RANKING QUE SE CALLA

### C1 · Ranking con ALL

```dax
Ranking = RANKX( ALL( dim_cultivo ) , [Kilos] )

```

**Punto de control 3:**

| Cultivo | `[Kilos]` | `[Ranking]` |
| --- | --- | --- |
| Mango | 12 700 | 1 |
| Maiz | 9 800 | 2 |
| Guayaba | 5 950 | 3 |
| Cacao | 2 100 | 4 |
| **Banano** | *(vacío)* | 5 |
| **Cafe** | *(vacío)* | 5 |
| **Total** | **30 550** | 1 |

**C2.** Aparecen porque la función `ALL` ignora el filtro visual, forzando a que la medida devuelva un número (el 5). Al no estar vacía la celda de la medida, la matriz se ve obligada a dibujar la fila. Es exactamente lo que pasó en la clase 17 cuando la medida `[Meta]` forzó la aparición de los cultivos vacíos.

**C3.** Ese 1 afirma que el "Total" (con 30 550 kilos) es el cultivo número uno de la empresa, lo cual es un error conceptual ya que compara el agregado global contra los elementos individuales.

### C4 · El ranking que se calla

```dax
Ranking = 
IF(
    HASONEVALUE( dim_cultivo[cultivo] ) && NOT ISBLANK( [Kilos] ),
    RANKX( ALL( dim_cultivo ) , [Kilos] )
)

```

**Punto de control 4:**

| Cultivo | `[Kilos]` | `[Ranking]` |
| --- | --- | --- |
| Mango | 12 700 | 1 |
| Maiz | 9 800 | 2 |
| Guayaba | 5 950 | 3 |
| Cacao | 2 100 | 4 |
| **Total** | **30 550** | *(vacío)* |

---

## PARTE D - EL TOP 3 DE DOS FILAS

**D1. Punto de control 5:**

| Cultivo | `[Kilos]` | `[Cosechas]` | `[Ranking]` |
| --- | --- | --- | --- |
| Mango | 12 700 | 3 | 1 |
| Maiz | 9 800 | 1 | 2 |
| Guayaba | 5 950 | 3 | 3 |
| **Total** | **28 450** | **7** |  |

**D2.** Es el total estricto de la suma de los kilos de los tres cultivos que están superando el filtro visual (Mango, Maíz y Guayaba), no el total general de la empresa.

**D2b. Punto de control 6:**

| Cultivo | `[Kilos]` | `[Cosechas]` | `[Ranking]` |
| --- | --- | --- | --- |
| Mango | 12 700 | 3 | 1 |
| Guayaba | 5 950 | 3 | 3 |
| **Total** | **18 650** | **6** |  |

**D3.** Ninguno. La medida reacciona a los filtros sin romper el visual ni emitir advertencias, mostrando silenciosamente un hueco en los puestos.

**D4.** Falta el **Cacao**, que tiene 2 100 kilos, y al que le tocó el lugar (Ranking) número 4.

**D5.** El segundo lugar lo tiene el **Maíz**. Sigue compitiendo porque la función `ALL(dim_cultivo)` dentro de la medida arrasa con absolutamente todos los filtros de la dimensión, incluyendo el filtro externo del segmentador que intentaba esconder el ciclo corto.

**D6. Punto de control 7 (Ciclo corto):**

| Cultivo | `[Kilos]` | `[Ranking]` |
| --- | --- | --- |
| Maiz | 9 800 | 2 |

**D7.** El primero sigue siendo el Mango. No está en la pantalla porque el segmentador de "ciclo corto" lo oculta visualmente, pero sigue ganando internamente.

---

## PARTE E - ALLSELECTED

### E1 · Ranking visible

```dax
Ranking visible = 
IF(
    HASONEVALUE( dim_cultivo[cultivo] ) && NOT ISBLANK( [Kilos] ),
    RANKX( ALLSELECTED( dim_cultivo ) , [Kilos] )
)

```

**E2. Punto de control 8:**

| Segmentador `tipo` | Filas del Top 3 | `[Ranking]` | `[Ranking visible]` | `[Kilos]` total |
| --- | --- | --- | --- | --- |
| *(ninguno)* | Mango, Maiz, Guayaba | 1, 2, 3 | 1, 2, 3 | 28 450 |
| perenne | Mango, Guayaba, Cacao | 1, 3, 4 | 1, 2, 3 | 20 750 |
| ciclo corto | Maiz | 2 | 1 | 9 800 |

**E3.** Porque si el desarrollador construye y valida el tablero sin tocar ni probar los segmentadores externos, ambas fórmulas entregan resultados matemáticamente impecables. El defecto está enmascarado y solo salta al interactuar.

**E4.**

* `[Ranking]`: "¿Qué lugar ocupa este cultivo históricamente contra la totalidad de la empresa, sin importar lo que el usuario esté filtrando ahora?"
* `[Ranking visible]`: "¿Qué lugar ocupa este cultivo compitiendo únicamente contra el subgrupo que el usuario acaba de filtrar?"
La medida de un verdadero «Top 3» dinámico es `[Ranking visible]`.



**E5.** La Guayaba da 2. No sale el error porque `ALL(dim_cultivo[cultivo])` quita únicamente el filtro a nivel de nombre de cultivo de las filas de la matriz, pero respeta el filtro de la columna `tipo` (perenne) del segmentador. Por ende, la Guayaba compite solo contra los perennes reales.

---

## PARTE F - SIN FÓRMULA, Y LO QUE UN RANKING NO DICE

**F1. Punto de control 9:**

| Segmentador `tipo` | Filas | `[Kilos]` total |
| --- | --- | --- |
| *(ninguno)* | Mango, Maiz, Guayaba | 28 450 |
| perenne | Mango, Guayaba, Cacao | 20 750 |

**F2.** Se parece a `[Ranking visible]` (la que usa `ALLSELECTED`), porque reasigna los puestos de manera inteligente respetando el contexto del segmentador externo (sube al Cacao al Top 3 cuando se elimina el ciclo corto).

### F3 · Ranking por finca

```dax
Ranking finca = 
IF(
    HASONEVALUE( dim_finca[finca] ) && NOT ISBLANK( [Kilos] ),
    RANKX( ALLSELECTED( dim_finca ) , [Kilos] )
)

```

**Punto de control 10:**

| Finca | `[Kilos]` 2026 | `[Ranking finca]` 2026 | `[Kilos]` 2025 | `[Ranking finca]` 2025 |
| --- | --- | --- | --- | --- |
| Finca El Guayabo | 14 250 | 1 | 9 200 | 2 |
| Hacienda Santa Rosa | 14 200 | 2 | 12 300 | 1 |
| Agricola La Union | 2 100 | 3 | 2 000 | 3 |

**F4.** El ranking es ciego ante la magnitud de la diferencia: disfraza una brecha técnica imperceptible de 50 kilos y un abismo de 12 100 kilos mostrándolos a ambos como un simple salto de posición (1 a 2 y 2 a 3). Para no desinformar, la columna del valor real (`[Kilos]`) debe acompañar siempre al ranking.

---

## PARTE G - PREGUNTAS DE CIERRE

1. **¿Qué decide la tabla?** Decide contra quién **compite** exactamente la fila actual para ganar su posición.


2. **¿Es el mismo ALL?** Sí. En la parte C hizo lo que queríamos (quitar el contexto de fila cerrado para permitir la comparación general), pero en la parte D hizo su trabajo demasiado bien: borró incluso la segmentación voluntaria del usuario, destruyendo la adaptabilidad de la pantalla.


3. **Regla de detección:** Un ranking o Top N escrito en DAX se debe probar siempre modificando segmentadores externos, para asegurar que los puestos se reasignen correctamente y no queden posiciones huecas u omitidas.


4. **¿Qué entendería el gerente?** Entendería equivocadamente que la producción total histórica o general de la empresa es 28 450. La tarjeta debería decir explícitamente "Total del Top 3" o aislarse de dicho filtro para mostrar el valor íntegro real.


5. **¿Cuándo quieres ALL a propósito?** Cuando la pregunta de negocio requiere un número absoluto inamovible. Por ejemplo: "¿Cuál es el cultivo más vendido de la historia a nivel global?", donde la posición 1 siempre debe ser la misma independientemente del país o mes que mire el analista.



```

```