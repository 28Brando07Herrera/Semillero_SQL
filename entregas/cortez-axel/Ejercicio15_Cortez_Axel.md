# Ejercicio práctico 15 · Escribe las medidas, y rompe el promedio a propósito

- **Alumno:** Cortez Cardozo Axel Josue

---

## Parte A · La estrella, sin Oracle

### A1 y A2 · Verificación de tipos de datos
Los tres campos requeridos (`h_cosecha[kg]`, `h_cosecha[fecha]` y `dim_tiempo[fecha]`) se importaron con el tipo de dato correcto de manera automática gracias al formato ISO estándar `AAAA-MM-DD` de los CSV de origen.

### A3 · Relaciones en la vista Modelo
- **Relaciones detectadas automáticamente por Power BI (2):**
  - `h_cosecha[finca_id]` -> `dim_finca[finca_id]`
  - `h_cosecha[cultivo_id]` -> `dim_cultivo[cultivo_id]`
- **Relaciones dibujadas manualmente (1):**
  - `h_cosecha[fecha]` -> `dim_tiempo[fecha]`
- **Configuración de las tres:** Cardinalidad Muchos a uno (`*:1`), dirección de filtro cruzado Simple (apuntando hacia la dimensión).

---

## Parte B · Tus primeras medidas

### B1 · Kilos

```dax
Kilos = SUM(h_cosecha[kg])
```

Resultado: 30550

### B2 · Cosechas

```dax
Cosechas = COUNTROWS(h_cosecha)
```

Resultado: 9

### B3 · Punto de control 2

| Finca | Kilos | Cosechas |
|---|---|---|
| Finca El Guayabo | 14 250 | 3 |
| Hacienda Santa Rosa | 14 200 | 4 |
| Agricola La Union | 2 100 | 2 |
| **Total** | **30 550** | **9** |

### B4 · ¿El total de una tabla es siempre la suma de las filas de arriba?
No. En DAX la fila de total no realiza una suma visual de los renglones anteriores, sino que evalúa la misma expresión en un contexto de filtro sin segmentar (evaluando la tabla completa).

---

## Parte C · Medida contra columna calculada

### C1 · Columna calculada tamano

```dax
tamano = IF( h_cosecha[kg] >= 3000, "grande", "chica" )
```

#### Punto de control 3

| tamano | Kilos | Cosechas |
|---|---|---|
| grande | 22 500 | 4 |
| chica | 8 050 | 5 |
| **Total** | **30 550** | **9** |

### C2 · Columna vs Medida sin filtros

Columna calculada en `h_cosecha`:
```dax
pct_columna = h_cosecha[kg] / SUM(h_cosecha[kg])
```

Medida:
```dax
Pct medida = DIVIDE( [Kilos] , CALCULATE( [Kilos] , ALL(h_cosecha) ) )
```

*Observación sin filtro:* En la tabla sin segmentador activo, `pct_columna` y `[Pct medida]` muestran exactamente los mismos valores porcentuales fila por fila.

### C3 · Con segmentador en Agricola La Union (Punto de control 4)

| Cosecha | pct_columna | [Pct medida] |
|---|---|---|
| cosecha 8 | 3,93 % | 57,14 % |
| cosecha 9 | 2,95 % | 42,86 % |
| **Total** | **6,87 %** | **100,00 %** |

### C4 · ¿Por qué la diferencia entre columna y medida?
La columna calculada se evaluó una sola vez durante la carga de datos, dejando congelado el denominador en 30 550 kg; la medida se evalúa dinámicamente en tiempo de ejecución respetando el contexto de filtro del segmentador (2 100 kg).

### C5 · ¿Cuál contesta la pregunta de negocio?
`[Pct medida]` contesta la pregunta «qué parte de esta finca aporta cada cosecha» porque responde al filtro; `pct_columna` contesta una pregunta distinta (el peso relativo de cada cosecha sobre el total histórico global).

---

## Parte D · Contexto de filtro

### D1 · Porcentaje mal escrito

```dax
Pct mal = DIVIDE( [Kilos] , [Kilos] )
```

#### Punto de control 5
En la tabla por finca, las tres filas muestran exactamente **100,00 %**.

### D2 · ¿Por qué no da un número distinto arriba y abajo?
Porque en cada fila de la visual opera el mismo contexto de filtro tanto en el numerador como en el denominador (por ejemplo, `14 250 / 14 250`), dividiendo el valor exacto entre sí mismo.

