# Ejercicio práctico 21 · Un bono cuyo total sea la suma de lo que se paga

**Duración: 2 horas · Individual · Solo Power BI Desktop · Entrega: un archivo `.md` y una captura**

---

## Qué vas a lograr hoy

1. Escribir dos medidas de una línea, `[Excedente]` y `[Faltante]`, y ver que **el total no es la suma de sus filas**: **6 110** donde la columna suma 9 010, y **0** donde suma 2 900.
2. Explicar **qué calcula la fila del total**, y por qué el faltante de La Unión **se compensó** con el bono de las otras fincas.
3. Ver por qué la prueba con **el año completo no lo atrapa**.
4. Arreglarlo con **`SUMX`**, y ver que el arreglo **vuelve a fallar** en cuanto la tabla va por mes.
5. Escribir un **`SUMX` dentro de otro** para aplicar la regla por finca y por mes.
6. Distinguir el total que **tiene** que sumar del que **no** debe, y saber decir de quién es la decisión.

**El número que prueba que el bono quedó bien es 18 450, por finca y por mes.** El que prueba que entendiste la clase es que sepas por qué el total de `[Faltante]` decía **0** con La Unión al 42 % de su meta.

---

## Antes de empezar

Séptima clase seguida sin motor: hoy tampoco se prende Oracle, ni Docker, ni el driver.

| | |
|---|---|
| Oracle, Docker, OCMT, `GRANT` | **no** |
| Power BI Desktop | **sí**, y es lo único |

### Lo que se baja hoy

**Hoy no se baja nada.** Los CSV son los de la clase 17, que son también los cinco primeros de [`datos/csv_clase19/`](../../datos/csv_clase19/).

Usa el `.pbix` de la clase 20.

> **Si tu `.pbix` quedó a medias**, carga los cinco CSV de [`datos/csv_clase19/`](../../datos/csv_clase19/) (sin `seguridad.csv`), rehaz las relaciones y crea `[Kilos]`, `[Meta]` y `[Cumplimiento]` como en la clase 17. Cuesta unos veinte minutos.

### Lo que tiene que estar funcionando antes de empezar

- Las relaciones de `h_meta`: `dim_finca[finca_id]` → `h_meta[finca_id]` y `dim_tiempo[fecha]` → `h_meta[fecha_mes]`
- Las medidas `[Kilos]`, `[Meta]` y `[Cumplimiento]`
- Segmentadores en `anio` = 2026 y `mes` en 1–4: `[Kilos]` = **30 550**, `[Meta]` = **24 440**, `[Cumplimiento]` = **125,00 %**
- **Ver como apagado**, y **el segmentador `tipo` de ayer sin nada marcado.** Si quedó **perenne**, El Guayabo pierde el maíz y hoy te cambian todos los números.

---

## Cómo se entrega

En `entregas/apellido-nombre/`, por *pull request*, **dos archivos**:

| Archivo | Qué lleva |
|---|---|
| `Ejercicio21_Apellido_Nombre.md` | **cada medida en un bloque de código**, y debajo la tabla que te dio, más las sumas a mano de la parte B y las respuestas de la parte G |
| `clase21-bono.png` | captura de **la tabla por mes** con `[Excedente por finca]` y `[Excedente mensual]` lado a lado, y los totales **9 010** y **18 450** |

Formato de cada respuesta, para que se pueda corregir:

````
### B1 · Excedente

```
Excedente = MAX( 0 , [Kilos] - [Meta] )
```

La Union 0 · El Guayabo 4 810 · Santa Rosa 4 200 · Total 6 110
````

> **Una medida sin su resultado anotado abajo no cuenta.** El `.pbix` no se entrega: el repositorio lo ignora a propósito.

---

## Parte A · La tabla de la meta (10 min)

### A1. Los segmentadores

Segmentadores en `anio` = 2026 y `mes` en 1, 2, 3 y 4. **No los muevas hasta la parte C.** El de `tipo`, **sin nada marcado**.

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

**A3.** En una línea: suma a mano la columna `[Kilos]` y la columna `[Cumplimiento]`. **¿Cuál de los dos totales es la suma de su columna?** ¿Te extraña el otro?

---

## Parte B · El bono y el apoyo (20 min) — es la parte que más vale

La gerencia decide: **cada kilo arriba de la meta paga bono**, y **cada kilo abajo entra al plan de apoyo**.

### B1. Dos medidas

