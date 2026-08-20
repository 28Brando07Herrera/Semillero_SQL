# Clase 8 · Vistas: la consulta que se queda
**Miércoles 19 de agosto**

Una hora de clase y el resto a práctica. Ayer escribieron veinte consultas buenas; hoy la base no se acuerda de ninguna. Una **vista** es un `SELECT` guardado con nombre: se consulta como si fuera una tabla, no ocupa espacio y no guarda datos — guarda **la pregunta**.

Y con eso viene el problema del día: cuando una consulta se convierte en la fuente oficial de un número, sus errores también se vuelven oficiales.

## Material

| Qué | Dónde |
|---|---|
| Diapositivas | [slides.md](slides.md) · [versión web](https://negatix092.github.io/Semillero_SQL/08-vistas.html) |
| Ejercicio práctico | [ejercicio.md](ejercicio.md) |
| Script base (ejecutar primero) | [`datos/agrodb_clase8.sql`](../../datos/agrodb_clase8.sql) |
| Trabajar con SQLite en tu máquina | [`recursos/entorno-local-sqlite.md`](../../recursos/entorno-local-sqlite.md) |

## Lo que hay que saber al terminar

- Que un `SELECT` no deja rastro, y que por eso existe `CREATE VIEW`
- Que una vista guarda **la pregunta**, no la respuesta: si cambian los datos, cambia la vista
- Consultar una vista igual que una tabla, y construir **una vista sobre otra**
- Leer la definición de una vista ajena con `SELECT sql FROM sqlite_master WHERE type='view'`
- Que SQLite **no tiene** `CREATE OR REPLACE VIEW`: se hace `DROP VIEW IF EXISTS` + `CREATE VIEW`
- Que `CREATE VIEW IF NOT EXISTS` no reemplaza nada y **no avisa**
- Que una vista es de solo lectura: `cannot modify … because it is a view`
- Que una vista **no se indexa** y por lo tanto **no acelera nada**
- Que una vista se crea aunque su tabla no exista: el error llega recién cuando alguien la consulta
- Auditar una vista heredada: qué filtra, qué no filtra y qué columna decidió no mostrar

## La regla del día

**Una vista es una opinión con nombre.**

El que la consulta hereda todas tus decisiones —qué filtraste, qué agrupaste, qué columna elegiste no mostrar— y no tiene forma de saber cuáles fueron. Lo que una vista no muestra deja de existir para el que la usa.

## Novedad en el modelo

Ninguna otra vez. `datos/agrodb_clase8.sql` trae **las mismas 10 tablas y las mismas 973 lecturas** que la clase 7, hasta el último dígito del control. Eso es a propósito: es la prueba de que las veinte consultas de ayer no dejaron rastro.

Lo único nuevo son **dos vistas** que ya vienen creadas y que no escribió nadie del curso:

- `v_temp_diaria` — el promedio de temperatura por día
- `v_alertas_sensores` — las lecturas que pasaron un umbral

Las dos corren sin error, las dos devuelven algo razonable, y **una de las dos está mal desde el día que se escribió**. La parte C del ejercicio es encontrar cuál y por qué. Mirándolas por afuera no se distingue: hay que abrirlas.

> El control ahora tiene **once** números en vez de diez. El que se agregó es la cantidad de vistas.

## Entrega

Un archivo `.sql` en `entregas/apellido-nombre/`, por pull request.

> **Un archivo `.sql` de texto.** Si el archivo empieza con `SQLite format 3` o con `<!DOCTYPE html>`, no es una entrega: es una base de datos o una página guardada, y no se puede corregir el razonamiento a partir de ninguna de las dos. Si te pasó eso antes, mirá la guía de [entorno local](../../recursos/entorno-local-sqlite.md): trabajando en un archivo `.sql` de verdad el problema desaparece solo.
