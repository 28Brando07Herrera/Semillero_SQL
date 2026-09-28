# Ejercicio 27 · Las pesadas de la báscula

- **Alumno:** Cortez Cardozo Axel Josue
- **Ejercicio / proyecto:** Ejercicio 27 · Configuración regional, parsing de fechas en Power Query y reconciliación de datos
- **Archivo:** `entregas/cortez-axel/Ejercicio27_Cortez_Axel.md`

---

# Parte A · El modelo

## A0a. Configuración regional previa

Antes de ajustarla a **Español (México)**, la configuración regional para importación del archivo se encontraba en **Español (Ecuador)** (o la predeterminada del sistema operativo).

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

### Medida Cosechas

```dax
Cosechas = COUNTROWS( h_cosecha )
```

- **Resultado:** Conteo total de filas en la tabla de hechos.

## A4. La tabla de control

**Segmentadores:** `anio = 2026`, `mes = 1 a 4`.

| Finca | [Kilos] | [Meta] | [Cumplimiento] | [Cosechas] |
|---|---:|---:|---:|---:|
| Agricola La Union | 2 100 | 5 000 | 42,00 % | 2 |
| Finca El Guayabo | 14 250 | 9 440 | 150,95 % | 3 |
| Hacienda Santa Rosa | 14 200 | 10 000 | 142,00 % | 4 |
| **Total** | **30 550** | **24 440** | **125,00 %** | **9** |

**Control superado:** El total suma exactamente **30 550 kg** en kilos, **24 440 kg** en meta, **125,00 %** de cumplimiento y **9 cosechas**.

---

# Parte B · El archivo de la báscula

## B2. Pasos aplicados automáticos en Power Query

Al conectar el archivo mediante **Transformar datos**, Power Query generó automáticamente los siguientes tres pasos:

1. **Origen:** Lectura del archivo `cosechas_bascula.csv` desde la ruta local.
2. **Encabezados promovidos:** Conversión de la primera fila en los títulos de cada columna.
3. **Tipo cambiado:** Conversión automática de tipos de datos según la configuración regional predeterminada del archivo.

## B3. Tipo de datos en la columna `fecha`

El encabezado presenta el icono de **Fecha** (calendario), indicando que el motor intentó convertir directamente los valores textuales a fechas del calendario.

## B4. Calidad de columna en `fecha`

- **Válido:** 70 %
- **Error:** 30 %
- **Vacío:** 0 %

> **Nota:** En este punto se tomó la captura `clase27-calidad.png`, mostrando la calidad de columna con **70 % válido / 30 % error**.

## B5. Mensaje literal del error

Al hacer clic en el espacio en blanco contiguo a una celda de error, se obtuvo el siguiente mensaje literal:

```text
DataFormat.Error: No pudimos analizar la entrada como un valor Date.
Detalles:
    05/14/2026
```

## B6. Identificación de las tres filas con error en el CSV

Las filas con error corresponden a los siguientes registros de `cosecha_id`:

- `cosecha_id = 27` — Texto: `05/14/2026`
- `cosecha_id = 28` — Texto: `05/20/2026`
- `cosecha_id = 35` — Texto: `08/24/2026`

### Patrón en común

El archivo viene estructurado en formato estadounidense **mes/día/año**.

Al procesarse bajo la configuración regional fijada en A0 (**día/mes/año**), el motor intentó leer el segundo número como el mes.

Como los números **14, 20 y 24** no corresponden a ningún mes del calendario, el parseo falló y marcó **Error**.

---

# Parte C · El arreglo obvio

## C1. Calidad de columna tras Quitar errores

Al aplicar **Quitar errores**, la columna `fecha` pasó a mostrar **100 % válido**, pero la tabla se redujo de **10 a 7 filas**, descartando silenciosamente las cosechas **27, 28 y 35**.

## C5. Tabla mensual de mayo a agosto tras Quitar errores

**Segmentadores:** `mes = 5 a 8`.

| nombre_mes | [Kilos] | [Cosechas] |
|---|---:|---:|
| Mayo | 2 500 | 1 |
| Junio | 4 100 | 2 |
| Julio | 3 400 | 1 |
| **Total** | **10 000** | **4** |

**Mes que falta:** Falta por completo el mes de **Agosto**.

## C6. Tabla por finca de mayo a agosto tras Quitar errores

| Finca | [Kilos] | [Meta] | [Cumplimiento] | [Cosechas] |
|---|---:|---:|---:|---:|
| Agricola La Union | 3 300 | 4 950 | 66,67 % | 2 |
| Finca El Guayabo | 1 200 | 6 760 | 17,75 % | 1 |
| Hacienda Santa Rosa | 5 500 | 4 000 | 137,50 % | 1 |
| **Total** | **10 000** | **15 710** | **64,68 %** | **4** |

## C7. Comprobación de enero a abril

