# Ejercicio 15 · Verdezoto Leon

## Parte A · La estrella, sin Oracle

#### A2. Todos los datos cargaron con sus tipos correctos en mi máquina (kg como número entero y las fechas como tipo Fecha).

#### A3. Power BI adivinó automáticamente las 3 relaciones.

## Parte B · Tus primeras medidas

### B1 · Kilos

```
Kilos = SUM(h_cosecha[kg])
```
Resultado: 30550

## B2 · Cosechas

```
Cosechas = COUNTROWS(h_cosecha)
```
Resultado: 9

## B3 · Punto de control 2

|       Finca         |  Kilos  | Cosechas |
| ------------------- | ------- | -------- |
| Finca El Guayabo    |  14 250 |    3     |
| Hacienda Santa Rosa | 14 200  |    4     |
| Agricola La Union   | 2 100   |    2     |
| Total               | 30 550  |    9     |

B4. No, el total de una tabla en Power BI no es siempre la suma de las filas de arriba. El total evalúa la medida sobre el contexto global (sin el filtro de la fila) y no realiza una simple suma aritmética de los resultados individuales.

# Parte C · Medida contra columna calculada
## C1 · Columna calculada

```
tamano = IF( h_cosecha[kg] >= 3000, "grande", "chica" )
```

Tabla de resultado:

|       tamano        |  Kilos | Cosechas |
| ------------------- | ------ | -------- |
| Grande              | 22 550 |    4     |
| Chica               |  8 050 |    5     |
| Total               | 30 550 |    9     |

# C2 · Columna vs. Medida

```
pct_columna = h_cosecha[kg] / SUM(h_cosecha[kg])
```

```
Pct medida = DIVIDE( [Kilos] , CALCULATE( [Kilos] , ALL(h_cosecha) ) )
```

Sin filtros aplicados, ambas muestran exactamente los mismos valores para cada fila.

# C3 · Punto de control 4 (Con segmentador en Agricola La Union)

|       Cosechas         | pct_columna | [Pct medida] |
| -------------------    | ----------- | ------------ |
| Cosechas 8             |    3,93 %   |    57,14 %   |
| Cosechas 9             |    2,95 %   |    42,86 %   |
| Total                  |    6,87 %   |    100,00 %  |

C4. La columna calculada se evaluó de forma estática durante la carga de datos dividiendo entre los 30 550 kg totales del modelo sin importar la selección. La medida se recalcula dinámicamente según el contexto de filtro actual del segmentador (2 100 kg).

C5. La [Pct medida] responde a la pregunta «qué parte de esta finca aporta cada cosecha», mientras que pct_columna contesta qué parte representa cada cosecha respecto al total general de todas las fincas.

# Parte D · Contexto de filtro
## D1 · Pct mal

```
Pct mal = DIVIDE( [Kilos] , [Kilos] )
```
|       Finca         |  Kilos | Pct mal  |
| ------------------- | ------ | -------- |
| Finca El Guayabo    | 14 250 | 100,00 % |
| Hacienda Santa Rosa | 14 200 | 100,00 % |
| Agricola La Union   | 2 100  | 100,00 % |
| Total               | 30 550 | 100,00 % |

D2. En DAX, ambos términos de la división evalúan la medida [Kilos] bajo el mismo contexto de filtro de la fila actual, por lo que dividen exactamente la misma cifra entre sí misma en cada linea.

## D3 · Pct del total

```
Pct del total = DIVIDE( [Kilos] , CALCULATE( [Kilos] , ALL(dim_finca) ) )
```

|        Finca        |  Kilos | Pct del total |
| ------------------- | ------ | ------------- |
|   Finca El Guayabo  | 14 250 |    "46,64 %"  |
| Hacienda Santa Rosa | 14 200 |   "46,48 %"   |
|  Agricola La Union  | 2 100  |   "6,87 %"    |
| Total               | 30 550 |   "100,00 %"  |

D4. Al usar ALL(dim_cultivo), solo se remueven los filtros aplicados sobre la dimensión de cultivos, de modo que el filtro de la dimensión dim_finca permanece intacto y la división sigue siendo contra el total de esa misma finca (100 %).

# Parte E · La trampa del día
## E1 · Promedio por cultivo MAL

```
Promedio por cultivo MAL = DIVIDE( [Kilos] , COUNTROWS(dim_cultivo) )
```

Resultado en tarjeta: 5 091,67E2. Power BI no arrojó ningún mensaje de error; el cálculo se ejecutó silenciosamente arrojando un resultado lógicamente incorrecto.E3. Dividió los 30 550 kg totales entre las 6 filas totales que existen en la tabla dim_cultivo ($30550 / 6 = 5091.666...$).

## E4 · Denominadores a pantalla

```
Cultivos en la dimension = COUNTROWS(dim_cultivo)
```
Resultado: 6

```
Cultivos con cosecha = DISTINCTCOUNT(h_cosecha[cultivo_id])
```
Resultado: 4

E5. Los dos cultivos que sobran son Banano (id 4) y Cafe (id 6). Están en dim_cultivo porque forman parte del catálogo maestro de cultivos de la empresa, aunque en este periodo no registraron cosechas.

## E6 · Promedio por cultivo (Correcto)

```
Promedio por cultivo = DIVIDE( [Kilos] , DISTINCTCOUNT(h_cosecha[cultivo_id]) )
```

Resultado en tarjeta: 7 637,50

# E7 · Con segmentador en tipo = perenne

|            Medida        |    Valor   |
| ------------------------ | ---------- |
|           [Kilos]        |    20 750  |
| Cultivos en la dimensión |      5     |
|   Cultivos con cosecha   |      3     |
| Promedio por cultivo MAL | "4 150,00" |
|   Promedio por cultivo   | "6 916,67" |

E8. La medida mala cuenta todas las filas presentes en la dimensión dim_cultivo bajo el filtro actual (5 cultivos perennes en catálogo), en lugar de contar únicamente los cultivos que efectivamente tuvieron registros de cosecha en la tabla de hechos (3 cultivos).

E9. Deja de estar bien cuando realizamos divisiones o promedios utilizando como denominador el conteo total de filas de una dimensión en lugar de contar los elementos únicos realmente referenciados en la tabla de hechos.

# Parte F · Preguntas de cierre
Una columna calculada se procesa estáticamente durante la carga/actualización del modelo consumiendo RAM, mientras que una medida se calcula dinámicamente en tiempo real al interactuar con el reporte según el contexto de filtro.

1. La fila del total no suma los valores superiores, sino que evalúa la fórmula DAX sobre todo el conjunto de datos global sin el filtro individual de la fila.

2. ALL(dim_finca) significa ignorar o remover cualquier filtro activo que provenga de la tabla dim_finca al evaluar la expresión.

3. Tienen en común que son errores lógicos y silenciosos que entregan un número coherente a simple vista sin lanzar advertencias o fallos del sistema.

4. Confirma la independencia de la capa de modelado y DAX frente al origen de datos; si hubiéramos usado una vista plana (v_bi_produccion), habríamos perdido la estructura en estrella y sufrido redundancia o errores al intentar filtrar dimensiones.