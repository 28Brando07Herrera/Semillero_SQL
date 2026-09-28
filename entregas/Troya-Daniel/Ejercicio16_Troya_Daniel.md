# Ejercicio práctico 16 · Haz que el tablero diga que la finca se cayó, y después arréglalo

**Estudiante:** Daniel Moises Troya Riofrio

---

## Parte A · Dos años y un calendario que alcance

### A2b · Estado inicial de fecha/hora automática
Estaba desmarcada en mi máquina antes de verificar las opciones del archivo.

### A5 · Medidas base

```dax
Kilos = SUM(h_cosecha[kg])
```

```dax
Cosechas = COUNTROWS(h_cosecha)
```

#### Punto de control 1 · Validación de carga

| Año | Kilos | Cosechas |
| :--- | :--- | :--- |
| 2025 | 47 000 | 16 |
| 2026 | 30 550 | 9 |
| **Total** | **77 550** | **25** |

### A6 · Integridad de los datos de 2026
No se perdió nada; el total de 2026 sigue dando exactamente 30 550 kilos porque el modelo sumó el histórico de 2025 en filas independientes sin alterar ni sobrescribir los registros del año en curso.

---

## Parte B · El eje de tiempo

### B2 · Orden alfabético inicial
Los meses salieron ordenados alfabéticamente por ser una columna de texto: Abril, Agosto, Diciembre, Enero, Febrero, Julio, Junio, Marzo, Mayo, Noviembre, Octubre, Septiembre.

### B3 · Punto de control 2 (Orden cronológico corregido)
* **Marzo:** 19 000 kg (10 800 + 8 200)
* **Abril:** 29 250 kg (19 750 + 9 500)

### B4 · Importancia del orden del eje
Porque el tiempo es continuo y secuencial; un eje desordenado destruye la capacidad visual de interpretar tendencias, estacionalidad y comportamiento del ciclo agrícola.

### B5 · Punto de control 3 (Puntos en los gráficos de líneas)
* **Gráfico izquierdo (`h_cosecha[fecha]`):** 4 puntos (solo los días/meses con cosecha registrada en 2026).
* **Gráfico derecho (`dim_tiempo[anio_mes]`):** 12 puntos (los doce meses del año 2026 completos).

### B6 · Comparación Hecho vs Dimensión
El gráfico de la tabla de hechos le esconde al lector los periodos de inactividad, haciendo parecer que la producción fue constante y continua al saltarse los meses sin cosecha.

---

## Parte C · El acumulado

### C1 · Kilos YTD

```dax
Kilos YTD = TOTALYTD( [Kilos] , dim_tiempo[fecha] )
```

#### Punto de control 4 · Matriz acumulada

| Año | Mes | [Kilos] | [Kilos YTD] |
| :--- | :--- | :--- | :--- |
| 2025 | Enero | 2 000 | 2 000 |
| 2025 | Marzo | 8 200 | 14 000 |
| 2025 | Abril | 9 500 | 23 500 |
| 2025 | Diciembre | 1 200 | 47 000 |
| 2026 | Marzo | 10 800 | 10 800 |
| 2026 | Abril | 19 750 | 30 550 |
| 2026 | Mayo | (vacío) | 30 550 |
| 2026 | Diciembre | (vacío) | 30 550 |

* **Resultado en la celda de Abril 2026:** 30 550

### C2 · Comportamiento de YTD en mayo 2026
No se cae a cero porque la función YTD acumula de forma continua desde el inicio del año natural; al no existir cosechas en mayo, suma cero y conserva el saldo acumulado anterior.

### C3 · Ausencia de Enero y Febrero 2026 en la matriz
No aparecen porque ambas medidas (`[Kilos]` y `[Kilos YTD]`) están completamente vacías para esos periodos, y Power BI oculta por defecto las filas sin datos.

---

## Parte D · El año pasado

### D1 · Kilos AA

```dax
Kilos AA = CALCULATE( [Kilos] , SAMEPERIODLASTYEAR( dim_tiempo[fecha] ) )
```

#### Punto de control 5

| Año | Mes | [Kilos] | [Kilos AA] |
| :--- | :--- | :--- | :--- |
| 2025 | Abril | 9 500 | (vacío) |
| 2026 | Marzo | 10 800 | 8 200 |
| 2026 | Abril | 19 750 | 9 500 |
| 2026 | Agosto | (vacío) | 5 600 |

### D2 · Vacíos en 2025 para Kilos AA
No es un error. Para calcular el año anterior de 2025 se requerirían los datos y fechas del año 2024, los cuales no existen en el modelo ni en el calendario.

### D3 · Variacion AA

```dax
Variacion AA = DIVIDE( [Kilos] - [Kilos AA] , [Kilos AA] )
```

#### Punto de control 6
* **Marzo 2026:** +31,71 %
* **Abril 2026:** +107,89 %

