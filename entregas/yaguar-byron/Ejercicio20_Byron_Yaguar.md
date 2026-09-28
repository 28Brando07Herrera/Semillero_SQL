# Ejercicio 20 · Un Top 3 que siga siendo de tres

## Byron Yaguar Rios

\---

## PARTE A · La tabla de siempre

### A1 · Los segmentadores

**Segmentadores creados:**

* `dim\_tiempo\[año]` = 2026 ✓
* `dim\_tiempo\[mes]` en 1, 2, 3, 4 ✓
* `dim\_cultivo\[tipo]` = (sin marcar) ✓

\---

### A2 · Punto de Control 1 (tabla por cultivo, ordenada por Kilos ↓)

|Cultivo|\[Kilos]|\[Cosechas]|
|-|-|-|
|Mango|12700|3|
|Maiz|9800|1|
|Guayaba|5950|3|
|Cacao|2100|2|
|**Total**|**30550**|**9**|

\---

### A3 · ¿Por qué faltan dos cultivos?

**En una línea: `dim\_cultivo` tiene 6 cultivos y la tabla muestra 4. ¿Por qué no salen Banano y Café?**

Respuesta: Banano y Café no cosecharon nada en el período (2026, meses 1-4), así que no tienen registros en h\_cosecha y no aparecen en la tabla.

\---

### A4 · ¿Para qué un ranking si ya está ordenado?

**En una línea: la tabla ya está ordenada. ¿Para qué quieres una medida de ranking si ya se ve quién va primero?**

Respuesta: Porque cuando filtres o agregues segmentadores, el orden puede cambiar pero el ranking sigue siendo correcto; sin una medida visible no puedes filtrar por "Top 3".

\---

## PARTE B · Todos en primer lugar

### B1 · La medida obvia

```dax
Ranking = RANKX( dim\_cultivo , \[Kilos] )
```

\---

### B2 · Punto de Control 2 (con la medida sin ALL)

|Cultivo|\[Kilos]|\[Ranking]|
|-|-|-|
|Mango|12700|1|
|Maiz|9800|1|
|Guayaba|5950|1|
|Cacao|2100|1|
|**Total**|**30550**|**1**|

**Esperado: todos en 1**

\---

### B3 · Mensaje de error o advertencia

**Copia textual:**

```
(Sin advertencia en Power BI, pero todos los rankings son 1)
```

\---

### B4 · El contexto en RANKX

**En dos líneas: en la fila del Mango, ¿cuántas filas tiene `dim\_cultivo` cuando `RANKX` la recorre? ¿Por qué? Usa la palabra contexto.**

Respuesta: En la fila del Mango, `dim\_cultivo` tiene solo 1 fila (la fila actual de Mango) porque el contexto de fila filtra la tabla. Por eso RANKX compite Mango contra Mango solamente, y gana con ranking 1.

\---

## PARTE C · Con ALL, y el ranking que se calla

### C1 · Edita Ranking con ALL

```dax
Ranking = RANKX( ALL( dim\_cultivo ) , \[Kilos] )
```

\---

### C2 · Punto de Control 3 (con ALL)

|Cultivo|\[Kilos]|\[Ranking]|
|-|-|-|
|Mango|12700|1|
|Maiz|9800|2|
|Guayaba|5950|3|
|Cacao|2100|4|
|**Banano**|**(vacío)**|**5**|
|**Cafe**|**(vacío)**|**5**|
|**Total**|**30550**|**1**|

**Esperado: 1, 2, 3, 4, 5, 5, 1 (el total debe ser 1)**

\---

### C3 · El problema: Banano y Café

**En dos líneas: Banano y Café no cosecharon nada y salieron en quinto empatados. ¿Por qué aparecen ahora? ¿Qué clase anterior te recuerda?**

Respuesta: ALL(dim\_cultivo) trae todos los cultivos de la dimensión, incluidos los que no tienen datos. Esto recuerda a la clase de Granularidad, cuando una tabla de dimensión puede tener registros sin datos en la tabla de hechos.

\---

### C4 · El total que dice 1

**En una línea: el total dice 1. ¿Qué afirma ese 1, leído por alguien que no hizo la medida?**

Respuesta: El gerente podría pensar que el total de kilos (30,550) es el #1 en ranking, lo cual es falso; es solo el total de todos.

\---

### C5 · El ranking que se calla (HASONEVALUE + ISBLANK)

**Reemplaza la medida:**

```dax
Ranking =
IF(
    HASONEVALUE( dim\_cultivo\[cultivo] ) \&\& NOT ISBLANK( \[Kilos] ),
    RANKX( ALL( dim\_cultivo ) , \[Kilos] )
)
```

\---

### C6 · Punto de Control 4 (con IF/HASONEVALUE/ISBLANK)

|Cultivo|\[Kilos]|\[Ranking]|
|-|-|-|
|Mango|12700|1|
|Maiz|9800|2|
|Guayaba|5950|3|
|Cacao|2100|4|
|**Total**|**30550**|**(vacío)**|

**Esperado: 1, 2, 3, 4, (vacío) en total**

\---

