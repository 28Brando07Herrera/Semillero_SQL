# Ejercicio práctico 26 · Los kilos entregados

**Estudiante:** Daniel Moises Troya Riofrio  
**Fecha:** Septiembre 2026  
**Herramienta:** Power BI Desktop  

---

## Parte A · El modelo

### A1a. Tipo de dato de fecha_entrega
Al verificar en la vista de tabla sobre `h_cosecha`, la columna `fecha_entrega` se configuró como tipo Fecha (`Date`) para asegurar la correcta cardinalidad y relación con la dimensión temporal.

### A3. Medidas base

Kilos = SUM( h_cosecha[kg] )
* Resultado (Ene–Abr 2026): 30 550

Meta = SUM( h_meta[kg_meta] )
* Resultado (Ene–Abr 2026): 24 440

Cumplimiento = DIVIDE( [Kilos] , [Meta] )
* Formato: Porcentaje con 2 decimales.
* Resultado (Ene–Abr 2026): 125,00 %

### A4. Tabla de control (Filtros: anio = 2026, mes = 1 a 4)

| Finca | Kilos | Meta | Cumplimiento |
| :--- | :--- | :--- | :--- |
| Agricola La Union | 2 100 | 5 000 | 42,00 % |
| Finca El Guayabo | 14 250 | 9 440 | 150,95 % |
| Hacienda Santa Rosa | 14 200 | 10 000 | 142,00 % |
| **Total** | **30 550** | **24 440** | **125,00 %** |

---

## Parte B · La segunda relación

### B2. Aspecto visual de la línea
A diferencia de la relación con `fecha` que se muestra como una línea continua y sólida, la nueva relación entre `h_cosecha[fecha_entrega]` y `dim_tiempo[fecha]` se dibuja como una línea punteada (discontinua), indicando que está inactiva.

### B3. Relaciones entre h_cosecha y dim_tiempo
1. `h_cosecha[fecha]` -> `dim_tiempo[fecha]` — Activa
2. `h_cosecha[fecha_entrega]` -> `dim_tiempo[fecha]` — Inactiva

### B4. ¿Por qué Power BI no permite dos relaciones activas simultáneas?
Porque generaría ambigüedad en la propagación del contexto de filtro. Si el usuario filtra `mes = 4`, el motor tabular no sabría si debe recuperar las cosechas cortadas en abril o las entregadas en abril.

---

## Parte C · La medida obvia

### C1. Medida inicial
Kilos entregados = SUM( h_cosecha[kg] )

### C2. Tabla por mes con la medida obvia

| nombre_mes | Kilos | Kilos entregados |
| :--- | :--- | :--- |
| Marzo | 10 800 | 10 800 |
| Abril | 19 750 | 19 750 |
| **Total** | **30 550** | **30 550** |

### C3. Análisis de la cosecha 7 (Maíz, 30 de abril)
La cosecha 7 se cortó el 30 de abril y se entregó en mayo. La medida `[Kilos entregados]` la está contabilizando en abril, porque evalúa la fecha de corte y no la de entrega.

### C4. Comportamiento del motor
Power BI no arrojó ningún error. La medida no usa `fecha_entrega` porque las expresiones DAX simples recorren exclusivamente la ruta de relación activa predeterminada del modelo (`fecha`), ignorando la relación inactiva.

---

## Parte D · USERELATIONSHIP

### D1. Medida corregida con relación de rol
Kilos entregados = CALCULATE( [Kilos] , USERELATIONSHIP( h_cosecha[fecha_entrega] , dim_tiempo[fecha] ) )

### D2. Tabla por mes (meses 1 a 4)

| nombre_mes | Kilos | Kilos entregados |
| :--- | :--- | :--- |
| Enero | | 1 200 |
| Marzo | 10 800 | 9 600 |
| Abril | 19 750 | 10 250 |
| **Total** | **30 550** | **21 050** |

### D3. Cosecha de 1 200 kg en enero
Corresponde a la cosecha cortada a finales de diciembre de 2025 cuya entrega física se postergó a enero de 2026. Cuenta en 2025 para `[Kilos]` y en 2026 para `[Kilos entregados]`.

### D4. Explicación del desfase de 9 500 kg
La diferencia de -9 500 kg entre cosechados (30 550) y entregados (21 050) se compone de:
* Entra (+1 200 kg): La cosecha realizada en diciembre 2025 que se entregó en enero 2026.
* Salen (-10 700 kg): Las cosechas cortadas en abril cuya fecha de entrega cayó en mayo (entre ellas la cosecha 7 de maíz por 9 800 kg y la cosecha 6 de cacao por 900 kg).
* Balance neto: +1 200 - 10 700 = -9 500 kg.

### D5. Comportamiento anual completo (año 2026)
Al remover el filtro de meses:
* [Kilos]: 30 550
* [Kilos entregados]: 31 750
* Aparece el mes de Mayo reflejando 10 700 kg entregados.

