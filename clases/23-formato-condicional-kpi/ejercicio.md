# Ejercicio práctico 23 · Un semáforo que no mienta

**Duración: 2 horas · Individual · Solo Power BI Desktop · Entrega: un archivo `.md` y una captura**

---

## Qué vas a lograr hoy

1. Pintar una tabla con **formato condicional**: un **degradado** y una **regla** con tipo Número.
2. Escribir la regla de «verde si cumple» con tipo **Porcentaje**, y ver que Santa Rosa, con **142,00 %**, sale en **rojo**.
3. Entender contra qué compara **Porcentaje** en una regla, y probarlo con un segmentador.
4. Arreglarlo con una **medida de color** y el estilo **Valor del campo**.
5. Armar una **tarjeta**, un **medidor** y un **KPI**, y ver que el KPI enseña **el último mes**, no el total.
6. Armar el **KPI del año** con `TOTALYTD`.

**El número que prueba que el tablero quedó bien es el KPI del año: 30 550 contra 24 440.** El que prueba que entendiste la clase es que sepas por qué Santa Rosa salió en rojo con **142,00 %**.

---

## Antes de empezar

Novena clase seguida sin motor: hoy tampoco se prende Oracle, ni Docker, ni el driver.

| | |
|---|---|
| Oracle, Docker, OCMT, `GRANT` | **no** |
| Power BI Desktop | **sí**, y es lo único |

### Lo que se baja hoy

**Hoy no se baja nada.** Los CSV son los de la clase 17, que son también los cinco primeros de [`datos/csv_clase19/`](../../datos/csv_clase19/).

Usa el `.pbix` de la clase 22. Las medidas de la semana pasada pueden quedarse: hoy no se usan.

> **Si tu `.pbix` quedó a medias**, carga los cinco CSV de [`datos/csv_clase19/`](../../datos/csv_clase19/) (sin `seguridad.csv`), rehaz las relaciones, marca `dim_tiempo` como tabla de fechas, ordena `nombre_mes` por `mes` y crea `[Kilos]`, `[Meta]` y `[Cumplimiento]` como en la clase 17. Cuesta unos veinte minutos.

### Lo que tiene que estar funcionando antes de empezar

- Las relaciones de `h_meta`: `dim_finca[finca_id]` → `h_meta[finca_id]` y `dim_tiempo[fecha]` → `h_meta[fecha_mes]`
- Las medidas `[Kilos]`, `[Meta]` y `[Cumplimiento]`
- `dim_tiempo` **marcada como tabla de fechas** y `nombre_mes` **ordenada por** `mes` (las dos de la clase 16)
- Segmentadores en `anio` = 2026 y `mes` en 1–4: `[Kilos]` = **30 550**, `[Meta]` = **24 440**, `[Cumplimiento]` = **125,00 %**
- **Ver como apagado**, y **el segmentador `tipo` sin nada marcado.** Solo en la parte C se marca perenne, y se quita en cuanto termina.

---

## Cómo se entrega

En `entregas/apellido-nombre/`, por *pull request*, **dos archivos**:

| Archivo | Qué lleva |
|---|---|
| `Ejercicio23_Apellido_Nombre.md` | **cada regla y cada fórmula**, y debajo **qué color salió en cada fila**, más la cuenta a mano de la parte C y las respuestas de la parte G |
| `clase23-semaforo.png` | captura de **la tabla por finca** pintada con `[Color cumplimiento]`, junto a **la tarjeta** de `[Kilos]` y **el KPI del año** |

Formato de cada respuesta, para que se pueda corregir:

````
### B2 · Regla de 5 000 kilos

| Si el valor | y | Tipo | Color |
|---|---|---|---|
| >= 0 | < 5000 | Número | rojo |
| >= 5000 | <= 100000 | Número | verde |

Mango verde · Maiz verde · Guayaba verde · Cacao rojo
````