## PARTE D · El Top 3 de dos filas (la fuga)

### D1 · Agrega filtro: Ranking ≤ 3

**Panel Filtros → Filtros en este objeto visual → \[Ranking] ≤ 3**

\---

### D2 · Punto de Control 5 (Top 3)

|Cultivo|\[Kilos]|\[Cosechas]|\[Ranking]|
|-|-|-|-|
|Mango|12700|3|1|
|Maiz|9800|1|2|
|Guayaba|5950|3|3|
|**Total**|**28450**|**7**|**(vacío)**|

**Esperado: 28 450 en el total (no 30 550)**

\---

### D2b · Marca "perenne" en el segmentador tipo

\---

### D3 · Punto de Control 6 (Top 3 con perenne)

|Cultivo|\[Kilos]|\[Cosechas]|\[Ranking]|
|-|-|-|-|
|Mango|12700|3|1|
|Guayaba|5950|3|3|
|**Total**|**18650**|**6**|**(vacío)**|

**Esperado: 2 filas (no 3), 18 650 en total**

\---

### D4 · Mensaje de error o advertencia (con perenne)

**Copia textual:**

```
(Sin advertencia en Power BI, pero falta Cacao que debería estar)
```

\---

### D5 · ¿Qué cultivo perenne falta?

**En dos líneas: el Top 3 tiene dos filas. ¿Qué cultivo perenne falta, cuántos kilos tiene, y qué ranking le tocó?**

Respuesta: Falta Cacao, que tiene 2,100 kilos y ranking 4. Aunque su ranking es 4 (no entra en Top 3 global), está oculto porque el filtro \[Ranking] ≤ 3 lo elimina.

\---

### D6 · La Guayaba en tercero sin segundo lugar

**En dos líneas: la Guayaba dice 3 y no hay segundo lugar a la vista. ¿Quién tiene el segundo lugar, y por qué sigue compitiendo si el segmentador lo escondió? Explícalo con ALL(dim\_cultivo).**

Respuesta: Maiz tiene el segundo lugar, pero está oculto en pantalla porque no es perenne. La Guayaba sigue compitiendo contra TODOS los cultivos (ALL(dim\_cultivo)), no solo contra los visibles, así que su ranking=3 es contra el universo completo.

\---

### D7 · Cambia a "ciclo corto"

\---

### D8 · Punto de Control 7 (Top 3 con ciclo corto)

|Cultivo|\[Kilos]|\[Ranking]|
|-|-|-|
|Maiz|9800|2|

**Esperado: 1 cultivo en segundo lugar**

\---

### D9 · ¿Quién va primero?

**En una línea: ¿quién va primero? ¿Está en tu pantalla?**

Respuesta: Mango va primero (12,700 kg), pero no está en pantalla porque no es ciclo corto.

\---

## PARTE E · ALLSELECTED

### E1 · Segunda medida: Ranking visible

```dax
Ranking visible =
IF(
    HASONEVALUE( dim\_cultivo\[cultivo] ) \&\& NOT ISBLANK( \[Kilos] ),
    RANKX( ALLSELECTED( dim\_cultivo ) , \[Kilos] )
)
```

**Agrega a la tabla. Quita el filtro de \[Ranking] y pon uno nuevo con \[Ranking visible] ≤ 3**

\---

### E2 · Punto de Control 8 (tabla de los tres segmentadores)

|Segmentador tipo|Filas del Top 3|\[Ranking]|\[Ranking visible]|\[Kilos] total|
|-|-|-|-|-|
|perenne|Mango, Guayaba, Cacao|1,3,4|1,2,3|**20750**|
|ciclo corto|Maiz|2|1|9800|

**Esperado:**

* *(ninguno)*: Mango, Maiz, Guayaba | 28 450
* perenne: Mango, Guayaba, Cacao | **20 750**
* ciclo corto: Maiz | 9 800

**CAPTURA: Este punto de control con perenne marcado**

\---

### E3 · ¿Por qué el error es fácil de publicar?

**En dos líneas: sin segmentador, \[Ranking] y \[Ranking visible] dan lo mismo. ¿Por qué eso hace que el error de la parte D sea tan fácil de publicar sin verlo?**

Respuesta: Porque el tablero se prueba sin segmentadores (*(ninguno)*) y todo funciona perfecto. Cuando el gerente aplica un filtro (perenne), el error aparece pero nadie lo vio en UAT.

\---

### E4 · Las preguntas distintas

**En dos líneas: \[Ranking] y \[Ranking visible] contestan preguntas distintas. Escribe cada pregunta en español, y di cuál de las dos es la de un "Top 3".**

Respuesta:

* \[Ranking]: ¿Cuál es el puesto global de este cultivo contra todos?
* \[Ranking visible]: ¿Cuál es el puesto de este cultivo solo entre los que se ven?
* La de un "Top 3" es \[Ranking visible], porque un Top 3 debe mostrar los 3 mejores de lo que filtraste, no los 3 mejores del universo.

\---

### E5 · Prueba: ALL(dim\_cultivo\[cultivo]) vs ALL(dim\_cultivo)

