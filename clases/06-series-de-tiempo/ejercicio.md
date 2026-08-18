# Ejercicio práctico 6 · El sensor que mintió tres días
**Duración: 2 horas · Individual · sqliteonline.com · Entrega: un archivo `.sql`**

---

## La situación

Los sensores llevan midiendo todo abril: una lectura cada tres horas, 977 filas en total. Nadie las había mirado nunca.

El jefe de operaciones quiere el promedio de temperatura del mes por lote. Es una consulta de una línea. Y va a estar mal.

Va a estar mal porque en esas 977 filas hay **cuatro problemas** que ninguna restricción de la base impidió: un sensor que estuvo tres días sin reportar, otro que escribió su código de falla como si fuera una temperatura, una medición que entró dos veces, y un rango de fechas que se come el último día del mes sin avisar.

Hoy no alcanza con escribir la consulta. Hay que **auditar la serie antes de promediarla**.

## Antes de empezar

1. **Pestaña nueva** en sqliteonline.com → SQLite.
2. Pegá `datos/agrodb_clase6.sql` completo y ejecutalo. Deben salir **3, 6, 8, 10, 7, 19, 16, 6, 9, 977**.
3. Trabajá en `Ejercicio6_Apellido_Nombre.sql`.

## La regla del día

> **Ningún promedio se entrega sin su `COUNT(*)` al lado.**
>
> En la clase 5 el `COUNT(*)` servía para detectar filas de más. Hoy sirve para detectar filas **de menos**. Si un sensor mide cada 3 horas durante 30 días, tiene que tener 240 lecturas. El que tenga menos, algo perdió. El que tenga más, algo duplicó.

Y la regla de formato de la clase 5 sigue vigente: **todo reporte que mencione un lote tiene que decir también la finca.**

---

## Parte A · Conocer la tabla nueva (20 min)

**A1.** Mirá diez lecturas cualesquiera y la estructura de la tabla:
```sql
SELECT * FROM lecturas LIMIT 10;
```
En un comentario, respondé: `fecha_hora` está declarada como `TEXT`. ¿Por qué SQLite no tiene un tipo `DATETIME` de verdad, y qué consecuencia tiene eso para nosotros?

**A2.** Cuántas lecturas tiene cada sensor, con su primera y su última medición.
*Pista:* `MIN(fecha_hora)` y `MAX(fecha_hora)`.
Esperado: **5 filas**. Un sensor tiene 241, otro 216, otro 240, otro 240, y otro tiene solo 40 y son todas de **febrero**.

Anotá en un comentario: ¿por qué ese sensor tiene lecturas viejas y ninguna de abril?

**A3.** Los sensores que **no tienen ninguna lectura**, con su lote y su finca.
Esperado: **1 sensor**.

> Ojo con este. `sensores` tiene 6 filas y `lecturas` menciona solo 5 sensores. Un `JOIN` normal nunca te va a mostrar el que falta. Esto es `LEFT JOIN` + `IS NULL`, igual que la clase 5.

**A4.** En un comentario: ¿qué diferencia hay entre estas tres cosas?
- un sensor con `activo = 0`
- un sensor sin lecturas
- un sensor con lecturas pero ninguna reciente

Las tres existen en esta base. Decí cuál es cuál.

---

## Parte B · Las funciones de fecha (25 min)

SQLite guarda las fechas como texto. Estas cuatro funciones son las que las convierten en algo con lo que se puede calcular:

| Función | Qué hace |
|---|---|
| `DATE(x)` | se queda con `AAAA-MM-DD`, tira la hora |
| `strftime('%H', x)` | saca una parte: `%Y` año, `%m` mes, `%d` día, `%H` hora, `%w` día de semana |
| `julianday(x)` | convierte a un número, para poder **restar** dos fechas |
| `datetime(x, '+3 hours')` | mueve una fecha |

**B1.** Promedio diario del sensor 1, con el conteo de lecturas de cada día.
Esperado: **30 filas**, y las primeras cinco deben dar **21.63 · 22.63 · 23.63 · 24.63 · 25.63**.

**B2.** La curva del día: promedio del sensor 1 **agrupado por hora del día**, ordenado por hora.
Esperado: **8 filas**. Tiene que dar una curva que sube al mediodía y baja de madrugada. Si no te da una curva, agrupaste mal.

