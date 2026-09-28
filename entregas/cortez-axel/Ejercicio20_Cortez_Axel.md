# Ejercicio 20 · Un Top 3 que siga siendo de tres cuando el gerente filtra

- **Alumno:** Cortez Cardozo Axel Josue
- **Ejercicio / proyecto:** Ejercicio 20 · RANKX, ALL, ALLSELECTED y evaluación de contexto en Top N
- **Archivo:** `entregas/cortez-axel/Ejercicio20_Cortez_Axel.md`

---

## Parte A · La tabla de siempre

### A1. Segmentadores
- `dim_tiempo[anio]` = 2026
- `dim_tiempo[mes]` en 1, 2, 3 y 4
- `dim_cultivo[tipo]` (sin selección)

### A2. Tabla por cultivo (Punto de control 1)

| Cultivo | [Kilos] | [Cosechas] |
|---|---|---|
| Mango | 12 700 | 3 |
| Maiz | 9 800 | 1 |
| Guayaba | 5 950 | 3 |
| Cacao | 2 100 | 2 |
| **Total** | **30 550** | **9** |

### A3. Respuesta
Banano y Café no aparecen porque el motor tabular aplica por defecto un auto-exist que omite del visual las filas cuyo cálculo de medidas devuelve valores nulos o en blanco.

### A4. Respuesta
Porque la ordenación visual solo cambia la presentación estética en el lienzo, pero no genera un valor escalar reutilizable para segmentar, condicionar lógicas DAX o aplicar filtros dinámicos de Top N.

---

## Parte B · Todos en primer lugar

### B1. Medida Ranking (primera versión)
```dax
Ranking = RANKX( dim_cultivo , [Kilos] )
```

### Tabla resultante (Punto de control 2)

| Cultivo | [Kilos] | [Ranking] |
|---|---|---|
| Mango | 12 700 | 1 |
| Maiz | 9 800 | 1 |
| Guayaba | 5 950 | 1 |
| Cacao | 2 100 | 1 |
| **Total** | **30 550** | **1** |

### B2. Mensaje de error o advertencia
Power BI no arrojó ningún error ni advertencia; la medida se evaluó sin excepciones.

### B3. Respuesta
Tiene exactamente 1 fila porque el contexto de filtro de la fila exterior restringe a `dim_cultivo` a ese único cultivo; `RANKX` evalúa a Mango compitiendo únicamente contra sí mismo.

---

## Parte C · Con ALL, y el ranking que se calla

### C1. Medida con ALL
```dax
Ranking = RANKX( ALL( dim_cultivo ) , [Kilos] )
```

### Tabla resultante (Punto de control 3)

| Cultivo | [Kilos] | [Ranking] |
|---|---|---|
| Mango | 12 700 | 1 |
| Maiz | 9 800 | 2 |
| Guayaba | 5 950 | 3 |
| Cacao | 2 100 | 4 |
| Banano | (vacío) | 5 |
| Cafe | (vacío) | 5 |
| **Total** | **30 550** | **1** |

### C2. Respuesta
Aparecen porque `ALL(dim_cultivo)` genera un número (5) para cada cultivo sin cosechas, forzando a la fila a mostrarse; recuerda al comportamiento de medidas aditivas sin control de contexto evaluadas sobre dimensiones completas.

### C3. Respuesta
Afirma equívocamente que el conjunto total de la empresa es el cultivo posicionado en el puesto número 1.

### C4. Medida que se calla
```dax
Ranking =
IF(
    HASONEVALUE( dim_cultivo[cultivo] ) && NOT ISBLANK( [Kilos] ),
    RANKX( ALL( dim_cultivo ) , [Kilos] )
)
```

### Tabla resultante (Punto de control 4)

| Cultivo | [Kilos] | [Ranking] |
|---|---|---|
| Mango | 12 700 | 1 |
| Maiz | 9 800 | 2 |
| Guayaba | 5 950 | 3 |
| Cacao | 2 100 | 4 |
| **Total** | **30 550** | (vacío) |

---

## Parte D · El Top 3 de dos filas

### D1. Top 3 sin filtro de tipo (Punto de control 5)

| Cultivo | [Kilos] | [Cosechas] | [Ranking] |
|---|---|---|---|
| Mango | 12 700 | 3 | 1 |
| Maiz | 9 800 | 1 | 2 |
| Guayaba | 5 950 | 3 | 3 |
| **Total** | **28 450** | **7** | |

### D2. Respuesta
Es el total agregado de los kilos correspondientes únicamente a las filas visibles que superaron el filtro visual (`[Ranking] <= 3`).

### D2b. Selección perenne (Punto de control 6)

| Cultivo | [Kilos] | [Cosechas] | [Ranking] |
|---|---|---|---|
| Mango | 12 700 | 3 | 1 |
| Guayaba | 5 950 | 3 | 3 |
| **Total** | **18 650** | **6** | |

