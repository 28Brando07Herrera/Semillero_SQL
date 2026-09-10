# Ejercicio 15 · La medida y el contexto

## Byron Yaguar · Power BI · DAX

\---

## PARTE A: Las medidas básicas

### A1. Medida implícita → Medida explícita

Cuando arrastras `h\_cosecha\[kg]` a los valores, Power BI escribe por ti:

```dax
\[Kilos] = SUM(h\_cosecha\[kg])
```

**Resultado esperado: 30 550**

Escríbela explícitamente en Power BI:

1. Vista de Datos → h\_cosecha
2. Métrica nueva → Nombre: `\[Kilos]`
3. Fórmula: `= SUM(h\_cosecha\[kg])`

Luego, en un visual de Tarjeta, arrastra `\[Kilos]`.

\---

### A2. Medida de cuenta

```dax
\[Cosechas] = COUNTA(h\_cosecha\[cosecha\_id])
```

**Resultado esperado: 9**

O más seguro (ignorando blancos):

```dax
\[Cosechas] = COUNTROWS(h\_cosecha)
```

Ambas devuelven 9.

\---

## PARTE B: Contexto de filtro

### B1. Lo que el segmentador no ve

Cuando filtras por `finca = 'Finca El Guayabo'`, la medida `\[Kilos]` se recalcula:

```dax
\[Kilos] → 14 250
```

Cuando filtras por `finca = 'Hacienda Santa Rosa'`:

```dax
\[Kilos] → 14 200
```

Cuando filtras por `finca = 'Agricola La Union'`:

```dax
\[Kilos] → 2 100
```

**Esto es el contexto de filtro.** La misma medida, cuatro resultados (el total es el cuarto).

\---

### B2. El tabla con desglose por finca

Crea una tabla:

* **Filas**: `dim\_finca\[finca]`
* **Valores**: `\[Kilos]`, `\[Cosechas]`

|Finca|Kilos|Cosechas|
|-|-|-|
|Agricola La Union|2 100|1|
|Finca El Guayabo|14 250|3|
|Hacienda Santa Rosa|14 200|5|
|**Total**|**30 550**|**9**|

**Nota importante:** El total no es la suma de tres números distintos en tres contextos.
Es la suma de las nueve filas de `h\_cosecha` cuando NO hay filtro.

\---

## PARTE C: El error silencioso de DAX (la medida mal escrita)

### C1. El promedio que no cuenta lo que no tiene cosechas

¿Cuál es el promedio de kilos por cultivo?

Primera idea (INCORRECTA):

```dax
\[Promedio por Cultivo (MALO)] = DIVIDE(SUM(h\_cosecha\[kg]), COUNTROWS(dim\_cultivo))
```

Resultado: **5 091,67 kilos por cultivo**

**¿Por qué está mal?** Porque `COUNTROWS(dim\_cultivo)` cuenta todos los 6 cultivos, incluso Banano y Café que nunca cosecharon.

Cálculo visible:

* 30 550 kg ÷ 6 cultivos = 5 091,67 kg/cultivo

Pero eso ignora que dos cultivos tienen 0 cosechas.

\---

### C2. El promedio correcto: cuenta solo los que aparecen

```dax
\[Promedio por Cultivo (CORRECTO)] = DIVIDE(SUM(h\_cosecha\[kg]), DISTINCTCOUNT(h\_cosecha\[cultivo\_id]))
```

Resultado: **7 637,50 kilos por cultivo**

Cálculo visible:

* 30 550 kg ÷ 4 cultivos (con cosechas) = 7 637,50 kg/cultivo

\---

### C3. Lado a lado: las dos medidas que lo atrapan

|Medida|Denominador|Valor|
|-|-|-|
|Promedio (MALO)|COUNTROWS(dim\_cultivo)|**5 091,67**|
|Promedio (CORRECTO)|DISTINCTCOUNT(h\_cosecha\[cultivo\_id])|**7 637,50**|

Escribe ambas en tu modelo, ponlas en dos tarjetas **una al lado de la otra** en el tablero.
La diferencia (2 545,83) es exactamente el "costo" de contar cultivos que no tienen cosechas.

\---

## PARTE D: CALCULATE y ALL — quitando filtros

### D1. El porcentaje del total (contexto removido)

```dax
\[% del Total] = DIVIDE(
    SUM(h\_cosecha\[kg]),
    CALCULATE(SUM(h\_cosecha\[kg]), ALL(dim\_finca))
)
```

Cuando filtras por finca en una tabla:

|Finca|Kilos|% del Total|
|-|-|-|
|Agricola La Union|2 100|6,87%|
|Finca El Guayabo|14 250|46,64%|
|Hacienda Santa Rosa|14 200|46,48%|
|**Total**|**30 550**|**100,00%**|

**¿Qué hace `ALL(dim\_finca)`?**
No significa "todo". Significa **"quita el filtro de dim\_finca"**.
Así el denominador siempre es 30 550, aunque estés filtrando una finca.

**Resultado esperado:**

* Agricola La Union: 2 100 ÷ 30 550 = **6,87%**
* Finca El Guayabo: 14 250 ÷ 30 550 = **46,64%**
* Hacienda Santa Rosa: 14 200 ÷ 30 550 = **46,48%**

\---

### D2. Cultura vs cosechas reales (el 6 contra el 4)

```dax
\[Cultivos en Dimensión] = DISTINCTCOUNT(dim\_cultivo\[cultivo\_id])
```

Resultado: **6** (Mango, Maiz, Guayaba, Cacao, Banano, Café)

```dax
\[Cultivos con Cosecha] = DISTINCTCOUNT(h\_cosecha\[cultivo\_id])
```

Resultado: **4** (Mango, Maiz, Guayaba, Cacao — sin Banano ni Café)

\---

## PARTE E: El comportamiento con segmentadores

Cuando filtras el tablero por `tipo = 'Perenne'` (supón que Banano y Café son perennes):

|Medida|Valor|
|-|-|
|`\[Kilos]`|20 750|
|`\[Cosechas]`|7|
|`\[Promedio (MALO)]`|4 150,00 (20 750 ÷ 5)|
|`\[Promedio (CORRECTO)]`|6 916,67 (20 750 ÷ 3)|
|`\[Cultivos en Dimensión]`|**5** (el filtro baja de 6 a 5)|
|`\[Cultivos con Cosecha]`|**3** (el filtro baja de 4 a 3)|

**La medida MALA se recalcula automáticamente porque COUNTROWS ve menos cultivos.
La medida CORRECTA también, pero por la razón correcta: menos cultivos tienen cosechas.**

\---

## PARTE F: Preguntas conceptuales

### F1. ¿Por qué `DIVIDE` y no `/`?

```dax
\[Promedio MALO (División)] = SUM(h\_cosecha\[kg]) / COUNTROWS(dim\_cultivo)
```

```dax
\[Promedio (DIVIDE)] = DIVIDE(SUM(h\_cosecha\[kg]), COUNTROWS(dim\_cultivo))
```

Ambas dan 5 091,67. ¿Entonces por qué escribir `DIVIDE`?

**Respuesta:**
`DIVIDE` tiene un tercer parámetro para "cuando el denominador es 0":

```dax
DIVIDE(numerador, denominador, valor\_si\_error)
```

Si el denominador es 0, `/` devuelve un error que rompe el tablero.
`DIVIDE` devuelve un valor amable (por defecto, 0 o un valor que vos configures).

En esta clase es "bonito tener", pero en un tablero con mil filas donde algunas celdas
dividen por 0, `DIVIDE` es obligatorio para que no aparezcan rojo.

\---

### 

