# Clase 3 · Del requerimiento al modelo de datos
**Martes 11 de agosto**

Cómo se pasa de un documento escrito en prosa a un modelo de tablas: entidades, atributos, cardinalidad y la relación muchos-a-muchos.

## Material

| Qué | Dónde |
|---|---|
| Diapositivas | [slides.md](slides.md) · [versión web](https://negatix092.github.io/Semillero_SQL/03-modelado.html) |
| Ejercicio práctico | [ejercicio.md](ejercicio.md) |
| Script base (ejecutar primero) | [`datos/agrodb_nucleo.sql`](../../datos/agrodb_nucleo.sql) |

## Lo que hay que saber al terminar

- Distinguir una entidad de un atributo, y poder justificar la diferencia
- De qué lado de la relación va la clave foránea, y por qué
- Por qué una relación N:M necesita una tabla puente, y por qué esa tabla tiene columnas propias
- Reconocer una tabla mal normalizada mirándola
- `CHECK`, `UNIQUE` sobre varias columnas, `DEFAULT` y `PRAGMA foreign_keys = ON`

## Entrega

Un archivo `.sql` en `entregas/apellido-nombre/`, por pull request.
El paso a paso está en [CONTRIBUTING.md](../../CONTRIBUTING.md).
