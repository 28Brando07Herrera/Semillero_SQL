---
marp: true
paginate: true
theme: default
title: "Clase 21 · El total que se comió el faltante"
style: |
  section { font-family: system-ui, -apple-system, "Segoe UI", sans-serif; font-size: 26px; background: #fbfbfa; color: #1f2933; padding: 60px 70px; }
  section.lead { background: #16324f; color: #f4f7fa; }
  section.lead h1 { color: #ffffff; font-size: 54px; line-height: 1.1; }
  section.lead h2 { color: #7fb3d5; font-weight: 400; font-size: 30px; }
  h1 { color: #16324f; font-size: 40px; border-bottom: 3px solid #f2a104; padding-bottom: 10px; }
  h2 { color: #1c7293; font-size: 32px; }
  strong { color: #b3541e; }
  code { background: #eef2f6; padding: 1px 6px; border-radius: 4px; }
  pre { background: #16324f; border-radius: 8px; font-size: 20px; }
  pre code { background: transparent; color: #e8eef4; }
  table { font-size: 23px; }
  th { background: #16324f; color: #fff; }
  blockquote { border-left: 5px solid #f2a104; color: #4a5568; font-style: normal; }
  footer { color: #8a99a8; font-size: 16px; }
footer: "Curso de SQL · AgroDB · Clase 21"
---

<!-- _class: lead -->

# El total que se comió el faltante

## Totales de medidas con SUMX, y una fila de total que no era la suma de nada

Clase 21 · 16 de septiembre

---

# Lo que llega hoy

**Nada.** Los CSV son los de la clase 17 y el `.pbix` es el de ayer.

Llega **una decisión de la gerencia** para la temporada:

> *«Cada kilo arriba de la meta paga bono. Cada kilo abajo, entra al plan de apoyo.»*

<br>

Segmentadores en `anio` = 2026, `mes` en 1–4, y `tipo` **sin nada marcado**:

| Finca | `[Kilos]` | `[Meta]` | `[Cumplimiento]` |
|---|---|---|---|
| Agricola La Union | 2 100 | 5 000 | 42,00 % |
| Finca El Guayabo | 14 250 | 9 440 | 150,95 % |
| Hacienda Santa Rosa | 14 200 | 10 000 | 142,00 % |
| **Total** | **30 550** | **24 440** | **125,00 %** |

---

# Dos medidas de una línea

**Inicio → Nueva medida**, dos veces:

```
Excedente = MAX( 0 , [Kilos] - [Meta] )
```

```
Faltante = MAX( 0 , [Meta] - [Kilos] )
```

<br>

- `[Kilos] - [Meta]` es positivo si la finca pasó la meta, negativo si no.
- `MAX( 0 , … )` se queda con **el mayor de los dos**: si la resta es negativa, **0**.
- Una finca tiene bono **o** faltante, nunca los dos.

> `MAX` con dos argumentos no recorre una columna: compara **dos números**.

---

# La tabla para finanzas

Agrega las dos a la tabla por finca:

| Finca | `[Kilos]` | `[Meta]` | `[Excedente]` | `[Faltante]` |
|---|---|---|---|---|
| Agricola La Union | 2 100 | 5 000 | 0 | **2 900** |
| Finca El Guayabo | 14 250 | 9 440 | **4 810** | 0 |
| Hacienda Santa Rosa | 14 200 | 10 000 | **4 200** | 0 |
| **Total** | **30 550** | **24 440** | **6 110** | **0** |

<br>

Finanzas lee la última fila: **6 110 kilos de bono**, y **nadie necesita apoyo**.

> Súmale la columna de `[Faltante]` con el dedo.

---

# ¿Y qué error dio?

## Ninguno. Otra vez.

<br>

| Columna | Lo que dice el total | Lo que suman las filas |
|---|---|---|
| `[Excedente]` | 6 110 | 4 810 + 4 200 = **9 010** |
| `[Faltante]` | **0** | **2 900** |

<br>

- Las tres filas están bien: cada finca tiene el bono y el faltante que le toca.
- Las dos fórmulas están bien: son de una línea.
- **El total no cuadra con su propia columna**, y no hay advertencia.

> Una tarjeta con `[Faltante]` diría **0**. La Unión cosechó **42 %** de su meta.

---

# Un total no es una suma

La fila del total **no suma las filas de arriba**. Hace otra cosa: **vuelve a calcular la medida** con el filtro del total, que es **toda la empresa**.

```
Fila de La Union:  MAX( 0 ,  2 100 −  5 000 ) = MAX( 0 , −2 900 ) =     0
Fila del total:    MAX( 0 , 30 550 − 24 440 ) = MAX( 0 ,  6 110 ) = 6 110
```

<br>

Es la clase 15 otra vez: **la medida se calcula en el contexto de la fila**. Y la fila del total también es una fila, con su propio contexto: **ningún filtro de finca**.

> En `[Kilos]` no se nota, porque sumar los kilos de toda la empresa **da lo mismo** que sumar las tres filas.

---

# Dónde quedó el faltante

La resta del total junta a las tres fincas **antes** del `MAX`:

```
  4 810   bono de El Guayabo
+ 4 200   bono de Santa Rosa
− 2 900   faltante de La Union
───────
  6 110   ← lo que dice el total
```

<br>

El faltante de La Unión **no desapareció**: se **restó del bono** de las otras dos. El total compensó unas fincas con otras.

> 9 010 − 2 900 = **6 110**. Es el mismo número por dos caminos, y por eso no se ve raro.

---

# Lo que parece suma

No todo total tiene que sumar sus filas:

| Medida | ¿El total debe sumar las filas? | ¿Lo hace? |
|---|---|---|
| `[Kilos]` | sí | **sí** |
| `[Cumplimiento]` | **no**: 42 + 150,95 + 142 no es un porcentaje | no, y dice 125,00 % |
| `[Excedente]` | **sí**: son kilos de bono | **no** |

<br>

Nadie suma una columna de porcentajes. Pero `[Excedente]` **se ve igual que `[Kilos]`**: números enteros, en kilos, uno debajo del otro.

> El peligro no es el total que no suma. Es **el que parece que suma**.

---

# Por qué no se vio al probarla

Quita el segmentador `mes` (año completo, 2026):

| Finca | `[Kilos]` | `[Meta]` | `[Excedente]` | `[Faltante]` |
|---|---|---|---|---|
| Agricola La Union | 2 100 | 8 000 | 0 | 5 900 |
| Finca El Guayabo | 14 250 | 19 000 | 0 | 4 750 |
| Hacienda Santa Rosa | 14 200 | 20 000 | 0 | 5 800 |
| **Total** | **30 550** | **47 000** | **0** | **16 450** |

<br>

5 900 + 4 750 + 5 800 = **16 450**. **Cuadra.** Las tres fincas están **del mismo lado** de la meta, y no hay nada que compensar.

> El error solo aparece cuando **unas filas pasan y otras no**. Vuelve a poner `mes` en 1–4.

---

# SUMX: una finca a la vez

```
SUMX( tabla , expresión )
```

1. Toma **cada fila** de la `tabla`.
2. Calcula la `expresión` **con el filtro de esa fila**.
3. **Suma** los resultados.

<br>

```
Excedente por finca = SUMX( dim_finca , [Excedente] )
```

En la fila del total, `SUMX` recorre las tres fincas: calcula el `[Excedente]` **de La Unión sola**, luego **de El Guayabo sola**, luego **de Santa Rosa sola**, y suma. **El `MAX` se aplica antes de sumar.**

> Es el `RANKX` de ayer: la `tabla` dice **quién se recorre**. Hoy decide **dónde se aplica la regla**.

---

# El total que ya suma

Crea las dos:

```
Excedente por finca = SUMX( dim_finca , [Excedente] )
```

```
Faltante por finca = SUMX( dim_finca , [Faltante] )
```

| Finca | `[Excedente por finca]` | `[Faltante por finca]` |
|---|---|---|
| Agricola La Union | 0 | 2 900 |
| Finca El Guayabo | 4 810 | 0 |
| Hacienda Santa Rosa | 4 200 | 0 |
| **Total** | **9 010** | **2 900** |

<br>

Las filas **no cambiaron**: en la fila de una finca, `dim_finca` ya trae **una sola** finca, y recorrerla es calcular una vez. **Lo único que cambió es el total.**

---

# El gerente lo quiere por mes

Tabla nueva con `dim_tiempo[anio_mes]`, `[Kilos]`, `[Meta]` y `[Excedente por finca]`:

| `anio_mes` | `[Kilos]` | `[Meta]` | `[Excedente por finca]` |
|---|---|---|---|
| 2026-01 | | 4 040 | 0 |
| 2026-02 | | 5 200 | 0 |
| 2026-03 | 10 800 | 6 900 | **6 600** |
| 2026-04 | 19 750 | 8 300 | **11 850** |
| **Total** | **30 550** | **24 440** | **9 010** |

<br>

6 600 + 11 850 = **18 450**. El total dice **9 010**.

> La medida **arreglada** hace diez minutos. **Y otra vez sin un aviso.**

---

# Por qué otra vez

`SUMX( dim_finca , … )` recorre **fincas**. No sabe nada de meses.

```
Fila de marzo:   cada finca, SOLO marzo        → el MAX se aplica por finca y mes
Fila del total:  cada finca, LOS CUATRO meses  → el MAX se aplica por finca
```

<br>

En el total, Santa Rosa junta sus cuatro meses **antes** del `MAX`:

| Santa Rosa | Ene | Feb | Mar | Abr | En la fila del total |
|---|---|---|---|---|---|
| `[Kilos] - [Meta]` | −1 500 | −2 000 | +6 600 | +1 100 | **+4 200** |
| con `MAX` | 0 | 0 | **6 600** | **1 100** | 4 200 |

> Es el mismo error de la diapositiva 7, **una dimensión más abajo**: enero y febrero se comieron 3 500 kilos del bono de marzo.

---

# SUMX dentro de SUMX

Si la regla se aplica **por finca y por mes**, la medida tiene que recorrer **las dos cosas**:

```
Excedente mensual =
SUMX(
    dim_finca ,
    SUMX( VALUES( dim_tiempo[anio_mes] ) , [Excedente] )
)
```

- `VALUES( dim_tiempo[anio_mes] )`: los meses **que deja el segmentador**, los cuatro.
- El `SUMX` de afuera recorre fincas; el de adentro, **los meses de cada finca**.

| | Por mes: Ene · Feb · Mar · Abr | Por finca: La Union · El Guayabo · Santa Rosa | Total |
|---|---|---|---|
| `[Excedente mensual]` | 0 · 0 · 6 600 · 11 850 | 0 · **10 750** · **7 700** | **18 450** |

> Ahora suma **en las dos tablas**.

---

# ¿Cuál es el bono?

## Depende de la regla. Y la regla no está en los datos.

<br>

| Medida | Dónde se aplica el `MAX` | Bono |
|---|---|---|
| `[Excedente]` | la empresa entera | 6 110 |
| `[Excedente por finca]` | cada finca, en la temporada | **9 010** |
| `[Excedente mensual]` | cada finca, cada mes | **18 450** |

<br>

Con la regla **por temporada**, El Guayabo compensa sus tres meses sin cosecha con el abril. Con la regla **mensual**, no: abril paga completo.

> Las tres fórmulas están bien. Es la clase 20 otra vez: **el tablero no dice cuál escogiste**. La granularidad del total se le pregunta **a quien paga el bono**, no a DAX.

---

# Tres versiones, para el cuaderno

Segmentadores en 2026 y 1–4:

| Versión | Excedente | Faltante | Excedente − Faltante |
|---|---|---|---|
| sin `SUMX` | 6 110 | 0 | **6 110** |
| `SUMX` por finca | 9 010 | 2 900 | **6 110** |
| `SUMX` por finca y mes | 18 450 | 12 340 | **6 110** |

<br>

Y una medida sin `MAX`:

```
Neto = [Kilos] - [Meta]
```

La Union **−2 900** · El Guayabo **4 810** · Santa Rosa **4 200** · total **6 110**, que **sí suma**.

> Una resta sí suma; un `MAX` **no**. El neto es siempre 6 110: lo que cambia es **cuánto se paga y cuánto se reporta faltante**.

---

# La prueba de un total

Ayer la prueba de un ranking era mover un segmentador. La de un total es **sumar la columna**:

<br>

| Qué revisas | Qué atrapa |
|---|---|
| que el total **sea la suma** de la columna, si son kilos, pesos o piezas | el total que compensa filas |
| con **unas filas arriba y otras abajo** de la meta, no solo con el año completo | la prueba que no podía fallar |
| **otra dimensión** en las filas: por mes, por cultivo | el `SUMX` que recorre lo que no es |
| que alguien te diga **por dónde se aplica la regla** | que escogiste la granularidad sin saberlo |

<br>

> **Si un total en kilos no es la suma de sus filas, alguna fila le prestó a otra.**

---

# Los errores que van a ver hoy

| Síntoma | Qué pasó | Arreglo |
|---|---|---|
| `[Faltante]` dice 0 en el total | el `MAX` se aplicó a la empresa | `SUMX( dim_finca , [Faltante] )` |
| `MAX` da error de sintaxis | escribiste `MAX( [Kilos] - [Meta] )`, con un argumento | `MAX( 0 , … )`, con dos |
| El Guayabo sale con 0 de bono y 4 990 de faltante | quedó **perenne** marcado de ayer: el maíz no cuenta | quita la marca del segmentador `tipo` |
| El total ya suma con el año completo | todas las fincas abajo de la meta | **no es arreglo**: regresa `mes` a 1–4 |
| Por mes, el total dice 9 010 | `SUMX` recorre fincas, no meses | `[Excedente mensual]` |
| `VALUES` da error | pusiste `VALUES( dim_tiempo )` o otra columna | `VALUES( dim_tiempo[anio_mes] )` |
| Las filas de enero y febrero salen con **0** | `MAX( 0 , … )` devuelve 0, no vacío | **no es error**: no hubo cosecha ni bono |
| Los meses salen desordenados | usaste `nombre_mes` | usa `anio_mes` |

---

<!-- _class: lead -->

# La idea del día

## Un total no suma las filas: vuelve a hacer la cuenta con toda la empresa, y si la fórmula tiene un MAX, lo que sobró en una finca tapa lo que faltó en otra.

<br>

El total de `[Faltante]` dijo **0** con La Unión al 42 % de su meta. `SUMX` lo arregló para las fincas, y por mes volvió a pasar. **La granularidad del total es la regla del bono, y nadie la escribió.**

<br>

**Práctica:** crea `[Excedente]` y `[Faltante]`, suma las columnas a mano, arréglalas con `SUMX`, pásalas a una tabla por mes y arréglalas otra vez.

**Y por finca y mes, el bono tiene que sumar 18 450.**