**Inicio → Nueva medida**, dos veces:

```
Excedente = MAX( 0 , [Kilos] - [Meta] )
```

```
Faltante = MAX( 0 , [Meta] - [Kilos] )
```

`MAX` con **dos** argumentos compara dos números y se queda con el mayor: si la resta es negativa, **0**. Agrega las dos a la tabla por finca.

> ### ✅ Punto de control 2
> | Finca | `[Kilos]` | `[Meta]` | `[Excedente]` | `[Faltante]` |
> |---|---|---|---|---|
> | Agricola La Union | 2 100 | 5 000 | 0 | **2 900** |
> | Finca El Guayabo | 14 250 | 9 440 | **4 810** | 0 |
> | Hacienda Santa Rosa | 14 200 | 10 000 | **4 200** | 0 |
> | **Total** | **30 550** | **24 440** | **6 110** | **0** |
>
> **Pégala.**

**B2.** Antes de seguir leyendo, contesta en un comentario: **¿qué mensaje de error o advertencia dio Power BI?**

**B3.** **Suma a mano** la columna `[Excedente]` y la columna `[Faltante]`, sin contar la fila del total. Escribe las dos sumas y, al lado, lo que dice el total.

**B4.** En dos líneas: finanzas arma una tarjeta con el total de `[Faltante]`. **¿Qué decisión toma con ese número**, y qué le pasa a La Unión?

---

## Parte C · Qué calculó el total (15 min)

### C1. La cuenta del total

**C1.** En dos líneas: la fila del total **no** suma las filas de arriba. Escribe la cuenta que sí hace, con los números de la tabla: `MAX( 0 , ___ − ___ )`. Usa la palabra **contexto**.

**C2.** En una línea: tu suma de B3 da 9 010 y el total dice 6 110. **¿Qué número falta para pasar de uno al otro, y de qué finca es?**

### C3. El año completo

En el segmentador `mes`, **quita la selección** (que queden los doce meses de 2026).

> ### ✅ Punto de control 3
> | Finca | `[Kilos]` | `[Meta]` | `[Excedente]` | `[Faltante]` |
> |---|---|---|---|---|
> | Agricola La Union | 2 100 | 8 000 | 0 | 5 900 |
> | Finca El Guayabo | 14 250 | 19 000 | 0 | 4 750 |
> | Hacienda Santa Rosa | 14 200 | 20 000 | 0 | 5 800 |
> | **Total** | **30 550** | **47 000** | **0** | **16 450** |
>
> **Pégala**, y **regresa `mes` a 1–4**.

**C4.** En dos líneas: con el año completo **el total sí suma**. ¿Por qué? ¿Qué tienen en común las tres fincas que en la tabla de 1–4 no tenían?

---

## Parte D · SUMX (15 min)

### D1. Recorrer las fincas

Crea las dos:

```
Excedente por finca = SUMX( dim_finca , [Excedente] )
```

```
Faltante por finca = SUMX( dim_finca , [Faltante] )
```

| Pieza | Qué hace |
|---|---|
| `dim_finca` | la tabla que se recorre, **una finca a la vez** |
| `[Excedente]` | se calcula **con el filtro de esa finca**, y el `MAX` se aplica ahí |
| `SUMX` | suma los resultados |

Agrégalas a la tabla por finca.

> ### ✅ Punto de control 4
> | Finca | `[Excedente]` | `[Excedente por finca]` | `[Faltante]` | `[Faltante por finca]` |
> |---|---|---|---|---|
> | Agricola La Union | 0 | 0 | 2 900 | 2 900 |
> | Finca El Guayabo | 4 810 | 4 810 | 0 | 0 |
> | Hacienda Santa Rosa | 4 200 | 4 200 | 0 | 0 |
> | **Total** | **6 110** | **9 010** | **0** | **2 900** |
>
> **Pégala.**

**D2.** En una línea: en la fila de El Guayabo, **¿cuántas fincas recorre `SUMX`?** ¿Por qué las filas no cambiaron?

**D3.** En una línea: ¿en qué se parece la `tabla` de `SUMX` a la `tabla` de `RANKX` de ayer?

---

## Parte E · El bono por mes (25 min)

### E1. La misma medida, por mes

Tabla **nueva** con `dim_tiempo[anio_mes]`, `[Kilos]`, `[Meta]` y `[Excedente por finca]`.

