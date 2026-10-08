# Proyecto integrador · El cierre de septiembre

**Del lunes 5 al viernes 9 de octubre · Individual · Solo Power BI Desktop · Cuatro puntos de control (lunes a jueves), y el viernes la entrega final con una presentación de 20 minutos**

---

## El encargo

> *«El viernes 9 presento a la dirección el **cierre al 30 de septiembre de 2026**. Necesito un tablero: cuánto cosechamos, cuánto era la meta, cuánto se cobró, cómo vamos contra el año pasado, y que cada gerente vea solo lo suyo. En enero compramos **Hacienda Los Ceibos**; ya viene en los datos. Les mando los archivos **como me llegaron**.»*
>
> — Dirección de AgroDB

Esta semana **no hay tema nuevo**. Hay un encargo, y todo lo que hace falta para cumplirlo ya se vio entre la clase 14 y la 30.

Tampoco hay enunciado paso a paso. En las clases, el ejercicio te decía qué botón apretar y qué número tenía que salir. Aquí te digo **qué tiene que existir al final de cada día** y te doy **uno o dos números para calibrar**. El resto de los números los pones tú, y yo te digo si cuadran.

**Los datos son nuevos. Ningún número de las clases anteriores sirve: el 30 550 ya no existe.**

---

## La semana

| Día | Etapa | Qué queda hecho | Vale |
|---|---|---|---|
| **Lunes 5** | 1 · El inventario | las fuentes revisadas **antes de cargarlas**, y las dimensiones en el modelo | 10 |
| **Martes 6** | 2 · Los hechos | `h_cosecha` armada en Power Query, con su precio | 15 |
| **Miércoles 7** | 3 · Las metas y el modelo | `h_meta`, las relaciones y las medidas base | 15 |
| **Jueves 8** | 4 · El análisis y la seguridad | ranking, bono, escenario, semáforo, KPI y el rol | 15 |
| **Viernes 9** | La entrega | el tablero terminado, **tu presentación ante la dirección** y la bitácora | 45 |

Suman **100**.

Cada etapa está pensada para **unas dos horas**. Si un día te toma más de tres, algo se atoró: usa la regla de los 20 minutos.

---

## Cómo funciona un punto de control

Cada punto de control (PC) tiene dos clases de números:

- **Anclas.** Están publicadas aquí. Son para que sepas, tú solo, si vas bien. Si tu ancla no sale, **no avances**: algo de esa etapa está mal.
- **Preguntas ciegas.** No están publicadas. Las contestas con lo que salga **en tu pantalla**, y al día siguiente te contesto en tu *pull request*, pregunta por pregunta, **«cuadra»** o **«no cuadra»**. Nada más. **No te voy a decir por qué**: encontrarlo es el proyecto.

> **Un ancla que sale no prueba que todo esté bien.** Ya lo viste en la 27, en la 28 y en la 30: el número viejo puede dar perfecto con el error adentro. Por eso existen las preguntas ciegas.

**Plazo:** cada PC se entrega por *pull request* **antes de las 23:59 de su día**. Entregado tarde vale **la mitad**. Lo que corrijas después de mi respuesta **no recupera puntos del PC**, pero sí cuenta para la entrega final, que se califica con el tablero **como quede el viernes**.

---

## Los datos