**Cambia `\[Ranking]` a: `ALL( dim\_cultivo\[cultivo] )` en lugar de `ALL( dim\_cultivo )`**

**Con perenne, ¿qué ranking da la Guayaba?**

Resultado: Guayaba da ranking 3 (igual que con ALL(dim\_cultivo))

**¿Por qué?**

Respuesta: Porque ALL(dim\_cultivo\[cultivo]) quita filtros en la columna cultivo pero trae todos los valores que están en h\_cosecha. Como Banano y Cafe no tienen datos, no entran en la competencia. El resultado es el mismo.

**Vuelve a poner: `ALL( dim\_cultivo )`**

\---

## PARTE F · Sin fórmula, y lo que un ranking no dice

### F1 · Tabla 2: N principales

**Copia la tabla. Quita el filtro de \[Ranking visible]. Agrega filtro: "N principales" → Superior 3 por \[Kilos]**

\---

### F2 · Punto de Control 9 (N principales)

|Segmentador tipo|Filas|\[Kilos] total|
|-|-|-|
|*ciclo corto*|Mango, Maiz, Guayaba|28450|
|perenne|Mango, Guayaba, Cacao|20750|

**Esperado: igual a E2 (28 450 y 20 750)**

\---

### F3 · ¿A cuál de tus medidas se parece N principales?

**En una línea: ¿a cuál de tus dos medidas se parece N principales, y en qué lo notas?**

Respuesta: Se parece a \[Ranking visible], porque ambas devuelven exactamente los 3 mejores de lo que ves en pantalla, no los 3 mejores del universo.

\---

### F4 · Ranking por finca

**Quita la marca del segmentador tipo (ninguno marcado)**

```dax
Ranking finca =
IF(
    HASONEVALUE( dim\_finca\[finca] ) \&\& NOT ISBLANK( \[Kilos] ),
    RANKX( ALLSELECTED( dim\_finca ) , \[Kilos] )
)
```

**Tabla nueva: dim\_finca\[finca], \[Kilos], \[Ranking finca]**

**Primero con año=2026, mes=1-4. Luego cambia año a 2025 (mes sigue igual).**

\---

### F5 · Punto de Control 10 (ranking por finca en 2026 y 2025)

**2026 (año=2026, mes=1-4):**

|Finca|\[Kilos] 2026|\[Ranking finca] 2026|
|-|-|-|
|Finca El Guayabo|14250|1|
|Hacienda Santa Rosa|14200|2|
|Agricola La Union|2100|3|

**2025 (año=2025, mes=1-4):**

|Finca|\[Kilos] 2025|\[Ranking finca] 2025|
|-|-|-|
|Finca El Guayabo|4450|2|
|Hacienda Santa Rosa|14200|1|
|Agricola La Union|(vacío)|(vacío)|

**Luego regresa año a 2026**

\---

### F6 · La diferencia entre filas

**En dos líneas: en 2026, entre 1° y 2° hay 50 kilos; entre 2° y 3° hay 12 100. ¿Qué dice el ranking de esa diferencia? ¿Qué columna tiene que ir siempre al lado de un ranking?**

Respuesta: El ranking no dice nada sobre esa diferencia; 1°, 2°, 3° son números iguales en importancia visual. Siempre debe ir la columna de valor (\[Kilos]) al lado del ranking para ver la magnitud de la diferencia.

\---

## PARTE G · Preguntas de cierre

### G1

**En una línea: `RANKX(tabla, expresión)`. ¿Qué decide la tabla? Contesta con la palabra "compite".**

Respuesta: La tabla decide cuáles filas compiten entre sí para el ranking.

\---

### G2

**En dos líneas: el `ALL` de la parte C arregló los cuatro primeros lugares y el de la parte D rompió el Top 3. ¿Es el mismo `ALL`? ¿Qué hizo distinto en cada caso?**

Respuesta: Es el mismo ALL. En C arregló el ranking porque mostró todo el universo claramente. En D rompió el Top 3 porque el filtro visual esconde filas pero ALL sigue compitiendo contra el universo escondido.

\---

### G3

**En una línea: escribe la regla de detección del día (basada en la de ayer sobre roles dinámicos).**

Respuesta: Si un ranking vale lo mismo con y sin segmentador, el ranking no respeta lo que filtraste; úsalo solo en medidas que no vayan a un filtro visual.

\---

### G4

**En dos líneas: un tablero muestra "Top 3 cultivos" y abajo "Total: 28 450". ¿Qué entendería el gerente, y qué tendría que decir la tarjeta para no engañarlo?**

Respuesta: El gerente entiende "sumé los 3 mejores y dan 28,450". La tarjeta debería decir "Top 3 de los cultivos sin filtro" o "Top 3 de ciclos cortos y anuales (28,450 si no filtra tipo)".

\---

### G5

**En una línea: ¿cuándo quieres `ALL` a propósito en un ranking? Da un ejemplo de pregunta de negocio.**

Respuesta: Cuando quieres comparar contra el ranking global. Ej: "¿En qué puesto global está Mango, aunque solo vea perennes en pantalla?"

\---

