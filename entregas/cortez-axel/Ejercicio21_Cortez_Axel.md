# Ejercicio 21 · Un bono cuyo total sea la suma de lo que se paga

- **Alumno:** Cortez Cardozo Axel Josue
- **Ejercicio / proyecto:** Ejercicio 21 · Granularidad, contexto de fila/filtro y totales con SUMX
- **Archivo:** `entregas/cortez-axel/Ejercicio21_Cortez_Axel.md`

---

## Parte A · La tabla de la meta

### A1. Segmentadores
- `dim_tiempo[anio]` = 2026
- `dim_tiempo[mes]` en 1, 2, 3 y 4
- `dim_cultivo[tipo]` (sin selección)

### A2. Tabla por finca (Punto de control 1)

| Finca | [Kilos] | [Meta] | [Cumplimiento] |
|---|---|---|---|
| Agricola La Union | 2 100 | 5 000 | 42,00 % |
| Finca El Guayabo | 14 250 | 9 440 | 150,95 % |
| Hacienda Santa Rosa | 14 200 | 10 000 | 142,00 % |
| **Total** | **30 550** | **24 440** | **125,00 %** |

### A3. Respuesta
El total de `[Kilos]` sí es la suma de su columna (30 550); el total de `[Cumplimiento]` no es la suma de los porcentajes (334,95 %) porque es un ratio ponderado calculado en el contexto global (`30 550 / 24 440`), lo cual es el comportamiento correcto en ratios.

---

## Parte B · El bono y el apoyo

### B1. Medidas iniciales
```dax
Excedente = MAX( 0 , [Kilos] - [Meta] )
```

```dax
Faltante = MAX( 0 , [Meta] - [Kilos] )
```

### Tabla resultante (Punto de control 2)

| Finca | [Kilos] | [Meta] | [Excedente] | [Faltante] |
|---|---|---|---|---|
| Agricola La Union | 2 100 | 5 000 | 0 | 2 900 |
| Finca El Guayabo | 14 250 | 9 440 | 4 810 | 0 |
| Hacienda Santa Rosa | 14 200 | 10 000 | 4 200 | 0 |
| **Total** | **30 550** | **24 440** | **6 110** | **0** |

### B2. Mensaje de error o advertencia
Power BI no mostró ningún error ni advertencia; ejecutó el cálculo evaluando la fórmula de forma silenciosa.

### B3. Sumas a mano vs Total mostrado
- **Suma a mano Excedente:** 0 + 4 810 + 4 200 = **9 010** | **Total mostrado:** 6 110
- **Suma a mano Faltante:** 2 900 + 0 + 0 = **2 900** | **Total mostrado:** 0

### B4. Respuesta
Finanzas asumiría que ninguna finca requiere asistencia social o financiera porque el faltante corporativo marca 0; como consecuencia, Agrícola La Unión no recibiría el plan de apoyo a pesar de estar 2 900 kilos por debajo de su meta.

---

## Parte C · Qué calculó el total

### C1. La cuenta del total
La fila del total evalúa la fórmula en el contexto total sin filtro de finca:
`MAX( 0 , 30 550 − 24 440 ) = 6 110` para Excedente, y `MAX( 0 , 24 440 − 30 550 ) = 0` para Faltante.

### C2. Respuesta
Faltan exactamente 2 900 kilos, que corresponden al faltante de Agrícola La Unión que fue absorbido y compensado por los excedentes de las otras dos fincas.

### C3. Año completo (Punto de control 3)

| Finca | [Kilos] | [Meta] | [Excedente] | [Faltante] |
|---|---|---|---|---|
| Agricola La Union | 2 100 | 8 000 | 0 | 5 900 |
| Finca El Guayabo | 14 250 | 19 000 | 0 | 4 750 |
| Hacienda Santa Rosa | 14 200 | 20 000 | 0 | 5 800 |
| **Total** | **30 550** | **47 000** | **0** | **16 450** |

### C4. Respuesta
El total sí coincide con la suma manual (16 450) porque las tres fincas quedaron con déficit respecto a su meta anual; al tener todas el mismo signo en la resta, no hubo excedentes positivos que cancelaran a los faltantes.

---

## Parte D · SUMX

### D1. Medidas iteradas por finca
```dax
Excedente por finca = SUMX( dim_finca , [Excedente] )
```

```dax
Faltante por finca = SUMX( dim_finca , [Faltante] )
```

### Tabla resultante (Punto de control 4)

| Finca | [Excedente] | [Excedente por finca] | [Faltante] | [Faltante por finca] |
|---|---|---|---|---|
| Agricola La Union | 0 | 0 | 2 900 | 2 900 |
| Finca El Guayabo | 4 810 | 4 810 | 0 | 0 |
| Hacienda Santa Rosa | 4 200 | 4 200 | 0 | 0 |
| **Total** | **6 110** | **9 010** | **0** | **2 900** |

### D2. Respuesta
Recorre exactamente 1 finca debido a que el contexto de filtro de la fila ya restringe `dim_finca` a esa única entidad; por eso los valores individuales de las filas no sufrieron modificaciones.

