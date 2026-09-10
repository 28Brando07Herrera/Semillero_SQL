# Ejercicio 16 · Herrera Brando

## Parte A · Dos años y un calendario que alcance

### A2b

La opción de fecha/hora automática estaba desactivada.

---

### A3

Se marcó la tabla `dim_tiempo` como tabla de fechas utilizando la columna `fecha`.

---

### A4

Se verificaron las tres relaciones del modelo:

- h_cosecha[finca_id] → dim_finca[finca_id]
- h_cosecha[cultivo_id] → dim_cultivo[cultivo_id]
- h_cosecha[fecha] → dim_tiempo[fecha]

Todas quedaron con cardinalidad muchos a uno (*:1) y dirección de filtro simple.

---

### A5

```DAX
Kilos = SUM(h_cosecha[kg])
```

```DAX
Cosechas = COUNTROWS(h_cosecha)
```

Resultado:

| Año | Kilos | Cosechas |
|------|------:|------:|
| 2025 | 47000 | 16 |
| 2026 | 30550 | 9 |
| Total | 77550 | 25 |

---

### A6

No se perdió nada. Los 30550 kg de 2026 siguen presentes y ahora forman parte de un total de 77550 kg al incluir también la campaña 2025.

---

# Parte B · El eje de tiempo

### B2

Los meses aparecieron ordenados alfabéticamente porque `nombre_mes` es una columna de texto.

Ejemplo: Abril apareció antes que Marzo.

---

### B3

Se configuró:

```text
nombre_mes → Ordenar por columna → mes
```

---

### Punto de control 2

```text
Marzo = 19000
Abril = 29250
```

---

### B4

Los valores no cambiaron. Lo que cambió fue el orden cronológico del eje, necesario para interpretar correctamente una serie temporal.

---

### B6

El gráfico basado en `h_cosecha[fecha]` oculta los meses sin cosecha porque solo muestra fechas donde existen registros.

El gráfico basado en `dim_tiempo[anio_mes]` muestra todos los meses del calendario, incluidos aquellos que no tienen cosechas registradas.

---

# Parte C · El acumulado

### C1

```DAX
Kilos YTD =
TOTALYTD(
    [Kilos],
    dim_tiempo[fecha]
)
```

Resultados relevantes:

| Año | Mes | Kilos | Kilos YTD |
|------|------|------:|------:|
| 2025 | Enero | 2000 | 2000 |
| 2025 | Marzo | 8200 | 14000 |
| 2025 | Abril | 9500 | 23500 |
| 2025 | Diciembre | 1200 | 47000 |
| 2026 | Marzo | 10800 | 10800 |
| 2026 | Abril | 19750 | 30550 |
| 2026 | Mayo | (vacío) | 30550 |
| 2026 | Diciembre | (vacío) | 30550 |

---

### C2

El acumulado no vuelve a cero porque TOTALYTD conserva la suma acumulada desde el inicio del año hasta el período actual.

---

### C3

Enero y Febrero de 2026 no aparecen porque tanto `[Kilos]` como `[Kilos YTD]` están vacíos y la matriz no muestra filas completamente vacías.

---

# Parte D · El año pasado

### D1

```DAX
Kilos AA =
CALCULATE(
    [Kilos],
    SAMEPERIODLASTYEAR(dim_tiempo[fecha])
)
```

Resultados:

| Año | Mes | Kilos | Kilos AA |
|------|------:|------:|------:|
| 2025 | Abril | 9500 | (vacío) |
| 2026 | Marzo | 10800 | 8200 |
| 2026 | Abril | 19750 | 9500 |
| 2026 | Agosto | (vacío) | 5600 |

---

### D2

No es un error. En 2025 no existe información de 2024 en el calendario, por lo que SAMEPERIODLASTYEAR devuelve valores vacíos.

---

### D3

```DAX
Variacion AA =
DIVIDE(
    [Kilos] - [Kilos AA],
    [Kilos AA]
)
```

Resultados:

| Mes | Variacion AA |
|------|------:|
| Marzo 2026 | 31,71 % |
| Abril 2026 | 107,89 % |

---

### D4

Se utiliza DIVIDE porque maneja correctamente casos donde el denominador es cero o está vacío, evitando errores o resultados infinitos.

---

