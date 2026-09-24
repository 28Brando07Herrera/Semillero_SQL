# Ejercicio26_Herrera_Brando.md

# Parte A · El modelo

## A1a

La columna:

```text
h_cosecha[fecha_entrega]
```

quedó con tipo:

```text
Fecha
```

No fue necesario modificarla.

---

## Medidas

```DAX
Kilos =
SUM( h_cosecha[kg] )
```

Resultado:

```text
30 550
```

---

```DAX
Meta =
SUM( h_meta[kg_meta] )
```

Resultado:

```text
24 440
```

---

```DAX
Cumplimiento =
DIVIDE(
    [Kilos],
    [Meta]
)
```

Resultado:

```text
125,00 %
```

---

## Tabla de control

| Finca | Kilos | Meta | Cumplimiento |
|---|---:|---:|---:|
| Agrícola La Unión | 2100 | 5000 | 42,00 % |
| Finca El Guayabo | 14250 | 9440 | 150,95 % |
| Hacienda Santa Rosa | 14200 | 10000 | 142,00 % |
| Total | 30550 | 24440 | 125,00 % |

---

# Parte B · La segunda relación

## B2

La relación nueva aparece como:

```text
Línea punteada (inactiva)
```

mientras que la relación entre:

```text
h_cosecha[fecha]
```

y

```text
dim_tiempo[fecha]
```

permanece continua (activa).

---

## B3

Relaciones entre:

```text
h_cosecha
```

y

```text
dim_tiempo
```

```text
h_cosecha[fecha]
→ dim_tiempo[fecha]
ACTIVA
```

```text
h_cosecha[fecha_entrega]
→ dim_tiempo[fecha]
INACTIVA
```

---

## B4

Power BI no permite ambas relaciones activas al mismo tiempo porque existirían dos caminos de filtrado entre las mismas tablas y el filtro de fechas sería ambiguo.

Con:

```text
mes = abril
```

Power BI no sabría si filtrar por fecha de cosecha o por fecha de entrega.

---

# Parte C · La medida obvia

## C1

```DAX
Kilos entregados =
SUM( h_cosecha[kg] )
```

---

## C2

Resultado:

| Mes | Kilos | Kilos entregados |
|---|---:|---:|
| Marzo | 10800 | 10800 |
| Abril | 19750 | 19750 |
| Total | 30550 | 30550 |

---

## C3

La cosecha:

```text
cosecha_id = 7
```

corresponde al maíz de:

```text
30 de abril
```

pero fue entregada posteriormente.

Sin embargo:

```text
[Kilos entregados]
```

la sigue contando en abril porque la medida continúa usando la relación activa basada en:

```text
h_cosecha[fecha]
```

---

## C4

Power BI no mostró ningún error.

La medida no utiliza:

```text
fecha_entrega
```

porque la relación correspondiente está inactiva y los filtros siguen viajando por la relación activa.

---

# Parte D · USERELATIONSHIP

## D1

```DAX
Kilos entregados =
CALCULATE(
    [Kilos],
    USERELATIONSHIP(
        h_cosecha[fecha_entrega],
        dim_tiempo[fecha]
    )
)
```

---

## D2

| Mes | Kilos | Kilos entregados |
|---|---:|---:|
| Enero | | 1200 |
| Marzo | 10800 | 9600 |
| Abril | 19750 | 10250 |
| Total | 30550 | 21050 |

---

## D3

Los:

```text
1200 kg
```

de enero corresponden a una cosecha cortada durante el año anterior y entregada en:

```text
enero de 2026
```

Para:

```text
[Kilos]
```

cuenta según la fecha de cosecha.

Para:

```text
[Kilos entregados]
```

cuenta según la fecha de entrega.

---

## D4

Los:

```text
9500 kg
```

de diferencia aparecen porque varias cosechas que fueron cortadas entre marzo y abril se entregan después de abril.

Además entra una cosecha entregada en enero que fue cortada antes.

Por eso:

```text
30550
-
21050
=
9500
```

---

## D5

Quitando el filtro de mes:

| Medida | Resultado |
|---|---:|
| Kilos | 30550 |
| Kilos entregados | 31750 |