### D6. Tabla por finca con ambas métricas

| Finca | Kilos | Meta | Cumplimiento | Kilos entregados |
| :--- | :--- | :--- | :--- | :--- |
| Agricola La Union | 2 100 | 5 000 | 42,00 % | 2 400 |
| Finca El Guayabo | 14 250 | 9 440 | 150,95 % | 4 450 |
| Hacienda Santa Rosa | 14 200 | 10 000 | 142,00 % | 14 200 |
| **Total** | **30 550** | **24 440** | **125,00 %** | **21 050** |

`[Kilos]` y `[Cumplimiento]` no sufrieron ninguna alteración, pues continúan evaluándose a través del camino activo de corte (`h_cosecha[fecha]`).

---

## Parte E · ¿Y si activo la otra?

### E1. Procedimiento de cambio
Se accedió a Administrar relaciones, se desactivó la casilla activa en `h_cosecha[fecha]` y posteriormente se marcó como activa la relación con `h_cosecha[fecha_entrega]`.

### E2. Tabla de control con fecha_entrega activa

| Finca | Kilos | Meta | Cumplimiento |
| :--- | :--- | :--- | :--- |
| Agricola La Union | 2 400 | 5 000 | 48,00 % |
| Finca El Guayabo | 4 450 | 9 440 | 47,14 % |
| Hacienda Santa Rosa | 14 200 | 10 000 | 142,00 % |
| **Total** | **21 050** | **24 440** | **86,13 %** |

### E3. Descenso de Finca El Guayabo
Su cumplimiento se desploma de 150,95 % a 47,14 % porque la cosecha 7 (9 800 kg de maíz cortados a fines de abril) tiene `fecha_entrega` en mayo. Al estar activa la relación de entrega, esa producción queda fuera del periodo enero–abril.

### E4. Invariabilidad de [Meta]
`[Meta]` se mantiene en 24 440 porque `h_meta` se vincula a `dim_tiempo` mediante su propia relación (`h_meta[fecha_mes]`), la cual nunca fue alterada.

### E5. Restauración del modelo
Se revirtió la configuración: relación de `fecha_entrega` inactiva y relación de `fecha` activa. La tabla retornó al 125,00 % de cumplimiento original.

### E6. Impacto colateral en otros artefactos
Si se dejase activa la entrega, los semáforos de producción mensual evaluarían despachos en lugar del volumen cosechado real en campo, y los KPIs anuales de productividad agrícola quedarían desfasados respecto al ciclo agronómico.

---

## Parte F · Días a la entrega

### F1. Medida de desfase
Dias a la entrega = AVERAGEX( h_cosecha , DATEDIFF( h_cosecha[fecha] , h_cosecha[fecha_entrega] , DAY ) )
* Formato: Número decimal, 2 decimales.

### F2. Tabla por cultivo

| cultivo | Dias a la entrega |
| :--- | :--- |
| Cacao | 27,00 |
| Guayaba | 2,00 |
| Maiz | 12,00 |
| Mango | 2,00 |
| **Total** | **8,67** |

### F3. ¿Por qué el total es 8,67 y no 10,75?
`AVERAGEX` itera sobre cada registro individual de la tabla `h_cosecha` calculando una media ponderada por número de eventos de cosecha, en lugar de un promedio aritmético simple entre las cuatro categorías.

### F4. Interacción con el segmentador
Aunque `DATEDIFF` opera a nivel de fila, el contexto de filtro temporal restringe qué filas de `h_cosecha` llegan al cálculo; dicho filtrado se realiza por la fecha activa de corte (`h_cosecha[fecha]`).

---

## Parte G · Preguntas de cierre

1. **¿Qué hace una relación inactiva mientras ninguna medida la pide?**  
   Permanece en reposo absoluto; no propaga filtros ni participa en ningún cálculo hasta ser activada explícitamente vía `USERELATIONSHIP`.
2. **¿Cuándo conviene cambiar la relación activa y cuándo usar USERELATIONSHIP?**  
   Conviene cambiar la activa si el eje central del modelo cambia de propósito de forma definitiva; se usa `USERELATIONSHIP` cuando una misma dimensión desempeña múltiples roles dentro del mismo análisis.
3. **Regla de detección del día:**  
   «Si dos medidas que representan eventos temporales distintos arrojan idéntico valor, ambas están resolviéndose por la misma relación activa por omisión».
4. **Auditoría de créditos bancarios aprobados en marzo:**  
   Revisaría qué columna de fecha (`fecha_solicitud` vs. `fecha_aprobacion`) está enlazada activamente al calendario y si la medida incorpora `USERELATIONSHIP` hacia la fecha de aprobación.
5. **Fecha de la meta y metas de entrega:**  
   La meta actual está planificada contra la fecha agronómica de corte; no tendría sentido medir entregas contra ella sin un modelo de metas logísticas formulado para el ciclo de despachos.