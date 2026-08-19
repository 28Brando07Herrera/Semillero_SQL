# Ejercicio práctico 8 · El tablero que nadie auditó
**Duración: 2 horas · Individual · sqliteonline.com (o tu SQLite local) · Entrega: un archivo `.sql`**

---

## La situación

Ayer escribieron veinte consultas. Hoy la base no se acuerda de ninguna.

Lo que sí quedó, porque alguien lo dejó escrito hace meses, son **dos vistas**: `v_temp_diaria` y `v_alertas_sensores`. Vienen con la base. Corren sin error. Devuelven algo que parece razonable. El tablero de la finca las consulta todas las mañanas.

Una de las dos está mal desde el día que se escribió, y nadie se dio cuenta porque **por afuera una vista no se distingue de otra**.

Hoy hacen dos cosas: construyen la capa de reporte que faltaba, y auditan la que ya estaba.

## Antes de empezar

1. **Pestaña nueva** en sqliteonline.com → SQLite.
2. Pegá `datos/agrodb_clase8.sql` completo y ejecutalo. Deben salir **3, 6, 8, 10, 7, 19, 16, 6, 9, 973, 2**.
   Los diez primeros son los mismos de ayer. El **2** es nuevo: son las vistas.
3. Trabajá en `Ejercicio8_Apellido_Nombre.sql`.

## La regla del día

> **Una vista es una opinión con nombre.**
>
> El que la consulta hereda todas tus decisiones: qué filtraste, qué agrupaste, qué redondeaste, qué columna elegiste no mostrar. Y no tiene forma de saber cuáles fueron.
>
> Toda vista que entregues hoy tiene que poder defenderse sola: filtro explícito, conteo a la vista, y un nombre que diga qué contiene de verdad.

Y siguen vigentes las de siempre: **todo reporte que mencione un lote dice también la finca**, y **ningún promedio se entrega sin su `COUNT(*)`**.

---

## Parte A · La consulta que se queda (20 min)

**A1.** Creá `v_lote_finca`: cada lote con su finca, su código, sus hectáreas y su tipo de suelo. Es el JOIN que vienen escribiendo desde la clase 5, guardado de una vez.

```sql
CREATE VIEW v_lote_finca AS
SELECT ...;
```

Esperado: `SELECT COUNT(*) FROM v_lote_finca;` da **8 filas**.

**A2.** Usala como si fuera una tabla: los lotes de `Hacienda Santa Rosa`, ordenados por hectáreas de mayor a menor.
Esperado: **3 filas** — `L-02` (31), `L-01` (28.5), `L-03` (19.25).

Fijate que en esta consulta **no escribiste ningún `JOIN`**. Ese es el punto.

**A3.** En un comentario: ¿dónde están guardados los datos que devuelve `v_lote_finca`? Si mañana alguien hace `UPDATE lotes SET hectareas = 40 WHERE lote_id = 2`, ¿qué devuelve la vista? ¿Y por qué?

---

## Parte B · El tablero de producción (30 min)

**B1.** Creá `v_produccion_lote` con: `finca`, `lote`, `hectareas`, `n_cosechas`, `kg_total` y `kg_ha`.
Esperado: **6 filas**, exactamente estas.

| finca | lote | hectareas | n_cosechas | kg_total | kg_ha |
|---|---|---|---|---|---|
| Agricola La Union | A-1 | 55 | 2 | 2100 | 38.18 |
| Finca El Guayabo | L-01 | 22 | 2 | 4450 | 202.27 |
| Finca El Guayabo | L-02 | 18.5 | 1 | 9800 | 529.73 |
| Hacienda Santa Rosa | L-01 | 28.5 | 2 | 7300 | 256.14 |
| Hacienda Santa Rosa | L-02 | 31 | 1 | 5400 | 174.19 |
| Hacienda Santa Rosa | L-03 | 19.25 | 1 | 1500 | 77.92 |

> **El `* 1.0` otra vez, y hoy es la última vez que se los aviso.** Si te da `202.0` en vez de `202.27`, te falta. La diferencia con ayer: ayer se equivocaba tu consulta. Hoy se equivoca la de todo el que use la vista, todos los días, hasta que alguien la abra.

**B2.** Creá `v_produccion_finca` **consultando `v_produccion_lote`**, no las tablas. Con: `finca`, cuántos lotes, kilos totales y kg/ha de la finca.
Esperado: **3 filas**.

| finca | lotes | kg | kg_ha |
|---|---|---|---|
| Agricola La Union | 1 | 2100 | 38.18 |
| Finca El Guayabo | 2 | 14250 | 351.85 |
| Hacienda Santa Rosa | 3 | 14200 | 180.32 |

En un comentario: ¿cuántos `JOIN` escribiste en B2? ¿Sobre cuántas tablas está corriendo esa consulta en realidad?

**B3 — la vista sigue a los datos.** Corré esto en orden y anotá los tres resultados:

