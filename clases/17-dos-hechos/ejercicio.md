# Ejercicio práctico 17 · Ponle una meta a cada cultivo, y después quítasela
**Duración: 2 horas · Individual · Solo Power BI Desktop · Entrega: un archivo `.md` y una captura**

---

## Qué vas a lograr hoy

1. Conectar una **segunda tabla de hechos** al modelo que ya tienes, con las dimensiones que sí puede compartir y **sin inventar la que no**.
2. Colgar un hecho **mensual** de un calendario **diario**, y entender con qué se paga.
3. Escribir tu primera medida que cruza dos tablas de hechos: `[Cumplimiento]`.
4. Ver la misma medida decir **165,00 %**, **65,00 %** y **125,00 %** según el contexto —eso ya lo sabes desde ayer— y despacharlo en cinco minutos.
5. Provocar el número silencioso del día: una meta de **24 440 kilos por cultivo** que se repite seis veces, cuadra al sumar y **no da ningún error**.
6. Atraparla con una medida de una línea, y después **hacer que la medida se calle** donde no puede contestar.

**El número que prueba que la carga salió bien es 47 000 de meta.** El que prueba que entendiste la clase es una **columna vacía con un total lleno**.

---

## Antes de empezar

Tercera clase seguida sin motor: hoy tampoco se prende Oracle, ni Docker, ni el driver.

| | |
|---|---|
| Oracle, Docker, OCMT, `GRANT` | **no** |
| Power BI Desktop | **sí**, y es lo único |

### Hoy sí puedes reutilizar el `.pbix` de ayer

Al revés que la clase pasada. **Los cuatro CSV de ayer no cambiaron ni un byte**, y las medidas de ayer las vas a necesitar hoy. Lo único que llega es un archivo nuevo:

```
h_meta.csv        36 filas   <- NUEVO
```