### D4 · Uso de DIVIDE
Para interceptar de forma segura los casos de división entre cero o valores en blanco (como en 2025), evitando arrojar errores visuales de cálculo.

---

## Parte E · La trampa del día

### E1 · Punto de control 7 (Año 2026 completo)

| Medida | Valor |
| :--- | :--- |
| [Kilos] | 30 550 |
| [Kilos AA] | 47 000 |
| [Variacion AA] | −35,00 % |

### E2 · Mensaje de error de Power BI
Ninguno (0 errores). Power BI ejecutó la matemática exacta sobre el contexto de filtro que se le suministró.

### E3 · El problema de fondo
Se están comparando 4 meses transcurridos de 2026 (enero a abril) contra los 12 meses completos cerrados de la campaña 2025; no es una comparación homogénea.

### E4 · Medidas de fechas de corte

```dax
Ultimo dia del contexto = MAX( dim_tiempo[fecha] )
```

```dax
Ultimo dia con cosecha = MAX( h_cosecha[fecha] )
```

#### Punto de control 8

| Medida | Valor |
| :--- | :--- |
| Último día del contexto | 31/12/2026 |
| Último día con cosecha | 30/04/2026 |

### E5 · Días desplazados y meses futuros
Debió desplazar 120 días (del 1 de enero al 30 de abril). Entraron en el contexto 8 meses de 2026 que no han ocurrido en la operación.

### E6 · Punto de control 9 (Arreglo con segmentador de meses 1 a 4)

| Medida | Antes | Después |
| :--- | :--- | :--- |
| [Kilos] | 30 550 | 30 550 |
| [Kilos AA] | 47 000 | 23 500 |
| [Variacion AA] | −35,00 % | +30,00 % |

### E7 · ¿Cuál variación está mal?
La de −35,00 % está conceptualmente mal porque compara periodos asimétricos, induciendo al error en una decisión de negocio, a pesar de que ambas son matemáticamente correctas para su contexto.

### E8 · Por qué [Kilos] no cambió y [Kilos AA] sí
Porque en 2026 no existen cosechas después de abril (filtrar meses 1 a 4 mantiene la totalidad cosechada), mientras que en 2025 sí hubo cosechas de mayo a diciembre que fueron excluidas al recortar el filtro.

### E9 · Medidas acumuladas año anterior y variación

```dax
Kilos AA YTD = CALCULATE( [Kilos YTD] , SAMEPERIODLASTYEAR( dim_tiempo[fecha] ) )
```

```dax
Variacion YTD = DIVIDE( [Kilos YTD] - [Kilos AA YTD] , [Kilos AA YTD] )
```

#### Punto de control 10

| Mes de corte | [Kilos YTD] | [Kilos AA YTD] | [Variacion YTD] |
| :--- | :--- | :--- | :--- |
| Marzo | 10 800 | 14 000 | −22,86 % |
| Abril | 30 550 | 23 500 | +30,00 % |
| Junio | 30 550 | 30 800 | −0,81 % |
| Septiembre | 30 550 | 41 050 | −25,58 % |
| Diciembre | 30 550 | 47 000 | −35,00 % |

### E10 · Lectura de la tarjeta de E1
La tarjeta de E1 leía el año completo cerrando a diciembre, mientras que la operación real del negocio se encuentra cortada a 30 de abril.

### E11 · Punto de control 11 (Desglose por Finca)

| Finca | Año contra año | A la misma fecha |
| :--- | :--- | :--- |
| Hacienda Santa Rosa | −32,38 % | +15,45 % |
| Finca El Guayabo | −17,15 % | +54,89 % |
| Agricola La Union | −76,14 % | +5,00 % |

### E12 · El falso caso aislado
Demuestra que el −35 % no correspondía a un bajo rendimiento particular de una finca, sino a una distorsión metodológica en el contexto temporal de todo el modelo.

---

## Parte F · Preguntas de cierre

* **SAMEPERIODLASTYEAR:**  
  Desplaza exactamente un año hacia atrás el conjunto de fechas recibido en el contexto de filtro actual.

* **Arreglo sin fórmulas y valor de una medida:**  
  Una medida no almacena datos fijos, sino que calcula dinámicamente según el contexto; al acotar los meses en el segmentador se redefinió el contexto temporal y el cálculo cambió de signo automáticamente.

* **Eje de tiempo desde dimensión:**  
  Porque la tabla de hechos solo contiene fechas donde hubo actividad, mientras que la dimensión garantiza una línea de tiempo uniforme, continua y sin huecos.

* **Al llegar mayo:**  
  El tablero manual quedaría congelado en abril y omitiría los datos nuevos; para automatizarlo se debe restringir el cálculo en DAX evaluando hasta la fecha máxima con registros (`MAX(h_cosecha[fecha])`).

* **Los tres números erróneos de las clases 14, 15 y 16:**  
  La aritmética era impecable, pero el contexto de evaluación (granularidad, relaciones o marco temporal) no representaba la realidad del negocio.