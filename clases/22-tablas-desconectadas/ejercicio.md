# Ejercicio práctico 22 · Un simulador de metas que no invente el nivel

**Duración: 2 horas · Individual · Solo Power BI Desktop · Entrega: un archivo `.md` y una captura**

---

## Qué vas a lograr hoy

1. Crear una **tabla desconectada** con `DATATABLE`, y ver que un segmentador sobre ella **no filtra nada** por sí solo.
2. Leer el segmentador desde una medida con **`SELECTEDVALUE`**, y ajustar la meta con el nivel marcado.
3. Marcar **dos niveles a la vez** y ver que la tabla dice **125,00 %**, calculado con un nivel que **nadie marcó**.
4. Ver que la **columna Total** de una matriz hace lo mismo: 5 000 donde las columnas suman 37 500.
5. Arreglarlo con **`HASONEVALUE`**, para que la medida **se calle** cuando no sabe qué nivel usar.
6. Contestar la pregunta de la gerencia: **¿hasta qué nivel se puede subir la meta?**

**El número que prueba que el simulador quedó bien es 96,15 %, al 130.** El que prueba que entendiste la clase es que sepas de dónde salió el **125,00 %** con 130 y 150 marcados.

---

## Antes de empezar

Octava clase seguida sin motor: hoy tampoco se prende Oracle, ni Docker, ni el driver.

| | |
|---|---|
| Oracle, Docker, OCMT, `GRANT` | **no** |
| Power BI Desktop | **sí**, y es lo único |

### Lo que se baja hoy

**Hoy no se baja nada.** Los CSV son los de la clase 17, que son también los cinco primeros de [`datos/csv_clase19/`](../../datos/csv_clase19/). La tabla nueva **se escribe a mano**, con una fórmula.

Usa el `.pbix` de la clase 21. Las medidas de ayer pueden quedarse: hoy no se usan.

> **Si tu `.pbix` quedó a medias**, carga los cinco CSV de [`datos/csv_clase19/`](../../datos/csv_clase19/) (sin `seguridad.csv`), rehaz las relaciones y crea `[Kilos]`, `[Meta]` y `[Cumplimiento]` como en la clase 17. Cuesta unos veinte minutos.

### Lo que tiene que estar funcionando antes de empezar

- Las relaciones de `h_meta`: `dim_finca[finca_id]` → `h_meta[finca_id]` y `dim_tiempo[fecha]` → `h_meta[fecha_mes]`
- Las medidas `[Kilos]`, `[Meta]` y `[Cumplimiento]`
- Segmentadores en `anio` = 2026 y `mes` en 1–4: `[Kilos]` = **30 550**, `[Meta]` = **24 440**, `[Cumplimiento]` = **125,00 %**
- **Ver como apagado**, y **el segmentador `tipo` sin nada marcado.** Si quedó **perenne**, El Guayabo pierde el maíz y no cumple en ningún nivel.

---

## Cómo se entrega

En `entregas/apellido-nombre/`, por *pull request*, **dos archivos**:

| Archivo | Qué lleva |
|---|---|
| `Ejercicio22_Apellido_Nombre.md` | **cada fórmula en un bloque de código**, y debajo la tabla que te dio, más la suma a mano de la parte D y las respuestas de la parte G |
| `clase22-escenarios.png` | captura de **la matriz por finca y nivel** con `[Meta del escenario]` y la **columna Total vacía**, junto a **la tabla por nivel** con `[Fincas que cumplen]` |

Formato de cada respuesta, para que se pueda corregir:

````
### B1 · Meta ajustada

```
Meta ajustada = [Meta] * [Nivel elegido] / 100
```

Con 130 marcado: La Union 6 500 · El Guayabo 12 272 · Santa Rosa 13 000 · Total 31 772
````

> **Una fórmula sin su resultado anotado abajo no cuenta.** El `.pbix` no se entrega: el repositorio lo ignora a propósito.

---

## Parte A · Una tabla que no viene de ningún archivo (10 min)

### A1. Los segmentadores

Segmentadores en `anio` = 2026 y `mes` en 1, 2, 3 y 4. **No los muevas en todo el ejercicio.** El de `tipo`, **sin nada marcado**.

