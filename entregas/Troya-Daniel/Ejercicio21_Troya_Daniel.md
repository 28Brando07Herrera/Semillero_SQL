# Ejercicio Práctico 21 · Un bono cuyo total sea la suma de lo que se paga

**Estudiante:** Troya Riofrio, Daniel Moises  
**Fecha:** 17 de septiembre de 2026  
**Entorno:** Power BI Desktop  

---

## Parte A · La tabla de la meta

### A1 & A2 · Tabla por finca

| Finca | [Kilos] | [Meta] | [Cumplimiento] |
| :--- | :--- | :--- | :--- |
| Agricola La Union | 2 100 | 5 000 | 42,00 % |
| Finca El Guayabo | 14 250 | 9 440 | 150,95 % |
| Hacienda Santa Rosa | 14 200 | 10 000 | 142,00 % |
| **Total** | **30 550** | **24 440** | **125,00 %** |

### A3 · Suma a mano de [Kilos] y [Cumplimiento]
* Suma de `[Kilos]`: $2\,100 + 14\,250 + 14\,200 = 30\,550$. Coincide con el total.
* Suma de `[Cumplimiento]`: $42{,}00\% + 150{,}95\% + 142{,}00\% = 334{,}95\%$. No es la suma de su columna porque representa el ratio global ponderado ($30\,550 / 24\,440 = 125{,}00\%$), lo cual es lo matemáticamente esperado.

---

## Parte B · El bono y el apoyo

### B1 · Medidas de Excedente y Faltante

```dax
Excedente = MAX( 0 , [Kilos] - [Meta] )
```

```dax
Faltante = MAX( 0 , [Meta] - [Kilos] )
```

| Finca | [Kilos] | [Meta] | [Excedente] | [Faltante] |
| :--- | :--- | :--- | :--- | :--- |
| Agricola La Union | 2 100 | 5 000 | 0 | 2 900 |
| Finca El Guayabo | 14 250 | 9 440 | 4 810 | 0 |
| Hacienda Santa Rosa | 14 200 | 10 000 | 4 200 | 0 |
| **Total** | **30 550** | **24 440** | **6 110** | **0** |

La Union 0 · El Guayabo 4 810 · Santa Rosa 4 200 · Total 6 110  
La Union 2 900 · El Guayabo 0 · Santa Rosa 0 · Total 0

### B2 · Advertencia o mensaje de error de Power BI
Ninguno; la sintaxis DAX es completamente válida.

### B3 · Sumas a mano vs. Totales de la tabla
* **Columna [Excedente]:** $0 + 4\,810 + 4\,200 = 9\,010$ (el total de la tabla muestra **6 110**).
* **Columna [Faltante]:** $2\,900 + 0 + 0 = 2\,900$ (el total de la tabla muestra **0**).

### B4 · Decisión de finanzas sobre el total de [Faltante]
Finanzas concluye erróneamente que no se requiere presupuesto para el plan de apoyo porque el total marca 0; como consecuencia, Agrícola La Unión no recibe asistencia a pesar de haber quedado 2 900 kg por debajo de su meta.

---

## Parte C · Qué calculó el total

### C1 · La cuenta real de la fila del total
En la fila del total no hay filtro de finca (el **contexto** abarca toda la empresa):  
`MAX( 0 , 30 550 − 24 440 ) = 6 110` para Excedente, y `MAX( 0 , 24 440 − 30 550 ) = 0` para Faltante.

### C2 · Diferencia entre 9 010 y 6 110
Faltan exactamente **2 900 kg**, que corresponden al déficit de **Agrícola La Unión**, el cual fue compensado globalmente con el sobrante de las otras fincas.

### C3 · Año completo (12 meses de 2026)

| Finca | [Kilos] | [Meta] | [Excedente] | [Faltante] |
| :--- | :--- | :--- | :--- | :--- |
| Agricola La Union | 2 100 | 8 000 | 0 | 5 900 |
| Finca El Guayabo | 14 250 | 19 000 | 0 | 4 750 |
| Hacienda Santa Rosa | 14 200 | 20 000 | 0 | 5 800 |
| **Total** | **30 550** | **47 000** | **0** | **16 450** |

### C4 · ¿Por qué con el año completo el total sí suma?
Porque las tres fincas están en la misma condición (todas tienen déficit, $[Kilos] < [Meta]$); al no haber fincas con superávit que cancelen a las deficitarias, no ocurre compensación cruzada.

---

## Parte D · SUMX

### D1 · Recorrer las fincas

```dax
Excedente por finca = SUMX( dim_finca , [Excedente] )
```

```dax
Faltante por finca = SUMX( dim_finca , [Faltante] )
```

| Finca | [Excedente] | [Excedente por finca] | [Faltante] | [Faltante por finca] |
| :--- | :--- | :--- | :--- | :--- |
| Agricola La Union | 0 | 0 | 2 900 | 2 900 |
| Finca El Guayabo | 4 810 | 4 810 | 0 | 0 |
| Hacienda Santa Rosa | 4 200 | 4 200 | 0 | 0 |
| **Total** | **6 110** | **9 010** | **0** | **2 900** |

### D2 · Filas recorridas por SUMX en una finca específica
Recorre solo **1 finca** porque el contexto de filtro de la fila ya restringe `dim_finca`; por ello el valor individual no cambia respecto a la medida original.