```sql
SELECT kg_total, n_cosechas, kg_ha FROM v_produccion_lote
 WHERE finca LIKE 'Hacienda%' AND lote = 'L-01';

INSERT INTO cosechas (siembra_id, fecha, kg, calidad, destino)
VALUES (1, '2026-05-02', 500, 'primera', 'mercado local');

SELECT kg_total, n_cosechas, kg_ha FROM v_produccion_lote
 WHERE finca LIKE 'Hacienda%' AND lote = 'L-01';

DELETE FROM cosechas WHERE fecha = '2026-05-02';
```

Esperado: **7300 / 2 / 256.14**, después **7800 / 3 / 273.68**, y al borrar vuelve a 7300.

En un comentario: nadie ejecutó un `UPDATE` sobre la vista. ¿Por qué cambió el número? Contestá con la palabra "pregunta" adentro.

**B4 — la trampa del `IF NOT EXISTS`.** Ejecutá tal cual:

```sql
CREATE VIEW IF NOT EXISTS v_produccion_lote AS SELECT 1 AS chiste;
SELECT * FROM v_produccion_lote;
```

¿Dio error? ¿Qué devolvió el `SELECT`? En un comentario, dos líneas: qué hizo SQLite con tu `CREATE`, y por qué esto es más peligroso que un error.

---

## Parte C · El tablero que ya estaba publicado (35 min)

Esta es la parte del día.

**C1.** Corré `SELECT COUNT(*) FROM v_temp_diaria;`
Esperado: **35**.

Nuestras lecturas de temperatura son de abril, y abril tiene 30 días. En un comentario, antes de investigar nada: escribí tu hipótesis de dónde salen las cinco de más.

**C2.** Ahora abrí la vista. La definición está guardada como texto:

```sql
SELECT sql FROM sqlite_master WHERE type = 'view';
```

Leela y contestá, en comentarios:
1. ¿Qué filtra el `WHERE` de esa vista? ¿Y qué **no** filtra?
2. Listá los sensores de tipo `temperatura` con su `activo` y sus fechas de lectura. ¿Cuántos son?
3. Entonces: ¿de dónde salen los cinco días de más, y de qué mes son?

*Pista:* `SELECT sensor_id, tipo, activo FROM sensores WHERE tipo = 'temperatura';` — son tres, no uno.

**C3.** Armá el ranking de días más calurosos **usando la vista tal como está**, con `RANK()`.
Esperado: **35 filas**, el primer puesto es `2026-04-20` con `27.33`, y el segundo puesto es un empate de **10 días** en `25.63`.

En un comentario: de esos diez empatados, ¿cuántos son de un sensor que está dado de baja? ¿Un tablero que muestra ese top 10 está informando o está mintiendo?

**C4 — el segundo problema, que no es el mismo.** `v_temp_diaria` devuelve dos columnas: `dia` y `temp_promedio`.

1. El 20 de abril está primero otra vez. Ayer supiste por qué. **¿Puede alguien que solo tiene esta vista darse cuenta?** Sí o no, y por qué.
2. ¿Qué columna, de una sola palabra, habría alcanzado para que se notara?
3. Ayer ese error duró una consulta. Escrito en una vista, ¿cuánto dura?

**C5.** Escribí `v_temp_diaria_v2`, la versión que se puede defender: solo sensores **activos**, con la cantidad de lecturas de cada día a la vista, y el `sensor_id` para que se sepa de quién es el promedio.
Esperado: **30 filas**. El primer día del ranking sigue siendo `2026-04-20` con `27.33` — pero ahora **al lado dice 6**.

En un comentario, dos líneas: el 20 de abril sigue primero. ¿Arreglaste el ranking o arreglaste otra cosa?

**C6 — la pregunta que no es de SQL.** Encontraste el error. Ahora querés reemplazar la vista vieja:

```sql
DROP VIEW v_temp_diaria;
CREATE VIEW v_temp_diaria AS ...  -- la buena
```

Eso corre en dos segundos y no da ningún error. En un comentario, tres líneas:
1. El tablero de la finca consulta `v_temp_diaria` todas las mañanas y espera **dos** columnas. Tu versión buena tiene cuatro. ¿Qué pasa mañana a las 7?
2. Los promedios de abril van a bajar de golpe. Alguien va a preguntar por qué. ¿Qué le decís?
3. ¿Qué habrías hecho distinto: reemplazarla, o publicar `v_temp_diaria_v2` al lado y avisar?

No hay una respuesta correcta. Hay respuestas que se hacen cargo y respuestas que no.

**C7.** Auditá también `v_alertas_sensores`, con el mismo método: leé su definición y verificá qué filtra.
Esperado: **93 filas** — 42 de temperatura, 21 de humedad, 30 de radiación.

Corré esta, que es la misma consulta **sin** el filtro de sensores activos:

```sql
SELECT COUNT(*) FROM lecturas l JOIN sensores s ON s.sensor_id = l.sensor_id
WHERE (s.tipo='temperatura' AND l.valor > 28)
   OR (s.tipo='humedad'     AND l.valor < 60)
   OR (s.tipo='radiacion'   AND l.valor > 800);
```
Esperado: **103**.

En un comentario: esta vista **sí** filtra `activo = 1`. ¿Está bien escrita? Auditar algo y encontrar que está bien también es un resultado — decilo con todas las letras.