> **Una regla sin sus colores anotados abajo no cuenta.** El `.pbix` no se entrega: el repositorio lo ignora a propósito.

---

## Parte A · Las dos tablas (10 min)

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

### A3. La tabla por cultivo

Otra **Tabla** con `dim_cultivo[cultivo]` y `[Kilos]`.

> ### ✅ Punto de control 2
> | Cultivo | `[Kilos]` |
> |---|---|
> | Mango | 12 700 |
> | Maiz | 9 800 |
> | Guayaba | 5 950 |
> | Cacao | 2 100 |
>
> **Pégala.** Banano y Café no salen: no tienen kilos en 2026.

---

## Parte B · Degradado y reglas (20 min)

### B1. Un degradado

En la tabla por cultivo: flechita junto a `Kilos` en el pozo **Columnas** → **Formato condicional** → **Color de fondo**. **Estilo de formato: Degradado**, del blanco (mínimo) al verde (máximo). **Aceptar.**

**B1a.** Anota qué cultivo quedó **más oscuro** y cuál **en blanco**.

**B1b.** A mano: el degradado reparte los colores entre el mínimo (2 100) y el máximo (12 700). **¿En qué porcentaje de la escala cae el Maiz?** Escribe la cuenta.

> ### ✅ Punto de control 3
> Mango el más oscuro, Cacao en blanco. El Maiz en el **72,64 %** de la escala, la Guayaba en el **36,32 %**.

### B2. Una regla de 5 000 kilos

Quita el degradado (flechita → **Quitar formato condicional**). Otra vez **Formato condicional → Color de fondo**, ahora con **Estilo de formato: Reglas**:

| Si el valor | y | Tipo | Color |
|---|---|---|---|
| `>=` 0 | `<` 5000 | **Número** | rojo |
| `>=` 5000 | `<=` 100000 | **Número** | verde |

Para la segunda regla, **+ Nueva regla**.

> ### ✅ Punto de control 4
> Mango, Maiz y Guayaba en **verde**; Cacao en **rojo**.
>
> **Anota los colores** con el formato de «Cómo se entrega».

**B3.** En una línea: el 100000 de la segunda regla es un **techo**. ¿Qué color tendría un cultivo con 150 000 kilos?

---

## Parte C · Verde si cumple (25 min) — es la parte que más vale

### C1. La regla en `[Cumplimiento]`

En la tabla por finca: flechita junto a `Cumplimiento` → **Formato condicional → Color de fondo → Reglas**. Cumplir es llegar al 100 %, y la columna está en porcentaje, así que escoge el tipo **Porcentaje**:

| Si el valor | y | Tipo | Color |
|---|---|---|---|
| `>=` 0 | `<` 100 | **Porcentaje** | rojo |
| `>=` 100 | `<=` 200 | **Porcentaje** | verde |

> ### ✅ Punto de control 5
> | Finca | `[Cumplimiento]` | Color |
> |---|---|---|
> | Agricola La Union | 42,00 % | rojo |
> | Finca El Guayabo | 150,95 % | verde |
> | Hacienda Santa Rosa | 142,00 % | **rojo** |
>
> **Anota los colores que te salieron.**

**C2.** Antes de seguir leyendo, contesta en un comentario: **¿qué mensaje de error o advertencia dio Power BI?**

**C3.** En dos líneas: ¿Santa Rosa **cumplió** la meta? ¿Qué color debería tener, y cuál tiene?

### C4. Porcentaje, ¿de qué?

En una regla, **Porcentaje** es la posición del valor **dentro del rango** entre el mínimo y el máximo de lo que se ve:

```
porcentaje del rango = ( valor − mínimo ) / ( máximo − mínimo )
```

**C4a.** Con el mínimo de la tabla (La Unión, 42,00 %) y el máximo (El Guayabo, 150,95 %), **calcula a mano** el porcentaje del rango de Santa Rosa. Escribe la cuenta.

