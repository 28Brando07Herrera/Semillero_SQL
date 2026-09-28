# Ejercicio 21 · AgroDB

## PARTE A - LA TABLA DE LA META

**A2. Punto de control 1:**[cite: 11]
| Finca | `[Kilos]` | `[Meta]` | `[Cumplimiento]` |
|---|---|---|---|
| Agricola La Union | 2 100 | 5 000 | 42,00 % |
| Finca El Guayabo | 14 250 | 9 440 | 150,95 % |
| Hacienda Santa Rosa | 14 200 | 10 000 | 142,00 % |
| **Total** | **30 550** | **24 440** | **125,00 %** |

**A3.** El total de `[Kilos]` (30 550) es la suma correcta de su columna. El otro total extraña porque la suma matemática de los porcentajes de `[Cumplimiento]` da 334,95 %, pero la tabla dice 125,00 %[cite: 11].

---

## PARTE B - EL BONO Y EL APOYO

### B1 · Excedente y Faltante
```dax
Excedente = MAX( 0 , [Kilos] - [Meta] )
Faltante  = MAX( 0 , [Meta] - [Kilos] )

**Punto de control 2:**

| Finca | `[Kilos]` | `[Meta]` | `[Excedente]` | `[Faltante]` |
| --- | --- | --- | --- | --- |
| Agricola La Union | 2 100 | 5 000 | 0 | **2 900** |
| Finca El Guayabo | 14 250 | 9 440 | **4 810** | 0 |
| Hacienda Santa Rosa | 14 200 | 10 000 | **4 200** | 0 |
| **Total** | **30 550** | **24 440** | **6 110** | **0** |

**B2.** Ninguno. Power BI no arroja un error ni advierte que el cálculo a nivel del total perdió su sentido aditivo y oculta información cruzada.

**B3.**

* Suma a mano de `[Excedente]`: **9 010** (el total dice 6 110).
* Suma a mano de `[Faltante]`: **2 900** (el total dice 0).



**B4.** Al leer un Faltante de 0 en el total, finanzas asume que la empresa completa superó las metas. Como consecuencia, a La Unión (que tuvo un cumplimiento crítico del 42 %) no se le asigna el plan de apoyo que necesitaba urgentemente.

---

## PARTE C - QUÉ CALCULÓ EL TOTAL

**C1.** La fila del total hace el cálculo evaluando los valores globales directos: `MAX( 0 , 30550 - 24440 )`, lo que da 6 110. Usa el **contexto** global del total, sin importarle las filas individuales de la matriz.

**C2.** Faltan **2 900** kilos para pasar de 6 110 a 9 010. Ese es exactamente el faltante que tuvo Agrícola La Unión, el cual "se comió" el excedente global.

**C3. Punto de control 3 (Año completo):**

| Finca | `[Kilos]` | `[Meta]` | `[Excedente]` | `[Faltante]` |
| --- | --- | --- | --- | --- |
| Agricola La Union | 2 100 | 8 000 | 0 | 5 900 |
| Finca El Guayabo | 14 250 | 19 000 | 0 | 4 750 |
| Hacienda Santa Rosa | 14 200 | 20 000 | 0 | 5 800 |
| **Total** | **30 550** | **47 000** | **0** | **16 450** |

**C4.** Suma correctamente porque en el año completo ninguna finca ha superado la meta. Al estar todas con saldo negativo, el `MAX(0, ...)` se activa igual en todas las filas individuales y en el total, haciendo que la resta global coincida matemáticamente.

---

## PARTE D - SUMX

### D1 · Excedente y Faltante por finca

```dax
Excedente por finca = SUMX( dim_finca , [Excedente] )
Faltante por finca  = SUMX( dim_finca , [Faltante] )

```

**Punto de control 4:**

| Finca | `[Excedente]` | `[Excedente por finca]` | `[Faltante]` | `[Faltante por finca]` |
| --- | --- | --- | --- | --- |
| Agricola La Union | 0 | 0 | 2 900 | 2 900 |
| Finca El Guayabo | 4 810 | 4 810 | 0 | 0 |
| Hacienda Santa Rosa | 4 200 | 4 200 | 0 | 0 |
| **Total** | **6 110** | **9 010** | **0** | **2 900** |

**D2.** Recorre **una sola** finca (Finca El Guayabo). Las filas no cambiaron porque iterar sobre una tabla filtrada a un solo registro da el mismo resultado que evaluar la medida original en ese contexto.

**D3.** Se parece en que el primer parámetro (`tabla`) fuerza el grano de iteración. Le dicta a la función el nivel de detalle al que debe bajar a mirar (la finca) antes de aplicar la lógica matemática o el ranking.

---

## PARTE E - EL BONO POR MES

**E1. Punto de control 5:**

| `anio_mes` | `[Kilos]` | `[Meta]` | `[Excedente por finca]` |
| --- | --- | --- | --- |
| 2026-01 | *(vacío)* | 4 040 | 0 |
| 2026-02 | *(vacío)* | 5 200 | 0 |
| 2026-03 | 10 800 | 6 900 | 6 600 |
| 2026-04 | 19 750 | 8 300 | 11 850 |
| **Total** | **30 550** | **24 440** | **9 010** |

**E2.** La suma a mano da **18 450**; el total dice **9 010**. En la fila del total, `SUMX` está iterando correctamente las tres fincas, pero **no** está iterando los meses; para cada finca evalúa el excedente sobre el bloque completo de 4 meses sumados.

### E3 · Excedente y Faltante mensual

```dax
Excedente mensual = SUMX( dim_finca , SUMX( VALUES( dim_tiempo[anio_mes] ) , [Excedente] ) )
Faltante mensual  = SUMX( dim_finca , SUMX( VALUES( dim_tiempo[anio_mes] ) , [Faltante] ) )

