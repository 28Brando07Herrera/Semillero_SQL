# Clase 4 · Modificar datos sin romper nada
**Jueves 13 de agosto**

`INSERT`, `UPDATE`, `DELETE`, transacciones y qué le pasa a los datos relacionados cuando borrás una fila.

## Material

| Qué | Dónde |
|---|---|
| Diapositivas | [slides.md](slides.md) · [versión web](https://negatix092.github.io/Semillero_SQL/04-modificar-datos.html) |
| Ejercicio práctico | [ejercicio.md](ejercicio.md) |
| Script base (ejecutar primero) | [`datos/agrodb_clase4.sql`](../../datos/agrodb_clase4.sql) |

## Lo que hay que saber al terminar

- Las tres formas de `INSERT`, y por qué siempre se nombran las columnas
- Correr el `WHERE` como `SELECT` **antes** de cada `UPDATE` o `DELETE`
- `BEGIN` / `COMMIT` / `ROLLBACK`, y por qué una transacción es todo o nada
- `ON DELETE RESTRICT` vs `CASCADE` vs `SET NULL` como decisión de negocio
- Detectar duplicados agrupando por la versión normalizada del dato

## Las dos reglas del día

1. Todo `UPDATE` y todo `DELETE` va dentro de un `BEGIN … COMMIT`.
2. Antes de cada uno, `SELECT COUNT(*)` con el mismo `WHERE`.

## Entrega

Un archivo `.sql` en `entregas/apellido-nombre/`, por pull request.
