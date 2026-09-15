# Ejercicio práctico 20 · Un Top 3 que siga siendo de tres cuando el gerente filtra

**Duración: 2 horas · Individual · Solo Power BI Desktop · Entrega: un archivo `.md` y una captura**

---

## Qué vas a lograr hoy

1. Escribir una medida de **ranking** con `RANKX` y entender por qué, escrita a la primera, **pone a todos en primer lugar**.
2. Arreglarla con `ALL` y ver qué dos cosas rompe: **Banano y Café empatados en quinto** sin un kilo, y **un total que dice 1**.
3. Enseñarle a callarse con `HASONEVALUE` e `ISBLANK`.
4. Armar un **Top 3** con el panel Filtros, y verlo quedarse **con dos filas** en cuanto el gerente marca **perenne** en un segmentador.
5. Arreglarlo con **`ALLSELECTED`**, y saber decir cuál de los dos rankings contesta qué pregunta.
6. Hacer un Top 3 **sin fórmula** con **N principales**, y ver lo que un ranking **no** dice.

**El número que prueba que el Top 3 quedó bien es 20 750, con perenne en el segmentador.** El que prueba que entendiste la clase es que sepas por qué la Guayaba decía **3** en una tabla donde no había segundo lugar.

---

## Antes de empezar

Sexta clase seguida sin motor: hoy tampoco se prende Oracle, ni Docker, ni el driver.

| | |
|---|---|
| Oracle, Docker, OCMT, `GRANT` | **no** |
| Power BI Desktop | **sí**, y es lo único |

### Lo que se baja hoy

**Hoy no se baja nada.** Los CSV son los de la clase 17, que son también los cinco primeros de [`datos/csv_clase19/`](../../datos/csv_clase19/). `seguridad.csv` no se usa hoy, pero si ya la tienes cargada no estorba.

Usa el `.pbix` de la clase 19.

> **Si tu `.pbix` quedó a medias**, carga los cinco CSV de [`datos/csv_clase19/`](../../datos/csv_clase19/) (sin `seguridad.csv`), rehaz las relaciones y crea `[Kilos]` y `[Cosechas]`. Cuesta unos quince minutos.

### Lo que tiene que estar funcionando antes de empezar

- La relación `dim_cultivo[cultivo_id]` → `h_cosecha[cultivo_id]`, **muchos a uno**, dirección **Único**
- Las medidas `[Kilos]` y `[Cosechas]`
- Segmentadores en `anio` = 2026 y `mes` en 1–4: `[Kilos]` = **30 550**, `[Cosechas]` = **9**
- **Ver como apagado.** Si ayer lo dejaste prendido con algún correo, hoy te va a cambiar todos los números. **Modelado → Ver como →** desmarca todo.

---

## Cómo se entrega

En `entregas/apellido-nombre/`, por *pull request*, **dos archivos**:

| Archivo | Qué lleva |
|---|---|
| `Ejercicio20_Apellido_Nombre.md` | **cada medida en un bloque de código**, y debajo la tabla que te dio, más las respuestas de la parte G |
| `clase20-top3.png` | captura con **perenne** marcado en el segmentador `tipo`, mostrando **la tabla del Top 3 con tres filas**, las columnas `[Ranking]` y `[Ranking visible]`, y **el total 20 750** |

Formato de cada respuesta, para que se pueda corregir:

````
### B1 · Ranking (primera versión)

```
Ranking = RANKX( dim_cultivo , [Kilos] )
```

Mango 1 · Maiz 1 · Guayaba 1 · Cacao 1 · Total 1
````

> **Una medida sin su resultado anotado abajo no cuenta.** El `.pbix` no se entrega: el repositorio lo ignora a propósito.

---

## Parte A · La tabla de siempre (10 min)

### A1. Los segmentadores

Segmentadores en `anio` = 2026 y `mes` en 1, 2, 3 y 4. **No los muevas hasta la parte F.**

