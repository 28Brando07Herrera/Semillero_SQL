# Ejercicio29_Herrera_Brando.md

# Parte A · Construcción de h_meta

## A1

Se cargaron las consultas:

```text
h_cosecha
dim_tiempo
dim_finca
dim_cultivo
metas_planeacion
```

No se cargó:

```text
h_meta.csv
```

porque la tabla fue construida en Power Query.

---

## A2

La hoja original tenía:

```text
4 filas
15 columnas
```

---

## A3

Se utilizó:

```text
Transformar
→ Anular dinamización de otras columnas
```

con:

```text
finca_id
finca
```

como columnas fijas.

Resultado:

```text
52 filas
```

---

## A4

Las columnas generadas fueron:

```text
Atributo
Valor
```

renombradas a:

```text
fecha_mes
kg_meta
```

---

## A5

Al convertir:

```text
fecha_mes
```

a tipo:

```text
Fecha
```

se generaron:

```text
4 errores
```

Mensaje observado:

```text
DataFormat.Error:
No se puede analizar la entrada proporcionada como un valor Date.

Detalles:
Total
```

---

## A6

Los errores provenían de la columna:

```text
Total
```

incluida en la hoja de planeación.

---

# Parte B · Eliminación de la columna Total

## B1

Después de eliminar las filas con error:

```text
48 filas
0 errores
```

---

## B2

Calidad de columna:

```text
finca_id
75 % válido
25 % vacío
```

La fila Total seguía existiendo como una finca sin identificador.

---

## B3

La consulta fue renombrada a:

```text
h_meta
```

---

# Parte C · Modelo

## Relaciones

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
h_meta[finca_id]
→ dim_finca[finca_id]
```

```text
h_meta[fecha_mes]
→ dim_tiempo[fecha]
```

---

## Medidas

```DAX
Kilos =
SUM(h_cosecha[kg])
```

Resultado:

```text
30550
```

---

```DAX
Meta =
SUM(h_meta[kg_meta])
```

Resultado con la fila Total:

```text
48880
```

---

```DAX
Cumplimiento =
DIVIDE(
    [Kilos],
    [Meta]
)
```

Resultado:

```text
62,50 %
```

---

```DAX
Cosechas =
COUNTROWS(h_cosecha)
```

Resultado:

```text
9
```

---

```DAX
Filas de meta =
COUNTROWS(h_meta)
```

Resultado:

```text
16
```

---

```DAX
Meta sin finca =
CALCULATE(
    [Meta],
    ISBLANK(dim_finca[finca])
)
```

Resultado:

```text
24440
```

---

# Parte D · La fila Total

## D1

Tabla de control con la fila Total todavía presente:

| Finca |