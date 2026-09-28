# Ejercicio 16 · AgroDB

## PARTE A - DIAGNÓSTICO

**A2b.** La fecha/hora automática estaba prendida por defecto; procedí a apagarla.

**A5. Punto de Control 1:**
| Año | Kilos | Cosechas |
|---|---|---|
| 2025 | 47 000 | 16 |
| 2026 | 30 550 | 9 |
| **Total** | **77 550** | **25** |

**A6.** No se perdió nada. El contexto de filtro del año 2026 aísla correctamente sus datos, por lo que los 30 550 kilos siguen intactos a pesar de agregar la información de 2025.

---

## PARTE B - DIAGNÓSTICO

**B2.** Los meses salieron ordenados de forma alfabética: Abril, Agosto, Diciembre, Enero, Febrero, Julio, Junio, Marzo, Mayo, Noviembre, Octubre, Septiembre.

**B3. Punto de Control 2:**
* Marzo: 19 000
* Abril: 29 250

**B4.** Importa porque el eje X debe representar el paso cronológico natural del tiempo. Si está ordenado alfabéticamente, resulta imposible interpretar tendencias.

**B5. Punto de Control 3:**
* Gráfico izquierdo (eje `h_cosecha`): 4 puntos (solo muestra los meses donde efectivamente existió cosecha).
* Gráfico derecho (eje `dim_tiempo`): 12 puntos (muestra el año completo).

**B6.** El gráfico de la izquierda esconde los meses sin actividad (los huecos sin datos), dando una falsa impresión de continuidad temporal. El de la derecha muestra la realidad completa al visibilizar los meses vacíos.

---

## PARTE C - DIAGNÓSTICO

