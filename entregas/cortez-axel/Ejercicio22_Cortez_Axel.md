# Ejercicio 22 · Un simulador de metas que no invente el nivel

- **Alumno:** Cortez Cardozo Axel Josue
- **Ejercicio / proyecto:** Ejercicio 22 · Tablas desconectadas, SELECTEDVALUE y control de totales con HASONEVALUE
- **Archivo:** `entregas/cortez-axel/Ejercicio22_Cortez_Axel.md`

---

## Parte A · Una tabla que no viene de ningún archivo

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

### A3. Tabla escenario (Punto de control 2)
```dax
escenario = DATATABLE( "nivel" , INTEGER , { { 100 } , { 110 } , { 120 } , { 130 } , { 140 } , { 150 } } )
```
- En vista de datos, `escenario` contiene 6 filas en una única columna numérica `nivel`.
- En vista de modelo, `escenario` permanece aislada sin relaciones hacia ninguna otra tabla.

### A5. Respuesta
La tabla no experimentó ningún cambio porque no existe una relación en el modelo que propague el contexto de filtro desde `escenario` hacia las tablas de hechos o dimensiones.

---

## Parte B · La medida pregunta

### B1. Medidas iniciales
```dax
Nivel elegido = SELECTEDVALUE( escenario[nivel] , 100 )
```

```dax
Meta ajustada = [Meta] * [Nivel elegido] / 100
```

```dax
Cumplimiento ajustado = DIVIDE( [Kilos] , [Meta ajustada] )
```

### Tabla por finca con nivel 130 (Punto de control 3)

| Finca | [Kilos] | [Meta ajustada] | [Cumplimiento ajustado] |
|---|---|---|---|
| Agricola La Union | 2 100 | 6 500 | 32,31 % |
| Finca El Guayabo | 14 250 | 12 272 | 116,12 % |
| Hacienda Santa Rosa | 14 200 | 13 000 | 109,23 % |
| **Total** | **30 550** | **31 772** | **96,15 %** |

### B2. Los seis niveles evaluados (Punto de control 4)

| Nivel | [Meta ajustada] | [Cumplimiento ajustado] |
|---|---|---|
| 100 | 24 440 | 125,00 % |
| 110 | 26 884 | 113,64 % |
| 120 | 29 328 | 104,17 % |
| 130 | 31 772 | 96,15 % |
| 140 | 34 216 | 89,29 % |
| 150 | 36 660 | 83,33 % |

### B3. Respuesta
La empresa cumple a nivel global hasta el nivel 120 (104,17 %); Agrícola La Unión no cumple en ninguno de los niveles analizados.

---

## Parte C · Dos niveles a la vez

### C1. Tabla con 130 y 150 marcados (Punto de control 5)

| Finca | [Kilos] | [Meta ajustada] | [Cumplimiento ajustado] |
|---|---|---|---|
| Agricola La Union | 2 100 | 5 000 | 42,00 % |
| Finca El Guayabo | 14 250 | 9 440 | 150,95 % |
| Hacienda Santa Rosa | 14 200 | 10 000 | 142,00 % |
| **Total** | **30 550** | **24 440** | **125,00 %** |

### C2. Mensaje de error o advertencia
Ninguno; Power BI calculó y renderizó los valores sin emitir excepciones ni advertencias visuales.

### C3. Respuesta
Corresponde al nivel 100; dicho nivel no está seleccionado en el segmentador, fue adoptado de forma predeterminada por el valor alternativo de la función.

### C4. Tarjeta de control (Punto de control 6)

| Qué hay marcado en el segmentador | [Nivel elegido] | Total de [Cumplimiento ajustado] |
|---|---|---|
| solo 130 | 130 | 96,15 % |
| 130 y 150 | 100 | 125,00 % |
| nada (borra la selección) | 100 | 125,00 % |

### C5. Respuesta
El valor 100 surge del segundo argumento de `SELECTEDVALUE`, que actúa como valor alternativo por defecto cuando existen múltiples valores en el contexto filtrado.

### C6. Respuesta
En la Parte B solo se seleccionó un valor a la vez, garantizando un contexto unívoco; el 125,00 % no parece sospechoso porque coincide de manera idéntica con el cumplimiento base original de la empresa.

### C7. Respuesta
Debió leer 83,33 %; una tarjeta KPI con `[Nivel elegido]` o un visual que alerte sobre selecciones ambiguas habría evidenciado que se estaba evaluando al 100 %.

---

## Parte D · Los seis a la vez

### D1. Matriz con Meta ajustada (Punto de control 7)

| Finca | 100 | 110 | 120 | 130 | 140 | 150 | Total |
|---|---|---|---|---|---|---|---|
| Agricola La Union | 5 000 | 5 500 | 6 000 | 6 500 | 7 000 | 7 500 | 5 000 |
| Finca El Guayabo | 9 440 | 10 384 | 11 328 | 12 272 | 13 216 | 14 160 | 9 440 |
| Hacienda Santa Rosa | 10 000 | 11 000 | 12 000 | 13 000 | 14 000 | 15 000 | 10 000 |
| **Total** | 24 440 | 26 884 | 29 328 | 31 772 | 34 216 | 36 660 | 24 440 |