# Parte E · La trampa del día

### E1

Segmentador:

```text
anio = 2026
```

Resultados:

| Medida | Valor |
|------|------:|
| Kilos | 30550 |
| Kilos AA | 47000 |
| Variacion AA | -35,00 % |

---

### E2

Power BI no mostró ningún mensaje de error.

---

### E3

Los números son correctos, pero la comparación no es justa.

Se están comparando cuatro meses con cosecha en 2026 contra los doce meses completos de 2025.

---

### E4

```DAX
Ultimo dia del contexto =
MAX(dim_tiempo[fecha])
```

```DAX
Ultimo dia con cosecha =
MAX(h_cosecha[fecha])
```

Resultados:

| Medida | Valor |
|------|------|
| Último día del contexto | 31/12/2026 |
| Último día con cosecha | 30/04/2026 |

---

### E5

SAMEPERIODLASTYEAR movió 365 días porque todo el año 2026 estaba en el contexto.

De esos doce meses, solo hasta abril existen cosechas. Los meses de mayo a diciembre participaron en la comparación aunque todavía no habían ocurrido.

---

### E6

Agregando un segmentador de meses (1, 2, 3 y 4) y sin modificar ninguna medida:

| Medida | Antes | Después |
|------|------:|------:|
| Kilos | 30550 | 30550 |
| Kilos AA | 47000 | 23500 |
| Variacion AA | -35,00 % | +30,00 % |

---

### E7

Ninguna de las dos medidas está mal.

Las dos son correctas matemáticamente, pero responden preguntas distintas.

La variación de −35,00 % compara todo 2026 contra todo 2025.

La variación de +30,00 % compara 2026 contra 2025 a la misma fecha de corte, que es la comparación adecuada.

---

### E8

[Kilos] no cambió porque no existen cosechas después de abril de 2026.

[Kilos AA] sí cambió porque dejó de incluir los meses de mayo a diciembre de 2025.

---

### E9

```DAX
Kilos AA YTD =
CALCULATE(
    [Kilos YTD],
    SAMEPERIODLASTYEAR(dim_tiempo[fecha])
)
```

```DAX
Variacion YTD =
DIVIDE(
    [Kilos YTD] - [Kilos AA YTD],
    [Kilos AA YTD]
)
```

Resultados:

| Mes | Kilos YTD | Kilos AA YTD | Variacion YTD |
|------|------:|------:|------:|
| Marzo | 10800 | 14000 | -22,86 % |
| Abril | 30550 | 23500 | +30,00 % |
| Junio | 30550 | 30800 | -0,81 % |
| Septiembre | 30550 | 41050 | -25,58 % |
| Diciembre | 30550 | 47000 | -35,00 % |

---

### E10

La tarjeta de E1 está leyendo el contexto completo del año 2026, equivalente a diciembre de 2026.

Sin embargo, los datos reales solo llegan hasta abril de 2026, por lo que la comparación correcta debe hacerse a la misma fecha de corte.

---

### E11

| Finca | Año contra año | A la misma fecha |
|------|------:|------:|
| Hacienda Santa Rosa | -32,38 % | +15,45 % |
| Finca El Guayabo | -17,15 % | +54,89 % |
| Agricola La Union | -76,14 % | +5,00 % |

---

### E12

Las tres fincas cambiaron significativamente al comparar contra la misma fecha.

Esto demuestra que el −35,00 % no era un caso aislado, sino un problema general causado por comparar un año incompleto contra un año completo.

---

# Parte F · Preguntas de cierre

### F1

SAMEPERIODLASTYEAR toma las fechas del contexto actual y las desplaza exactamente un año hacia atrás.

---

### F2

Una medida no tiene un valor fijo. Cambia cuando cambia el contexto de filtro, como ocurrió al limitar la comparación a los meses 1 a 4.

---

### F3

El eje de tiempo debe salir de dim_tiempo porque contiene todos los períodos del calendario, incluso cuando no existen datos.

---

### F4

Cuando lleguen nuevas cosechas, el filtro manual de meses quedará desactualizado.

Sería necesario automatizar la fecha de corte utilizando la última fecha con datos disponibles.

---

### F5

Los tres errores estudiados eran cálculos aritméticamente correctos, pero respondían una pregunta equivocada debido al contexto utilizado.