### D3. Respuesta
En ambas funciones, el primer argumento define la tabla de granularidad sobre la cual el motor itera y aplica el cálculo fila por fila.

---

## Parte E · El bono por mes

### E1. Tabla por mes con Excedente por finca (Punto de control 5)

| anio_mes | [Kilos] | [Meta] | [Excedente por finca] |
|---|---|---|---|
| 2026-01 | (en blanco) | 4 040 | 0 |
| 2026-02 | (en blanco) | 5 200 | 0 |
| 2026-03 | 10 800 | 6 900 | 6 600 |
| 2026-04 | 19 750 | 8 300 | 11 850 |
| **Total** | **30 550** | **24 440** | **9 010** |

### E2. Respuesta
La suma manual da 18 450 (6 600 + 11 850), pero el total dice 9 010; ocurre porque en el total `SUMX( dim_finca , ... )` itera únicamente sobre las fincas acumulando todo el cuatrimestre a la vez, compensando meses malos con meses buenos.

### E3. Medidas iteradas por finca y mes
```dax
Excedente mensual =
SUMX(
    dim_finca ,
    SUMX( VALUES( dim_tiempo[anio_mes] ) , [Excedente] )
)
```

```dax
Faltante mensual =
SUMX(
    dim_finca ,
    SUMX( VALUES( dim_tiempo[anio_mes] ) , [Faltante] )
)
```

### Tabla resultante por mes (Punto de control 6)

| anio_mes | [Excedente por finca] | [Excedente mensual] | [Faltante mensual] |
|---|---|---|---|
| 2026-01 | 0 | 0 | 4 040 |
| 2026-02 | 0 | 0 | 5 200 |
| 2026-03 | 6 600 | 6 600 | 2 700 |
| 2026-04 | 11 850 | 11 850 | 400 |
| **Total** | **9 010** | **18 450** | **12 340** |

*(Se anexa captura `clase21-bono.png` con esta vista).*

### Tabla resultante por finca (Punto de control 7)

| Finca | [Excedente por finca] | [Excedente mensual] | [Faltante mensual] |
|---|---|---|---|
| Agricola La Union | 0 | 0 | 2 900 |
| Finca El Guayabo | 4 810 | 10 750 | 5 940 |
| Hacienda Santa Rosa | 4 200 | 7 700 | 3 500 |
| **Total** | **9 010** | **18 450** | **12 340** |

### E4. Respuesta
En Santa Rosa: Ene (−1 700), Feb (−1 800), Mar (+4 200), Abr (+3 500). El bono mensual suma solo los meses positivos (4 200 + 3 500 = 7 700), mientras que el de temporada compensó los 3 500 negativos de enero y febrero contra abril.

### E5. Respuesta
Depende de la política contractual de compensación: si el bono se liquida mensualmente es 18 450; si se liquida por campaña acumulada es 9 010. El título de la tabla debe especificar claramente si es "Bono Acumulado Cuatrimestral" o "Bono por Liquidación Mensual".

---

## Parte F · Lo que sí debe sumar, y lo que no

### F1. Neto (Punto de control 8)
```dax
Neto = [Kilos] - [Meta]
```

| Finca | [Neto] |
|---|---|
| Agricola La Union | −2 900 |
| Finca El Guayabo | 4 810 |
| Hacienda Santa Rosa | 4 200 |
| **Total** | **6 110** |

### F2. Respuesta
Porque `[Neto]` es una operación puramente aditiva y lineal ($A - B$), mientras que `[Excedente]` tiene una función condicional no lineal (`MAX(0, ...)`), perdiendo la propiedad asociativa en los totales.

### F3. Las tres versiones (Punto de control 9)

| Versión | Excedente | Faltante | Excedente − Faltante |
|---|---|---|---|
| sin `SUMX` | 6 110 | 0 | 6 110 |
| `SUMX` por finca | 9 010 | 2 900 | 6 110 |
| `SUMX` por finca y mes | 18 450 | 12 340 | 6 110 |

### F4. Respuesta
El resultado es siempre 6 110; lo único que cambia es el nivel de granularidad donde se trunca el cero, ya que el balance físico global entre kilos y metas de la temporada es constante.

### F5. Respuesta
No está mal; es un ratio porcentual global ponderado y carece de sentido financiero sumar alícuotas o tasas relativas.

---

## Parte G · Preguntas de cierre

1. La fila del total evalúa la fórmula en el contexto de filtro global generado por todos los segmentadores externos, sin filtros en los campos de fila visual.
2. No estaba mal escrita, pero carecía de granularidad temporal: solo iteraba sobre `dim_finca`, omitiendo recorrer mes a mes las metas parciales.
3. Si una medida condicional con cero no suma en el total, los negativos de una categoría están compensando silenciosamente los positivos de otra.
4. Quitaría los filtros agregados y evaluaría la tabla abierta en su máxima granularidad operativa (por finca o por mes) para comprobar si existen entidades en déficit.
5. El precio promedio ponderado, el margen porcentual o cualquier medida que represente promedios o ratios.