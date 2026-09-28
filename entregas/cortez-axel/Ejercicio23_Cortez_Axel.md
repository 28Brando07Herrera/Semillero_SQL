# Ejercicio 23 · Un semáforo que no mienta

- **Alumno:** Cortez Cardozo Axel Josue
- **Ejercicio / proyecto:** Ejercicio 23 · Formato condicional, reglas relativas vs absolutas y KPIs con Time Intelligence
- **Archivo:** `entregas/cortez-axel/Ejercicio23_Cortez_Axel.md`

---

## Parte A · Las dos tablas

### A1. Segmentadores
- `dim_tiempo[anio]` = 2026
- `dim_tiempo[mes]` en 1, 2, 3 y 4
- `dim_cultivo[tipo]` (sin selección)

### A2. Tabla por finca (Punto de control 1)

| Finca | [Kilos] | [Meta] | [Cumplimiento] |
|---|---|---|---|
| Agricola La Union | 2 100 | 5 000 | 42,00 % |
| Finca El Guayabo | 14 250 | 9 440 | 150,95 % |
| Hacienda Santa Rosa | 14 200 | 10 000 | 142,00 % |
| **Total** | **30 550** | **24 440** | **125,00 %** |

### A3. Tabla por cultivo (Punto de control 2)

| Cultivo | [Kilos] |
|---|---|
| Mango | 12 700 |
| Maiz | 9 800 |
| Guayaba | 5 950 |
| Cacao | 2 100 |

---

## Parte B · Degradado y reglas

### B1. Degradado en Kilos
- **B1a:** Cultivo más oscuro: Mango (12 700 kg). Cultivo en blanco: Cacao (2 100 kg).
- **B1b. Cálculo a mano de la escala:**
  `Escala = (9 800 - 2 100) / (12 700 - 2 100) = 7 700 / 10 600 = 72,64 %`.
  El Maíz cae exactamente en el 72,64 % de la escala cromática; Guayaba en el 36,32 %.

### B2. Regla de 5 000 kilos (Punto de control 4)

| Si el valor | y | Tipo | Color |
|---|---|---|---|
| >= 0 | < 5000 | Número | rojo |
| >= 5000 | <= 100000 | Número | verde |

Mango verde · Maiz verde · Guayaba verde · Cacao rojo

### B3. Respuesta
Quedaría sin color de fondo (en blanco), ya que supera el límite superior de 100 000 fijado en la regla.

---

## Parte C · Verde si cumple

### C1. Regla en Cumplimiento con tipo Porcentaje (Punto de control 5)

| Finca | [Cumplimiento] | Color |
|---|---|---|
| Agricola La Union | 42,00 % | rojo |
| Finca El Guayabo | 150,95 % | verde |
| Hacienda Santa Rosa | 142,00 % | **rojo** |

### C2. Mensaje de error o advertencia
Power BI no emitió ninguna advertencia ni error; aplicó la regla silenciosamente sobre el espacio del rango visual.

### C3. Respuesta
Santa Rosa sí cumplió holgadamente la meta (142,00 %); debería mostrar color verde, pero se pintó de rojo porque el tipo Porcentaje no evalúa la métrica absoluta, sino la posición relativa entre el mínimo y el máximo de la columna.

### C4. Cálculo a mano del porcentaje del rango (Punto de control 6)
- Rango: Mínimo = 42,00 % (0,42), Máximo = 150,95 % (1,5095).
- Amplitud del rango: `1,5095 - 0,42 = 1,0895`.
- Cálculo Santa Rosa: `(1,42 - 0,42) / 1,0895 = 1,00 / 1,0895 = 91,78 %`.
Al estar en el 91,78 % del rango, cae en la regla `< 100 %` y por eso se pinta de rojo.

### C5. Respuesta
Solo entra la entidad con el valor máximo absoluto visible (El Guayabo con el 100 % del rango). La regla no respondía «¿quién cumplió la meta?», sino «¿quién es el primer lugar de la tabla?».

### C6. Prueba con segmentador en "perenne" (Punto de control 7)

| Finca | [Cumplimiento] | Porcentaje del rango | Color |
|---|---|---|---|
| Agricola La Union | 42,00 % | 0 % | rojo |
| Finca El Guayabo | 47,14 % | 5,14 % | rojo |
| Hacienda Santa Rosa | 142,00 % | 100 % | **verde** |

*(Se retiró la selección de perenne tras la prueba).*

### C7. Respuesta
Porque al excluirse el maíz en El Guayabo, su cumplimiento bajó a 47,14 %, convirtiendo a Santa Rosa (142,00 %) en el nuevo valor máximo (100 % del rango) y haciéndola saltar automáticamente a verde.

### C8. Respuesta con Número en 0 / 100 / 200
Todas las filas salen rojas; internamente en DAX un porcentaje es un número decimal donde 100 % equivale a 1. Al evaluar si el valor es mayor o igual a 100, ninguna finca alcanza esa cifra numérica (142 % es 1,42).

