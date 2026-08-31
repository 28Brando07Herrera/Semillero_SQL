# Ejercicio práctico 13 · Tu propio Oracle, y Power BI leyendo de él
**Duración: 2 horas · Individual · En tu computadora (Windows) · Entrega: un archivo `.sql` y una captura**

---

## Qué vas a lograr hoy

Al terminar vas a tener, en tu máquina:

1. **Oracle Free** corriendo en un contenedor de Docker, con su puerto abierto.
2. **AgroDB** cargada, con los mismos trece números de control de ayer.
3. Una **vista de reporte** y un **usuario de sólo lectura** que únicamente puede ver esa vista.
4. **Power BI Desktop** conectado a esa base, con una gráfica de kilos por finca.

**El número que prueba que todo salió bien es 30 550.** Es la suma de kilos que conoces desde la clase 5. Si tu gráfica de Power BI da eso, la cadena completa funciona.

---

## Antes de empezar

**Revisa esto antes de bajar nada:**

| | |
|---|---|
| Windows 10 u 11 de 64 bits | |
| **10 GB** de disco libre | |
| 2 GB de RAM disponibles | |
| **Docker Desktop** instalado y abierto | |
| Power BI Desktop instalado, de 64 bits | |
| Permisos de administrador | **sólo** para el driver de la parte D |

> **Docker Desktop se instala por usuario y no pide administrador**, así que el motor lo puedes levantar aunque tu máquina esté bloqueada. Si te frenan en el driver de la parte D, ve al **Plan B** que está hasta el final: se califica igual.

**Comprueba Docker ahorita mismo**, antes de leer lo demás:

```
docker version
```

Si salen los dos bloques (`Client:` y `Server:`), estás listo. Si sólo sale `Client:`, abre Docker Desktop desde el menú Inicio.

**Y baja el driver**, que ese sí es tuyo:

- **Oracle Client for Microsoft Tools, 64-bit** — <https://www.oracle.com/database/technologies/appdev/ocmt.html> — pesa alrededor de **100 MB**

Descarga también el script de la base, que es el mismo de ayer:
[`datos/agrodb_oracle_clase12.sql`](../../datos/agrodb_oracle_clase12.sql)

## Cómo se entrega

En `entregas/apellido-nombre/`, por *pull request*, **dos archivos**:

| Archivo | Qué lleva |
|---|---|
| `Ejercicio13_Apellido_Nombre.sql` | todas las consultas de este ejercicio, con **su resultado pegado como comentario** debajo de cada una, y las respuestas de la parte E |
| `clase13-powerbi.png` | una captura de tu gráfica de Power BI donde se alcance a leer el total |

> Como hoy la mayoría del trabajo no es SQL sino instalación, **el resultado pegado es la evidencia**. Una consulta sin su resultado abajo no cuenta.

---

## Parte A · Levantar el motor (40 min)

### A1. Comprueba que Docker responde

```
docker version
```

Tienen que salir **dos** bloques: `Client:` y `Server:`. Si sólo sale `Client:` y abajo un error que menciona un *pipe*, el motor de Docker está apagado: abre **Docker Desktop** desde el menú Inicio, espera a que diga **Engine running**, y repite.

### A2. Levanta Oracle

Un solo comando, **todo en minúsculas**:

```
docker run -d --name oracle-free -p 1521:1521 -e ORACLE_PWD=Agrodb2026 container-registry.oracle.com/database/free:latest
```

La contraseña de administrador de la base es la que va en `ORACLE_PWD`. **Usa exactamente esa:** `Agrodb2026`.

> La primera vez baja alrededor de **2 GB**. Mientras tanto, lee las partes C y D de este documento, para saber a dónde vas.

### A3. Espera a que la base esté lista

```
docker logs -f oracle-free
```

Se queda escribiendo. Está listo cuando aparezca:

```
DATABASE IS READY TO USE!
```

Ahí sales con `Ctrl+C`. **Eso no apaga nada**, sólo deja de mostrarte el log.

Comprueba que el contenedor sigue de pie:

```
docker ps
```