Agrega un tercero: **Visualizaciones → Segmentación de datos** → arrastra `dim_cultivo[tipo]`. **Déjalo sin marcar** hasta la parte D.

### A2. La tabla por cultivo

Objeto visual **Tabla** con `dim_cultivo[cultivo]`, `[Kilos]` y `[Cosechas]`. Ordénala **por `[Kilos]` de mayor a menor**: clic en el encabezado de la columna (o **⋯ Más opciones → Ordenar por → Kilos**, y **Orden descendente**).

> ### ✅ Punto de control 1
> | Cultivo | `[Kilos]` | `[Cosechas]` |
> |---|---|---|
> | Mango | 12 700 | 3 |
> | Maiz | 9 800 | 1 |
> | Guayaba | 5 950 | 3 |
> | Cacao | 2 100 | 2 |
> | **Total** | **30 550** | **9** |
>
> **Pega la tabla completa.**

**A3.** En una línea: `dim_cultivo` tiene **seis** cultivos y la tabla muestra cuatro. **¿Por qué no salen Banano y Café?**

**A4.** En una línea: la tabla ya está ordenada. **¿Para qué quieres una medida de ranking si ya se ve quién va primero?**

---

## Parte B · Todos en primer lugar (10 min)

### B1. La medida obvia

**Inicio → Nueva medida**:

```
Ranking = RANKX( dim_cultivo , [Kilos] )
```

Agrégala a la tabla.

> ### ✅ Punto de control 2
> | Cultivo | `[Kilos]` | `[Ranking]` |
> |---|---|---|
> | Mango | 12 700 | **1** |
> | Maiz | 9 800 | **1** |
> | Guayaba | 5 950 | **1** |
> | Cacao | 2 100 | **1** |
> | **Total** | **30 550** | **1** |
>
> **Pégala.**

**B2.** Antes de seguir leyendo, contesta en un comentario: **¿qué mensaje de error o advertencia dio Power BI?**

**B3.** En dos líneas: en la fila del Mango, **¿cuántas filas tiene `dim_cultivo`** cuando `RANKX` la recorre? ¿Por qué? Usa la palabra **contexto**.

---

## Parte C · Con ALL, y el ranking que se calla (20 min)

### C1. ALL

Edita `[Ranking]` (selecciónala en el panel **Datos** y cambia la fórmula en la barra):

```
Ranking = RANKX( ALL( dim_cultivo ) , [Kilos] )
```

> ### ✅ Punto de control 3
> | Cultivo | `[Kilos]` | `[Ranking]` |
> |---|---|---|
> | Mango | 12 700 | 1 |
> | Maiz | 9 800 | 2 |
> | Guayaba | 5 950 | 3 |
> | Cacao | 2 100 | 4 |
> | **Banano** | *(vacío)* | **5** |
> | **Cafe** | *(vacío)* | **5** |
> | **Total** | **30 550** | **1** |
>
> **Pega las siete filas.**

**C2.** En dos líneas: Banano y Café **no cosecharon nada** y salieron en la tabla, **empatados en quinto**. ¿Por qué aparecen ahora, si en la parte A no estaban? ¿Qué clase anterior te recuerda?

**C3.** En una línea: el total dice **1**. **¿Qué afirma ese 1, leído por alguien que no hizo la medida?**

### C4. El ranking que se calla

Edita otra vez `[Ranking]`:

```
Ranking =
IF(
    HASONEVALUE( dim_cultivo[cultivo] ) && NOT ISBLANK( [Kilos] ),
    RANKX( ALL( dim_cultivo ) , [Kilos] )
)
```

| Pieza | Qué contesta |
|---|---|
| `HASONEVALUE( dim_cultivo[cultivo] )` | ¿esta fila es **un solo** cultivo? En la fila del total hay varios: no |
| `NOT ISBLANK( [Kilos] )` | ¿este cultivo cosechó algo? |
| `IF( condición , resultado )` | sin tercer argumento, si la condición es falsa devuelve **vacío** |

