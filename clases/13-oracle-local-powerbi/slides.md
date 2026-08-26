---
marp: true
paginate: true
theme: default
title: "Clase 13 · Oracle en tu máquina y Power BI conectado"
style: |
  section { font-family: system-ui, -apple-system, "Segoe UI", sans-serif; font-size: 26px; background: #fbfbfa; color: #1f2933; padding: 60px 70px; }
  section.lead { background: #16324f; color: #f4f7fa; }
  section.lead h1 { color: #ffffff; font-size: 54px; line-height: 1.1; }
  section.lead h2 { color: #7fb3d5; font-weight: 400; font-size: 30px; }
  h1 { color: #16324f; font-size: 40px; border-bottom: 3px solid #f2a104; padding-bottom: 10px; }
  h2 { color: #1c7293; font-size: 32px; }
  strong { color: #b3541e; }
  code { background: #eef2f6; padding: 1px 6px; border-radius: 4px; }
  pre { background: #16324f; border-radius: 8px; font-size: 20px; }
  pre code { background: transparent; color: #e8eef4; }
  table { font-size: 23px; }
  th { background: #16324f; color: #fff; }
  blockquote { border-left: 5px solid #f2a104; color: #4a5568; font-style: normal; }
  footer { color: #8a99a8; font-size: 16px; }
footer: "Curso de SQL · AgroDB · Clase 13"
---

<!-- _class: lead -->

# El motor en tu máquina

## Instalar Oracle paso a paso y conectar Power BI a AgroDB

Clase 13 · 26 de agosto

---

# Hoy sí hay que instalar, y hay una razón

Doce clases trabajamos en el navegador. Hoy no alcanza.

<br>

**FreeSQL es una caja de arena.** Te presta un esquema, te deja escribir SQL y te devuelve una tabla en la pantalla. Pero **no tiene un puerto abierto**: no hay una dirección a la que otro programa se pueda conectar.

<br>

Power BI no lee pantallas. Power BI se conecta a un **servidor**.

<br>

> Al final de la clase vas a tener una gráfica de kilos por finca, hecha en Power BI, leyendo de una base que corre en tu computadora. Y el total de esa gráfica tiene que dar **30 550**, el número que conoces desde la clase 5.

---

# Las tres capas

Casi nadie las separa, y por eso casi nadie sabe dónde falló.

| Capa | Qué es | Puerto / archivo |
|---|---|---|
| **1. El motor** | Oracle Database 23ai Free | escucha en `1521` |
| **2. El driver** | Oracle Client for Microsoft Tools | una DLL en tu Windows |
| **3. La herramienta** | Power BI Desktop | ya la tienes instalada |

<br>

> **El 80 % de los problemas de conexión están en la capa 2**, que es la única que nadie recuerda que existe. Hoy la instalamos a propósito y con nombre.

---

# Antes de empezar: lo que necesitas

| | |
|---|---|
| Windows | 10 u 11, de 64 bits |
| Disco libre | **15 GB** durante la instalación |
| RAM | 2 GB disponibles |
| Permisos | **administrador local** en la máquina |
| Power BI Desktop | ya instalado, de 64 bits |

<br>

**Dos descargas, y las dos deben estar bajando desde ahorita:**

1. Oracle Database 23ai Free (Windows x64) — **≈ 1.5 GB**
2. Oracle Client for Microsoft Tools (64-bit) — **≈ 100 MB**

> Si no tienes permisos de administrador en esa computadora, no hay versión portable. Sigue la clase, toma nota, e instálalo en una máquina donde sí puedas.

---

# Paso 1 · Descargar el motor

Ve a:

**<https://www.oracle.com/database/free/get-started/>**

<br>

Busca **Oracle Database 23ai Free** y elige la descarga de **Microsoft Windows x64**. Es un archivo `.zip`.

<br>

> Puede pedirte una cuenta de Oracle. Es gratuita y es la misma que usaste para FreeSQL.

<br>

> **No bajes** «Oracle Database 23ai Enterprise», ni «Free Graph», ni el «Client» a secas. El que quieres dice **Free** y **Database**.

---

# Paso 2 · Descomprimir y ejecutar

1. Descomprime el `.zip` en una carpeta **sin espacios ni acentos** en la ruta.
   Por ejemplo: `C:\oracle23ai\`
2. Adentro está `setup.exe`. **Clic derecho → Ejecutar como administrador.**
3. El instalador te va a pedir **una sola cosa importante**: la contraseña de administrador de la base.

<br>

**Usa esta y anótala:** `Agrodb2026`

<br>

> **Esa contraseña no se recupera.** Si la pierdes, se reinstala. Anótala en el mismo archivo donde vas a hacer la entrega, en un comentario.

> La instalación tarda entre 10 y 20 minutos. Déjala correr y sigue viendo la clase.

---

# Paso 3 · Qué quedó instalado

Cuando termine, en tu máquina hay tres cosas nuevas:

| Qué | Cómo se llama | Cómo lo revisas |
|---|---|---|
| El servicio del motor | `OracleServiceFREE` | `services.msc` |
| El *listener* | `OracleOraDB23Home1TNSListener` | `services.msc` |
| La base | contenedor `FREE`, con la base `FREEPDB1` adentro | en un minuto |

<br>

Los dos servicios deben decir **En ejecución**. Si alguno está detenido, botón derecho → **Iniciar**.

<br>

> El *listener* es el que atiende el puerto `1521`. Es, literalmente, la razón por la que hoy instalamos algo.

---

# Paso 4 · La primera conexión

El instalador también te dejó `sqlplus`. Abre una terminal (`cmd` o PowerShell) y escribe:

```
sqlplus system/Agrodb2026@localhost:1521/FREEPDB1
```

<br>

Si te responde con `SQL>`, ya está. Comprueba dónde estás parado:

```sql
SELECT sys_context('USERENV','CON_NAME') AS donde_estoy FROM dual;
```

<br>

Debe decir **`FREEPDB1`**.

---

# Paso 5 · Por qué `FREEPDB1` y no `FREE`

Oracle moderno guarda **bases adentro de una base**.

| Nombre | Qué es | Para qué sirve |
|---|---|---|
| `FREE` | el contenedor (**CDB**) | administrar el motor |
| `FREEPDB1` | la base de trabajo (**PDB**) | **aquí van tus tablas** |

<br>

Si te conectas a `FREE` y tratas de crear un usuario normal:

```
ORA-65096: nombre de usuario o rol común no válido
```

<br>

> No es un error tuyo: te está diciendo *«estás en el contenedor; los usuarios normales van adentro de una PDB»*. **Conéctate siempre a `FREEPDB1`.**

---

# Paso 6 · Crear el usuario del curso

Conectado como `system` en `FREEPDB1`:

```sql
CREATE USER agro IDENTIFIED BY Agro2026;
GRANT CONNECT, RESOURCE TO agro;
ALTER USER agro QUOTA UNLIMITED ON users;
```

<br>

Y ahora entra con ese usuario:

```sql
CONNECT agro/Agro2026@localhost:1521/FREEPDB1
```

<br>

> **Por qué no trabajar como `system`:** `system` ve las 3 000 tablas internas del motor. `agro` va a ver **sólo las tuyas**. Cuando abras el navegador de Power BI vas a agradecerlo.

---

# Paso 7 · Cargar AgroDB · punto de control

Conectado como `agro`, y con el archivo del repo ya descargado:

```sql
SET SERVEROUTPUT ON
@C:\ruta\donde\lo\bajaste\agrodb_oracle_clase12.sql
```

<br>

Al final tienen que salir los **trece números de siempre**:

**3, 6, 8, 10, 7, 19, 16, 6, 9, 8640, 0, 0, 23**

<br>

> Es el mismo script de ayer. Si esos trece números salen, tu Oracle local está bien instalado y tienes la misma base que tuviste en el navegador. **Mitad de la clase, lista.**

---

# Ahora el otro lado

Power BI **no sabe hablar con Oracle por sí solo.**

<br>

Windows no trae el driver, y el motor que acabas de instalar tampoco se lo instala a Power BI.

<br>

Si intentas conectarte ahorita, vas a ver esto:

```
No se pudo encontrar el proveedor de datos de Oracle.
Es posible que no esté instalado.
```

<br>

> Y aquí es donde se pierde la tarde el que no sabe que existe la capa 2.

---

# Paso 8 · El driver que falta

Se llama **Oracle Client for Microsoft Tools** (OCMT). Es el driver oficial para Power BI, Excel y SSIS.

**<https://www.oracle.com/database/technologies/appdev/ocmt.html>**

1. Baja la versión de **64 bits**. Tu Power BI Desktop es de 64 bits.
2. Ejecútalo como administrador. No te pregunta casi nada.
3. **Cierra Power BI Desktop por completo y vuelve a abrirlo.** Si no lo reinicias, el driver no aparece.

<br>

| Si instalas | Y tu Power BI es | Resultado |
|---|---|---|
| 64 bits | 64 bits | funciona |
| 32 bits | 64 bits | *«proveedor no registrado»* |

> Es el error número uno de esta conexión, y no dice nada sobre bits. Dice que el proveedor no existe.

---

# Paso 9 · La vista que el tablero va a leer

Conectado como `agro`, crea la capa que vas a exponer:

```sql
CREATE OR REPLACE VIEW v_bi_produccion AS
SELECT f.nombre    AS finca,
       l.codigo    AS lote,
       cu.nombre   AS cultivo,
       s.estado    AS estado_siembra,
       co.fecha    AS fecha_cosecha,
       co.calidad  AS calidad,
       co.kg       AS kg
  FROM cosechas co
  JOIN siembras s  ON s.siembra_id = co.siembra_id
  JOIN lotes    l  ON l.lote_id    = s.lote_id
  JOIN fincas   f  ON f.finca_id   = l.finca_id
  JOIN cultivos cu ON cu.cultivo_id = s.cultivo_id;

SELECT COUNT(*) AS filas, SUM(kg) AS kilos FROM v_bi_produccion;
```

**Debe dar 9 filas y 30 550 kilos.** Anota los dos números: son tu prueba.

---

# Paso 10 · Un usuario que sólo puede leer eso

Un tablero **no se conecta con el dueño de las tablas.** Nunca.

```sql
CONNECT system/Agrodb2026@localhost:1521/FREEPDB1

CREATE USER bi_agro IDENTIFIED BY Bi2026;
GRANT CREATE SESSION TO bi_agro;

CONNECT agro/Agro2026@localhost:1521/FREEPDB1

GRANT SELECT ON v_bi_produccion TO bi_agro;
```

<br>

`bi_agro` puede entrar y puede leer **una vista**. No puede leer `cosechas`, no puede borrar nada, no puede crear nada.

> El permiso sobre la vista lo da `agro`, porque la vista es suya. Crear el usuario lo hace `system`. Son dos cosas distintas y por eso son dos conexiones.

---

# Paso 11 · Conectar Power BI

En Power BI Desktop:

1. **Inicio → Obtener datos → Más… → Base de datos → Base de datos Oracle**
2. En **Servidor**, escribe exactamente:

```
localhost:1521/FREEPDB1
```

3. Deja el resto en blanco y da **Aceptar**.

<br>

> No es una ruta de Windows ni una URL. Es `servidor : puerto / nombre_de_servicio`, y el nombre de servicio es el de la PDB, el mismo que vienes usando en `sqlplus` desde el paso 4.

---

# Paso 12 · Credenciales y navegador

En la ventana de credenciales, elige la pestaña **Base de datos** (no *Windows*):

| | |
|---|---|
| Usuario | `bi_agro` |
| Contraseña | `Bi2026` |

<br>

En el **Navegador** vas a ver el esquema **`AGRO`**, y adentro **una sola cosa**: `V_BI_PRODUCCION`.

<br>

> Ese navegador casi vacío es el resultado del paso 10, y es el punto de toda la clase: **el tablero ve lo que le dejaste ver, no lo que hay.**

---

# Paso 13 · Importar o DirectQuery

Power BI te pregunta cómo quiere los datos. Es una decisión, no un trámite.

| | **Importar** | **DirectQuery** |
|---|---|---|
| Dónde viven los datos | copiados dentro del `.pbix` | se quedan en Oracle |
| Velocidad | rápido siempre | depende de la base |
| ¿Están al día? | **hasta el último *Actualizar*** | sí |
| Si apagas Oracle | el tablero sigue mostrando | el tablero se cae |

<br>

**Hoy elige Importar.** Pero anota la fila tres: un tablero en modo Importar puede mostrar los datos de la semana pasada **sin decir una palabra**.

---

# Paso 14 · La primera gráfica

Da **Cargar**, y en el lienzo:

1. Inserta un **Gráfico de barras agrupadas**
2. **Eje Y:** `FINCA`
3. **Valores:** `KG` (asegúrate de que diga **Suma de KG**)

<br>

| Finca | Kilos |
|---|---|
| Finca El Guayabo | **14 250** |
| Hacienda Santa Rosa | **14 200** |
| Agricola La Union | **2 100** |
| **Total** | **30 550** |

<br>

> Si tu total no da 30 550, algo se perdió entre la base y el tablero. **Ese es el control, no que se vea bonito.**

---

# Los errores que van a ver hoy

| Mensaje | Qué pasó | Arreglo |
|---|---|---|
| `ORA-12541: TNS:no listener` | el motor no está prendido | inicia `OracleServiceFREE` y el listener en `services.msc` |
| `ORA-12514` | el nombre de servicio está mal | es `FREEPDB1`, no `FREE` ni `XE` |
| `ORA-01017` | usuario o contraseña | ojo: la contraseña **sí** distingue mayúsculas |
| `ORA-65096` | te conectaste al contenedor | conéctate a `FREEPDB1` |
| *«proveedor no registrado»* | falta el OCMT, o es de 32 bits | instala el de 64 y **reinicia Power BI** |
| El navegador está vacío | `bi_agro` no tiene permiso | `GRANT SELECT` desde `agro` |

---

<!-- _class: lead -->

# La idea del día

## Un tablero no se conecta a una base. Se conecta a lo que la base le deja ver.

<br>

Hoy expusiste **una vista y un usuario de sólo lectura**. Ese recorte no es paranoia: es el diseño.

<br>

**Práctica:** termina la instalación, conecta, y entrega el `.sql` con tus comprobaciones más una captura de tu gráfica.

**El número que tiene que salir es 30 550.**
