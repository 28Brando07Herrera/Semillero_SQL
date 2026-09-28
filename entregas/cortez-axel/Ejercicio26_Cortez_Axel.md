# Ejercicio 26 · Los kilos entregados

- **Alumno:** Cortez Cardozo Axel Josue
- **Ejercicio / proyecto:** Ejercicio 26 · Relaciones inactivas, USERELATIONSHIP y cálculo entre fechas con DATEDIFF
- **Archivo:** `entregas/cortez-axel/Ejercicio26_Cortez_Axel.md`

---

# Parte A · El modelo

## A1a. Tipo de dato de `fecha_entrega`

En la vista de tabla, la columna `h_cosecha[fecha_entrega]` se validó y configuró con tipo de dato **Fecha** (`Date`), evitando que el motor la trate como texto e impida relacionarla con la dimensión calendario.

## A3. El calendario y las medidas

### Medida Kilos

```dax
Kilos = SUM( h_cosecha[kg] )
```

- **Resultado:** Medida base de kilos cortados.

### Medida Meta

```dax
Meta = SUM( h_meta[kg_meta] )
```

- **Resultado:** Medida base de metas presupuestadas.

### Medida Cumplimiento

```dax
Cumplimiento = DIVIDE( [Kilos] , [Meta] )
```

- **Resultado:** Medida base con formato de porcentaje y dos decimales.

## A4. La tabla de control

**Segmentadores:** `anio = 2026`, `mes = 1 a 4`.

| Finca | [Kilos] | [Meta] | [Cumplimiento] |
|---|---:|---:|---:|
| Agricola La Union | 2 100 | 5 000 | 42,00 % |
| Finca El Guayabo | 14 250 | 9 440 | 150,95 % |
| Hacienda Santa Rosa | 14 200 | 10 000 | 142,00 % |
| **Total** | **30 550** | **24 440** | **125,00 %** |

**Control superado:** el total suma **30 550 kg** en kilos, **24 440 kg** en meta y **125,00 %** de cumplimiento.

---

# Parte B · La segunda relación

## B1. Creación de la relación

Se arrastró el campo `h_cosecha[fecha_entrega]` sobre `dim_tiempo[fecha]` en la vista de modelo.

## B2. Aspecto visual de la segunda relación

La línea entre `h_cosecha[fecha_entrega]` y `dim_tiempo[fecha]` se dibuja como una **línea punteada**, lo que indica que se trata de una relación inactiva dentro del modelo.

## B3. Relaciones en Administrar relaciones

1. `h_cosecha[fecha]` → `dim_tiempo[fecha]` — Varios a uno, **Activa**.
2. `h_cosecha[fecha_entrega]` → `dim_tiempo[fecha]` — Varios a uno, **Inactiva**.

## B4. Razón de inactividad

Power BI no permite dos relaciones activas simultáneas entre las mismas dos tablas porque crearía ambigüedad en el motor de filtrado. Por ejemplo, un filtro como `mes = 4` no sabría si debe propagarse sobre las filas cuya cosecha ocurrió en abril o sobre aquellas cuya entrega se completó en abril.

> **Nota:** En este punto se tomó la captura `clase26-modelo.png` con las seis relaciones: cinco continuas y una punteada.

---

# Parte C · La medida obvia

## C1. Medida preliminar

```dax
Kilos entregados = SUM( h_cosecha[kg] )
```

- **Resultado:** 30 550 kg, correspondientes al total acumulado de enero a abril.

## C2. Tabla por mes con la medida preliminar (`SUM`)

| nombre_mes | [Kilos] | [Kilos entregados] |
|---|---:|---:|
| Marzo | 10 800 | 10 800 |
| Abril | 19 750 | 19 750 |
| **Total** | **30 550** | **30 550** |

## C3. Comportamiento de la cosecha 7

La cosecha 7, correspondiente a maíz de **9 800 kg** cortado el **30 de abril**, tiene `fecha_entrega = 2026-05-12`, es decir, mayo.

Sin embargo, la medida preliminar la cuenta en **abril**, porque sigue respondiendo a la relación activa correspondiente a la fecha de corte.

## C4. Comportamiento del motor tabular

Power BI no arrojó ningún error sintáctico ni mensaje de advertencia. Simplemente ignoró la relación inactiva porque las medidas comunes resuelven el contexto de filtro a través del camino activo por defecto.

