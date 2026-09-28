# Ejercicio 17 · Ponle una meta a cada cultivo, y después quítasela

## Byron Yaguar · Power BI · DAX

**Fecha:** Septiembre 2026

\---

## PARTE A: La segunda tabla de hechos

### A1. Carga `h\_meta.csv`

Tabla cargada correctamente en Power BI Desktop con las siguientes columnas:

* `meta\_id` (Número entero)
* `finca\_id` (Número entero)
* `fecha\_mes` (Fecha)
* `kg\_meta` (Número entero)

**Total de filas:** 36 (3 fincas × 12 meses)

### A2. Las dos relaciones nuevas

Se crearon dos relaciones **muchos a uno**:

|De|A|Tipo|
|-|-|-|
|`h\_meta\[finca\_id]`|`dim\_finca\[finca\_id]`|Muchos a uno|
|`h\_meta\[fecha\_mes]`|`dim\_tiempo\[fecha]`|Muchos a uno|

### A3. La relación que falta

**Pregunta:** `h\_cosecha` tiene tres relaciones y `h\_meta` solo dos. ¿Cuál es la que falta y por qué no se puede crear?

**Respuesta:** Falta la relación `h\_meta\[cultivo\_id] → dim\_cultivo\[cultivo\_id]`. No se puede crear porque **`h\_meta` no tiene columna cultivo**. La meta se fijó por finca y por mes, no por cultivo. En la vida real, una meta se establece a nivel de operación (finca), no a nivel de producto (cultivo).

### A4. Punto de control 1

```
\[Kilos] = SUM(h\_cosecha\[kg])
Resultado sin filtros: 77550
```

```
\[Cosechas] = COUNTROWS(h\_cosecha)
Resultado: 25
```

```
\[Meta] = SUM(h\_meta\[kg\_meta])
Resultado: 47000
```

✅ **Los números se mantuvieron intactos.** La carga de la segunda tabla de hechos no rompió nada.

\---

## PARTE B: Medidas que cruzan dos tablas de hechos

### B1. Medidas básicas

```dax
Meta = SUM(h\_meta\[kg\_meta])
```

Resultado sin filtros: **47 000**

```dax
Cumplimiento = DIVIDE(\[Kilos], \[Meta])
```

Formato: Porcentaje con dos decimales

Resultado sin filtros: **165,00 %**

### B2. ¿Por qué 165,00 %?

Porque se están comparando dos años completos de cosecha (77 550 kg en 2025 y 2026) contra una meta de un solo año (47 000 kg, que es la meta de 2026). El cumplimiento es mayor al 100 % porque cosechamos más de lo que se esperaba para 2026.

### B3. Los tres contextos

|Filtros|`\[Kilos]`|`\[Meta]`|`\[Cumplimiento]`|
|-|-|-|-|
|ninguno|77 550|47 000|**165,00 %**|
|`anio` = 2026|30 550|47 000|**65,00 %**|
|`anio` = 2026 y `mes` en 1–4|30 550|24 440|**125,00 %**|

### B4. Comparación con ayer

Ayer (Clase 16) la variación con `anio` = 2026 sin meses fue **−35,00 %**. Hoy es **65,00 %**. **Sí, es el mismo número visto desde diferente ángulo:**

* Ayer: (30 550 − 47 000) ÷ 47 000 = −35,00 % (cuánto falta)
* Hoy: 30 550 ÷ 47 000 = 65,00 % (cuánto se cumple)

Son complementarios: −35,00 % + 65,00 % = 0 % en el contexto de cuánto falta vs. cuánto se cumple.

### B5. ¿Es un error que `\[Cumplimiento]` salga vacío en 2025?

No. Es correcto. La meta se fijó solo para 2026. No hay meta en 2025, así que Power BI devuelve vacío (no hay denominador en la división). **Anotar este comportamiento es lo correcto.**

\---

## PARTE C: Por finca, que sí funciona

### C1. Tabla por finca (año 2026)

```
Tabla con dim\_finca\[finca], \[Kilos], \[Meta], \[Cumplimiento]
Segmentador: anio = 2026
```

|Finca|Kilos|Meta|Cumplimiento|
|-|-|-|-|
|Hacienda Santa Rosa|14 200|20 000|**71,00 %**|
|Finca El Guayabo|14 250|19 000|**75,00 %**|
|Agricola La Union|2 100|8 000|**26,25 %**|
|**Total**|**30 550**|**47 000**|**65,00 %**|

