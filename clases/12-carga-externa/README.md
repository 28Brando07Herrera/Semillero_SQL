# Clase 12 · Datos que llegan de afuera
**Martes 25 de agosto**

Una hora de clase y el resto a práctica. Segundo día en Oracle: el motor ya no es la novedad, así que hoy se usa para algo que en SQLite se podía hacer a medias y acá se hace bien.

## Material

| Qué | Dónde |
|---|---|
| Diapositivas | [slides.md](slides.md) · [versión web](https://negatix092.github.io/Semillero_SQL/12-carga-externa.html) |
| Ejercicio práctico | [ejercicio.md](ejercicio.md) |
| Script base (ejecutar primero) | [`datos/agrodb_oracle_clase12.sql`](../../datos/agrodb_oracle_clase12.sql) |
| Instalación local de Oracle *(opcional)* | [`recursos/entorno-local-oracle.md`](../../recursos/entorno-local-oracle.md) |

## Entorno

**[Oracle FreeSQL](https://freesql.com)** — gratis, en el navegador, sin instalar nada. El mismo de ayer, con la misma cuenta.

Todo el ejercicio se hace en línea. **No hace falta instalar Oracle.** La [guía local](../../recursos/entorno-local-oracle.md) sigue siendo opcional y sigue conviniendo hacerla después de clase, no durante.

### Cómo se corre el script base

Es idéntico a ayer, y la trampa también:

1. **Guardá primero tu archivo del ejercicio 11.** El script borra y vuelve a crear las tablas.
2. Pegá `datos/agrodb_oracle_clase12.sql` **completo** en el worksheet.
3. **No dejes texto seleccionado.** Clic en el editor para deseleccionar.
4. **Run Script** (`F5`), no **Run Statement** (`Ctrl+Enter`).
5. Mirá **Script output**: `Table ... created`, `1 row inserted`, y al final **trece** números.

> **El error que van a tener sigue siendo `ORA-00942`.** No es el script: es que se corrió solo la verificación del final. Deseleccionar y Run Script otra vez.

> **`DBMS_OUTPUT`:** la pestaña **DBMS output** hay que abrirla y **habilitarla antes** de correr el bloque. En local, `SET SERVEROUTPUT ON`.

## Lo que hay que saber al terminar

- Qué es una tabla de **staging** y por qué **no** valida nada
- Que un staging con clave foránea pierde en silencio la fila que más importa
- `TO_NUMBER(x DEFAULT NULL ON CONVERSION ERROR)` y `TO_DATE(x DEFAULT NULL ON CONVERSION ERROR, fmt)`
- Que eso es la contracara del `WHEN OTHERS THEN NULL` de ayer: el `NULL` está **en la expresión**, no escondido
- Separar **«el archivo estaba mal»** de **«el modelo dijo que no»**, y que son dos llamados telefónicos distintos
- Que un `INSERT ... SELECT` es atómico: una fila mala tira las veinte
- `DBMS_ERRLOG.CREATE_ERROR_LOG` y `LOG ERRORS INTO ... REJECT LIMIT UNLIMITED`
- Por qué la tabla de rechazos guarda **todo como texto**
- Que `LOG ERRORS` hace que la sentencia **termine sin error**, y qué obligación crea eso
- **Idempotencia:** correrlo dos veces y que el estado final sea el mismo
- Que reconciliar con `NOT EXISTS` **no encuentra los duplicados**, y por qué
- `MERGE` con `WHEN MATCHED` / `WHEN NOT MATCHED`, y qué se pierde con «insertá lo que falta»
- Que las secuencias **no vuelven atrás**: `NEXTVAL` se gasta también en las filas que fallan
- Que `NEXTVAL` no se puede usar en un `SELECT` con `ORDER BY`, `GROUP BY`, `DISTINCT` ni `UNION`
- `BULK COLLECT` + `FORALL ... SAVE EXCEPTIONS` y `SQL%BULK_EXCEPTIONS` — la respuesta a la pregunta de ayer
- Variables de enlace: `EXECUTE IMMEDIATE ... USING`, y por qué **nunca** se concatena SQL a mano

## La regla del día

**El dato que llega de afuera no es un dato: es una propuesta.**

Y de ahí sale la segunda, que es la que se toma:

**Un proceso de carga no se juzga por la primera corrida. Se juzga por la segunda.**

## Las tres cosas que son la clase

Si el día se complica y hay que recortar, estas tres no se recortan:

1. **El corte 4 y 4.** De las ocho filas rechazadas, cuatro las rechazó el archivo y cuatro las rechazó el modelo. Son dos problemas distintos con dos responsables distintos, y sin staging son «la carga falló».
2. **La segunda corrida.** El bot se reinicia. La tabla no se duplica —pero no por el código, sino por un `UNIQUE` de la clase 6— y la tabla de rechazos pasa de 8 filas a 28, de las cuales 12 no son errores. La evidencia se ensucia sola.
3. **`1 OR 1=1`.** Le pedís un sensor y te devuelve el mes entero, sin un error. Con `USING`, el mismo texto da `ORA-01722`. No se validó nada: cambió de lugar.

## Lo que se cobra hoy

De la clase 11, la pregunta que quedó abierta al final:

> *«¿Entonces nunca hay que usar bucles?»* — «Cuando cada fila necesita una decisión distinta que SQL no puede expresar. Y ahí, `BULK COLLECT` + `FORALL`.»

Hoy se escribe. Y de paso queda la tabla de las tres formas de cargar el mismo archivo, con la columna que decide: **dónde quedan los errores.**

También se cobra el `WHEN OTHERS` de ayer. La parte D del ejercicio 12 tiene un `WHEN OTHERS` que **sí** está bien puesto, y la consigna es que cada uno lo compare contra la regla que escribió ayer en su propio archivo.

## Novedad en el modelo

Mismo AgroDB. Mismos nueve conteos de siempre —**3, 6, 8, 10, 7, 19, 16, 6, 9**— y las mismas **8.640** lecturas de abril.

`resumen_diario` y `bitacora` vuelven **vacías**: este script no trae resuelto nada del ejercicio 11.

Lo nuevo:

| Objeto | Qué trae |
|---|---|
| `staging_lecturas` | **23 filas**, todo `VARCHAR2`: 20 líneas del archivo del 1 de mayo (8 con defectos) y 3 de la corrección posterior |
| `seq_lecturas` | secuencia que arranca en 8641, para no inventar el `lectura_id` a mano |
| `err_lecturas` | **no viene**: la crean ellos con `DBMS_ERRLOG` en la parte B |

Los números que se mueven hoy: `lecturas` va de **8640** a **8652** al final de la parte B, y a **8654** al final de la parte C.

## Entrega

Un archivo `.sql` en `entregas/apellido-nombre/`, por pull request.

> **El archivo arranca en la parte A.** No se pega el script base adentro de la entrega.

> **Y tiene que correr completo de arriba abajo.** Las partes C y D dependen del estado que dejó la anterior; si alguien volvió atrás a rehacer algo sin recargar la base, se nota. Es el problema del día aplicado a la propia entrega, y por eso puntúa.

## Nota sobre el material

El script base y los ejemplos están escritos contra **Oracle Database 23ai** (FreeSQL, o Oracle 23ai Free en local). `DEFAULT ... ON CONVERSION ERROR` requiere 12.2 o superior; `LOG ERRORS` y `MERGE` son mucho más viejos.

Conviene **correr el script una vez antes de la clase** y comprobar los trece números de control.
