# Ejercicio práctico 7 · El día que no fue el más caluroso
**Duración: 2 horas · Individual · sqliteonline.com · Entrega: un archivo `.sql`**

---

## La situación

Ayer limpiamos la serie. Sacamos tres lecturas averiadas y una duplicada, le pusimos a `lecturas` las dos restricciones que le faltaban, y quedó una tabla de la que uno se puede fiar.

Hoy el jefe de operaciones pide el ranking de los días más calurosos de abril, y el ranking sale **mal en el primer puesto**.

No sale mal por un error de SQL. Sale mal porque **la limpieza de ayer dejó su propia marca**, y ninguna consulta de las que sabemos escribir hasta ahora la muestra.

Las funciones de ventana son la herramienta del día. También son las que te permiten equivocarte más rápido.

## Antes de empezar

1. **Pestaña nueva** en sqliteonline.com → SQLite.
2. Pegá `datos/agrodb_clase7.sql` completo y ejecutalo. Deben salir **3, 6, 8, 10, 7, 19, 16, 6, 9, 973**.
3. Trabajá en `Ejercicio7_Apellido_Nombre.sql`.

## La regla del día

> **Un ranking sin la columna que cuenta las filas es una opinión.**
>
> En la clase 6, el `COUNT(*)` servía para detectar filas de menos. Hoy sirve para saber si el primer puesto **se lo ganó o se lo regalamos**. Todo ranking que entregues hoy lleva al lado la cuenta de las filas sobre las que se calculó.

Y siguen vigentes las dos de siempre: **todo reporte que mencione un lote dice también la finca**, y **ningún promedio se entrega sin su `COUNT(*)`**.

---

## Parte A · Lo que `GROUP BY` no podía (20 min)

**A1.** Cada labor con su costo de mano de obra y, **al lado**, el costo total de mano de obra de toda su siembra.
*Pista:* `SUM(costo_mano_obra) OVER (PARTITION BY siembra_id)`.
Esperado: **19 filas** — una por labor, ninguna se colapsa.

Verificá con la siembra 5: sus dos labores son la 8 (320) y la 9 (95), y las dos tienen que mostrar **415** en la columna del total.

**A2.** Lo mismo, agregando qué **porcentaje** representa cada labor sobre el total de su siembra.
Esperado: las dos labores de la siembra 5 dan **77.1** y **22.9**, y suman 100.

**A3.** En un comentario: escribí la razón por la que esta consulta **no se puede** hacer con `GROUP BY siembra_id`. No vale "porque da error" — decí qué información se pierde exactamente y en qué momento.

> Esta es la idea entera del día en una consulta. Si A1 te salió, el resto es vocabulario.

---

## Parte B · Rankings (35 min)

**B1.** Ranking de lotes por rendimiento (**kg/ha**) **dentro de cada finca**, con su puesto.
*Pista:* `RANK() OVER (PARTITION BY f.nombre ORDER BY ... DESC)`.
Esperado: **6 filas**.

| finca | lote | kg_ha | puesto |
|---|---|---|---|
| Agricola La Union | A-1 | 38.18 | 1 |
| Finca El Guayabo | L-02 | 529.73 | 1 |
| Finca El Guayabo | L-01 | 202.27 | 2 |
| Hacienda Santa Rosa | L-01 | 256.14 | 1 |
| Hacienda Santa Rosa | L-02 | 174.19 | 2 |
| Hacienda Santa Rosa | L-03 | 77.92 | 3 |

> Si te da **202.0** en vez de 202.27, te falta el `* 1.0`. Es la trampa de la clase 5, y hoy es peor: el número truncado se esconde adentro de un puesto y el puesto parece razonable igual.

**B2.** El promedio diario del sensor 1 en abril, con **las tres** funciones de numeración al mismo tiempo: `ROW_NUMBER`, `RANK` y `DENSE_RANK`, todas ordenando por el promedio de mayor a menor.
Esperado: **30 filas**. Las primeras siete tienen que dar exactamente esto:

| dia | prom | row_number | rank | dense_rank |
|---|---|---|---|---|
| 2026-04-20 | 27.33 | 1 | 1 | 1 |
| 2026-04-05 | 25.63 | 2 | 2 | 2 |
| 2026-04-10 | 25.63 | 3 | 2 | 2 |
| 2026-04-15 | 25.63 | 4 | 2 | 2 |
| 2026-04-25 | 25.63 | 5 | 2 | 2 |
| 2026-04-30 | 25.63 | 6 | 2 | 2 |
| 2026-04-19 | 24.86 | 7 | 7 | 3 |

