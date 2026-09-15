# Ejercicio 20 · Herrera Brando

# Parte A · Todos en primer lugar

## A1 · Primer intento

```DAX
Ranking =
RANKX(
    dim_cultivo,
    [Kilos]
)
```

Resultado:

| Cultivo | Kilos | Ranking |
|----------|------:|------:|
| Mango | 12700 | 1 |
| Maiz | 9800 | 1 |
| Guayaba | 5950 | 1 |
| Cacao | 2100 | 1 |
| Total | 30550 | 1 |

---

## A2

Todos aparecen en primer lugar porque RANKX se evalúa dentro del contexto de la fila actual.

Cada cultivo compite únicamente contra sí mismo.

---

# Parte B · ALL

## B1

```DAX
Ranking =
RANKX(
    ALL(dim_cultivo),
    [Kilos]
)
```

Resultado:

| Cultivo | Kilos | Ranking |
|----------|------:|------:|
| Mango | 12700 | 1 |
| Maiz | 9800 | 2 |
| Guayaba | 5950 | 3 |
| Cacao | 2100 | 4 |
| Banano | (vacío) | 5 |
| Cafe | (vacío) | 5 |
| Total | 30550 | 1 |

---

## B2

ALL elimina el filtro de la fila actual y permite que todos los cultivos participen en la misma comparación.

---

## B3

Banano y Café aparecen porque RANKX trata los valores vacíos como cero y también los incluye en la clasificación.

---

# Parte C · El ranking que se calla

## C1

```DAX
Ranking =
IF(
    HASONEVALUE(dim_cultivo[cultivo])
    && NOT ISBLANK([Kilos]),
    RANKX(
        ALL(dim_cultivo),
        [Kilos]
    )
)
```

Resultado:

| Cultivo | Kilos | Ranking |
|----------|------:|------:|
| Mango | 12700 | 1 |
| Maiz | 9800 | 2 |
| Guayaba | 5950 | 3 |
| Cacao | 2100 | 4 |

---

## C2

HASONEVALUE evita calcular el ranking en los totales y NOT ISBLANK evita que participen cultivos sin cosechas.

---

# Parte D · Top 3

## D1

Filtro del objeto visual:

```text
[Ranking] <= 3
```

Resultado:

| Cultivo | Kilos | Cosechas | Ranking |
|----------|------:|------:|------:|
| Mango | 12700 | 3 | 1 |
| Maiz | 9800 | 1 | 2 |
| Guayaba | 5950 | 3 | 3 |
| Total | 28450 | 7 | |

---

## D2

El total cambia porque el objeto visual está filtrado y solo suma los elementos que permanecen visibles.

---

# Parte E · El Top 3 tenía dos

## E1

Segmentador:

```text
tipo = perenne
```

Resultado:

| Cultivo | Kilos | Cosechas | Ranking |
|----------|------:|------:|------:|
| Mango | 12700 | 3 | 1 |
| Guayaba | 5950 | 3 | 3 |
| Total | 18650 | 6 | |

---

## E2

El Top 3 muestra únicamente dos filas porque el ranking sigue compitiendo contra Maíz, aunque el segmentador lo haya ocultado.

---

## E3

ALL(dim_cultivo) elimina todos los filtros de la tabla dim_cultivo, incluidos los filtros aplicados por los segmentadores.

---

# Parte F · ALLSELECTED

## F1

```DAX
Ranking visible =
IF(
    HASONEVALUE(dim_cultivo[cultivo])
    && NOT ISBLANK([Kilos]),
    RANKX(
        ALLSELECTED(dim_cultivo),
        [Kilos]
    )
)
```

Resultado con:

```text
tipo = perenne
```

| Cultivo | Kilos | Ranking | Ranking visible |
|----------|------:|------:|------:|
| Mango | 12700 | 1 | 1 |
| Guayaba | 5950 | 3 | 2 |
| Cacao | 2100 | 4 | 3 |
| Total | 20750 | | |

---

## F2

ALLSELECTED elimina únicamente el filtro de la fila actual y conserva los filtros aplicados por segmentadores.

---

## F3

Ranking responde a la pregunta: ¿qué lugar ocupa el cultivo en toda la empresa?

Ranking visible responde a la pregunta: ¿qué lugar ocupa el cultivo dentro de lo que estoy viendo?
