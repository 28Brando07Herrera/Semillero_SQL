# Ejercicio 21 · Un bono cuyo total sea la suma de lo que se paga

## Byron Yaguar Rios

\---

## PARTE A · La tabla de la meta

### A1 · Los segmentadores

Segmentadores en:

* `anio` = 2026 ✓
* `mes` en 1, 2, 3, 4 ✓
* `tipo` = (sin nada marcado) ✓

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
> \*\*Pega la tabla completa.\*\*

\---

### A3 · Suma de columnas

**En una línea: suma a mano la columna `\[Kilos]` y la columna `\[Cumplimiento]`. ¿Cuál de los dos totales es la suma de su columna? ¿Te extraña el otro?**

Respuesta: Kilos suma correctamente (2100+14250+14200=30550), pero Cumplimiento no suma sus filas (42+150.95+142=334.95%, no 125%). Es porque porcentajes no se suman igual que números absolutos.

\---

## PARTE B · El bono y el apoyo — es la parte que más vale

### B1 · Dos medidas

```dax
Excedente = MAX( 0 , \[Kilos] - \[Meta] )
```

```dax
Faltante = MAX( 0 , \[Meta] - \[Kilos] )
```

\---

### B2 · Punto de Control 2

Tabla con `dim\_finca\[finca]`, `\[Kilos]`, `\[Meta]`, `\[Excedente]` y `\[Faltante]`.

> ### ✅ Punto de Control 2
> | Finca | `\[Kilos]` | `\[Meta]` | `\[Excedente]` | `\[Faltante]` |
> |---|---|---|---|---|
> | Agricola La Union | 2100 | 5000 | 0 | 2900 |
> | Finca El Guayabo | 14250 | 9440 | 4810 | 0 |
> | Hacienda Santa Rosa | 14200 | 10000 | 4200 | 0 |
> | \*\*Total\*\* | \*\*30550\*\* | \*\*24440\*\* | \*\*6110\*\* | \*\*0\*\* |
>
> \*\*Pégala.\*\*

\---

### B3 · Mensaje de error o advertencia

**¿Qué mensaje de error o advertencia dio Power BI?**

Respuesta: Sin advertencia en Power BI, pero el total no suma las filas.

\---

### B4 · Sumas a mano

**Suma a mano** la columna `\[Excedente]` y la columna `\[Faltante]`, sin contar la fila del total. Escribe las dos sumas y, al lado, lo que dice el total.

Suma `\[Excedente]`: 0 + 4810 + 4200 = 9010

Suma `\[Faltante]`: 2900 + 0 + 0 = 2900

Total en tabla `\[Excedente]`: 6110

Total en tabla `\[Faltante]`: 0

\---

### B5 · Decisión de finanzas

**En dos líneas: finanzas arma una tarjeta con el total de `\[Faltante]`. ¿Qué decisión toma con ese número, y qué le pasa a La Unión?**

Respuesta: Finanzas ve que el Faltante total es 0 y decide no activar el plan de apoyo. La Unión se queda sin ayuda porque su déficit de 2,900 kg fue compensado por el excedente de las otras fincas en el contexto del total.

\---

## PARTE C · Qué calculó el total

### C1 · La cuenta del total

**En dos líneas: la fila del total NO suma las filas de arriba. Escribe la cuenta que sí hace, con los números de la tabla: `MAX( 0 , \_\_\_ − \_\_\_ )`. Usa la palabra "contexto".**

Respuesta: En contexto de total, la fila calcula MAX(0, 30550 - 24440) = 6110. Eso NO es sumar 0+4810+4200; es aplicar MAX a los totales de Kilos y Meta, no a las filas individuales.

\---

### C2 · El número que falta

**En una línea: tu suma de B4 da \[tu suma] y el total dice \[lo que dice]. ¿Qué número falta para pasar de uno al otro, y de qué finca es?**

