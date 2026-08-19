# Semillero SQL · AgroDB

Base de datos para gestión agrícola, construida clase a clase.
Todo el material del curso está aquí: diapositivas, scripts, ejercicios y entregas.

**Diapositivas online:** https://negatix092.github.io/Semillero_SQL/
**Entorno de trabajo:** [sqliteonline.com](https://sqliteonline.com) (elegir SQLite)
**¿Preferís trabajar en tu máquina?** [Guía de entorno local](recursos/entorno-local-sqlite.md) — opcional, y recomendada de acá en adelante

---

## Cómo se usa este repo

| Si eres… | Haces esto |
|---|---|
| Alumno, quiero ver la clase | Entras al link de diapositivas, o abrís `clases/NN-tema/slides.md` |
| Alumno, quiero entregar | Haces *fork* → rama → tu archivo en `entregas/` → *pull request*. Ver [CONTRIBUTING.md](CONTRIBUTING.md) |
| Alumno, estoy trabado | Abres un *issue* con la plantilla **Duda**. No es penalizado: es parte del curso |
| Instructor | `clases/NN-tema/README.md` tiene la guía docente de cada sesión |

---

## Estructura

```
clases/         una carpeta por sesión: guía docente, diapositivas y ejercicio
datos/          scripts .sql que hay que ejecutar antes de cada práctica
entregas/       una carpeta por alumno, creada vía pull request
recursos/       chuletas de sintaxis y material de consulta
proyecto-final/ enunciado y rúbrica
```

---

## Clases

| # | Fecha | Tema | Material |
|---|---|---|---|
| 1 | 4 ago | SELECT, WHERE, GROUP BY, JOIN, LEFT JOIN | — |
| 2 | 5 ago | CASE, COALESCE, subconsultas, CTE, ventanas | — |
| P1 | 6 ago | Proyecto 1 · diseñá tu propia base | — |
| 3 | 12 ago | Del requerimiento al modelo · normalización y N:M | [clase](clases/03-modelado/) |
| 4 | 13 ago | INSERT / UPDATE / DELETE y transacciones | [clase](clases/04-modificar-datos/) |
| 5 | 14 ago | Consultar el modelo propio · JOIN, fan-out y LEFT JOIN | [clase](clases/05-consultar-modelo/) |
| 6 | 17 ago | Sensores: el tiempo como problema | [clase](clases/06-series-de-tiempo/) |
| 7 | 18 ago | Funciones de ventana · rankings, `LAG` y medias móviles | [clase](clases/07-funciones-ventana/) |
| **8** | **19 ago** | **Vistas · la capa de reporte, y la que nadie auditó** | [clase](clases/08-vistas/) |

---

## Regla de los 20 minutos

Si llevás veinte minutos trabado en el mismo error: escribís la duda como comentario en tu archivo empezando con `DUDA`, o abrís un issue, y seguís con lo siguiente. **Trabarse no baja la nota. Quedarse callado sí te cuesta la clase entera.**