### C2. Suma de la columna `\[Meta]` en las tres filas

20 000 + 19 000 + 8 000 = **47 000**

Coincide exactamente con el total de la meta de 2026.

### C3. Lo que esconde el total

El total dice **65,00 %**, pero Agricola La Union solo cumple **26,25 %**, lo que está muy por debajo. El porcentaje total (65 %) **oculta el rezago de la finca más pequeña**, que está cumpliendo menos de la mitad de su meta. Es un promedio que puede ser engañoso.

\---

## PARTE D: La trampa del día (el error silencioso)

### D1. Tabla por cultivo (sin cambiar medidas)

```
Tabla con dim\_cultivo\[cultivo], \[Kilos], \[Meta], \[Cumplimiento]
Segmentador: anio = 2026
```

|Cultivo|Kilos|Meta|Cumplimiento|
|-|-|-|-|
|Mango|33 700|**47 000**|71,70 %|
|Maiz|19 150|**47 000**|40,74 %|
|Guayaba|13 800|**47 000**|29,36 %|
|Cacao|10 900|**47 000**|23,19 %|
|**Banano**|*(vacío)*|**47 000**|*(vacío)*|
|**Cafe**|*(vacío)*|**47 000**|*(vacío)*|
|**Total**|**77 550**|**47 000**|**165,00 %**|

### D2. ¿Qué mensaje de error dio Power BI?

Ninguno. No hubo error. Power BI devolvió números que se ven razonables y que **aprueban la revisión obvia**.

### D3. ¿Por qué Banano y Café aparecen hoy?

Porque aparecen en `dim\_cultivo` (la dimensión tiene 6 cultivos) pero no en `h\_cosecha` (que solo tiene 4 cultivos cosechados). **Hoy aparecen sostenidos por `\[Meta]`**, que devuelve un valor para cada cultivo aunque no haya cosecha. En las clases anteriores no aparecían porque no había una medida que los sustentara.

### D4. Suma de porcentajes

71,70 + 40,74 + 29,36 + 23,19 = **165,00**

Exactamente el total de la tabla.

### D5. Suma de la columna `\[Meta]`

4 × 47 000 = **188 000** (meta repetida en cuatro filas) +
2 × 47 000 = 94 000 (meta repetida en dos filas Banano y Café) =
**282 000 kilos de meta cuando se suman las 6 filas**

La empresa se propuso cosechar **47 000 kilos en 2026**. Pero si sumas la columna de meta por cultivo, parece que se propuso **282 000 kilos**. Eso es un múltiplo imposible de la realidad.

### D6. La medida que lo atrapa

```dax
Filas de meta = COUNTROWS(h\_meta)
```

Agregada a la tabla por cultivo:

|Cultivo|`\[Cosechas]`|`\[Filas de meta]`|
|-|-|-|
|Mango|3|**36**|
|Maiz|1|**36**|
|Guayaba|3|**36**|
|Cacao|2|**36**|
|Banano|*(vacío)*|**36**|
|Cafe|*(vacío)*|**36**|
|**Total**|**9**|**36**|

### D7. Regla sobre relaciones incompletas

Cuando una medida de una tabla de hechos se particiona por una dimensión que **no tiene relación** con esa tabla de hechos, la medida devuelve el **total sin desglose**. En este caso: todas las filas ven todas las 36 filas de `h\_meta` (3 fincas × 12 meses), porque `dim\_cultivo` no está conectada a `h\_meta`. La medida responde a un nivel que no debería poder responder.

### D8. El filtro cruzado bidireccional

Si se prendiera un filtro cruzado bidireccional entre `dim\_finca` y `h\_cosecha`, estaría afirmando que **la meta de una finca está distribuida por cultivo**. Eso es falso. La meta se fijó por finca completa, no desagregada por cultivo dentro de la finca. El bidireccional "arreglaría" el número pero haría la mentira invisible.

\---

## PARTE E: La granularidad de mes vs día

### E1. Meta al nivel de día (mes de marzo 2026)

```
Tabla con dim\_tiempo\[fecha], \[Kilos], \[Meta]
Segmentadores: anio = 2026, mes = 3
```