### C1 · Kilos YTD
```dax
Kilos YTD = TOTALYTD( [Kilos] , dim_tiempo[fecha] )

### Punto de control 4:

| Año | Mes | [Kilos] | [Kilos YTD] |
|---|---|---|---|
| 2025 | Enero | 2 000 | 2 000 |
| 2025 | Marzo | 8 200 | 14 000 |
| 2025 | Abril | 9 500 | 23 500 |
| 2025 | Diciembre | 1 200 | 47 000 |
| 2026 | Marzo | 10 800 | 10 800 |
| 2026 | Abril | 19 750 | 30 550 |
| 2026 | Mayo | (vacío) | 30 550 |
| 2026 | Diciembre | (vacío) | 30 550 |

**C2.** El acumulado no cae a cero porque TOTALYTD arrastra el total histórico sumado desde el primer día del año hasta el contexto actual. Si en mayo no hay kilos nuevos, suma cero al total que traía de abril.

**C3.** Porque ni [Kilos] ni [Kilos YTD] tienen valores en esos meses. Al resultar ambas en BLANK, la matriz oculta automáticamente toda la fila.

# PARTE D - DIAGNÓSTICO
## D1 · Kilos AA

```
Kilos AA = CALCULATE( [Kilos] , SAMEPERIODLASTYEAR( dim_tiempo[fecha] ) )
```

### Punto de control 5:

| Año | Mes | [Kilos] | [Kilos AA] |
|---|---|---|---|
| 2025 | Abril | 9 500 | (vacío) |
| 2026 | Marzo | 10 800 | 8 200 |
| 2026 | Abril | 19 750 | 9 500 |
| 2026 | Agosto | (vacío) | 5 600 |

**D2.** No es un error. En 2025 la función busca información en las fechas equivalentes de 2024. Al no estar el año 2024 en el modelo, devuelve vacío de forma natural.

##  D3 · Variacion AA

```
Variacion AA = DIVIDE( [Kilos] - [Kilos AA] , [Kilos AA] ) 
```

### Punto de control 6:

* Marzo 2026: +31,71 %

* Abril 2026: +107,89 %

**D4.** DIVIDE gestiona los errores de división por cero automáticamente devolviendo un valor en blanco (BLANK), lo que protege las visualizaciones en la interfaz.

# PARTE E - LA TRAMPA DEL DÍA
## Punto de control 7:

| Medida | Valor |
|---|---|
| [Kilos] | 30 550 |
| [Kilos AA] | 47 000 |
| [Variacion AA] | −35,00 % |

**E2.** Ninguno. Power BI no arroja un error porque aritméticamente la resta y división están correctas, pero producen un número descontextualizado.

**E3.** El problema es la disparidad en las bases de comparación temporal. Se está comparando un año 2026 trunco (4 meses trabajados) contra todo el acumulado de los 12 meses de 2025.

## E4 · Fechas de corte

```
Ultimo dia del contexto = MAX( dim_tiempo[fecha] )
Ultimo dia con cosecha  = MAX( h_cosecha[fecha] )
```

### Punto de control 8:

* Último día del contexto: 31/12/2026

* Último día con cosecha: 30/04/2026

### E5. Solo debía mover los días correspondientes a los cuatro primeros meses de operación. Se desplazaron 365 días porque eso indicaba el filtro de año, introduciendo erróneamente en el cálculo los 8 meses sobrantes del año anterior.

### Punto de control 9:

|Medida | Antes |  Después |
|---|---|---|
| [Kilos] | 30 550 | 30 550 |
| [Kilos AA] | 47 000  | 23 500 |
| [Variacion AA] | −35,00 % | +30,00 % |

**E7.** El −35,00 % es incorrecto para fines evaluativos porque distorsiona el progreso contra un año completo finalizado. El +30,00 % es el indicador válido al medir métricas en igualdad de periodos (mismo cuatrimestre).

**E8.** [Kilos] no varió porque no hay más kilos cosechados posterior a abril. [Kilos AA] cambió drásticamente porque sí existían cosechas entre mayo y diciembre de 2025, de las cuales el filtro se deshizo.

### Punto de control 10:

| Mes de corte | [Kilos YTD] | [Kilos AA YTD] | [Variacion YTD] |
|---|---|---|---|
| Marzo | 10 800 | 14 000 | "−22,86 %" |
| Abril | 30 550 | 23 500 | "+30,00 %" |
| Junio | 30 550 | 30 800 | "−0,81 %" |
| Septiembre | 30 550 | 41 050 | "−25,58 %" |
| Diciembre | 30 550 | 47 000 | "−35,00 %" |

**E10.** La tarjeta del −35,00 % está leyendo a cierre de Diciembre, pero actualmente los datos de cosecha solo llegan hasta Abril.

### Punto de control 11:

| Finca | Año contra año | A la misma fecha |
|---|---|---|
| Hacienda Santa Rosa | "−32,38 %" | "+15,45 %" |
| Finca El Guayabo | "−17,15 %" | "+54,89 %" |
| Agricola La Union | "−76,14 %" | "+5,00 %" |

**E12.** Demuestra que no fue un error aislado y puntual en un registro, sino una falla transversal en el contexto temporal que afecta a todas las entidades del modelo arrastrando las cifras hacia abajo.

# PARTE F - CIERRE
1. ¿Qué hace SAMEPERIODLASTYEAR? Desplaza exactamente un año hacia atrás el conjunto activo de fechas en el contexto de filtro evaluado.

2. ¿Qué tiene que ver una cosa con la otra? Comprueba que las medidas no contienen valores estáticos; al alterar los meses seleccionados mediante el segmentador, el cálculo se rehizo para encajar con el nuevo contexto sin tener que reescribir DAX.

3. ¿Por qué el eje sale de dim_tiempo? Porque la dimensión de tiempo provee una secuencia cronológica intacta y continua, previniendo los cortes y saltos de días sin operación en la tabla de hechos.

4. ¿Qué le pasa al tablero en mayo? Estará desactualizado, ya que la selección manual en los meses 1 al 4 ignorará la nueva carga. Se deberá programar inteligencia de tiempo que compare automáticamente contra la fecha máxima real o emplear períodos relativos.

5. ¿Qué tenían mal los tres números? Eran cifras aritméticamente irrefutables que provenían de contextos de negocio irreales o incompletos por fallas de filtrado o modelado.