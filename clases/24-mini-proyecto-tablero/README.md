# Clase 24 · Diez números para la gerencia
**Martes 22 de septiembre**

**Mini proyecto autoguiado, de 90 minutos a 2 horas, en el horario de clase.** Hoy no hay clase en vivo: las diapositivas guían el trabajo paso a paso, con un reloj, los clics de cada parte y qué hacer cuando algo no sale. Décima clase seguida del lado de Power BI: **hoy tampoco se prende Oracle.**

## Material

| Qué | Dónde |
|---|---|
| Diapositivas | [slides.md](slides.md) · [versión web](https://negatix092.github.io/Semillero_SQL/24-mini-proyecto-tablero.html) |
| Ejercicio práctico (el proyecto y su checklist) | [ejercicio.md](ejercicio.md) |
| Datos del día | **ninguno nuevo**: los seis CSV de [`datos/csv_clase19/`](../../datos/csv_clase19/) |

> **Hoy se empieza de cero**: un `.pbix` vacío. Copia `datos/csv_clase19/` a `C:\agrodb24\` y trabaja sobre esa copia, porque en la parte E se edita `seguridad.csv`.

## Qué hace falta tener listo

| | |
|---|---|
| Power BI Desktop | y nada más |
| Oracle, Docker, el OCMT | **no**, hoy tampoco |
| El `.pbix` de clases anteriores | **no**: hoy el modelo se arma desde cero |

## De qué se trata

La gerencia pide **un solo tablero** para la junta de cumplimiento 2026: que se vea **quién cumple en verde o en rojo**, un **KPI del año** arriba, que **cada gerente vea solo su finca** y que el **practicante** no vea nada hasta que se le dé permiso, **sin tocar el modelo**.

Todo lo que hace falta ya se vio entre la clase 14 y la 23. Hoy se junta:

| Parte | Qué se arma | De qué clase viene |
|---|---|---|
| A | seis CSV y **seis relaciones dibujadas a mano** en la vista de modelo, con la detección automática apagada; el calendario marcado y `nombre_mes` ordenada | 14, 15, 16, 17 |
| B | las siete medidas, y la tabla por finca que **dice qué relación falta** si algo sale mal | 15, 16, 17, 19, 23 |
| C | el semáforo con `[Color cumplimiento]`, un degradado, tres tarjetas y el **KPI del año** con título | 23 |
| D | el rol dinámico en `dim_finca` y **Ver como** con tres correos: gerente, regional y practicante | 18, 19 |
| E | el **alta del practicante** con una línea en `seguridad.csv` y **Actualizar** | 19 |

## El giro de hoy

**No hay trampa nueva.** Están todas las de antes, en el mismo lienzo: la relación que falta, la regla con Porcentaje, el KPI que enseña abril, el rol en la tabla de permisos. Por eso la calificación es un **checklist de diez números**, cada uno visible en una captura, y cada uno **solo sale si se esquivó una trampa del curso**:

- el total en **125,00 %** y no en 65,00 % (la meta sin su relación con el calendario);
- Santa Rosa **verde** con 142,00 % y no roja (la regla con Porcentaje);
- el KPI en **30 550** y no en 19 750 (el último mes);
- el gerente de La Unión en **42,00 %** y no en 8,59 % ni en 125,00 % (el rol en la tabla equivocada);
- el regional en **113,23 %** y no con un error (el `LOOKUPVALUE`);
- el practicante **sin nada**, y no con la empresa entera.

> La nota sale de poner las capturas junto al checklist: **diez puntos, diez segundos cada uno.** El *pull request* se abre **hoy, al terminar**, aunque falte algo.

## Lo que hay que saber al terminar

- Armar un modelo en estrella **desde cero**, con las relaciones **dibujadas a mano**, todas muchos a uno y de dirección única
- Reconocer **qué relación falta** por el número que sale en la tabla por finca
- Poner las medidas, el semáforo con **Valor del campo**, un degradado y el **KPI del año** con un título que diga su periodo
- Escribir el **rol dinámico** en la dimensión y probarlo con **tres correos**: uno de una finca, uno de varias y uno que no está
- Dar un permiso **sin abrir el rol**
- Revisar un tablero **contra un checklist de números**, no contra la pinta que tiene

## La idea del día

**Un tablero está terminado cuando cada número que enseña se probó contra la trampa que lo haría mentir.**

## Las cuatro cosas que son la clase

Si el día se complica y hay que recortar, estas no se recortan:

1. **Las seis relaciones a mano**, con la captura del modelo.
2. **La tabla por finca con 125,00 %** y el semáforo con Santa Rosa en verde.
3. **El rol en `dim_finca`** y Ver como con el regional: **113,23 %**.
4. **El practicante**, sin nada y luego con Santa Rosa, sin abrir el rol.

## Los números de control

Todos con segmentadores en `anio` = 2026 y `mes` en 1–4.

| Dónde | Qué debe decir |
|---|---|
| El modelo | **6 tablas**, **6 relaciones** muchos a uno; `dim_cultivo` sin relación con `h_meta` |
| La tabla por finca | La Union **2 100 / 5 000 / 42,00 %** · El Guayabo **14 250 / 9 440 / 150,95 %** · Santa Rosa **14 200 / 10 000 / 142,00 %** · total **30 550 / 24 440 / 125,00 %** |
| Sin la relación 5 (`h_meta` con el calendario) | `[Meta]` **47 000**, total **65,00 %** |
| Sin la relación 4 (`h_meta` con la finca) | `[Meta]` **24 440** en cada finca: 8,59 / 58,31 / 58,10 % |
| Sin la relación 3 (`h_cosecha` con el calendario) | `[Kilos]` **77 550** |
| El semáforo | La Union rojo · El Guayabo verde · Santa Rosa **verde** · total **verde** |
| La tabla por cultivo | Mango **12 700** · Maiz **9 800** · Guayaba **5 950** · Cacao **2 100** |
| El KPI del año | **30 550** contra **24 440**, **+25,00 %** (con `[Kilos]`: 19 750; sin ordenar `nombre_mes`: 10 800) |
| Ver como gerente.launion | **1 fila**, **2 100 / 5 000 / 42,00 %**, rojo · KPI **−58,00 %** · por cultivo solo Cacao |
| Ver como regional.norte | **2 filas**, total **16 350 / 14 440 / 113,23 %**, verde · KPI **+13,23 %** |
| Ver como practicante | **nada** |
| Tras agregar `practicante@agrodb.test,1` | **1 fila**, Santa Rosa **14 200 / 10 000 / 142,00 %**, verde · KPI **+42,00 %** |

## Entrega

En `entregas/apellido-nombre/`, por *pull request*, **siete archivos**:

| Archivo | Qué lleva |
|---|---|
| `Ejercicio24_Apellido_Nombre.md` | el **checklist** lleno con lo que salió en pantalla, las siete medidas y el rol en bloques de código, la trampa que descarta cada punto, y las respuestas A3a, A3b, D5 y E1 |
| `clase24-1-modelo.png` | la vista de modelo, seis tablas y seis relaciones |
| `clase24-2-tablero.png` | el tablero completo, sin Ver como |
| `clase24-3-gerente.png` | Ver como gerente.launion |
| `clase24-4-regional.png` | Ver como regional.norte |
| `clase24-5-practicante.png` | Ver como practicante, antes del alta |
| `clase24-6-alta.png` | Ver como practicante, después del alta |

> El `.pbix` no se entrega: el repositorio lo ignora a propósito. Tampoco el `seguridad.csv` modificado.

## Nota sobre el material

Los números de esta clase —la tabla por finca, lo que dice cuando falta cada relación, los colores, el KPI del año y lo que ve cada correo, antes y después del alta— están **verificados contra los CSV publicados en `datos/csv_clase19/`** con `docente/clase24_verificacion_docente.py`, que modela las seis relaciones y **las quita una por una**, propaga el rol **solo** por las relaciones que existen y en su sentido, y calcula el último punto del KPI.

Lo que **ningún script puede verificar** es lo que dibuja Power BI en tu versión: cómo se llama la opción de **detectar relaciones**, cómo se ve una relación en la vista de modelo, y los nombres de los menús. Si en tu máquina algo se llama distinto, **anótalo en la entrega: eso puntúa**.
