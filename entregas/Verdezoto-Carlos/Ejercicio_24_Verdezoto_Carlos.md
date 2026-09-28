# Ejercicio 26 · AgroDB

## PARTE A - EL MODELO

**A1a.** Al inspeccionar los datos cargados en la vista de tabla, la columna `fecha_entrega` quedó configurada inicialmente como **Texto**. Procedí a cambiarla al tipo **Fecha** para que pueda ser relacionada con el calendario[cite: 18].

---

## PARTE B - LA SEGUNDA RELACIÓN

**B2.** La nueva línea de relación se ve **punteada**, lo cual indica visualmente en Power BI que la relación se creó, pero se encuentra **inactiva**[cite: 18].

**B3.**
- Relación activa: `h_cosecha[fecha]` → `dim_tiempo[fecha]`
- Relación inactiva: `h_cosecha[fecha_entrega]` → `dim_tiempo[fecha]`[cite: 18]

**B4.** Power BI no permite que ambas estén activas simultáneamente porque se generaría ambigüedad en el modelo. Si alguien filtra un mes en particular, el motor no sabría por cuál de los dos caminos enviar el filtro hacia la tabla de hechos, causando cálculos duplicados o inconsistentes[cite: 18].

---

## PARTE C - LA MEDIDA OBVIA

### C1 · Kilos entregados (primera versión)
```dax
Kilos entregados = SUM( h_cosecha[kg] )

```

**C2. Tabla Enero a Abril:**

| `nombre_mes` | `[Kilos]` | `[Kilos entregados]` |
| --- | --- | --- |
| Marzo | 10 800 | 10 800 |
| Abril | 19 750 | 19 750 |
| **Total** | **30 550** | **30 550** |

**C3.** La cosecha 7 (maíz del 30 de abril) se entregó en el mes de **mayo**. Sin embargo, la medida `[Kilos entregados]` la está sumando en **abril** porque sigue guiándose por la fecha de corte.

**C4.** Power BI no arrojó **ningún error** o advertencia. La medida no usa `fecha_entrega` (a pesar de tener la relación dibujada) porque el comportamiento natural de DAX es utilizar única y exclusivamente las relaciones que están *activas*, ignorando las inactiva hasta que se le ordene lo contrario.

---

## PARTE D - USERELATIONSHIP

### D1 · Kilos entregados con USERELATIONSHIP

```dax
Kilos entregados = CALCULATE( [Kilos] , USERELATIONSHIP( h_cosecha[fecha_entrega] , dim_tiempo[fecha] ) )

```

**D2. Tabla con entregas (Enero a Abril):**

| `nombre_mes` | `[Kilos]` | `[Kilos entregados]` |
| --- | --- | --- |
| Enero |  | 1 200 |
| Marzo | 10 800 | 9 600 |
| Abril | 19 750 | 10 250 |
| **Total** | **30 550** | **21 050** |

**D3.** Los 1 200 kilos de enero corresponden a una cosecha que se cortó a fines de **2025**. Cuenta para `[Kilos]` en el año 2025 (su fecha activa), pero cuenta para `[Kilos entregados]` en el año **2026** por el desfase de la entrega.

**D4.** La diferencia de 9 500 kilos ocurre porque el universo del cuatrimestre se reacomodó:

* **Salen 10 700 kilos**: Incluye la `cosecha_id = 7` (9 800 kg de maíz) y otras menores que se cortaron en marzo/abril, pero sus entregas resbalaron a mayo.
* **Entra 1 200 kilos**: Corresponde a la cosecha arrastrada de diciembre 2025.
* Operación: +1 200 (que entran) − 10 700 (que salen) = −9 500 kilos netos en el periodo.



**D5.** Al quitar el segmentador de mes (año 2026 completo):

* Total `[Kilos]`: **30 550**
* Total `[Kilos entregados]`: **31 750**
* Aparece un mes nuevo en la tabla: **Mayo**, con **10 700** kilos entregados.



**D6.** Al agregar la nueva medida a la tabla por finca, `[Kilos]` y `[Cumplimiento]` **no cambiaron** en lo absoluto, ya que esas métricas base continúan respetando el filtro que impone la relación activa original.