---

# Parte D · USERELATIONSHIP

## D1. Medida corregida con `USERELATIONSHIP`

```dax
Kilos entregados =
CALCULATE(
    [Kilos],
    USERELATIONSHIP(
        h_cosecha[fecha_entrega],
        dim_tiempo[fecha]
    )
)
```

- **Resultado:** 21 050 kg, correspondientes al total general de enero a abril.

## D2. Tabla por mes con `USERELATIONSHIP`

**Segmentadores:** `mes = 1 a 4`.

| nombre_mes | [Kilos] | [Kilos entregados] |
|---|---:|---:|
| Enero |  | 1 200 |
| Marzo | 10 800 | 9 600 |
| Abril | 19 750 | 10 250 |
| **Total** | **30 550** | **21 050** |

> **Nota:** En este punto se tomó la captura `clase26-entregas.png`.

## D3. Cosecha de 1 200 kg en enero

Corresponde a la fila con **`cosecha_id = 8`**.

Esta cosecha:

- Se cortó el `2025-12-28`.
- Se entregó el `2026-01-24`.
- Para `[Kilos]` contó en el año **2025**.
- Para `[Kilos entregados]` cuenta en **enero de 2026**.

## D4. Desglose de los 9 500 kg de diferencia

### Kilos que salen

Las siguientes cosechas fueron cortadas en abril, pero entregadas en mayo:

- **Cosecha 6:** 1 850 kg.
- **Cosecha 7:** 9 800 kg.

En total salen:

**−11 650 kg**

### Kilos que entran

La cosecha 8 fue cortada en diciembre de 2025, pero entregada en enero de 2026:

**+1 200 kg**

### Efecto neto

```text
-11 650 + 1 200 = -9 500 kg
```

Por lo tanto, la diferencia neta es de **−9 500 kg**.

## D5. Año 2026 completo sin filtro de mes

Al evaluar todo el año 2026:

- `[Kilos]` = **30 550**
- `[Kilos entregados]` = **31 750**

Además, aparece el mes de **mayo** con **10 700 kg entregados**, correspondientes a la suma de las cosechas 6 y 7.

## D6. Tabla por finca agregando `[Kilos entregados]`

| Finca | [Kilos] | [Meta] | [Cumplimiento] | [Kilos entregados] |
|---|---:|---:|---:|---:|
| Agricola La Union | 2 100 | 5 000 | 42,00 % | 2 400 |
| Finca El Guayabo | 14 250 | 9 440 | 150,95 % | 4 450 |
| Hacienda Santa Rosa | 14 200 | 10 000 | 142,00 % | 14 200 |
| **Total** | **30 550** | **24 440** | **125,00 %** | **21 050** |

Ni `[Kilos]` ni `[Cumplimiento]` cambiaron porque continúan evaluándose a través del camino activo correspondiente a la fecha de corte: `h_cosecha[fecha]`.

---

# Parte E · ¿Y si activo la otra?

## E1. Conmutación de relaciones en Administrar relaciones

Se desactivó primero la relación activa entre:

`h_cosecha[fecha]` → `dim_tiempo[fecha]`

Posteriormente, se marcó como activa la relación:

`h_cosecha[fecha_entrega]` → `dim_tiempo[fecha]`

## E2. Tabla con relación activa en `fecha_entrega`

Sin modificar las medidas existentes, los resultados fueron:

| Finca | [Kilos] | [Meta] | [Cumplimiento] |
|---|---:|---:|---:|
| Agricola La Union | 2 400 | 5 000 | 48,00 % |
| Finca El Guayabo | 4 450 | 9 440 | 47,14 % |
| Hacienda Santa Rosa | 14 200 | 10 000 | 142,00 % |
| **Total** | **21 050** | **24 440** | **86,13 %** |

## E3. Caída de Finca El Guayabo a 47,14 %

Finca El Guayabo baja su cumplimiento porque sus cosechas:

- **Cosecha 6:** 1 850 kg.
- **Cosecha 7:** 9 800 kg.

fueron entregadas en el mes de **mayo**, por lo que quedan excluidas del rango temporal evaluado de enero a abril.

## E4. Por qué `[Meta]` no cambió

La medida `[Meta]` no cambió porque la tabla de presupuestos `h_meta` se vincula a `dim_tiempo` mediante su propia relación en `fecha_mes`, la cual se mantuvo inalterada.