En la columna `PORTS` tiene que decir `0.0.0.0:1521->1521/tcp`. Ese es tu *listener*.

> Para apagarlo y prenderlo sin perder los datos: `docker stop oracle-free` y `docker start oracle-free`.

### A4. Conéctate por primera vez

`sqlplus` está adentro del contenedor:

```
docker exec -it oracle-free sqlplus system/Agrodb2026@localhost:1521/FREEPDB1
```

Cuando veas `SQL>`, corre esto:

```sql
SELECT sys_context('USERENV','CON_NAME') AS donde_estoy FROM dual;
```

> ### ✅ Punto de control 1
> Debe decir **`FREEPDB1`**.
> **Pega en tu archivo de entrega la consulta y su resultado.**

**A5.** En un comentario, contesta con tus palabras: `FREE` y `FREEPDB1` son dos cosas distintas. **¿Cuál de las dos es la que va a guardar tus tablas, y qué es la otra?**

---

## Parte B · Cargar AgroDB (20 min)

### B1. Crea tu usuario

Sigues conectado como `system`. Corre las tres líneas:

```sql
CREATE USER agro IDENTIFIED BY Agro2026;
GRANT CONNECT, RESOURCE TO agro;
ALTER USER agro QUOTA UNLIMITED ON users;
```

### B2. Entra con ese usuario

```sql
CONNECT agro/Agro2026@localhost:1521/FREEPDB1
```

Fíjate que el `SQL>` sigue ahí pero **ya eres otro usuario**. Compruébalo:

```sql
SELECT USER FROM dual;
```

Debe decir **`AGRO`**, en mayúsculas.

### B3. Carga la base

El script está en tu Windows y la base adentro del contenedor, así que primero se copia. **En otra terminal**, parado en la carpeta del repo:

```
docker cp datos/agrodb_oracle_clase12.sql oracle-free:/tmp/agrodb.sql
```

Y de regreso en `sqlplus`, conectado como `agro`:

```sql
SET SERVEROUTPUT ON
@/tmp/agrodb.sql
```

> ### ✅ Punto de control 2
> Al final tienen que salir los trece números:
> **3, 6, 8, 10, 7, 19, 16, 6, 9, 8640, 0, 0, 23**
> **Pega la lista completa en tu archivo de entrega.**

**B4.** En un comentario, una línea: acabas de correr **el mismo script** que corriste ayer en el navegador y te dio **los mismos trece números**. ¿Qué cosa, entonces, *sí* es distinta entre FreeSQL y esto que acabas de instalar?

---

## Parte C · La capa que va a ver el tablero (25 min)

Aquí ya no estás instalando: estás diseñando. Es la parte que más puntos vale.

### C1. La vista de reporte

Conectado como `agro`:

```sql
CREATE OR REPLACE VIEW v_bi_produccion AS
SELECT f.nombre     AS finca,
       l.codigo     AS lote,
       cu.nombre    AS cultivo,
       s.estado     AS estado_siembra,
       co.fecha     AS fecha_cosecha,
       co.calidad   AS calidad,
       co.kg        AS kg
  FROM cosechas co
  JOIN siembras s  ON s.siembra_id  = co.siembra_id
  JOIN lotes    l  ON l.lote_id     = s.lote_id
  JOIN fincas   f  ON f.finca_id    = l.finca_id
  JOIN cultivos cu ON cu.cultivo_id = s.cultivo_id;
```

Y comprueba:

```sql
SELECT COUNT(*) AS filas, SUM(kg) AS kilos FROM v_bi_produccion;
```

> ### ✅ Punto de control 3
> Debe dar **9 filas** y **30 550 kilos**.
> Si te da más de 9 filas, tienes un `JOIN` de más o mal: revísalo antes de seguir. **Es el mismo fan-out de la clase 5.**

Y estos son los tres renglones que vas a ver en Power BI:

```sql
SELECT finca, SUM(kg) AS kilos
  FROM v_bi_produccion
 GROUP BY finca
 ORDER BY kilos DESC;
```

