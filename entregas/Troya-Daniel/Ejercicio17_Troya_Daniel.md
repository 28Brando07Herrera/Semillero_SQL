# Ejercicio práctico 17 · Ponle una meta a cada cultivo, y después quítasela

**Estudiante:** Daniel Moises Troya Riofrio

---

## Parte A · La segunda tabla de hechos

### A2 · Relaciones creadas
* `h_meta[finca_id]` -> `dim_finca[finca_id]` (Muchos a uno)
* `h_meta[fecha_mes]` -> `dim_tiempo[fecha]` (Muchos a uno)

### A3 · La relación ausente
Falta la relación con `dim_cultivo`. No se puede crear porque la tabla `h_meta` no contiene ninguna columna de cultivo (`cultivo_id`); el presupuesto fue planificado exclusivamente a nivel de finca y mes.

### A4 · Punto de control 1
* **[Kilos] sin filtros:** 77 550
* **[Kilos] con anio = 2026:** 30 550
* **[Cosechas]:** 25

---

## Parte B · La medida que cruza los dos hechos

### B1 · Medidas base

```dax
Meta = SUM( h_meta[kg_meta] )
```
* **Resultado sin filtros:** 47 000

```dax
Cumplimiento = DIVIDE( [Kilos] , [Meta] )
```
* **Resultado sin filtros:** 165,00 %

#### Punto de control 2

| Medida | Valor |
| :--- | :--- |
| [Kilos] | 77 550 |
| [Meta] | 47 000 |
| [Cumplimiento] | 165,00 % |

### B2 · Explicación del 165,00 %
Porque se están comparando dos años completos de cosecha acumulada (2025 y 2026, que suman 77 550 kg) contra la meta de solo el año 2026 (47 000 kg).

### B3 · Punto de control 3 · Contextos

| Filtros | [Kilos] | [Meta] | [Cumplimiento] |
| :--- | :--- | :--- | :--- |
| ninguno | 77 550 | 47 000 | 165,00 % |
| anio = 2026 | 30 550 | 47 000 | 65,00 % |
| anio = 2026 y mes en 1–4 | 30 550 | 24 440 | 125,00 % |

### B4 · Comparación con la clase 16
Sí, representa la misma realidad operativa. El 65,00 % de cumplimiento equivale exactamente a una brecha negativa de −35,00 % respecto al total presupuestado anual ($100\% - 35\% = 65\%$).

### B5 · Cumplimiento en 2025
No es un error. No existe presupuesto definido para 2025 en `h_meta`; al dar `[Meta]` en blanco, `DIVIDE` devuelve un valor vacío de forma segura.

---

## Parte C · Por finca, que sí funciona

### C1 · Punto de control 4 (Filtro anio = 2026 y meses 1 a 4)

| Finca | [Kilos] | [Meta] | [Cumplimiento] |
| :--- | :--- | :--- | :--- |
| Agricola La Union | 2 100 | 5 000 | 42,00 % |
| Finca El Guayabo | 14 250 | 9 440 | 150,95 % |
| Hacienda Santa Rosa | 14 200 | 10 000 | 142,00 % |
| **Total** | **30 550** | **24 440** | **125,00 %** |

### C2 · Suma de metas
La suma da 24 440 kg y coincide con la meta total del periodo de enero a abril de 2026.

### C3 · La realidad de Agricola La Union
El total de 125,00 % oculta que Agricola La Union está severamente atrasada con solo el 42,00 % de su meta, viéndose compensada por el sobrecumplimiento de las otras dos fincas.

---

## Parte D · La trampa del día

### D1 · Punto de control 5 · Tabla por cultivo

| Cultivo | [Kilos] | [Meta] | [Cumplimiento] |
| :--- | :--- | :--- | :--- |
| Banano | (vacío) | 24 440 | (vacío) |
| Cacao | 2 100 | 24 440 | 8,59 % |
| Cafe | (vacío) | 24 440 | (vacío) |
| Guayaba | 5 950 | 24 440 | 24,35 % |
| Maiz | 9 800 | 24 440 | 40,10 % |
| Mango | 12 700 | 24 440 | 51,96 % |
| **Total** | **30 550** | **24 440** | **125,00 %** |

### D2 · Mensaje de error
Ninguno (0 errores).

### D3 · Aparición de Banano y Café
Aparecen porque la columna `[Meta]` evalúa a 24 440 para cada fila de la dimensión; la existencia de un valor numérico no vacío fuerza a la tabla a mostrar la fila completa.

### D4 · Punto de control 6
$$51,96\% + 24,35\% + 40,10\% + 8,59\% = 125,00\%$$
(suma idéntica al total general).

### D5 · Suma manual de la columna Meta
Da 146 640 kg ($24\,440 \times 6$). La empresa se propuso cosechar 24 440 kg en el cuatrimestre, no 146 640 kg.

