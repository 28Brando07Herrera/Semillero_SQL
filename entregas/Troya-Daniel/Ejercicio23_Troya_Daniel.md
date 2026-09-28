# Ejercicio práctico 23 · Un semáforo que no mienta

**Estudiante:** Daniel Moises Troya Riofrio

---

## Parte A · Las dos tablas

### A1. Configuración de los segmentadores
* `anio` = 2026
* `mes` = 1, 2, 3, 4
* `tipo` = sin selección

### A2. Tabla por finca

| Finca | [Kilos] | [Meta] | [Cumplimiento] |
| :--- | :--- | :--- | :--- |
| Agricola La Union | 2 100 | 5 000 | 42,00 % |
| Finca El Guayabo | 14 250 | 9 440 | 150,95 % |
| Hacienda Santa Rosa | 14 200 | 10 000 | 142,00 % |
| **Total** | **30 550** | **24 440** | **125,00 %** |

### A3. Tabla por cultivo

| Cultivo | [Kilos] |
| :--- | :--- |
| Mango | 12 700 |
| Maiz | 9 800 |
| Guayaba | 5 950 |
| Cacao | 2 100 |

*(Nota: Banano y Café no aparecen en la tabla porque no registran kilos cosechados en el periodo filtrado de 2026).*

---

## Parte B · Degradado y reglas

### B1. El degradado
* **B1a.** Cultivo más oscuro: **Mango** (12 700). Cultivo en blanco: **Cacao** (2 100).
* **B1b. Cuenta a mano del porcentaje de escala para Maíz:**
  $$\text{Porcentaje de escala} = \frac{\text{Valor} - \text{Mínimo}}{\text{Máximo} - \text{Mínimo}} = \frac{9\,800 - 2\,100}{12\,700 - 2\,100} = \frac{7\,700}{10\,600} \approx 0{,}726415 \rightarrow \mathbf{72{,}64\,\%}$$
  *(Para Guayaba: $\frac{5\,950 - 2\,100}{10\,600} = \frac{3\,850}{10\,600} \approx \mathbf{36{,}32\,\%}$).*

### B2 · Regla de 5 000 kilos

| Si el valor | y | Tipo | Color |
| :--- | :--- | :--- | :--- |
| >= 0 | < 5000 | Número | rojo |
| >= 5000 | <= 100000 | Número | verde |

* **Resultado:** Mango verde · Maiz verde · Guayaba verde · Cacao rojo

### B3. Pregunta de control sobre el techo
Quedaría en **blanco (sin formato)**, ya que 150 000 excede el límite superior estricto `<= 100000` definido en las reglas.

---

## Parte C · Verde si cumple (es la parte que más vale)

### C1 · Regla en [Cumplimiento] (la trampa del porcentaje)

| Si el valor | y | Tipo | Color |
| :--- | :--- | :--- | :--- |
| >= 0 | < 100 | Porcentaje | rojo |
| >= 100 | <= 200 (o abierto) | Porcentaje | verde |

* **Resultado inicial:** Agricola La Union rojo · Finca El Guayabo verde · Hacienda Santa Rosa rojo

### C2. Mensaje de error o advertencia de Power BI sobre el 200 %
Al intentar ingresar `200` en el límite superior con tipo *Porcentaje*, Power BI no permite guardar y muestra un ícono de advertencia rojo `(i)` deshabilitando el botón **Aceptar**. Esto ocurre porque en el modo *Porcentaje*, Power BI normaliza la escala de la vista entre 0 % (mínimo) y 100 % (máximo relativo), impidiendo definir un valor mayor al 100 % del rango visible a menos que el límite superior se deje en blanco (abierto).

### C3. Evaluación de Hacienda Santa Rosa
Hacienda Santa Rosa sí cumplió la meta holgadamente (alcanzó 142,00 %, superando el 100 % requerido). Debería tener color **verde**, pero en la tabla tiene color **rojo**.

### C4. Porcentaje, ¿de qué?
En una regla de formato condicional, *Porcentaje* no evalúa el número matemático en sí, sino la posición relativa del valor dentro del rango visible:

$$\text{porcentaje del rango} = \frac{\text{valor} - \text{mínimo}}{\text{máximo} - \text{mínimo}}$$

**C4a. Cálculo a mano para Hacienda Santa Rosa:**
* Mínimo visible de la tabla (La Unión): $42{,}00\,\% = 0{,}42$
* Máximo visible de la tabla (El Guayabo): $150{,}95\,\% = 1{,}5095$
* Valor de Santa Rosa: $142{,}00\,\% = 1{,}42$

