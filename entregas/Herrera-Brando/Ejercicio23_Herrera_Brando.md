# Ejercicio 23 · Herrera Brando

# Parte A · Las dos tablas

## A1 · Segmentadores

Configuración utilizada durante toda la práctica:

```text
anio = 2026
mes = 1,2,3,4
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

## A3 · Tabla por cultivo

| Cultivo | Kilos |
|---------|---------:|
| Mango | 12700 |
| Maiz | 9800 |
| Guayaba | 5950 |
| Cacao | 2100 |

---

# Parte B · Degradado y reglas

## B1 · Degradado

Formato aplicado:

```text
Color de fondo
→ Degradado
→ Blanco (mínimo)
→ Verde (máximo)
```

### B1a

Resultado:

```text
Cultivo más oscuro: Mango
Cultivo más claro: Cacao
```

### B1b

Maiz:

```text
(9800 - 2100) / (12700 - 2100)

= 7700 / 10600

= 0,7264

= 72,64 %
```

Guayaba:

```text
(5950 - 2100) / (12700 - 2100)

= 3850 / 10600

= 0,3632

= 36,32 %
```

---

## B2 · Regla de 5000 kilos

| Si el valor | y | Tipo | Color |
|---|---|---|---|
| >= 0 | < 5000 | Número | Rojo |
| >= 5000 | <= 100000 | Número | Verde |

Resultado:

```text
Mango     Verde
Maiz      Verde
Guayaba   Verde
Cacao     Rojo
```

---

## B3

Un cultivo con 150000 kilos no tendría color porque supera el límite superior de 100000 definido en las reglas.

---

# Parte C · Verde si cumple

## C1 · Regla con Porcentaje

Regla intentada:

| Si el valor | y | Tipo | Color |
|---|---|---|---|
| >= 0 | < 100 | Porcentaje | Rojo |
| >= 100 | <= 200 | Porcentaje | Verde |

---

## C2

Power BI mostró un error de validación al intentar configurar la segunda regla con tipo Porcentaje.

Mi versión de Power BI no permitió reproducir exactamente el comportamiento mostrado en el enunciado.

---

## C3

Sí, Hacienda Santa Rosa cumplió la meta porque tiene un cumplimiento de 142,00 %.

Debería aparecer en verde, pero la prueba demuestra que las reglas con porcentaje pueden producir resultados engañosos.

---

## C4a

Cálculo del porcentaje del rango de Santa Rosa:

```text
(142,00 - 42,00)
/
(150,95 - 42,00)

= 100 / 108,95

= 0,9178

= 91,78 %
```

---

## C5

La regla estaba comparando contra el porcentaje del rango visible y no contra el valor real de cumplimiento.

Por eso podía pintar resultados diferentes aunque una finca estuviera por encima del 100 %.

---

## C6

Con el filtro tipo = perenne:

```text
Agricola La Union = Rojo
Finca El Guayabo = Rojo
Hacienda Santa Rosa = Verde
```

---

## C7

El cumplimiento de Santa Rosa no cambió.

Lo que cambió fue el rango visible utilizado por la regla de formato condicional.

---

## C8

Con tipo Número y valores:

```text
0
100
200
```

los resultados dejan de representar porcentajes reales de cumplimiento.

Internamente 142,00 % equivale a 1,42 y no a 142.

---

# Parte D · El color como medida

## D1 · Regla correcta con Número

| Si el valor | y | Tipo | Color |
|---|---|---|---|
| >= 0 | < 1 | Número | Rojo |
| >= 1 | <= 2 | Número | Verde |

Resultado:

```text
Agricola La Union     Rojo
Finca El Guayabo      Verde
Hacienda Santa Rosa   Verde
Total                 Verde
```

### D1a

Una finca con 250 % quedaría fuera de la segunda regla porque:

```text
250 % = 2,50
```

y supera el límite superior de 2.

---

## D2 · Medida de color

```DAX
Color cumplimiento =
IF(
    [Cumplimiento] >= 1,
    "#1E8449",
    "#C0392B"
)
```

Resultado:

| Finca | Cumplimiento | Color |
|---------|---------:|---------|
| Agricola La Union | 42,00 % | Rojo |
| Finca El Guayabo | 150,95 % | Verde |
| Hacienda Santa Rosa | 142,00 % | Verde |
| Total | 125,00 % | Verde |

---

## D3

Con tipo = perenne:

```text
Santa Rosa no cambió de color.
```

El color depende directamente del valor de la medida y no del rango visible.

---

## D4

La medida es preferible porque utiliza la regla real de negocio.

También puede reutilizarse en otros objetos visuales sin depender de cómo se vean los datos en pantalla.

---

# Parte E · Tarjeta, medidor y KPI

## E1 · Tarjeta

```text
[Kilos] = 30 550
```

---

## E2 · Medidor

```DAX
Tope del medidor =
[Meta] * 1.5
```

Resultado:

| Valor | Resultado |
|---------|---------:|
| Valor del medidor | 30550 |
| Aguja de la meta | 24440 |
| Máximo sin Tope del medidor | 61100 |
| Máximo con Tope del medidor | 36660 |

---

## E3 · KPI

Configuración:

```text
Valor = [Kilos]
Eje de tendencia = dim_tiempo[nombre_mes]
Destino = [Meta]
```

Resultado:

| Elemento | Valor |
|---------|---------|
| Número grande | 19750 |
| Objetivo | 8300 |
| Distancia | +137,95 % |
| Color | Verde |

---

## E4

Power BI no mostró ningún error ni advertencia.

El KPI muestra el último valor del eje de tendencia y no el total del período.

---

## E5 · Tabla por mes

| Mes | Kilos | Meta |
|---------|---------:|---------:|
| Enero | (vacío) | 4040 |
| Febrero | (vacío) | 5200 |
| Marzo | 10800 | 6900 |
| Abril | 19750 | 8300 |
| Total | 30550 | 24440 |

---

## E6

El KPI muestra el último punto disponible del eje de tendencia.

El valor 19750 corresponde al mes de abril, que es el último mes visible.

---

# Parte F · El KPI del año

## F1 · Medidas YTD

```DAX
Kilos YTD =
TOTALYTD(
    [Kilos],
    dim_tiempo[fecha]
)
```

```DAX
Meta YTD =
TOTALYTD(
    [Meta],
    dim_tiempo[fecha]
)
```

Resultado:

| KPI del mes | KPI del año |
|---------|---------|
| 19750 | 30550 |
| 8300 | 24440 |
| +137,95 % | +25,00 % |

---

## F2

A fin de marzo:

```text
Kilos YTD = 10800
Meta YTD = 16140
Distancia = -33,09 %
```

---

## F3

Seleccionando Agricola La Union:

```text
Kilos YTD = 2100
Meta YTD = 5000
Distancia = -58,00 %
```

---

## F4

Títulos utilizados:

```text
KPI del último mes
```

```text
KPI acumulado del año
```

---

# Parte G · Preguntas de cierre

## G1

Una regla con tipo Porcentaje compara contra la posición relativa dentro del rango visible. Un degradado también utiliza el mínimo y el máximo visibles para repartir los colores.

---

## G2

El objeto visual KPI muestra el último valor disponible del eje de tendencia.

---

## G3

Si un color cambia aunque el valor no cambie, la regla está comparando contra el rango visible y no contra el valor real.

---

## G4

Es una regla relativa porque compara contra el promedio del grupo.

Aunque todos mejoren sus ventas, seguirán existiendo vendedores por debajo del promedio.

---

## G5

El porcentaje del rango es útil cuando se desea 