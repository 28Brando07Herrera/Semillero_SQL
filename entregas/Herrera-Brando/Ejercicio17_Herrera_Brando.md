# Ejercicio 17 · Herrera Brando

---

# Parte A · La segunda tabla de hechos

## A3

La relación que falta es entre `h_meta` y `dim_cultivo`.

No puede crearse porque la tabla `h_meta` no contiene `cultivo_id`. La meta fue definida por finca y mes, no por cultivo.

---

## A4

Resultados de comprobación:

| Medida | Valor |
|---------|---------|
| [Kilos] sin filtros | 77550 |
| [Kilos] con anio = 2026 | 30550 |
| [Cosechas] | 25 |

La incorporación de `h_meta` no modificó los datos de cosecha.

---

# Parte B · La medida que cruza los dos hechos

## B1 · Meta

```DAX
Meta =
SUM(h_meta[kg_meta])
```

Resultado sin filtros:

```text
47000
```

---

## B1 · Cumplimiento

```DAX
Cumplimiento =
DIVIDE([Kilos],[Meta])
```

Resultado sin filtros:

```text
165,00 %
```

---

## B2

El 165,00 % aparece porque se comparan 77 550 kilos cosechados contra una meta de 47 000 kilos.

---

## B3

| Filtros | Kilos | Meta | Cumplimiento |
|----------|----------:|----------:|----------:|
| Ninguno | 77550 | 47000 | 165,00 % |
| anio = 2026 | 30550 | 47000 | 65,00 % |
| anio = 2026, mes = 1–4 | 30550 | 24440 | 125,00 % |

---

## B4

Sí, describen la misma situación desde enfoques distintos.

La clase 16 comparaba contra el año anterior y la clase 17 compara contra una meta.

---

## B5

No es un error.

No existen metas registradas para 2025, por lo que las medidas relacionadas con la meta aparecen vacías.

---

# Parte C · Por finca, que sí funciona

## C1

| Finca | Kilos | Meta | Cumplimiento |
|---------|---------:|---------:|---------:|
| Agricola La Union | 2100 | 5000 | 42,00 % |
| Finca El Guayabo | 14250 | 9440 | 150,95 % |
| Hacienda Santa Rosa | 14200 | 10000 | 142,00 % |
| Total | 30550 | 24440 | 125,00 % |

---

## C2

La suma de las metas de las tres fincas da 24 440 kilos y coincide con el total de la columna Meta.

---

## C3

El total de 125,00 % oculta que Agricola La Union está por debajo de su meta, mientras las otras dos fincas la superan ampliamente.

---

# Parte D · La trampa del día

## D1

| Cultivo | Kilos | Meta | Cumplimiento |
|---------|---------:|---------:|---------:|
| Banano | (vacío) | 24440 | (vacío) |
| Cacao | 2100 | 24440 | 8,59 % |
| Cafe | (vacío) | 24440 | (vacío) |
| Guayaba | 5950 | 24440 | 24,35 % |
| Maiz | 9800 | 24440 | 40,10 % |
| Mango | 12700 | 24440 | 51,96 % |
| Total | 30550 | 24440 | 125,00 % |

---

## D2

Power BI no mostró ningún mensaje de error.

---

## D3

Banano y Cafe aparecen porque la meta no está relacionada con cultivo.

Al usar cultivo en las filas, Power BI repite la meta completa porque no existe ninguna relación que permita repartirla entre cultivos.

---

## D4

```text
51,96
+24,35
+40,10
+8,59
-------
125,00
```

La suma de los porcentajes coincide exactamente con el total.

---

## D5

La suma de la columna Meta da:

```text
146640
```

Sin embargo, la empresa realmente se propuso cosechar:

```text
47000
```

La meta se repite en cada fila de cultivo.

---

## D6 · Filas de meta

```DAX
Filas de meta =
COUNTROWS(h_meta)
```

Resultado:

| Cultivo | Cosechas | Filas de meta |
|---------|---------:|---------:|
| Banano | (vacío) | 12 |
| Cacao | 2 | 12 |
| Cafe | (vacío) | 12 |
| Guayaba | 3 | 12 |
| Maiz | 1 | 12 |
| Mango | 3 | 12 |
| Total | 9 | 12 |

---

## D7

Si una medida devuelve exactamente el mismo valor en todas las filas y también en el total, esa dimensión no está llegando a la tabla de hechos utilizada por la medida.

---

## D8

Ese modelo estaría afirmando incorrectamente que la meta puede distribuirse por cultivo aunque nunca fue capturada a ese nivel de detalle.

---

# Parte E · El otro lado de la granularidad

## E1

| Día | Kilos | Meta |
|---------|---------:|---------:|
| 01/03/2026 | (vacío) | 6900 |
| 20/03/2026 | 4200 | (vacío) |
| 22/03/2026 | 5400 | (vacío) |
| 28/03/2026 | 1200 | (vacío) |
| Total | 10800 | 6900 |

---

## E2

La meta aparece el día 1 porque la columna `fecha_mes` almacena el primer día de cada mes para representar una meta mensual.

---

## E3

La medida puede interpretarse correctamente a nivel mensual o superior.

No puede interpretarse correctamente a nivel diario porque la meta fue capturada por mes y no por día.

---

# Parte F · La medida que se calla

## F1 · Meta valida

```DAX
Meta valida =
IF(
    ISFILTERED(dim_cultivo[cultivo]) ||
    ISFILTERED(dim_tiempo[fecha]),
    BLANK(),
    [Meta]
)
```

Resultado:

La medida devuelve vacío cuando la consulta se realiza por cultivo o por fecha.

---

## F1 · Cumplimiento valido

```DAX
Cumplimiento valido =
DIVIDE(
    [Kilos],
    [Meta valida]
)
```

---

## F2

| Cultivo | Kilos | Meta valida | Cumplimiento valido |
|---------|---------:|---------:|---------:|
| Cacao | 2100 | (vacío) | (vacío) |
| Guayaba | 5950 | (vacío) | (vacío) |
| Maiz | 9800 | (vacío) | (vacío) |
| Mango | 12700 | (vacío) | (vacío) |
| Total | 30550 | 24440 | 125,00 % |

---

## F3

El total sí responde porque en la fila Total no existe un filtro activo sobre cultivo.

Las filas individuales sí filtran por cultivo y por eso la medida devuelve BLANK().

---

## F4

| Finca | Kilos | Meta valida | Cumplimiento valido |
|---------|---------:|---------:|---------:|
| Agricola La Union | 2100 | 5000 | 42,00 % |
| Finca El Guayabo | 14250 | 9440 | 150,95 % |
| Hacienda Santa Rosa | 14200 | 10000 | 142,00 % |
| Total | 30550 | 24440 | 125,00 % |

La medida sigue funcionando correctamente por finca.

---

## F5

Sí, está bien que se vacíe.

La meta fue capturada por finca y no por cultivo. Mostrar un valor bajo un filtro de cultivo sería engañoso.

---

# Parte G · Preguntas de cierre

## G1

Una medida solo debe interpretarse al nivel de detalle en que fue capturado el hecho o a un nivel superior.

---

## G2

En la parte E el problema apareció porque la meta mensual fue llevada a nivel diario.

En la parte D Power BI seguía mostrando un número aparentemente válido y fue necesario programar la restricción mediante BLANK().

---

## G3

La medida `Filas de meta` habría dado la misma pista, porque devolvía exactamente el mismo valor en todas las filas y en el total.

---

## G4

Si `h_meta` tuviera una columna `cultivo_id` real, `Meta valida` ya no necesitaría bloquear
