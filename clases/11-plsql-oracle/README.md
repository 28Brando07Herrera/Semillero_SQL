# Clase 11 · PL/SQL sobre Oracle
**Lunes 24 de agosto**

Una hora de clase y el resto a práctica. **Es la primera clase fuera de SQLite**, y el motor no es un detalle: la mitad de lo que escribieron en diez clases no corre acá.

## Material

| Qué | Dónde |
|---|---|
| Diapositivas | [slides.md](slides.md) · [versión web](https://negatix092.github.io/Semillero_SQL/11-plsql-oracle.html) |
| Ejercicio práctico | [ejercicio.md](ejercicio.md) |
| Script base (ejecutar primero) | [`datos/agrodb_oracle_clase11.sql`](../../datos/agrodb_oracle_clase11.sql) |
| Instalación local de Oracle | [`recursos/entorno-local-oracle.md`](../../recursos/entorno-local-oracle.md) |

## Entorno

**[Oracle FreeSQL](https://freesql.com)** — gratis, en el navegador, sin instalar nada. Es el `sqliteonline.com` de hoy. Es el servicio que reemplazó a Oracle Live SQL: si tenías guardado `livesql.oracle.com`, ese link ya no es el bueno.

Todo el ejercicio se hace en línea. **No hace falta instalar Oracle.**

### Cómo se corre el script base

1. Pegá `datos/agrodb_oracle_clase11.sql` **completo** en el worksheet.
2. **No dejes texto seleccionado.** Si hay una selección, el worksheet ejecuta *solo lo seleccionado*. Hacé clic en el editor para deseleccionar.
3. **Run Script** (`F5`) — no **Run Statement** (el triángulo, `Ctrl+Enter`), que ejecuta una sola sentencia.
4. Mirá la pestaña **Script output**: tiene que llenarse de `Table ... created` y `1 row inserted`.

> **El error que van a tener:** `ORA-00942: table or view "FINCAS" does not exist`. No es un problema del script — es que se corrió solo la consulta de verificación del final, sin haber creado las tablas. Deseleccionar y Run Script otra vez.

> La [guía de Oracle local](../../recursos/entorno-local-oracle.md) está para el que quiera instalarlo en su máquina. **No es obligatoria** y conviene hacerla después de clase, no durante: la descarga son varios gigas.

## Lo que hay que saber al terminar

- Que **el SQL que saben es en parte SQLite**, y cuál parte
- Las cuatro que se rompen: `SELECT` sin `FROM`, `LIMIT`, `DROP ... IF EXISTS`, `DATE()`
- `dual`, `FETCH FIRST n ROWS ONLY`, `TRUNC()`, `DATE 'aaaa-mm-dd'`, `INSERT ALL`
- Que en Oracle **la cadena vacía es `NULL`**, y qué se pierde con eso
- Que el `* 1.0` de la clase 5 era una defensa contra SQLite, no una regla de SQL
- Que ventanas, CTE, `LEFT JOIN`, vistas e índices **se transfieren enteros**
- Anatomía de un bloque: `DECLARE` / `BEGIN` / `EXCEPTION` / `END;` y la `/`
- `SELECT ... INTO`, `%TYPE`, `%ROWTYPE`, `DBMS_OUTPUT` y `SET SERVEROUTPUT ON`
- Que `SELECT ... INTO` exige **exactamente una fila**: `NO_DATA_FOUND` y `TOO_MANY_ROWS`
- El cursor `FOR` loop, y **cuándo no usarlo**
- **El context switch**: por qué un bucle con SQL adentro cuesta 180 veces más que una sentencia
- Que el plan de ejecución **no muestra cuántas veces** se ejecuta algo
- Excepciones con nombre, `PRAGMA EXCEPTION_INIT`, `SQLCODE` / `SQLERRM`, `RAISE_APPLICATION_ERROR`
- Por qué **`WHEN OTHERS THEN NULL`** es la línea más cara de la industria
- `CREATE OR REPLACE`, procedimientos vs. funciones
- Triggers con `:NEW` / `:OLD` e `INSERTING` / `UPDATING` / `DELETING`
- **Que Oracle sí tiene `USER`:** la bitácora de la clase 10, por fin completa

## La regla del día

**En SQL le pedís un resultado. En PL/SQL le dictás un procedimiento.**

Y todo lo que le dictás, lo hace: incluidas las ciento ochenta vueltas que no hacían falta, y el error que le pediste que ignore.

## Las tres cosas que son la clase

Si el día se complica y hay que recortar, estas tres no se recortan:

1. **El `* 1.0`.** Diez clases escribiendo un parche cuyo motivo era del motor y no del lenguaje. Nadie preguntó nunca por qué.
2. **El context switch.** Dos formas de llenar la misma tabla con las mismas 180 filas: una lee 8.640 filas, la otra 1.555.200. Los dos planes de ejecución son idénticos.
3. **Las cuatro labores.** Se cargan cuatro, entran dos, no hay ni un error. Es la clase 8, la 9 y la 10 otra vez, con una línea nueva que tiene nombre: `WHEN OTHERS THEN NULL`.

## Lo que se cobra hoy

De la clase 10:

> *"SQLite no tiene `CURRENT_USER`: el cuándo sale gratis, el quién no existe en el motor."*

Oracle lo tiene. `SELECT USER FROM dual`. La bitácora que quedó coja el viernes se completa hoy — con la misma advertencia de entonces: sigue siendo una facilidad, no una garantía.

## Novedad en el modelo

Mismo AgroDB, traducido. Los nueve conteos de siempre siguen dando **3, 6, 8, 10, 7, 19, 16, 6, 9**, y `SUM(kg)` sigue siendo **30550**.

Lo nuevo:

| Tabla | Qué trae |
|---|---|
| `lecturas` | **8.640 filas**, abril 2026 completo, seis sensores cada 30 min — generadas con `CONNECT BY`, sin un solo `INSERT` a mano |
| `resumen_diario` | **vacía**. Hoy se llena dos veces, de dos maneras, y se comparan |
| `bitacora` | **vacía**, y con una columna `usuario` que esta vez se puede llenar |

## Entrega

Un archivo `.sql` en `entregas/apellido-nombre/`, por pull request.

> **El archivo arranca en la parte A.** No se pega el script base adentro de la entrega: si el enunciado cambia un dato, tu entrega estaría contestando sobre otra base y nadie se enteraría.

## Nota sobre el material

El script base y los ejemplos están escritos contra **Oracle Database 23ai** (FreeSQL, o Oracle 23ai Free en local). La sintaxis usada es conservadora a propósito —nada posterior a 12c salvo `FETCH FIRST` e `IDENTITY`— pero conviene **correr el script una vez antes de la clase** y comprobar los doce números de control.
