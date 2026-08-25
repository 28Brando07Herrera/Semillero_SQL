---
marp: true
paginate: true
theme: default
title: "Clase 10 · Calidad de datos y auditoría"
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
footer: "Curso de SQL · AgroDB · Clase 10"
---

<!-- _class: lead -->

# El que borra no deja huella

## Calidad de datos, triggers y la bitácora que pidieron tres veces

Clase 10 · 21 de agosto

---

# Ustedes ya escribieron la respuesta de hoy

**Ejercicio 6, parte E:** *"si agregás las restricciones hoy, ¿qué pasa con las filas malas que ya están?"*

**Ejercicio 7, parte C4:** *"¿qué habría que haber guardado para que dentro de seis meses alguien sepa que ahí hubo una medición y que la borramos a propósito?"*

**Ejercicio 8, parte C6:** *"el tablero la consulta todas las mañanas. ¿Qué pasa mañana a las 7?"*

<br>

Las cinco entregas del ejercicio 6 contestaron lo mismo: **una columna de estado, o una bitácora de descartes.**

> Hoy la construimos. Y descubrimos qué parte de lo que prometieron **el motor no puede cumplir**.

---

# Pero primero: la base cambió el fin de semana

Entró una carga masiva desde un CSV. Quien la corrió puso `PRAGMA foreign_keys = OFF` para que "no se quejara", cargó, y lo volvió a prender.

**No hubo ningún error. Nadie se enteró.**

<br>

Lo único que la base tuvo para avisar fue esto:

```
siembras   10 -> 11
labores    19 -> 21
cosechas    9 -> 11
```

> El control de carga que vienen mirando de reojo desde la clase 4.

---

# Dos totales oficiales que no coinciden

```sql
SELECT SUM(kg) FROM cosechas;              -- 33750
SELECT SUM(kg_total) FROM v_produccion_lote; -- 31350
```

<br>

El del ejercicio 5 era **30550**. Ahora hay dos números y **ninguno de los dos es ese**.

La diferencia entre ellos es **2400**, exactos.

> Y los dos están *bien calculados*. Uno cuenta una cosecha que existe en la tabla y **no pertenece a ninguna siembra**: aparece en el `SUM` directo y desaparece en cuanto hay un `JOIN`.

---

# Lo que el motor sí puede encontrar solo

```sql
PRAGMA foreign_key_check;
```
```
cosechas  | 10 | siembras | 0
siembras  | 11 | lotes    | 1
```

Dos huérfanos, con nombre y apellido. Gratis, en una línea.

<br>

> Es la herramienta que hay que correr **el día que heredás una base**. Y también el día después de cualquier carga masiva, porque `foreign_keys = OFF` deja pasar exactamente esto.

---

# Y lo que no

Quedan **tres** filas malas que `foreign_key_check` no ve, porque no violan ninguna clave:

| Fila | Por qué está mal |
|---|---|
| una cosecha del **20 de diciembre de 2025** | su siembra es del **15 de enero de 2026** |
| una labor **idéntica** a otra | misma siembra, mismo tipo, misma fecha |
| una labor fechada en **2027** | el futuro no se trabajó todavía |

<br>

> Ninguna viola una restricción. Las tres violan **el sentido común del negocio**, y de eso el motor no sabe nada.

---

# La cosecha que llegó antes de la siembra

```sql
SELECT c.cosecha_id, c.fecha AS cosecha, si.fecha_siembra
FROM cosechas c JOIN siembras si ON si.siembra_id = c.siembra_id
WHERE c.fecha < si.fecha_siembra;
```
```
11 | 2025-12-20 | 2026-01-15
```

Una fila. Y mirá lo que le hizo al reporte de producción:

| | antes | ahora |
|---|---|---|
| L-02 de El Guayabo | 9800 kg | **10600 kg** |
| su kg/ha | 529.73 | **572.97** |

> El lote más productivo del curso lo es **un poco más** desde el sábado, y nadie tocó una cosecha vieja.

---

# `CHECK` no alcanza

```sql
CHECK (kg > 0)                    -- si: mira su propia fila
CHECK (fecha <= date('now'))      -- no: date('now') no es determinista
CHECK (fecha >= (SELECT ...))     -- no: no puede consultar otra tabla
```

<br>

