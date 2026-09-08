# Ejercicio Práctico 15 · Escribe las medidas, y rompe el promedio a propósito

## Parte A · La estrella, sin Oracle

* **A2. Tipos de datos:** Los cuatro CSV cargaron con sus tipos correctos en mi máquina (`kg` como número entero y los campos de `fecha` como tipo Fecha). No hizo falta corregir tipos en Power Query.
* **A3 / Punto de control 1:** Se verificaron las 3 relaciones de muchos a uno simples apuntando hacia las dimensiones (`dim_finca`, `dim_cultivo` y `dim_tiempo`). Se aseguraron manualmente las conexiones desde las llaves foráneas de `h_cosecha` hacia las llaves primarias de cada dimensión.

---

## Parte B · Tus primeras medidas

### B1 · Kilos

```dax
Kilos = SUM(h_cosecha[kg])
```
* **Resultado:** 30 550

### B2 · Cosechas

```dax
Cosechas = COUNTROWS(h_cosecha)
```
* **Resultado:** 9

### B3 · Tabla por Finca (Punto de control 2)

| Finca | Kilos | Cosechas |
| :--- | :--- | :--- |
| Finca El Guayabo | 14 250 | 3 |
| Hacienda Santa Rosa | 14 200 | 4 |
| Agricola La Union | 2 100 | 2 |
| **Total** | **30 550** | **9** |

### B4 · ¿El total de una tabla es siempre la suma de las filas de arriba?
No siempre. En Power BI el total no es una sumatoria visual de las celdas superiores, sino una evaluación independiente de la medida sobre un contexto de filtro sin segmentar (el total de filas evaluado de golpe).

---

## Parte C · Medida contra columna calculada

### C1 · Columna calculada tamano

```dax
tamano = IF( h_cosecha[kg] >= 3000, "grande", "chica" )
```

* **grande:** 22 500 Kilos | 4 Cosechas
* **chica:** 8 050 Kilos | 5 Cosechas
* **Total:** 30 550 Kilos | 9 Cosechas

### C2 · Columna vs Medida sin filtro

```dax
pct_columna = h_cosecha[kg] / SUM(h_cosecha[kg])
```

```dax
Pct medida = DIVIDE( [Kilos] , CALCULATE( [Kilos] , ALL(h_cosecha) ) )
```

Sin ningún filtro aplicado, ambas columnas muestran exactamente los mismos valores porcentuales fila por fila.

### C3 · Con Segmentador en Agricola La Union (Punto de control 4)

| Cosecha | pct_columna | Pct medida |
| :--- | :--- | :--- |
| cosecha 8 | 3,93 % | 57,14 % |
| cosecha 9 | 2,95 % | 42,86 % |
| **Total** | **6,87 %** | **100,00 %** |

### C4 · ¿Por qué la columna dividió entre 30 550 y la medida entre 2 100?
La columna calculada se evaluó una sola vez durante la carga del modelo (congelando el denominador en los 30 550 kg totales), mientras que la medida es dinámica y se recalculó en tiempo de consulta dentro del contexto de filtro impuesto por el segmentador (2 100 kg).

### C5 · ¿Qué pregunta responde cada una?
`[Pct medida]` contesta qué parte de esta finca aporta cada cosecha, mientras que `pct_columna` contesta qué porcentaje aporta sobre el total histórico de toda la empresa.

---

## Parte D · Contexto de filtro

### D1 · Pct mal

```dax
Pct mal = DIVIDE( [Kilos] , [Kilos] )
```
* **Resultado:** 100,00 % en todas las fincas (Punto de control 5).

### D2 · ¿Por qué no da un número distinto arriba y abajo?
Porque en cada fila de la tabla ambas llamadas a `[Kilos]` se evalúan bajo el mismo contexto de filtro exacto (los kilos de esa finca específica), dividiendo un número entre sí mismo.

### D3 · Pct del total (Punto de control 6)

```dax
Pct del total = DIVIDE( [Kilos] , CALCULATE( [Kilos] , ALL(dim_finca) ) )
```