**B3.** Cuántas lecturas hay por mes (`strftime('%Y-%m', ...)`), de toda la tabla.
Esperado: **2 filas** — febrero con **40** y abril con **937**.

**B4 — la trampa del día.** Corré estas dos y anotá los dos números:
```sql
SELECT COUNT(*) FROM lecturas
WHERE fecha_hora BETWEEN '2026-04-01' AND '2026-04-30';

SELECT COUNT(*) FROM lecturas
WHERE fecha_hora >= '2026-04-01' AND fecha_hora < '2026-05-01';
```
Esperado: **905** y **937**.

Faltan **32 lecturas**. Encontralas:
```sql
SELECT COUNT(*) FROM lecturas WHERE DATE(fecha_hora) = '2026-04-30';
```

En un comentario, explicá **exactamente** por qué el `BETWEEN` las perdió. La respuesta no es "porque `BETWEEN` es excluyente" —`BETWEEN` es inclusivo en los dos extremos—. La respuesta tiene que ver con qué texto es `'2026-04-30'` cuando lo comparás contra `'2026-04-30 03:00:00'`.

> **Esta es la que más caro sale en la vida real.** Un reporte mensual que se come el último día del mes no da error, no da cero, y nadie lo nota hasta que alguien suma los doce meses y no cuadra con el año.

---

## Parte C · Auditar la serie (35 min)

Esta es la parte importante. Hacela despacio.

**C1 · El valor imposible.**
El sensor 1 mide temperatura. Buscá su mínimo, su máximo y su promedio.
Esperado: mínimo **-99**, máximo **32**, promedio **22.15**.

Ahora el mismo promedio, excluyendo las lecturas averiadas.
Esperado: **23.68**.

En un comentario: la diferencia es de un grado y medio. ¿Por qué **eso** es peor que una diferencia de veinte grados?

**C2.** Cuántas lecturas averiadas hay y de qué días son.
Esperado: **3 lecturas**, repartidas en **2 días**.
Mostrá esos dos días con su promedio **crudo** (sin filtrar). Esperado: **9.38** y **-4.25**.

> Un promedio diario de −4.25 °C en abril en Los Ríos. Ese número habría llegado al tablero.

**C3 · El hueco.**
El sensor 2 debería tener 240 lecturas de abril y tiene 216. Faltan 24, o sea 3 días.

Primero probá el camino que **no** funciona:
```sql
SELECT DATE(fecha_hora) AS dia, COUNT(*) AS n
FROM lecturas WHERE sensor_id = 2
GROUP BY dia HAVING n <> 8;
```
Esperado: **0 filas**. Anotá por qué esto no encuentra nada, aunque los días falten de verdad. *(Es la lección de la parte: un `GROUP BY` solo puede agrupar lo que existe. Un día sin ninguna fila no es un grupo vacío — no es un grupo.)*

Ahora encontralos de verdad, con un calendario generado:
```sql
WITH RECURSIVE dias(d) AS (
    SELECT '2026-04-01'
    UNION ALL
    SELECT DATE(d, '+1 day') FROM dias WHERE d < '2026-04-30'
)
SELECT d FROM dias
WHERE d NOT IN (SELECT DATE(fecha_hora) FROM lecturas WHERE sensor_id = 2);
```
Esperado: **3 días** — el **11, 12 y 13 de abril**.

**C4.** El mismo hueco, por el otro camino: comparando cada lectura con la anterior.
```sql
SELECT sensor_id, anterior, fecha_hora,
       ROUND((julianday(fecha_hora) - julianday(anterior)) * 24, 1) AS horas_sin_medir
FROM (
  SELECT sensor_id, fecha_hora,
         LAG(fecha_hora) OVER (PARTITION BY sensor_id ORDER BY fecha_hora) AS anterior
  FROM lecturas
)
WHERE anterior IS NOT NULL
  AND (julianday(fecha_hora) - julianday(anterior)) * 24 > 3;
```
Esperado: **1 fila**, con **75 horas** sin medir.

En un comentario: ¿por qué 75 y no 72? *(Contá desde la última lectura buena hasta la primera lectura después del hueco.)*

> `LAG()` es una **función de ventana** y la vemos en serio mañana. Hoy alcanza con leerla como *"traeme el valor de la fila anterior de este mismo sensor, ordenando por fecha"*.