Está en [`datos/csv_clase17/`](../../datos/csv_clase17/). **Descárgalo y guárdalo junto a los otros cuatro**, en `C:\agrodb\csv16\`.

> **Si tu `.pbix` de ayer quedó a medias**, o prefieres empezar de cero: en `datos/csv_clase17/` están **los cinco** archivos, los cuatro de ayer incluidos y sin cambios. Guárdalos en `C:\agrodb\csv17\` y rehaz las relaciones y las medidas de la clase 16. Cuesta unos veinte minutos.

### Lo que tiene que estar funcionando antes de empezar

Del `.pbix` de ayer, y si algo de esto falla, arréglalo primero:

- Las cuatro tablas cargadas y las tres relaciones, todas **muchos a uno**
- `dim_tiempo` **marcada como tabla de fechas**
- `nombre_mes` **ordenada por** `mes`
- `[Kilos] = SUM(h_cosecha[kg])` dando **77 550** sin filtros y **30 550** con `anio` = 2026
- `[Cosechas] = COUNTROWS(h_cosecha)` dando **25**

### Qué es `h_meta`

Un **presupuesto**. Alguien se sentó en diciembre de 2025 y fijó, para cada finca y cada mes de 2026, cuántos kilos espera cosechar. Cuatro columnas:

| Columna | Qué es |
|---|---|
| `meta_id` | correlativo, no significa nada |
| `finca_id` | la finca a la que se le fijó la meta |
| `fecha_mes` | **el día 1 del mes** al que corresponde la meta |
| `kg_meta` | los kilos prometidos |

**No tiene cultivo.** No es un olvido del enunciado: la meta se fijó por finca, como se fija en la vida real. Y **no tiene 2025**: una meta se fija hacia adelante.

---

## Cómo se entrega

En `entregas/apellido-nombre/`, por *pull request*, **dos archivos**:

| Archivo | Qué lleva |
|---|---|
| `Ejercicio17_Apellido_Nombre.md` | **cada medida en un bloque de código**, y debajo el valor que te dio, más las respuestas de la parte G |
| `clase17-tablero.png` | captura con **las dos matrices por cultivo juntas**: la de la meta repetida y la de la columna vacía con total |

Formato de cada respuesta, para que se pueda corregir:

````
### B1 · Meta

```
Meta = SUM(h_meta[kg_meta])
```

Resultado sin filtros: 47000
````

> **Una medida sin su resultado anotado abajo no cuenta.** Y el `.pbix` no se entrega: el repositorio lo ignora a propósito.

---

## Parte A · La segunda tabla de hechos (20 min)

### A1. Carga `h_meta.csv`

**Inicio → Obtener datos → Texto/CSV**. Antes de dar **Cargar**, revisa los tipos:

| Columna | Tiene que ser |
|---|---|
| `meta_id` | Número entero |
| `finca_id` | Número entero |
| `fecha_mes` | **Fecha** |
| `kg_meta` | Número entero |

> Si `fecha_mes` se carga como texto, la relación con `dim_tiempo` no se va a poder crear, o se va a crear y no va a filtrar nada. **Es el error más caro de la parte A.**

### A2. Las dos relaciones nuevas

Vista **Modelo**. Las dos, **muchos a uno** hacia la dimensión:

| De | A |
|---|---|
| `h_meta[finca_id]` | `dim_finca[finca_id]` |
| `h_meta[fecha_mes]` | `dim_tiempo[fecha]` |

**A3.** En un comentario, y es la pregunta que ordena el día: `h_cosecha` tiene tres relaciones y `h_meta` solo dos. **¿Cuál es la que falta y por qué no se puede crear?**

### A4. Comprueba que no se rompió nada

> ### ✅ Punto de control 1
> | Medida | Valor |
> |---|---|
> | `[Kilos]` sin filtros | **77 550** |
> | `[Kilos]` con `anio` = 2026 | **30 550** |
> | `[Cosechas]` | **25** |
>
> **Pega los tres.** Agregar una tabla al modelo no puede mover los kilos. Si se movieron, la relación nueva está mal hecha.
>
> Y si en algún visual aparece **una fila en blanco**, `fecha_mes` no está cuadrando con el calendario: revisa el tipo de la columna.

---

## Parte B · La medida que cruza los dos hechos (10 min)

### B1. `Meta` y `Cumplimiento`

```
Meta         = SUM( h_meta[kg_meta] )
Cumplimiento = DIVIDE( [Kilos] , [Meta] )
```

Dale a `[Cumplimiento]` formato de **porcentaje con dos decimales**.

Pon las tres en tarjetas —`[Kilos]`, `[Meta]` y `[Cumplimiento]`— **sin ningún segmentador puesto**.

> ### ✅ Punto de control 2
> | Medida | Valor |
> |---|---|
> | `[Kilos]` | **77 550** |
> | `[Meta]` | **47 000** |
> | `[Cumplimiento]` | **165,00 %** |
>
> **Pégalo.**

**B2.** En una línea: **¿por qué 165 %?** (Lo contestaste ayer con otras palabras.)

### B3. Los tres contextos

Pon un segmentador de `dim_tiempo[anio]` y otro de `dim_tiempo[mes]`, y llena esta tabla a mano:

> ### ✅ Punto de control 3
> | Filtros | `[Kilos]` | `[Meta]` | `[Cumplimiento]` |
> |---|---|---|---|
> | ninguno | 77 550 | 47 000 | **165,00 %** |
> | `anio` = 2026 | 30 550 | 47 000 | **65,00 %** |
> | `anio` = 2026 y `mes` en 1–4 | 30 550 | 24 440 | **125,00 %** |
>
> **Pega las nueve celdas.**

**B4.** En dos líneas: ayer la misma comparación te dio **−35,00 %** y hoy te da **65,00 %**. **¿Es el mismo número?** Explica por qué.

**B5.** En una línea: pon el segmentador de `anio` en **2025**. `[Cumplimiento]` sale vacío. **¿Es un error?**

---

## Parte C · Por finca, que sí funciona (10 min)

Deja los segmentadores en `anio` = 2026 y `mes` en 1, 2, 3 y 4, y **no los muevas hasta la parte E**.

### C1. La tabla por finca

Inserta una **tabla** con `dim_finca[finca]`, `[Kilos]`, `[Meta]` y `[Cumplimiento]`.

> ### ✅ Punto de control 4
> | Finca | `[Kilos]` | `[Meta]` | `[Cumplimiento]` |
> |---|---|---|---|
> | Agricola La Union | 2 100 | 5 000 | **42,00 %** |
> | Finca El Guayabo | 14 250 | 9 440 | **150,95 %** |
> | Hacienda Santa Rosa | 14 200 | 10 000 | **142,00 %** |
> | **Total** | **30 550** | **24 440** | **125,00 %** |
>
> **Pega la tabla completa.**

**C2.** En una línea: suma a mano la columna `[Meta]` de las tres fincas. **¿Cuánto da, y con qué coincide?**

**C3.** En una línea: el total dice **125,00 %**, o sea que la empresa va **arriba** de su meta. Mira la fila de Agricola La Union. **¿Qué esconde ese total?**

---

## Parte D · La trampa del día (30 min) — es la parte que más vale

### D1. Cambia la dimensión, no cambies nada más

Duplica la tabla de la parte C y en la copia **cambia `dim_finca[finca]` por `dim_cultivo[cultivo]`**. No toques las medidas, ni los filtros, ni el formato.

> ### ✅ Punto de control 5
> | Cultivo | `[Kilos]` | `[Meta]` | `[Cumplimiento]` |
> |---|---|---|---|
> | Banano | *(vacío)* | **24 440** | *(vacío)* |
> | Cacao | 2 100 | **24 440** | **8,59 %** |
> | Cafe | *(vacío)* | **24 440** | *(vacío)* |
> | Guayaba | 5 950 | **24 440** | **24,35 %** |
> | Maiz | 9 800 | **24 440** | **40,10 %** |
> | Mango | 12 700 | **24 440** | **51,96 %** |
> | **Total** | **30 550** | **24 440** | **125,00 %** |
>
> **Pega la tabla completa, las siete filas.** Si en tu Power BI `[Cumplimiento]` sale **0,00 %** en vez de vacío para Banano y Café, **anótalo**: es una diferencia de versión y documentarla puntúa.

**D2.** Antes de seguir leyendo, contesta en un comentario: **¿qué mensaje de error dio Power BI?**

**D3.** En un comentario: **Banano y Café no han cosechado un solo kilo en dos años** y hoy aparecen en la tabla con una meta de 24 440 kilos. En la clase 15 no aparecían en ningún visual. **¿Por qué aparecen hoy?**

**D4.** Suma los cuatro porcentajes que no están vacíos: 51,96 + 24,35 + 40,10 + 8,59.

> ### ✅ Punto de control 6
> Da **125,00**, exactamente el total de la tabla.
>
> **Anótalo.** Es la razón por la que este error pasa las revisiones: **la comprobación obvia lo aprueba.**

**D5.** En una línea: ahora suma la columna `[Meta]` de las seis filas. **¿Cuánto da?** ¿Y cuánto se propuso cosechar la empresa en 2026?

### D6. La medida que lo atrapa

```
Filas de meta = COUNTROWS( h_meta )
```

Agrégala a la tabla por cultivo, junto con `[Cosechas]`.

> ### ✅ Punto de control 7
> | Cultivo | `[Cosechas]` | `[Filas de meta]` |
> |---|---|---|
> | Banano | *(vacío)* | **12** |
> | Cacao | **2** | **12** |
> | Cafe | *(vacío)* | **12** |
> | Guayaba | **3** | **12** |
> | Maiz | **1** | **12** |
> | Mango | **3** | **12** |
> | **Total** | **9** | **12** |
>
> **Pega las siete filas.** Nueve cosechas repartidas en cuatro filas; doce metas enteras en las seis.

**D7.** En dos líneas: `[Filas de meta]` vale **12 en todas las filas y 12 en el total**. **¿Qué te dice eso sobre la relación entre `dim_cultivo` y `h_meta`?** Escríbelo como regla, para tu cuaderno.

**D8.** En una línea: alguien propone arreglarlo **prendiendo el filtro cruzado bidireccional** entre `dim_finca` y `h_cosecha`, para que el cultivo alcance a la meta dando la vuelta. **¿Qué estaría afirmando ese modelo sobre la meta?** (No lo hagas. Solo contéstalo.)

---

## Parte E · El otro lado de la granularidad (15 min)

### E1. La meta al nivel de día

Página nueva. Deja el segmentador de `anio` en 2026 y pon uno de `dim_tiempo[mes]` en **3** (marzo). Inserta una **tabla** con `dim_tiempo[fecha]`, `[Kilos]` y `[Meta]`.

> ### ✅ Punto de control 8
> | Día | `[Kilos]` | `[Meta]` |
> |---|---|---|
> | 01/03/2026 | *(vacío)* | **6 900** |
> | 20/03/2026 | **4 200** | *(vacío)* |
> | 22/03/2026 | **5 400** | *(vacío)* |
> | 28/03/2026 | **1 200** | *(vacío)* |
> | **Total** | **10 800** | **6 900** |
>
> **Pega las cinco filas.** Y anota qué dice `[Cumplimiento]` en cada uno de esos días.

**E2.** En dos líneas: la meta de marzo son 6 900 kilos del mes entero, y aparece **el día 1**. **¿Por qué el día 1?** (La respuesta está en una columna del CSV.)

**E3.** En una línea: el total del mes dice **156,52 %** y está bien; el detalle por día no sirve para nada. **¿A qué nivel se puede leer esta medida, y a cuál no?**

---

## Parte F · La medida que se calla (20 min)

### F1. `Meta valida`

```
Meta valida = IF(
    ISFILTERED( dim_cultivo[cultivo] ) || ISFILTERED( dim_tiempo[fecha] ),
    BLANK(),
    [Meta]
)

