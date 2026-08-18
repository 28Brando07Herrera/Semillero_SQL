# Clase 7 · Funciones de ventana: mirar sin agrupar
**Martes 18 de agosto**

Sesión corta: **45–50 minutos de clase** y el resto a práctica. `GROUP BY` colapsa las filas; `OVER` hace la misma cuenta y las deja donde estaban. Con eso salen rankings, comparaciones contra la fila anterior, acumulados y medias móviles.

Y sale también el podio del día: el 20 de abril aparece como la jornada más calurosa de abril, y no lo fue.

## Material

| Qué | Dónde |
|---|---|
| Diapositivas | [slides.md](slides.md) · [versión web](https://negatix092.github.io/Semillero_SQL/07-funciones-ventana.html) |
| Ejercicio práctico | [ejercicio.md](ejercicio.md) |
| Script base (ejecutar primero) | [`datos/agrodb_clase7.sql`](../../datos/agrodb_clase7.sql) |

## Lo que hay que saber al terminar

- Qué hace `OVER` que `GROUP BY` no puede: calcular sobre el grupo **sin colapsar la fila**
- Leer `FUNCION() OVER (PARTITION BY … ORDER BY …)` parte por parte
- `ROW_NUMBER`, `RANK` y `DENSE_RANK`, y **en qué se diferencian cuando hay empates**
- Que `ROW_NUMBER` con empates no es determinista, y cómo desempatar a mano
- El patrón *"el mejor de cada grupo"*: ventana adentro de una CTE, filtro afuera
- **Por qué no se puede filtrar por una función de ventana en el `WHERE`**
- `LAG` y `LEAD` para comparar una fila con la anterior o la siguiente
- Que el `NULL` de la primera fila de cada partición es la respuesta correcta, no un error
- `SUM() OVER (ORDER BY …)` para un acumulado
- `ROWS BETWEEN … PRECEDING AND CURRENT ROW` para una media móvil
- Que `* 1.0` sigue haciendo falta, y que hoy el error se esconde adentro de un puesto

## La regla del día

**Un ranking sin la columna que cuenta las filas es una opinión.**

En la clase 6 el `COUNT(*)` servía para detectar filas de menos. Hoy sirve para saber **si el primer puesto se lo ganó o se lo regalamos**.

## Novedad en el modelo

Ninguna. `datos/agrodb_clase7.sql` no agrega una sola tabla: es el modelo de la clase 6 con **el ejercicio 6 ya aplicado**.

- `lecturas` gana `CHECK (valor BETWEEN -50 AND 1500)` y `UNIQUE (sensor_id, fecha_hora)`
- se fueron 4 filas: las 3 lecturas averiadas y la medición duplicada
- de 977 lecturas quedan **973**

Lo que **no** se arregló, y es a propósito: el hueco del sensor 2 (11, 12 y 13 de abril) sigue ahí, porque eso no era un dato malo sino un dato que no existe. Y `lotes.hectareas` sigue con enteros.

> **La limpieza de ayer dejó su propia marca.** Las tres lecturas que borramos eran las tres de madrugada, así que el 19 y el 20 de abril quedaron sin sus horas frías. Buena parte del ejercicio de hoy es descubrir eso solos.

## Entrega

Un archivo `.sql` en `entregas/apellido-nombre/`, por pull request.

> **Un archivo `.sql` de texto.** Si el archivo empieza con `SQLite format 3` o con `<!DOCTYPE html>`, no es una entrega: es una base de datos o una página guardada, y no se puede corregir el razonamiento a partir de ninguna de las dos.