| Finca | Kilos |
|---|---|
| Finca El Guayabo | 14250 |
| Hacienda Santa Rosa | 14200 |
| Agricola La Union | 2100 |

### C2. El usuario de sólo lectura

Un tablero **no se conecta con el dueño de las tablas**. Crea uno que sólo pueda leer la vista:

```sql
CONNECT system/Agrodb2026@localhost:1521/FREEPDB1

CREATE USER bi_agro IDENTIFIED BY Bi2026;
GRANT CREATE SESSION TO bi_agro;
```

Y ahora, **como dueño de la vista**, dale el permiso:

```sql
CONNECT agro/Agro2026@localhost:1521/FREEPDB1

GRANT SELECT ON v_bi_produccion TO bi_agro;
```

### C3. Comprueba que el recorte sirve

Entra como el usuario nuevo y prueba las dos cosas:

```sql
CONNECT bi_agro/Bi2026@localhost:1521/FREEPDB1

SELECT SUM(kg) FROM agro.v_bi_produccion;   -- debe darte 30550
SELECT COUNT(*) FROM agro.cosechas;         -- debe FALLAR
```

**Pega el error de la segunda consulta en tu archivo.** Ese error es el objetivo, no un problema.

**C4.** En un comentario, dos líneas: ¿por qué el permiso sobre la vista lo tuvo que dar `agro` y no `system`? ¿Y por qué `bi_agro` tiene que escribir `agro.v_bi_produccion` con el prefijo?

---

## Parte D · Conectar Power BI (25 min)

### D1. Instala el driver

Ejecuta como administrador el **Oracle Client for Microsoft Tools** que descargaste. Elige **64 bits**.

Cuando termine: **cierra Power BI Desktop por completo y vuelve a abrirlo.** Si no lo reinicias, Power BI no ve el driver nuevo.

### D2. Conéctate

En Power BI Desktop:

1. **Inicio → Obtener datos → Más… → Base de datos → Base de datos Oracle**
2. En **Servidor**, escribe exactamente esto:

```
localhost:1521/FREEPDB1
```

3. Elige **Importar** y da **Aceptar**.
4. En la ventana de credenciales, elige la pestaña **Base de datos** (no *Windows*):
   - Usuario: `bi_agro`
   - Contraseña: `Bi2026`
5. **Conectar**.

### D3. Mira bien el navegador

Se abre la ventana **Navegador**. Ábrela toda y fíjate en lo que hay.

Debajo del esquema `AGRO` hay **una sola cosa**: `V_BI_PRODUCCION`.

> ### ✅ Punto de control 4
> **Esa lista corta es lo que hiciste en la parte C.** En un comentario de tu archivo, contesta: si te hubieras conectado con el usuario `agro` en vez de `bi_agro`, **¿cuántas tablas verías en esta lista?** Nómbralas.

Selecciona `V_BI_PRODUCCION` y da **Cargar**.

### D4. La gráfica

En el lienzo:

1. Inserta un **Gráfico de barras agrupadas**
2. **Eje Y:** `FINCA`
3. **Valores:** `KG` — asegúrate de que el campo diga **Suma de KG** y no *Recuento de KG*

Agrega también una **Tarjeta** con `KG` (suma), para que se vea el total.

> ### ✅ Punto de control 5
> El total tiene que decir **30 550**, y las barras 14 250 / 14 200 / 2 100.
> **Toma la captura con el total visible.** Esa es `clase13-powerbi.png`.

**D5.** Si tu tarjeta dice **9** en vez de 30 550, no está sumando: está contando. En un comentario, una línea: ¿dónde se cambia eso, y por qué Power BI eligió contar en lugar de sumar?

---

## Parte E · Preguntas de cierre (10 min, comentarios en tu archivo)

