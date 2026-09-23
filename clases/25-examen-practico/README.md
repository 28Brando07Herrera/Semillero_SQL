# Clase 25 · Examen práctico
**Miércoles 23 de septiembre**

**90 minutos, individual, en un formulario de Google.** No hay tema nuevo: hoy se mide lo que ya se vio. La primera parte es SQL sobre AgroDB, en SQLite, y la segunda es Power BI sobre los CSV de la clase 19.

## Material

| Qué | Dónde |
|---|---|
| El formulario | el enlace lo manda el instructor por el chat al empezar |
| Parte 1 · SQL | [`datos/agrodb_clase7.sql`](../../datos/agrodb_clase7.sql), en [sqliteonline.com](https://sqliteonline.com) |
| Parte 2 · Power BI | tu `.pbix` de la clase 24, o los seis CSV de [`datos/csv_clase19/`](../../datos/csv_clase19/) |

## Qué hace falta tener listo, antes de que empiece el reloj

| | |
|---|---|
| sqliteonline.com | abierto, con `datos/agrodb_clase7.sql` pegado **completo** y ejecutado. Comprueba que `SELECT COUNT(*) FROM lecturas;` da **973** |
| Power BI Desktop | con tu `.pbix` de la clase 24 abierto, **Ver como apagado** y **sin nada marcado en los segmentadores** |
| Si no tienes el `.pbix` de la 24 | copia `datos/csv_clase19/` a `C:\agrodb25\` y arma el modelo como en la parte A de la clase 24: seis tablas, seis relaciones muchos a uno, `dim_tiempo` marcada como tabla de fechas. Cuesta unos 15 minutos, así que hazlo **antes** |
| Oracle, Docker, el OCMT | **no** |

## Cómo es

| Parte | Tiempo sugerido | Puntos | De qué clases |
|---|---|---|---|
| 1 · SQL | unos 35 minutos | **40** (10 preguntas × 4) | 3 a 10: `JOIN`, `LEFT JOIN`, `NULL`, `GROUP BY`, subconsultas, fechas, funciones de ventana, división entera |
| 2 · Power BI | unos 50 minutos | **60** (10 preguntas × 6) | 14 a 23: relaciones, contexto de filtro, inteligencia de tiempo, dos hechos, seguridad por filas, `RANKX`, `SUMX`, tablas desconectadas, formato condicional |

- **Cada pregunta se contesta con un número que tú sacas del motor**, y se elige entre opciones.
- **Las opciones incorrectas no son al azar.** Cada una es el número que da un error que ya vimos en el curso. Si tu número no está entre las opciones, tu consulta o tu medida tiene algo: revísala antes de adivinar.
- En algunas preguntas se pide **pegar la consulta o la medida** que usaste. Esas no suman puntos, pero sirven para revisar tu respuesta si la opción no cuadra.
- Los decimales de SQL van **con punto**, como los imprime SQLite. Los de Power BI, **con coma y dos decimales**, como los enseña Power BI.

## Reglas

- **Individual.** Se puede usar todo el repositorio, tus apuntes y tus ejercicios anteriores. No se le pregunta a un compañero.
- **Un solo envío.** Revisa antes de mandar: el formulario no deja editar la respuesta.
- La calificación **no sale en cuanto envías**: sale cuando el instructor revisa las consultas que pegaste.
- Si una pregunta te parece mal planteada, **contéstala con lo que te dio el motor y escríbelo en la consulta que pegas**: eso se revisa. El enunciado también se audita.

## Regla de los 20 minutos, versión examen

Si llevas **cinco minutos** atorado en la misma pregunta, déjala y sigue. Al final regresas. Una pregunta vale 4 o 6 puntos; quedarte media hora en ella te cuesta las que ya no alcanzaste a contestar.

## Nota sobre el material

Cada opción de cada pregunta —la buena y las incorrectas— se recalculó con un script: la parte de SQL, **corriendo** `datos/agrodb_clase7.sql` en SQLite; la de Power BI, rehaciendo la aritmética de cada medida sobre los CSV publicados, con el contexto de filtro y el rol. **Nada de la parte de Power BI se corrió en Power BI.** Si algo sale distinto en tu máquina, anótalo en la consulta que pegas: eso puntúa.
