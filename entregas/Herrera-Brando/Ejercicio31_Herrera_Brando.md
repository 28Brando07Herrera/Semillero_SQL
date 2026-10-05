# Ejercicio 31 – Las pesadas de la báscula

**Estudiante:** Brando Herrera

---

# Parte A

## A3. Medida

```DAX
Meta = SUM(h_meta[kg_meta])
```

Resultado:

```text
La Unión: 5.000
El Guayabo: 9.440
Hacienda Santa Rosa: 10.000
Total: 24.440
```

## A4. Observaciones iniciales

- Filas de datos en `pesadas.csv`: **54**
- Cosechas distintas: **25**
- Camiones distintos en la cosecha 7: **3**

---

# Parte B

## B2. Medidas creadas

```DAX
Kilos = SUM(h_cosecha[kg])
```

```DAX
Cosechas = COUNTROWS(h_cosecha)
```

```DAX
Cumplimiento = DIVIDE([Kilos],[Meta])
```

```DAX
Cosechas repetidas =
[Cosechas] - DISTINCTCOUNT(h_cosecha[cosecha_id])
```

## B3. Resultado antes de agrupar

```text
Kilos: 30.550
Meta: 24.440
Cumplimiento: 125,00 %
Cosechas: 19
Cosechas repetidas: 10
```

### ¿Qué está contando [Cosechas]?

La medida está contando filas de la tabla, es decir, registros de pesadas o camiones, no cosechas únicas.

## B4. Agrupar por Básico

Agrupación realizada por:

```text
cosecha_id
```

Resultado observado:

- Filas: 25
- Columnas: 2
- Columna creada: Count
- Operación: Recuento de filas

Columnas desaparecidas:

```text
finca_id
cultivo_id
fecha
calidad
camion
kg
```

Posteriormente se eliminó el paso de agrupación.

---

# Parte C

## C1. Agrupación con camion incluido en las llaves

Llaves utilizadas:

```text
cosecha_id
finca_id
cultivo_id
fecha
calidad
camion
```

Agregación:

```text
kg = Suma(kg)
```

Resultado:

```text
36 filas
```

## C2. Resultado del control

```text
Kilos: 30.550
Meta: 24.440
Cumplimiento: 125,00 %

Cosechas: 14
Cosechas repetidas: 5
```

## C3. Análisis de la cosecha 1

Resultado después de agrupar:

```text
LRA-1101    2700
LRA-1102    1500
```

En el archivo original:

```text
LRA-1101    1500
LRA-1102    1500
LRA-1101    1200
```

### ¿Por qué tres camiones dieron dos filas?

Porque dos registros pertenecían al mismo camión (LRA-1101). Al agrupar por las llaves, Power Query consolidó ambas filas y sumó los kilos en un único registro.

## C4. Agrupación final

Llaves:

```text
cosecha_id
finca_id
cultivo_id
fecha
calidad
```

Agregaciones:

```text
kg              = Suma(kg)
pesadas         = Recuento de filas
carga_promedio  = Promedio(kg)
```

Resultado:

```text
25 filas
```

Control final:

```text
Kilos: 30.550
Meta: 24.440
Cumplimiento: 125,00 %

Cosechas: 9
Cosechas repetidas: 0
```

## C5. Pregunta de análisis

Las llaves deben contener únicamente las columnas que identifican una cosecha. No deben incluir columnas que varían entre registros de una misma cosecha, como camion o pesada_id.

Si pesada_id hubiera formado parte de las llaves, cada fila habría permanecido individual, ya que se trata de un identificador único. El resultado habría conservado las 54 filas originales.

---

# Parte D

## D1. Medida de promedio