Un `CHECK` solo puede mirar **la fila que se está escribiendo**, y con funciones deterministas.

| Regla | ¿`CHECK`? |
|---|---|
| el peso es positivo | sí |
| la calidad es uno de tres valores | sí |
| **no cosechar antes de sembrar** | **no** — es otra tabla |
| **no cargar fechas futuras** | **no** — "hoy" cambia todos los días |

> Para esas dos hace falta algo que corra **en el momento del cambio**. Eso es un trigger.

---

<!-- _class: lead -->

# La bitácora

## Lo que pidieron en el ejercicio 7

---

# `CREATE TRIGGER`: la anatomía

```sql
CREATE TRIGGER tr_cosechas_borrado
AFTER DELETE ON cosechas
BEGIN
    INSERT INTO bitacora (tabla, operacion, fila_id, valor_viejo)
    VALUES ('cosechas', 'DELETE', OLD.cosecha_id,
            'siembra ' || OLD.siembra_id || ' | ' || OLD.fecha || ' | ' || OLD.kg || ' kg');
END;
```

| Pieza | Qué elige |
|---|---|
| `BEFORE` / `AFTER` / `INSTEAD OF` | **cuándo** corre |
| `INSERT` / `UPDATE` / `DELETE` | **qué** lo dispara |
| `OLD.` | la fila **como estaba** (en `UPDATE` y `DELETE`) |
| `NEW.` | la fila **como queda** (en `INSERT` y `UPDATE`) |

---

# Esta vez sí queda registrado

Borramos las dos cosechas malas del sábado, **con el trigger puesto**:

```sql
DELETE FROM cosechas WHERE cosecha_id IN (10, 11);
SELECT operacion, fila_id, valor_viejo FROM bitacora;
```
```
DELETE | 10 | siembra 88 | 2026-04-15 | 2400 kg
DELETE | 11 | siembra  5 | 2025-12-20 |  800 kg
```

**Un solo `DELETE`. Dos filas en la bitácora.** El trigger dispara **por fila**, no por sentencia.

> En la clase 6 hicimos exactamente esto con tres lecturas `-99` y no quedó nada. Dos días después, el 20 de abril encabezaba un ranking y nadie sabía por qué. Hoy la explicación queda en una tabla.

---

# Y el número que dice que terminaste

Cuando las cinco filas se van, los dos totales que no coincidían vuelven a ser uno:

```sql
SELECT SUM(kg) FROM cosechas;                 -- 30550
SELECT SUM(kg_total) FROM v_produccion_lote;  -- 30550
```

**30550.** El total del ejercicio 5, exacto.

<br>

| También vuelven | a |
|---|---|
| L-02 de El Guayabo | 9800 kg · 529.73 kg/ha |
| `v_costo_siembra` | 3562.30 |
| `PRAGMA foreign_key_check` | 0 filas |

> Un número viejo que vuelve a dar es la mejor prueba de una limpieza. Por eso se anotan.

---

# Un detalle: hoy no podrían repetir la clase 6

```sql
INSERT INTO lecturas (sensor_id, fecha_hora, valor)
VALUES (1, '2026-05-01 00:00:00', -99);
```
```
Error: CHECK constraint failed: valor BETWEEN -50 AND 1500
```

**Ese `CHECK` lo escribieron ustedes**, en la parte E del ejercicio 6.

<br>

> El problema que nos costó dos clases enteras hoy **no puede volver a entrar**. Es la única de las cuatro fallas de aquel lunes que está resuelta de raíz, y no por una consulta: por una restricción.

---

# La columna que no se puede llenar

El cronograma de este curso dice, textual: *"trigger que registra **quién** cambió qué"*.

```sql
SELECT CURRENT_TIMESTAMP;   -- 2026-08-21 09:33:54
SELECT CURRENT_USER;        -- Error: no such column: CURRENT_USER
SELECT USER();              -- Error: no such function: USER
```

<br>

**SQLite no sabe quién sos.** No tiene usuarios: es un archivo. El "cuándo" sale gratis; el "quién" **no existe en el motor**.

> Tiene que ponerlo la aplicación que hace el cambio. Y si la aplicación no lo pone, la bitácora dice que alguien borró algo, y nada más.

---

# Y la otra: `motivo`

Un trigger ve `OLD` y `NEW`. Eso es todo lo que ve.