|Día|Kilos|Meta|
|-|-|-|
|01/03/2026|*(vacío)*|**6 900**|
|20/03/2026|4 200|*(vacío)*|
|22/03/2026|5 400|*(vacío)*|
|28/03/2026|1 200|*(vacío)*|
|**Total**|**10 800**|**6 900**|

Cumplimiento en cada día:

* 01/03: vacío (la meta no se particiona en días)
* 20/03: vacío
* 22/03: vacío
* 28/03: vacío
* Total: 156,52 %

### E2. ¿Por qué la meta aparece el día 1?

Porque `h\_meta` tiene una columna `fecha\_mes` que siempre guarda **el primer día del mes** (01/01, 01/02, 01/03, etc.). Eso es el estándar en análisis de datos: cuando captura información mensual, se fija la fecha al primer día para poder relacionarla con calendarios diarios. La meta del mes entero queda "pegada" al 01.

### E3. A qué nivel se puede leer

La medida `\[Meta]` se puede leer **al nivel de mes o más arriba** (trimestre, año, sin filtro). **No se puede leer al nivel de día** porque la meta no se desglosó por día. En este caso, el día 01 "ve" toda la meta del mes, y los demás días ven nada.

\---

## PARTE F: La medida que se calla

### F1. Medidas validadas

```dax
Meta valida = IF(
    ISFILTERED(dim\_cultivo\[cultivo]) || ISFILTERED(dim\_tiempo\[fecha]),
    BLANK(),
    \[Meta]
)
```

Resultado: La medida devuelve BLANK() si se está filtrando por cultivo O por fecha, y devuelve `\[Meta]` si no hay filtro.

```dax
Cumplimiento valido = DIVIDE(\[Kilos], \[Meta valida])
```

Resultado: El cumplimiento que solo contesta donde la meta puede contestar.

### F2. Tabla por cultivo con medidas validadas

```
Tabla con dim\_cultivo\[cultivo], \[Kilos], \[Meta valida], \[Cumplimiento valido]
Segmentador: anio = 2026
```

|Cultivo|Kilos|Meta valida|Cumplimiento valido|
|-|-|-|-|
|Cacao|10 900|*(vacío)*|*(vacío)*|
|Guayaba|13 800|*(vacío)*|*(vacío)*|
|Maiz|19 150|*(vacío)*|*(vacío)*|
|Mango|33 700|*(vacío)*|*(vacío)*|
|**Total**|**77 550**|**47 000**|**165,00 %**|

Banano y Café han desaparecido (ya no hay medida que los sostenga). Las cuatro filas de cultivo están vacías. El total contesta.

### F3. ¿Por qué el total sí contesta?

Porque en la fila del total **no hay filtro de cultivo activo**. El `ISFILTERED(dim\_cultivo\[cultivo])` devuelve FALSE en la fila de total, así que la condición del `IF` es falsa y devuelve `\[Meta]`. La medida se comporta correctamente: contesta donde puede, se calla donde no puede.

### F4. Tabla por finca con medidas validadas

```
Tabla con dim\_finca\[finca], \[Kilos], \[Meta valida], \[Cumplimiento valido]
Segmentador: anio = 2026
```

|Finca|Kilos|Meta valida|Cumplimiento valido|
|-|-|-|-|
|Agricola La Union|2 100|**8 000**|**26,25 %**|
|Finca El Guayabo|14 250|**19 000**|**75,00 %**|
|Hacienda Santa Rosa|14 200|**20 000**|**71,00 %**|
|**Total**|**30 550**|**47 000**|**65,00 %**|

Idéntica a la del punto de control 4. Callar la medida donde no puede contestar no le quita nada donde sí puede.

### F5. ¿Está bien que se vacíe el total cuando filtras por cultivo?

Sí. Si pones un segmentador de cultivo (por ejemplo, selecciona Mango), entonces `ISFILTERED(dim\_cultivo\[cultivo])` devuelve TRUE, y la medida se vacía **incluso en el total**. Eso es correcto: si estás filtrando por cultivo y la meta no tiene cultivo, la medida correctamente dice "no puedo contestar a este nivel".

\---

## PARTE G: Preguntas de cierre

### G1. Regla sobre granularidad

Una medida que cruza dos tablas de hechos se puede leer **al nivel de granularidad más grueso de las dos tablas**, o más arriba en las jerarquías. En este caso, `\[Meta]` se capturó por mes y finca, así que se lee a ese nivel (mes y finca) o más arriba (trimestre, año, sin filtro). Nunca más abajo (día, cultivo).