Cumplimiento valido = DIVIDE( [Kilos] , [Meta valida] )
```

`ISFILTERED` contesta una sola cosa: **¿alguien está filtrando esta columna ahora mismo?** Ponerla en las filas de una tabla cuenta como filtrarla. Un segmentador también.

### F2. Vuelve a la tabla por cultivo

Cambia `[Meta]` por `[Meta valida]` y `[Cumplimiento]` por `[Cumplimiento valido]`. Segmentadores en `anio` = 2026 y `mes` en 1–4.

> ### ✅ Punto de control 9
> | Cultivo | `[Kilos]` | `[Meta valida]` | `[Cumplimiento valido]` |
> |---|---|---|---|
> | Cacao | 2 100 | *(vacío)* | *(vacío)* |
> | Guayaba | 5 950 | *(vacío)* | *(vacío)* |
> | Maiz | 9 800 | *(vacío)* | *(vacío)* |
> | Mango | 12 700 | *(vacío)* | *(vacío)* |
> | **Total** | **30 550** | **24 440** | **125,00 %** |
>
> **Pega las cinco filas.** Banano y Café tienen que haber **desaparecido**: ya no hay ninguna medida que sostenga esas filas.
>
> **Deja esta tabla al lado de la del punto de control 5.** Las dos juntas van en la captura.

**F3.** En dos líneas: las cuatro filas están vacías y el total dice 125,00 %. **¿Por qué el total sí contesta?** (Piensa qué está filtrado en la fila del total.)

### F4. Comprueba que no rompiste lo que funcionaba

Vuelve a la tabla por **finca** y cámbiale también las dos medidas.

> ### ✅ Punto de control 10
> | Finca | `[Kilos]` | `[Meta valida]` | `[Cumplimiento valido]` |
> |---|---|---|---|
> | Agricola La Union | 2 100 | **5 000** | **42,00 %** |
> | Finca El Guayabo | 14 250 | **9 440** | **150,95 %** |
> | Hacienda Santa Rosa | 14 200 | **10 000** | **142,00 %** |
> | **Total** | **30 550** | **24 440** | **125,00 %** |
>
> **Pega la tabla.** Idéntica a la del punto de control 4. **Callar la medida donde no puede contestar no le quita nada donde sí.**

**F5.** En una línea: pon un **segmentador de `dim_cultivo[cultivo]`** en la página y selecciona Mango. `[Meta valida]` se vacía **hasta en el total**. **¿Está bien que se vacíe?**

---

## Parte G · Preguntas de cierre (10 min)

1. En una línea: la meta se capturó por **mes y finca**. Escribe en una frase la regla sobre a qué detalle se puede leer una medida y a cuál no.
2. En dos líneas: en la parte E la medida **se calló sola** al bajar al día, y en la parte D **no se calló** al partir por cultivo, hubo que escribirlo. **¿Cuál es la diferencia entre los dos casos?**
3. En una línea: `[Filas de meta]` valía 12 en todas las filas. **¿Qué otra medida del curso te habría dado la misma pista si la hubieras puesto al lado?**
4. En dos líneas: mañana llega `h_meta` con una columna `cultivo_id` de verdad, capturada por cultivo. **¿Qué le pasa a `[Meta valida]`?** ¿Qué habría que cambiar?
5. En dos líneas: el número malo de la clase 14 fue **19 750**; el de la 15, **5 091,67**; el de la 16, **−35,00 %**; el de hoy, **24 440 repetido seis veces**. Los cuatro eran aritmética correcta y ninguno dio error. **Hoy el aviso apareció. ¿Quién lo puso?**

---

## Si algo falla

| Síntoma | Qué pasó | Qué haces |
|---|---|---|
| No deja crear la relación con `dim_tiempo` | `fecha_mes` se cargó como texto | cambia el tipo a Fecha en Power Query |
| Aparece una fila en blanco en los visuales | alguna `fecha_mes` no está en el calendario | los 730 días tienen que estar completos |
| `[Meta]` da 47 000 en todas las fincas | falta la relación con `dim_finca` | vista Modelo, muchos a uno |
| `[Kilos]` dejó de dar 30 550 | tocaste una relación de ayer | deshaz y revisa las tres viejas |
| `[Cumplimiento]` da 165,00 % | no hay filtro de año | **no es un error**, es el punto de control 2 |
| `[Cumplimiento]` sale vacío en 2025 | no hay meta de 2025 | **no es un error**, anótalo |
| `[Cumplimiento]` da `1,25` en vez de 125,00 % | falta el formato | Herramientas de medidas → **%** |
| Banano y Café no aparecen en la tabla | no tienes `[Meta]` en esa tabla | agrégala: ellos salen por la meta |
| `[Meta valida]` sale vacía también por finca | metiste `dim_finca` en el `IF` | solo `dim_cultivo[cultivo]` y `dim_tiempo[fecha]` |
| `[Meta valida]` no se vacía por cultivo | el `ISFILTERED` apunta a otra columna | tiene que ser la que está en las filas |
| La meta ya no se repite por cultivo | prendiste el bidireccional | apágalo: es el arreglo que borra la evidencia |
| Los decimales llevan punto y no coma | configuración regional de tu Windows | **no es un error**, anótalo y sigue |

> ### La regla de los 20 minutos sigue vigente
> Veinte minutos atorado en lo mismo: lo escribes en tu archivo empezando con `DUDA`, o abres un *issue*, y sigues con lo siguiente. **Atorarse no baja la nota. Quedarse callado sí.**

---

## Plan B · Si Power BI Desktop no abre en tu máquina

1. Ponte con un compañero: el tablero se arma en una sola máquina.
2. **Tú escribes todas las medidas** en tu propio archivo `.md`, con su resultado, y anotas con quién trabajaste.
3. La captura es la misma para los dos, y los dos lo dicen en un comentario.

**Con el Plan B completo se llega a 100 de 100.** Lo que se califica es el DAX que escribiste y el número que atrapaste, no de quién era la laptop.

---

## Rúbrica (100 puntos)

| Criterio | Pts |
|---|---|
| Parte A: `h_meta` cargada con los tipos correctos, las dos relaciones, el 77 550 intacto y A3 contestada | 10 |
| Parte B: `Meta`, `Cumplimiento`, los tres contextos, y B2, B4 y B5 | 10 |
| Parte C: la tabla por finca completa, y C2 y C3 | 10 |
| **Parte D: la meta repetida provocada, los cuatro porcentajes que suman 125, `Filas de meta` y D3, D7 y D8** | **30** |
| Parte E: la meta pegada al día 1, y E2 y E3 | 10 |
| **Parte F: `Meta valida`, la columna vacía con total, la tabla por finca intacta y F3** | **20** |
| Parte G: las cinco preguntas con criterio | 10 |

Los criterios suman **100** exactos.

> **Lo que más se califica hoy no es que hayas conectado una segunda tabla de hechos.** Es que hayas visto una meta de 24 440 kilos repetida en seis cultivos —y aprobando la revisión de que los porcentajes cuadran— y que después la hayas hecho **callar**.