### A2. La tabla por finca

Objeto visual **Tabla** con `dim_finca[finca]`, `[Kilos]`, `[Meta]` y `[Cumplimiento]`.

> ### ✅ Punto de control 1
> | Finca | `[Kilos]` | `[Meta]` | `[Cumplimiento]` |
> |---|---|---|---|
> | Agricola La Union | 2 100 | 5 000 | 42,00 % |
> | Finca El Guayabo | 14 250 | 9 440 | 150,95 % |
> | Hacienda Santa Rosa | 14 200 | 10 000 | 142,00 % |
> | **Total** | **30 550** | **24 440** | **125,00 %** |
>
> **Pega la tabla completa.**

### A3. La tabla `escenario`

**Modelado → Nueva tabla**, y pega:

```
escenario = DATATABLE( "nivel" , INTEGER , { { 100 } , { 110 } , { 120 } , { 130 } , { 140 } , { 150 } } )
```

> ### ✅ Punto de control 2
> - En la **vista de tabla**, `escenario` tiene **6 filas** y una columna, `nivel`: 100, 110, 120, 130, 140 y 150.
> - En la **vista de modelo**, `escenario` **no tiene ninguna línea** hacia otra tabla.
>
> **Anota las dos cosas.** Si ves una relación, **bórrala**.

### A4. El segmentador

Segmentador nuevo con `escenario[nivel]`. Marca **130**, y luego **150**.

**A5.** En dos líneas: **¿qué le pasó a la tabla por finca?** ¿Por qué? Usa la palabra **relación**.

---

## Parte B · La medida pregunta (20 min)

### B1. Tres medidas

**Inicio → Nueva medida**, tres veces:

```
Nivel elegido = SELECTEDVALUE( escenario[nivel] , 100 )
```

```
Meta ajustada = [Meta] * [Nivel elegido] / 100
```

```
Cumplimiento ajustado = DIVIDE( [Kilos] , [Meta ajustada] )
```

| Pieza | Qué hace |
|---|---|
| `SELECTEDVALUE( escenario[nivel] , … )` | si en el contexto queda **un solo** nivel, lo devuelve |
| `100` | el **alternativo**: lo que devuelve si quedan **varios o ninguno** |
| `[Meta] * [Nivel elegido] / 100` | la meta de la clase 17, escalada al nivel |

Formato: `[Meta ajustada]` **número entero** con miles; `[Cumplimiento ajustado]` **porcentaje** con dos decimales. **No crees todavía ninguna tarjeta.**

Quita `[Meta]` y `[Cumplimiento]` de la tabla por finca y pon `[Meta ajustada]` y `[Cumplimiento ajustado]`. En el segmentador `escenario`, **solo 130** marcado.

> ### ✅ Punto de control 3
> | Finca | `[Kilos]` | `[Meta ajustada]` | `[Cumplimiento ajustado]` |
> |---|---|---|---|
> | Agricola La Union | 2 100 | 6 500 | 32,31 % |
> | Finca El Guayabo | 14 250 | 12 272 | 116,12 % |
> | Hacienda Santa Rosa | 14 200 | 13 000 | 109,23 % |
> | **Total** | **30 550** | **31 772** | **96,15 %** |
>
> **Pégala.**

### B2. Los seis niveles

Marca **un nivel a la vez**, del 100 al 150, y anota el total de la tabla.

> ### ✅ Punto de control 4
> | Nivel | `[Meta ajustada]` | `[Cumplimiento ajustado]` |
> |---|---|---|
> | 100 | 24 440 | 125,00 % |
> | 110 | 26 884 | 113,64 % |
> | 120 | 29 328 | 104,17 % |
> | 130 | 31 772 | 96,15 % |
> | 140 | 34 216 | 89,29 % |
> | 150 | 36 660 | 83,33 % |
>
> **Llénala con lo que te dio.**

**B3.** En una línea: **¿hasta qué nivel cumple la empresa?** ¿Y La Unión, cumple en alguno?

---

## Parte C · Dos niveles a la vez (25 min) — es la parte que más vale

### C1. Comparar dos

El gerente quiere ver **130 y 150** juntos. En el segmentador: clic en **130**, y **Ctrl+clic** en **150**. Que queden los dos marcados.

