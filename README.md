# Semillero SQL · AgroDB

Base de datos para gestión agrícola, construida clase a clase.
Todo el material del curso está aquí: diapositivas, scripts, ejercicios y entregas.

**Diapositivas online:** https://negatix092.github.io/Semillero_SQL/
**Notas y correcciones:** https://negatix092.github.io/Semillero_SQL/resultados.html
**Entorno de trabajo:** [sqliteonline.com](https://sqliteonline.com) (SQLite, clases 1 a 10) · [freesql.com](https://freesql.com) (Oracle, desde la clase 11) · Oracle local + Power BI (desde la clase 13) · Power BI sobre CSV, sin motor (clases 15 a 21)
**¿Preferís trabajar en tu máquina?** [SQLite local](recursos/entorno-local-sqlite.md) · [Oracle local](recursos/entorno-local-oracle.md) — los dos opcionales

---

## Cómo se usa este repo

| Si eres… | Haces esto |
|---|---|
| Alumno, quiero ver la clase | Entras al link de diapositivas, o abrís `clases/NN-tema/slides.md` |
| Alumno, quiero entregar | Haces *fork* → rama → tu archivo en `entregas/` → *pull request*. Ver [CONTRIBUTING.md](CONTRIBUTING.md) |
| Alumno, quiero ver mi nota | [Página de resultados](https://negatix092.github.io/Semillero_SQL/resultados.html). Vas por alias: cada uno sabe cuál es el suyo |
| Alumno, estoy trabado | Abres un *issue* con la plantilla **Duda**. No es penalizado: es parte del curso |
| Instructor | `clases/NN-tema/README.md` tiene la guía docente de cada sesión |

---

## Estructura

```
clases/         una carpeta por sesión: guía docente, diapositivas y ejercicio
  resultados/   la página de notas que se publica en GitHub Pages
datos/          scripts .sql que hay que ejecutar antes de cada práctica
                (y desde la clase 15, también los CSV que lee Power BI)
entregas/       una carpeta por alumno, creada vía pull request
recursos/       chuletas de sintaxis, guías de entorno y material de consulta
proyecto-final/ enunciado y rúbrica
```

---

## Clases

| # | Fecha | Tema | Motor | Material |
|---|---|---|---|---|
| 1 | 4 ago | SELECT, WHERE, GROUP BY, JOIN, LEFT JOIN | SQLite | — |
| 2 | 5 ago | CASE, COALESCE, subconsultas, CTE, ventanas | SQLite | — |
| P1 | 6 ago | Proyecto 1 · diseñá tu propia base | SQLite | — |
| 3 | 12 ago | Del requerimiento al modelo · normalización y N:M | SQLite | [clase](clases/03-modelado/) |
| 4 | 13 ago | INSERT / UPDATE / DELETE y transacciones | SQLite | [clase](clases/04-modificar-datos/) |
| 5 | 14 ago | Consultar el modelo propio · JOIN, fan-out y LEFT JOIN | SQLite | [clase](clases/05-consultar-modelo/) |
| 6 | 17 ago | Sensores: el tiempo como problema | SQLite | [clase](clases/06-series-de-tiempo/) |
| 7 | 18 ago | Funciones de ventana · rankings, `LAG` y medias móviles | SQLite | [clase](clases/07-funciones-ventana/) |
| 8 | 19 ago | Vistas · la capa de reporte, y la que nadie auditó | SQLite | [clase](clases/08-vistas/) |
| 9 | 20 ago | Índices · `EXPLAIN QUERY PLAN` y cien mil filas | SQLite | [clase](clases/09-indices/) |
| 10 | 21 ago | Calidad de datos y auditoría · `CHECK`, triggers y bitácora | SQLite | [clase](clases/10-calidad-auditoria/) |
| **11** | **24 ago** | **PL/SQL sobre Oracle · fila por fila es lento por lento** | **Oracle** | [clase](clases/11-plsql-oracle/) |
| **12** | **25 ago** | **Datos que llegan de afuera · staging, `LOG ERRORS` y `MERGE`** | **Oracle** | [clase](clases/12-carga-externa/) |
| **13** | **26 ago** | **Oracle en tu máquina y Power BI conectado** | **Oracle local + Power BI** | [clase](clases/13-oracle-local-powerbi/) |
| **14** | **28 ago** | **Del reporte plano al modelo dimensional · hechos, dimensiones y la estrella** | **Oracle local + Power BI** | [clase](clases/14-modelo-dimensional/) |
| **15** | **4 sep** | **La medida y el contexto · DAX, contexto de filtro y el denominador que nadie mira** | **Power BI (CSV)** | [clase](clases/15-dax-contexto/) |
| **16** | **8 sep** | **Comparar contra el año pasado · inteligencia de tiempo y el año que todavía no termina** | **Power BI (CSV)** | [clase](clases/16-inteligencia-tiempo/) |
| **17** | **9 sep** | **La meta que no sabe de cultivos · dos tablas de hechos, dos granularidades y una medida que se calla** | **Power BI (CSV)** | [clase](clases/17-dos-hechos/) |
| **18** | **10 sep** | **Lo que cada quien puede ver · seguridad a nivel de fila y un filtro que no llega a donde creías** | **Power BI (CSV)** | [clase](clases/18-seguridad-filas/) |
| **19** | **14 sep** | **Un rol para todos · seguridad dinámica, y una tabla de permisos que no protegía nada** | **Power BI (CSV)** | [clase](clases/19-seguridad-dinamica/) |
| **20** | **15 sep** | **El Top 3 que tenía dos · rankings con `RANKX`, y un podio que competía contra lo que no se veía** | **Power BI (CSV)** | [clase](clases/20-ranking-top-n/) |
| **21** | **16 sep** | **El total que se comió el faltante · totales de medidas con `SUMX`, y una fila de total que no era la suma de nada** | **Power BI (CSV)** | [clase](clases/21-totales-sumx/) |

---

## Dónde estamos

Las diez primeras clases fueron **SQLite**: modelar, modificar, consultar, medir y auditar, siempre sobre el mismo AgroDB.

Desde la clase 11 el curso cambia de motor. No porque SQLite se quede corto para aprender —no se queda—, sino porque hay una lección que solo se aprende cruzando: **cuánto de lo que uno sabe es SQL y cuánto es el dialecto en el que lo aprendió.** El `* 1.0` que venimos escribiendo desde la clase 5 resulta que nunca fue una regla de SQL.

Desde la 12, el motor deja de ser la novedad y pasa a ser la herramienta: lo que entra a la base **ya no lo escribe una persona**, lo deja un proceso a las seis de la mañana, y hay que decidir qué pasa cuando ese proceso corre dos veces.

Y en la 13 el curso sale del navegador: **Oracle se instala en la máquina de cada quien** y Power BI se conecta a él. No por gusto de instalar cosas, sino porque un servicio de navegador no expone un puerto, y una herramienta de BI no lee pantallas: se conecta a un servidor. La idea de esa clase es la que ordena todo lo que sigue: **un tablero no se conecta a una base, se conecta a lo que la base le deja ver.**

Y en la 14 se le da forma a lo que la 13 conectó. Ayer el tablero leyó **una vista plana**; hoy lee **un modelo**: los kilos en una tabla de hechos, la finca, el cultivo y la fecha en tablas de dimensión. Eso se llama **estrella**, y trae consigo el error más silencioso del curso: un calendario que no cubre marzo hace que el tablero diga **19 750** en vez de 30 550, con las nueve cosechas cargadas y sin un solo mensaje de error.

Y en la 15 el curso cruza del todo al otro lado: **no se prende Oracle**. La fuente son cuatro CSV, el modelo es el mismo, y lo que se aprende es a escribir **medidas** en DAX en vez de arrastrar campos. Cambiar la fuente entera sin que el tablero se entere no es una casualidad: es lo que se ganó construyendo la estrella en la 14. Y el error del día ya no es un número más chico, es peor: un promedio de **5 091,67** que está mal y que **se puede defender en una junta**.

Y en la 16 llega el histórico: la campaña **2025** entera, y con ella la primera tabla de hechos del curso que cubre **dos años**. Por primera vez en once clases el 30 550 deja de ser el total y pasa a ser el total de 2026, intacto adentro de 77 550. Con dos años ya se puede escribir la comparación más pedida del mundo —contra el año pasado—, y la tarjeta dice que la cosecha **cayó 35 %**. Estamos en septiembre y 2026 tiene cosechas hasta el 30 de abril: se comparó **cuatro meses contra doce**. Lo nuevo es el arreglo: la misma medida, **sin cambiar un carácter**, pasa a **+30 %** cuando se recorta el contexto. La medida nunca estuvo mal; contestaba bien una pregunta que nadie hizo.

Y en la 17 el modelo deja de tener **un** hecho al centro. Llega `h_meta` —la meta que la gerencia fijó para 2026, **47 000 kilos**, los mismos que se cosecharon en 2025— y llega con dos cosas que `h_cosecha` no tiene: se capturó **por mes**, no por día, y **no sabe de cultivos**, porque las metas se fijan por finca. Partida por finca, la medida funciona y la columna suma su propio total. Partida por cultivo —la misma medida, cambiando nada más la dimensión de las filas— **la meta dice 24 440 en las seis filas**, Banano y Café aparecen con meta sin haber cosechado un kilo en dos años, y los porcentajes **suman 125,00 exacto**, así que el error pasa la revisión obvia. Lo nuevo es el arreglo: no es una función más lista ni un contexto más chico, es **enseñarle a la medida a no contestar**. Once clases diciendo *qué avisó — nada*, y hoy el aviso aparece porque lo escribimos nosotros, con un `BLANK()`.

Y en la 18 el tablero se le manda por primera vez a **alguien**: el gerente de La Unión, con el requisito de que vea su finca y nada más. Eso es un **rol**, y la primera versión es la obvia —el filtro en `h_cosecha`, porque ahí están los kilos—. Funciona: viendo como el gerente, los kilos dicen 2 100. Pero la meta dice **24 440**, la de toda la empresa, el cumplimiento **8,59 %** en vez de **42,00 %**, y la tabla por finca le enseña **el presupuesto de las otras dos**. La seguridad también es un filtro, y viaja solo por las relaciones: desde `h_cosecha` no llega a `h_meta`. Lo atrapa el `[Filas de meta]` de ayer, que no se mueve con el rol, y se arregla subiendo la condición a `dim_finca`. En la clase 13 Oracle contestó `ORA-00942`; hoy nadie contestó nada.

Y en la 19 se pasa de tres roles escritos a mano a **uno solo para todos**: llega `seguridad.csv`, una tabla con un correo y una finca por permiso, y el rol pregunta quién está mirando con `USERPRINCIPALNAME()`. La primera versión pone la condición donde está el correo, en la tabla de permisos, y sí filtra: la lista de permisos baja a una fila. Pero el gerente de La Unión lee **30 550** kilos y **125,00 %**, y un practicante que no está en la tabla **ve la empresa entera**. La tabla de permisos es una tabla más, y el filtro no sube de ella a `dim_finca`. La condición va en la dimensión y **consulta** la tabla: con `LOOKUPVALUE` funciona para los gerentes y **truena con el regional**, que tiene dos fincas —el único error con mensaje de la semana, y el bueno—, y con `IN` y `CALCULATETABLE` el regional ve sus dos fincas, **113,23 %**, y el practicante no ve nada.

Y en la 20 nadie se esconde de nadie: la pregunta es la más vieja de los tableros, **¿quiénes son los primeros?** Un Top 3 es un filtro sobre un lugar, y el lugar se calcula con `RANKX`. La primera versión pone **a los cuatro cultivos en primer lugar**, porque en cada fila la carrera tiene un solo corredor; con `ALL` los lugares salen bien, y callando los vacíos queda un Top 3 de **28 450** kilos. Pero en cuanto el gerente marca **perenne** en un segmentador, el Top 3 **se queda con dos filas**: Mango en 1, Guayaba en **3**, y el Cacao fuera. `ALL` quitó también el filtro del segmentador, y el maíz, escondido en la pantalla, **siguió compitiendo y se quedó con el segundo lugar**. Con `ALLSELECTED` el ranking compite contra lo que se está viendo y el Top 3 suma **20 750**. Las dos medidas están bien: contestan preguntas distintas, y **el tablero no dice cuál escogiste**.

Y en la 21 la pregunta es la más inocente de todas: **la última fila de la tabla**. La gerencia paga bono por cada kilo arriba de la meta y apoyo por cada kilo abajo, y las dos medidas son de una línea: `MAX( 0 , [Kilos] - [Meta] )`. Por finca salen bien —El Guayabo **4 810**, Santa Rosa **4 200**, La Unión **2 900** de faltante—, pero el total dice **6 110** de bono y **0** de faltante, cuando la columna suma 9 010 y 2 900. La fila del total **no suma las filas**: vuelve a hacer la cuenta con toda la empresa, y ahí el faltante de La Unión **se compensa** con el bono de las otras dos. Con el año completo las tres fincas están abajo de la meta y el total cuadra, así que la prueba de siempre no lo atrapa. `SUMX` sobre las fincas lo arregla, y en cuanto el gerente lo pide **por mes** vuelve a pasar: la columna suma **18 450** y el total dice 9 010. Las tres cifras salen de la misma línea, recorrida de tres maneras, y **cuál es el bono lo decide la regla, no DAX**.

> **Nota de idioma:** el material de la clase 13 en adelante está redactado en español de México. Las clases 1 a 12 conservan la redacción original.

---

## El hilo del curso

Si hay una sola cosa que llevarse de las veintiún clases, es esta:

**Los errores que dan error son los baratos.**

| Clase | Qué pasó | Qué avisó |
|---|---|---|
| 5 | un `SUM` inflado por fan-out | nada |
| 6 | un `-99` disfrazado de temperatura | nada |
| 8 | `CREATE VIEW IF NOT EXISTS` no reemplazó nada | nada |
| 9 | un `SEARCH` que leía media tabla | nada |
| 10 | cinco filas imposibles cargadas con las claves apagadas | nada |
| 11 | dos `INSERT` que fallaron adentro de un `WHEN OTHERS THEN NULL` | nada |
| 12 | una carga que terminó «bien» con ocho filas rechazadas | nada |
| 13 | un tablero en modo Importar mostrando los datos de la semana pasada | nada |
| 14 | una dimensión de tiempo que no cubría marzo, y 10 800 kilos que se evaporaron | nada |
| 15 | un promedio dividido entre seis cultivos cuando sólo cuatro habían cosechado | nada |
| 16 | una caída del 35 % que comparaba cuatro meses contra doce | nada |
| 17 | una meta mensual por finca repartida entre cultivos que no existen en ella | nada — **hasta que la medida aprendió a callarse** |
| 18 | un rol puesto en la tabla de cosechas que le enseñó al gerente de una finca la meta de toda la empresa | nada — **pero el `[Filas de meta]` de ayer lo atrapó** |
| 19 | un rol puesto en la tabla de permisos que le dejó la empresa entera a cada gerente, y a quien no tenía ningún permiso | nada — **el único error con mensaje fue el del arreglo a medias** |
| 20 | un Top 3 de cultivos perennes que salió con dos filas, porque el ranking competía contra el maíz que el segmentador escondía | nada — **y el `ALL` que lo causó fue el mismo que arregló el primer intento** |
| 21 | un faltante de 2 900 kilos que la fila del total borró, porque restó la meta de la empresa contra la cosecha de la empresa | nada — **el total estaba bien calculado: la suma era la que nadie hizo** |

---

## Regla de los 20 minutos

Si llevás veinte minutos trabado en el mismo error: escribís la duda como comentario en tu archivo empezando con `DUDA`, o abrís un issue, y seguís con lo siguiente. **Trabarse no baja la nota. Quedarse callado sí te cuesta la clase entera.**

## Y una regla para el material

El enunciado también se audita. Van cinco errores encontrados corrigiendo —las «6 filas» del ejercicio 3, la rúbrica del 8 que sumaba 105 diciendo 100, el eje del punto de control 3 del 16, y en la clase 11 el `SQLERRM` de las diapositivas y las «cuatro de cinco» del A1—, y los cinco están anotados en la [página de resultados](https://negatix092.github.io/Semillero_SQL/resultados.html) con nombre y apellido. Si un número del enunciado no te cierra, **no lo fuerces: documentá la discrepancia.** Eso puntúa.