Copia [`datos/csv_proyecto/`](../../datos/csv_proyecto/) completa a **`C:\agrodbproyecto\`** y trabaja sobre esa copia. Empiezas con un **`.pbix` vacío** y lo vas guardando toda la semana: **es un solo archivo, no uno por día.**

| Archivo | Quién lo manda | Qué trae | Dónde se vio algo parecido |
|---|---|---|---|
| `dim_finca.csv` | sistemas | las **cuatro** fincas | 14 |
| `dim_cultivo.csv` | sistemas | los seis cultivos | 14 |
| `dim_tiempo.csv` | sistemas | el calendario 2025–2026 | 14, 16 |
| `seguridad.csv` | sistemas | qué correo ve qué finca | 19 |
| `bascula\` (carpeta) | la báscula | las cosechas de enero de 2025 a junio de 2026, **un archivo por mes** | 30 |
| `bascula_digital_2026.csv` | la báscula digital | las cosechas de julio a septiembre de 2026 | 27 |
| `precios.csv` | comercial | el precio por kilo de cada cultivo según su calidad | 28 |
| `metas_planeacion.csv` | planeación | **su hoja** de metas 2026 | 29 |

Cada cosecha trae además `fecha_entrega`, la fecha en que finanzas la cobra (clase 26).

**`h_cosecha.csv` y `h_meta.csv` no vienen: las construyes tú.**

### Reglas del modelo

- **Configuración regional del archivo: Español (México)**, como desde la 27. Se fija antes de cargar nada.
- **«Detectar automáticamente nuevas relaciones después de cargar los datos»: apagada.** Las relaciones las dibujas tú.
- La tabla de hechos de cosechas se llama **`h_cosecha`** y la de metas **`h_meta`**, con las columnas de siempre (`kg`, `kg_meta`, `fecha_mes`).
- **El periodo del cierre** es **2026, de enero a septiembre**: segmentadores `dim_tiempo[anio]` = **2026** y `dim_tiempo[mes]` de **1 a 9**. Todo número de este enunciado es con esos dos segmentadores, salvo donde diga otra cosa.

---

## Cómo se entrega

En `entregas/apellido-nombre/`, por *pull request*. **Un PR por día**, con estos nombres exactos:

| Día | Archivos |
|---|---|
| Lunes | `Proyecto_PC1_Apellido_Nombre.md` · `proyecto-pc1-modelo.png` |
| Martes | `Proyecto_PC2_Apellido_Nombre.md` · `proyecto-pc2-hechos.png` · `proyecto-pc2-pasos.png` |
| Miércoles | `Proyecto_PC3_Apellido_Nombre.md` · `proyecto-pc3-modelo.png` · `proyecto-pc3-control.png` |
| Jueves | `Proyecto_PC4_Apellido_Nombre.md` · `proyecto-pc4-gerente.png` · `proyecto-pc4-regional.png` · `proyecto-pc4-practicante.png` |
| Viernes | `Proyecto_Final_Apellido_Nombre.pptx` (**antes de la sesión**) · `Proyecto_Final_Apellido_Nombre.md` · `proyecto-final-1-resumen.png` · `proyecto-final-2-analisis.png` · `proyecto-final-3-auditoria.png` |

> El `.pbix` no se entrega: el repositorio lo ignora a propósito. **Guárdalo**: si una captura no se entiende, te voy a pedir que lo abras.

En cada `.md` de punto de control van, en este orden: las **anclas** con lo que salió en tu pantalla, las **preguntas ciegas** contestadas, y la **bitácora del día** (ver abajo).

### La bitácora

Es lo que más vale del proyecto. Cada vez que un número no te cuadre, o que un archivo traiga algo que no esperabas, anotas una fila:

| Qué encontré | Cómo me di cuenta | Qué número daba mal | Cómo lo arreglé | Cómo sé que quedó |
|---|---|---|---|---|

«Cómo me di cuenta» es **una prueba**, no una corazonada: filas antes y después, una tarjeta que tenía que dar cero, la calidad de una columna, una suma contra un total que alguien más calculó. Una fila que diga «lo arreglé porque el número no salía» **no cuenta**.

---

## Etapa 1 · Lunes · El inventario (10 puntos)

**Hoy casi no se toca Power BI.** Se abren los archivos.

**1.1** Abre **cada** archivo de `C:\agrodbproyecto\` con el **Bloc de notas** (los de la carpeta `bascula\`, todos). Llena esta tabla en tu `.md`:

| Fuente | Filas | Columnas | Su llave | A qué tabla del modelo va |
|---|---|---|---|---|

**1.2** **«Lo que veo raro».** Una lista de **al menos cinco** cosas que, antes de cargar nada, crees que van a mover un número. Para cada una: **en qué archivo y en qué línea** lo viste, **qué número crees que va a mover**, y **hacia dónde** (más, menos, a otro mes). Todavía no las arregles.

**1.3** Crea el `.pbix`: configuración regional, detección de relaciones apagada, y carga **solo** `dim_finca`, `dim_cultivo`, `dim_tiempo` y `seguridad`. Marca el calendario como tabla de fechas, ordena `nombre_mes` por `mes`, y dibuja la relación de `seguridad` con `dim_finca`.

**Anclas del lunes**

| Qué | Debe decir |
|---|---|
| Filas de `dim_finca` / `dim_cultivo` / `dim_tiempo` / `seguridad` | **4 / 6 / 730 / 10** |
| Archivos en `C:\agrodbproyecto\bascula\` | **19** |

**Preguntas ciegas del lunes**

- **L1.** Según los archivos, sin cargar nada: ¿cuántas cosechas **distintas** hay en total, sumando la carpeta y la báscula digital?
- **L2.** ¿Cuánto es la meta de **toda la empresa para todo 2026**, y en qué celda de qué archivo lo leíste?
- **L3.** ¿Qué correo de `seguridad.csv` tiene más de una finca **sin tenerlas todas**, y cuáles son?

**Captura:** `proyecto-pc1-modelo.png`, la vista de modelo con las cuatro tablas y su relación.

---

## Etapa 2 · Martes · Los hechos (15 puntos)

Al terminar el día existe **`h_cosecha`**: **una fila por cosecha**, desde enero de 2025 hasta septiembre de 2026, con `cosecha_id`, `finca_id`, `cultivo_id`, `fecha`, `fecha_entrega`, `calidad`, `kg` y **`precio_kg`**. Todo se hace en **Power Query**.

Tiene que salir de tres fuentes: la carpeta `bascula\`, `bascula_digital_2026.csv` y `precios.csv`. Cómo las juntas es decisión tuya; cada decisión va a la bitácora.

Relaciona `h_cosecha` con `dim_finca`, `dim_cultivo` y `dim_tiempo` (por `fecha`), y escribe por lo menos:

```
Kilos = SUM( h_cosecha[kg] )
Cosechas = COUNTROWS( h_cosecha )
Cosechas repetidas = COUNTROWS( h_cosecha ) - DISTINCTCOUNT( h_cosecha[cosecha_id] )
Ingresos = SUMX( h_cosecha , h_cosecha[kg] * h_cosecha[precio_kg] )
```

**Anclas del martes** (sin segmentadores)

| Qué | Debe decir |
|---|---|
| `[Cosechas]` | **53** |
| `[Cosechas repetidas]` | **0** |
| `[Kilos]` | **136 600** |

**Preguntas ciegas del martes**

- **M1.** `[Kilos]` de **agosto de 2025**.
- **M2.** `[Cosechas]` y `[Kilos]` de **septiembre de 2026**.
- **M3.** `[Kilos]` de cada una de las cuatro fincas, en el periodo del cierre.
- **M4.** `[Ingresos]` de la empresa en el periodo del cierre, con dos decimales.
- **M5.** ¿Cuántas filas tenía `h_cosecha` **la primera vez** que la cargaste, antes de corregir nada? ¿Y cuántas columnas tenían valores vacíos o `Error`, y cuáles?

**Capturas:** `proyecto-pc2-hechos.png` (una matriz con `anio` y `nombre_mes` en filas, `[Kilos]` y `[Cosechas]`, y las tarjetas de las tres anclas) y `proyecto-pc2-pasos.png` (el Editor de Power Query con `h_cosecha` seleccionada y sus **Pasos aplicados** a la vista).

---

## Etapa 3 · Miércoles · Las metas y el modelo (15 puntos)

Al terminar el día existe **`h_meta`** —una fila por finca y por mes de 2026, con `finca_id`, `fecha_mes` y `kg_meta`—, el modelo tiene **todas** sus relaciones, y están las medidas base.

**3.1** Arma `h_meta` desde `metas_planeacion.csv`, en Power Query, y relaciónala.

**3.2** Dibuja la relación de `h_cosecha[fecha_entrega]` con el calendario.

**3.3** Escribe las medidas. Los nombres son obligatorios; cómo las escribes es tuyo:

| Medida | Qué contesta |
|---|---|
| `[Meta]` | los kilos de meta |
| `[Cumplimiento]` | kilos entre meta. **En una tabla por cultivo no debe enseñar una meta que no existe** |
| `[Kilos entregados]` | los kilos según la fecha en que se **entregaron**, no en que se cortaron |
| `[Kilos año anterior]` | los kilos del **mismo periodo** de 2025 |
| `[Variacion]` | cuánto cambió contra el año anterior, en porcentaje |
| `[Promedio por cultivo]` | kilos por cultivo, **entre los cultivos que sí cosecharon** |

**Anclas del miércoles**

| Qué | Debe decir |
|---|---|
| Filas de `h_meta` | **48** |
| `[Meta]` con solo `anio` = 2026 | **110 000** |
| `[Cumplimiento]` de la empresa, periodo del cierre | **105,92 %** |

**Preguntas ciegas del miércoles**

- **X1.** `[Cumplimiento]` de **cada una** de las cuatro fincas.
- **X2.** `[Kilos entregados]` de la empresa en el periodo del cierre. ¿Por qué no es igual a `[Kilos]`? Contesta con las cosechas concretas que hacen la diferencia.
- **X3.** `[Variacion]` de la empresa. Y luego la pregunta que te va a hacer la dirección: **¿crecimos eso?** Da el número que tú presentarías y defiéndelo en tres líneas.
- **X4.** `[Promedio por cultivo]` en el periodo del cierre.
- **X5.** Pon `[Meta]` en una tabla por `dim_cultivo[cultivo]`. ¿Qué enseña, y qué debería enseñar?

**Capturas:** `proyecto-pc3-modelo.png` (la vista de modelo completa, con todas las relaciones visibles) y `proyecto-pc3-control.png` (la tabla por finca con `[Kilos]`, `[Meta]` y `[Cumplimiento]`, con los dos segmentadores a la vista).

---

## Etapa 4 · Jueves · El análisis y la seguridad (15 puntos)

Lo que la dirección pidió, punto por punto:

**4.1 El podio.** Los **tres cultivos** con más kilos. Tiene que seguir enseñando tres cuando alguien filtre por `dim_cultivo[tipo]`: el podio **de lo que se está viendo**.

**4.2 El bono y el apoyo.** La empresa paga bono por cada kilo **arriba** de la meta y da apoyo por cada kilo **abajo**. **La regla se aplica finca por finca**, y el total de la empresa es la suma de lo que le toca a cada una.

**4.3 ¿Y si subimos la meta?** Un segmentador con niveles de **100 a 150 %**, de diez en diez, que mueva la meta y el cumplimiento. Si alguien marca dos niveles a la vez, el tablero **no debe inventar** uno.

**4.4 El semáforo y el KPI.** En la tabla por finca, verde si la finca cumple y rojo si no. Y un **KPI del año**: lo cosechado contra la meta, **acumulado** al cierre, con un título que diga qué periodo enseña.

**4.5 Cada quien lo suyo.** **Un solo rol** para todos, que lea `seguridad`. Quien no esté en la tabla no ve nada.

**Ancla del jueves**

| Qué | Debe decir |
|---|---|
| **Ver como** `regional.sur@agrodb.test`: filas en la tabla por finca y `[Cumplimiento]` del total | **2 filas** y **104,44 %** |

**Preguntas ciegas del jueves**

- **J1.** Con `tipo` = **perenne** marcado: ¿qué tres cultivos están en el podio, en qué lugar cada uno, y cuántos kilos suman?
- **J2.** El **bono** total y el **apoyo** total de la empresa, en kilos. Y lo que diría cada uno si la regla se aplicara a la empresa entera en vez de finca por finca.
- **J3.** Con la meta al **110 %**: `[Cumplimiento]` de la empresa, y cuántas fincas cumplen.
- **J4.** Lo que enseña el KPI del año: valor, objetivo y la diferencia en porcentaje.
- **J5.** **Ver como** `gerente.launion@agrodb.test`: kilos, meta, cumplimiento y color. Y **ver como** `practicante@agrodb.test`.

**Capturas:** `proyecto-pc4-gerente.png`, `proyecto-pc4-regional.png` y `proyecto-pc4-practicante.png`, cada una con una tarjeta que enseñe **quién está mirando**.

---

## Viernes · La entrega final (45 puntos)

### El tablero (15 puntos)

Tres páginas, tres capturas:

| Página | Captura | Lo mínimo que lleva |
|---|---|---|
| **Resumen** | `proyecto-final-1-resumen.png` | el KPI del año con su título; tarjetas de kilos, meta, cumplimiento e ingresos; la tabla por finca con semáforo; kilos contra meta por mes |
| **Análisis** | `proyecto-final-2-analisis.png` | el podio de cultivos; cosechado contra entregado por mes; la comparación contra 2025; el bono y el apoyo por finca |
| **Auditoría** | `proyecto-final-3-auditoria.png` | las pruebas que te dicen que el modelo está sano: **las que tienen que dar cero y las que tienen que dar un número que alguien más calculó** |

Se califica que **se lea**: títulos que digan el periodo, unidades, nada de `Suma de kg`, y que una persona que no tomó el curso entienda la página Resumen en un minuto.

### La presentación ante la dirección (10 puntos)

El viernes, en el horario de clase, **cada quien presenta su cierre**. Haz de cuenta que enfrente está la dirección: gente que no sabe qué es DAX y que va a tomar decisiones con lo que digas.

- **En PowerPoint**, archivo `Proyecto_Final_Apellido_Nombre.pptx`, subido en tu *pull request* **antes de que empiece la sesión**.
- **Máximo 20 minutos por persona, contando las preguntas.** Apunta a 15 de exposición y deja 5. A los 20 se corta, vayas donde vayas.
- **Máximo 10 láminas.** El orden de las presentaciones se sortea al empezar.

Lo que tiene que llevar, en este orden:

| # | Lámina | Qué lleva |
|---|---|---|
| 1 | **El cierre en una línea** | cuánto, contra cuánto, y en qué periodo |
| 2 | **El tablero** | la página Resumen, en captura o en vivo |
| 3 a 5 | **Tres hallazgos**, uno por lámina | cada uno con su número y una recomendación. Un hallazgo es algo que **no se ve en la tarjeta del total** |
| 6 | **Una advertencia** | un número del tablero que se puede leer mal, y cómo hay que leerlo |
| 7 y 8 | **Dos filas de tu bitácora** | qué traía el archivo, **cómo te diste cuenta** y qué número daba mal |
| 9 | **Por qué creerle a este tablero** | la página Auditoría: qué pruebas tiene y qué dicen |

Tres reglas para las láminas:

- **Un número por lámina, grande, con su unidad y su periodo.** Las fórmulas no van: van en el `.md`.
- **No leas la lámina.** Si lo que dices es lo que está escrito, sobra una de las dos cosas.
- **En las preguntas te voy a pedir que abras el `.pbix`** y me enseñes de dónde sale un número, y te voy a preguntar por una fila de tu bitácora que no hayas presentado. Tenlo abierto.

Los 10 puntos: el cierre en una línea (2), los tres hallazgos con número y recomendación (2 cada uno) y la advertencia (2). Las láminas 7 a 9 y tus respuestas cuentan para la bitácora y el tablero, que se califican ahí mismo.

### La bitácora completa (15 puntos)

En `Proyecto_Final_Apellido_Nombre.md`. La de los cuatro días, junta y revisada, con las cinco columnas. Aquí entra también lo que corregiste después de mis «no cuadra».

### Las medidas y el rol (5 puntos)

En el mismo `.md`. Todas las medidas y la condición del rol, en bloques de código, cada una con **una línea** que diga qué pregunta contesta.

---

## Lo que se puede y lo que no

| Sí | No |
|---|---|
| Consultar **todas** las clases, sus diapositivas y tus ejercicios anteriores | Abrir el `.pbix` de un compañero |
| Preguntarle a un compañero **cómo se hace** algo | Preguntarle **cuánto le dio** una pregunta ciega |
| Preguntarme lo que sea, en clase o por *issue* | Copiar una captura |
| Corregir después de un «no cuadra» | Borrar de la bitácora lo que salió mal |

**La regla de los 20 minutos sigue igual:** veinte minutos en lo mismo → escribe `DUDA` en tu `.md` con lo que intentaste, y sigue con lo siguiente. Una `DUDA` bien escrita no baja puntos.

Y la regla del material: **si un número de este enunciado no te cierra, no lo fuerces: documenta la discrepancia.** Eso puntúa.

---

## Plan B · Si Power BI Desktop no abre en tu máquina

1. Trabaja en la máquina de un compañero, **en un `.pbix` aparte**, en otro horario.
2. Si no se puede, avísame **el mismo día**: la etapa 1 se hace completa con el Bloc de notas, y las demás las vemos caso por caso.

---

## Rúbrica (100 puntos)

| Criterio | Pts |
|---|---|
| **PC1 · lunes:** la tabla de fuentes (3), «lo que veo raro» (4), las anclas, las ciegas y la captura (3) | 10 |
| **PC2 · martes:** las tres anclas (3), las cinco ciegas (2 cada una) y la bitácora del día con sus capturas (2) | 15 |
| **PC3 · miércoles:** las tres anclas (3), las cinco ciegas (2 cada una) y la bitácora del día con sus capturas (2) | 15 |
| **PC4 · jueves:** el ancla (3), las cinco ciegas (2 cada una) y la bitácora del día con sus capturas (2) | 15 |
| **Final · el tablero:** tres páginas que se leen | 15 |
| **Final · la presentación:** el cierre, tres hallazgos y una advertencia, en 20 minutos | 10 |
| **Final · la bitácora completa:** cada hallazgo con su prueba | 15 |
| **Final · las medidas y el rol**, con su pregunta | 5 |

Los criterios suman **100** exactos.

> **Lo que más se califica esta semana no es que el número salga.** Es que puedas decir **cómo supiste que estaba mal** cuando no salía, y **cómo sabes que está bien** ahora.