> ### ✅ Punto de control 5
> | Finca | `[Kilos]` | `[Meta ajustada]` | `[Cumplimiento ajustado]` |
> |---|---|---|---|
> | Agricola La Union | 2 100 | 5 000 | 42,00 % |
> | Finca El Guayabo | 14 250 | 9 440 | 150,95 % |
> | Hacienda Santa Rosa | 14 200 | 10 000 | 142,00 % |
> | **Total** | **30 550** | **24 440** | **125,00 %** |
>
> **Pégala.**

**C2.** Antes de seguir leyendo, contesta en un comentario: **¿qué mensaje de error o advertencia dio Power BI?**

**C3.** En dos líneas: compara el total con tu punto de control 4. **¿A qué nivel corresponde el 125,00 %?** ¿Está marcado en el segmentador?

### C4. La tarjeta

Objeto visual **Tarjeta** con `[Nivel elegido]`, junto al segmentador. Prueba las tres situaciones:

> ### ✅ Punto de control 6
> | Qué hay marcado en el segmentador | `[Nivel elegido]` | Total de `[Cumplimiento ajustado]` |
> |---|---|---|
> | solo 130 | 130 | 96,15 % |
> | 130 y 150 | **100** | **125,00 %** |
> | nada (borra la selección) | **100** | **125,00 %** |
>
> **Llénala con lo que te dio.**

**C5.** En dos líneas: **¿de dónde sale el 100** con 130 y 150 marcados? Escribe qué devuelve `SELECTEDVALUE` cuando en el contexto hay **más de un** valor.

**C6.** En dos líneas: al probar la medida en la parte B **todo salió bien**. ¿Por qué ninguna de esas pruebas podía atrapar esto? ¿Y por qué el 125,00 % **no se ve raro**?

**C7.** En dos líneas: el gerente sale de la junta diciendo *«con la meta al 150 % la empresa cumple al 125 %»*. ¿Qué número debió leer al 150, y qué objeto visual le habría avisado?

---

## Parte D · Los seis a la vez (20 min)

### D1. La matriz

**Borra la selección** del segmentador `escenario`. Objeto visual **Matriz**: `dim_finca[finca]` en **Filas**, `escenario[nivel]` en **Columnas**, `[Meta ajustada]` en **Valores**.

> ### ✅ Punto de control 7
> | Finca | 100 | 110 | 120 | 130 | 140 | 150 | **Total** |
> |---|---|---|---|---|---|---|---|
> | Agricola La Union | 5 000 | 5 500 | 6 000 | 6 500 | 7 000 | 7 500 | **5 000** |
> | Finca El Guayabo | 9 440 | 10 384 | 11 328 | 12 272 | 13 216 | 14 160 | **9 440** |
> | Hacienda Santa Rosa | 10 000 | 11 000 | 12 000 | 13 000 | 14 000 | 15 000 | **10 000** |
> | **Total** | 24 440 | 26 884 | 29 328 | 31 772 | 34 216 | 36 660 | **24 440** |
>
> **Pégala.** Si la columna Total no aparece, **anótalo**: en **Formato → Subtotales de columna** se prende.

**D2.** **Suma a mano** las seis columnas de La Unión. Escribe la suma y, al lado, lo que dice la columna Total.

**D3.** En dos líneas: ¿por qué las columnas del 100 al 150 **sí** salen bien, y la columna Total no? Contesta con la palabra **contexto**, como en la clase 21.

**D4.** En una línea: la columna Total de La Unión dice lo mismo que la columna del 100. **¿La copió?**

---

## Parte E · Que diga que no sabe (20 min)

### E1. Dos medidas más

```
Meta del escenario =
IF(
    HASONEVALUE( escenario[nivel] ) ,
    [Meta] * SELECTEDVALUE( escenario[nivel] ) / 100
)
```

```
Cumplimiento del escenario = DIVIDE( [Kilos] , [Meta del escenario] )
```

`HASONEVALUE` es la de la clase 20: **verdadero** si en el contexto queda un solo nivel. Si no, el `IF` no tiene rama de «si no», y la medida devuelve **vacío**.

