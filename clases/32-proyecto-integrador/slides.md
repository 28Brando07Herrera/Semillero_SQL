---
marp: true
paginate: true
theme: default
title: "Proyecto integrador · El cierre de septiembre"
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
  .verde { background: #1E8449; color: #fff; padding: 2px 10px; border-radius: 4px; }
  .rojo { background: #C0392B; color: #fff; padding: 2px 10px; border-radius: 4px; }
footer: "Curso de SQL · AgroDB · Proyecto integrador"
---

<!-- _class: lead -->

# El cierre de septiembre

## Proyecto integrador: una semana, un tablero, y nadie que te diga qué botón apretar

Del lunes 5 al viernes 9 de octubre

---

# El encargo

> *«El viernes 9 presento a la dirección el **cierre al 30 de septiembre de 2026**. Necesito un tablero: cuánto cosechamos, cuánto era la meta, cuánto se cobró, cómo vamos contra el año pasado, y que cada gerente vea solo lo suyo.*
>
> *En enero compramos **Hacienda Los Ceibos**; ya viene en los datos.*
>
> *Les mando los archivos **como me llegaron**.»*

<br>

La última frase es el proyecto.

---

# Esta semana no hay tema nuevo

| | En las clases | **Esta semana** |
|---|---|---|
| El enunciado | cada clic, en orden | **qué tiene que existir** al final del día |
| Los números | todos publicados | **uno o dos para calibrar** |
| El error del día | uno, y la clase te llevaba a él | **los que haya**, y nadie avisa cuántos |
| Quién revisa | tú, contra el enunciado | tú, **contra tus propias pruebas** |

<br>

> Todo lo que hace falta ya se vio entre la clase 14 y la 30.

---

# Lo que llega

| Archivo | Quién lo manda | Se parece a la clase |
|---|---|---|
| `dim_finca`, `dim_cultivo`, `dim_tiempo` | sistemas | 14 |
| `seguridad.csv` | sistemas | 19 |
| `bascula\`, un archivo por mes | la báscula | 30 |
| `bascula_digital_2026.csv` | la báscula digital | 27 |
| `precios.csv` | comercial | 28 |
| `metas_planeacion.csv` | planeación | 29 |

**`h_cosecha.csv` y `h_meta.csv` no vienen: las construyes tú.**

---

# Los datos son nuevos

- **Cuatro fincas**: llega **Hacienda Los Ceibos**, en El Oro. Cosecha banano.
- Cosechas **hasta el 30 de septiembre de 2026**.
- Cada cosecha trae **`fecha_entrega`** y **`calidad`**.
- El periodo del cierre: **2026, de enero a septiembre**.

<br>

> **Ningún número de las clases anteriores sirve. El 30 550 ya no existe.**

Si en tu tablero aparece un 30 550, un 24 440 o un 125,00 %, abriste la carpeta equivocada.

---

# La semana

| Día | Etapa | Qué queda hecho | Vale |
|---|---|---|---|
| **Lunes 5** | 1 · El inventario | las fuentes revisadas **antes de cargarlas** | 10 |
| **Martes 6** | 2 · Los hechos | `h_cosecha`, con su precio | 15 |
| **Miércoles 7** | 3 · Las metas y el modelo | `h_meta`, relaciones y medidas base | 15 |
| **Jueves 8** | 4 · El análisis y la seguridad | podio, bono, escenario, semáforo, KPI, rol | 15 |
| **Viernes 9** | La entrega | tablero, informe y bitácora | 45 |

Unas **dos horas** por etapa. Un solo `.pbix` para toda la semana.

---

# Cómo funciona un punto de control

**Anclas** · publicadas en el enunciado. Si tu ancla no sale, **no avances**.

**Preguntas ciegas** · no están publicadas. Contestas con lo que salga en tu pantalla.

<br>

Al día siguiente te contesto en tu *pull request*, pregunta por pregunta:

<span class="verde">cuadra</span> &nbsp; o &nbsp; <span class="rojo">no cuadra</span>

**Y nada más. No te voy a decir por qué.**

---

# Un ancla que sale no prueba nada

| Clase | El número viejo decía | Y adentro había |
|---|---|---|
| 27 | columna **100 % válida** | seis fechas al revés |
| 28 | control en **30 550** | el mango de segunda a precio de primera |
| 30 | control en **125,00 %** | un julio sin kilos |

<br>

> Las tres veces la prueba pasó. Las tres veces la prueba **miraba para otro lado**.

Por eso hay preguntas ciegas: miran a donde el ancla no mira.

---

# Lunes · Etapa 1 · El inventario

**Hoy casi no se toca Power BI. Se abren los archivos.**

1. **Cada archivo** en el Bloc de notas. Los de `bascula\`, todos.
2. Una tabla: fuente, filas, columnas, **su llave**, a qué tabla va.
3. **«Lo que veo raro»**: al menos cinco cosas, con **archivo y línea**, qué número van a mover y **hacia dónde**.
4. El `.pbix` con las cuatro tablas que sí llegaron limpias.

<br>

> Un archivo que no abriste es un archivo en el que confiaste.

---

# Empezar bien: el archivo vacío

En vivo, juntos, y es lo único que hacemos juntos:

1. Copiar `datos/csv_proyecto/` a **`C:\agrodbproyecto\`**.
2. `.pbix` nuevo → **Configuración regional: Español (México)**.
3. Apagar **«Detectar automáticamente nuevas relaciones»**.
4. Cargar `dim_finca`.

| Ancla | Debe decir |
|---|---|
| Filas de `dim_finca` | **4** |
| Archivos en `bascula\` | **19** |

---

# Martes y miércoles · Las dos tablas de hechos

**Martes · `h_cosecha`**: una fila por cosecha, de enero de 2025 a septiembre de 2026, **con su precio**. Sale de tres fuentes. Todo en Power Query.

**Miércoles · `h_meta`**: una fila por finca y por mes. Sale de la hoja de planeación. Más **todas** las relaciones y las medidas base.

<br>

| Día | Anclas |
|---|---|
| Martes, sin segmentadores | **53** cosechas · **0** repetidas · **136 600** kg |
| Miércoles | **48** filas de meta · **110 000** en 2026 · **105,92 %** al cierre |

---

# Jueves · Lo que pidió la dirección

- **El podio**: los tres cultivos con más kilos, **de lo que se esté viendo**.
- **El bono y el apoyo**: la regla se aplica **finca por finca**.
- **¿Y si subimos la meta?** Del 100 al 150 %. Con dos niveles marcados, **no inventa**.
- **El semáforo y el KPI del año**, con un título que diga el periodo.
- **Un solo rol** para todos. Quien no está en la tabla, no ve nada.

<br>

| Ancla | Debe decir |
|---|---|
| Ver como `regional.sur@agrodb.test` | **2 filas** y **104,44 %** |

---

# Viernes · La entrega

| Qué | Vale | Qué se califica |
|---|---|---|
| **El tablero**, tres páginas | 15 | que **se lea**: Resumen, Análisis y **Auditoría** |
| **El informe** para la dirección | 10 | el cierre, **tres hallazgos** y una advertencia, en una página |
| **La bitácora** completa | 15 | cada hallazgo **con su prueba** |
| Las medidas y el rol | 5 | cada una con la pregunta que contesta |

<br>

> Un hallazgo es algo que **no se ve en la tarjeta del total**.

---

# La bitácora

| Qué encontré | Cómo me di cuenta | Qué número daba mal | Cómo lo arreglé | Cómo sé que quedó |
|---|---|---|---|---|

<br>

«Cómo me di cuenta» es **una prueba**, no una corazonada.

<span class="rojo">No cuenta</span> &nbsp; *«lo arreglé porque el número no salía»*

<span class="verde">Cuenta</span> &nbsp; *«la consulta tenía N filas antes del paso y M después, y M no podía ser»*

---

# Las pruebas que ya tienes

| Prueba | La usaste en |
|---|---|
| Filas **antes y después** de cada paso | 28, 29 |
| Una tarjeta que **tiene que dar cero** | 28, 30 |
| **Calidad de columna**: válidos, errores, vacíos | 27, 30 |
| **Distintos contra únicos** en la llave | 28 |
| Sumar contra **un total que alguien más calculó** | 29 |
| Una medida que **cuenta filas** en vez de sumar | 17, 18 |
| **Ver como**, con alguien que no debería ver nada | 19 |

La página **Auditoría** del viernes es esta lámina, en tu tablero.

---

# Las reglas

| Sí | No |
|---|---|
| Consultar **todas** las clases y tus ejercicios | Abrir el `.pbix` de un compañero |
| Preguntar **cómo se hace** algo | Preguntar **cuánto le dio** una ciega |
| Corregir después de un «no cuadra» | Borrar de la bitácora lo que salió mal |

- Un *pull request* **por día**, antes de las **23:59**. Tarde vale la mitad.
- Corregir no recupera puntos del PC, pero **sí cuenta para el viernes**.
- **Veinte minutos** en lo mismo → `DUDA` en tu `.md`, y sigues.

---

# La idea de la semana

**Un tablero no está bien porque el número salió. Está bien porque sabes qué prueba lo habría atrapado si estuviera mal.**

<br>

Hoy, antes de las 23:59:

- `Proyecto_PC1_Apellido_Nombre.md`
- `proyecto-pc1-modelo.png`

> El enunciado completo está en `ejercicio.md`. Empieza por el Bloc de notas.