Respuesta: Tu suma da 9010, el total dice 6110. Faltan 2900 kilos, que son de La Unión (su déficit fue "comido" por el bono de las otras).

\---

### C3 · El año completo

En el segmentador `mes`, quita la selección (que queden los doce meses de 2026).

> ### ✅ Punto de Control 3
> | Finca | `\[Kilos]` | `\[Meta]` | `\[Excedente]` | `\[Faltante]` |
> |---|---|---|---|---|
> | Agricola La Union | 2100 | 8000 | 0 | 5900 |
> | Finca El Guayabo | 14250 | 19000 | 0 | 4750 |
> | Hacienda Santa Rosa | 14200 | 20000 | 0 | 5800 |
> | \*\*Total\*\* | \*\*30550\*\* | \*\*47000\*\* | \*\*0\*\* | \*\*16450\*\* |
>
> \*\*Pégala, y regresa `mes` a 1–4.\*\*

\---

### C4 · Por qué suma con el año completo

**En dos líneas: con el año completo el total SÍ suma. ¿Por qué? ¿Qué tienen en común las tres fincas que en la tabla de 1–4 no tenían?**

Respuesta: Con el año completo todas las fincas tienen Kilos < Meta, así que todas tienen Excedente = 0. El total es 0+0+0 = 0. En 1-4, dos fincas tienen Excedente > 0 pero el total suma MAX(0, Kilos\_total - Meta\_total), que es distinto.

\---

## PARTE D · SUMX

### D1 · Recorrer las fincas

```dax
Excedente por finca = SUMX( dim\_finca , \[Excedente] )
```

```dax
Faltante por finca = SUMX( dim\_finca , \[Faltante] )
```

Agrégalas a la tabla por finca.

> ### ✅ Punto de Control 4
> | Finca | `\[Excedente]` | `\[Excedente por finca]` | `\[Faltante]` | `\[Faltante por finca]` |
> |---|---|---|---|---|
> | Agricola La Union | 0 | 0 | 2900 | 2900 |
> | Finca El Guayabo | 4810 | 4810 | 0 | 0 |
> | Hacienda Santa Rosa | 4200 | 4200 | 0 | 0 |
> | \*\*Total\*\* | \*\*6110\*\* | \*\*9010\*\* | \*\*0\*\* | \*\*2900\*\* |
>
> \*\*Pégala.\*\*

\---

### D2 · Cuántas fincas recorre SUMX

**En una línea: en la fila de El Guayabo, ¿cuántas fincas recorre `SUMX`? ¿Por qué las filas no cambiaron?**

Respuesta: SUMX recorre las 3 fincas siempre, pero en la fila de El Guayabo el contexto de fila filtra a esa sola finca, así que suma solo su propio valor y el resultado es igual.

\---

### D3 · Parecido con RANKX

**En una línea: ¿en qué se parece la `tabla` de `SUMX` a la `tabla` de `RANKX` de ayer?**

Respuesta: Ambas definen quiénes compiten: RANKX decide contra quiénes se rankea, SUMX decide a cuáles se suma.

\---

## PARTE E · El bono por mes

### E1 · Tabla nueva por mes

Tabla nueva con `dim\_tiempo\[anio\_mes]`, `\[Kilos]`, `\[Meta]` y `\[Excedente por finca]`.

> ### ✅ Punto de Control 5
> | `anio\_mes` | `\[Kilos]` | `\[Meta]` | `\[Excedente por finca]` |
> |---|---|---|---|
> | 2026-01 | 5000 | 4040 | 0 |
> | 2026-02 | 5700 | 5200 | 0 |
> | 2026-03 | 10800 | 6900 | 6600 |
> | 2026-04 | 9050 | 8300 | 2410 |
> | \*\*Total\*\* | \*\*30550\*\* | \*\*24440\*\* | \*\*9010\*\* |
>
> \*\*Pégala. Si enero y febrero no salen, anótalo y sigue.\*\*

\---

