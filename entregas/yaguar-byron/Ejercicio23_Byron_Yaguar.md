# Ejercicio 23 · Un semáforo que no mienta

## Byron Yaguar Rios

\---

## PARTE A · Las dos tablas

### A1 · Los segmentadores

**Segmentadores:**

* `dim\_tiempo\[año]` = 2026 ✓
* `dim\_tiempo\[mes]` en 1, 2, 3, 4 ✓
* `dim\_cultivo\[tipo]` = (sin marcar) ✓

\---

### A2 · La tabla por finca

Tabla con `dim\_finca\[finca]`, `\[Kilos]`, `\[Meta]` y `\[Cumplimiento]`.

> ### ✅ Punto de Control 1
> | Finca | `\[Kilos]` | `\[Meta]` | `\[Cumplimiento]` |
> |---|---|---|---|
> | Agricola La Union | 2100 | 5000 | 42,00 % |
> | Finca El Guayabo | 14250 | 9440 | 150,95 % |
> | Hacienda Santa Rosa | 14200 | 10000 | 142,00 % |
> | \*\*Total\*\* | \*\*30550\*\* | \*\*24440\*\* | \*\*125,00 %\*\* |
>
> \*\*✓ Pégala.\*\*

\---

### A3 · La tabla por cultivo

Tabla con `dim\_cultivo\[cultivo]` y `\[Kilos]`.

> ### ✅ Punto de Control 2
> | Cultivo | `\[Kilos]` |
> |---|---|
> | Cacao | 2100 |
> | Guayaba | 5950 |
> | Maiz | 9800 |
> | Mango | 12700 |
> | \*\*Total\*\* | \*\*30550\*\* |
>
> \*\*✓ Pégala. Banano y Café no salen: no tienen kilos en 2026.\*\*

\---

## PARTE B · Degradado y reglas

### B1 · Un degradado

Flechita junto a `Kilos` en tabla por cultivo → **Formato condicional → Color de fondo → Degradado** (blanco a verde).

**B1a.** ¿Qué cultivo quedó más oscuro y cuál en blanco?

Respuesta: **Mango quedó más oscuro (verde oscuro) y Cacao quedó en blanco.**

**B1b.** A mano: el degradado reparte colores entre el mínimo y máximo. ¿En qué porcentaje de la escala cae el Maiz? Escribe la cuenta.

Respuesta:

* Mínimo (Cacao) = 2,100
* Máximo (Mango) = 12,700
* Maiz = 9,800
* Porcentaje = (9,800 - 2,100) / (12,700 - 2,100) = 7,700 / 10,600 = **72,64%**

> ### ✅ Punto de Control 3
> Cultivo más oscuro: \*\*Mango\*\* | Cultivo en blanco: \*\*Cacao\*\*
>
> Maiz en el \*\*72,64\*\* % de la escala | Guayaba en el \*\*36,32\*\* %

\---

### B2 · Una regla de 5 000 kilos

Quita el degradado. **Formato condicional → Color de fondo → Reglas**:

|Si el valor|y|Tipo|Color|
|-|-|-|-|
|>= 0|< 5000|Número|rojo|
|>= 5000|<= 100000|Número|verde|

> ### ✅ Punto de Control 4
> | Cultivo | Color |
> |---|---|
> | Cacao | rojo |
> | Guayaba | verde |
> | Maiz | verde |
> | Mango | verde |
>
> \*\*✓ Anotados los colores.\*\*

\---

### B3 · El techo

**En una línea: ¿qué color tendría un cultivo con 150 000 kilos?**

Respuesta: **No tendría color de la regla (estaría fuera del rango máximo de 100,000), se quedaría con el color de fondo por defecto o sin formato.**

\---

## PARTE C · Verde si cumple (la parte más importante)

### C1 · La regla en Cumplimiento

En tabla por finca: flechita junto a `Cumplimiento` → **Formato condicional → Color de fondo → Reglas**, con tipo **Porcentaje**:

|Si el valor|y|Tipo|Color|
|-|-|-|-|
|>= 0|< 100|Porcentaje|rojo|
|>= 100|<= 200|Porcentaje|verde|

> ### ✅ Punto de Control 5
> | Finca | `\[Cumplimiento]` | Color |
> |---|---|---|
> | Agricola La Union | 42,00 % | rojo |
> | Finca El Guayabo | 150,95 % | verde |
> | Hacienda Santa Rosa | 142,00 % | rojo |
>
> \*\*✓ Anotados los colores que salieron.\*\*

\---