## E5. Retorno de la relación

Finalmente:

1. Se desactivó la relación basada en `fecha_entrega`.
2. Se reactivó la relación basada en `h_cosecha[fecha]`.

La tabla por finca volvió inmediatamente a:

- **30 550 kg**.
- **125,00 %** de cumplimiento.

## E6. Impacto colateral de mantener activa `fecha_entrega`

Mantener `fecha_entrega` como relación activa podría alterar otros indicadores del reporte.

Por ejemplo, los semáforos condicionales podrían pintar en rojo a fincas con alta productividad en campo pero con rezago logístico.

Además, métricas anuales acumuladas como `TOTALYTD` o comparaciones interanuales mediante `SAMEPERIODLASTYEAR` medirían los tiempos de despacho o entrega en lugar del ciclo productivo agronómico.

---

# Parte F · Días a la entrega

## F1. Medida

```dax
Dias a la entrega =
AVERAGEX(
    h_cosecha,
    DATEDIFF(
        h_cosecha[fecha],
        h_cosecha[fecha_entrega],
        DAY
    )
)
```

- **Formato:** Número decimal con 2 decimales.

## F2. Tabla por cultivo

**Segmentadores:** `anio = 2026`, `mes = 1 a 4`.

| Cultivo | [Dias a la entrega] |
|---|---:|
| Mango | 2,00 |
| Guayaba | 2,00 |
| Maiz | 12,00 |
| Cacao | 27,00 |
| **Total** | **8,67** |

## F3. Explicación del total 8,67

`AVERAGEX` calcula la media evaluando fila a fila cada cosecha individual incluida en el periodo.

En este caso existen **78 días totales** distribuidos entre **9 cosechas activas**:

```text
78 / 9 = 8,67 días
```

Por lo tanto, el resultado total es **8,67 días**.

Este resultado no corresponde al promedio simple de las medias de los cuatro cultivos:

```text
(2 + 2 + 12 + 27) / 4
= 43 / 4
= 10,75 días
```

La diferencia se debe a que `AVERAGEX` evalúa las filas individuales y no realiza un promedio de los promedios mostrados por cultivo.

## F4. Filtrado del segmentador en `DATEDIFF`

Aunque `DATEDIFF` opera a nivel de fila entre dos columnas de la misma tabla, el segmentador de mes determina cuáles filas entran en la evaluación.

Esto ocurre mediante la relación activa principal:

`h_cosecha[fecha]` → `dim_tiempo[fecha]`

Es decir, el filtro temporal sigue utilizando la **fecha de corte**.

---

# Parte G · Preguntas de cierre

## G1. Estado de una relación inactiva

Una relación inactiva permanece latente dentro del modelo sin propagar filtros ni intervenir directamente en las visualizaciones.

Solo entra en funcionamiento cuando una medida la invoca explícitamente mediante `USERELATIONSHIP`.

## G2. Cuándo cambiar la relación activa y cuándo usar `USERELATIONSHIP`

Conviene cambiar la relación activa cuando el proceso central del modelo pasa a ser, de manera fija, la **entrega**.

En cambio, se utiliza `USERELATIONSHIP` cuando ambos procesos —**corte y entrega**— deben coexistir y compararse dentro del mismo reporte.

De esta forma, se mantiene una relación principal activa y se utiliza la relación alternativa únicamente en las medidas que la necesitan.

## G3. Regla de detección del día

> **«Si dos medidas con nombres de procesos distintos dan exactamente los mismos números, ambas están viajando por la misma relación activa.»**

Esta regla permite detectar rápidamente si una medida que debería utilizar otra fecha continúa siendo evaluada mediante la relación activa predeterminada.

## G4. Caso bancario: solicitud vs. aprobación

En un modelo bancario que contenga una fecha de solicitud y una fecha de aprobación, revisaría primero cuál de las dos fechas mantiene la relación activa con la dimensión calendario.

Esto permitiría determinar mediante qué proceso temporal se están propagando actualmente los filtros del reporte.

## G5. Meta de entregas con `h_meta`

La tabla `h_meta` utiliza la **fecha de corte**, mediante el campo `fecha_mes`.

Por lo tanto, no tendría sentido utilizar directamente esta meta como una meta de entregas, ya que las metas operativas de producción no contemplan los días de rezago logístico que pueden desplazar las entregas hacia meses posteriores.