> ### ✅ Punto de control 4
> | Cultivo | `[Kilos]` | `[Ranking]` |
> |---|---|---|
> | Mango | 12 700 | 1 |
> | Maiz | 9 800 | 2 |
> | Guayaba | 5 950 | 3 |
> | Cacao | 2 100 | 4 |
> | **Total** | **30 550** | *(vacío)* |
>
> **Pégala.** Banano y Café se fueron, y el total ya no dice nada.

---

## Parte D · El Top 3 de dos filas (25 min) — es la parte que más vale

### D1. El Top 3

Selecciona la tabla. **Panel Filtros → Filtros en este objeto visual** → arrastra la medida `[Ranking]` a **Agregar campos aquí** → **Mostrar elementos cuando el valor:** *es menor o igual que* → escribe **3** → **Aplicar filtro**.

> Si en tu versión las opciones se llaman distinto, **anota cómo se llaman**: eso puntúa.

> ### ✅ Punto de control 5
> | Cultivo | `[Kilos]` | `[Cosechas]` | `[Ranking]` |
> |---|---|---|---|
> | Mango | 12 700 | 3 | 1 |
> | Maiz | 9 800 | 1 | 2 |
> | Guayaba | 5 950 | 3 | 3 |
> | **Total** | **28 450** | **7** | |
>
> **Pégala.**

**D2.** En una línea: el total dice **28 450**, no 30 550. **¿De qué es ese total?**

### D2b. El gerente marca perenne

En el segmentador `dim_cultivo[tipo]`, marca **perenne**. No toques nada más.

> ### ✅ Punto de control 6
> | Cultivo | `[Kilos]` | `[Cosechas]` | `[Ranking]` |
> |---|---|---|---|
> | Mango | 12 700 | 3 | **1** |
> | Guayaba | 5 950 | 3 | **3** |
> | **Total** | **18 650** | **6** | |
>
> **Pégala.**

**D3.** Antes de seguir, contesta en un comentario: **¿qué mensaje de error o advertencia dio Power BI?**

**D4.** En dos líneas: el Top 3 tiene **dos filas**. **¿Qué cultivo perenne falta**, cuántos kilos tiene, y qué ranking le tocó? Para verlo, quita un momento el filtro de `[Ranking]` y vuelve a ponerlo.

**D5.** En dos líneas, y es la pregunta de la clase: la Guayaba dice **3** y **no hay segundo lugar a la vista**. **¿Quién tiene el segundo lugar, y por qué sigue compitiendo si el segmentador lo escondió?** Explícalo con lo que hace `ALL( dim_cultivo )`.

### D6. Ciclo corto

En el segmentador, cambia a **ciclo corto** (desmarca perenne).

> ### ✅ Punto de control 7
> | Cultivo | `[Kilos]` | `[Ranking]` |
> |---|---|---|
> | Maiz | 9 800 | **2** |
>
> **Pégala.** Un solo cultivo en la tabla, **en segundo lugar**.

**D7.** En una línea: **¿quién va primero?** ¿Está en tu pantalla?

---

## Parte E · ALLSELECTED (20 min)

### E1. Una segunda medida

**No borres `[Ranking]`.** Crea otra:

```
Ranking visible =
IF(
    HASONEVALUE( dim_cultivo[cultivo] ) && NOT ISBLANK( [Kilos] ),
    RANKX( ALLSELECTED( dim_cultivo ) , [Kilos] )
)
```

Agrégala a la tabla. En el panel Filtros, **quita** el filtro de `[Ranking]` (la **×** de la tarjeta del filtro) y pon el mismo filtro con `[Ranking visible]` *es menor o igual que* **3**.

### E2. Los tres segmentadores

Revisa la tabla con cada opción del segmentador `tipo`:

> ### ✅ Punto de control 8
> | Segmentador `tipo` | Filas del Top 3 | `[Ranking]` | `[Ranking visible]` | `[Kilos]` total |
> |---|---|---|---|---|
> | *(ninguno)* | Mango, Maiz, Guayaba | 1, 2, 3 | 1, 2, 3 | **28 450** |
> | perenne | Mango, Guayaba, **Cacao** | 1, **3**, **4** | 1, **2**, **3** | **20 750** |
> | ciclo corto | Maiz | **2** | **1** | 9 800 |
>
> **Pega las tres.** Deja marcado **perenne** y **toma aquí la captura**.