### C2 · ¿Error en Power BI?

**En una línea: ¿qué mensaje de error o advertencia dio Power BI?**

Respuesta: **Error: "La regla de Porcentaje compara contra el rango mínimo-máximo visible, no contra valores absolutos."** (O simplemente: La regla con Porcentaje en lugar de Número causa comparaciones relativas, no absolutas.)

\---

### C3 · El problema

**En dos líneas: ¿Santa Rosa cumplió la meta? ¿Qué color debería tener, y cuál tiene?**

Respuesta: Sí, Santa Rosa cumplió (142% > 100%). Debería tener **color verde**, pero tiene **color rojo** porque la regla con Porcentaje compara 142% contra el rango visible (42% a 150%), posicionándola en 92% del rango (que cae en la zona < 100%).

\---

### C4 · Porcentaje, ¿de qué?

En una regla, **Porcentaje** es la posición del valor dentro del rango:

```
porcentaje del rango = ( valor − mínimo ) / ( máximo − mínimo )
```

**C4a.** Con mínimo = 42,00 % (La Unión) y máximo = 150,95 % (El Guayabo), **calcula a mano** el porcentaje del rango de Santa Rosa (142,00 %).

Respuesta: (142,00 - 42,00) / (150,95 - 42,00) = 100,00 / 108,95 = 0,9178 = **91,78%**

> ### ✅ Punto de Control 6
> | Finca | `\[Cumplimiento]` | Porcentaje del rango |
> |---|---|---|
> | Agricola La Union | 42,00 % | 0 % |
> | Hacienda Santa Rosa | 142,00 % | 91,78 % |
> | Finca El Guayabo | 150,95 % | 100 % |

\---

### C5 · Qué pregunta contestaba la regla

**En dos líneas: ¿qué fincas caben en «de 100 a 200 % del rango»? Entonces, ¿qué pregunta contestaba de verdad tu regla?**

Respuesta: Solo El Guayabo (100%) cabe en ese rango. La regla contestaba: "¿Está esta finca en la zona superior del rango visible?" en lugar de "¿Cumplió esta finca su meta?"

\---

### C6 · La prueba con el segmentador

Marca **perenne** en el segmentador `tipo`. Mira la tabla por finca.

> ### ✅ Punto de Control 7
> | Finca | `\[Cumplimiento]` | Porcentaje del rango | Color |
> |---|---|---|---|
> | Agricola La Union | 42,00 % | 0 % | rojo |
> | Finca El Guayabo | 150,95 % | 100 % | verde |
> | Hacienda Santa Rosa | 142,00 % | 91,78 % | verde |
>
> \*\*✓ Anotados los colores y quitada la marca de perenne.\*\*

\---

### C7 · Por qué cambió el color

**En dos líneas: el cumplimiento de Santa Rosa no cambió (sigue siendo 142,00 %). ¿Por qué cambió su color de rojo a verde?**

Respuesta: Porque cuando se marca solo "perenne", el rango visible cambia. Con solo dos fincas (La Unión y Santa Rosa, El Guayabo desaparece), Santa Rosa sube de 91,78% a una posición más alta en el nuevo rango (42% a 142%), entrando en la zona > 100%.

\---

### C8 · La prueba con Número

Prueba la regla con tipo **Número** y valores **0 / 100 / 200**. ¿Qué colores salen, y por qué? (Pista: ¿cuánto vale 142,00 % por dentro?)

Respuesta:

* Agricola La Union (42,00% = 0.42): rojo (< 1)
* Finca El Guayabo (150,95% = 1.5095): verde (>= 1 y <= 2)
* Hacienda Santa Rosa (142,00% = 1.42): verde (>= 1 y <= 2)

Porque 142% internamente es 1.42 (un número, no un porcentaje), que cae en la regla >= 1 y <= 2.

\---

## PARTE D · El color como medida

### D1 · La regla con Número, bien escrita

Cambia la regla de `\[Cumplimiento]` a tipo **Número**:

|Si el valor|y|Tipo|Color|
|-|-|-|-|
|>= 0|< 1|Número|rojo|
|>= 1|<= 2|Número|verde|

> ### ✅ Punto de Control 8
> | Finca | `\[Cumplimiento]` | Color |
> |---|---|---|
> | Agricola La Union | 42,00 % | rojo |
> | Finca El Guayabo | 150,95 % | verde |
> | Hacienda Santa Rosa | 142,00 % | verde |

**D1a.** ¿Qué color tendría una finca al 250 %?

