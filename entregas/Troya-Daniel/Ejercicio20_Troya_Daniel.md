# Ejercicio Práctico 20: Un Top 3 que siga siendo de tres cuando el gerente filtra

**Estudiante:** Troya Riofrio, Daniel Moises  
**Fecha:** 15 de septiembre de 2026  
**Entorno:** Power BI Desktop  

---

## Parte A · La tabla de siempre

### A1 & A2 · Tabla por cultivo ordenada por [Kilos]

| Cultivo | [Kilos] | [Cosechas] |
| :--- | :--- | :--- |
| Mango | 12 700 | 3 |
| Maiz | 9 800 | 1 |
| Guayaba | 5 950 | 3 |
| Cacao | 2 100 | 2 |
| **Total** | **30 550** | **9** |

### A3 · ¿Por qué no salen Banano y Café?
No aparecen porque la relación entre las dimensiones y la tabla de hechos evalúa la medida `[Kilos]`, la cual da en blanco para ambos cultivos en ese periodo, y Power BI oculta automáticamente las filas vacías.

### A4 · ¿Para qué quieres una medida de ranking si la tabla ya está ordenada?
Para poder aplicar filtros visuales de corte (como un Top N dinámico) o conservar el puesto relativo independientemente de cómo el usuario reordene la tabla por otras columnas.

---

## Parte B · Todos en primer lugar

### B1 · Ranking (primera versión)

```dax
Ranking = RANKX( dim_cultivo , [Kilos] )
```

| Cultivo | [Kilos] | [Ranking] |
| :--- | :--- | :--- |
| Mango | 12 700 | 1 |
| Maiz | 9 800 | 1 |
| Guayaba | 5 950 | 1 |
| Cacao | 2 100 | 1 |
| **Total** | **30 550** | **1** |

Mango 1 · Maiz 1 · Guayaba 1 · Cacao 1 · Total 1

### B2 · Advertencia o mensaje de error de Power BI
Ninguno. La fórmula es sintácticamente válida para DAX.

### B3 · Filas en dim_cultivo y contexto de filtro
En la fila de Mango, `dim_cultivo` tiene solo una fila debido a que el contexto de filtro de la fila restringe la tabla a ese cultivo; por tanto, `RANKX` lo evalúa compitiendo únicamente contra sí mismo y le asigna el puesto 1.

---

## Parte C · Con ALL, y el ranking que se calla

### C1 · Ranking con ALL

```dax
Ranking = RANKX( ALL( dim_cultivo ) , [Kilos] )
```

| Cultivo | [Kilos] | [Ranking] |
| :--- | :--- | :--- |
| Mango | 12 700 | 1 |
| Maiz | 9 800 | 2 |
| Guayaba | 5 950 | 3 |
| Cacao | 2 100 | 4 |
| Banano | (vacío) | 5 |
| Cafe | (vacío) | 5 |
| **Total** | **30 550** | **1** |

### C2 · Aparición de Banano y Café
Aparecen porque la medida `[Ranking]` ahora devuelve un valor numérico (5) para ellos, obligando a Power BI a mostrar la fila; recuerda al comportamiento de dimensionalidad completa visto en clases anteriores al romper contextos con `ALL`.

### C3 · ¿Qué afirma el total = 1?
Afirma erróneamente que el total global (30 550 kg) es el valor más grande frente a la lista de todos los cultivos individuales evaluados.

### C4 · El ranking que se calla

```dax
Ranking =
IF(
    HASONEVALUE( dim_cultivo[cultivo] ) && NOT ISBLANK( [Kilos] ),
    RANKX( ALL( dim_cultivo ) , [Kilos] )
)
```

| Cultivo | [Kilos] | [Ranking] |
| :--- | :--- | :--- |
| Mango | 12 700 | 1 |
| Maiz | 9 800 | 2 |
| Guayaba | 5 950 | 3 |
| Cacao | 2 100 | 4 |
| **Total** | **30 550** | **(vacío)** |

---

## Parte D · El Top 3 de dos filas

### D1 · Top 3 con filtro visual [Ranking] <= 3

| Cultivo | [Kilos] | [Cosechas] | [Ranking] |
| :--- | :--- | :--- | :--- |
| Mango | 12 700 | 3 | 1 |
| Maiz | 9 800 | 1 | 2 |
| Guayaba | 5 950 | 3 | 3 |
| **Total** | **28 450** | **7** |  |

### D2 · ¿De qué es el total 28 450?
Es la suma de los kilos de las filas visibles que cumplen la condición del filtro del objeto visual (Mango, Maiz y Guayaba).

### D2b · Segmentador tipo = perenne

| Cultivo | [Kilos] | [Cosechas] | [Ranking] |
| :--- | :--- | :--- | :--- |
| Mango | 12 700 | 3 | 1 |
| Guayaba | 5 950 | 3 | 3 |
| **Total** | **18 650** | **6** |  |

### D3 · Advertencia o mensaje de error de Power BI
Ninguno.

### D4 · Cultivo faltante en perenne
Falta Cacao (2 100 kg), al cual le correspondió el ranking 4 absoluto; por eso el filtro `<= 3` lo descarta y deja la tabla con solo dos filas.