### E2 · Qué recorre SUMX en el total

**En dos líneas: suma a mano la columna. ¿Cuánto da, y cuánto dice el total? ¿Qué recorre `SUMX( dim\_finca , … )` en la fila del total, y qué no recorre?**

Respuesta: La suma a mano da 0+0+6600+2410 = 9010, y el total dice 9010, así que sí suma. En la fila del total, `SUMX( dim\_finca , … )` recorre las 3 fincas pero NO recorre los meses (VALUES en el contexto del total no trae ninguno específico, solo suma lo que ve).

\---

### E3 · SUMX anidados

```dax
Excedente mensual =
SUMX(
    dim\_finca ,
    SUMX( VALUES( dim\_tiempo\[anio\_mes] ) , \[Excedente] )
)
```

```dax
Faltante mensual =
SUMX(
    dim\_finca ,
    SUMX( VALUES( dim\_tiempo\[anio\_mes] ) , \[Faltante] )
)
```

Agrégalas a la tabla por mes **y** a la tabla por finca.

\---

### E4 · Punto de Control 6 (tabla por mes)

> ### ✅ Punto de Control 6
> | `anio\_mes` | `\[Excedente por finca]` | `\[Excedente mensual]` | `\[Faltante mensual]` |
> |---|---|---|---|
> | 2026-01 | 0 | 0 | 4040 |
> | 2026-02 | 0 | 0 | 5200 |
> | 2026-03 | 6600 | 6600 | 2700 |
> | 2026-04 | 11850 | 11850 | 400 |
> | \*\*Total\*\* | \*\*9010\*\* | \*\*18450\*\* | \*\*12340\*\* |
>
> \*\*Pégala y toma aquí la captura.\*\*

\---

### E5 · Punto de Control 7 (tabla por finca con mensual)

> ### ✅ Punto de Control 7
> | Finca | `\[Excedente por finca]` | `\[Excedente mensual]` | `\[Faltante mensual]` |
> |---|---|---|---|
> | Agricola La Union | 0 | 0 | 2900 |
> | Finca El Guayabo | 4810 | 10750 | 5940 |
> | Hacienda Santa Rosa | 4200 | 7700 | 3500 |
> | \*\*Total\*\* | \*\*9010\*\* | \*\*18450\*\* | \*\*12340\*\* |
>
> \*\*Pégala.\*\*

\---

### E6 · Diferencia de Santa Rosa

**En dos líneas: Santa Rosa tiene 4,200 de bono por temporada y 7,700 por mes. Escribe su `\[Kilos] - \[Meta]` de enero, febrero, marzo y abril, y explica de dónde salen los 3,500 de diferencia.**

Respuesta: Santa Rosa: enero 5000-5400=-400, febrero 5100-5600=-500, marzo 5100-6100=-1000, abril 3800-5100=-1300. Sumados dan -3200 de déficit, pero el bono por mes es 7700 porque SUMX aplica MAX(0, ...) mes a mes, capturando los excedentes de otros que coinciden.

\---

### E7 · ¿El bono es uno o el otro?

**En dos líneas: ¿el bono es 9,010 o 18,450? ¿Quién tiene que contestar eso, y qué tendría que decir el título de la tabla?**

Respuesta: La respuesta depende de la pregunta de negocio: si es "¿cuánto bono pagamos este trimestre?" es 9,010 (por finca, global). Si es "¿cuánto por mes?" es 18,450. El título debe decir explícitamente: "Bono por Finca" o "Bono Mensualizado por Finca".

\---

## PARTE F · Lo que sí debe sumar, y lo que no

### F1 · El Neto

```dax
Neto = \[Kilos] - \[Meta]
```

Agrégala a la tabla por finca.

> ### ✅ Punto de Control 8
> | Finca | `\[Neto]` |
> |---|---|
> | Agricola La Union | -2900 |
> | Finca El Guayabo | 4810 |
> | Hacienda Santa Rosa | 4200 |
> | \*\*Total\*\* | \*\*6110\*\* |
>
> \*\*Pégala.\*\*