---

## Parte D · Lo que una vista no puede, y lo que sí puede esconder (20 min)

**D1.** Intentá escribir en una vista y **pegá el error como comentario**:

```sql
INSERT INTO v_produccion_lote VALUES ('x','y',1,1,1,1);
UPDATE v_produccion_lote SET kg_total = 0;
```

Después, en una línea: `kg_total` es un `SUM` de varias filas de `cosechas`. Si SQLite te dejara escribirle `8000`, ¿qué tendría que hacer con las tablas de abajo?

**D2.** Intentá indexar una vista y pegá el error:

```sql
CREATE INDEX ix_kgha ON v_produccion_lote(kg_ha);
```

En un comentario: entonces, ¿una vista hace que la consulta sea **más rápida**? Sí o no, y qué corre SQLite cada vez que hacés `SELECT * FROM v_produccion_lote`.

**D3 — la vista que no valida nada.** Ejecutá las dos líneas, en este orden:

```sql
CREATE VIEW v_fantasma AS SELECT * FROM tabla_que_no_existe;
SELECT * FROM v_fantasma;
```

La primera **funciona**. La segunda no. En un comentario: ¿en qué momento SQLite revisa que la vista tenga sentido? ¿Qué significa eso para una base con cuarenta vistas encadenadas y una tabla que alguien renombró?

**D4 — el error que se hereda.** Alguien escribió el costo por siembra así, juntando mano de obra e insumos en un solo `JOIN`:

```sql
CREATE VIEW v_costo_mal AS
SELECT si.siembra_id,
       SUM(la.costo_mano_obra)              AS costo_mano_obra,
       SUM(li.cantidad * li.costo_unitario) AS costo_insumos
FROM siembras si
JOIN labores la      ON la.siembra_id = si.siembra_id
LEFT JOIN labor_insumo li ON li.labor_id = la.labor_id
GROUP BY si.siembra_id;
```

Esperado: **8 filas**, y la siembra 1 da `costo_mano_obra = 455`.

El número real es **335**. Y las siembras son **10**, no 8.

1. ¿Por qué 455 y no 335? *(Pista: la siembra 1 tiene una labor con dos insumos. Es el fan-out de la clase 5.)*
2. ¿Qué dos siembras desaparecieron, y qué `JOIN` se las comió?
3. Escribí `v_costo_siembra`, la buena: las **10** siembras, con su finca y su lote, la mano de obra sin inflar, los insumos, y el total.

Esperado: **10 filas**. La siembra 1 da `335 | 295.80 | 630.80`. Y esto tiene que cerrar:

```sql
SELECT ROUND(SUM(costo_total), 2) FROM v_costo_siembra;
```
```
3562.30
```

> Ese `3562.30` es el mismo número del **ejercicio 5**. Si te da otra cosa, la vista está inflando o está perdiendo filas, y ya sabés cuál de las dos según si el número salió más grande o más chico.

---

## Parte E · Cierre (15 min, comentarios en el archivo)

1. Una vista y una CTE las dos le ponen nombre a una consulta. En **una frase**, la diferencia práctica: ¿cuánto vive cada una?
2. `v_temp_diaria` estuvo mal desde el día que se escribió y nadie lo notó en meses. **¿Por qué es más difícil encontrar un error adentro de una vista que adentro de una consulta?** Dos líneas.
3. De todo lo de hoy: si mañana te toca publicar una vista para que la use gente que no va a leer su definición nunca, escribí **tres reglas** que te vas a imponer. Una de ellas tiene que ser sobre el nombre.

---

## Rúbrica (100 puntos)

| Criterio | Pts |
|---|---|
| Parte A: `v_lote_finca` creada, usada, y A3 bien contestada | 10 |
| Parte B1: `v_produccion_lote` con `* 1.0` y las 6 filas exactas | 15 |
| Parte B2: composición — la vista construida **sobre** la otra vista | 10 |
| Parte B3–B4: la vista sigue a los datos + la trampa del `IF NOT EXISTS` | 10 |
| **Parte C1–C5: el tablero auditado — los 35 días, el sensor de baja, la columna ausente y la v2** | **25** |
| **Parte C6: qué pasa cuando reemplazás una vista que otros usan** | **5** |
| Parte C7: `v_alertas_sensores` auditada y declarada correcta | 5 |
| Parte D1–D3: los tres límites, con los errores transcriptos | 10 |
| Parte D4: el fan-out heredado y `v_costo_siembra` cerrando en 3562.30 | 10 |
| Preguntas de cierre con criterio | 5 |
| **Extra:** una vista propia que responda una pregunta de negocio que yo no pedí, con su justificación y el motivo por el que merece ser vista y no consulta suelta | +5 |

El archivo debe correr **completo** de arriba abajo después de `datos/agrodb_clase8.sql`. Poné `DROP VIEW IF EXISTS ...;` antes de cada `CREATE VIEW` tuyo, o la segunda corrida te va a fallar.

**Toda vista que entregues sin filtro explícito o sin su conteo se descuenta, aunque los números estén bien.** Hoy el punto no es que la consulta funcione: es que el que la herede pueda confiar en ella.
