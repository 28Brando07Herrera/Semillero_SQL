# Clase 21 · El total que se comió el faltante
**Miércoles 16 de septiembre**

**50 minutos de clase** y el resto de práctica. Séptima clase seguida del lado de Power BI: **hoy tampoco se prende Oracle.**

## Material

| Qué | Dónde |
|---|---|
| Diapositivas | [slides.md](slides.md) · [versión web](https://negatix092.github.io/Semillero_SQL/21-totales-sumx.html) |
| Ejercicio práctico | [ejercicio.md](ejercicio.md) |
| Datos del día | **ninguno nuevo**: los cinco CSV de la clase 17, los mismos de [`datos/csv_clase19/`](../../datos/csv_clase19/) |

> **Hoy no se baja nada.** Se trabaja sobre el `.pbix` de la clase 20, **con Ver como apagado** y **el segmentador `tipo` sin nada marcado**.

## Qué hace falta tener listo

| | |
|---|---|
| Power BI Desktop | y nada más |
| Oracle, Docker, el OCMT | **no**, hoy tampoco |
| El `.pbix` de la clase 20 | con `[Kilos]`, `[Meta]`, `[Cumplimiento]` y las relaciones de `h_meta` con `dim_finca` y `dim_tiempo` |

## De qué se trata

La gerencia decide dos cosas para la temporada: **un bono** por cada kilo que una finca coseche arriba de su meta, y **un plan de apoyo** para cada kilo que le falte. Son dos medidas de una línea:

```
Excedente = MAX( 0 , [Kilos] - [Meta] )
Faltante  = MAX( 0 , [Meta] - [Kilos] )
```

Por finca las dos salen bien: El Guayabo **4 810** kilos de bono, Santa Rosa **4 200**, y La Unión **2 900** de faltante. Pero la fila del total dice **6 110** de bono y **0** de faltante. Sumando la columna a mano son **9 010** y **2 900**. El tablero le dice a finanzas que **ninguna finca necesita apoyo**.

## El giro de hoy

**La fila del total no suma las filas.** Vuelve a calcular la medida con el filtro de toda la empresa: `MAX( 0 , 30 550 − 24 440 )`. Y en esa resta el faltante de La Unión **se compensa** con el bono de las otras dos: 9 010 − 2 900 = **6 110**. Con el año completo las tres fincas quedan abajo de la meta, el total **sí suma** (16 450), y por eso el error no aparece en la prueba de siempre.

El arreglo es decirle al total **por dónde recorrer**:

```
Excedente por finca = SUMX( dim_finca , [Excedente] )
```

`SUMX` calcula `[Excedente]` **una finca a la vez** y suma los resultados: el total pasa a **9 010**, y el faltante a **2 900**.

Y en cuanto el gerente pide la misma tabla **por mes**, vuelve a pasar: marzo **6 600**, abril **11 850**, y el total dice **9 010**. `SUMX` arregló el total **para las fincas**, no para los meses. Si el bono se paga **por finca y por mes**, la medida tiene que recorrer las dos cosas:

```
Excedente mensual =
SUMX(
    dim_finca ,
    SUMX( VALUES( dim_tiempo[anio_mes] ) , [Excedente] )
)
```

y el bono es **18 450**.

> 6 110, 9 010 y 18 450 salen de la **misma** fórmula de una línea, recorrida de tres maneras. Ninguna está mal escrita: la que está bien depende de **la regla del bono**, y esa regla no está en los datos.

## Lo que hay que saber al terminar

- Que la **fila del total** de una medida **no suma las filas**: vuelve a hacer la cuenta en el contexto del total
- Que en `[Kilos]` da lo mismo, y en `[Cumplimiento]` nadie espera que sume, y que **el peligro está en lo que parece suma y no lo es**
- Por qué un `MAX`, un `IF` o un `DIVIDE` dentro de la medida hacen que el total **compense** unas filas con otras
- Que cuando todas las filas están **del mismo lado**, el total coincide: por eso la prueba con el año completo **no lo atrapa**
- `SUMX( tabla , expresión )`: calcula la expresión **fila por fila** de la tabla y suma
- Que `SUMX` arregla el total **solo para la tabla que recorre**
- `SUMX` dentro de `SUMX`, y `VALUES` para recorrer los meses que deja el segmentador
- Que el `[Neto]`, sin `MAX`, **sí suma** siempre, y que `Excedente − Faltante` da **6 110** en las tres versiones
- Que **la granularidad del total es una regla de negocio**, no una decisión de DAX

## La idea del día

**Un total no suma las filas: vuelve a hacer la cuenta con toda la empresa, y si la fórmula tiene un MAX, lo que sobró en una finca tapa lo que faltó en otra.**

## Las cuatro cosas que son la clase

Si el día se complica y hay que recortar, estas no se recortan:

1. **El 6 110 y el 0** del total, contra el 9 010 y el 2 900 de sumar a mano.
2. **Qué calcula la fila del total**: 30 550 − 24 440, y el faltante de La Unión compensado.
3. **`SUMX( dim_finca , … )`** y el total que ya suma.
4. **Por mes vuelve a pasar**: el 9 010 contra el 18 450, y que escoger entre los dos es la regla del bono.

## Los números de control

Todos con segmentadores en `anio` = 2026, `mes` en 1–4 y `tipo` **sin nada marcado**.

| Dónde | Qué debe decir |
|---|---|
| La tabla por finca | La Union **2 100 / 5 000 / 42,00 %** · El Guayabo **14 250 / 9 440 / 150,95 %** · Santa Rosa **14 200 / 10 000 / 142,00 %** · total **30 550 / 24 440 / 125,00 %** |
| `[Excedente]` por finca | 0 · **4 810** · **4 200** · total **6 110** ← la columna suma **9 010** |
| `[Faltante]` por finca | **2 900** · 0 · 0 · total **0** ← la columna suma **2 900** |
| Con `mes` sin filtrar (año completo) | `[Excedente]` 0 en todo · `[Faltante]` 5 900 · 4 750 · 5 800 · total **16 450**, que sí suma |
| `[Excedente por finca]` / `[Faltante por finca]` | mismas filas · totales **9 010** y **2 900** |
| `[Neto]` por finca | −2 900 · 4 810 · 4 200 · total **6 110**, que sí suma |
| Tabla por `anio_mes`, `[Excedente por finca]` | 0 · 0 · **6 600** · **11 850** · total **9 010** ← la columna suma **18 450** |
| `[Excedente mensual]` por mes | 0 · 0 · 6 600 · 11 850 · total **18 450** |
| `[Excedente mensual]` por finca | 0 · **10 750** · **7 700** · total **18 450** |
| `[Faltante mensual]` por finca | 2 900 · **5 940** · **3 500** · total **12 340** |
| `[Faltante mensual]` por mes | 4 040 · 5 200 · 2 700 · 400 · total **12 340** |
| Excedente − Faltante, en las tres versiones | 6 110 − 0 = 9 010 − 2 900 = 18 450 − 12 340 = **6 110** |

## Entrega

En `entregas/apellido-nombre/`, por *pull request*, **dos archivos**:

| Archivo | Qué lleva |
|---|---|
| `Ejercicio21_Apellido_Nombre.md` | cada medida en un bloque de código con **su resultado anotado debajo**, las sumas a mano de la parte B y las respuestas de la parte G |
| `clase21-bono.png` | captura de **la tabla por mes** con `[Excedente por finca]` y `[Excedente mensual]` lado a lado, y los totales **9 010** y **18 450** |

> El `.pbix` no se entrega: el repositorio lo ignora a propósito.

## Nota sobre el material

Los números de esta clase —el 6 110 y el 0 del total, el 9 010 y el 2 900 de la suma, el 16 450 del año completo, el 18 450 y el 12 340 por mes y el 6 110 del neto en las tres versiones— están **verificados contra los CSV publicados en `datos/csv_clase19/`** con `docente/clase21_verificacion_docente.py`, que modela el contexto de la fila y el del total por separado, y la iteración de `SUMX` por fincas y por meses.

Lo que **ningún script puede verificar** es lo que dibuja Power BI en tu versión: si las filas de enero y febrero aparecen con **0**, y cómo se llaman los menús. Si en tu máquina algo sale distinto, **anótalo en la entrega: eso puntúa**, igual que documentar una discrepancia del enunciado.
