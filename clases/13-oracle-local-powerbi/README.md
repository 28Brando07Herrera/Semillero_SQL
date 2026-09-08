# Clase 13 · Oracle en tu máquina y Power BI conectado
**Miércoles 26 de agosto**

**50 minutos de clase** y el resto de práctica. Es la primera sesión del curso en la que hay que instalar algo, y hay una razón concreta para hacerlo justo hoy.

## Material

| Qué | Dónde |
|---|---|
| Diapositivas | [slides.md](slides.md) · [versión web](https://negatix092.github.io/Semillero_SQL/13-oracle-local-powerbi.html) |
| Ejercicio práctico | [ejercicio.md](ejercicio.md) |
| Script de la base (el mismo de ayer) | [`datos/agrodb_oracle_clase12.sql`](../../datos/agrodb_oracle_clase12.sql) |
| Guía de referencia de Oracle local | [`recursos/entorno-local-oracle.md`](../../recursos/entorno-local-oracle.md) |

> **Hoy no hay script nuevo.** Se usa el de la clase 12 tal cual: la novedad no está en los datos, está en dónde corren.

## Antes de que empiece la clase

**1. Abre Docker Desktop y comprueba que responde:**

```
docker version
```

Tienen que salir los dos bloques, `Client:` y `Server:`. Si sólo sale `Client:`, abre Docker Desktop desde el menú Inicio y espera a que diga **Engine running**.

**2. Baja el driver de Power BI**, que ese sí es una descarga tuya (unos 100 MB):

- **Oracle Client for Microsoft Tools, 64-bit** — <https://www.oracle.com/database/technologies/appdev/ocmt.html>

> **La imagen de Oracle no la bajas tú**: la baja Docker con el comando del paso 2 de la clase. Son unos **2 GB**, así que si tienes buena conexión conviene adelantar ese comando antes de clase.

## Requisitos

| | |
|---|---|
| Sistema | Windows 10 u 11, 64 bits |
| Disco libre | **10 GB** |
| RAM disponible | 2 GB |
| Docker Desktop | instalado y abierto |
| Power BI Desktop | ya instalado, 64 bits |
| Permisos de administrador | **sólo** para instalar el driver (paso 8) |

> **Docker Desktop se instala por usuario y no pide administrador.** Si tu máquina está bloqueada, el motor de hoy igual lo puedes levantar. Donde sí te puede frenar es en el driver: para eso hay un **Plan B** al final del [ejercicio](ejercicio.md), se hace la conexión en pareja, llega a 75 de 100 y no es castigo. Avisa por privado.

## Por qué hoy sí hay que instalar

Doce clases trabajamos en [FreeSQL](https://freesql.com) y estuvo bien. Pero FreeSQL es una caja de arena: te presta un esquema, te deja escribir SQL y te devuelve una tabla en la pantalla. **No tiene un puerto abierto.** No hay una dirección a la que otro programa se pueda conectar.

Power BI no lee pantallas. Power BI se conecta a un servidor.

## Las tres capas

Es lo que hay entre tu Power BI y tus datos, y casi nadie las separa:

| Capa | Qué es | Dónde vive |
|---|---|---|
| **1. El motor** | Oracle Free, en un contenedor Docker | escucha en el puerto `1521` |
| **2. El driver** | Oracle Client for Microsoft Tools (OCMT) | una biblioteca en tu Windows |
| **3. La herramienta** | Power BI Desktop | ya la tienes |

El 80 % de los problemas de conexión están en la **capa 2**, que es la única que nadie recuerda que existe. Por eso hoy se instala a propósito y con nombre.

## Lo que hay que saber al terminar

- Por qué un servicio de navegador no sirve para conectar una herramienta de BI
- Qué es el *listener* y por qué el puerto `1521` es el tema de la clase
- La diferencia entre **CDB** (`FREE`) y **PDB** (`FREEPDB1`), y por qué `ORA-65096` no es culpa tuya
- Cómo se ve una cadena de conexión Oracle: `servidor:puerto/servicio`
- Crear un usuario, darle `CONNECT`, `RESOURCE` y cuota
- Cargar un `.sql` completo con `@archivo` desde `sqlplus`
- Que el **driver** es una pieza aparte, y que 32 vs 64 bits se manifiesta como *«proveedor no registrado»*
- Diseñar la **vista de reporte**: ancha, plana, sin `JOIN` para quien la consume
- Que el permiso sobre un objeto lo da **su dueño**, no el administrador
- Crear un usuario de **sólo lectura** que ve una vista y nada más
- **Importar vs DirectQuery**, y qué se pierde con cada uno
- Leer un total en Power BI y compararlo contra la base

## La idea del día

**Un tablero no se conecta a una base. Se conecta a lo que la base le deja ver.**

## Las cuatro cosas que son la clase

Si el día se complica y hay que recortar, estas no se recortan:

1. **Las tres capas.** Motor, driver, herramienta. Saber nombrar la capa que falló es la mitad del arreglo.
2. **El OCMT y los bits.** Instalar el de 32 en un Power BI de 64 produce un mensaje que no dice nada de bits, y ahí se pierde la tarde.
3. **El usuario de sólo lectura.** `bi_agro` puede leer una vista. No puede tocar `cosechas`. Lo decides tú, en tres líneas.
4. **El navegador de Power BI con una sola vista adentro.** Es el resultado visible del punto 3, y es el momento en que la idea del día se entiende sin explicarla.

## El número de control

**30 550 kilos.** Es la suma de cosechas que conocen desde la clase 5, y hoy tiene que recorrer la cadena completa sin perder nada:

| Dónde | Qué debe decir |
|---|---|
| `SELECT SUM(kg) FROM cosechas` | 30550 |
| `SELECT SUM(kg) FROM v_bi_produccion` | 30550 (y **9 filas**) |
| La tarjeta de Power BI | 30 550 |

Y el desglose de las barras: **Finca El Guayabo 14 250 · Hacienda Santa Rosa 14 200 · Agricola La Union 2 100**.

> Si la gráfica no da 30 550, algo se perdió entre la base y el tablero. Ese es el control del día, no que se vea bonita.

## Entrega

En `entregas/apellido-nombre/`, por *pull request*, **dos archivos**:

| Archivo | Qué lleva |
|---|---|
| `Ejercicio13_Apellido_Nombre.sql` | las consultas del ejercicio con **su resultado pegado como comentario** debajo de cada una |
| `clase13-powerbi.png` | captura de la gráfica, con el total visible |

> Hoy la mayor parte del trabajo no es escribir SQL, es instalar. **Por eso la evidencia es el resultado pegado**, no la consulta. Una consulta sin su salida abajo no cuenta.

## Nota sobre el material

Las rutas, nombres de servicio y nombres de menú de Power BI **cambian entre versiones**. Los de este material corresponden a la imagen `container-registry.oracle.com/database/free:latest` (hoy entrega **Oracle AI Database 26ai Free, 23.26.3.0.0**) y a Power BI Desktop de 64 bits en Windows 11. Si algo en tu máquina se llama distinto, anótalo en la entrega: eso puntúa, igual que documentar una discrepancia del enunciado.

Los números de AgroDB (las 9 filas, los 30 550, el desglose por finca) sí están verificados contra el script publicado.