> ### ✅ Punto de control 6
> | Finca | `[Cumplimiento]` | Porcentaje del rango |
> |---|---|---|
> | Agricola La Union | 42,00 % | 0 % |
> | Hacienda Santa Rosa | 142,00 % | **91,78 %** |
> | Finca El Guayabo | 150,95 % | 100 % |

**C5.** En dos líneas: ¿qué fincas caben en «de 100 a 200 % **del rango**»? Entonces, ¿qué pregunta contestaba de verdad tu regla?

### C6. La prueba con el segmentador

Marca **perenne** en el segmentador `tipo`. Mira la tabla por finca.

> ### ✅ Punto de control 7
> | Finca | `[Cumplimiento]` | Porcentaje del rango | Color |
> |---|---|---|---|
> | Agricola La Union | 42,00 % | 0 % | rojo |
> | Finca El Guayabo | 47,14 % | 5,14 % | rojo |
> | Hacienda Santa Rosa | **142,00 %** | 100 % | **verde** |
>
> **Anota los colores** y **quita la marca de perenne**.

**C7.** En dos líneas: el cumplimiento de Santa Rosa **no cambió**. ¿Por qué cambió su color?

**C8.** Prueba la regla con tipo **Número** y los valores **0 / 100 / 200**. ¿Qué colores salen, y por qué? (Pista: ¿cuánto vale 142,00 % **por dentro**?)

---

## Parte D · El color como medida (20 min)

### D1. La regla con Número, bien escrita

Cambia la regla de `[Cumplimiento]` a:

| Si el valor | y | Tipo | Color |
|---|---|---|---|
| `>=` 0 | `<` 1 | **Número** | rojo |
| `>=` 1 | `<=` 2 | **Número** | verde |

**D1a.** Anota los colores. **¿Qué color tendría una finca al 250 %?**

### D2. La medida de color

**Inicio → Nueva medida**, con `h_cosecha` seleccionada en el panel **Datos**:

```
Color cumplimiento = IF( [Cumplimiento] >= 1 , "#1E8449" , "#C0392B" )
```

| Pieza | Qué hace |
|---|---|
| `[Cumplimiento] >= 1` | la misma condición que «cumplir», con el **1** de verdad |
| `"#1E8449"` | verde, en código hexadecimal (con el `#`) |
| `"#C0392B"` | rojo |

Quita la regla de `[Cumplimiento]`. **Formato condicional → Color de fondo → Estilo de formato: Valor del campo**, en **¿En qué campo debemos basarnos?** escoge `[Color cumplimiento]`, y en **Aplicar a**: **Valores y totales**.

> ### ✅ Punto de control 8
> | Finca | `[Cumplimiento]` | Color |
> |---|---|---|
> | Agricola La Union | 42,00 % | rojo |
> | Finca El Guayabo | 150,95 % | verde |
> | Hacienda Santa Rosa | 142,00 % | **verde** |
> | **Total** | **125,00 %** | **verde** |
>
> **Anota los colores.** Esta tabla va en la captura.

**D3.** Marca **perenne** otra vez. Anota los colores y **quita la marca**. ¿Santa Rosa cambió de color? ¿Por qué ahora no?

**D4.** En dos líneas: la regla con Número y 1 (D1) y la medida (D2) dan los mismos colores hoy. Da **dos razones** para preferir la medida.

---

## Parte E · Tarjeta, medidor y KPI (20 min)

### E1. La tarjeta

Objeto visual **Tarjeta** con `[Kilos]`. Debe decir **30 550**.

### E2. El medidor

Objeto visual **Medidor**: `[Kilos]` en **Valor**, `[Meta]` en **Valor de destino**. Pasa el mouse sobre el extremo derecho del arco y **anota el máximo**.

Luego crea:

```
Tope del medidor = [Meta] * 1.5
```

y ponla en **Valor máximo**.