### D5 · ¿Quién tiene el segundo lugar y por qué sigue compitiendo?
El segundo lugar le pertenece al Maíz (9 800 kg); sigue compitiendo porque `ALL( dim_cultivo )` borra todos los filtros sobre la dimensión, ignorando por completo la selección externa del segmentador `tipo = perenne`.

### D6 · Segmentador tipo = ciclo corto

| Cultivo | [Kilos] | [Ranking] |
| :--- | :--- | :--- |
| Maiz | 9 800 | 2 |
| **Total** | **9 800** |  |

### D7 · ¿Quién va primero en ciclo corto?
Va primero el Mango (12 700 kg), pero no está visible en pantalla porque el segmentador de tipo lo filtró.

---

## Parte E · ALLSELECTED

### E1 · Definición de Ranking visible

```dax
Ranking visible =
IF(
    HASONEVALUE( dim_cultivo[cultivo] ) && NOT ISBLANK( [Kilos] ),
    RANKX( ALLSELECTED( dim_cultivo ) , [Kilos] )
)
```

### E2 · Tabla comparativa por segmentador de tipo

| Segmentador tipo | Filas del Top 3 | [Ranking] | [Ranking visible] | [Kilos] total |
| :--- | :--- | :--- | :--- | :--- |
| **(ninguno)** | Mango, Maiz, Guayaba | 1, 2, 3 | 1, 2, 3 | 28 450 |
| **perenne** | Mango, Guayaba, Cacao | 1, 3, 4 | 1, 2, 3 | 20 750 |
| **ciclo corto** | Maiz | 2 | 1 | 9 800 |

*(La captura requerida `clase20-top3.png` se toma en este estado: `tipo = perenne`, mostrando Mango, Guayaba y Cacao con total 20 750).*

### E3 · ¿Por qué es fácil publicar este error?
Porque sin segmentadores activos, `[Ranking]` y `[Ranking visible]` dan idéntico resultado; el error conceptual solo se hace visible cuando el usuario final interactúa con los filtros.

### E4 · Preguntas de negocio de cada medida
* **[Ranking]:** ¿Qué posición histórica ocupa este cultivo frente a todos los cultivos del catálogo general?
* **[Ranking visible]:** ¿Qué lugar ocupa este cultivo dentro del grupo seleccionado o visible en pantalla? (Esta última es la pregunta de un «Top 3»).

### E5 · ALL( dim_cultivo[cultivo] ) frente a ALL( dim_cultivo )
Al liberar solo la columna `[cultivo]`, el filtro del segmentador sobre `[tipo]` sigue activo en la dimensión; Guayaba da 2 porque el Maíz queda fuera de la tabla evaluada por el contexto de `tipo`.

---

## Parte F · Sin fórmula, y lo que un ranking no dice

### F1 · N principales (Top 3 por [Kilos])

| Segmentador tipo | Filas | [Kilos] total |
| :--- | :--- | :--- |
| **(ninguno)** | Mango, Maiz, Guayaba | 28 450 |
| **perenne** | Mango, Guayaba, Cacao | 20 750 |

### F2 · ¿A cuál medida se parece N principales?
Se parece a `[Ranking visible]`, ya que recalcula los mejores elementos respetando los filtros externos aplicados por los segmentadores.

### F3 · Ranking por finca

```dax
Ranking finca =
IF(
    HASONEVALUE( dim_finca[finca] ) && NOT ISBLANK( [Kilos] ),
    RANKX( ALLSELECTED( dim_finca ) , [Kilos] )
)
```

| Finca | [Kilos] 2026 | [Ranking finca] 2026 | [Kilos] 2025 | [Ranking finca] 2025 |
| :--- | :--- | :--- | :--- | :--- |
| Finca El Guayabo | 14 250 | 1 | 9 200 | 2 |
| Hacienda Santa Rosa | 14 200 | 2 | 12 300 | 1 |
| Agricola La Union | 2 100 | 3 | 2 000 | 3 |

### F4 · Lo que esconde el ranking
El ranking solo informa posición ordinal pero oculta las distancias reales (magnitudes) entre competidores; por ello, la columna de valor real (`[Kilos]`) tiene que ir siempre al lado de un ranking.

---

## Parte G · Preguntas de cierre

1. **¿Qué decide la tabla en `RANKX( tabla , expresión )`?**  
   Decide el conjunto de elementos contra los cuales **compite** la fila evaluada.

2. **Diferencia del impacto de ALL en C vs. D:**  
   En C quitó el filtro de fila para restaurar la lista completa de competidores; en D borró los filtros de segmentación del usuario, obligando a competir a elementos que estaban excluidos de la vista.

3. **Regla de detección del día:**  
   «Un ranking dinámico se prueba siempre filtrando una categoría en un segmentador».

4. **Interpretación errónea de la tarjeta de total en un Top 3:**  
   El gerente entendería que 28 450 kg es la producción total de la empresa; la tarjeta tendría que decir «Total Top 3» para no engañarlo.

5. **¿Cuándo se quiere ALL a propósito en un ranking?**  
   Cuando se necesita conocer la posición absoluta global; por ejemplo: *«¿Qué puesto ocupa esta sucursal a nivel nacional, incluso si filtro solo mi provincia?»*.
