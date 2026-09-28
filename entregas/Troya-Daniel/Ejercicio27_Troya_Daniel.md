# Ejercicio práctico 27 · Las pesadas de la báscula

**Estudiante:** Daniel Moisés Troya Riofrío  
**Entrega:** Ejercicio27_Troya_Daniel.md  
**Capturas asociadas:** `clase27-calidad.png` y `clase27-bascula.png`

---

## Parte A · El modelo

### A0a. Configuración regional previa
* **Configuración regional antes del cambio:** Español (Ecuador) / Español (Latinoamérica).  
* **Configuración fijada para la importación:** Español (México) (`dd/MM/yyyy`).

### Medidas DAX del modelo base

```dax
Kilos = SUM( h_cosecha[kg] )
-- Resultado en tabla de control: 30 550
```

```dax
Meta = SUM( h_meta[kg_meta] )
-- Resultado en tabla de control: 24 440
```

```dax
Cumplimiento = DIVIDE( [Kilos] , [Meta] )
-- Resultado en tabla de control: 125,00 %
```

```dax
Cosechas = COUNTROWS( h_cosecha )
-- Resultado en tabla de control: 9
```

### A4. Tabla de control (Filtro: Año 2026, Meses 1 a 4)

| Finca | [Kilos] | [Meta] | [Cumplimiento] | [Cosechas] |
| :--- | :--- | :--- | :--- | :--- |
| Agricola La Union | 2 100 | 5 000 | 42,00 % | 2 |
| Finca El Guayabo | 14 250 | 9 440 | 150,95 % | 3 |
| Hacienda Santa Rosa | 14 200 | 10 000 | 142,00 % | 4 |
| **Total** | **30 550** | **24 440** | **125,00 %** | **9** |

---

## Parte B · El archivo de la báscula

* **B2. Pasos que creó Power Query de forma automática:**
  1. `Origen`
  2. `Encabezados promovidos`
  3. `Tipo cambiado`
* **B3. Ícono de la columna `fecha`:** Calendario (tipo Fecha).
* **B4. Calidad de columna en `fecha`:**
  * Válido: **70 %**
  * Error: **30 %**
  * Vacío: **0 %**
* **B5. Mensaje literal de error:**
  > `DataFormat.Error: No se puede analizar la entrada proporcionada como un valor Date.`  
  > `Detalles: 05/20/2026`
* **B6. Filas con error en `cosechas_bascula.csv`:**
  * `cosecha_id` de las filas con error: **27**, **28** y **35**.
  * **Qué tienen en común sus fechas:** En el archivo de texto traen fechas en formato estadounidense `MM/dd/yyyy`: `05/14/2026`, `05/20/2026` y `08/24/2026`. Al interpretarse bajo la configuración regional `dd/MM/yyyy`, Power Query asume que el segundo valor es el mes. Como no existen los meses 14, 20 ni 24 en el calendario, la conversión falla y arroja error.

---

## Parte C · El arreglo obvio

* **C1. Calidad de columna tras «Quitar errores»:** 100 % Válido, 0 % Error, 0 % Vacío (quedan 7 filas de las 10 originales).
* **C5. Tabla por mes (Filtro: Meses 5 a 8 de 2026):**

| dim_tiempo[nombre_mes] | [Kilos] | [Cosechas] |
| :--- | :--- | :--- |
| Mayo | 2 500 | 1 |
| Junio | 4 100 | 2 |
| Julio | 3 400 | 1 |
| **Total** | **10 000** | **4** |

* **¿Qué mes falta?:** Falta el mes de **Agosto**.

* **C6. Tabla por finca (Filtro: Meses 5 a 8 de 2026):**

| Finca | [Kilos] | [Meta] | [Cumplimiento] | [Cosechas] |
| :--- | :--- | :--- | :--- | :--- |
| Agricola La Union | 2 100 | 3 150 | 66,67 % | 1 |
| Finca El Guayabo | 1 100 | 6 200 | 17,75 % | 1 |
| Hacienda Santa Rosa | 6 800 | 6 110 | 111,29 % | 2 |
| **Total** | **10 000** | **15 460** | **64,68 %** | **4** |