Aparece:

```text
Mayo
```

con:

```text
10700 kg
```

entregados.

Luego se volvió a aplicar el filtro:

```text
Mes = 1,2,3,4
```

---

## D6

Tabla por finca:

| Finca | Kilos | Meta | Cumplimiento | Kilos entregados |
|---|---:|---:|---:|---:|
| Agrícola La Unión | 2100 | 5000 | 42,00 % | 2400 |
| Finca El Guayabo | 14250 | 9440 | 150,95 % | 4450 |
| Hacienda Santa Rosa | 14200 | 10000 | 142,00 % | 14200 |

Observación:

```text
[Kilos] no cambió.
```

```text
[Cumplimiento] no cambió.
```

Solo cambió:

```text
[Kilos entregados]
```

porque usa una relación distinta.

---

# Parte E · ¿Y si activo la otra?

## E2

| Finca | Kilos | Meta | Cumplimiento |
|---|---:|---:|---:|
| Agrícola La Unión | 2400 | 5000 | 48,00 % |
| Finca El Guayabo | 4450 | 9440 | 47,14 % |
| Hacienda Santa Rosa | 14200 | 10000 | 142,00 % |
| Total | 21050 | 24440 | 86,13 % |

---

## E3

El Guayabo baja porque su cosecha grande:

```text
cosecha_id = 7
```

ya no cuenta dentro del período enero-abril cuando los filtros usan:

```text
fecha_entrega
```

en lugar de:

```text
fecha
```

---

## E4

La medida:

```text
[Meta]
```

no cambió porque sigue utilizando:

```text
h_meta[fecha_mes]
```

y su relación con:

```text
dim_tiempo
```

permanece exactamente igual.

---

## E5

Se restauró la relación activa original:

```text
h_cosecha[fecha]
→ dim_tiempo[fecha]
```

El total volvió a:

```text
125,00 %
```

---

## E6

También cambiarían automáticamente:

```text
El semáforo de cumplimiento.
```

```text
El KPI acumulado del año.
```

porque ambos dependen de medidas filtradas por fecha.

---

# Parte F · Días a la entrega

## F1

```DAX
Dias a la entrega =
AVERAGEX(
    h_cosecha,
    DATEDIFF(
        h_cosecha[fecha],
        h_cosecha[fecha_entrega],
        DAY
    )
)
```

Resultado:

```text
8,67
```

---

## F2

| Cultivo | Dias a la entrega |
|---|---:|
| Mango | 2,00 |
| Guayaba | 2,00 |
| Maiz | 12,00 |
| Cacao | 27,00 |
| Total | 8,67 |

---

## F3

El total:

```text
8,67
```

no es el promedio simple de los cuatro cultivos.

La medida promedia todas las filas de:

```text
h_cosecha
```

y no los cuatro resultados visibles de la tabla.

---

## F4

DATEDIFF no utiliza relaciones.

Sin embargo el segmentador de mes sí cambia el resultado porque filtra previamente las filas de:

```text
h_cosecha
```

mediante la relación activa basada en:

```text
fecha
```

---

# Parte G · Preguntas de cierre

## G1

Una relación inactiva no participa en los filtros del modelo hasta que una medida la activa explícitamente.

---

## G2

Conviene cambiar la relación activa cuando toda la página debe trabajar con la segunda fecha.

Conviene usar:

```text
USERELATIONSHIP
```

cuando únicamente una medida requiere esa fecha alternativa.

---

## G3

Regla de detección:

```text
Si dos medidas dan exactamente el mismo resultado aunque deberían usar fechas distintas, probablemente ambas siguen filtrando por la misma relación activa.
```

---

## G4

Primero revisaría cuál relación entre:

```text
fecha_solicitud
```

y

```text
fecha_aprobacion
```

está activa.

Después verificaría qué fecha usa cada medida del tablero.

---

## G5

La meta utiliza:

```text
h_meta[fecha_mes]
```

No tendría sentido reutilizar exactamente la misma meta para entregas porque la fecha de entrega puede ocurrir en un período diferente al de la cosecha.