---

## PARTE E - ¿Y SI ACTIVO LA OTRA?

**E1.** Se desactivó `h_cosecha[fecha]` primero y luego se procedió a activar `h_cosecha[fecha_entrega]` en el administrador de relaciones.

**E2. Tabla por finca:**

| Finca | `[Kilos]` | `[Meta]` | `[Cumplimiento]` |
| --- | --- | --- | --- |
| Agricola La Union | 2 400 | 5 000 | 48,00 % |
| Finca El Guayabo | 4 450 | 9 440 | 47,14 % |
| Hacienda Santa Rosa | 14 200 | 10 000 | 142,00 % |
| **Total** | **21 050** | **24 440** | **86,13 %** |

**E3.** El Guayabo se desploma drásticamente al 47,14 % porque su **cosecha 7** (los 9 800 kilos de maíz) dejó de contar para el cuatrimestre. Al cambiar la relación activa, todo el modelo de la finca mandó esa cosecha al mes de mayo, sacándola de la ventana evaluada.

**E4.** Porque la medida `[Meta]` fluye desde la tabla `h_meta` hacia `dim_tiempo` por su propia relación independiente (`fecha_mes`). Esa conexión nunca fue modificada y no se ve afectada por lo que ocurra en `h_cosecha`.

**E5.** Relaciones restauradas. La tabla volvió exitosamente al **125,00 %** total.

**E6.** Otras partes del curso que habrían cambiado solas de haber dejado esa configuración:

1. **El KPI del año (YTD):** Al acumular sobre la nueva relación, mostraría el volumen acumulado de entregas (y no de cosechas).
2. **El Semáforo condicional:** Habría pintado de **rojo** a Finca El Guayabo, ya que su cumplimiento real en ese periodo habría bajado al 47,14 %.



---

## PARTE F - DÍAS A LA ENTREGA

### F1 · Medida de días promedio

```dax
Dias a la entrega = AVERAGEX( h_cosecha , DATEDIFF( h_cosecha[fecha] , h_cosecha[fecha_entrega] , DAY ) )

```

**F3.** Porque `AVERAGEX` itera fila por fila a nivel de tabla de hechos (`h_cosecha`). Calcula el promedio ponderado basado en el número total de transacciones/eventos individuales de cosecha en toda la finca, no saca un simple promedio aritmético de los 4 cultivos agregados.

**F4.** Porque el segmentador sigue utilizando y viajando a través de la **única relación activa** del modelo, que es `fecha` (la fecha de corte). Muestra los días promedio de retraso solo para aquellas cosechas que fueron cortadas dentro de los meses seleccionados.

---

## PARTE G - PREGUNTAS DE CIERRE

1. **¿Qué hace una relación inactiva?** Descansa invisible y no filtra nada en el modelo, esperando pacientemente a que una medida DAX explícita la invoque mediante `USERELATIONSHIP`.


2. **¿Cuándo cambiar la activa y cuándo usar USERELATIONSHIP?** Conviene cambiar la activa si toda la lógica del negocio pivota hacia la nueva fecha (ej. la empresa ahora mide todo por despacho). Usa `USERELATIONSHIP` cuando ambas fechas coexisten (ej. analizar cortes y despachos en el mismo gráfico).


3. **Regla de detección:** "Si creaste una medida para una fecha secundaria y el número es exactamente igual al de la medida primaria, DAX te está leyendo la relación activa; olvidaste el `USERELATIONSHIP`".


4. **¿Qué revisarías primero?** Revisaría en la vista de modelo de Power BI cuál de las dos líneas (`fecha_solicitud` o `fecha_aprobacion`) está en trazado continuo (activa) conectada al calendario, para saber qué significa "marzo" para esa tarjeta.


5. **¿Qué fecha usa la meta?** La meta usa una fecha fija de mes estático (`fecha_mes`, por lo general día 1). Tendría sentido una meta de entregas siempre y cuando se compare contra los "kilos entregados" activados o si la gerencia registra presupuestos apartados para despacho.



```

```