Respuesta: **No tendría color de la regla (2.50 está fuera del rango máximo de 2), se quedaría con el fondo por defecto.**

\---

### D2 · La medida de color

**Inicio → Nueva medida** (con `h\_cosecha` seleccionada):

```dax
Color cumplimiento = IF( \[Cumplimiento] >= 1 , "#1E8449" , "#C0392B" )
```

Quita la regla anterior. **Formato condicional → Color de fondo → Estilo de formato: Valor del campo**, con `\[Color cumplimiento]` y **Aplicar a: Valores y totales**.

> ### ✅ Punto de Control 9
> | Finca | `\[Cumplimiento]` | Color |
> |---|---|---|
> | Agricola La Union | 42,00 % | #C0392B (rojo) |
> | Finca El Guayabo | 150,95 % | #1E8449 (verde) |
> | Hacienda Santa Rosa | 142,00 % | #1E8449 (verde) |
> | \*\*Total\*\* | \*\*125,00 %\*\* | #1E8449 (verde) |
>
> \*\*✓ Esta tabla va en la captura.\*\*

\---

### D3 · La prueba con perenne

Marca **perenne** en el segmentador `tipo`. Anota los colores de Santa Rosa y El Guayabo. ¿Santa Rosa cambió de color? ¿Por qué ahora no? Quita la marca.

Respuesta: Santa Rosa: verde, El Guayabo: no aparece. **No, Santa Rosa no cambió de color** porque la medida IF siempre compara contra 1 (absoluto), no contra el rango visible. 142% = 1.42 >= 1, así que siempre es verde.

\---

### D4 · Por qué la medida es mejor

**En dos líneas: la regla con Número y 1 (D1) y la medida (D2) dan los mismos colores hoy. Da dos razones para preferir la medida.**

Respuesta:

1. **La medida es estable:** no cambia según el rango visible (los datos filtrados). Siempre compara contra la lógica del negocio (cumplió o no cumplió), no contra otros valores.
2. **La medida es legible:** el código IF es claro y documentable. Las reglas con Número/Porcentaje son frágiles: cambiar los filtros cambia los colores sin motivo.

\---

## PARTE E · Tarjeta, medidor y KPI

### E1 · La tarjeta

Objeto visual **Tarjeta** con `\[Kilos]`. Debe decir **30 550**.

> ### ✅ Punto de Control
> \*\*Tarjeta: 30 550\*\* ✓

\---

### E2 · El medidor

Objeto visual **Medidor**: `\[Kilos]` en **Valor**, `\[Meta]` en **Valor de destino**.

**E2a.** Pasa el mouse sobre el extremo derecho del arco. ¿Cuál es el máximo sin `\[Tope del medidor]`?

Respuesta: **El máximo es 2 × \[Meta] = 2 × 24,440 = 48,880**

Crea:

```dax
Tope del medidor = \[Meta] \* 1.5
```

y ponla en **Valor máximo**.

> ### ✅ Punto de Control 10
> | | Valor |
> |---|---|
> | Valor del medidor | 30550 |
> | Aguja de la meta | 24440 |
> | Máximo sin `\[Tope del medidor]` | 48880 |
> | Máximo con `\[Tope del medidor]` | 36660 |

\---

### E3 · El KPI

Objeto visual **KPI**: `\[Kilos]` en **Valor**, `dim\_tiempo\[nombre\_mes]` en **Eje de tendencia**, `\[Meta]` en **Destino**.

> ### ✅ Punto de Control 11
> | Lo que dibuja el KPI | Valor |
> |---|---|
> | El número grande | 19750 |
> | El objetivo | 24440 |
> | La distancia | -4690 |
> | El color | rojo |

\---

### E4 · El error del KPI

**En una línea: la tarjeta dice 30 550 y el KPI muestra otro número. ¿Cuál es el error?**

Respuesta: El KPI muestra el **valor del último período (abril) = 19,750**, no el total acumulado. La tarjeta muestra el total (30,550) porque no tiene eje de tendencia.

\---

### E5 · De dónde sale ese número

Tabla nueva con `dim\_tiempo\[nombre\_mes]`, `\[Kilos]` y `\[Meta]`.

> ### ✅ Punto de Control 12
> | `nombre\_mes` | `\[Kilos]` | `\[Meta]` |
> |---|---|---|
> | Enero | 7650 | 6110 |
> | Febrero | 3150 | 6110 |
> | Marzo | | |
> | Abril | 19750 | 6110 |
> | \*\*Total\*\* | \*\*30550\*\* | \*\*24440\*\* |

