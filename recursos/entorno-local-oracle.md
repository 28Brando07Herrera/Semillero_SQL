# Oracle en tu propia máquina

La clase 11 corre en [Oracle Live SQL](https://livesql.oracle.com), que es gratis, va en el navegador y no requiere instalar nada. **Para entregar el ejercicio alcanza con eso.**

Esta guía es para el que quiera tener Oracle propio. No es obligatoria, y **no la hagas durante la clase**: la descarga son varios gigas y te vas a perder la práctica.

---

## Antes de decidir: ¿lo necesitás?

| | Live SQL | Oracle local |
|---|---|---|
| Instalar | nada | 2 a 5 GB |
| Empezar | dos minutos | media hora larga |
| `SET SERVEROUTPUT ON` | ya viene prendido | lo ponés vos |
| Tu base al día siguiente | las sesiones se reciclan | queda |
| Medir tiempos en serio | más o menos | sí |
| Cargar millones de filas | no | sí |
| Ver el plan con `DBMS_XPLAN` | sí | sí |
| `PRAGMA AUTONOMOUS_TRANSACTION`, jobs, packages grandes | limitado | completo |

> **Regla práctica:** si el ejercicio de hoy te alcanzó con Live SQL, no instales nada todavía. Instalá cuando te choques con un límite de verdad, no antes.

---

## Opción A · Oracle Database 23ai Free en Docker (la más limpia)

Si ya tenés Docker (o Docker Desktop en Windows), es la opción con menos rastro: todo queda adentro de un contenedor y se borra con un comando.

```bash
docker run -d --name oracle-free \
  -p 1521:1521 \
  -e ORACLE_PWD=Agrodb2026 \
  container-registry.oracle.com/database/free:latest
```

La primera vez tarda: la imagen son unos 2 GB y después el contenedor se inicializa solo. Mirá cuándo está listo:

```bash
docker logs -f oracle-free
```

Cuando aparezca `DATABASE IS READY TO USE!`, ya está.

Datos de conexión:

| | |
|---|---|
| host | `localhost` |
| puerto | `1521` |
| service name | `FREEPDB1` |
| usuario | `system` |
| contraseña | la que pusiste en `ORACLE_PWD` |

Para entrar por consola sin instalar nada más:

```bash
docker exec -it oracle-free sqlplus system/Agrodb2026@localhost:1521/FREEPDB1
```

Para apagarlo y encenderlo (los datos quedan):

```bash
docker stop oracle-free
docker start oracle-free
```

Para borrar todo rastro:

```bash
docker rm -f oracle-free
docker rmi container-registry.oracle.com/database/free:latest
```

---

## Opción B · Instalador de Windows

Si no podés usar Docker, Oracle publica un instalador para Windows.

1. Entrá a **<https://www.oracle.com/database/free/get-started/>**
2. Bajá **Oracle Database 23ai Free** para Windows x64. Hace falta una cuenta de Oracle (gratuita, la misma de Live SQL).
3. Descomprimí y ejecutá `setup.exe`. Te va a pedir **una sola cosa**: la contraseña de administrador. Anotala, no la vas a poder recuperar.
4. Al terminar, el service name es `FREEPDB1` y el puerto `1521`.

> **Requisitos reales:** unos 12 GB de disco libres y 2 GB de RAM disponibles. Si tu máquina es justa, andá por Docker o quedate en Live SQL.

> **Si estás en una máquina de la empresa** y el instalador te pide permisos de administrador que no tenés: no hay versión portable de Oracle. Live SQL es tu opción.

---

## Un cliente para escribir SQL

El motor solo te da `sqlplus`, que funciona pero es de 1985. Elegí uno:

### SQLcl (recomendado, y es un `.zip`)

Es `sqlplus` moderno: historial, autocompletado, formatos de salida y `INFORMATION` de tablas. Es Java puro, no se instala.

1. **<https://www.oracle.com/database/sqldeveloper/technologies/sqlcl/download/>**
2. Descomprimilo, por ejemplo en `C:\sqlcl\`
3. Necesita Java 11 o superior. Si no lo tenés: <https://adoptium.net>

```bash
C:\sqlcl\bin\sql system/Agrodb2026@localhost:1521/FREEPDB1
```

Ya adentro:

```sql
SET SERVEROUTPUT ON
@agrodb_oracle_clase11.sql
```

| Comando | Qué hace |
|---|---|
| `@archivo.sql` | ejecuta un archivo entero (el `.read` de SQLite) |
| `SET SERVEROUTPUT ON` | **muestra lo que imprime `DBMS_OUTPUT`** |
| `SET TIMING ON` | te dice cuánto tardó cada sentencia |
| `SET PAGESIZE 200` | deja de repetir los encabezados cada 14 filas |
| `SET LINESIZE 200` | deja de cortar las filas anchas |
| `DESC lecturas` | te muestra las columnas de la tabla |
| `INFO lecturas` | columnas, índices, restricciones y claves, todo junto |
| `EXPLAIN PLAN FOR ...` + `SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);` | el plan |
| `EXIT` | salir |

Las tres primeras conviene ponerlas siempre, apenas entrás.

### VS Code

Si ya usás VS Code, la extensión **Oracle SQL Developer for VS Code** (de Oracle) te da un editor con conexión, autocompletado y el resultado en una grilla. Es lo más parecido a Live SQL, pero tuyo.

Buscala en el panel de extensiones como `Oracle.oracledevtools`.

### SQL Developer (el clásico)

Aplicación de escritorio con árbol de objetos y todo lo demás. Es pesada y hoy la mayoría prefiere las dos anteriores, pero si te gustan las interfaces gráficas completas está en la misma página de descargas.

---

## Cargar la base del curso

Con cualquiera de los tres clientes:

1. Descargá `datos/agrodb_oracle_clase11.sql` del repositorio.
2. Conectate.
3. `SET SERVEROUTPUT ON`
4. `@ruta/al/agrodb_oracle_clase11.sql`
5. Comprobá los doce números: **3, 6, 8, 10, 7, 19, 16, 6, 9, 8640, 0, 0**

---

## Las tres cosas que te van a pasar

**1. No ves nada de lo que imprimís.**
Falta `SET SERVEROUTPUT ON`. Es por sesión: si te reconectás, se apaga. Es el error número uno de todos los que arrancan con PL/SQL.

**2. El bloque se queda esperando y parece colgado.**
Falta la `/` sola en una línea al final. Adentro de un bloque hay puntos y comas, así que el `;` no alcanza para decir «terminó»: eso lo dice la barra.

**3. `ORA-12541: TNS:no listener`.**
El motor no está levantado. En Docker: `docker start oracle-free` y esperá a que los logs digan que está listo. En Windows: revisá que el servicio `OracleServiceFREE` esté iniciado.

---

## Lo que Live SQL no te deja hacer

Por si te preguntás qué te estás perdiendo:

- **Transacciones autónomas** (`PRAGMA AUTONOMOUS_TRANSACTION`) — la forma correcta de que la bitácora sobreviva a un `ROLLBACK`, que aparece en la parte D del ejercicio 11.
- **`DBMS_SCHEDULER`** — tareas programadas.
- **Cargas grandes** — Live SQL corta las ejecuciones largas.
- **Tu base al día siguiente** — el script se guarda, la base no siempre.

Ninguna hace falta para el ejercicio 11. Todas hacen falta si esto lo vas a usar en serio.
