# Clase 6 · Datos de sensores: el tiempo como problema
**Lunes 17 de agosto**

La primera tabla del curso que no cabe en la pantalla: 977 lecturas de sensores. Funciones de fecha en SQLite, promedios por día y por hora, y cuatro formas de que una serie de tiempo mienta sin dar error.

## Material

| Qué | Dónde |
|---|---|
| Diapositivas | [slides.md](slides.md) · [versión web](https://negatix092.github.io/Semillero_SQL/06-series-de-tiempo.html) |
| Ejercicio práctico | [ejercicio.md](ejercicio.md) |
| Script base (ejecutar primero) | [`datos/agrodb_clase6.sql`](../../datos/agrodb_clase6.sql) |

## Lo que hay que saber al terminar

- Que en SQLite una fecha es **texto**, y por qué el formato ISO no era una cuestión de estilo
- `DATE()`, `strftime()`, `julianday()` y `datetime()`: cuál usar para qué
- Agrupar una serie por día y por hora del día, y leer la curva que sale
- **Por qué `BETWEEN` con fecha suelta se come el último día del mes**, y qué escribir en su lugar
- Buscar `MIN` y `MAX` **antes** que `AVG`, para que un código de falla no se disfrace de dato
- Que un `GROUP BY` no puede encontrar un día que no tiene ninguna fila
- Generar un calendario con `WITH RECURSIVE` y restarle lo que hay, para encontrar huecos
- Detectar duplicados con el mismo `GROUP BY … HAVING` de la clase 4, sobre una tabla nueva
- `CASE` para convertir un número en una alerta

## La regla del día

**Ningún promedio se entrega sin su `COUNT(*)` al lado.** En la clase 5 el conteo servía para detectar filas de más; hoy sirve para detectar filas de menos.

## Novedad en el modelo

`datos/agrodb_clase6.sql` agrega la tabla **`lecturas`** (una fila por medición, cada 3 horas durante todo abril) y deja el resto del modelo igual que en la clase 5.

La tabla se carga con un `WITH RECURSIVE` en vez de con mil `INSERT`, y trae **cuatro problemas de calidad metidos a propósito**. No están marcados: encontrarlos es el ejercicio.

## Entrega

Un archivo `.sql` en `entregas/apellido-nombre/`, por pull request.

> **Un archivo `.sql` de texto**, no la base exportada desde sqliteonline. Si el archivo empieza con `SQLite format 3` en vez de con un comentario, no es una entrega: es una base de datos, y no se puede corregir el razonamiento a partir de ella.