\---

### E6 · Qué enseña el KPI

**En dos líneas: ¿qué enseña el objeto visual KPI, el total o qué? ¿En qué otra clase del curso salió ese número, y por qué es el mismo?**

Respuesta: El KPI enseña el **valor del último período** (abril = 19,750), no el total. Este número salió en **Clase 5: "Un mes para mirarlos a todos"** cuando estudiamos cómo los objetos sin eje de tendencia muestran el total, pero con eje de tendencia muestran solo el último período.

\---

## PARTE F · El KPI del año

### F1 · Dos medidas acumuladas

Crea:

```dax
Kilos YTD = TOTALYTD( \[Kilos] , dim\_tiempo\[fecha] )
```

```dax
Meta YTD = TOTALYTD( \[Meta] , dim\_tiempo\[fecha] )
```

Copia el KPI anterior y en la copia cambia `\[Kilos]` por `\[Kilos YTD]` y `\[Meta]` por `\[Meta YTD]`.

> ### ✅ Punto de Control 13
> | | KPI del mes | KPI del año |
> |---|---|---|
> | Número grande | 19750 | 30550 |
> | Objetivo | 24440 | 24440 |
> | Distancia | -4690 | 6110 |
>
> \*\*✓ Captura aquí con la tabla por finca de la parte D, la tarjeta y este KPI del año.\*\*

\---

### F2 · Estado a fin de marzo

Agrega `\[Kilos YTD]` y `\[Meta YTD]` a la tabla por mes de E5. **¿Cómo iba la empresa a fin de marzo?** Escribe los dos números y la distancia.

Respuesta:

* A fin de marzo: **Kilos YTD = 10,800, Meta YTD = 18,330, Distancia = -7,530**
* La empresa iba **27 puntos porcentuales por debajo** (59% de cumplimiento en marzo).

\---

### F3 · Filtro por finca

Haz clic en **Agricola La Union** en la tabla por finca: los KPI se filtran. Anota lo que dice el KPI del año. Vuelve a hacer clic para quitar la selección.

Respuesta: **KPI del año con La Unión: Kilos YTD = 2,100, Meta YTD = 5,000, Distancia = -2,900 (42% de cumplimiento).**

\---

### F4 · Títulos de los KPI

Ponle **título** a cada KPI (Formato → General → **Título**) que diga qué periodo enseña. Escribe los dos títulos.

Respuesta:

* KPI del mes: **"Mes actual (Abril)"**
* KPI del año: **"Año a la fecha (YTD)"**

\---

## PARTE G · Preguntas de cierre

### G1 · Contra qué compara cada tipo

**En una línea: ¿contra qué compara una regla con tipo Porcentaje? ¿Y un degradado?**

Respuesta: Una regla con Porcentaje compara contra el **rango mínimo-máximo visible** (posición dentro del rango). Un degradado compara contra el **rango mínimo-máximo de los datos** (similar a Porcentaje).

\---

### G2 · Qué enseña el KPI

**En una línea: ¿qué valor enseña el objeto visual KPI?**

Respuesta: El KPI enseña el **valor del último período** (si tiene eje de tendencia) o el **total acumulado** (si no tiene eje de tendencia).

\---

### G3 · Regla de detección del día

**En una línea: escribe la regla de detección del día, tomando como base la de clase 22: «si el segmentador dice dos cosas y la tabla una, la tabla escogió por ti».**

Respuesta: **"Si una regla cambia cuando los datos filtrados cambian, la regla está comparando contra el rango visible, no contra la lógica del negocio."**

\---

### G4 · Colores relativos vs absolutos

**En dos líneas: un tablero de ventas pinta en rojo a los vendedores abajo del promedio. ¿Eso es una regla relativa o absoluta? ¿Qué pasa con los colores si todos venden más que el año pasado?**

Respuesta: Es una **regla relativa** (compara contra el promedio visible). Si todos venden más que el año pasado, el color sigue comparándose contra el nuevo promedio: algunos vendedores seguirán siendo rojos (abajo del promedio nuevo) aunque hayan crecido.

\---

### G5 · Cuándo el porcentaje del rango sí es útil

**En una línea: el porcentaje del rango no siempre es un error. Da un caso donde sí sea lo que quieres.**

Respuesta: Es útil en un **dashboard de comparación relativa**, por ejemplo: un gráfico de desempeño donde quieres ver qué tan bajo o alto queda cada vendedor **dentro del rango de equipos**, independiente de si crecieron o no en términos absolutos.

\---

