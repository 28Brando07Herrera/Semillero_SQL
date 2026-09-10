# Clase 18 · Lo que cada quien puede ver
**Jueves 10 de septiembre**

**50 minutos de clase** y el resto de práctica. Cuarta clase seguida del lado de Power BI: **hoy tampoco se prende Oracle.**

## Material

| Qué | Dónde |
|---|---|
| Diapositivas | [slides.md](slides.md) · [versión web](https://negatix092.github.io/Semillero_SQL/18-seguridad-filas.html) |
| Ejercicio práctico | [ejercicio.md](ejercicio.md) |
| Datos del día | **ninguno nuevo**: los cinco de [`datos/csv_clase17/`](../../datos/csv_clase17/), sin cambios |

> **Hoy no se baja nada.** Se trabaja sobre el `.pbix` de la clase 17. Quien lo tenga roto, que lo rehaga con los cinco CSV de ayer antes de empezar.

## Qué hace falta tener listo

| | |
|---|---|
| Power BI Desktop | y nada más |
| Oracle, Docker, el OCMT | **no**, hoy tampoco |
| El `.pbix` de la clase 17 | con las cinco relaciones **en una sola dirección** y las medidas de ayer, `[Filas de meta]` incluida |

## De qué se trata

Hasta hoy todos veíamos todo. Hoy el tablero se le va a mandar a **una persona**: el gerente de **Agricola La Union**, con un requisito de una línea: *que vea su finca, y nada más.*

Eso se hace con un **rol**: un filtro que el usuario no puede ver ni quitar, escrito como una condición sobre una tabla, y probado en Power BI Desktop con **Ver como**, sin publicar nada.

La primera versión es la obvia, porque lo delicado son los kilos:

```
Rol:       Gerente La Union
Tabla:     h_cosecha
Condición: [finca_id] = 3
```

Y funciona: viendo como el gerente, `[Kilos]` dice **2 100** y `[Cosechas]` dice **2**, que es exactamente La Unión. Pero la tarjeta que el gerente va a mirar dice **`[Meta]` = 24 440** y **`[Cumplimiento]` = 8,59 %**, cuando su finca va en **42,00 %**. Y si pone la finca en las filas, ve **tres fincas**, con **la meta de las otras dos**.

## El giro de hoy

No es un error de fórmula ni de contexto: es que **la seguridad también es un filtro**, y un filtro viaja solo por las relaciones, del lado uno al lado muchos. Un rol puesto en `h_cosecha` recorta `h_cosecha` y ahí se queda: no sube a `dim_finca`, así que **nunca llega a `h_meta`**. Es la regla de ayer, sin una sola excepción.

Y lo atrapa **la medida que escribimos ayer**: `[Filas de meta]` vale **12** con el rol y sin el rol. Una finca tendría que tener **4**.

El arreglo es mover la condición **una tabla más arriba**:

```
Tabla:     dim_finca
Condición: [finca] = "Agricola La Union"
```

> En la clase 13, cuando `bi_agro` se pasó, Oracle contestó **`ORA-00942`**. Hoy el gerente se pasó de su finca y **nadie contestó nada**.

## Lo que hay que saber al terminar

- Qué es un **rol**, cómo se crea en **Administrar roles** y cómo se prueba con **Ver como**
- Que un rol es un filtro que se evalúa **fila por fila** y que el usuario **no ve ni puede quitar**
- Que la seguridad **viaja por las relaciones** igual que cualquier filtro, y que un rol en una tabla de hechos **no llega** a los otros hechos
- La regla: **la seguridad se pone en la dimensión**, que es la única tabla que llega a todos los hechos, incluidos los que todavía no existen
- Que la tarjeta de kilos **no sirve** para probar un rol: los kilos bajan con el rol bien y mal puesto
- La prueba de verdad: **Ver como**, la dimensión del rol en las filas, y un conteo de cada tabla de hechos
- Que **`ALL` no puede traer lo que el rol escondió**: para el gerente, la empresa es su finca
- Que qué puede ver cada quien es **una decisión de negocio**, y el rol solo la ejecuta

## La idea del día

**La seguridad es un filtro más: llega solo a donde llegan las relaciones.**

## Las cuatro cosas que son la clase

Si el día se complica y hay que recortar, estas no se recortan:

1. **El rol obvio en `h_cosecha`**, que recorta bien los kilos.
2. **El 8,59 % y las tres fincas en pantalla**, con la meta de las otras dos, sin un solo aviso.
3. **`[Filas de meta]` en 12 con el rol y sin el rol.** El aviso de ayer, sirviendo hoy.
4. **El rol en `dim_finca` y el 42,00 %.** La misma condición, una tabla más arriba.

## Los números de control

Todos con segmentadores en `anio` = 2026 y `mes` en 1–4.

| Dónde | Qué debe decir |
|---|---|
| Sin rol, por finca | La Union **42,00 %** · El Guayabo **150,95 %** · Santa Rosa **142,00 %** · total **125,00 %** |
| **Rol en `h_cosecha`**, viendo como La Union | `[Kilos]` **2 100** · `[Cosechas]` **2** · `[Meta]` **24 440** · `[Cumplimiento]` **8,59 %** ← el error del día |
| La misma tabla por finca | **3 filas**, con las metas **9 440** y **10 000** de las otras dos ← la fuga |
| `[Filas de meta]` con ese rol | **12**, igual que sin rol ← la detección |
| Los tres gerentes con el rol en `h_cosecha` | **8,59 %** · **58,31 %** · **58,10 %**, que suman **125,00** |
| **Rol en `dim_finca`**, viendo como La Union | `[Meta]` **5 000** · `[Filas de meta]` **4** · `[Cumplimiento]` **42,00 %** · **1 fila** |
| Los tres gerentes con el rol en `dim_finca` | **42,00 %** · **150,95 %** · **142,00 %** |
| `[Participacion]` sin rol | La Union **6,87 %** · El Guayabo **46,64 %** · Santa Rosa **46,48 %** |
| `[Participacion]` viendo como La Union | **100,00 %** |

## Entrega

En `entregas/apellido-nombre/`, por *pull request*, **dos archivos**:

| Archivo | Qué lleva |
|---|---|
| `Ejercicio18_Apellido_Nombre.md` | cada rol y cada medida en un bloque de código con **su resultado anotado debajo**, y las respuestas de la parte G |
| `clase18-ver-como.png` | captura con **Ver como** prendido y **las dos tablas por finca**: la de tres filas y la de una |

> El `.pbix` no se entrega: el repositorio lo ignora a propósito.

## Nota sobre el material

Hoy no hay datos nuevos. Los números de esta clase —el 8,59 %, las metas de las otras fincas, el 12 que no se mueve, los tres gerentes, el 42,00 % con el rol bien puesto y la participación— están **verificados contra los CSV publicados en `datos/csv_clase17/`** con `docente/clase18_verificacion_docente.py`, que modela el rol como un recorte de tabla y lo propaga **solo** por las relaciones que existen, en su sentido.

Lo que **ningún script puede verificar** es el comportamiento del motor y los nombres de menú de Power BI en tu versión y tu idioma: **Administrar roles**, **Ver como** y el editor de condiciones cambian de lugar y de nombre entre versiones. Si en tu máquina algo se llama distinto, **anótalo en la entrega: eso puntúa**, igual que documentar una discrepancia del enunciado.