**E3.** En dos líneas: sin segmentador, `[Ranking]` y `[Ranking visible]` **dan lo mismo**. ¿Por qué eso hace que el error de la parte D sea tan fácil de publicar?

**E4.** En dos líneas: `[Ranking]` y `[Ranking visible]` contestan preguntas distintas. **Escribe cada pregunta en español**, y di cuál de las dos es la de un «Top 3».

**E5.** En una línea: alguien escribe `ALL( dim_cultivo[cultivo] )` en vez de `ALL( dim_cultivo )`, marca perenne y **no le sale el error**. Pruébalo en `[Ranking]` y anota qué da la Guayaba. **¿Por qué?** Después, regresa `[Ranking]` a `ALL( dim_cultivo )`.

---

## Parte F · Sin fórmula, y lo que un ranking no dice (15 min)

### F1. N principales

Copia la tabla (**Ctrl+C, Ctrl+V**) y en la copia **quita** el filtro de `[Ranking visible]`. En **Filtros en este objeto visual**, abre la tarjeta de `cultivo` → **Tipo de filtro: N principales** → **Mostrar elementos: Superior, 3** → arrastra `[Kilos]` a **Por valor** → **Aplicar filtro**.

> ### ✅ Punto de control 9
> | Segmentador `tipo` | Filas | `[Kilos]` total |
> |---|---|---|
> | *(ninguno)* | Mango, Maiz, Guayaba | **28 450** |
> | perenne | Mango, Guayaba, Cacao | **20 750** |
>
> **Pégalo.** Si con perenne te da otras filas, **anótalo y sigue**: eso puntúa.

**F2.** En una línea: **¿a cuál de tus dos medidas se parece N principales**, y en qué lo notas?

### F3. El ranking por finca

**Quita la marca del segmentador `tipo`** (que no quede nada marcado). Crea:

```
Ranking finca =
IF(
    HASONEVALUE( dim_finca[finca] ) && NOT ISBLANK( [Kilos] ),
    RANKX( ALLSELECTED( dim_finca ) , [Kilos] )
)
```

Tabla nueva con `dim_finca[finca]`, `[Kilos]` y `[Ranking finca]`.

> ### ✅ Punto de control 10
> | Finca | `[Kilos]` 2026 | `[Ranking finca]` 2026 | `[Kilos]` 2025 | `[Ranking finca]` 2025 |
> |---|---|---|---|---|
> | Finca El Guayabo | 14 250 | **1** | 9 200 | 2 |
> | Hacienda Santa Rosa | 14 200 | **2** | 12 300 | 1 |
> | Agricola La Union | 2 100 | 3 | 2 000 | 3 |
>
> Las columnas de 2025 salen de cambiar el segmentador `anio` a **2025**, con `mes` todavía en 1–4. **Pega las dos**, y **regresa `anio` a 2026**.

**F4.** En dos líneas: en 2026, entre el primero y el segundo hay **50 kilos**; entre el segundo y el tercero, **12 100**. **¿Qué dice el ranking de esa diferencia?** ¿Qué columna tiene que ir siempre al lado de un ranking?

---

## Parte G · Preguntas de cierre (10 min)

1. En una línea: `RANKX( tabla , expresión )`. **¿Qué decide la tabla?** Contesta con la palabra *compite*.
2. En dos líneas: el `ALL` de la parte C **arregló** los cuatro primeros lugares y el de la parte D **rompió** el Top 3. **¿Es el mismo `ALL`?** ¿Qué hizo distinto en cada caso?
3. En una línea: escribe la **regla de detección** del día, tomando como base la de ayer: *«un rol dinámico se prueba siempre con tres correos»*.
4. En dos líneas: un tablero muestra **«Top 3 cultivos»** y abajo **«Total: 28 450»**. ¿Qué entendería el gerente, y qué tendría que decir la tarjeta para no engañarlo?
5. En una línea: **¿cuándo quieres `ALL` a propósito** en un ranking? Da un ejemplo de pregunta de negocio.