Agrega `[Meta del escenario]` a la matriz, **debajo** de `[Meta ajustada]` en **Valores**.

> ### ✅ Punto de control 8
> | La Unión | Columna 130 | Columna **Total** |
> |---|---|---|
> | `[Meta ajustada]` | 6 500 | **5 000** |
> | `[Meta del escenario]` | 6 500 | *(vacío)* |
>
> Y el renglón **Total** de `[Meta del escenario]`: 24 440 · 26 884 · 29 328 · 31 772 · 34 216 · 36 660 · *(vacío)*.
>
> **Pega la matriz.** Para la captura, **quita `[Meta ajustada]`** y deja solo `[Meta del escenario]`.

### E2. Otra vez 130 y 150

En la tabla por finca, cambia `[Meta ajustada]` y `[Cumplimiento ajustado]` por `[Meta del escenario]` y `[Cumplimiento del escenario]`. Marca **130 y 150** en el segmentador.

> ### ✅ Punto de control 9
> | Qué hay marcado | Total de `[Meta del escenario]` | Total de `[Cumplimiento del escenario]` |
> |---|---|---|
> | solo 130 | 31 772 | 96,15 % |
> | 130 y 150 | *(vacío)* | *(vacío)* |
> | nada | *(vacío)* | *(vacío)* |
>
> **Llénala con lo que te dio.** Si en vez de vacío ves otra cosa, **anótalo tal cual**.

**E3.** En el segmentador: **Formato → Configuración del segmentador → Selección → Selección única**. Intenta marcar dos. **Anota** qué pasa, y si el segmentador te deja **quitar** la única marca. Si el menú se llama distinto en tu versión, **anota cómo se llama**.

**E4.** En dos líneas: con **selección única** prendida, ¿la columna Total de la matriz con `[Meta ajustada]` sigue diciendo 5 000? ¿Por qué la selección única **no alcanza** y la medida con `HASONEVALUE` sí?

---

## Parte F · ¿Hasta dónde se puede subir? (15 min)

### F1. Cuántas fincas cumplen

```
Fincas que cumplen = COUNTROWS( FILTER( dim_finca , [Cumplimiento del escenario] >= 1 ) )
```

`FILTER` recorre `dim_finca` **una finca a la vez**, como el `SUMX` de ayer, y se queda con las que llegan al 100 %.

Quita la **selección única** y **borra la selección** del segmentador. Tabla **nueva** con `escenario[nivel]`, `[Kilos]`, `[Meta del escenario]`, `[Cumplimiento del escenario]` y `[Fincas que cumplen]`.

> ### ✅ Punto de control 10
> | `nivel` | `[Kilos]` | `[Meta del escenario]` | `[Cumplimiento del escenario]` | `[Fincas que cumplen]` |
> |---|---|---|---|---|
> | 100 | 30 550 | 24 440 | 125,00 % | 2 |
> | 110 | 30 550 | 26 884 | 113,64 % | 2 |
> | 120 | 30 550 | 29 328 | 104,17 % | 2 |
> | 130 | 30 550 | 31 772 | **96,15 %** | 2 |
> | 140 | 30 550 | 34 216 | 89,29 % | 2 |
> | 150 | 30 550 | 36 660 | 83,33 % | **1** |
> | **Total** | **30 550** | | | |
>
> **Pégala** y **toma aquí la captura**, con la matriz de la parte E.

**F2.** En una línea: **¿por qué `[Kilos]` dice 30 550 en las seis filas?**

**F3.** En dos líneas: al 150 cumple **una** finca. ¿Cuál, y con qué porcentaje? Agrega `dim_finca[finca]` a una matriz o marca 150 en la tabla por finca para averiguarlo.

**F4.** En dos líneas, y es la pregunta de la gerencia: **¿hasta qué nivel conviene subir la meta?** Da la respuesta para la empresa y para las fincas, y di por qué **no es el mismo número**.

---

## Parte G · Preguntas de cierre (10 min)