**Segmentadores:** `mes = 1 a 4`.

Al regresar el segmentador a los meses 1 a 4, la tabla de control se alteró respecto a la Parte A:

| Finca | [Kilos] | [Meta] | [Cumplimiento] | [Cosechas] |
|---|---:|---:|---:|---:|
| Agricola La Union | 2 100 | 5 000 | 42,00 % | 2 |
| Finca El Guayabo | 14 650 | 9 440 | 155,19 % | 4 |
| Hacienda Santa Rosa | 14 200 | 10 000 | 142,00 % | 4 |
| **Total** | **30 950** | **24 440** | **126,64 %** | **10** |

**Finca alterada:** Cambió **Finca El Guayabo**, sumando **400 kg** y pasando de **3 a 4 cosechas**.

## C8. Identificación de la cosecha desplazada a enero-abril

Corresponde a la fila con `cosecha_id = 31`:

- **Texto en CSV:** `07/02/2026`
- **Fecha real:** 2 de julio de 2026 (mes 7, día 2).
- **Cómo la interpretó Power Query:** Leyó el valor como 7 de febrero de 2026 (día 7, mes 2), introduciéndola indebidamente dentro del rango de enero a abril.

---

# Parte D · La regla en el paso

## D1. Comparación de interpretación de fechas

| cosecha_id | Texto en el CSV | Es (mes/día) | Se leyó (día/mes) |
|---:|---|---|---|
| 26 | 05/07/2026 | 7 de mayo | 5 de julio |
| 27 | 05/14/2026 | 14 de mayo | Error (no existe mes 14) |
| 28 | 05/20/2026 | 20 de mayo | Error (no existe mes 20) |
| 29 | 06/06/2026 | 6 de junio | 6 de junio (simétrica) |
| 30 | 06/09/2026 | 9 de junio | 6 de septiembre |
| 31 | 07/02/2026 | 2 de julio | 7 de febrero |
| 32 | 07/10/2026 | 10 de julio | 7 de octubre |
| 33 | 08/05/2026 | 5 de agosto | 8 de mayo |
| 34 | 08/06/2026 | 6 de agosto | 8 de junio |
| 35 | 08/24/2026 | 24 de agosto | Error (no existe mes 24) |

**Filas que quedaron al revés sin marcar error:** 6 cosechas (**26, 30, 31, 32, 33 y 34**).

**Fila que coincidió por simetría:** La cosecha **29 (`06/06/2026`)**, dado que tanto el día como el mes son 6.

## D2. Eliminación de pasos en Power Query

En la consulta `cosechas_bascula` se eliminaron en orden los pasos:

1. **Errores quitados**
2. **Tipo cambiado**

Esto permitió restaurar la lectura original del campo de texto antes de la inferencia fallida.

## D3. Aplicación de "Usar configuración regional"

Se seleccionó la columna `fecha`, accediendo a:

**Cambiar tipo → Usar configuración regional…**

Se establecieron los siguientes valores:

- **Tipo de datos:** Fecha
- **Configuración regional:** Inglés (Estados Unidos)

El indicador de calidad pasó a **100 % válido**, preservando las **10 filas de pesadas**.

## D4. Tipos de datos numéricos

Se convirtieron las siguientes columnas a **Número entero** antes de aplicar los cambios:

- `cosecha_id`
- `finca_id`
- `cultivo_id`
- `kg`

## D5. Tabla por mes corregida

**Segmentadores:** `mes = 5 a 8`.

| nombre_mes | [Kilos] | [Cosechas] |
|---|---:|---:|
| Mayo | 5 800 | 3 |
| Junio | 4 400 | 2 |
| Julio | 1 700 | 2 |
| Agosto | 4 800 | 3 |
| **Total** | **16 700** | **10** |

## D6. Tabla por finca corregida

**Segmentadores:** `mes = 5 a 8`.

| Finca | [Kilos] | [Meta] | [Cumplimiento] | [Cosechas] |
|---|---:|---:|---:|---:|
| Agricola La Union | 3 300 | 4 950 | 66,67 % | 2 |
| Finca El Guayabo | 5 800 | 6 760 | 85,80 % | 4 |
| Hacienda Santa Rosa | 7 600 | 3 750 | 137,50 % | 4 |
| **Total** | **16 700** | **15 460** | **108,02 %** | **10** |

## D7. Validación de retorno de la tabla de control

**Segmentadores:** `mes = 1 a 4`.

Al ajustar nuevamente el segmentador a los meses 1 a 4, los valores retornaron de manera limpia al estado original de la Parte A:

- **Kilos:** 30 550
- **Meta:** 24 440
- **Cumplimiento:** 125,00 %
- **Cosechas:** 9

## D8. Explicación de la recuperación de El Guayabo de 17,75 % a 85,80 %

La **Finca El Guayabo** tenía 4 pesadas en este periodo:

- Las cosechas **27 y 28** fueron eliminadas en la Parte C por **Quitar errores**, al superar el día 12 en el campo intermedio.
- La cosecha **31 (400 kg)** se desplazó al **7 de febrero**, saliendo del filtro de meses 5 a 8.
- Únicamente la cosecha **30 (1 200 kg)** se computó en la Parte C.

Al implementar correctamente la regla en el paso, se reincorporaron las **3 cosechas faltantes**, equivalentes a **4 600 kg adicionales**.

De esta manera, El Guayabo alcanzó:

- **5 800 kg**
- **4 cosechas**
- **85,80 % de cumplimiento**

---

# Parte E · La prueba de las cuatro cifras

## E1. Medidas de conciliación de báscula

### Pesadas báscula

```dax
Pesadas bascula =
CALCULATE(
    [Cosechas],
    h_cosecha[cosecha_id] >= 26
)
```

### Kilos báscula

```dax
Kilos bascula =
CALCULATE(
    [Kilos],
    h_cosecha[cosecha_id] >= 26
)
```

### Primera pesada

```dax
Primera pesada =
CALCULATE(
    MIN( h_cosecha[fecha] ),
    h_cosecha[cosecha_id] >= 26
)
```

### Última pesada

```dax
Ultima pesada =
CALCULATE(
    MAX( h_cosecha[fecha] ),
    h_cosecha[cosecha_id] >= 26
)
```

## E2. Las cuatro tarjetas de control

En una página independiente y sin segmentadores, las tarjetas muestran:

| Tarjeta | Resultado |
|---|---|
| **Pesadas bascula** | 10 |
| **Kilos bascula** | 16 700 |
| **Primera pesada** | 7 de mayo de 2026 |
| **Ultima pesada** | 24 de agosto de 2026 |

Las cifras concuerdan de forma unívoca con el correo de operaciones emitido.

> **Nota:** En este punto se tomó la captura `clase27-bascula.png`, conteniendo las cuatro tarjetas de verificación.

## E3. Resultados teóricos con el error de la Parte C

Si las tarjetas se hubiesen calculado sobre el modelo defectuoso de la Parte C, los valores habrían sido:

- **Pesadas bascula:** 7, debido a la eliminación de las cosechas 27, 28 y 35.
- **Kilos bascula:** 13 200, correspondientes a los 16 700 kg menos los 3 500 kg de las tres filas descartadas.
- **Primera pesada:** 7 de febrero de 2026, producida por la cosecha 31 convertida erróneamente en `07/02`.
- **Ultima pesada:** 7 de octubre de 2026, producida por la cosecha 32 convertida erróneamente en `07/10`.

## E4. Riesgo de cambiar la configuración global del archivo

Si se altera la configuración regional del archivo `.pbix` completo a **Inglés (Estados Unidos)**, este CSV se leerá correctamente.

Sin embargo, cualquier otro archivo de origen que entregue fechas en formato latinoamericano, por ejemplo:

```text
05/07/2026
```

entendido como **5 de julio**, podría ser malinterpretado como **7 de mayo**.

Por este motivo, la configuración regional debe especificarse de forma localizada en el paso del archivo que la requiere.

## E5. Por qué la prueba del número viejo atrapó la cosecha 31 y no la 26

La cosecha **31 (`07/02/2026`)** tenía como mes real **7 (julio)** y, al invertirse, se convirtió en mes **2 (febrero)**. Esto provocó que ingresara incorrectamente al rango de enero a abril.

En cambio, la cosecha **26 (`05/07/2026`)** tenía como mes real **5 (mayo)** y, al invertirse, pasó a mes **7 (julio)**.

Por lo tanto, quedó fuera del filtro de meses 1 a 4 en ambos escenarios.

---

# Parte F · Preguntas de cierre

## F1. Comportamiento real de Quitar errores

**Quitar errores** descarta y suprime por completo las filas que presentan inconsistencias.

Esta acción no soluciona el formato ni preserva los datos de los registros eliminados.

## F2. Ubicación de la regla de conversión

La regla reside en el paso de transformación aplicado dentro de la consulta en Power Query (`Table.TransformColumnTypes`), donde se define la cultura regional de origen para esa columna.

## F3. Regla de detección del día

> **«Si la calidad de columna marca 100 % válido pero los números no cuadran, las fechas se están leyendo al revés sin avisar.»**

## F4. Caso bancario: Sucursal Miami

Revisaría si las fechas se cargaron con la configuración regional de **Estados Unidos**.

Un **100 % válido** no es suficiente garantía, ya que cualquier día menor o igual a 12 puede transponerse silenciosamente con el mes sin generar advertencias en el motor.

## F5. Similitud con la clase 12

Ambos escenarios comparten el descarte silencioso de registros para forzar una carga «exitosa», enmascarando una pérdida de información de negocio en lugar de atacar la causa raíz de incompatibilidad de formatos.