```

**Punto de control 6:**

| `anio_mes` | `[Excedente por finca]` | `[Excedente mensual]` | `[Faltante mensual]` |
| --- | --- | --- | --- |
| 2026-01 | 0 | 0 | 4 040 |
| 2026-02 | 0 | 0 | 5 200 |
| 2026-03 | 6 600 | 6 600 | 2 700 |
| 2026-04 | 11 850 | 11 850 | 400 |
| **Total** | **9 010** | **18 450** | **12 340** |

**Punto de control 7:**

| Finca | `[Excedente por finca]` | `[Excedente mensual]` | `[Faltante mensual]` |
| --- | --- | --- | --- |
| Agricola La Union | 0 | 0 | 2 900 |
| Finca El Guayabo | 4 810 | 10 750 | 5 940 |
| Hacienda Santa Rosa | 4 200 | 7 700 | 3 500 |
| **Total** | **9 010** | **18 450** | **12 340** |

**E4.** Los 3 500 de diferencia provienen de los faltantes que tuvo la finca en enero y febrero (cero kilos con metas altas). Al iterar el cuatrimestre junto, esos meses malos "se comen" parte del bono de los meses buenos. Al iterar mensual, el `MAX` perdona el faltante y paga los meses buenos íntegros.

**E5.** Debe contestarlo la gerencia o el área de negocios (basados en las reglas estipuladas del bono). Si deciden el de 18 450, el título de la tabla tendría que decir **"Bono evaluado por Finca y por Mes"** para no engañar sobre cómo se hizo el corte.

---

## PARTE F - LO QUE SÍ DEBE SUMAR, Y LO QUE NO

### F1 · Neto

```dax
Neto = [Kilos] - [Meta]

```

**Punto de control 8:**

| Finca | `[Neto]` |
| --- | --- |
| Agricola La Union | −2 900 |
| Finca El Guayabo | 4 810 |
| Hacienda Santa Rosa | 4 200 |
| **Total** | **6 110** |

**F2.** Porque `[Neto]` es una operación matemática lineal (una simple resta continua), por lo que conserva la propiedad aditiva. `[Excedente]` usa `MAX`, que es una función no lineal (corta los negativos volviéndolos ceros) y destruye la linealidad.

**F3. Punto de control 9:**

| Versión | Excedente | Faltante | Excedente − Faltante |
| --- | --- | --- | --- |
| sin `SUMX` | 6 110 | 0 | **6 110** |
| `SUMX` por finca | 9 010 | 2 900 | **6 110** |
| `SUMX` por finca y mes | 18 450 | 12 340 | **6 110** |

**F4.** Es siempre **el neto global** (6 110). Lo único que cambia de una versión a otra es cuánto de ese neto se clasifica como excedente y cuánto se reconoce como faltante al bajar el microscopio (granularidad) de iteración.

**F5.** No, no está mal. Un porcentaje o un ratio es intensivo y no debe sumarse aritméticamente. Nadie lo reclama porque el negocio entiende de manera instintiva que un cumplimiento se evalúa contra su propio agregado (30 550 / 24 440) y no sumando los porcentajes sueltos de las fincas.

---

## PARTE G - PREGUNTAS DE CIERRE

1. **¿Qué calcula la fila del total?** Calcula la medida evaluando las columnas base directamente en el **contexto** global de la tabla, no sumando las filas visibles.


2. **¿Estaba mal escrito?** No estaba mal escrito matemáticamente, pero estaba incompleto lógicamente. Le faltaba bajar también la granularidad del tiempo integrando el iterador de meses.


3. **Regla de detección:** Si el total de una medida que incluye lógica condicional (como IF o MAX) no suma lo mismo que las filas visibles de la matriz, es porque se requiere un iterador (`SUMX`) para forzar la granularidad deseada.


4. **¿Qué prueba harías?** Quitaría la medida del visual agregado y crearía una matriz particionada al nivel más bajo (finca por mes o por día) para sumar a mano, validando si hay déficits ocultos compensándose con superávits.


5. **Ejemplo de medida que no suma:** Una medida de `[Precio Promedio de Venta]` o el porcentaje de `[Margen de Ganancia]`; sus totales jamás deben ser la suma de los valores individuales.



```

```