# Ejercicio28_Herrera_Brando.md

# Parte A · El modelo

## A0

Configuración regional:

```text
Español (México)
```

---

## Relaciones

```text
h_cosecha[finca_id]    -> dim_finca[finca_id]
h_cosecha[cultivo_id]  -> dim_cultivo[cultivo_id]
h_cosecha[fecha]       -> dim_tiempo[fecha]

h_meta[finca_id]       -> dim_finca[finca_id]
h_meta[fecha_mes]      -> dim_tiempo[fecha]
```

```text
precios
```

no tiene relaciones.

---

## Medidas

```DAX
Kilos =
SUM( h_cosecha[kg] )
```

Resultado:

```text
30550
```

---

```DAX
Meta =
SUM( h_meta[kg_meta] )
```

Resultado:

```text
24440
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

```DAX
Cosechas =
COUNTROWS(
    h_cosecha
)
```

Resultado:

```text
9
```

---

```DAX
Filas repetidas =
COUNTROWS( h_cosecha )
-
DISTINCTCOUNT( h_cosecha[cosecha_id] )
```

Resultado inicial:

```text
0
```

---

## A4

| Finca | Kilos | Meta | Cumplimiento | Cosechas |
|---------|---------:|---------:|---------:|---------:|
| Agrícola La Unión | 2100 | 5000 | 42,00 % | 2 |
| Finca El Guayabo | 14250 | 9440 | 150,95 % | 3 |
| Hacienda Santa Rosa | 14200 | 10000 | 142,00 % | 4 |
| Total | 30550 | 24440 | 125,00 % | 9 |

```text
Filas repetidas = 0
```

---

## A5

Para encontrar un único precio se necesitan:

```text
cultivo_id
+
calidad
```

---

# Parte B · La combinación obvia

## B1

Filas iniciales de h_cosecha:

```text
25
```

---

## B2

Combinación realizada:

```text
h_cosecha[cultivo_id]
↔
precios[cultivo_id]
```

Tipo:

```text
Externa izquierda
```

---

## B3

Se expandió únicamente:

```text
precio_kg
```

---

## Medidas

```DAX
Ingresos =
SUMX(
    h_cosecha,
    h_cosecha[precio_kg] * h_cosecha[kg]
)
```

---

```DAX
Precio por kilo =
DIVIDE(
    [Ingresos],
    [Kilos]
)
```

---

## B5

| Finca | Ingresos |
|---------|---------:|
| Agrícola La Unión | 9030 |
| Finca El Guayabo | 7390 |
| Hacienda Santa Rosa | 11660 |
| Total | 28080 |

```text
Precio por kilo = 0,55
```

---

## B6

Sí.

El precio promedio parecía razonable, pero los ingresos y el número de cosechas aumentaron demasiado respecto al modelo original. Eso indicaba que la combinación había duplicado registros.

---

# Parte C · El número que no debía moverse

## C1

Tabla de control:

```text
Kilos          51300
Meta           24440
Cumplimiento   209,90 %
Cosechas       17
```

```text
Filas repetidas = 8
```

---

## C2

Filas en Power Query:

```text
46
```

---

## C3

Distribución de:

```text
cosecha_id
```

Resultado:

```text
25 distintos
4 únicos
```

---

## C4

Para:

```text
cosecha_id = 2
```

aparecieron dos filas con dos precios distintos:

```text
0,50
0,30
```

El precio correcto es:

```text
0,30
```

porque la cosecha tiene calidad:

```text
segunda
```

---

## C5

Las cuatro cosechas únicas fueron las asociadas a cultivos que tenían un único precio posible en la tabla de precios.

Por eso no se duplicaron.

---

## C6

El indicador:

```text
25 de 25
```

solo cuenta si existe coincidencia.

No verifica que exista una única coincidencia.

---

## C7

Los ingresos aumentaron mucho porque varias cosechas se duplicaron.

El precio promedio apenas cambió porque tanto el numerador como el denominador crecieron al mismo tiempo.

---

# Parte D · El segundo arreglo obvio

## D1

Se aplicó:

```text
Quitar duplicados
```

sobre:

```text
cosecha_id
```

---

## D2

Pruebas:

### Filas en Power Query

```text
25
```

### Tabla de control

```text
Kilos          30550
Meta           24440
Cumplimiento   125,00 %
Cosechas       9
```

### Filas repetidas

```text
0
```

---

## D3

| Finca | Ingresos |
|---------|---------:|
| Agrícola La Unión | 5250 |
| Finca El Guayabo | 5610 |
| Hacienda Santa Rosa | 7250 |
| Total | 18110 |

---

## D4

| cosecha_id | Cultivo | Calidad | Kg | Precio | Ingreso |
|------------|----------|----------|------:|------:|------:|
| 1 | Mango | primera | 4200 | 0,50 | 2100 |
| 2 | Mango | segunda | 3100 | 0,30 | 930 |
| 3 | Mango | primera | 5400 | 0,50 | 2700 |
| 4 | Guayaba | primera | 1500 | 0,60 | 900 |
| 5 | Guayaba | primera | 2600 | 0,60 | 1560 |
| 6 | Guayaba | segunda | 1850 | 0,40 | 740 |
| 7 | Maíz | primera | 9800 | 0,30 | 2940 |
| 8 | Cacao | primera | 1200 | 2,50 | 3000 |
| 9 | Cacao | primera | 900 | 2,50 | 2250 |
| **Total** | | | **30550** | | **17120** |

---

## D5

La diferencia es:

```text
18110 - 17120 = 990
```

La explican las cosechas cobradas con precio de primera cuando correspondía precio de segunda.

---

## D6

```text
Quitar duplicados eliminó filas repetidas sin verificar cuál contenía el precio correcto.
```

Power Query conservó la primera fila encontrada.

---

# Parte E · La llave completa

## E1

Se eliminaron los pasos:

```text
Duplicados quitados
Se expandió precios
Consultas combinadas
```

---

## E2

Nueva combinación:

```text
cultivo_id
+
calidad
```

---

## E3

Resultado:

```text
25 filas
25 distintos
25 únicos
```

---

## E4

Tabla de control:

```text
Kilos          30550
Meta           24440
Cumplimiento   125,00 %
Cosechas       9
```

```text
Filas repetidas = 0
```

---

## E5

| Finca | Ingresos |
|---------|---------:|
| Agrícola La Unión | 5250 |
| Finca El Guayabo | 5240 |
| Hacienda Santa Rosa | 6630 |
| Total | 17120 |

```text
Precio por kilo = 0,56
```

```text
Filas repetidas = 0
```

---

## E6

| Cultivo | Ingresos |
|----------|---------:|
| Mango | 5730 |
| Guayaba | 3200 |
| Cacao | 5250 |
| Maíz | 2940 |

El único cultivo que dio el mismo resultado fue:

```text
Maíz
```

porque solo tenía un precio posible.

---

## E7

La llave de:

```text
precios
```

es:

```text
cultivo_id
+
calidad
```

---

# Parte F · Quién avisa

## F1

Fórmula:

```DAX
Precio incompleto =
LOOKUPVALUE(
    precios[precio_kg],
    precios[cultivo_id],
    [cultivo_id]
)
```

Error:

```text
Se proporcionó una tabla de varios valores donde se esperaba un solo valor.
```

Explicación:

```text
Un cultivo puede tener más de un precio, por lo que cultivo_id no identifica un registro único.
```

---

## F2

```DAX
Precio buscado =
LOOKUPVALUE(
    precios[precio_kg],
    precios[cultivo_id], [cultivo_id],
    precios[calidad], [calidad]
)
```

---

```DAX
Diferencia de precio =
SUMX(
    h_cosecha,
    ABS(
        h_cosecha[precio_kg]
        -
        h_cosecha[Precio buscado]
    )
)
```

Resultado:

```text
0
```

---

## F3

Cardinalidad propuesta:

```text
Muchos a muchos
```

Power BI advierte que existen múltiples valores coincidentes en ambos lados.

---

## F4

### 1

```text
Anexar agrega filas; Combinar agrega columnas.
```

### 2

```text
Si al cargar datos nuevos cambia un número viejo, la llave utilizada probablemente no identifica un registro único.
```

### 3

```text
Quitar errores y Quitar duplicados eliminan síntomas sin resolver la causa.

Quitar duplicados es más peligroso porque puede conservar datos incorrectos sin mostrar ningún error.
```

### 4

```text
La tabla precios actuó como la tabla con múltiples filas por llave.
```

### 5

```text
La combinación debería utilizar cultivo_id, calidad y mes.

La primera prueba sería verificar que el número de filas siga siendo 25 y que Filas repetidas continúe en 0.
```