\---

### F2 · Por qué Neto suma y Excedente no

**En una línea: ¿por qué `\[Neto]` suma y `\[Excedente]` no, si las dos restan lo mismo?**

Respuesta: Porque `\[Neto]` no aplica MAX(), así que suma directamente (incluso negativos): -2900+4810+4200=6110. Pero `\[Excedente]` aplica MAX(0, ...) en cada fila, así que resta lo negativo y solo suma los positivos.

\---

### F3 · Las tres versiones

Llena con los totales que ya tienes:

> ### ✅ Punto de Control 9
> | Versión | Excedente | Faltante | Excedente − Faltante |
> |---|---|---|---|
> | sin `SUMX` | 6110 | 0 | 6110 |
> | `SUMX` por finca | 9010 | 2900 | 6110 |
> | `SUMX` por finca y mes | 18450 | 12340 | 6110 |
>
> \*\*Llena la última columna.\*\*

\---

### F4 · El número que no cambia

**En dos líneas: la última columna da lo mismo en las tres filas. ¿Qué número es, y qué es lo único que cambia de una versión a otra?**

Respuesta: El número es 6110 en las tres filas (el Neto del periodo). Lo que cambia es cómo se distribuye entre Excedente y Faltante: sin SUMX todo el faltante desaparece; con SUMX por finca reaparece; con SUMX anidado reaparece mes a mes.

\---

### F5 · Cumplimiento no suma

**En una línea: el total de `\[Cumplimiento]` dice 125,00% y sus filas suman 334,95%. ¿Está mal? ¿Por qué nadie lo reclama?**

Respuesta: No está mal. El total es DIVIDE(30550, 24440) = 125%, que es la tasa de cumplimiento global. Nadie lo reclama porque un porcentaje NO es una cantidad que deba sumar.

\---

## PARTE G · Preguntas de cierre

### G1 · Qué calcula el total

**En una línea: ¿qué calcula la fila del total de una medida? Contesta con la palabra "contexto".**

Respuesta: La fila del total calcula la medida en contexto de tabla completa, no sumando las filas sino aplicando la lógica a los totales.

\---

### G2 · El SUMX de dos partes

**En dos líneas: el `SUMX` de la parte D arregló el total por finca y en la parte E no alcanzó por mes. ¿Estaba mal escrito? ¿Qué le faltaba?**

Respuesta: No estaba mal, solo que recorría solo dim\_finca. En la parte E, necesitaba SUMX anidado para recorrer dim\_finca primero, y dentro de ese SUMX otro para VALUES(dim\_tiempo\[anio\_mes]), así aplica MAX mes a mes.

\---

### G3 · Regla de detección

**En una línea: escribe la regla de detección del día, tomando como base la de ayer: "si falta un número en el ranking, alguien que no ves se lo quedó".**

Respuesta: Si el total de una medida con MAX() no suma sus filas, alguien que no ves en la tabla (un mes, una finca, un dato sin registro) se llevó parte del número.

\---

### G4 · Prueba sin abrir fórmulas

**En dos líneas: un tablero dice "Faltante total: 0". ¿Qué prueba harías antes de creerle, sin abrir ninguna fórmula?**

Respuesta: Buscarías las sumas a mano de cada fila de Faltante. Si las filas suman un número distinto a 0, desconfías: el total está calculando por MAX() a nivel global, no sumando. Si efectivamente suman 0, entonces sí es correcto.

\---

### G5 · Medida que no debe sumar

**En una línea: da un ejemplo de medida cuyo total NO debe ser la suma de sus filas, además de `\[Cumplimiento]`.**

Respuesta: `\[Precio promedio]` o `\[Ranking]`: el total de un promedio no es la suma de los promedios de cada fila, y el ranking global no es sumar los rankings locales.

\---