$$\text{porcentaje del rango} = \frac{1{,}42 - 0{,}42}{1{,}5095 - 0{,}42} = \frac{1{,}00}{1{,}0895} \approx 0{,}91785 \rightarrow \mathbf{91{,}78\,\%}$$

Santa Rosa queda en el 91,78 % del rango, por lo que entra en la regla `< 100 %` y se pinta de rojo.

### C5. Análisis de la regla
En el rango de «100 a 200 % del rango» solo cabe exactamente la fila que posea el valor máximo de la tabla (Finca El Guayabo con el 100 % del rango). Por lo tanto, la regla no respondía a *«¿cumplió la meta?»*, sino a *«¿es esta finca la número uno visible de la tabla?»*.

### C6 · La prueba con el segmentador (`tipo = perenne`)

| Finca | [Cumplimiento] | Porcentaje del rango | Color |
| :--- | :--- | :--- | :--- |
| Agricola La Union | 42,00 % | 0,00 % | rojo |
| Finca El Guayabo | 47,14 % | 5,14 % | rojo |
| Hacienda Santa Rosa | 142,00 % | 100,00 % | verde |

* **Resultado:** Agricola La Union rojo · Finca El Guayabo rojo · Hacienda Santa Rosa verde

### C7. Por qué cambió el color de Santa Rosa
El cumplimiento de Santa Rosa no cambió (siguió en 142,00 %), pero al filtrar por perenne, El Guayabo bajó a 47,14 %. Esto convirtió a Santa Rosa en el nuevo valor máximo visible de la tabla (100 % del rango relativo), cumpliendo la condición `>= 100 %` de la regla y pintándose de verde.

### C8. Prueba de la regla con tipo Número (0 / 100 / 200)
Todas las fincas salen en **rojo**. En DAX y Power BI, los porcentajes son números decimales (142,00 % equivale internamente al valor numérico `1.42`). Al ingresar 0, 100 y 200 con tipo Número, los tres valores (`0.42`, `1.5095` y `1.42`) son estrictamente menores a 100, cayendo todos en la regla roja.

---

## Parte D · El color como medida

### D1 · Regla con Número, bien escrita (decimales)

| Si el valor | y | Tipo | Color |
| :--- | :--- | :--- | :--- |
| >= 0 | < 1 | Número | rojo |
| >= 1 | <= 2 | Número | verde |

* **Resultado:** Agricola La Union rojo · Finca El Guayabo verde · Hacienda Santa Rosa verde
* **D1a.** Una finca al 250 % (valor `2.5`) quedaría en **blanco (sin formato)** al exceder el límite `<= 2`.

### D2. La medida de color

```dax
Color cumplimiento = IF( [Cumplimiento] >= 1 , "#1E8449" , "#C0392B" )
```

* **Configuración:** Formato condicional → Color de fondo → Estilo de formato: *Valor del campo* → ¿En qué campo debemos basarnos?: `[Color cumplimiento]` → Aplicar a: *Valores y totales*.

| Finca | [Cumplimiento] | Color |
| :--- | :--- | :--- |
| Agricola La Union | 42,00 % | rojo |
| Finca El Guayabo | 150,95 % | verde |
| Hacienda Santa Rosa | 142,00 % | verde |
| **Total** | **125,00 %** | **verde** |

* **Resultado visual:** Agricola La Union rojo · Finca El Guayabo verde · Hacienda Santa Rosa verde · Total verde

### D3. Comprobación con tipo = perenne
* **Colores:** Agricola La Union rojo · Finca El Guayabo rojo · Hacienda Santa Rosa verde · Total verde.
* **¿Santa Rosa cambió de color?:** No, se mantuvo en verde.
* **¿Por qué ahora no cambió?:** Porque la medida DAX evalúa una condición lógica absoluta e independiente (`[Cumplimiento] >= 1`), sin depender de los valores mínimos o máximos del resto de filas del visual.

### D4. Dos razones para preferir la medida DAX
1. **Mantenibilidad y centralización:** Si el umbral de cumplimiento o los colores corporativos cambian, se modifican una sola vez en la medida DAX y se propagan automáticamente a todos los visuales del informe.
2. **Sin techos artificiales:** Al usar un condicional `>= 1`, evalúa correctamente cualquier valor por encima del 100 % sin dejar sin color a registros atípicos (como 250 % o 500 %).