* **C7. Tabla de control regresando el segmentador a meses 1 a 4:**
  * Valores obtenidos: Total Kilos **30 950**, Total Cumplimiento **126,64 %**, Total Cosechas **10**.
  * **Finca que cambió:** **Hacienda Santa Rosa** subió de 14 200 kg a 14 600 kg.
* **C8. Cosecha que apareció en enero–abril:**
  * Cosecha: `cosecha_id` **31**.
  * Texto en el archivo: `07/02/2026`.
  * Día en realidad: **2 de julio de 2026**.
  * Día en que la colocó Power Query: **7 de febrero de 2026** (mes 2, quedando dentro del rango enero–abril).

---

## Parte D · La regla en el paso

### D1. Tabla de análisis de lectura de fechas

| cosecha_id | Texto en el CSV | Es (mes/día) | Se leyó (día/mes) |
| :--- | :--- | :--- | :--- |
| 26 | 05/07/2026 | 7 de mayo | 5 de julio |
| 27 | 05/14/2026 | 14 de mayo | Error |
| 28 | 05/20/2026 | 20 de mayo | Error |
| 29 | 06/06/2026 | 6 de junio | 6 de junio |
| 30 | 06/09/2026 | 9 de junio | 6 de septiembre |
| 31 | 07/02/2026 | 2 de julio | 7 de febrero |
| 32 | 07/10/2026 | 10 de julio | 7 de octubre |
| 33 | 08/05/2026 | 5 de agosto | 8 de mayo |
| 34 | 08/06/2026 | 6 de agosto | 8 de junio |
| 35 | 08/24/2026 | 24 de agosto | Error |

* **¿Cuántas quedaron al revés sin marcar error?:** **6 fechas** (`cosecha_id` 26, 30, 31, 32, 33 y 34).
* **¿Cuál salió bien y por qué?:** La cosecha **29** (`06/06/2026`), porque el día y el mes coinciden en el valor 6, leyéndose como 6 de junio en ambas reglas.

### D5. Tabla por mes corregida (Meses 5 a 8)

| nombre_mes | [Kilos] | [Cosechas] |
| :--- | :--- | :--- |
| Mayo | 5 800 | 3 |
| Junio | 4 400 | 2 |
| Julio | 1 700 | 2 |
| Agosto | 4 800 | 3 |
| **Total** | **16 700** | **10** |

### D6. Tabla por finca corregida (Meses 5 a 8)

| Finca | [Kilos] | [Meta] | [Cumplimiento] | [Cosechas] |
| :--- | :--- | :--- | :--- | :--- |
| Agricola La Union | 3 000 | 4 500 | 66,67 % | 2 |
| Finca El Guayabo | 5 320 | 6 200 | 85,80 % | 4 |
| Hacienda Santa Rosa | 8 380 | 6 094 | 137,50 % | 4 |
| **Total** | **16 700** | **15 460** | **108,02 %** | **10** |

* **D7. Verificación enero–abril:** Al volver a colocar el segmentador en meses 1 a 4, la tabla de control regresó exactamente a **30 550 kg**, **125,00 %** y **9 cosechas**.
* **D8. Explicación de El Guayabo (pasó de 17,75 % a 85,80 %):**
  * Al usar «Quitar errores» se habían eliminado las cosechas **27** (1 800 kg) y **28** (1 500 kg).
  * La cosecha **30** (2 300 kg del 9 de junio) se leyó como 6 de septiembre, desplazándose fuera del rango mayo–agosto.
  * Por ello, a El Guayabo solo se le contabilizaba la cosecha **34** (1 100 kg), dando un cumplimiento residual de $1\,100 / 6\,200 = 17,75\,\%$. Con la regla por configuración regional correcta, recuperó sus 4 cosechas reales ($5\,320 / 6\,200 = 85,80\,\%$).

