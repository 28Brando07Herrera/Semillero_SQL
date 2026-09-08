# Clase 14 · Del reporte plano al modelo dimensional
**Viernes 28 de agosto**

**50 minutos de clase** y el resto de práctica. Es la clase que le da forma a lo que ayer se conectó: ayer el tablero leyó **una vista**; hoy va a leer **un modelo**.

## Material

| Qué | Dónde |
|---|---|
| Diapositivas | [slides.md](slides.md) · [versión web](https://negatix092.github.io/Semillero_SQL/14-modelo-dimensional.html) |
| Ejercicio práctico | [ejercicio.md](ejercicio.md) |
| Script de la base | [`datos/agrodb_oracle_clase14.sql`](../../datos/agrodb_oracle_clase14.sql) |

> **Hoy sí hay script nuevo**, y trae **doce** números, no trece: `staging_lecturas` era el tema de la clase 12 y hoy no se usa.
>
> **El script borra tu `v_bi_produccion` de ayer.** A propósito: el script de cada día se escribe para no traer resuelto el ejercicio del día anterior. Se reescribe en la parte A del ejercicio y son treinta segundos.

## Qué hace falta tener listo

| | |
|---|---|
| Oracle local | el de la clase 13, prendido |
| Usuario `agro` | `sqlplus agro/Agro2026@localhost:1521/FREEPDB1` |
| Usuario `bi_agro` | ya existe; los usuarios no se borran al recargar tablas |
| Power BI + OCMT | ya instalados en la clase 13 |

> **¿No pudiste instalar Oracle ayer?** Hoy no es un bloqueo. **85 de los 100 puntos del ejercicio se hacen en [FreeSQL](https://freesql.com)**: son tablas, `INSERT … SELECT` y consultas. Ver el Plan B del [ejercicio](ejercicio.md).

## De qué se trata

Ayer construyeron `v_bi_produccion`: una vista ancha, plana, con la finca, el lote, el cultivo, la fecha y los kilos, todo en la misma fila. Dio 9 filas y 30 550 kilos, Power BI la leyó y el tablero salió bien.

Con nueve filas eso funciona. Con nueve millones, no:

- `Hacienda Santa Rosa` se escribe una vez **por cada fila**.
- «Kilos por trimestre» obliga a calcular el trimestre **en cada consulta**.
- Filtrar por finca es **comparar texto**, y un espacio de más borra una finca del reporte.

El modelo dimensional separa **lo que se mide** de **lo que describe**. Los kilos van a una tabla de hechos; la finca, el cultivo y la fecha van a tablas de dimensión. El dibujo que sale se llama **estrella**.

## Las dos palabras del día

| | **Hecho** | **Dimensión** |
|---|---|---|
| Qué guarda | lo que se mide | lo que describe |
| En AgroDB | `h_cosecha` (los kilos) | `dim_finca`, `dim_cultivo`, `dim_tiempo` |
| Cuántas filas | muchas, crecen a diario | pocas, casi no cambian |
| Cómo se lee | se **suma** | se **agrupa** y se **filtra** |

Regla práctica: **si tiene sentido sumarla, es un hecho. Si tiene sentido ponerla en un `GROUP BY`, es una dimensión.**

## Lo que hay que saber al terminar

- Qué es un **hecho** y qué es una **dimensión**, y cómo se decide cuál es cuál
- Qué es el **grano** de una tabla de hechos, y por qué se escribe antes de crear la tabla
- Por qué el calendario es **una tabla** y no un `EXTRACT` repetido en cada consulta
- Cómo se carga una estrella: el `JOIN` de cinco tablas se escribe **una sola vez**
- Que en Oracle un `DATE` **trae la hora adentro**, y por qué eso hace que `TRUNC` no sea opcional
- Que una **dimensión con filas de sobra** está bien, y un **hecho con claves huérfanas** es un desastre
- Detectar huérfanos con `LEFT JOIN … IS NULL`, y la consulta de control origen-contra-estrella
- Que una **clave foránea** en la tabla de hechos convierte un error silencioso en un `ORA-02298`
- La diferencia entre **estrella** y **copo de nieve**, y por qué hoy se elige estrella
- Cargar **cuatro tablas relacionadas** en Power BI y revisar las relaciones a mano

## La idea del día

**Una dimensión incompleta no da error. Da un número más chico.**

## Las cuatro cosas que son la clase

Si el día se complica y hay que recortar, estas no se recortan:

1. **Hecho y dimensión.** Dos palabras, y con ellas se lee cualquier modelo de BI del mundo.
2. **El grano.** Se decide primero y se escribe en la tabla. Elegirlo mal no da error: da un `SUM` que nadie puede explicar.
3. **El 19 750.** Ver el número equivocarse en vivo, sin un solo mensaje de error.
4. **El `ORA-02298`.** La restricción que convierte ese silencio en un error con nombre.

## El número de control

**30 550 kilos**, otra vez. Pero hoy el recorrido incluye una parada en un número falso:

| Dónde | Qué debe decir |
|---|---|
| `SELECT SUM(kg) FROM cosechas` | 30550 |
| `SELECT SUM(kg) FROM h_cosecha` | 30550 (**9 filas**) |
| La estrella con `dim_tiempo` **de abril** | **19750** ← el error del día |
| La estrella con `dim_tiempo` **completa** | 30550 |
| La tarjeta de Power BI | 30550 |

Y los huérfanos que explican la diferencia: **3 filas, 10 800 kilos**, las tres cosechas de marzo.

> El desglose por finca correcto sigue siendo **Finca El Guayabo 14 250 · Hacienda Santa Rosa 14 200 · Agricola La Union 2 100**. Con el calendario roto da **14 250 / 4 600 / 900**, y lo que más asusta es que Guayabo **no se mueve**: sólo cambian las otras dos.

## Entrega

En `entregas/apellido-nombre/`, por *pull request*, **dos archivos**:

| Archivo | Qué lleva |
|---|---|
| `Ejercicio14_Apellido_Nombre.sql` | las consultas con **su resultado pegado como comentario** debajo de cada una, y las respuestas de la parte F |
| `clase14-modelo.png` | captura de la vista **Modelo** de Power BI, con las **tres relaciones** visibles |

> La captura de hoy **no es la gráfica**: es el diagrama del modelo. La gráfica ya la entregaron ayer; lo nuevo es que Power BI recibió un modelo y no una tabla.

## Nota sobre el material

Los números de AgroDB de esta clase —las 9 filas, los 30 550, los 19 750, los 3 huérfanos con 10 800 kilos y el desglose por finca y por cultivo— están **verificados contra el script publicado** con `docente/clase14_verificacion_docente.py`.

Los nombres de menú de Power BI y el texto literal de los `ORA-` dependen de la versión y del idioma de cada máquina. Si en la tuya algo se llama distinto, **anótalo en la entrega: eso puntúa**, igual que documentar una discrepancia del enunciado.