1. Hoy instalamos **tres** cosas: el motor, el driver y (ya la tenías) la herramienta. En una línea cada una: **qué pasa si falta**, y con qué mensaje te enteras.
2. Elegiste **Importar** y no **DirectQuery**. Mañana alguien carga 500 kilos nuevos en `cosechas` desde `sqlplus`. **¿Qué muestra tu tablero si lo abres sin tocar nada?** ¿Y qué error te avisa de eso?
3. En dos líneas: `bi_agro` no puede leer `cosechas`. Si mañana el jefe pide una gráfica de costos de labores, **¿qué hay que hacer, y quién lo hace?** (La respuesta no es «darle permiso a todo».)
4. FreeSQL sigue existiendo y sigue siendo gratis. En una línea: **¿en qué caso concreto seguirías usando FreeSQL** en lugar de esto que acabas de instalar?

---

## Si algo falla

Busca tu mensaje aquí antes de pedir ayuda:

| Mensaje | Qué pasó | Qué haces |
|---|---|---|
| `docker: command not found` | Docker Desktop no está abierto | ábrelo y espera a **Engine running** |
| `No such container` | escribiste `Oracle-free` con mayúscula | es `oracle-free`, todo en minúsculas |
| `ORA-12541: TNS:no listener` | el contenedor está detenido | `docker start oracle-free` |
| `ORA-12514` | el nombre de servicio está mal | escribe `FREEPDB1`, no `FREE`, no `XE`, no `ORCL` |
| `ORA-01017: invalid credential` | usuario o contraseña | la contraseña **distingue mayúsculas**: es `Agrodb2026` |
| `ORA-65096: common user...` | te conectaste al contenedor `FREE` | reconéctate a `FREEPDB1` |
| `ORA-00942` al leer `agro.cosechas` como `bi_agro` | **está bien, eso queríamos** | pégalo en la entrega y sigue |
| `'sqlplus' no se reconoce` | lo estás corriendo en tu Windows | `sqlplus` vive **adentro** del contenedor: entra con `docker exec` |
| *«proveedor de datos de Oracle no encontrado»* | falta el OCMT, o instalaste el de 32 bits | instala el de **64 bits** y **reinicia Power BI** |
| El navegador de Power BI sale vacío | a `bi_agro` le falta el `GRANT SELECT` | vuelve a C2, conectado como `agro` |
| La tarjeta dice 9 y no 30550 | Power BI está contando | cambia el campo a **Suma** |

> ### La regla de los 20 minutos sigue vigente
> Si llevas veinte minutos atorado en el mismo error: escríbelo como comentario en tu archivo empezando con `DUDA`, o abre un *issue*, y sigue con lo que puedas. **Atorarse no baja la nota. Quedarse callado sí.**

---

## Plan B · Si no puedes instalar

Si no pudiste instalar el driver de la parte D, o la máquina no da:

1. Haz las partes **C1 y C3** completas en **FreeSQL**, con el script de ayer. La vista y la comprobación de las 9 filas y los 30 550 kilos se pueden hacer ahí perfectamente.
2. En tu archivo, escribe un comentario que empiece con `PLAN B` explicando **qué te bloqueó exactamente**, con el mensaje o la pantalla que viste.
3. Contesta **todas** las preguntas de la parte E. No necesitas haber instalado para contestarlas.
4. Para la parte D, ponte con un compañero que sí haya podido: pueden hacer la conexión en una sola máquina, y cada quien entrega su captura diciendo en un comentario que fue trabajo en pareja y con quién.

**Con el Plan B completo se llega a 75 de 100.** No es un castigo: es lo que se puede evaluar.

---

## Rúbrica (100 puntos)

| Criterio | Pts |
|---|---|
| Parte A: Oracle instalado y respondiendo, con el punto de control 1 pegado | 20 |
| Parte B: AgroDB cargada, los trece números pegados | 20 |
| **Parte C: la vista con sus 9 filas y 30 550, el usuario `bi_agro`, y el `ORA-00942` que prueba el recorte** | **25** |
| Parte D: Power BI conectado, la gráfica con el total correcto y la captura | 25 |
| Parte E: las cuatro preguntas con criterio | 10 |

Los criterios suman **100** exactos.

> **Lo que más se califica hoy no es que hayas podido instalar.** Es la parte C: que entiendas que un tablero se conecta a **lo que le dejas ver**, y no a la base entera.