---

## Parte E · La prueba de las cuatro cifras

### Medidas DAX creadas en `h_cosecha`

```dax
Pesadas bascula = CALCULATE( [Cosechas] , h_cosecha[cosecha_id] >= 26 )
-- Resultado en tarjeta: 10
```

```dax
Kilos bascula = CALCULATE( [Kilos] , h_cosecha[cosecha_id] >= 26 )
-- Resultado en tarjeta: 16 700
```

```dax
Primera pesada = CALCULATE( MIN( h_cosecha[fecha] ) , h_cosecha[cosecha_id] >= 26 )
-- Resultado en tarjeta: 07/05/2026 (7 de mayo de 2026)
```

```dax
Ultima pesada = CALCULATE( MAX( h_cosecha[fecha] ) , h_cosecha[cosecha_id] >= 26 )
-- Resultado en tarjeta: 24/08/2026 (24 de agosto de 2026)
```

### Respuestas a las preguntas E3, E4 y E5

* **E3. Valores en la versión de la Parte C y su procedencia:**
  * **Pesadas bascula (7):** Se eliminaron las 3 pesadas que tenían día intermedio superior a 12 (27, 28 y 35).
  * **Kilos bascula (13 200):** Se restaron los kilos de las 3 pesadas borradas ($16\,700 - 1\,800 - 1\,500 - 200 = 13\,200$).
  * **Primera pesada (07/02/2026):** La cosecha 31 (`07/02/2026`, 2 de julio) fue leída como 7 de febrero, quedando como la fecha mínima.
  * **Ultima pesada (07/10/2026):** La cosecha 32 (`07/10/2026`, 10 de julio) fue leída como 7 de octubre, quedando como la fecha máxima.
* **E4. ¿Por qué no cambiar la configuración regional de todo el archivo a Inglés (EE.UU.)?:**
  Funcionaría exclusivamente para este archivo, pero corrompería el resto de orígenes de datos locales (`h_cosecha`, `dim_tiempo`, etc.). El día que llegue un CSV con formato hispanoamericano (`dd/MM/yyyy`), sus fechas se invertirán silenciosamente o fallarán en días mayores a 12.
* **E5. ¿Por qué la prueba de enero–abril atrapó la cosecha 31 y no la 26?:**
  Porque la cosecha 31 (`07/02/2026`) se permutó al mes 2 (febrero), cayendo dentro del filtro 1–4; mientras que la 26 (`05/07/2026`) se permutó al mes 7 (julio), quedando fuera del cuatrimestre evaluado.

---

## Parte F · Preguntas de cierre

1. **¿Qué hace Quitar errores con una fila, y qué no hace?:**  
   Elimina la fila por completo del modelo en silencio; no corrige el valor ni soluciona el problema de formato que originó el error.

2. **¿Dónde vive la regla que dice que 05/07/2026 es el 7 de mayo: en el CSV, en la columna o en el paso?:**  
   Vive en el **paso** de transformación de Power Query (`Table.TransformColumnTypes` con el parámetro de Culture).

3. **Regla de detección del día:**  
   Si en una columna de fechas ninguna fila tiene un valor de día superior a 12, los días y los meses se están interpretando al revés de cómo fueron emitidos.

4. **Caso de la sucursal de Miami (100 % válido y ningún día > 12):**  
   Revisaría la procedencia regional del archivo y cotejaría fechas con eventos operativos conocidos, ya que al no existir días mayores a 12 todas las fechas `MM/dd/yyyy` son válidas en un entorno latino pero con días y meses completamente intercambiados.

5. **Similitud entre la clase 12 y Quitar errores:**  
   Ambos métodos descartan registros sin resolver la causa del rechazo, generando métricas aparentemente válidas pero con pérdida crítica de datos e integridad analítica.