<br>

| La bitácora puede decir | No puede decir |
|---|---|
| qué tabla | **quién** |
| qué operación | **por qué** |
| el valor viejo y el nuevo | si fue a propósito |
| cuándo | si alguien lo autorizó |

<br>

> **Un trigger registra QUÉ pasó. Nunca POR QUÉ.** Y el ejercicio 7 preguntaba justamente cómo saber que *"la borramos a propósito"*. Eso no lo da el motor: lo da un `UPDATE` que marca la fila en vez de borrarla, o una carga que escribe el motivo a mano.

---

# `BEFORE` + `RAISE`: impedir en vez de registrar

```sql
CREATE TRIGGER tr_cosecha_no_futura
BEFORE INSERT ON cosechas
BEGIN
    SELECT CASE WHEN NEW.fecha > date('now')
        THEN RAISE(ABORT, 'no se puede registrar una cosecha con fecha futura')
    END;
END;
```
```
Error: no se puede registrar una cosecha con fecha futura
```

Es el `CHECK` que no se podía escribir, porque ahora sí puede mirar el reloj y otras tablas.

> `AFTER` **anota**. `BEFORE` con `RAISE(ABORT)` **impide**. Anotar sirve para investigar; impedir sirve para que no haya nada que investigar.

---

# `INSTEAD OF`: la vista de la clase 8, escribible

Anteayer chocamos con esto:

```sql
UPDATE v_lote_finca SET hectareas = 99 WHERE lote_id = 1;
-- Error: cannot modify v_lote_finca because it is a view
```

```sql
CREATE TRIGGER tr_v_lote_finca_update
INSTEAD OF UPDATE ON v_lote_finca
BEGIN
    UPDATE lotes SET hectareas = NEW.hectareas WHERE lote_id = OLD.lote_id;
END;
```

Ahora el `UPDATE` sobre la vista funciona: **vos definís qué significa escribir en ella.**

> Es la única forma de que una vista acepte escrituras. Y la responsabilidad de que la traducción tenga sentido es enteramente tuya.

---

# Lo que la bitácora no ve

| Agujero | Por qué |
|---|---|
| **todo lo anterior al trigger** | las 5 filas del sábado no están y no van a estar |
| **`DROP TRIGGER`** | se borra sin error y sin dejar rastro |
| **la bitácora misma** | nadie la audita: se puede editar y borrar |
| lo que pasa con la base cerrada | copiar el archivo `.db` no dispara nada |

<br>

> Una bitácora no es una garantía: es una **facilidad**. Sirve contra el error y el olvido, no contra alguien que quiera borrar el rastro. Para eso hacen falta permisos, que un archivo suelto no tiene.

---

# Lo que cuesta

Ayer vimos que un índice hace más lenta cada escritura. Un trigger es lo mismo, pero peor:

<br>

| | Un índice | Un trigger |
|---|---|---|
| en cada `INSERT` | actualiza una estructura | **corre SQL que escribiste vos** |
| se puede desactivar | no hace falta | solo borrándolo |
| se ve en el plan | sí | **no** |

<br>

> Un trigger es código invisible que corre en cada cambio. Es la herramienta más útil de hoy y la que más sorprende a quien hereda la base seis meses después.

---

# Lo de hoy en una línea

**Los datos malos no dan error, y el motor solo te defiende de los que violan una regla que le escribiste.**

| Quiero | Uso |
|---|---|
| huérfanos | `PRAGMA foreign_key_check` |
| duplicados lógicos | `GROUP BY ... HAVING COUNT(*) > 1` |
| fechas imposibles | un `JOIN` contra la tabla padre |
| impedir que entre | `BEFORE` + `RAISE(ABORT, ...)` |
| registrar lo que pasó | `AFTER` + tabla `bitacora` |
| escribir en una vista | `INSTEAD OF` |
| saber **quién** | la aplicación. El motor no sabe |

---

<!-- _class: lead -->

# A trabajar

## `ejercicio.md`

Cinco filas que nadie vio, dos totales que no coinciden, y la bitácora que pidieron en el ejercicio 7.

Antes de empezar: `datos/agrodb_clase10.sql`
Tiene que dar **3, 6, 8, 11, 7, 21, 16, 6, 11, 973, 7, 105120, 2**
