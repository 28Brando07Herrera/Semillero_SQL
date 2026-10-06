# Proyecto PC2 – Los Hechos

**Estudiante:** Brando Herrera

---

# Anclas del martes

| Medida | Resultado |
|---------|---------:|
| Kilos | 136.600 |
| Cosechas | 53 |
| Cosechas repetidas | 0 |
| Ingresos | 80.270 |

---

# Construcción de h_cosecha

La tabla `h_cosecha` fue construida a partir de tres fuentes:

- Carpeta `bascula`
- Archivo `bascula_digital_2026.csv`
- Archivo `precios.csv`

Durante el proceso se realizaron las siguientes actividades:

1. Combinación automática de los archivos de la carpeta `bascula`.
2. Corrección del encabezado `kg_neto` a `kg` en el archivo de agosto de 2025.
3. Exclusión del archivo duplicado `bascula_2026-03 - copia.csv`.
4. Integración de `bascula_digital_2026.csv`.
5. Incorporación de `precio_kg` mediante combinación con `precios.csv`.
6. Conversión correcta de los valores de precio utilizando configuración regional adecuada para números decimales.

---

# Relaciones creadas

```text
h_cosecha[finca_id]
→ dim_finca[finca_id]
```

```text
h_cosecha[cultivo_id]
→ dim_cultivo[cultivo_id]
```

```text
h_cosecha[fecha]
→ dim_tiempo[fecha]
```

```text
seguridad[finca_id]
→ dim_finca[finca_id]
```

---

# Medidas

## Kilos

```DAX
Kilos =
SUM(h_cosecha[kg])
```

Resultado:

```text
136.600
```

---

## Cosechas

```DAX
Cosechas =
COUNTROWS(h_cosecha)
```

Resultado:

```text
53
```

---

## Cosechas repetidas

```DAX
Cosechas repetidas =
COUNTROWS(h_cosecha)
-
DISTINCTCOUNT(h_cosecha[cosecha_id])
```

Resultado:

```text
0
```

---

## Ingresos

```DAX
Ingresos =
SUMX(
    h_cosecha,
    h_cosecha[kg] * h_cosecha[precio_kg]
)
```

Resultado:

```text
80.270
```

---

# Preguntas ciegas

## M1

**Kilos de agosto de 2025**

Pendiente de validación en la matriz por año y mes.

---

## M2

**Cosechas y kilos de septiembre de 2026**

Pendiente de validación mediante segmentación de septiembre 2026.

---

## M3

**Kilos por finca en el período del cierre**

Pendiente de validación mediante tabla por finca.

---

## M4

**Ingresos de la empresa en el período del cierre**

Resultado actual:

```text
80.270
```

---

## M5

**¿Cuántas filas tenía h_cosecha antes de corregir los problemas?**

Observaciones identificadas:

- Existía un archivo duplicado:
  ```text
  bascula_2026-03 - copia.csv
  ```
- Existía un encabezado incorrecto:
  ```text
  kg_neto
  ```
  en lugar de:
  ```text
  kg
  ```
- El proceso de combinación con precios inicialmente generó duplicidad al utilizar únicamente `cultivo_id` como llave.
- La combinación correcta se realizó mediante:
  ```text
  cultivo_id + calidad
  ```

---

# Bitácora del día

| Qué encontré | Cómo me di cuenta | Qué número daba mal | Cómo lo arreglé | Cómo sé que quedó |
|--------------|------------------|---------------------|-----------------|-------------------|
| Archivo duplicado `bascula_2026-03 - copia.csv` | Revisión de Source.Name | Kilos y cosechas aumentaban | Se filtró el archivo duplicado | Cosechas repetidas = 0 |
| Encabezado `kg_neto` | Calidad de columna mostraba valores vacíos | Kilos e ingresos disminuían | Renombrado automático `kg_neto → kg` | kg = 100 % válido |
| Fechas de archivo digital | Revisión de tipos de datos | Relación con calendario fallaba | Conversión a fecha | Relación válida con dim_tiempo |
| Lectura incorrecta de precios | Valores enteros en precio_kg | Ingresos incorrectos | Configuración regional adecuada | Precio_kg con valores decimales |
| Combinación errónea con precios | 106 filas después del merge | Cosechas = 106 | Se utilizó la llave compuesta `cultivo_id + calidad` | h_cosecha = 53 filas |

---

# Evidencias

## Captura 1

```text
proyecto-pc2-hechos.png
```

Matriz por año y mes junto a las tarjetas:

```text
Kilos
Cosechas
Cosechas repetidas
Ingresos
```

---

## Captura 2

```text
proyecto-pc2-pasos.png
```

Consulta `h_cosecha` mostrando los pasos aplicados en Power Query.