### G2. Diferencia entre los dos casos de error

En la Parte E, la medida **se calló sola** al bajar al día porque no hay relación entre `h\_meta\[fecha\_mes]` (primer día del mes) y `dim\_tiempo\[fecha]` (todos los días). La relación existe pero es muchos-a-uno a nivel mensual, así que al bajar al día se rompe naturalmente.

En la Parte D, la medida **no se calló** al partir por cultivo porque `h\_meta` sigue viendo todas sus filas; no hay relación que se rompa, hay simplemente ausencia de relación. Hubo que escribir el `BLANK()` manualmente.

### G3. Otra medida que habría dado la pista

`\[Cosechas] = COUNTROWS(h\_cosecha)` habría dado la pista. En la tabla por cultivo, `\[Cosechas]` hubiera mostrado números variables (3, 1, 3, 2, 0, 0) mientras que `\[Filas de meta]` mostró un constante 36. La discrepancia habría señalado que algo estaba mal.

### G4. Si mañana llega `cultivo\_id` en `h\_meta`

Si `h\_meta` tuviera una columna `cultivo\_id` y se creara la relación `h\_meta\[cultivo\_id] → dim\_cultivo\[cultivo\_id]`, entonces `\[Meta valida]` tendría que cambiar. Ya no habría que rechazar los filtros de cultivo. La medida pasaría a ser:

```dax
Meta valida = IF(
    ISFILTERED(dim\_tiempo\[fecha]),
    BLANK(),
    \[Meta]
)
```

Solo rechazaría los filtros de fecha, no los de cultivo. Y los números por cultivo serían reales, no totales repetidos.

### G5. Quién puso el aviso

En la Clase 14, el número malo (**19 750**) fue un error silencioso del modelo.
En la Clase 15, el número malo (**5 091,67**) fue un error de agregación.
En la Clase 16, el número malo (**−35,00 %**) fue un error de contexto.
En la Clase 17, el número malo (**24 440 repetido seis veces**) fue **nosotros**, escribiendo `IF(ISFILTERED(...), BLANK(), \[Meta])`. **Hasta hoy, el aviso no aparecía porque no lo escribimos. Hoy lo escribimos.**

\---

## Resumen de medidas

|Medida|Fórmula|Resultado clave|
|-|-|-|
|`\[Kilos]`|`= SUM(h\_cosecha\[kg])`|77 550 (total) / 30 550 (2026)|
|`\[Cosechas]`|`= COUNTROWS(h\_cosecha)`|25|
|`\[Meta]`|`= SUM(h\_meta\[kg\_meta])`|47 000|
|`\[Cumplimiento]`|`= DIVIDE(\[Kilos], \[Meta])`|165,00 % (sin filtro) / 65,00 % (2026)|
|`\[Filas de meta]`|`= COUNTROWS(h\_meta)`|36 (todas partes, sin desglose)|
|`\[Meta valida]`|`= IF(ISFILTERED(dim\_cultivo\[cultivo]) \|\| ISFILTERED(dim\_tiempo\[fecha]), BLANK(), \[Meta])`|47 000 (total) / vacío (por cultivo)|
|`\[Cumplimiento valido]`|`= DIVIDE(\[Kilos], \[Meta valida])`|165,00 % (total) / vacío (por cultivo)|

\---

## Número de control final

|Dónde|Qué debe decir|
|-|-|
|`h\_meta`|36 filas, SUM(kg\_meta) = 47 000 ✓|
|`\[Kilos]` sin filtros|77 550 ✓|
|`\[Meta]` sin filtros|47 000 ✓|
|`\[Cumplimiento]` sin filtros|165,00 % ✓|
|`\[Cumplimiento]` con año 2026|65,00 % ✓|
|Por finca, año 2026|Agricola 26,25 % / Guayabo 75,00 % / Santa Rosa 71,00 % ✓|
|Por cultivo: `\[Meta]`|47 000 en las seis filas ← el error del día ✓|
|Por cultivo: `\[Filas de meta]`|36 en todas partes ✓|
|Por cultivo: `\[Meta valida]`|Vacío en cultivos, 47 000 en total ✓|
|Banano y Café con `\[Meta valida]`|Desaparecen (sin medida que los sostenga) ✓|

\---

## 