### D3. Mensaje de error o advertencia
Ninguno; el visual simplemente omitió la tercera fila de forma silenciosa.

### D4. Respuesta
Falta Cacao, que tiene 2 100 kilos y un ranking global de 4; el filtro del visual solo permite valores menores o iguales a 3.

### D5. Respuesta
El segundo lugar pertenece al Maíz (9 800 kilos); sigue compitiendo porque `ALL(dim_cultivo)` remueve todos los filtros de la tabla completa, ignorando el segmentador de tipo.

### D6. Selección ciclo corto (Punto de control 7)

| Cultivo | [Kilos] | [Ranking] |
|---|---|---|
| Maiz | 9 800 | 2 |

### D7. Respuesta
El primer lugar lo ocupa el Mango; no está en pantalla porque fue excluido por el segmentador de tipo.

---

## Parte E · ALLSELECTED

### E1. Medida Ranking visible
```dax
Ranking visible =
IF(
    HASONEVALUE( dim_cultivo[cultivo] ) && NOT ISBLANK( [Kilos] ),
    RANKX( ALLSELECTED( dim_cultivo ) , [Kilos] )
)
```

### E2. Comportamiento en los tres escenarios (Punto de control 8)

| Segmentador `tipo` | Filas del Top 3 | [Ranking] | [Ranking visible] | [Kilos] total |
|---|---|---|---|---|
| *(ninguno)* | Mango, Maiz, Guayaba | 1, 2, 3 | 1, 2, 3 | 28 450 |
| perenne | Mango, Guayaba, Cacao | 1, 3, 4 | 1, 2, 3 | 20 750 |
| ciclo corto | Maiz | 2 | 1 | 9 800 |

*(Se adjunta captura `clase20-top3.png` con la opción perenne activa).*

### E3. Respuesta
Porque en la vista global sin segmentadores ambas medidas devuelven números idénticos (1, 2 y 3), ocultando el defecto estructural hasta que el usuario final interactúa con los filtros.

### E4. Respuesta
- `[Ranking]`: "¿Qué lugar ocupa este cultivo frente a todos los cultivos de la compañía?"
- `[Ranking visible]`: "¿Qué lugar ocupa este cultivo dentro del subconjunto actualmente seleccionado?"
La de un Top 3 dinámico en un tablero interactivo es `[Ranking visible]`.

### E5. Respuesta
Con `ALL(dim_cultivo[cultivo])` la Guayaba da 2 porque solo se ignora el filtro sobre la columna de nombre, manteniendo activo el filtro exterior de la columna `tipo` en el contexto.

---

## Parte F · Sin fórmula, y lo que un ranking no dice

### F1. N principales nativo (Punto de control 9)

| Segmentador `tipo` | Filas | [Kilos] total |
|---|---|---|
| *(ninguno)* | Mango, Maiz, Guayaba | 28 450 |
| perenne | Mango, Guayaba, Cacao | 20 750 |

### F2. Respuesta
Se asemeja a `[Ranking visible]` porque recalcula la selección dentro del subconjunto de datos filtrado por los segmentadores del informe.

### F3. Ranking por finca (Punto de control 10)
```dax
Ranking finca =
IF(
    HASONEVALUE( dim_finca[finca] ) && NOT ISBLANK( [Kilos] ),
    RANKX( ALLSELECTED( dim_finca ) , [Kilos] )
)
```

| Finca | [Kilos] 2026 | [Ranking finca] 2026 | [Kilos] 2025 | [Ranking finca] 2025 |
|---|---|---|---|---|
| Finca El Guayabo | 14 250 | 1 | 9 200 | 2 |
| Hacienda Santa Rosa | 14 200 | 2 | 12 300 | 1 |
| Agricola La Union | 2 100 | 3 | 2 000 | 3 |

### F4. Respuesta
El ranking es una métrica puramente ordinal y oculta por completo las distancias numéricas de magnitud; la métrica de volumen absoluto (`[Kilos]`) debe acompañar siempre a un ranking.

---

## Parte G · Preguntas de cierre

1. La tabla determina el universo de competidores contra el cual se evalúa la expresión de cálculo.
2. Es la misma función DAX pero operando en contextos distintos: en la parte C eliminó el filtro de fila para comparar contra los demás elementos, mientras que en la parte D eliminó incorrectamente los filtros externos del segmentador interactivo.
3. Un ranking interactivo se prueba siempre con al menos un segmentador de categoría activo y una categoría sin elementos dominantes.
4. El usuario asumiría que 28 450 kilos es la cosecha global de toda la empresa; la tarjeta debe titularse "Total Top 3" o "Kilos Seleccionados" para no inducir a error.
5. Se utiliza cuando se necesita evaluar la jerarquía global de una entidad independientemente de cualquier filtro o vista analítica (por ejemplo: "Lugar del producto en la cuota histórica nacional").