# SQLite en tu propia máquina

Hasta ahora todo el curso corrió en [sqliteonline.com](https://sqliteonline.com), y para las primeras clases estuvo bien: cero instalación, todos con lo mismo, nadie perdió media hora peleando con un instalador.

Pero ya nos queda chico. Esta guía es para pasarse a un SQLite local. **No es obligatorio para entregar**, y sqliteonline va a seguir funcionando para todo lo que hicimos hasta hoy.

---

## Por qué conviene ahora

| En sqliteonline | En local |
|---|---|
| Cerrás la pestaña y perdiste la base | La base es un archivo `.db` que queda en tu disco |
| Volvés a pegar el script cada vez | `.read agrodb_clase8.sql` y listo |
| Escribís en un editor que no es un editor | Tu `.sql` es un archivo de texto de verdad |
| Bajar el trabajo te da un `.db` o una página guardada | Guardás el `.sql` y eso es exactamente lo que se entrega |
| 973 lecturas van bien | **100.000 lecturas también** |

Ese último renglón es el que importa esta semana: en la clase de índices vamos a generar cien mil lecturas y a medir cuánto tarda una consulta antes y después de indexar. Eso en una pestaña del navegador no se puede medir en serio.

> **Y si alguna vez entregaste un archivo que no era `.sql`:** el problema no fuiste vos, fue que sqliteonline no te da otra cosa fácil de bajar. Trabajando local, tu entrega **es** el archivo en el que escribís. El problema desaparece solo.

---

## Opción A · DB Browser for SQLite (recomendada)

Es una ventana con las tablas a la izquierda, una pestaña para escribir SQL y otra para navegar los datos. Es lo más parecido a sqliteonline, pero tuyo.

1. Entrá a **<https://sqlitebrowser.org/dl/>**
2. Bajá la versión para Windows de 64 bits. Hay dos:
   - el **instalador** (`.msi`), si podés instalar programas en tu máquina;
   - la **versión portable** (un `.zip`), que se descomprime y se ejecuta sin instalar nada. Si estás en una máquina de la empresa y el instalador te pide permisos que no tenés, usá esta.
3. Abrilo → **Nueva base de datos** → guardala como `agrodb.db` en tu carpeta del curso.
4. Pestaña **Ejecutar SQL** → pegá `agrodb_clase8.sql` → botón de ejecutar (o `Ctrl+Return`).
5. **Escribir Cambios** (`Write Changes`). Este paso es el que la gente olvida: hasta que no lo apretás, lo que hiciste no está guardado en el archivo.

Con eso ya tenés la base en disco. Mañana la abrís y está todo.

---

## Opción B · `sqlite3` por línea de comandos

Más liviano, y es la forma en que vas a ver SQLite en cualquier servidor.

1. Entrá a **<https://sqlite.org/download.html>**
2. Buscá la sección **Precompiled Binaries for Windows** y bajá el zip que empieza con `sqlite-tools-win-x64` (el número del final cambia con cada versión).
3. Descomprimilo en una carpeta, por ejemplo `C:\sqlite\`. Adentro está `sqlite3.exe`. No hay instalador: eso es todo.
4. Abrí una terminal en tu carpeta del curso y ejecutá:

```bash
C:\sqlite\sqlite3.exe agrodb.db
```

Ya estás adentro. Los comandos que empiezan con punto son del programa, no SQL:

| Comando | Qué hace |
|---|---|
| `.read agrodb_clase8.sql` | ejecuta un archivo `.sql` entero |
| `.tables` | lista las tablas **y las vistas** |
| `.schema lecturas` | te muestra el `CREATE TABLE` de esa tabla |
| `.headers on` | muestra los nombres de las columnas |
| `.mode box` | dibuja los resultados en una tabla con bordes |
| `.timer on` | **te dice cuánto tardó cada consulta** |
| `.output salida.txt` | manda los resultados a un archivo |
| `.quit` | salir |

Las dos primeras que conviene correr siempre, apenas entrás:

```
.headers on
.mode box
```

> `.timer on` es la que vamos a usar en la clase de índices. Es la que convierte "esto va lento" en un número.

---

## Opción C · Ya tenés Python

Si tenés Python instalado, ya tenés SQLite: viene adentro. No sirve como entorno de trabajo cómodo, pero sirve para verificar algo rápido.

```bash
python -c "import sqlite3; print(sqlite3.sqlite_version)"
```

---

## Y ahora sí: las fechas

Esta es la pregunta que aparece siempre, y la respuesta es incómoda pero corta.

### SQLite no tiene tipo fecha

No lo tiene local, no lo tiene en sqliteonline, no lo tiene en ningún lado. SQLite guarda exactamente **cinco** clases de valores:

```
NULL · INTEGER · REAL · TEXT · BLOB
```

`DATE`, `DATETIME`, `TIMESTAMP` y `BOOLEAN` **se pueden escribir** en un `CREATE TABLE` y no dan error. Pero son etiquetas: SQLite se las anota y guarda el valor como texto o como número igual.

Probalo, en local o donde sea:

```sql
CREATE TABLE prueba (a DATETIME, b DATE, c TIMESTAMP, d BOOLEAN);
INSERT INTO prueba VALUES ('2026-04-20 03:00:00', '2026-04-20',
                           '2026-04-20 03:00:00', 1);
SELECT typeof(a), typeof(b), typeof(c), typeof(d) FROM prueba;
```
```
text | text | text | integer
```

Declaramos tres columnas de fecha y SQLite guardó tres textos.

### Entonces, ¿cómo hicimos funcionar `DATE()` y `julianday()` en las clases 6 y 7?

Porque nuestro `fecha_hora` es **texto en formato ISO-8601**: `2026-04-20 03:00:00`. Año, mes, día, con ceros adelante y en ese orden. Y las funciones de fecha de SQLite trabajan sobre ese formato.

Ese formato tiene una propiedad que lo hace funcionar:

```sql
SELECT '2026-04-09 21:00:00' < '2026-04-10 00:00:00';   -- 1 (verdadero)
```

Ordenado como texto, queda ordenado como fecha. Por eso `ORDER BY fecha_hora` funciona, y por eso `LAG(fecha_hora) OVER (ORDER BY fecha_hora)` de la clase 7 daba lo correcto.

**Y por eso el formato importa tanto.** Mirá lo que pasa con una fecha escrita como la escribimos las personas:

```sql
SELECT date('20/04/2026');
```
```
NULL
```

No da error. Devuelve `NULL` y sigue. Ese `NULL` después se propaga por toda la consulta, y a nadie le avisa nada.

### Lo que sí podés hacer

Las funciones andan igual en local que en la web:

```sql
SELECT date('2026-04-20 03:00:00');                    -- 2026-04-20
SELECT datetime('2026-04-20 03:00:00', '+2 hours');    -- 2026-04-20 05:00:00
SELECT strftime('%H', '2026-04-20 03:00:00');          -- 03
SELECT julianday('2026-04-20') - julianday('2026-04-19');  -- 1.0
SELECT unixepoch('2026-04-20 03:00:00');               -- 1776654000
SELECT datetime(1776654000, 'unixepoch');              -- 2026-04-20 03:00:00
```

Las tres formas aceptadas de guardar un instante en SQLite son:

| Cómo | Ejemplo | Cuándo |
|---|---|---|
| **TEXT ISO-8601** | `'2026-04-20 03:00:00'` | por defecto. Es lo que usamos, y es legible |
| INTEGER (epoch) | `1776654000` | cuando importa el espacio o venís de otro sistema |
| REAL (día juliano) | `2461150.625` | casi nunca a mano |

### Lo que **no** vas a conseguir instalando SQLite

Una columna que rechace `'20/04/2026'`, o que sepa de zonas horarias, o que te devuelva un objeto fecha en vez de un texto. Eso no es cuestión de local contra web: SQLite no lo tiene.

Un motor con tipos de fecha de verdad —`DATE`, `TIMESTAMP WITH TIME ZONE`, validación al insertar— es **PostgreSQL**, y es justamente lo que sigue después de este curso.

### Lo que local sí te da para entender esto

`typeof()` es la herramienta, y sirve para algo más que fechas. Probá esto sobre AgroDB:

```sql
SELECT codigo, hectareas, typeof(hectareas) FROM lotes;
```
```
L-01   28.5   real
L-02   31     integer     <-- acá está el problema del * 1.0
L-03   19.25  real
L-01   22     integer
```

**Ahí está, con nombre y apellido, la trampa que venimos arrastrando desde la clase 5.** La columna está declarada `NUMERIC(10,2)`, pero SQLite guardó `31` como entero porque `31.00` es un entero exacto. Y entero dividido entero da entero.

Eso explica también por qué `CAST(x AS NUMERIC)` no arregla nada: `NUMERIC` es una *afinidad*, una preferencia, no un tipo. Lo que fuerza el decimal es `* 1.0` o `CAST(x AS REAL)`.

Y para ver qué declaró cada columna:

```sql
PRAGMA table_info(lotes);
```

---

## Si te pasás a local, no cambia nada de la entrega

Mismo repositorio, mismo pull request, mismo `entregas/apellido-nombre/`, mismo archivo `Ejercicio8_Apellido_Nombre.sql`. Ver [CONTRIBUTING.md](../CONTRIBUTING.md).

Lo que **no** se sube nunca es el archivo `.db`: es la base, no tu trabajo, y ya está en el `.gitignore` del repo. Lo que se entrega es siempre el `.sql`.

---

## La regla de los 20 minutos también vale acá

Si llevás veinte minutos peleando con la instalación: volvé a sqliteonline, hacé el ejercicio, y lo vemos juntos después. **La instalación no es parte de la nota.**