### D3 · Parecido con la tabla de RANKX
En ambos casos el contexto de filtro restringe la tabla a una sola fila dentro del cuerpo visual, operando fila por fila con transición de contexto.

---

## Parte E · El bono por mes

### E1 · Medida [Excedente por finca] en tabla por mes

| anio_mes | [Kilos] | [Meta] | [Excedente por finca] |
| :--- | :--- | :--- | :--- |
| 2026-01 | 4 040 | 0 | 0 |
| 2026-02 | 5 200 | 0 | 0 |
| 2026-03 | 10 800 | 6 900 | 6 600 |
| 2026-04 | 19 750 | 8 300 | 11 850 |
| **Total** | **30 550** | **24 440** | **9 010** |

### E2 · Suma a mano vs. Total por mes
La suma a mano da $0 + 0 + 6\,600 + 11\,850 = 18\,450$, pero el total dice **9 010**. En la fila del total, `SUMX` itera sobre `dim_finca` acumulando los 4 meses juntos por finca, sin iterar mes a mes.

### E3 · Recorrer fincas y meses

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

#### Tabla por mes (Captura: clase21-bono.png)

| anio_mes | [Excedente por finca] | [Excedente mensual] | [Faltante mensual] |
| :--- | :--- | :--- | :--- |
| 2026-01 | 0 | 0 | 4 040 |
| 2026-02 | 0 | 0 | 5 200 |
| 2026-03 | 6 600 | 6 600 | 2 700 |
| 2026-04 | 11 850 | 11 850 | 400 |
| **Total** | **9 010** | **18 450** | **12 340** |

#### Tabla por finca

| Finca | [Excedente por finca] | [Excedente mensual] | [Faltante mensual] |
| :--- | :--- | :--- | :--- |
| Agricola La Union | 0 | 0 | 2 900 |
| Finca El Guayabo | 4 810 | 10 750 | 5 940 |
| Hacienda Santa Rosa | 4 200 | 7 700 | 3 500 |
| **Total** | **9 010** | **18 450** | **12 340** |

### E4 · Diferencia de Santa Rosa (4 200 vs. 7 700)
* Kilos − Meta por mes en Santa Rosa: Enero: $-2\,000$, Febrero: $-1\,500$, Marzo: $+3\,700$, Abril: $+4\,000$.  
* La diferencia de **3 500 kg** surge porque el cálculo mensual paga los bonos de marzo y abril ($3\,700 + 4\,000 = 7\,700$) sin castigar a la finca por los déficits de enero y febrero ($-3\,500$).

### E5 · ¿El bono es 9 010 o 18 450?
La decisión es de **Recursos Humanos / Gerencia General** según las bases del contrato. El título debe ser explícito: *"Bono por Liquidación Acumulada Cuatrimestral"* (9 010) o *"Bono por Liquidación Mes a Mes Independiente"* (18 450).

---

## Parte F · Lo que sí debe sumar, y lo que no

### F1 · Medida Neto

```dax
Neto = [Kilos] - [Meta]
```

| Finca | [Neto] |
| :--- | :--- |
| Agricola La Union | −2 900 |
| Finca El Guayabo | 4 810 |
| Hacienda Santa Rosa | 4 200 |
| **Total** | **6 110** |

### F2 · ¿Por qué [Neto] suma y [Excedente] no?
Porque `[Neto]` es una operación puramente lineal (suma de diferencias), mientras que `[Excedente]` tiene una función `MAX` no lineal que descarta valores negativos e impide la propiedad aditiva.

### F3 · Comparación de las tres versiones

| Versión | Excedente | Faltante | Excedente − Faltante |
| :--- | :--- | :--- | :--- |
| sin SUMX | 6 110 | 0 | 6 110 |
| SUMX por finca | 9 010 | 2 900 | 6 110 |
| SUMX por finca y mes | 18 450 | 12 340 | 6 110 |

### F4 · Constancia del valor 6 110
El resultado siempre es **6 110** (el balance neto global de la empresa); lo único que varía es la granularidad con la que se distribuyen las ganancias y pérdidas entre entidades y periodos.

### F5 · El 125,00 % de Cumplimiento frente al 334,95 %
No está mal; nadie lo reclama porque sumar porcentajes carece de sentido financiero; se requiere el promedio ponderado en el contexto global consolidado.

---

## Parte G · Preguntas de cierre

1. **¿Qué calcula la fila del total de una medida?**  
   Calcula la expresión DAX directamente sobre el **contexto** global consolidado, sin sumar los resultados de las filas visuales superiores.

2. **¿Por qué el SUMX de la parte D no bastó en la parte E?**  
   No estaba mal escrito; le faltaba granularidad temporal, pues solo iteraba sobre las fincas y consolidaba los meses en un solo bloque.

3. **Regla de detección del día:**  
   «Si una medida tiene un `MAX` o `IF` con tope cero, el total no sumará a menos que uses `SUMX` con la granularidad exacta del negocio».

4. **Prueba ante un "Faltante total: 0":**  
   Desglosaría la métrica por cada entidad individual (fincas) o periodo (meses) para verificar si existen déficits individuales que se están compensando a nivel global.

5. **Ejemplo de medida cuyo total no debe sumar sus filas:**  
   `[Precio Promedio Ponderado]` o `[Margen Porcentual]`.