> ### ✅ Punto de control 5
> | `anio_mes` | `[Kilos]` | `[Meta]` | `[Excedente por finca]` |
> |---|---|---|---|
> | 2026-01 | | 4 040 | 0 |
> | 2026-02 | | 5 200 | 0 |
> | 2026-03 | 10 800 | 6 900 | **6 600** |
> | 2026-04 | 19 750 | 8 300 | **11 850** |
> | **Total** | **30 550** | **24 440** | **9 010** |
>
> **Pégala.** Si enero y febrero no salen, **anótalo y sigue**.

**E2.** En dos líneas: **suma a mano** la columna. ¿Cuánto da, y cuánto dice el total? ¿Qué recorre `SUMX( dim_finca , … )` **en la fila del total**, y qué no recorre?

### E3. Recorrer fincas y meses

```
Excedente mensual =
SUMX(
    dim_finca ,
    SUMX( VALUES( dim_tiempo[anio_mes] ) , [Excedente] )
)
```

```
Faltante mensual =
SUMX(
    dim_finca ,
    SUMX( VALUES( dim_tiempo[anio_mes] ) , [Faltante] )
)
```

`VALUES( dim_tiempo[anio_mes] )` son los meses **que deja el segmentador**: los cuatro. Agrega las dos a la tabla por mes **y** a la tabla por finca.

> ### ✅ Punto de control 6
> | `anio_mes` | `[Excedente por finca]` | `[Excedente mensual]` | `[Faltante mensual]` |
> |---|---|---|---|
> | 2026-01 | 0 | 0 | 4 040 |
> | 2026-02 | 0 | 0 | 5 200 |
> | 2026-03 | 6 600 | 6 600 | 2 700 |
> | 2026-04 | 11 850 | 11 850 | 400 |
> | **Total** | **9 010** | **18 450** | **12 340** |
>
> **Pégala** y **toma aquí la captura**.

> ### ✅ Punto de control 7
> | Finca | `[Excedente por finca]` | `[Excedente mensual]` | `[Faltante mensual]` |
> |---|---|---|---|
> | Agricola La Union | 0 | 0 | 2 900 |
> | Finca El Guayabo | 4 810 | **10 750** | **5 940** |
> | Hacienda Santa Rosa | 4 200 | **7 700** | **3 500** |
> | **Total** | **9 010** | **18 450** | **12 340** |
>
> **Pégala.** Ahora el total suma **en las dos tablas**.

**E4.** En dos líneas: Santa Rosa tiene **4 200** de bono por temporada y **7 700** por mes. Escribe su `[Kilos] - [Meta]` de enero, febrero, marzo y abril, y explica **de dónde salen los 3 500** de diferencia.

**E5.** En dos líneas, y es la pregunta de la clase: **¿el bono es 9 010 o 18 450?** ¿Quién tiene que contestar eso, y qué tendría que decir el título de la tabla?

---

## Parte F · Lo que sí debe sumar, y lo que no (20 min)

### F1. El neto

```
Neto = [Kilos] - [Meta]
```

Agrégala a la tabla por finca.

> ### ✅ Punto de control 8
> | Finca | `[Neto]` |
> |---|---|
> | Agricola La Union | −2 900 |
> | Finca El Guayabo | 4 810 |
> | Hacienda Santa Rosa | 4 200 |
> | **Total** | **6 110** |
>
> **Pégala.** Este total **sí** es la suma de la columna.

**F2.** En una línea: **¿por qué `[Neto]` suma y `[Excedente]` no**, si las dos restan lo mismo?

### F3. Las tres versiones

Con los totales que ya tienes, llena:

> ### ✅ Punto de control 9
> | Versión | Excedente | Faltante | Excedente − Faltante |
> |---|---|---|---|
> | sin `SUMX` | 6 110 | 0 | |
> | `SUMX` por finca | 9 010 | 2 900 | |
> | `SUMX` por finca y mes | 18 450 | 12 340 | |
>
> **Llena la última columna.**

**F4.** En dos líneas: la última columna da **lo mismo** en las tres filas. **¿Qué número es**, y qué es lo único que cambia de una versión a otra?

**F5.** En una línea: el total de `[Cumplimiento]` dice 125,00 % y sus filas suman 334,95 %. **¿Está mal?** ¿Por qué nadie lo reclama?

---

## Parte G · Preguntas de cierre (15 min)

