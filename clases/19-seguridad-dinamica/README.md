# Clase 19 · Un rol para todos
**Lunes 14 de septiembre**

**50 minutos de clase** y el resto de práctica. Quinta clase seguida del lado de Power BI: **hoy tampoco se prende Oracle.**

## Material

| Qué | Dónde |
|---|---|
| Diapositivas | [slides.md](slides.md) · [versión web](https://negatix092.github.io/Semillero_SQL/19-seguridad-dinamica.html) |
| Ejercicio práctico | [ejercicio.md](ejercicio.md) |
| Datos del día | [`datos/csv_clase19/`](../../datos/csv_clase19/): **un archivo nuevo**, `seguridad.csv`, y los cinco de la clase 17 sin cambios |

> **Se baja un solo archivo**: `seguridad.csv`. Se trabaja sobre el `.pbix` de la clase 18, **sin los tres roles de ayer**.

## Qué hace falta tener listo

| | |
|---|---|
| Power BI Desktop | y nada más |
| Oracle, Docker, el OCMT | **no**, hoy tampoco |
| El `.pbix` de la clase 18 | con las relaciones **en una sola dirección** y **sin roles** |

## De qué se trata

Ayer se escribieron **tres roles para tres gerentes**. Con cuarenta gerentes, un regional que ve dos fincas y una dirección que ve todas, eso no se sostiene: cada alta es abrir el modelo.

Hoy se escribe **un solo rol**. Lo que cambia entre personas pasa a una **tabla de permisos**, `seguridad.csv` (un correo y un `finca_id` por fila), y el rol pregunta quién está mirando con **`USERPRINCIPALNAME()`**. Se prueba con **Ver como → Otro usuario**, escribiendo cualquier correo, sin publicar nada.

La primera versión es la obvia, porque el correo está en la tabla de permisos:

```
Rol:       Por correo
Tabla:     seguridad
Condición: [correo] = USERPRINCIPALNAME()
```

Y el rol **sí** filtra: `[Filas de seguridad]` baja de **8** a **1**. Pero viendo como el gerente de La Unión, `[Kilos]` dice **30 550** y `[Cumplimiento]` **125,00 %**, y la tabla por finca le enseña **las tres fincas**. Y un correo que **no está** en la tabla, `practicante@agrodb.test`, también ve **la empresa entera**.

## El giro de hoy

Es la regla de ayer, otra vez sin excepciones: **el filtro viaja solo por las relaciones, del lado uno al lado muchos.** `seguridad` es el lado muchos de su relación con `dim_finca`, así que un rol puesto ahí recorta la lista de permisos y **no llega a nada más**.

La condición tiene que ir en **`dim_finca`**, y desde ahí **consultar** la tabla de permisos. El primer intento, con `LOOKUPVALUE`, funciona con los gerentes de una finca y **truena con el regional**, que tiene dos: es el único mensaje de error de la semana, y es el bueno. El arreglo es preguntar *¿está en la lista?* en vez de *¿es igual a?*:

```
Tabla:     dim_finca
Condición: [finca_id] IN
               CALCULATETABLE(
                   VALUES( seguridad[finca_id] ),
                   seguridad[correo] = USERPRINCIPALNAME()
               )
```

> Ayer el rol en la tabla equivocada le enseñó al gerente la meta de los demás. **Hoy, en la tabla de permisos, le enseñó todo, y al que no tenía permiso también.**

## Lo que hay que saber al terminar

- Qué es la **seguridad dinámica**: un solo rol, una tabla de permisos y `USERPRINCIPALNAME()`
- Cómo se prueba con **Ver como → Otro usuario**, marcando **también el rol**
- Que la tabla de permisos **es una tabla más** del modelo, y que un rol puesto en ella **no llega** a la dimensión ni a los hechos
- Que un rol mal puesto **deja la puerta abierta por defecto**: el que no está en la tabla ve todo
- La regla: **la condición va en la dimensión, y consulta la tabla de permisos**; la tabla de permisos no filtra, se consulta
- Que `LOOKUPVALUE` espera **un** valor y truena con una persona de varias fincas, y que ese error es el bueno
- `IN`, `VALUES` y `CALCULATETABLE`: preguntar *¿está en la lista?*
- La prueba de un rol dinámico: **tres correos**, uno de una finca, uno de varias y uno que no está
- Que dar de alta a alguien **ya no toca el modelo**, y por eso la tabla de permisos es tan delicada como los kilos

## La idea del día

**Un rol dinámico sigue siendo un rol: la condición pregunta quién mira, pero el filtro viaja solo por las relaciones.**

## Las cuatro cosas que son la clase

Si el día se complica y hay que recortar, estas no se recortan:

1. **El rol obvio en `seguridad`**, que sí filtra la lista de permisos.
2. **El 125,00 % del gerente y el 30 550 del practicante**, sin un solo aviso.
3. **El regional rompiendo `LOOKUPVALUE`.** Un error con mensaje, y por qué es bueno.
4. **El rol con `IN` en `dim_finca` y el 113,23 % del regional.** La misma regla de ayer, con una lista.

## Los números de control

Todos con segmentadores en `anio` = 2026 y `mes` en 1–4.

| Dónde | Qué debe decir |
|---|---|
| Sin rol, `[Filas de seguridad]` por finca | La Union **3** · El Guayabo **3** · Santa Rosa **2** · total **8** |
| **Rol en `seguridad`**, viendo como gerente.launion | `[Filas de seguridad]` **1** · `[Kilos]` **30 550** · `[Cumplimiento]` **125,00 %** · **3 fincas** ← el error del día |
| El mismo rol, viendo como practicante | `[Kilos]` **30 550** · `[Cumplimiento]` **125,00 %** ← la puerta abierta |
| **`LOOKUPVALUE` en `dim_finca`** | gerente.launion **42,00 %** · gerente.guayabo **150,95 %** · practicante **vacío** · regional.norte **error** |
| **`IN` en `dim_finca`**, los tres gerentes | **42,00 %** · **150,95 %** · **142,00 %** |
| …regional.norte | **2 fincas** · `[Kilos]` **16 350** · `[Meta]` **14 440** · `[Cumplimiento]` **113,23 %** |
| …direccion | **3 fincas** · **30 550** · **125,00 %** |
| …practicante | **0 fincas**, todo vacío |
| Tras agregar `auditor.santarosa@agrodb.test,1` | `[Filas de seguridad]` sin rol **9** · auditor **14 200** y **142,00 %** |

## Entrega

En `entregas/apellido-nombre/`, por *pull request*, **dos archivos**:

| Archivo | Qué lleva |
|---|---|
| `Ejercicio19_Apellido_Nombre.md` | cada rol y cada medida en un bloque de código con **su resultado anotado debajo**, el mensaje de error textual de la parte D, y las respuestas de la parte G |
| `clase19-ver-como.png` | captura con **Ver como** en `regional.norte@agrodb.test`: la tarjeta `[Quien mira]` y **la tabla por finca de dos filas** |

> El `.pbix` no se entrega: el repositorio lo ignora a propósito. Tampoco se sube el `seguridad.csv` modificado de la parte F.

## Nota sobre el material

Los números de esta clase —el 125,00 % y el 30 550 con el rol en `seguridad`, las filas de permisos por finca, los tres gerentes, el regional con 113,23 % y el practicante sin nada— están **verificados contra los CSV publicados en `datos/csv_clase19/`** con `docente/clase19_verificacion_docente.py`, que modela el rol como un recorte de tabla, lo propaga **solo** por las relaciones que existen y en su sentido, y hace tronar `LOOKUPVALUE` cuando encuentra más de un valor.

Lo que **ningún script puede verificar** es el comportamiento del motor y los nombres de menú de Power BI en tu versión y tu idioma: **Ver como → Otro usuario**, el editor de la condición y, sobre todo, **el mensaje de error textual del regional**. Si en tu máquina algo se llama distinto o dice otra cosa, **anótalo en la entrega: eso puntúa**, igual que documentar una discrepancia del enunciado.