---

## Parte E · Tarjeta, medidor y KPI

### E1. La tarjeta
* `[Kilos]` = 30 550

### E2. El medidor

```dax
Tope del medidor = [Meta] * 1.5
```

* **Valor del medidor:** 30 550
* **Aguja de la meta:** 24 440
* **Máximo sin [Tope del medidor]:** 61 100 (el doble automático del valor actual)
* **Máximo con [Tope del medidor]:** 36 660

### E3. El KPI (del mes)
* **Campos configurados:** Valor: `[Kilos]`, Eje de tendencia: `dim_tiempo[nombre_mes]`, Destino: `[Meta]`.
* **Valores arrojados:**
  * **Número grande:** 19 750
  * **Objetivo:** 8 300
  * **Distancia:** +137,95 %
  * **Color:** Verde

### E4. Diagnóstico de la tarjeta vs KPI
Power BI no arrojó ningún error. El objeto visual KPI está diseñado por definición para mostrar el valor puntual del último periodo de la línea de tiempo (Abril), mientras que la tarjeta muestra la agregación total de todo el periodo filtrado.

### E5. Tabla de apoyo mensual

| nombre_mes | [Kilos] | [Meta] |
| :--- | :--- | :--- |
| Enero | (vacío) | 4 040 |
| Febrero | (vacío) | 5 200 |
| Marzo | 10 800 | 6 900 |
| Abril | 19 750 | 8 300 |
| **Total** | **30 550** | **24 440** |

### E6. Análisis del valor 19 750
El visual KPI enseña el desempeño del último periodo del eje temporal (abril de 2026). El número 19 750 ya había salido en las clases 16 y 17 al analizar la producción puntual de dicho mes.

---

## Parte F · El KPI del año

### F1. Acumulados YTD

```dax
Kilos YTD = TOTALYTD( [Kilos] , dim_tiempo[fecha] )
```

```dax
Meta YTD = TOTALYTD( [Meta] , dim_tiempo[fecha] )
```

#### Comparación de los dos visuales KPI:

| Concepto | KPI del mes | KPI del año |
| :--- | :--- | :--- |
| **Número grande** | 19 750 | 30 550 |
| **Objetivo** | 8 300 | 24 440 |
| **Distancia** | +137,95 % | +25,00 % |

### F2. Situación de la empresa a fin de marzo
* **Kilos YTD a marzo:** 10 800
* **Meta YTD a marzo:** $4\,040 + 5\,200 + 6\,900 = 16\,140$
* **Distancia:**
  $$\frac{10\,800 - 16\,140}{16\,140} = -33{,}09\,\%$$

### F3. Filtrado interactivo con Agrícola La Unión
Al seleccionar Agrícola La Unión en la tabla por finca, el KPI del año muestra:
* **Kilos YTD:** 2 100
* **Meta YTD:** 5 000
* **Distancia:** −58,00 % (color rojo)

### F4. Títulos de los KPI
* **KPI del mes:** KPI Cosecha - Último Mes (Abril 2026)
* **KPI del año:** KPI Cosecha Acumulada Anual (YTD 2026)

---

## Parte G · Preguntas de cierre

* **¿Contra qué compara una regla con tipo Porcentaje? ¿Y un degradado?:**  
  Ambos comparan contra el rango visible de los datos en ese momento: el 0 % es el valor mínimo visible y el 100 % es el valor máximo visible de la tabla.

* **¿Qué valor enseña el objeto visual KPI?:**  
  Muestra el valor correspondiente al último periodo cronológico registrado en su eje de tendencia, no la suma de todo el periodo.

* **Regla de detección del día:**  
  *«Si el segmentador cambia los vecinos y la regla cambia el color, no medías tu meta: medías tu podio».*

* **Regla relativa vs. absoluta en vendedores:**  
  Es una regla relativa. Si todos venden más que el año pasado, la regla recalcula el promedio hacia arriba y siempre seguirá pintando de rojo a la mitad inferior que quede por debajo de la nueva media.

* **Caso donde el porcentaje del rango sí es el resultado deseado:**  
  Cuando se busca clasificar a los elementos por percentiles o cuartiles relativos (por ejemplo, pintar en rojo al 20 % de fincas con menor rendimiento relativo respecto al grupo para priorizar visitas de inspección técnica).