1. En una línea: **¿qué calcula la fila del total** de una medida? Contesta con la palabra *contexto*.
2. En dos líneas: el `SUMX` de la parte D **arregló** el total por finca y en la parte E **no alcanzó** por mes. ¿Estaba mal escrito? ¿Qué le faltaba?
3. En una línea: escribe la **regla de detección** del día, tomando como base la de ayer: *«si falta un número en el ranking, alguien que no ves se lo quedó»*.
4. En dos líneas: un tablero dice **«Faltante total: 0»**. ¿Qué prueba harías antes de creerle, sin abrir ninguna fórmula?
5. En una línea: da un ejemplo de medida cuyo total **no debe** ser la suma de sus filas, además de `[Cumplimiento]`.

---

## Si algo falla

| Síntoma | Qué pasó | Qué haces |
|---|---|---|
| `[Meta]` no es 24 440 | quedó **Ver como** prendido, o falta la relación de `h_meta` con `dim_tiempo` | **Modelado → Ver como** → desmarca todo; revisa la vista de modelo |
| El Guayabo sale con 0 de bono y 4 990 de faltante | quedó **perenne** marcado de ayer | quita la marca del segmentador `tipo` |
| `MAX` da error de sintaxis | escribiste `MAX( [Kilos] - [Meta] )`, con un argumento | son dos: `MAX( 0 , [Kilos] - [Meta] )` |
| En la parte C el total ya suma y no ves el error | quitaste `mes` antes de tiempo | regresa `mes` a 1–4: el error solo sale con fincas de los dos lados |
| `[Excedente por finca]` no da 9 010 en el total | escribiste `SUMX( h_cosecha , … )` o `SUMX( dim_tiempo , … )` | la tabla es `dim_finca` |
| `VALUES` da error | pusiste `VALUES( dim_tiempo )` o una columna que no existe | `VALUES( dim_tiempo[anio_mes] )` |
| Los meses salen desordenados | usaste `nombre_mes` en la tabla | usa `anio_mes` |
| Enero y febrero salen con **0** | `MAX( 0 , … )` devuelve cero, no vacío | **no es un error**: no hubo cosecha ni bono |
| `SUMX` con dos `SUMX` no entra | falta un paréntesis, o usaste `;` | copia la medida completa del enunciado; si tu Power BI usa `;` como separador, **anótalo** |
| Los decimales o los miles salen distintos | configuración regional de tu Windows | **no es un error**, anótalo y sigue |

> ### La regla de los 20 minutos sigue vigente
> Veinte minutos atorado en lo mismo: lo escribes en tu archivo empezando con `DUDA`, o abres un *issue*, y sigues con lo siguiente. **Atorarse no baja la nota. Quedarse callado sí.**

---

## Plan B · Si Power BI Desktop no abre en tu máquina

1. Ponte con un compañero: el tablero se arma en una sola máquina.
2. **Tú escribes todas las medidas** en tu propio archivo `.md`, con su resultado, y anotas con quién trabajaste.
3. **Las sumas a mano de B3, E2 y F3 las haces tú**, con tus propios números.
4. La captura es la misma para los dos, y los dos lo dicen en un comentario.

**Con el Plan B completo se llega a 100 de 100.** Lo que se califica es qué recorre tu total y por qué, no de quién era la laptop.

---

## Rúbrica (100 puntos)

| Criterio | Pts |
|---|---|
| Parte A: los segmentadores, la tabla con el 24 440 y el 125,00 %, y A3 | 10 |
| **Parte B: `[Excedente]` y `[Faltante]` con el 6 110 y el 0, las sumas a mano 9 010 y 2 900, y B2 y B4** | **25** |
| Parte C: la cuenta del total, el año completo con el 16 450, y C2 y C4 | 10 |
| Parte D: las dos medidas con `SUMX`, los totales 9 010 y 2 900, y D2 y D3 | 15 |
| Parte E: la tabla por mes con el 9 010, `[Excedente mensual]` y `[Faltante mensual]` con el 18 450 y el 12 340, la captura, y E2, E4 y E5 | 20 |
| Parte F: `[Neto]`, las tres versiones con su 6 110, y F2, F4 y F5 | 10 |
| Parte G: las cinco preguntas con criterio | 10 |

Los criterios suman **100** exactos.

> **Lo que más se califica hoy no es el `SUMX` de la parte E**, que se copia del enunciado. Es la parte B: que hayas **sumado la columna a mano** y visto que el total no cuadra, sin un solo aviso, y que sepas explicar a dónde se fueron los 2 900 kilos de La Unión.