| Finca | Kilos | Pct del total |
| :--- | :--- | :--- |
| Finca El Guayabo | 14 250 | 46,64 % |
| Hacienda Santa Rosa | 14 200 | 46,48 % |
| Agricola La Union | 2 100 | 6,87 % |
| **Total** | **30 550** | **100,00 %** |

### D4 · Reemplazo por ALL(dim_cultivo)
Al poner `ALL(dim_cultivo)`, solo se remueven los filtros sobre la dimensión de cultivos, pero la tabla sigue filtrada por `dim_finca[finca]`. El denominador sigue filtrado por finca y el cálculo vuelve a dar 100,00 %.

---

## Parte E · La trampa del día

### E1 · Promedio por cultivo MAL

```dax
Promedio por cultivo MAL = DIVIDE( [Kilos] , COUNTROWS(dim_cultivo) )
```
* **Resultado:** 5 091,67 (Punto de control 7).

### E2 · ¿Qué mensaje de error dio Power BI?
Ninguno. Power BI no arrojó ningún error ni advertencia; devolvió un cálculo matemáticamente exacto pero conceptualmente incorrecto.

### E3 · ¿De dónde sale el 5 091,67?
Sale de dividir los kilos totales (30 550) entre el total de filas de la tabla de dimensión cultivo (6):  
30 550 / 6 = 5 091,67

### E4 · Diagnóstico (Punto de control 8)

```dax
Cultivos en la dimension = COUNTROWS(dim_cultivo)
```
* **Resultado:** 6

```dax
Cultivos con cosecha = DISTINCTCOUNT(h_cosecha[cultivo_id])
```
* **Resultado:** 4

### E5 · Cultivos sobrantes y su presencia
Sobran dos cultivos que están registrados en el catálogo maestro (`dim_cultivo`), pero que nunca registraron una cosecha en el período analizado.

### E6 · Promedio por cultivo (Versión correcta)

```dax
Promedio por cultivo = DIVIDE( [Kilos] , DISTINCTCOUNT(h_cosecha[cultivo_id]) )
```
* **Resultado:** 7 637,50 (Punto de control 9, correspondiente a 30 550 / 4).

### E7 · Con segmentador en tipo = perenne (Punto de control 10)
* **[Kilos]:** 20 750
* **Cultivos en la dimensión:** 5
* **Cultivos con cosecha:** 3
* **Promedio por cultivo MAL:** 4 150,00 (20 750 / 5)
* **Promedio por cultivo:** 6 916,67 (20 750 / 3)

### E8 · ¿Por qué está mal la medida mala si ambas respetan el filtro?
Porque utiliza como denominador el catálogo disponible de la dimensión en lugar de contar únicamente los cultivos que efectivamente tuvieron producción registrada en la tabla de hechos.

### E9 · ¿Cuándo deja de estar bien tener filas no usadas en una dimensión?
Deja de estar bien cuando usamos las dimensiones para calcular métricas de actividad (promedios o ratios de eventos del hecho) asumiendo erróneamente que cada elemento de la dimensión participó en los hechos.

---

## Parte F · Preguntas de cierre

* **Diferencia entre medida y columna calculada (momento de cálculo):**  
  La columna calculada se procesa durante la carga/actualización de los datos y queda fija en memoria; la medida se evalúa dinámicamente en tiempo de consulta según el contexto de filtro activo.

* **¿Qué está calculando en realidad la fila del total?:**  
  Evalúa la expresión DAX completa sobre todo el conjunto de datos visible sin el filtro de fila, no es una suma aritmética de los valores proyectados arriba.

* **¿Qué significa ALL(dim_finca)?:**  
  Significa remover o ignorar cualquier contexto de filtro existente que provenga de la tabla `dim_finca`.

* **¿Qué tienen en común todos los números silenciosos analizados?:**  
  Que son errores lógicos o de modelado sintácticamente válidos: el motor no arroja errores ni detiene la ejecución, generando números verosímiles pero falsos.

* **Impacto del modelo estrella vs vista plana:**  
  El modelo estrella desacopla la fuente de datos de la capa analítica sin alterar las métricas. Con la vista plana `v_bi_produccion` se habrían perdido los cultivos sin cosechas y las agregaciones habrían sufrido duplicaciones o problemas de granularidad.