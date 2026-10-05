# Ejercicio 30 – La carpeta de la báscula

**Estudiante:** Brando Herrera

---

# Parte A

## A3. Medidas

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

- Cantidad de archivos en la carpeta bascula: **15 archivos**.
- Cantidad esperada de filas en h_cosecha según los archivos: **31 filas**.
- Cantidad esperada de kilos para 2025: **47.000 kg**.

---

# Parte B

## Medidas creadas

```DAX
Kilos = SUM(h_cosecha[kg])
```

Resultado inicial:

```text
50.300
```

```DAX
Cosechas = COUNTROWS(h_cosecha)
```

Resultado inicial:

```text
15
```

```DAX
Cumplimiento = DIVIDE([Kilos],[Meta])
```

Resultado inicial:

```text
205,81 %
```

---

# Parte C

## C1. Tabla de control antes de corregir la copia

```text
La Unión              3.000      60,00 %
El Guayabo           28.500     301,91 %
Hacienda Santa Rosa  18.800     188,00 %

Total:
Kilos: 50.300
Meta: 24.440
Cumplimiento: 205,81 %
Cosechas: 15
```

## C3. Quitar duplicados

Cantidad de filas luego de intentar quitar duplicados:

```text
31 filas
```

¿Por qué no se eliminaron?

Porque las filas provenientes del archivo duplicado poseen un valor diferente en la columna **Source.Name**, por lo que Power Query las considera registros distintos aunque los datos de cosecha sean iguales.

## C4. Medida de detección

```DAX
Cosechas repetidas =
[Cosechas] - DISTINCTCOUNT(h_cosecha[cosecha_id])
```

Resultado antes del filtro:

```text
6
```

Resultado después del filtro:

```text
0
```

## C6. Pregunta de análisis

El filtro que excluye archivos cuyo nombre contiene la palabra **copia** elimina únicamente el archivo duplicado actual.

Si en el futuro apareciera un archivo llamado:

```text
bascula_2026-05 (2).csv
```

el filtro no lo detectaría.

Las medidas que permitirían identificar el problema serían:

- Cosechas repetidas.
- Kilos.
- Cosechas.

ya que presentarían totales superiores a los esperados.

---

# Parte D

## D1. Tabla de los años antes de la corrección

```text
2025    44.150    16
2026    30.550     9

Total:
74.700    25
```

## D2. Mes con problema

El mes que presenta cosechas registradas pero sin kilos es:

```text
Julio 2025
```

## D3. Calidad de columna

Resultado observado en la columna kg:

```text
92 % válido
0 % error
8 % vacío
```

Filtrando únicamente valores nulos se encontraron:

```text
bascula_2025-07.csv
cosecha_id 19

bascula_2025-07.csv
cosecha_id 20
```

## D4. Encabezados de los archivos

Archivo correcto:

```text
cosecha_id,finca_id,cultivo_id,fecha,calidad,kg
```

Archivo de julio:

```text
cosecha_id,finca_id,cultivo_id,fecha,calidad,kg_neto
```

¿Qué cambió?

La columna **kg** fue reemplazada por **kg_neto**.

¿Por qué Power Query no generó Error?

Porque el archivo mantenía una estructura válida; solamente cambió el nombre de una columna, por lo que los valores quedaron como nulos al momento de expandirse.

## D5. Medida de validación

```DAX
Cosechas sin kilos =
COUNTROWS(
    FILTER(
        h_cosecha,
        ISBLANK(h_cosecha[kg])
    )
)
```

Resultado antes de la corrección:

```text
2
```

Resultado después de la corrección:

```text
Vacío
```

## D6. Validación manual de archivos

| Archivo | Kilos archivo |
|----------|----------:|
| bascula_2025-05.csv | 4.200 |
| bascula_2025-06.csv | 3.100 |
| bascula_2025-07.csv | 2.850 |
| bascula_2025-08.csv | 5.600 |
| Total | 15.750 |

Antes de la corrección Power BI mostraba:

```text
12.900
```

Después de la corrección:

```text
15.750
```

## D7. Análisis

¿Por qué julio nunca fue detectado por el control enero-abril?

Porque el tablero de control estaba filtrado únicamente para los meses de enero a abril de 2026, mientras que el problema se encontraba en julio de 2025.

¿Por qué eliminar los null funcionó en una clase anterior y hoy no?

En la clase anterior los valores nulos representaban registros inválidos. En este ejercicio los valores nulos correspondían a información válida que se perdió debido a un encabezado incorrecto, por lo que eliminar los registros habría significado perder datos reales.

---

# Parte E

## E2. Corrección realizada

Se agregó el siguiente paso dentro de la función Transformar archivo:

```PowerQuery
Table.RenameColumns(
    #"Encabezados promovidos",
    {{"kg_neto","kg"}},
    MissingField.Ignore
)
```

## E3. Calidad final

```text
100 % válido
0 % vacío
0 % error
```

## E4. Resultado final

```text
2025    47.000    16
2026    30.550     9

Total:
77.550    25
```

```text
Cosechas repetidas = 0
```

```text
Cosechas sin kilos = Vacío
```

## E6. Respuesta

Sí.

Las tres respuestas iniciales fueron correctas:

- 15 archivos.
- 31 filas iniciales.
- 47.000 kg para 2025.

---

# Parte F

## F1. Línea de expansión

```PowerQuery
Table.ExpandTableColumn(#"Se han quitado otras columnas.", "Transformar archivo", Table.ColumnNames(#"Transformar archivo"(#"Archivo de ejemplo")))
```

¿De dónde obtiene las columnas?

Obtiene la lista de columnas desde el archivo de ejemplo utilizado durante el proceso de combinación de archivos.

## F2. Archivo de ejemplo incorrecto

Si el archivo de ejemplo hubiera sido el de julio, Power Query habría tomado la estructura con la columna **kg_neto** como referencia. Los demás archivos contienen la columna **kg**, por lo que los problemas se habrían propagado al resto de la carga.

## F3. Preguntas finales

### 1. ¿Qué hace Combinar archivos?

Une todos los archivos de una carpeta en una sola tabla agregando sus filas en un conjunto consolidado.

### 2. Regla de detección del día

Un cambio en el nombre de una columna puede provocar pérdida de datos sin generar errores visibles en Power Query.

### 3. ¿Por qué se detectó la copia de abril y no julio?

La copia de abril incrementó los totales y duplicó cosechas dentro del período analizado. Julio mantuvo las cosechas pero perdió los kilos debido a una diferencia en el encabezado del archivo.

### 4. ¿Por qué el renombrado se realiza en Transformar archivo?

Porque la corrección debe aplicarse a todos los archivos que ingresen desde la carpeta y no únicamente al resultado consolidado.

### 5. Si en noviembre aparece una columna llamada "kilos"

El proceso podría volver a presentar valores vacíos debido a un nombre de columna diferente al esperado. La medida **Cosechas sin kilos** ayudaría a identificar el problema durante la validación.