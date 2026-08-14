# Clase 5 · Consultar el modelo propio
**Viernes 14 de agosto**

JOIN de cuatro y cinco tablas sobre el modelo que ustedes diseñaron, el `SUM` que se infla sin avisar, y `LEFT JOIN` para encontrar lo que falta.

## Material

| Qué | Dónde |
|---|---|
| Diapositivas | [slides.md](slides.md) · [versión web](https://negatix092.github.io/Semillero_SQL/05-consultar-modelo.html) |
| Ejercicio práctico | [ejercicio.md](ejercicio.md) |
| Script base (ejecutar primero) | [`datos/agrodb_clase5.sql`](../../datos/agrodb_clase5.sql) |

## Lo que hay que saber al terminar

- Leer un JOIN de cinco tablas como un camino sobre el modelo, no como cinco tablas sueltas
- Reconocer el **fan-out**: unir dos tablas hijas del mismo padre multiplica las filas y el `SUM` miente
- Detectarlo con `COUNT(*)` y corregirlo agregando **antes** de unir
- Que un `JOIN` interno también borra filas en silencio (las labores sin insumos)
- Que en SQLite `entero / entero` da entero, y que eso rompe un `kg/ha` sin dar error
- `LEFT JOIN` + `WHERE hijo IS NULL` para preguntar por lo que **no** está
- Por qué la condición sobre la tabla derecha va en el `ON` y no en el `WHERE`
- Los nombres formales: 1FN, 2FN y 3FN, aplicados a lo que ya normalizaron en la clase 3

## La regla del día

**Antes de cada `SUM`, corré la misma consulta con `COUNT(*)`.** Si hay más filas de las que esperabas, el número está inflado.

## Novedad en el modelo

`datos/agrodb_clase5.sql` agrega la tabla **`cosechas`** (una siembra puede rendir varias) y trae el lote de abril ya limpio, con todos los jornales cargados.

## Entrega

Un archivo `.sql` en `entregas/apellido-nombre/`, por pull request.