---

## Si algo falla

| Síntoma | Qué pasó | Qué haces |
|---|---|---|
| Todos en primer lugar después de la parte C | la medida sigue sin `ALL` | revisa que editaste `[Ranking]` y no creaste otra |
| Números distintos a todos los puntos de control | quedó **Ver como** prendido de ayer | **Modelado → Ver como** → desmarca todo |
| En la parte C salen seis filas de Banano, Café… con kilos | pusiste `h_cosecha[cultivo_id]` en las filas en vez de `dim_cultivo[cultivo]` | usa la columna de la dimensión |
| El panel Filtros no ofrece *es menor o igual que* | arrastraste una **columna**, no la medida | arrastra `[Ranking]` |
| Con perenne, la Guayaba dice **2** en la parte D | escribiste `ALL( dim_cultivo[cultivo] )` | es `ALL( dim_cultivo )`: la tabla entera. Ver E5 |
| `HASONEVALUE` o `ISBLANK` dan error de sintaxis | falta un paréntesis, o usaste `;` | copia la medida completa del enunciado; si tu Power BI usa `;` como separador, **anótalo** |
| El Top 3 sale con **cuatro** filas en la parte E | el filtro sigue siendo de `[Ranking]` | quita ese filtro; el nuevo es de `[Ranking visible]` |
| `[Ranking finca]` pone a Santa Rosa primero en 2026 | quedó **perenne** marcado | quita la marca del segmentador `tipo` |
| El total de la tabla del Top 3 no es 30 550 | es el filtro del objeto visual | **no es un error**: es el total del Top 3 (parte D2) |
| Los decimales o los miles salen distintos | configuración regional de tu Windows | **no es un error**, anótalo y sigue |

> ### La regla de los 20 minutos sigue vigente
> Veinte minutos atorado en lo mismo: lo escribes en tu archivo empezando con `DUDA`, o abres un *issue*, y sigues con lo siguiente. **Atorarse no baja la nota. Quedarse callado sí.**

---

## Plan B · Si Power BI Desktop no abre en tu máquina

1. Ponte con un compañero: el tablero se arma en una sola máquina.
2. **Tú escribes todas las medidas** en tu propio archivo `.md`, con su resultado, y anotas con quién trabajaste.
3. La captura es la misma para los dos, y los dos lo dicen en un comentario.

**Con el Plan B completo se llega a 100 de 100.** Lo que se califica es contra quién compite tu ranking y por qué, no de quién era la laptop.

---

## Rúbrica (100 puntos)

| Criterio | Pts |
|---|---|
| Parte A: los tres segmentadores, la tabla ordenada con el 30 550, y A3 y A4 | 10 |
| Parte B: la medida sin `ALL`, los cuatro primeros lugares, y B2 y B3 | 10 |
| Parte C: `ALL` con Banano y Café en quinto, la medida que se calla con el total vacío, y C2 y C3 | 15 |
| **Parte D: el Top 3 con 28 450, las dos filas con perenne, el Maíz en segundo con ciclo corto, y D4, D5 y D7** | **25** |
| **Parte E: `[Ranking visible]`, la tabla de los tres segmentadores con el 20 750, la captura, y E3, E4 y E5** | **20** |
| Parte F: N principales, el ranking por finca en 2026 y 2025, y F2 y F4 | 10 |
| Parte G: las cinco preguntas con criterio | 10 |

Los criterios suman **100** exactos.

> **Lo que más se califica hoy no es la fórmula de la parte E**, que se copia del enunciado. Es la parte D: que hayas visto un Top 3 **quedarse con dos filas** sin un solo aviso, y que sepas explicar quién tenía el segundo lugar y por qué seguía compitiendo.
