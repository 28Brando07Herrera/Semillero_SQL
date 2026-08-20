# Clase 9 · Índices: lo que cuesta encontrar algo
**Jueves 20 de agosto**

Una hora de clase y el resto a práctica. Ayer cerramos con una deuda: *"una vista no acelera nada"*. Hoy vemos lo que sí acelera, y por qué a veces no alcanza.

La base de hoy tiene **105.120 filas** en una tabla nueva. Es la primera vez en el curso que hay que esperar a que algo termine.

## Material

| Qué | Dónde |
|---|---|
| Diapositivas | [slides.md](slides.md) · [versión web](https://negatix092.github.io/Semillero_SQL/09-indices.html) |
| Ejercicio práctico | [ejercicio.md](ejercicio.md) |
| Script base (ejecutar primero) | [`datos/agrodb_clase9.sql`](../../datos/agrodb_clase9.sql) |
| Trabajar con SQLite en tu máquina | [`recursos/entorno-local-sqlite.md`](../../recursos/entorno-local-sqlite.md) |

> **Hoy es el día para el entorno local.** No es obligatorio, pero `sqlite3` local trae `.timer on`, que le pone un número a cada consulta. En el navegador se puede hacer todo el ejercicio igual, midiendo a ojo.

## Lo que hay que saber al terminar

- Leer `EXPLAIN QUERY PLAN` y distinguir **`SCAN`** de **`SEARCH`**
- Que `USE TEMP B-TREE` significa que además hubo que ordenar a mano
- Que todo `UNIQUE` y todo `PRIMARY KEY` **ya crea un índice** — vienen usándolos desde la clase 3
- `CREATE INDEX` y `DROP INDEX`, y que **un índice cambia el plan, no el resultado**
- Índices compuestos y la **regla del prefijo izquierdo**: se usan de la primera columna hacia la derecha
- Que una función sobre la columna (`DATE(fecha_hora)`) **anula el índice**, y cómo reescribirla como rango
- Qué es un `COVERING INDEX` y por qué puede aparecer junto a `SCAN`
- Que un índice también sirve para el `ORDER BY` y el `GROUP BY`, no solo para el `WHERE`
- Lo que cuesta un índice: espacio, escrituras más lentas, y alguien que lo mantenga
- Cuándo **no** conviene indexar

## La regla del día

**El reloj es una anécdota. El plan es la evidencia.**

El cronómetro cambia según tu máquina, tu navegador y qué más tengas abierto. `EXPLAIN QUERY PLAN` devuelve lo mismo siempre. Toda afirmación sobre rendimiento va acompañada del plan que la sostiene.

## Novedad en el modelo

Una tabla nueva y cinco vistas.

- **`lecturas_historico`** — 105.120 filas: un año entero, cada 30 minutos, seis sensores. **Sin ningún índice propio**, y eso es el ejercicio.
- Las **cinco vistas del ejercicio 8** ya vienen creadas: `v_lote_finca`, `v_produccion_lote`, `v_produccion_finca`, `v_costo_siembra` y `v_temp_diaria_v2`.

`v_temp_diaria` —la mala, la que no filtra sensores de baja ni expone el conteo— **sigue ahí**. Es la respuesta a la parte C6 de ayer: se depreca, no se borra, porque hay un tablero que la consulta todas las mañanas. Si molesta verla, esa incomodidad es la que siente cualquiera que hereda una base con años encima.

> Las diez tablas del modelo y las 973 filas de `lecturas` **no cambiaron**. Los datos con los que se piensa siguen ahí; `lecturas_historico` es volumen, no información: la curva se repite igual todos los días, a propósito.

## La deuda que se salda hoy

El ejercicio 6 preguntaba, el lunes: *"Nombrá una cosa que va a dejar de funcionar bien a esa escala"*. Hoy se contesta con un plan de ejecución.

## Entrega

Un archivo `.sql` en `entregas/apellido-nombre/`, por pull request.

> **Un archivo `.sql` de texto**, y del ejercicio de hoy. Antes de subirlo, abrilo y comprobá que sea el que quisiste subir.