> ### ✅ Punto de control 9
> | | Valor |
> |---|---|
> | Valor del medidor | 30 550 |
> | Aguja de la meta | 24 440 |
> | Máximo sin `[Tope del medidor]` | **61 100** (el doble del valor) |
> | Máximo con `[Tope del medidor]` | **36 660** |

### E3. El KPI

Objeto visual **KPI**: `[Kilos]` en **Valor**, `dim_tiempo[nombre_mes]` en **Eje de tendencia**, `[Meta]` en **Destino**. Si los pozos se llaman distinto en tu versión, **anota cómo se llaman**.

> ### ✅ Punto de control 10
> | Lo que dibuja el KPI | |
> |---|---|
> | El número grande | **19 750** |
> | El objetivo | **8 300** |
> | La distancia | **+137,95 %** |
> | El color | verde |
>
> **Anota lo que te salió**, y cómo escribe tu versión la distancia.

**E4.** Antes de seguir leyendo, en una línea: la tarjeta dice 30 550 y el KPI 19 750. **¿Qué error dio Power BI?**

### E5. De dónde sale el 19 750

Tabla nueva con `dim_tiempo[nombre_mes]`, `[Kilos]` y `[Meta]`.

> ### ✅ Punto de control 11
> | `nombre_mes` | `[Kilos]` | `[Meta]` |
> |---|---|---|
> | Enero | *(vacío)* | 4 040 |
> | Febrero | *(vacío)* | 5 200 |
> | Marzo | 10 800 | 6 900 |
> | Abril | **19 750** | **8 300** |
> | **Total** | **30 550** | **24 440** |

**E6.** En dos líneas: ¿qué enseña el objeto visual KPI, **el total o qué**? ¿En qué otra clase del curso salió el número 19 750, y por qué es el mismo?

---

## Parte F · El KPI del año (15 min)

### F1. Dos acumulados

`[Kilos YTD]` ya la tienes de la clase 16. Si no, créala. Y crea `[Meta YTD]`:

```
Kilos YTD = TOTALYTD( [Kilos] , dim_tiempo[fecha] )
```

```
Meta YTD = TOTALYTD( [Meta] , dim_tiempo[fecha] )
```

**Copia el KPI** (Ctrl+C, Ctrl+V) y en la copia cambia `[Kilos]` por `[Kilos YTD]` y `[Meta]` por `[Meta YTD]`.

> ### ✅ Punto de control 12
> | | KPI del mes | KPI del año |
> |---|---|---|
> | Número grande | 19 750 | **30 550** |
> | Objetivo | 8 300 | **24 440** |
> | Distancia | +137,95 % | **+25,00 %** |
>
> **Toma aquí la captura**, con la tabla por finca de la parte D y la tarjeta.

**F2.** Agrega `[Kilos YTD]` y `[Meta YTD]` a la tabla por mes de E5. **¿Cómo iba la empresa a fin de marzo?** Escribe los dos números y la distancia (debe salir **−33,09 %**).

**F3.** Haz clic en **Agricola La Union** en la tabla por finca: los KPI se filtran. Anota lo que dice el KPI del año (debe salir **2 100** contra **5 000**, **−58,00 %**). Vuelve a hacer clic para quitar la selección.

**F4.** Ponle **título** a cada KPI (Formato → General → **Título**) que diga **qué periodo** enseña. Escribe los dos títulos.

---

## Parte G · Preguntas de cierre (10 min)

1. En una línea: **¿contra qué compara** una regla con tipo Porcentaje? ¿Y un degradado?
2. En una línea: **¿qué valor enseña** el objeto visual KPI?
3. En una línea: escribe la **regla de detección** del día, tomando como base la de la clase 22: *«si el segmentador dice dos cosas y la tabla una, la tabla escogió por ti»*.
4. En dos líneas: un tablero de ventas pinta en rojo a **los vendedores abajo del promedio**. ¿Eso es una regla relativa o absoluta? ¿Qué pasa con los colores si **todos** venden más que el año pasado?
5. En una línea: el porcentaje del rango **no siempre es un error**. Da un caso donde sí sea lo que quieres.

