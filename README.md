# Semillero SQL · AgroDB

Base de datos para gestión agrícola, construida clase a clase.
Todo el material del curso está aquí: diapositivas, scripts, ejercicios y entregas.

**Diapositivas online:** https://negatix092.github.io/Semillero_SQL/
**Notas y correcciones:** https://negatix092.github.io/Semillero_SQL/resultados.html
**Entorno de trabajo:** [sqliteonline.com](https://sqliteonline.com) (SQLite, clases 1 a 10) · [freesql.com](https://freesql.com) (Oracle, desde la clase 11)
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

---

## Dónde estamos

Las diez primeras clases fueron **SQLite**: modelar, modificar, consultar, medir y auditar, siempre sobre el mismo AgroDB.

Desde la clase 11 el curso cambia de motor. No porque SQLite se quede corto para aprender —no se queda—, sino porque hay una lección que solo se aprende cruzando: **cuánto de lo que uno sabe es SQL y cuánto es el dialecto en el que lo aprendió.** El `* 1.0` que venimos escribiendo desde la clase 5 resulta que nunca fue una regla de SQL.

Lo que sigue después: **Power BI** conectado a esta misma base, que es la capa de arriba. El motor primero, el tablero después.

---

## El hilo del curso

Si hay una sola cosa que llevarse de las once clases, es esta:

**Los errores que dan error son los baratos.**

| Clase | Qué pasó | Qué avisó |
|---|---|---|
| 5 | un `SUM` inflado por fan-out | nada |
| 6 | un `-99` disfrazado de temperatura | nada |
| 8 | `CREATE VIEW IF NOT EXISTS` no reemplazó nada | nada |
| 9 | un `SEARCH` que leía media tabla | nada |
| 10 | cinco filas imposibles cargadas con las claves apagadas | nada |
| 11 | dos `INSERT` que fallaron adentro de un `WHEN OTHERS THEN NULL` | nada |

---

## Regla de los 20 minutos

Si llevás veinte minutos trabado en el mismo error: escribís la duda como comentario en tu archivo empezando con `DUDA`, o abrís un issue, y seguís con lo siguiente. **Trabarse no baja la nota. Quedarse callado sí te cuesta la clase entera.**

## Y una regla para el material

El enunciado también se audita. Van dos errores encontrados corrigiendo —las «6 filas» del ejercicio 3 y la rúbrica del 8 que sumaba 105 diciendo 100—, y los dos están anotados en la [página de resultados](https://negatix092.github.io/Semillero_SQL/resultados.html) con nombre y apellido. Si un número del enunciado no te cierra, **no lo fuerces: documentá la discrepancia.** Eso puntúa.