---

## Parte D · El color como medida

### D1. Regla con Número en escala decimal (0 a 1 y 1 a 2)
- Agricola La Union: rojo
- Finca El Guayabo: verde
- Hacienda Santa Rosa: verde
- Una finca al 250 % (2,5) quedaría sin color al exceder el límite superior de 2.

### D2. Medida de color aplicada por Valor del campo (Punto de control 8)
```dax
Color cumplimiento = IF( [Cumplimiento] >= 1 , "#1E8449" , "#C0392B" )
```

| Finca | [Cumplimiento] | Color |
|---|---|---|
| Agricola La Union | 42,00 % | rojo |
| Finca El Guayabo | 150,95 % | verde |
| Hacienda Santa Rosa | 142,00 % | **verde** |
| **Total** | **125,00 %** | **verde** |

### D3. Prueba con perenne
Santa Rosa permanece verde; no cambió de color porque la medida evalúa una condición lógica absoluta independiente de los máximos y mínimos de las otras fincas.

### D4. Respuesta
1. Reutilización consistente: centraliza la lógica y la paleta de colores institucional en una sola medida para múltiples tablas o matrices.
2. Escalabilidad sin topes artificiales: no requiere fijar techos arbitrarios (como 2 o 100 000), funcionando correctamente con cumplimientos atípicos como 300 % o 500 %.

---

## Parte E · Tarjeta, medidor y KPI

### E1. Tarjeta de Kilos
- Muestra el total consolidado: **30 550**.

### E2. Medidor con tope dinámico (Punto de control 9)
```dax
Tope del medidor = [Meta] * 1.5
```
- Valor actual: 30 550
- Aguja de la meta: 24 440
- Máximo automático: 61 100
- Máximo con medida de tope: 36 660

### E3. KPI mensual (Punto de control 10)
- Valor principal: **19 750**
- Objetivo: **8 300**
- Distancia: **+137,95 %**
- Estado de color: Verde

### E4. Respuesta
Power BI no emitió ningún error; el objeto visual KPI está programado por diseño para mostrar el estado del último período cronológico del eje de tendencia.

### E5. Tabla mensual de contraste (Punto de control 11)

| nombre_mes | [Kilos] | [Meta] |
|---|---|---|
| Enero | (vacío) | 4 040 |
| Febrero | (vacío) | 5 200 |
| Marzo | 10 800 | 6 900 |
| Abril | 19 750 | 8 300 |
| **Total** | **30 550** | **24 440** |

### E6. Respuesta
El KPI muestra el valor del último período en la serie temporal (abril), no el total acumulado del año. El 19 750 apareció en el Ejercicio 21 como la cosecha individual del mes de abril.

---

## Parte F · El KPI del año

### F1. Fórmulas YTD (Punto de control 12)
```dax
Kilos YTD = TOTALYTD( [Kilos] , dim_tiempo[fecha] )
```

```dax
Meta YTD = TOTALYTD( [Meta] , dim_tiempo[fecha] )
```

| Métrica | KPI del mes | KPI del año |
|---|---|---|
| Número grande | 19 750 | **30 550** |
| Objetivo | 8 300 | **24 440** |
| Distancia | +137,95 % | **+25,00 %** |

*(Se anexa captura `clase23-semaforo.png` mostrando la tabla por finca, la tarjeta y el KPI anual).*

### F2. Desempeño a fin de marzo
- Kilos YTD: 10 800
- Meta YTD: 16 140 (4 040 + 5 200 + 6 900)
- Distancia: **−33,09 %** (la empresa arrancó el año en déficit antes del repunte de abril).

### F3. Filtro interactivo en Agricola La Union
Al seleccionar La Unión, el KPI del año muestra **2 100** frente a un objetivo de **5 000**, reflejando una distancia de **−58,00 %**.

### F4. Títulos de los KPIs
- KPI del mes: **"Desempeño Operativo del Mes (Abril 2026)"**
- KPI del año: **"Cumplimiento Acumulado Anual (YTD 2026)"**

---

## Parte G · Preguntas de cierre

1. Una regla con tipo Porcentaje compara contra el rango relativo visual `(valor - min) / (max - min)`; un degradado distribuye tonalidades continuas a lo largo de ese mismo rango.
2. Enseña el valor correspondiente al último período cronológico ordenado en el eje de tendencia.
3. Si un semáforo cambia de color cuando filtras a su vecino, no estaba evaluando tu meta sino compitiendo contra la de al lado.
4. Es una regla relativa; si todos superan sus ventas históricas pero algunos quedan bajo el nuevo promedio anual, los rezagados seguirán pintándose de rojo a pesar de su buen rendimiento individual.
5. Al analizar cuartiles de rendimiento o clasificar a los clientes en percentiles (Top 10 %, quintil superior) para análisis de distribución relativa.