# Clase 10 · Calidad de datos y auditoría
**Viernes 21 de agosto**

Una hora de clase y el resto a práctica. **Es la última sesión técnica del curso**: la semana que viene son integración, preguntas de negocio y el taller de proyecto.

Y es la clase que ustedes pidieron tres veces sin saberlo.

## Material

| Qué | Dónde |
|---|---|
| Diapositivas | [slides.md](slides.md) · [versión web](https://negatix092.github.io/Semillero_SQL/10-calidad-auditoria.html) |
| Ejercicio práctico | [ejercicio.md](ejercicio.md) |
| Script base (ejecutar primero) | [`datos/agrodb_clase10.sql`](../../datos/agrodb_clase10.sql) |

## Lo que ya escribieron ustedes

- **Ejercicio 6, parte E:** *"si agregás las restricciones hoy, ¿qué pasa con las filas malas que ya están?"*
- **Ejercicio 7, parte C4:** *"¿qué habría que haber guardado para que dentro de seis meses alguien sepa que ahí hubo una medición y que la borramos a propósito?"*
- **Ejercicio 8, parte C6:** *"el tablero la consulta todas las mañanas. ¿Qué pasa mañana a las 7?"*

Las cinco entregas del ejercicio 6 contestaron lo mismo: **una columna de estado, o una bitácora de descartes.** Hoy la construimos — y descubrimos qué parte de eso el motor no puede cumplir.

## Lo que hay que saber al terminar

- Que **los datos malos no dan error**, y que el motor solo defiende de lo que viola una regla escrita
- `PRAGMA foreign_key_check` y por qué se corre el día que heredás una base
- Detectar duplicados lógicos (`GROUP BY … HAVING COUNT(*) > 1`), fechas imposibles y `NULL` sospechosos
- Distinguir un `NULL` que es un dato faltante de uno que es una respuesta legítima
- Qué **puede** y qué **no puede** expresar un `CHECK`: solo su propia fila, y solo con funciones deterministas
- `CREATE TRIGGER`: `BEFORE` / `AFTER` / `INSTEAD OF`, y `OLD.` / `NEW.`
- Que un trigger dispara **por fila**, no por sentencia
- `AFTER` para **registrar**; `BEFORE` + `RAISE(ABORT, …)` para **impedir**
- `INSTEAD OF` para hacer escribible una vista — el error de la clase 8, resuelto
- **Que SQLite no tiene `CURRENT_USER`:** el "cuándo" sale gratis, el "quién" no existe en el motor
- Lo que una bitácora **no** ve, y por qué es una facilidad y no una garantía

## La regla del día

**Los datos malos no dan error.**

Una cosecha anterior a su siembra, una labor cargada dos veces, una fecha en 2027: ninguna rompe una restricción, y las tres se suman al reporte sin pestañear.

## Novedad en el modelo

**Cinco filas que no deberían estar.** Entraron el fin de semana por una carga masiva con `PRAGMA foreign_keys = OFF`. El script base **no dice cuáles son**: encontrarlas es la parte A.

Lo único que la base tuvo para avisar fue el control de carga:

```
siembras   10 -> 11      labores   19 -> 21      cosechas   9 -> 11
```

Y ya movieron todos los números que se saben de memoria: el total de kilos del ejercicio 5 pasó de **30550** a **33750**… o a **31350**, según con qué consulta lo pidan. **Los dos están bien calculados.**

También vienen los dos índices del ejercicio 9 ya creados.

> Cuando la limpieza esté hecha, los dos totales vuelven a coincidir en **30550** y `v_costo_siembra` en **3562.30**. Un número viejo que vuelve a dar es la mejor prueba de que terminaste.

## Entrega

Un archivo `.sql` en `entregas/apellido-nombre/`, por pull request.

> **Un archivo `.sql` de texto**, y del ejercicio de hoy. Antes de subirlo, abrilo y comprobá que sea el que quisiste subir.