### D2. Suma a mano vs Columna Total
- **Suma a mano La Unión:** 5 000 + 5 500 + 6 000 + 6 500 + 7 000 + 7 500 = **37 500**
- **Columna Total mostrada:** 5 000

### D3. Respuesta
Cada columna del 100 al 150 posee un contexto de filtro unívoco para el nivel; en contraste, la columna de total abarca a los seis niveles simultáneamente, activando el valor alternativo de 100.

### D4. Respuesta
No la copió; evaluó de forma independiente la expresión en un contexto con múltiples niveles, devolviendo el cálculo escalar parametrizado con el valor alternativo 100.

---

## Parte E · Que diga que no sabe

### E1. Medidas de seguridad y comportamiento en matriz
```dax
Meta del escenario =
IF(
    HASONEVALUE( escenario[nivel] ) ,
    [Meta] * SELECTEDVALUE( escenario[nivel] ) / 100
)
```

```dax
Cumplimiento del escenario = DIVIDE( [Kilos] , [Meta del escenario] )
```

### Punto de control 8

| La Unión | Columna 130 | Columna Total |
|---|---|---|
| `[Meta ajustada]` | 6 500 | 5 000 |
| `[Meta del escenario]` | 6 500 | (vacío) |

El renglón Total de `[Meta del escenario]` entrega: 24 440 · 26 884 · 29 328 · 31 772 · 34 216 · 36 660 · (vacío).

### E2. Evaluación con selección ambigua (Punto de control 9)

| Qué hay marcado | Total de [Meta del escenario] | Total de [Cumplimiento del escenario] |
|---|---|---|
| solo 130 | 31 772 | 96,15 % |
| 130 y 150 | (vacío) | (vacío) |
| nada | (vacío) | (vacío) |

### E3. Respuesta sobre Selección única
Al activar selección única, hacer clic en otra opción deselecciona automáticamente la anterior impidiendo selecciones múltiples; tampoco permite desmarcar el valor activo para dejar el segmentador en blanco.

### E4. Respuesta
La columna Total sigue mostrando 5 000 porque los totales de una matriz abarcan todas las columnas por definición de contexto; la configuración visual del segmentador no altera la semántica de agregación de la matriz, mientras que `HASONEVALUE` controla directamente la lógica en DAX.

---

## Parte F · ¿Hasta dónde se puede subir?

### F1. Tabla por nivel con fincas cumplidoras (Punto de control 10)
```dax
Fincas que cumplen = COUNTROWS( FILTER( dim_finca , [Cumplimiento del escenario] >= 1 ) )
```

| nivel | [Kilos] | [Meta del escenario] | [Cumplimiento del escenario] | [Fincas que cumplen] |
|---|---|---|---|---|
| 100 | 30 550 | 24 440 | 125,00 % | 2 |
| 110 | 30 550 | 26 884 | 113,64 % | 2 |
| 120 | 30 550 | 29 328 | 104,17 % | 2 |
| 130 | 30 550 | 31 772 | 96,15 % | 2 |
| 140 | 30 550 | 34 216 | 89,29 % | 2 |
| 150 | 30 550 | 36 660 | 83,33 % | 1 |
| **Total** | **30 550** | | | |

*(Se anexa captura `clase22-escenarios.png` con esta tabla y la matriz).*

### F2. Respuesta
Porque la tabla de cosecha no mantiene relación con la tabla desconectada `escenario`; los kilos se calculan invariables bajo los filtros temporales activos.

### F3. Respuesta
Cumple únicamente Finca El Guayabo con un cumplimiento del 100,64 % (14 250 kilos sobre 14 160 de meta simulada).

### F4. Respuesta
Para la empresa en su conjunto conviene subir hasta el nivel 120 (cumplimiento global de 104,17 %); para mantener al menos dos fincas operativas cumpliendo metas conviene subir hasta el nivel 140, ya que a nivel individual El Guayabo y Santa Rosa compensan de forma dispar frente al total corporativo.

---

## Parte G · Preguntas de cierre

1. Una tabla desconectada no filtra directamente ninguna tabla de hechos ni dimensiones en el modelo tabular.
2. Devuelve el valor alternativo provisto como segundo parámetro, o un valor BLANK en caso de omitirse.
3. Si un parámetro interactivo arroja resultados sin selección explícita, la medida está asumiendo silenciosamente un valor por defecto no verificado.
4. Seleccionar múltiples monedas al mismo tiempo y limpiar toda la selección del segmentador para verificar si los cálculos se invalidan o devuelven valores arbitrarios.
5. Cuando el negocio define una política explícita de fallback, como aplicar la tasa de inflación base estándar si el analista no elige un escenario particular.