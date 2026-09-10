# Ejercicio práctico 16 · Haz que el tablero diga que la finca se cayó, y después arréglalo

- **Alumno:** Cortez Cardozo Axel Josue
- **Entrega:** `entregas/cortez-axel/Ejercicio16_Cortez_Axel.md`, `entregas/cortez-axel/clase16-tablero.png`

---

## Parte A · Dos años y un calendario que alcance

### A1. Carga de los cuatro CSV
- Archivos cargados desde `C:\agrodb\csv16\`: `dim_finca.csv` (3 filas), `dim_cultivo.csv` (6 filas), `dim_tiempo.csv` (730 filas) y `h_cosecha.csv` (25 filas).
- Tipos de datos verificados:
  - `h_cosecha[kg]`: Número entero
  - `h_cosecha[fecha]`: Fecha
  - `dim_tiempo[fecha]`: Fecha
  - `dim_tiempo[anio]`, `dim_tiempo[mes]`, `dim_tiempo[trimestre]`: Número entero
  - `dim_tiempo[anio_mes]`, `dim_tiempo[nombre_mes]`: Texto

### A2b. Fecha/hora automática
Estaba prendida por defecto en Power BI Desktop y se desmarcó en Archivo → Opciones y configuración → Opciones → Carga de datos → Inteligencia de tiempo para evitar calendarios ocultos redundantes.

### A3. Tabla de fechas marcada
Se marcó la tabla `dim_tiempo` como tabla de fechas utilizando la columna `fecha`, asegurando la continuidad de los 730 días completos sin huecos ni duplicados.

### A4. Relaciones del Modelo
- `h_cosecha[finca_id]` -> `dim_finca[finca_id]` (Muchos a uno, Simple)
- `h_cosecha[cultivo_id]` -> `dim_cultivo[cultivo_id]` (Muchos a uno, Simple)
- `h_cosecha[fecha]` -> `dim_tiempo[fecha]` (Muchos a uno, Simple)

### A5. Medidas base

```dax
Kilos = SUM(h_cosecha[kg])
```

Resultado: 77550

```dax
Cosechas = COUNTROWS(h_cosecha)
```

Resultado: 25

#### Punto de control 1

| Año | Kilos | Cosechas |
|---|---|---|
| 2025 | 47 000 | 16 |
| 2026 | 30 550 | 9 |
| **Total** | **77 550** | **25** |

### A6. Integridad de los datos de 2026
No se perdió nada; el total de 2026 sigue intacto en 30 550 kg y simplemente se sumó al histórico de 2025 (47 000 kg) dentro del mismo modelo dimensional.

---

## Parte B · El eje de tiempo

### B1 y B2. Orden alfabético inicial
Al colocar `nombre_mes` como texto sin configurar orden, los meses salieron ordenados alfabéticamente: Abril, Agosto, Diciembre, Enero, Febrero, Julio, Junio, Marzo, Mayo, Noviembre, Octubre, Septiembre.

### B3. Punto de control 2 (Orden cronológico)
Tras ordenar `nombre_mes` por la columna `mes`:
- **Marzo:** 19 000 (10 800 + 8 200)
- **Abril:** 29 250 (19 750 + 9 500)

### B4. Importancia del orden cronológico
Porque el tiempo es una dimensión secuencial; aunque los números por barra no cambien, el orden cronológico es indispensable para visualizar tendencias reales, estacionalidad y continuidades de negocio.

### B5 y B6. Punto de control 3: Eje del hecho vs eje de dimensión
- Puntos en el gráfico izquierdo (`h_cosecha[fecha]`): 2 puntos.
- Puntos en el gráfico derecho (`dim_tiempo[anio_mes]`): 12 puntos.
- El gráfico de la izquierda esconde los periodos de inactividad; al unir únicamente los puntos con datos hace parecer que la producción fue continua y oculta los meses vacíos.

---

## Parte C · El acumulado

### C1. Kilos YTD

```dax
Kilos YTD = TOTALYTD( [Kilos] , dim_tiempo[fecha] )
```

Resultado en la celda de Abril 2026: 30550

#### Punto de control 4

| Año | Mes | [Kilos] | [Kilos YTD] |
|---|---|---|---|
| 2025 | Enero | 2 000 | 2 000 |
| 2025 | Marzo | 8 200 | 14 000 |
| 2025 | Abril | 9 500 | 23 500 |
| 2025 | Diciembre | 1 200 | 47 000 |
| 2026 | Marzo | 10 800 | 10 800 |
| 2026 | Abril | 19 750 | 30 550 |
| 2026 | Mayo | | 30 550 |
| 2026 | Diciembre | | 30 550 |

### C2. Comportamiento del YTD en meses vacíos
Porque `TOTALYTD` acumula la suma de todos los días transcurridos desde el 1 de enero hasta la fecha evaluada; si en mayo no hubo cosecha, el acumulado anual alcanzado hasta abril se conserva intacto.

### C3. Ausencia de Enero y Febrero 2026 en la matriz
Porque en esos meses tanto `[Kilos]` como `[Kilos YTD]` eran nulos al no existir cosechas registradas ni acumulados previos, y Power BI omite filas con todas las medidas vacías.

---

## Parte D · El año pasado

### D1. Kilos AA

```dax
Kilos AA = CALCULATE( [Kilos] , SAMEPERIODLASTYEAR( dim_tiempo[fecha] ) )
```

Resultado en la celda de Abril 2026: 9500

#### Punto de control 5

| Año | Mes | [Kilos] | [Kilos AA] |
|---|---|---|---|
| 2025 | Abril | 9 500 | |
| 2026 | Marzo | 10 800 | 8 200 |
| 2026 | Abril | 19 750 | 9 500 |
| 2026 | Agosto | | 5 600 |

### D2. Vacío en 2025
No es un error; `SAMEPERIODLASTYEAR` desplaza las fechas 365 días hacia atrás, y como el calendario arranca en 2025, el año 2024 no existe en la dimensión de tiempo.

### D3. Variacion AA

```dax
Variacion AA = DIVIDE( [Kilos] - [Kilos AA] , [Kilos AA] )
```

#### Punto de control 6
- **Marzo 2026:** +31,71 %
- **Abril 2026:** +107,89 %

### D4. Uso de DIVIDE
Para evitar divisiones por cero y controlar de forma segura las celdas vacías (como en todo el año 2025), entregando un valor en blanco en lugar de un error.

---

## Parte E · La trampa del día

### E1. Tarjetas con segmentador de año 2026 (Punto de control 7)

| Medida | Valor |
|---|---|
| `[Kilos]` | 30 550 |
| `[Kilos AA]` | 47 000 |
| `[Variacion AA]` | −35,00 % |

### E2. Mensaje de error de Power BI
Ninguno. Power BI no arrojó advertencias ni errores de cálculo; ejecutó la fórmula matemáticamente y devolvió un resultado conceptualmente engañoso.

### E3. Diagnóstico del error
Se está comparando un año parcial (los primeros 4 meses de 2026 con 30 550 kg) contra los 12 meses completos del año 2025 (47 000 kg).

### E4. Fechas de corte (Punto de control 8)

```dax
Ultimo dia del contexto = MAX( dim_tiempo[fecha] )
```

Resultado: 31/12/2026

```dax
Ultimo dia con cosecha = MAX( h_cosecha[fecha] )
```

Resultado: 30/04/2026

### E5. Desplazamiento temporal
`SAMEPERIODLASTYEAR` desplazó los 365 días que estaban en el contexto de filtro anual. Tenía que haber desplazado solo 120 días (hasta el 30 de abril). Entraron 8 meses de 2026 en el contexto que todavía no han transcurrido en las operaciones reales.

### E6. Arreglo con segmentador de meses (1 a 4) (Punto de control 9)

| Medida | Antes | Después |
|---|---|---|
| `[Kilos]` | 30 550 | 30 550 |
| `[Kilos AA]` | 47 000 | 23 500 |
| `[Variacion AA]` | −35,00 % | +30,00 % |

### E7. ¿Cuál de las dos medidas está mal?
Está mal la de −35,00 % porque viola la comparabilidad temporal al contrastar periodos asimétricos; la de +30,00 % responde adecuadamente al desempeño real comparando el mismo tramo de meses (enero-abril).

### E8. Comportamiento de Kilos frente a Kilos AA
`[Kilos]` no cambió porque en 2026 no hay registros después de abril (el acumulado a abril ya era 30 550). `[Kilos AA]` sí cambió porque en 2025 sí hubo cosechas entre mayo y diciembre, las cuales fueron excluidas al limitar el filtro.

### E9. Acumulados y variaciones YTD

```dax
Kilos AA YTD = CALCULATE( [Kilos YTD] , SAMEPERIODLASTYEAR( dim_tiempo[fecha] ) )
```

```dax
Variacion YTD = DIVIDE( [Kilos YTD] - [Kilos AA YTD] , [Kilos AA YTD] )
```

#### Punto de control 10

| Mes de corte | [Kilos YTD] | [Kilos AA YTD] | [Variacion YTD] |
|---|---|---|---|
| Marzo | 10 800 | 14 000 | −22,86 % |
| Abril | 30 550 | 23 500 | +30,00 % |
| Junio | 30 550 | 30 800 | −0,81 % |
| Septiembre | 30 550 | 41 050 | −25,58 % |
| Diciembre | 30 550 | 47 000 | −35,00 % |

### E10. Mes evaluado por la tarjeta general
La tarjeta general evaluó el contexto de filtro de todo el año calendario (equivalente al corte de diciembre), ignorando que la operación se encuentra cortada a abril de 2026.

### E11. Comparativa por finca (Punto de control 11)

| Finca | Año contra año | A la misma fecha |
|---|---|---|
| Hacienda Santa Rosa | −32,38 % | +15,45 % |
| Finca El Guayabo | −17,15 % | +54,89 % |
| Agricola La Union | −76,14 % | +5,00 % |

### E12. Conclusión del cambio de signo
Demuestra que la supuesta caída no correspondía a un problema productivo ni a una anomalía de una finca en particular, sino a una distorsión sistemática causada por comparar periodos no homogéneos.

---

## Parte F · Preguntas de cierre

1. **Función única de SAMEPERIODLASTYEAR:** Desplaza el conjunto de fechas recibido en el contexto de filtro exactamente un año hacia atrás sobre la tabla marcada como calendario.
2. **Medidas y contexto de filtro:** Una medida define una fórmula dinámica sin un valor fijo; al modificar el contexto de filtro con el segmentador de meses, la misma expresión recalculó un resultado conceptualmente válido sin necesidad de modificar el código DAX.
3. **Origen del eje temporal:** Porque la tabla dimensional garantiza una serie de tiempo continua y completa para mostrar tendencias y huecos de actividad, a diferencia de la tabla de hechos que solo posee fechas en las que ocurrieron cosechas.
4. **Dependencia manual y automatización:** Si en mayo entran nuevas cosechas el filtro manual quedará desactualizado; para resolverlo automáticamente en DAX se debe acotar el cálculo hasta la fecha máxima real de la tabla de hechos mediante `MAX(h_cosecha[fecha])`.
5. **Causa común de los errores:** Los tres cálculos fueron operaciones aritméticas matemáticamente correctas que no arrojaron advertencias técnicas, pero que arrojaron conclusiones falsas de negocio por problemas de contexto de evaluación y granularidad.