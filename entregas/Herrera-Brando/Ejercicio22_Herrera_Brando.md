# Ejercicio 22 · Herrera Brando

# Parte A · Una tabla que no viene de ningún archivo

## A1 · Segmentadores

Configuración utilizada durante todo el ejercicio:

```text
anio = 2026
mes = 1, 2, 3 y 4
tipo = sin selección
```

---

## A2 · Tabla por finca

| Finca | Kilos | Meta | Cumplimiento |
|---------|---------:|---------:|---------:|
| Agricola La Union | 2100 | 5000 | 42,00 % |
| Finca El Guayabo | 14250 | 9440 | 150,95 % |
| Hacienda Santa Rosa | 14200 | 10000 | 142,00 % |
| Total | 30550 | 24440 | 125,00 % |

---

## A3 · Tabla escenario

```DAX
escenario =
DATATABLE(
    "nivel",
    INTEGER,
    {
        { 100 },
        { 110 },
        { 120 },
        { 130 },
        { 140 },
        { 150 }
    }
)
```

Resultado:

```text
La tabla escenario tiene 6 filas:
100, 110, 120, 130, 140 y 150.
```

```text
La tabla escenario no tiene relaciones con ninguna otra tabla del modelo.
```

---

## A4

Se creó un segmentador utilizando:

```text
escenario[nivel]
```

Se probaron los valores:

```text
130
150
```

---

## A5

La tabla por finca no cambió al seleccionar niveles en el segmentador.

Esto ocurre porque la tabla escenario no tiene ninguna relación con el resto del modelo.

---

# Parte B · La medida pregunta

## B1 · Nivel elegido

```DAX
Nivel elegido =
SELECTEDVALUE(
    escenario[nivel],
    100
)
```

---

## B1 · Meta ajustada

```DAX
Meta ajustada =
[Meta] * [Nivel elegido] / 100
```

---

## B1 · Cumplimiento ajustado

```DAX
Cumplimiento ajustado =
DIVIDE(
    [Kilos],
    [Meta ajustada]
)
```

Resultado con:

```text
nivel = 130
```

| Finca | Kilos | Meta ajustada | Cumplimiento ajustado |
|---------|---------:|---------:|---------:|
| Agricola La Union | 2100 | 6500 | 32,31 % |
| Finca El Guayabo | 14250 | 12272 | 116,12 % |
| Hacienda Santa Rosa | 14200 | 13000 | 109,23 % |
| Total | 30550 | 31772 | 96,15 % |

---

## B2 · Los seis niveles

| Nivel | Meta ajustada | Cumplimiento ajustado |
|---------|---------:|---------:|
| 100 | 24440 | 125,00 % |
| 110 | 26884 | 113,64 % |
| 120 | 29328 | 104,17 % |
| 130 | 31772 | 96,15 % |
| 140 | 34216 | 89,29 % |
| 150 | 36660 | 83,33 % |

---

## B3

La empresa cumple hasta el nivel 120 porque todavía 