---

## Si algo falla

| Síntoma | Qué pasó | Qué haces |
|---|---|---|
| `[Meta]` no es 24 440 | quedó **Ver como** prendido, o falta la relación de `h_meta` con `dim_tiempo` | **Modelado → Ver como** → desmarca todo; revisa la vista de modelo |
| No encuentras **Formato condicional** | lo buscas en el lienzo | en el pozo **Columnas**, la flechita junto al campo; o **Formato → Elementos de celda** |
| Todo sale en **rojo** en la parte C | escogiste **Número** con 100 | es la pregunta C8: anótalo. Para C1 usa **Porcentaje** |
| El total de la tabla no se pinta | **Aplicar a** quedó en solo valores | **Valores y totales** |
| En **Valor del campo** no aparece `[Color cumplimiento]` | la medida no está en una tabla del modelo, o tiene un error | revisa que devuelva el texto con el `#` |
| El KPI dice **10 800** | `nombre_mes` no está ordenada por `mes`: el último, en orden alfabético, es **Marzo** | vista de tabla → `nombre_mes` → **Ordenar por columna → `mes`** |
| El KPI no dibuja la línea de fondo | falta el campo en **Eje de tendencia** | arrastra `dim_tiempo[nombre_mes]` |
| `[Kilos YTD]` da lo mismo que `[Kilos]` | `dim_tiempo` no está marcada como tabla de fechas | **Herramientas de tabla → Marcar como tabla de fechas** → `fecha` |
| Los KPI se quedan con La Unión | quedó seleccionada la fila en la tabla por finca | clic otra vez en la fila, o en un espacio vacío de la tabla |
| Los decimales o los miles salen distintos | configuración regional de tu Windows | **no es un error**, anótalo y sigue |

> ### La regla de los 20 minutos sigue vigente
> Veinte minutos atorado en lo mismo: lo escribes en tu archivo empezando con `DUDA`, o abres un *issue*, y sigues con lo siguiente. **Atorarse no baja la nota. Quedarse callado sí.**

---

## Plan B · Si Power BI Desktop no abre en tu máquina

1. Ponte con un compañero: el tablero se arma en una sola máquina.
2. **Tú escribes todas las reglas y las fórmulas** en tu propio archivo `.md`, con sus colores, y anotas con quién trabajaste.
3. **La cuenta a mano de C4a y las respuestas de C5, C7 y E6 las haces tú**, con tus propias palabras.
4. La captura es la misma para los dos, y los dos lo dicen en un comentario.

**Con el Plan B completo se llega a 100 de 100.** Lo que se califica es contra qué comparaba el color y por qué, no de quién era la laptop.

---

## Rúbrica (100 puntos)

| Criterio | Pts |
|---|---|
| Parte A: las dos tablas con sus números | 10 |
| Parte B: el degradado con la cuenta del Maiz, la regla de 5 000 con sus colores, y B3 | 10 |
| **Parte C: Santa Rosa en rojo con la regla de Porcentaje, la cuenta del 91,78 %, la prueba con perenne, y C2, C3, C5, C7 y C8** | **25** |
| Parte D: la regla con Número y 1, `[Color cumplimiento]` con Valor del campo y el total pintado, y D3 y D4 | 15 |
| Parte E: la tarjeta, el medidor con sus dos máximos, el KPI con 19 750, la tabla por mes, y E4 y E6 | 15 |
| Parte F: `[Meta YTD]`, el KPI del año con 30 550 contra 24 440, la captura, y F2, F3 y F4 | 15 |
| Parte G: las cinco preguntas con criterio | 10 |

Los criterios suman **100** exactos.

> **Lo que más se califica hoy no es la medida de color de la parte D**, que se copia del enunciado. Es la parte C: que hayas visto a Santa Rosa en rojo con 142,00 %, sin un solo aviso, y que sepas explicar **contra qué** estaba comparando la regla.
