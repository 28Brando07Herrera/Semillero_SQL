---
marp: true
paginate: true
theme: default
title: "Clase 8 · Vistas: la consulta que se queda"
style: |
  section { font-family: system-ui, -apple-system, "Segoe UI", sans-serif; font-size: 26px; background: #fbfbfa; color: #1f2933; padding: 60px 70px; }
  section.lead { background: #16324f; color: #f4f7fa; }
  section.lead h1 { color: #ffffff; font-size: 58px; line-height: 1.1; }
  section.lead h2 { color: #7fb3d5; font-weight: 400; font-size: 30px; }
  h1 { color: #16324f; font-size: 42px; border-bottom: 3px solid #f2a104; padding-bottom: 10px; }
  h2 { color: #1c7293; font-size: 32px; }
  strong { color: #b3541e; }
  code { background: #eef2f6; padding: 1px 6px; border-radius: 4px; }
  pre { background: #16324f; border-radius: 8px; font-size: 21px; }
  pre code { background: transparent; color: #e8eef4; }
  table { font-size: 23px; }
  th { background: #16324f; color: #fff; }
  blockquote { border-left: 5px solid #f2a104; color: #4a5568; font-style: normal; }
  footer { color: #8a99a8; font-size: 16px; }
footer: "Curso de SQL · AgroDB · Clase 8"
---

<!-- _class: lead -->

# La consulta que se queda

## Vistas: la capa de reporte, y la que nadie auditó

Clase 8 · 19 de agosto

---

# La base no se acuerda de ayer

Ayer escribieron veinte consultas. Auditaron un podio, encontraron un hueco que habíamos hecho nosotros, calcularon una media móvil.

Carguen la base de hoy y miren el control:

```
3, 6, 8, 10, 7, 19, 16, 6, 9, 973
```

**Los mismos diez números de ayer.** Ni una tabla nueva, ni una fila nueva.

> Un `SELECT` no deja rastro: se ejecuta, muestra el resultado y se olvida. De las veinte consultas de ayer, lo único que existe es el `.sql` que ustedes guardaron a mano.

---

# El JOIN que todos copiaron

Esta es la consulta de producción por lote. La escribimos en la clase 5, la volvimos a escribir en la 7:

```sql
FROM cosechas c
JOIN siembras si ON si.siembra_id = c.siembra_id
JOIN lotes lo    ON lo.lote_id    = si.lote_id
JOIN fincas f    ON f.finca_id    = lo.finca_id
```

Cuatro tablas para contestar *"¿cuántos kilos dio cada lote?"*.

<br>

Ahora imaginen esas cuatro líneas **copiadas en seis archivos distintos**. Seis personas, seis copias. Cinco se olvidaron el `* 1.0`.

> No hay forma de arreglar las cinco. Ni siquiera hay forma de encontrarlas.

---

# `CREATE VIEW`: la consulta con nombre

```sql
CREATE VIEW v_produccion_lote AS
SELECT ...;
```

<br>

Y desde ese momento:

```sql
SELECT * FROM v_produccion_lote;
```

<br>

| Una vista **no** es | Una vista **es** |
|---|---|
| una tabla | un `SELECT` guardado con nombre |
| una copia de los datos | **la pregunta**, no la respuesta |
| algo que ocupa espacio | texto en `sqlite_master` |

---

# La misma pregunta, escrita una sola vez

```sql
CREATE VIEW v_produccion_lote AS
SELECT f.nombre AS finca, lo.codigo AS lote, lo.hectareas,
       COUNT(c.cosecha_id) AS n_cosechas, SUM(c.kg) AS kg_total,
       ROUND(SUM(c.kg) * 1.0 / lo.hectareas, 2) AS kg_ha
FROM cosechas c
JOIN siembras si ON si.siembra_id = c.siembra_id
JOIN lotes lo    ON lo.lote_id    = si.lote_id
JOIN fincas f    ON f.finca_id    = lo.finca_id
GROUP BY f.nombre, lo.codigo, lo.hectareas;
```
```
Hacienda Santa Rosa  L-01  28.5  2  7300  256.14
Finca El Guayabo     L-02  18.5  1  9800  529.73
```

El `* 1.0` se escribe **una vez** y queda bien para todo el que la use.

---

# No guarda datos: guarda la pregunta

```sql
SELECT kg_total, n_cosechas, kg_ha FROM v_produccion_lote
WHERE lote = 'L-01' AND finca LIKE 'Hacienda%';
```
```
7300   2   256.14
```

Entra una cosecha nueva de 500 kg. **Nadie toca la vista.**

```sql
INSERT INTO cosechas (siembra_id, fecha, kg, calidad, destino)
VALUES (1, '2026-05-02', 500, 'primera', 'mercado local');
```
```
7800   3   273.68
```

> La vista no se actualizó: **se volvió a ejecutar**. Cada consulta corre el `SELECT` de adentro contra las tablas como están en ese instante.

---

# Vistas sobre vistas

Una vista se consulta como una tabla. Entonces también se puede consultar **desde otra vista**:

```sql
CREATE VIEW v_produccion_finca AS
SELECT finca, COUNT(*) AS lotes, SUM(kg_total) AS kg,
       ROUND(SUM(kg_total) * 1.0 / SUM(hectareas), 2) AS kg_ha
FROM v_produccion_lote
GROUP BY finca;
```
```
Agricola La Union     1   2100    38.18
Finca El Guayabo      2  14250   351.85
Hacienda Santa Rosa   3  14200   180.32
```

**Cuatro tablas, dos vistas, cero JOIN escritos hoy.** Eso es una capa de reporte.

---

<!-- _class: lead -->

# Y ahora, el tablero

## Que ya estaba publicado cuando ustedes llegaron

---

# Dos vistas que vinieron con la base

`agrodb_clase8.sql` trae dos vistas que **no escribieron ustedes**:

| Vista | Qué promete |
|---|---|
| `v_temp_diaria` | el promedio de temperatura de cada día |
| `v_alertas_sensores` | las lecturas que pasaron el umbral |

<br>

Las dos corren sin error. Las dos devuelven algo que parece razonable. Las dos están escritas con el mismo estilo.

**Una de las dos está mal.**

> Por afuera no se distingue cuál. Hay que abrirlas.

---

# 35 días

```sql
SELECT COUNT(*) FROM v_temp_diaria;
```
```
35
```

<br>

Nuestras lecturas de temperatura son **de abril**.

Abril tiene **30** días.

---

# Abrir la vista

La definición está guardada como texto, y se lee:

```sql
SELECT sql FROM sqlite_master WHERE type = 'view';
```
```sql
CREATE VIEW v_temp_diaria AS
SELECT DATE(l.fecha_hora) AS dia, ROUND(AVG(l.valor),2) AS temp_promedio
FROM lecturas l JOIN sensores s ON s.sensor_id = l.sensor_id
WHERE s.tipo = 'temperatura'
GROUP BY DATE(l.fecha_hora);
```

`WHERE s.tipo = 'temperatura'`. Y nada más.

> **El sensor 3 también es de temperatura.** Está dado de baja desde febrero —`activo = 0`— pero sus 40 lecturas de febrero siguen en la tabla. Son los cinco días de más.

---

# El podio del tablero oficial

```sql
SELECT dia, temp_promedio,
       RANK() OVER (ORDER BY temp_promedio DESC) AS puesto
FROM v_temp_diaria ORDER BY puesto, dia;
```
```
2026-04-20   27.33    1
2026-02-04   25.63    2      <- sensor dado de baja
2026-02-05   25.63    2      <- sensor dado de baja
...
2026-04-05   25.63    2
2026-04-19   24.86   12
```

Diez días empatados en el segundo puesto. **La mitad son de un sensor que ya no existe, en un mes que nadie pidió.**

Y arriba de todo, otra vez, el 20 de abril.

---

# La columna que la vista decidió no mostrar

`v_temp_diaria` devuelve **dos** columnas: `dia` y `temp_promedio`.

No devuelve `COUNT(*)`.

<br>

| Ayer | Hoy |
|---|---|
| el `n = 6` estaba en su consulta | la vista **no lo expone** |
| lo vieron y desconfiaron | no hay nada de qué desconfiar |
| el error duró una consulta | el error dura **todas las mañanas** |

> Ayer el 20 de abril fue un hallazgo de ustedes. Hoy es un renglón de un tablero que diez personas miran y ninguna puede auditar.

---

# La regla del día

# **Una vista es una opinión con nombre.**

<br>

El que la consulta hereda **todas** sus decisiones: qué filtró, qué agrupó, qué redondeó.

Incluidas las que quien la escribió no sabía que estaba tomando.

<br>

> Lo que una vista no muestra **deja de existir** para el que la consulta. No es que esté escondido: es que no hay forma de saber que falta.

---

# Arreglarla es más difícil de lo que parece

```sql
CREATE OR REPLACE VIEW v_temp_diaria AS ...
```
```
Error: near "OR": syntax error
```

**SQLite no tiene `CREATE OR REPLACE VIEW`.** Se hace en dos pasos:

```sql
DROP VIEW IF EXISTS v_temp_diaria;
CREATE VIEW v_temp_diaria AS ...;
```

> Y cuidado con la que **sí** existe: `CREATE VIEW IF NOT EXISTS` no da error, no reemplaza nada y **deja la vista vieja**. Corrigen la definición, la ejecutan, no ven error, y siguen consultando la de antes.

---

# Lo que una vista no puede: escribirse

```sql
INSERT INTO v_produccion_lote VALUES (...);
UPDATE v_produccion_lote SET kg_total = 0;
```
```
Error: cannot modify v_produccion_lote because it is a view
```

Tiene sentido: `kg_total` es un `SUM` de nueve filas de `cosechas`. Escribirle 8000 no significa nada.

<br>

| Se lee | Se escribe |
|---|---|
| la vista | **la tabla de abajo** |

Una vista es de **lectura**. La capa de reporte no es la capa de carga.

---

# Lo que una vista no puede: indexarse

```sql
CREATE INDEX ix ON v_produccion_lote(kg_ha);
```
```
Error: views may not be indexed
```

Una vista no tiene datos propios, así que no hay nada que indexar.

<br>

**Y por eso una vista no acelera nada.** Cada consulta vuelve a correr los cuatro `JOIN`. Sobre 973 lecturas no se nota; sobre medio millón, sí.

> Los índices van en las **tablas**. Eso es mañana, y es la otra mitad de esta clase.

---

# Lo que una vista sí puede: heredar tu error

Costo por siembra, juntando mano de obra e insumos en un solo `JOIN`:

```
siembra 1     455.00
```

El número real es **335.00**. La siembra 1 tiene una labor con dos insumos, y `costo_mano_obra` se sumó dos veces. Es el **fan-out** de la clase 5.

<br>

| Escrito en una consulta | Escrito en una vista |
|---|---|
| se equivocó una persona, una vez | se equivocan **todos**, siempre |
| lo ves si mirás la consulta | nadie mira la consulta: mira el nombre |

> Y el nombre dice `v_costo_siembra`, que suena a que está bien.

---

# Cuándo sí y cuándo no

| Hacé una vista cuando… | No hagas una vista cuando… |
|---|---|
| la consulta la usan varias personas | la vas a correr una sola vez |
| esconde un JOIN de 4 o 5 tablas | querés que sea más rápida |
| define **un** número oficial (kg/ha) | necesitás escribir en ella |
| querés arreglar en un lugar | no sabés qué filtró la de abajo |

<br>

> Una vista buena tiene el filtro explícito, expone el conteo, y su nombre dice **exactamente** qué contiene: `v_temp_diaria_sensores_activos` es feo y no miente.

---

# Lo de hoy en una línea

**Una vista guarda la pregunta, no la respuesta — y con ella, todas las decisiones de quien la escribió.**

| Quiero | Escribo |
|---|---|
| guardar una consulta con nombre | `CREATE VIEW v_x AS SELECT ...` |
| usarla | `SELECT * FROM v_x` |
| ver cómo está hecha | `SELECT sql FROM sqlite_master WHERE type='view'` |
| cambiarla | `DROP VIEW IF EXISTS v_x;` + `CREATE VIEW ...` |
| armar un tablero | una vista **sobre** otra vista |
| escribir datos | en la **tabla**, nunca en la vista |

---

<!-- _class: lead -->

# A trabajar

## `ejercicio.md`

Dos vistas heredadas, una de ellas mentirosa, y un tablero para construir.

Antes de empezar: `datos/agrodb_clase8.sql`
Tiene que dar **3, 6, 8, 10, 7, 19, 16, 6, 9, 973, 2**
