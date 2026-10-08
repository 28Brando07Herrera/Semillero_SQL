# Proyecto integrador · El cierre de septiembre
**Del lunes 5 al viernes 9 de octubre**

**Una semana, individual.** El lunes hay **50 minutos de explicación**; de martes a jueves el horario de clase es para trabajar y resolver dudas, y el viernes **cada quien presenta su cierre**: PowerPoint, 20 minutos máximo. Solo Power BI Desktop: **esta semana tampoco se prende Oracle.**

## Material

| Qué | Dónde |
|---|---|
| Diapositivas del lunes | [slides.md](slides.md) · [versión web](https://negatix092.github.io/Semillero_SQL/32-proyecto-integrador.html) |
| El enunciado, los puntos de control y la rúbrica | [ejercicio.md](ejercicio.md) |
| Datos | [`datos/csv_proyecto/`](../../datos/csv_proyecto/): siete CSV y la carpeta `bascula/` con 19 archivos. **Todos nuevos** |

> Copia `datos/csv_proyecto/` a `C:\agrodbproyecto\` y empieza con un **`.pbix` vacío**. Es **un solo archivo para toda la semana**.

## Qué hace falta tener listo

| | |
|---|---|
| Power BI Desktop | y nada más |
| Oracle, Docker, el OCMT | **no** |
| Los `.pbix` de clases anteriores | **no**: los datos son otros y ningún número viejo sirve |

## De qué se trata

La dirección presenta el viernes el **cierre al 30 de septiembre de 2026** y pide un tablero: cuánto se cosechó, cuánto era la meta, cuánto se cobró, cómo va el año contra el anterior, y que cada gerente vea solo lo suyo. En enero la empresa compró **Hacienda Los Ceibos**, que ya viene en los datos. Y los archivos llegan **como llegaron**: la carpeta de la báscula, la báscula digital, la lista de precios de comercial y la hoja de planeación.

No hay tema nuevo: todo se vio entre la clase 14 y la 30. Lo que cambia es que **el enunciado no dice qué botón apretar**. Dice qué tiene que existir al final de cada día.

## La semana

| Día | Etapa | Qué queda hecho | Vale |
|---|---|---|---|
| Lunes 5 | 1 · El inventario | las fuentes revisadas antes de cargarlas, y las dimensiones en el modelo | 10 |
| Martes 6 | 2 · Los hechos | `h_cosecha` armada en Power Query, con su precio | 15 |
| Miércoles 7 | 3 · Las metas y el modelo | `h_meta`, las relaciones y las medidas base | 15 |
| Jueves 8 | 4 · El análisis y la seguridad | ranking, bono, escenario, semáforo, KPI y el rol | 15 |
| Viernes 9 | La entrega | el tablero, **la presentación ante la dirección** y la bitácora | 45 |

## Cómo funciona un punto de control

Cada día tiene **anclas** y **preguntas ciegas**.

- Las **anclas** están publicadas: sirven para saber, sin preguntarle a nadie, si la etapa va bien.
- Las **preguntas ciegas** no: se contestan con lo que salga en pantalla, y al día siguiente el instructor responde en el *pull request* **«cuadra»** o **«no cuadra»**, sin decir por qué.

| Día | Anclas |
|---|---|
| Lunes | **4 / 6 / 730 / 10** filas en las cuatro tablas, y **19** archivos en `bascula\` |
| Martes | **53** cosechas, **0** repetidas, **136 600** kg, sin segmentadores |
| Miércoles | **48** filas de meta, **110 000** en 2026, y **105,92 %** de cumplimiento al cierre |
| Jueves | viendo como `regional.sur@agrodb.test`: **2 filas** y **104,44 %** |

Cada punto de control se entrega por *pull request* **antes de las 23:59 de su día**; tarde vale la mitad.

## La idea de la semana

**Un tablero no está bien porque el número salió. Está bien porque sabes qué prueba lo habría atrapado si estuviera mal.**

## Lo que más se califica

La **bitácora**: cada cosa rara que se encontró, **con la prueba** que la delató, el número que daba mal, el arreglo y cómo se sabe que quedó. Y la página **Auditoría** del tablero, con las pruebas que tienen que dar cero.