### D3 · Versión correcta con ALL

```dax
Pct del total = DIVIDE( [Kilos] , CALCULATE( [Kilos] , ALL(dim_finca) ) )
```

#### Punto de control 6

| Finca | Kilos | Pct del total |
|---|---|---|
| Finca El Guayabo | 14 250 | 46,64 % |
| Hacienda Santa Rosa | 14 200 | 46,48 % |
| Agricola La Union | 2 100 | 6,87 % |
| **Total** | **30 550** | **100,00 %** |

### D4 · Reemplazo por ALL(dim_cultivo)
Al cambiar por `ALL(dim_cultivo)` vuelve a dar 100 % en cada fila porque la tabla visual filtra por `dim_finca[finca]`, y limpiar los filtros de la dimensión cultivo no remueve el filtro de finca que sigue activo en el denominador.

---

## Parte E · La trampa del día

### E1 · Promedio escrito ingenuamente

```dax
Promedio por cultivo MAL = DIVIDE( [Kilos] , COUNTROWS(dim_cultivo) )
```

Resultado en tarjeta: **5 091,67**

### E2 · Mensaje de error de Power BI
Ninguno. Power BI no arrojó ningún error ni advertencia; ejecutó la operación matemática y mostró un número aparentemente válido pero conceptualmente erróneo.

### E3 · Origen matemático del 5 091,67
El cálculo manual fue:
`30 550 / 6 = 5 091,67`
Power BI dividió el total de kilos (30 550) entre el total de filas del catálogo `dim_cultivo` (6).

### E4 · Denominador en pantalla (Punto de control 8)

```dax
Cultivos en la dimension = COUNTROWS(dim_cultivo)
```
Resultado: **6**

```dax
Cultivos con cosecha = DISTINCTCOUNT(h_cosecha[cultivo_id])
```
Resultado: **4**

### E5 · Cultivos sobrantes
Los cultivos sobrantes en el denominador son **Aguacate Hass** y **Mango Tommy**. Existen en `dim_cultivo` porque forman parte del catálogo general de la empresa, aunque todavía no registran cosechas efectivas en la tabla de hechos.

### E6 · Promedio correcto

```dax
Promedio por cultivo = DIVIDE( [Kilos] , DISTINCTCOUNT(h_cosecha[cultivo_id]) )
```

Resultado en tarjeta: **7 637,50** (`30 550 / 4`)

### E7 · Con segmentador en tipo perenne (Punto de control 10)

| Medida | Valor |
|---|---|
| `[Kilos]` | 20 750 |
| Cultivos en la dimension | 5 |
| Cultivos con cosecha | 3 |
| Promedio por cultivo MAL | 4 150,00 |
| Promedio por cultivo | 6 916,67 |

### E8 · ¿Por qué la primera medida está mal?
No está mal por no responder al filtro (ambas se mueven), sino porque asume que el universo del catálogo equivale a los cultivos activos, dividiendo entre todos los existentes en vez de los que realmente tuvieron producción.

### E9 · ¿Cuándo deja de estar bien tener filas no usadas en una dimensión?
Deja de estar bien en el momento en que se utiliza la tabla de dimensión como base de agregación o denominador cuantitativo para medir eventos transaccionales del hecho.

---

## Parte F · Preguntas de cierre

1. **Diferencia entre medida y columna calculada:** La columna calculada se procesa durante la carga/actualización del modelo y se almacena en memoria; la medida se evalúa dinámicamente en tiempo de ejecución al momento de renderizar los visuales e interactuar con los filtros.
2. **Qué calcula la fila del total:** Evalúa la medida original aplicando el contexto de filtro general de la consulta visual, omitiendo las restricciones impuestas por las filas individuales.
3. **Significado de ALL(dim_finca):** Instruye a la fórmula a remover o ignorar cualquier filtro proveniente de las columnas de la tabla `dim_finca`.
4. **Qué tienen en común los errores:** Son errores silenciosos de lógica de negocio: fórmulas y consultas técnicamente válidas que no emiten alertas pero producen números engañosos.
5. **Independencia del modelo y comparación con vista plana:** Demuestra que el modelo dimensional desacopla la lógica analítica del motor de base de datos; si se hubiera usado una vista plana (`v_bi_produccion`), se habrían perdido las dimensiones puras y se habría dificultado la distinción entre entidades del catálogo y registros de actividad sin incurrir en duplicaciones por granularidad.