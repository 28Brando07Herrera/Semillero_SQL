# Ejercicio 21 · Herrera Brando

# Parte A · La foto inicial

## A1

Tabla por finca:

| Finca | Kilos | Meta | Cumplimiento |
|---------|---------:|---------:|---------:|
| Agricola La Union | 2100 | 5000 | 42,00 % |
| Finca El Guayabo | 14250 | 9440 | 150,95 % |
| Hacienda Santa Rosa | 14200 | 10000 | 142,00 % |
| Total | 30550 | 24440 | 125,00 % |

---

# Parte B · Bono y apoyo

## B1 · Excedente

```DAX
Excedente =
MAX(
    0,
    [Kilos] - [Meta]
)
```

Resultado:

| Finca | Excedente |
|---------|---------:|
| Agricola La Union | 0 |
| Finca El Guayabo | 4810 |
| Hacienda Santa Rosa | 4200 |
| Total | 6110 |

Suma manual:

```text
0 + 4810 + 4200 = 9010
```

---

## B2 · Faltante

```DAX
Faltante =
MAX(
    0,
    [Meta] - [Kilos]
)
```

Resultado:

| Finca | Faltante |
|---------|---------:|
| Agricola La Union | 2900 |
| Finca El Guayabo | 0 |
| Hacienda Santa Rosa | 0 |
| Total | 0 |

Suma manual:

```text
2900 + 0 + 0 = 2900
```

---

## B3

La fila del total no suma las filas visibles.

Power BI vuelve a calcular la medida utilizando el contexto de toda la empresa.

---

## B4

Para el total:

```text
Kilos = 30550
Meta = 24440
```

Entonces:

```text
30550 - 24440 = 6110
```

Por eso el total de Excedente muestra 6110.

---

## B5

El faltante de Agricola La Union queda compensado por los excedentes de Finca El Guayabo y Hacienda Santa Rosa.

Por eso el total de Faltante aparece como 0.

---

# Parte C · El año completo

## C1

Quitando el filtro de meses:

Resultado esperado:

```text
Excedente = 0
```

en todas las fincas.

---

## C2

Resultado:

| Finca | Faltante |
|---------|---------:|
| Agricola La Union | 5900 |
| Finca El Guayabo | 4750 |
| Hacienda Santa Rosa | 5800 |
| Total | 16450 |

---

## C3

En este caso el total coincide porque todas las fincas están por debajo de la meta.

Ninguna fila compensa a otra.

---

# Parte D · SUMX por finca

## D1

```DAX
Excedente por finca =
SUMX(
    dim_finca,
    [Excedente]
)
```

Resultado:

```text
Total = 9010
```

---

## D2

```DAX
Faltante por finca =
SUMX(
    dim_finca,
    [Faltante]
)
```

Resultado:

```text
Total = 2900
```

---

## D3

SUMX evalúa la medida una finca a la vez y luego suma los resultados obtenidos.

---

## D4

Ahora los totales coinciden con la suma manual de las filas visibles.

---

# Parte E · Neto

## E1

```DAX
Neto =
[Kilos] - [Meta]
```

Resultado:

| Finca | Neto |
|---------|---------:|
| Agricola La Union | -2900 |
| Finca El Guayabo | 4810 |
| Hacienda Santa Rosa | 4200 |
| Total | 6110 |

---

## E2

El total es correcto porque la medida no tiene MAX ni IF que separen resultados positivos y negativos.

---

## E3

Comprobación:

```text
Excedente - Faltante

9010 - 2900 = 6110
```

Coincide exactamente con:

```text
[Neto] = 6110
```

---

# Parte F · El problema vuelve por mes

## F1

Tabla por mes utilizando:

```DAX
[Excedente por finca]
```

Resultado:

| Mes | Excedente por finca |
|---------|---------:|
| Enero | 0 |
| Febrero | 0 |
| Marzo | 6600 |
| Abril | 11850 |
| Total | 9010 |

Suma manual:

```text
6600 + 11850 = 18450
```

---

## F2

SUMX corrigió el cálculo para las fincas, pero no para los meses.

---

## F3

El total vuelve a ser recalculado en el contexto general y no suma las filas mensuales.

---

# Parte G · SUMX dentro de SUMX

## G1

```DAX
Excedente mensual =
SUMX(
    dim_finca,
    SUMX(
        VALUES(dim_tiempo[anio_mes]),
        [Excedente]
    )
)
```

---

## G2

Resultado por mes:

| Mes | Excedente mensual |
|---------|---------:|
| Enero | 0 |
| Febrero | 0 |
| Marzo | 6600 |
| Abril | 11850 |
| Total | 18450 |

---

## G3

Resultado por finca:

| Finca | Excedente mensual |
|---------|---------:|
| Agricola La Union | 0 |
| Finca El Guayabo | 10750 |
| Hacienda Santa Rosa | 7700 |
| Total | 18450 |

---

## G4

```DAX
Faltante mensual =
SUMX(
    dim_finca,
    SUMX(
        VALUES(dim_tiempo[anio_mes]),
        [Faltante]
    )
)
```

Resultado por finca:

| Finca | Faltante mensual |
|---------|---------:|
| Agricola La Union | 2900 |
| Finca El Guayabo | 5940 |
| Hacienda Santa Rosa | 3500 |
| Total | 12340 |

---

## G5

Resultado por mes:

| Mes | Faltante mensual |
|---------|---------:|
| Enero | 4040 |
| Febrero | 5200 |
| Marzo | 2700 |
| Abril | 400 |
| Total | 12340 |

---

# Parte H · Comparación de resultados

## H1

Resultado utilizando la medida original:

```text
Excedente = 6110
Faltante = 0
```

---

## H2

Resultado utilizando SUMX por finca:

```text
Excedente por finca = 9010
Faltante por finca = 2900
```

---

## H3

Resultado utilizando SUMX por finca y por mes:

```text
Excedente mensual = 18450
Faltante mensual = 12340
```

---

## H4

Comprobación:

```text
6110 - 0 = 6110

9010 - 2900 = 6110

18450 - 12340 = 6110
```

Los tres enfoques producen exactamente el mismo neto.

---

# Preguntas de cierre

## I1

La fila del total no suma las filas visibles. Power BI vuelve a calcular la medida utilizando el contexto del total.

---

## I2

Las medidas que contienen funciones como MAX, IF o DIVIDE pueden producir totales diferentes porque compensan resultados entre filas.

---

## I3

SUMX permite controlar explícitamente la granularidad del cálculo recorriendo una tabla fila por fila.

---

## I4

SUMX corrige el total únicamente para la tabla que recorre. Si la lógica debe aplicarse por finca y por mes, es necesario recorrer ambas dimensiones.

---

## I5

La granularidad del total es una decisión de negocio y no una decisión técnica de DAX.

Primero debe definirse cómo se calcula el bono y luego implementarse la medida correspondiente.