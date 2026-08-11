# Curso de SQL · AgroDB

Base de datos para gestión agrícola, construida clase a clase.
Todo el material del curso vive acá: diapositivas, scripts, ejercicios y entregas.

**Diapositivas online:** https://USUARIO.github.io/curso-sql-agrodb/
**Entorno de trabajo:** [sqliteonline.com](https://sqliteonline.com) (elegir SQLite)

---

## Cómo se usa este repo

| Si sos… | Hacés esto |
|---|---|
| Alumno, quiero ver la clase | Entrás al link de diapositivas, o abrís `clases/NN-tema/slides.md` |
| Alumno, quiero entregar | Hacés *fork* → rama → tu archivo en `entregas/` → *pull request*. Ver [CONTRIBUTING.md](CONTRIBUTING.md) |
| Alumno, estoy trabado | Abrís un *issue* con la plantilla **Duda**. No es penalizado: es parte del curso |
| Instructor | `clases/NN-tema/README.md` tiene la guía docente de cada sesión |

---

## Estructura

```
clases/        una carpeta por sesión: guía docente, diapositivas y ejercicio
datos/         scripts .sql que hay que ejecutar antes de cada práctica
entregas/      una carpeta por alumno, creada por ustedes vía pull request
recursos/      chuletas de sintaxis y material de consulta
proyecto-final/ enunciado y rúbrica
cronograma.md  el plan completo hasta el 29 de agosto
```

---

## Clases

| # | Fecha | Tema | Material |
|---|---|---|---|
| 1 | 4 ago | SELECT, WHERE, GROUP BY, JOIN, LEFT JOIN | — |
| 2 | 5 ago | CASE, COALESCE, subconsultas, CTE, ventanas | — |
| P1 | 6 ago | Proyecto 1 · diseñá tu propia base | — |
| **3** | **11 ago** | **Del requerimiento al modelo · normalización y N:M** | [clase](clases/03-modelado/) |
| 4 | 12 ago | INSERT / UPDATE / DELETE y transacciones | — |
| 5 | 13 ago | Consultar el modelo propio | — |
| 6 | 14 ago | Sensores: series de tiempo | — |

El plan completo está en [cronograma.md](cronograma.md).

---

## Regla de los 20 minutos

Si llevás veinte minutos trabado en el mismo error: escribís la duda como comentario en tu archivo empezando con `DUDA`, o abrís un issue, y seguís con lo siguiente. **Trabarse no baja la nota. Quedarse callado sí te cuesta la clase entera.**