### D6 · Medida Filas de meta

```dax
Filas de meta = COUNTROWS( h_meta )
```

#### Punto de control 7

| Cultivo | [Cosechas] | [Filas de meta] |
| :--- | :--- | :--- |
| Banano | (vacío) | 12 |
| Cacao | 2 | 12 |
| Cafe | (vacío) | 12 |
| Guayaba | 3 | 12 |
| Maiz | 1 | 12 |
| Mango | 3 | 12 |
| **Total** | **9** | **12** |

### D7 · Regla sobre dim_cultivo y h_meta
Si una tabla de hechos no tiene relación con una dimensión, el contexto de filtro de esa dimensión es incapaz de recortarla y la medida siempre devolverá el total sin filtrar.

### D8 · Filtro bidireccional
Estaría asumiendo erróneamente que una finca solo produce los cultivos que ya cosechó históricamente en `h_cosecha`, forzando una relación artificial inexistente en el presupuesto.

---

## Parte E · El otro lado de la granularidad

### E1 · Punto de control 8 (Marzo 2026)

| Día | [Kilos] | [Meta] | [Cumplimiento] |
| :--- | :--- | :--- | :--- |
| 01/03/2026 | (vacío) | 6 900 | (vacío) |
| 20/03/2026 | 4 200 | (vacío) | (vacío) |
| 22/03/2026 | 5 400 | (vacío) | (vacío) |
| 28/03/2026 | 1 200 | (vacío) | (vacío) |
| **Total** | **10 800** | **6 900** | **156,52 %** |

### E2 · Por qué el día 1
Porque en el CSV de metas la granularidad temporal se capturó asignando la fecha al primer día de cada mes (`fecha_mes`).

### E3 · Granularidad permitida
La medida solo puede leerse a nivel de mes o superior (trimestre, año); a nivel de fecha diaria carece de sentido.

---

## Parte F · La medida que se calla

### F1 · Medidas seguras

```dax
Meta valida = IF(
    ISFILTERED( dim_cultivo[cultivo] ) || ISFILTERED( dim_tiempo[fecha] ),
    BLANK(),
    [Meta]
)
```

```dax
Cumplimiento valido = DIVIDE( [Kilos] , [Meta valida] )
```

### F2 · Punto de control 9 · Tabla por cultivo corregida

| Cultivo | [Kilos] | [Meta valida] | [Cumplimiento valido] |
| :--- | :--- | :--- | :--- |
| Cacao | 2 100 | (vacío) | (vacío) |
| Guayaba | 5 950 | (vacío) | (vacío) |
| Maiz | 9 800 | (vacío) | (vacío) |
| Mango | 12 700 | (vacío) | (vacío) |
| **Total** | **30 550** | **24 440** | **125,00 %** |

### F3 · El total con valor
Porque en la fila de total la columna `dim_cultivo[cultivo]` no se encuentra filtrada (`ISFILTERED` devuelve `FALSE`), permitiendo evaluar la meta válida para la empresa completa.

### F4 · Punto de control 10 · Fincas intactas

| Finca | [Kilos] | [Meta valida] | [Cumplimiento valido] |
| :--- | :--- | :--- | :--- |
| Agricola La Union | 2 100 | 5 000 | 42,00 % |
| Finca El Guayabo | 14 250 | 9 440 | 150,95 % |
| Hacienda Santa Rosa | 14 200 | 10 000 | 142,00 % |
| **Total** | **30 550** | **24 440** | **125,00 %** |

### F5 · Segmentador en Mango
Sí, es correcto que se vacíe por completo, pues la meta general no puede desagregarse para responder por un cultivo individual.

---

## Parte G · Preguntas de cierre

* **Regla de granularidad:**  
  Una medida solo puede evaluarse al nivel de detalle de las dimensiones con las que su tabla de hechos tiene relación directa o superior.

* **Diferencia entre día y cultivo:**  
  A nivel diario existía una relación física que solo coincidió en un día puntual; por cultivo no existía ninguna relación física, provocando un producto cartesiano que repitió el total en cada fila.

* **Pista de Filas de meta:**  
  La medida `[Cosechas]` (o `COUNTROWS(h_cosecha)`) de clases anteriores, que al desconectarse de una dimensión se repite idéntica en todas las filas.

* **Al llegar cultivo_id en h_meta:**  
  La condición `ISFILTERED( dim_cultivo[cultivo] )` en `[Meta valida]` dejaría de tener sentido y debería eliminarse tras relacionar `h_meta` con `dim_cultivo`.

* **Quién puso el aviso:**  
  Lo pusimos nosotros como analistas de datos mediante código DAX defensivo, ya que el motor jamás arrojará error ante una falta de granularidad o de relaciones.