En un comentario, contestá las tres:
- ¿Por qué `RANK` salta de 2 a 7 y `DENSE_RANK` no?
- Los 30 días tienen solo **7** promedios distintos. ¿Cuál de las tres funciones te dice ese número de un vistazo?
- ¿Por qué `ROW_NUMBER` le pone 2 a uno de los días empatados y 3 a otro, si valen lo mismo? ¿Qué garantiza que mañana no se los cambie?

**B3 — el punto del día.** Repetí B2 **agregando la columna `COUNT(*)`** de cada día.

Mirá el primer puesto. Después contestá, en un comentario y con nombre propio:

1. ¿Cuántas lecturas tiene el 20 de abril? ¿Y el 19?
2. ¿Por qué tienen menos que los otros días? *(La respuesta está en lo que hicimos ayer, no en el sensor.)*
3. Las tres lecturas que faltan eran de las **21:00, 00:00 y 03:00**. ¿Qué le hace eso al promedio del día?
4. Entonces: **¿el 20 de abril fue el día más caluroso de abril?** Sí o no, y por qué.

**B4.** Volvé a armar el ranking, ahora **solo con los días que tienen las 8 lecturas**.
Esperado: **28 filas**, y el primer puesto pasa a ser un empate de **5 días** en **25.63**.

En un comentario: ¿es esta la respuesta correcta, o simplemente otra respuesta? ¿Qué perdimos al descartar el 19 y el 20?

**B5.** El **mejor lote de cada finca**, una sola fila por finca.
*Pista:* no se puede filtrar por una función de ventana en el `WHERE`. Hay que meter la ventana en una CTE y filtrar afuera.
Esperado: **3 filas** — `A-1` (38.18), `L-02` (529.73) y `L-01` (256.14).

Antes de escribir la versión que funciona, escribí la que **no** funciona (`WHERE puesto = 1`), corré la, y pegá el mensaje de error como comentario. Después explicá por qué el `WHERE` no la ve.

---

## Parte C · Mirar la fila de al lado (30 min)

**C1.** Cada cosecha con los kilos de la **cosecha anterior de la misma siembra** y la diferencia entre las dos.
*Pista:* `LAG(kg) OVER (PARTITION BY siembra_id ORDER BY fecha)`.
Esperado: **9 filas**. Seis tienen `NULL` en la columna "anterior".

En un comentario: esas seis, ¿por qué son `NULL`? ¿Está mal la consulta?

**C2.** Ahora solo las cosechas que **rindieron menos** que la anterior de su misma siembra.
Esperado: **3 filas**.

| siembra | de | a | delta |
|---|---|---|---|
| 1 | 4200 | 3100 | −1100 |
| 4 | 2600 | 1850 | −750 |
| 6 | 1200 | 900 | −300 |

En un comentario, una línea: **las tres siembras que tuvieron un segundo corte, las tres cayeron.** ¿Qué le preguntarías al jefe de finca con este resultado en la mano?

**C3.** Con `LEAD`, cuántos **días** pasaron entre cada cosecha y la siguiente de la misma siembra.
Esperado: **9 filas**, de las cuales **3** tienen un número: **29**, **21** y **25** días.

**C4 — el hueco que hicimos nosotros.** Corré esta, que es exactamente la misma del ejercicio 6:

```sql
SELECT sensor_id, ant, fecha_hora,
       ROUND((julianday(fecha_hora) - julianday(ant)) * 24, 1) AS horas_sin_medir
FROM (
  SELECT sensor_id, fecha_hora,
         LAG(fecha_hora) OVER (PARTITION BY sensor_id ORDER BY fecha_hora) AS ant
  FROM lecturas
)
WHERE ant IS NOT NULL
  AND (julianday(fecha_hora) - julianday(ant)) * 24 > 3;
```

**En la clase 6 esta consulta devolvía 1 fila. Hoy devuelve 2.**

Esperado:

| sensor | desde | hasta | horas |
|---|---|---|---|
| 1 | 2026-04-19 18:00 | 2026-04-20 06:00 | **12.0** |
| 2 | 2026-04-10 21:00 | 2026-04-14 00:00 | 75.0 |

