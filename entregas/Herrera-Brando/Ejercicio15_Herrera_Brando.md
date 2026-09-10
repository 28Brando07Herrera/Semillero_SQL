# Ejercicio 15 · Herrera Brando

## Parte A · La estrella, sin Oracle

### A2

Los tipos de datos llegaron correctamente.

- h_cosecha[kg] → Número entero
- h_cosecha[fecha] → Fecha
- dim_tiempo[fecha] → Fecha

### A3

Power BI detectó automáticamente las tres relaciones del modelo:

- h_cosecha[finca_id] → dim_finca[finca_id]
- h_cosecha[cultivo_id] → dim_cultivo[cultivo_id]
- h_cosecha[fecha] → dim_tiempo[fecha]

Cardinalidad: muchos a uno (*:1)

Dirección de filtro: simple

Resultado: 3 relaciones automáticas y 0 manuales.

---

# Parte B · Tus primeras medidas

### B1 · Kilos

```DAX
Kilos = SUM(h_cosecha[kg])
```

Resultado: 30550

---

### B2 · Cosechas

```DAX
Cosechas = COUNTROWS(h_cosecha)
```

Resultado: 9

---

### B3 · Tabla por finca

| Finca | Kilos | Cosechas |
|---------|---------:|---------:|
| Finca El Guayabo | 14250 | 3 |
| Hacienda Santa Rosa | 14200 | 4 |
| Agricola La Union | 2100 | 2 |
| **Total** | **30550** | **9** |

---

### B4

No siempre. El total es una nueva evaluación de la medida en un contexto diferente y no necesariamente la suma de las filas visibles.

---

# Parte C · Medida contra columna calculada

### C1 · Columna calculada

```DAX
tamano = IF( h_cosecha[kg] >= 3000, "grande", "chica" )
```

Resultado:

| tamano | Kilos | Cosechas |
|---------|---------:|---------:|
| grande | 22500 | 4 |
| chica | 8050 | 5 |
| **Total** | **30550** | **9** |

---

### C2 · Columna calculada y medida

```DAX
pct_columna = h_cosecha[kg] / SUM(h_cosecha[kg])
```

```DAX
Pct medida =
DIVIDE(
    [Kilos],
    CALCULATE([Kilos], ALL(h_cosecha))
)
```

Sin filtros, ambas muestran los mismos porcentajes.

---

### C3

Con el segmentador en:

```text
Agricola La Union
```

Resultado:

| | pct_columna | Pct medida |
|---|---:|---:|
| cosecha 8 | 3,93 % | 57,14 % |
| cosecha 9 | 2,95 % | 42,86 % |
| Total | 6,87 % | 100,00 % |

---

### C4

La columna calculada se creó al cargar los datos y quedó almacenada usando el total de 30550 kg.

La medida se recalcula cada vez que cambia el contexto de filtro. Al seleccionar Agricola La Union utiliza como referencia únicamente los 2100 kg de esa finca.

---

### C5

La medida responde correctamente qué porcentaje aporta cada cosecha dentro de la finca seleccionada.

La columna calculada responde qué porcentaje representa cada cosecha respecto al total global de 30550 kg.

---

# Parte D · Contexto de filtro

### D1 · Pct mal

```DAX
Pct mal = DIVIDE( [Kilos] , [Kilos] )
```

Resultado:

| Finca | Kilos | Pct mal |
|---|---:|---:|
| Finca El Guayabo | 14250 | 100,00 % |
| Hacienda Santa Rosa | 14200 | 100,00 % |
| Agricola La Union | 2100 | 100,00 % |
| Total | 30550 | 100,00 % |

---

### D2

Las dos referencias a [Kilos] se evalúan dentro del mismo contexto de filtro.

Como ambas devuelven el mismo valor, la división siempre produce 1 (100%).

---

### D3 · Pct del total

```DAX
Pct del total =
DIVIDE(
    [Kilos],
    CALCULATE( [Kilos] , ALL(dim_finca) )
)
```

Resultado:

| Finca | Kilos | Pct del total |
|---|---:|---:|
| Finca El Guayabo | 14250 | 46,64 % |
| Hacienda Santa Rosa | 14200 | 46,48 % |
| Agricola La Union | 2100 | 6,87 % |
| Total | 30550 | 100,00 % |

---

### D4

ALL(dim_finca) elimina el filtro de finca.

Si se usa ALL(dim_cultivo), el filtro de finca continúa activo y el porcentaje vuelve a evaluarse contra el mismo subconjunto, produciendo nuevamente 100%.

---

# Parte E · La trampa del día

### E1 · Promedio por cultivo MAL

```DAX
Promedio por cultivo MAL =
DIVIDE(
    [Kilos],
    COUNTROWS(dim_cultivo)
)
```

Resultado: 5091,67

---

### E2

Power BI no mostró ningún mensaje de error.

---

### E3

Power BI dividió:

```text
30550 / 6
```

Resultado:

```text
5091,67
```

---

### E4 · Medidas de control

```DAX
Cultivos en la dimension =
COUNTROWS(dim_cultivo)
```

Resultado: 6

```DAX
Cultivos con cosecha =
DISTINCTCOUNT(h_cosecha[cultivo_id])
```

Resultado: 4

---

### E5

Los cultivos que sobran son Banano y Café.

Están presentes en la dimensión porque existen en el negocio, aunque todavía no tengan cosechas registradas.

---

### E6 · Promedio por cultivo

```DAX
Promedio por cultivo =
DIVIDE(
    [Kilos],
    DISTINCTCOUNT(h_cosecha[cultivo_id])
)
```

Resultado: 7637,50

---

### E7

Segmentador:

```text
dim_cultivo[tipo] = perenne
```

Resultado:

| Medida | Valor |
|---|---:|
| Kilos | 20750 |
| Cultivos en la dimension | 5 |
| Cultivos con cosecha | 3 |
| Promedio por cultivo MAL | 4150,00 |
| Promedio por cultivo | 6916,67 |

---

### E8

Las dos medidas reaccionan al segmentador porque respetan el contexto de filtro.

La medida incorrecta sigue siendo incorrecta porque usa como denominador todos los cultivos de la dimensión y no únicamente los cultivos que tienen cosechas.

---

### E9

Una dimensión con filas sin hechos asociados deja de ser inofensiva cuando esas filas participan en un denominador o en el cálculo de un promedio.

---

# Parte F · Preguntas de cierre

### F1

Una columna calculada se evalúa al cargar o actualizar los datos. Una medida se evalúa cada vez que cambia el contexto de filtro.

---

### F2

No siempre. La fila Total es una nueva evaluación de la medida en un contexto diferente y no necesariamente la suma de las filas visibles.

---

### F3

ALL(dim_finca) significa eliminar el filtro aplicado sobre la dimensión de fincas.

---

### F4

Todos producen resultados incorrectos que parecen válidos y normalmente no muestran ningún mensaje de error.

---

### F5