1. En una línea: **¿qué filtra** un segmentador de una tabla desconectada?
2. En una línea: **¿qué devuelve `SELECTEDVALUE`** cuando hay dos valores en el contexto? ¿Y cuando no hay ninguno marcado?
3. En una línea: escribe la **regla de detección** del día, tomando como base la de ayer: *«si un total en kilos no es la suma de sus filas, alguna fila le prestó a otra»*.
4. En dos líneas: un tablero tiene un segmentador de **tipo de cambio** (pesos por dólar) y una tabla con ventas en dólares. ¿Qué dos pruebas harías antes de creerle, sin abrir ninguna fórmula?
5. En una línea: el valor alternativo de `SELECTEDVALUE` **no siempre es un error**. Da un caso donde sí tenga sentido.

---

## Si algo falla

| Síntoma | Qué pasó | Qué haces |
|---|---|---|
| `[Meta]` no es 24 440 | quedó **Ver como** prendido, o falta la relación de `h_meta` con `dim_tiempo` | **Modelado → Ver como** → desmarca todo; revisa la vista de modelo |
| El Guayabo no cumple en ningún nivel | quedó **perenne** marcado | quita la marca del segmentador `tipo` |
| `DATATABLE` da error | falta un par de llaves, o una coma | copia la fórmula completa del enunciado |
| No encuentras **Nueva tabla** | estás en otra cinta | **Modelado → Nueva tabla**; o en la vista de tabla, **Herramientas de tabla → Nueva tabla**. Anota dónde estaba |
| El segmentador no cambia nada, aun con las medidas | dejaste `[Meta]` y `[Cumplimiento]` en la tabla | ponle `[Meta ajustada]` y `[Cumplimiento ajustado]` |
| Con 130 y 150 no sale 125,00 % | el segmentador está en **selección única** y no te dejó marcar dos | desactívala: la parte C es **con** dos marcados |
| La matriz no tiene columna Total | la tienes apagada | **Formato → Subtotales de columna** |
| Todo sale **vacío** en la parte E | no hay nada marcado en el segmentador | **no es error**: la medida no sabe qué nivel usar. Marca uno |
| Apareció una relación hacia `escenario` | la hiciste a mano, o arrastraste una columna en la vista de modelo | bórrala |
| Los decimales o los miles salen distintos | configuración regional de tu Windows | **no es un error**, anótalo y sigue |

> ### La regla de los 20 minutos sigue vigente
> Veinte minutos atorado en lo mismo: lo escribes en tu archivo empezando con `DUDA`, o abres un *issue*, y sigues con lo siguiente. **Atorarse no baja la nota. Quedarse callado sí.**

---

## Plan B · Si Power BI Desktop no abre en tu máquina

1. Ponte con un compañero: el tablero se arma en una sola máquina.
2. **Tú escribes todas las fórmulas** en tu propio archivo `.md`, con su resultado, y anotas con quién trabajaste.
3. **La suma a mano de D2 y las respuestas de C5 y C6 las haces tú**, con tus propias palabras.
4. La captura es la misma para los dos, y los dos lo dicen en un comentario.

**Con el Plan B completo se llega a 100 de 100.** Lo que se califica es qué nivel usó tu medida y por qué, no de quién era la laptop.

---

## Rúbrica (100 puntos)

| Criterio | Pts |
|---|---|
| Parte A: la tabla `escenario` sin relaciones, el segmentador que no mueve nada, y A5 | 10 |
| Parte B: las tres medidas, el 96,15 % al 130 y los seis niveles, y B3 | 15 |
| **Parte C: el 125,00 % con 130 y 150 marcados, la tarjeta con el 100, y C2, C3, C5, C6 y C7** | **25** |
| Parte D: la matriz, la columna Total con el 5 000 contra la suma de 37 500, y D3 y D4 | 15 |
| Parte E: `[Meta del escenario]` con el total vacío, la tabla vacía con dos marcados, lo anotado de la selección única, y E4 | 15 |
| Parte F: `[Fincas que cumplen]` con el 2 y el 1, la captura, y F2, F3 y F4 | 10 |
| Parte G: las cinco preguntas con criterio | 10 |

Los criterios suman **100** exactos.

> **Lo que más se califica hoy no es el `HASONEVALUE` de la parte E**, que se copia del enunciado. Es la parte C: que hayas **marcado dos niveles** y visto que la tabla calculó con un tercero, sin un solo aviso, y que sepas explicar de dónde salió ese 100.