En un comentario, tres líneas:
1. El hueco del sensor 2 ya estaba ayer. ¿De dónde salió el del sensor 1?
2. ¿Es un hueco del **sensor** o un hueco de la **base de datos**?
3. Cuando borrás una fila mala, la fila no queda en blanco: **desaparece**. ¿Qué habría que haber guardado para que dentro de seis meses alguien pueda saber que ahí hubo una medición y que la borramos a propósito?

---

## Parte D · Acumulados y media móvil (25 min)

**D1.** Kilos cosechados por fecha, con el **acumulado** del curso del año.
*Pista:* `SUM(SUM(kg)) OVER (ORDER BY fecha)`.
Esperado: **8 filas**, y la última tiene que cerrar en **30550** — el mismo total del ejercicio 5.

**D2.** El mismo acumulado, pero **reiniciándose en cada finca**.
Esperado: **9 filas**. Los tres acumulados finales: **2100**, **14250** y **14200**.

En un comentario: qué cambió en el `OVER (...)` entre D1 y D2, y por qué eso alcanza.

**D3.** Media móvil de **7 días** del promedio diario del sensor 1.
*Pista:* `AVG(prom) OVER (ORDER BY d ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)`.
Esperado: **30 filas**. Del 18 al 21 de abril tiene que dar:

| dia | prom | media_movil |
|---|---|---|
| 2026-04-18 | 23.63 | 23.49 |
| 2026-04-19 | 24.86 | 23.81 |
| 2026-04-20 | 27.33 | **24.33** |
| 2026-04-21 | 21.63 | 23.91 |

> **Cuidado con dónde ponés el filtro.** La ventana tiene que ver **los 30 días**. Si filtrás el rango de fechas en el mismo `SELECT` donde está el `OVER`, la media móvil se calcula solo sobre lo que quedó y te da otros números, sin ningún error. Es el mismo *ventana adentro, filtro afuera* de B5.

**D4.** Agregale a D3 una columna con `COUNT(*) OVER (ORDER BY d ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)`.

Mirá los primeros seis días. En un comentario: la media móvil del 1 de abril, ¿sobre cuántos días se calculó? ¿Es una media de 7 días? Si un tablero muestra esa primera columna sin aclarar nada, **¿qué está afirmando que no es cierto?**

**D5.** En un comentario, sobre el 20 de abril: el promedio crudo dice **27.33** y la media móvil dice **24.33**. La media móvil existe para sacarle el ruido a una serie. **¿Le sacó ruido, o le tapó un problema?** Tres líneas.

---

## Parte E · Cierre (10 min, comentarios en el archivo)

1. `GROUP BY` y `OVER (PARTITION BY ...)` se parecen mucho. En **una sola frase**, la diferencia.
2. Hoy usaste `ROW_NUMBER` en B5 para quedarte con el mejor lote de cada finca. Si dos lotes de la misma finca empataran exactamente en kg/ha, ¿qué devolvería tu consulta? ¿Es lo que querías?
3. De todo lo de hoy, lo único que **no** es una función nueva: el 20 de abril salió primero por algo que hicimos nosotros ayer con la mejor intención. Escribí, en tres líneas, qué regla te llevás para la próxima vez que limpies datos.

---

## Rúbrica (100 puntos)

| Criterio | Pts |
|---|---|
| Parte A: la ventana al lado del detalle, con el porcentaje y la explicación de A3 | 15 |
| Parte B1: el ranking por finca, con `* 1.0` | 10 |
| Parte B2: las tres funciones juntas y las tres preguntas contestadas | 15 |
| **Parte B3: el podio auditado — las cuatro preguntas, con la causa bien identificada** | **20** |
| Parte B5: el patrón CTE + filtro afuera, con el error transcripto | 10 |
| Parte C1–C3: `LAG` y `LEAD`, con los `NULL` bien explicados | 10 |
| **Parte C4: el segundo hueco, y de dónde salió** | **10** |
| Parte D: acumulados, media móvil y la ventana incompleta de D4 | 10 |
| Preguntas de cierre con criterio | 5 |
| **Extra:** una consulta con ventana que responda una pregunta de negocio que yo no pedí, con su justificación en un comentario | +5 |

El archivo debe correr **completo** de arriba abajo después de `datos/agrodb_clase7.sql`.

**Todo ranking que entregues sin la columna de conteo al lado se descuenta, aunque el orden esté bien.** Hoy esa columna era la respuesta.