**C5 · El duplicado.**
Mediciones que entraron dos veces: mismo sensor, misma `fecha_hora`.
*Pista:* `GROUP BY sensor_id, fecha_hora` + `HAVING COUNT(*) > 1`, igual que la clase 4.
Esperado: **1 fila** — el sensor 1, el **7 de abril a las 12:00**.

Buscá en `datos/agrodb_clase6.sql` la restricción que **habría** impedido esto y que la tabla no tiene. Escribila como comentario, en SQL.

---

## Parte D · El reporte que sí se puede entregar (30 min)

**D1.** Promedio de abril por finca, lote y tipo de sensor, con el conteo de lecturas al lado, **excluyendo las averiadas y usando el rango de fechas correcto**.
Esperado: **4 filas**.

| finca | lote | tipo | n | promedio |
|---|---|---|---|---|
| Agricola La Union | A-1 | humedad | 240 | 79.38 |
| Finca El Guayabo | L-01 | radiacion | 240 | 278.75 |
| Hacienda Santa Rosa | L-01 | humedad | 216 | 76.91 |
| Hacienda Santa Rosa | L-01 | temperatura | 238 | 23.68 |

> Mirá la columna `n` antes de mirar la columna `promedio`. Dos de esas cuatro filas no tienen 240 y ya sabés por qué. **Un promedio sin su conteo al lado es un número sin garantía.**

**D2 · Alertas con `CASE`.**
Clasificá cada día del sensor 1 según su temperatura máxima:
- `>= 32` → `'ALERTA CALOR'`
- `>= 30` → `'atencion'`
- resto → `'normal'`

Mostrá solo los días que no son normales, ordenados por fecha. Esperado: **18 filas**.

**D3.** Lo mismo, resumido: cuántos días cayó en cada estado.
Esperado: **ALERTA CALOR 6 · atencion 12 · normal 12**. Los tres suman 30.

**D4.** Cruzá las dos mitades del modelo: labores de **riego** que tengan lecturas de sensor **del mismo día y del mismo lote**, con el conteo de esas lecturas.
*Son 5 tablas.* Esperado: **1 fila** — la labor **14**, del **14 de abril**, en **L-01**, con **8 lecturas**.

En un comentario, escribí la pregunta de negocio que esta consulta empieza a responder y qué le falta al modelo para responderla del todo.

---

## Parte E · Cierre (10 min, comentarios en el archivo)

1. De los cuatro problemas de hoy —el hueco, el valor de falla, el duplicado y el `BETWEEN`—, **¿cuál es el más difícil de detectar** una vez que el reporte ya se entregó? Justificá en tres líneas.
2. La tabla `lecturas` no tiene `CHECK` sobre `valor` ni `UNIQUE (sensor_id, fecha_hora)`. Escribí las dos restricciones que le agregarías. Después contestá: si las agregás hoy, ¿qué pasa con las filas malas que ya están cargadas?
3. En abril hay 977 lecturas. Con 6 sensores midiendo cada 3 horas, en un año son unas 17.500; con 200 sensores, más de medio millón. Nombrá **una** cosa que va a dejar de funcionar bien a esa escala. *(No hace falta resolverla: mañana y el jueves la resolvemos.)*

---

## Rúbrica (100 puntos)

| Criterio | Pts |
|---|---|
| Parte A: las 3 consultas + la distinción de A4 bien explicada | 15 |
| Parte B: las funciones de fecha aplicadas, con los números exactos | 15 |
| **Parte B4: la trampa del `BETWEEN` explicada correctamente** | **10** |
| **Parte C: los cuatro problemas detectados, cada uno con su consulta** | **30** |
| Parte C3: por qué el `GROUP BY` no encuentra el día que falta | 5 |
| Parte D: el reporte limpio con los conteos al lado + las alertas | 20 |
| Preguntas de cierre con criterio | 5 |
| **Extra:** una consulta que detecte un quinto problema de calidad en la serie, que yo no pedí | +5 |

El archivo debe correr **completo** de arriba abajo después de `datos/agrodb_clase6.sql`.

**Si un `AVG` no tiene su `COUNT(*)` al lado, se descuenta aunque el número esté bien.** Es la misma regla de ayer, del otro lado.
