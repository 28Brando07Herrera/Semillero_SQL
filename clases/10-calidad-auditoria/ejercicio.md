# Ejercicio práctico 10 · Cinco filas que nadie vio
**Duración: 2 horas · Individual · sqliteonline.com (o tu SQLite local) · Entrega: un archivo `.sql`**

---

## La situación

El fin de semana entró una carga masiva desde un CSV. Quien la corrió puso `PRAGMA foreign_keys = OFF` para que "no se quejara", cargó, y lo volvió a prender.

No hubo error. No hubo aviso. **Cinco filas están en la base ahora mismo**, y ya movieron todos los números que ustedes se saben de memoria.

Hoy hacen dos cosas: encontrarlas —el script base **no dice cuáles son**— y construir lo que vienen pidiendo desde el ejercicio 6, para que la próxima vez quede registrado.

## Antes de empezar

1. **Pestaña nueva** en sqliteonline.com → SQLite.
2. Pegá `datos/agrodb_clase10.sql` completo y ejecutalo. Deben salir **3, 6, 8, 11, 7, 21, 16, 6, 11, 973, 7, 105120, 2**.
3. Trabajá en `Ejercicio10_Apellido_Nombre.sql`.

> **No leas el bloque "LA CARGA DEL FIN DE SEMANA" del script base hasta terminar la parte A.** Está marcado. Si lo leés primero, la parte A deja de ser un ejercicio y pasa a ser una transcripción.

## La regla del día

> **Los datos malos no dan error.**
>
> El motor te avisa cuando rompés una regla que vos le escribiste. De todo lo demás —una cosecha anterior a su siembra, una labor cargada dos veces, una fecha en 2027— no sabe nada, y te lo va a sumar en el reporte sin pestañear.

---

## Parte A · Encontrar las cinco (30 min)

**A1 — el control.** Compará el control de hoy con el de ayer:

```
ayer:  3, 6, 8, 10, 7, 19, 16, 6,  9, 973, 7, 105120
hoy:   3, 6, 8, 11, 7, 21, 16, 6, 11, 973, 7, 105120, 2
```

En un comentario: **qué tres tablas crecieron y cuántas filas entraron en total.** *(El último número no cuenta: son los índices que crearon ayer.)*

**A2 — los dos totales.** Corré estas dos:

```sql
SELECT SUM(kg) FROM cosechas;
SELECT SUM(kg_total) FROM v_produccion_lote;
```

Esperado: **33750** y **31350**. En el ejercicio 5 los dos daban **30550**.

En un comentario, tres líneas:
1. Los dos están bien calculados. ¿Por qué dan distinto?
2. La diferencia es **2400**. ¿Qué fila vale exactamente eso, y por qué aparece en uno y no en el otro?
3. Si un reporte usa el primero y otro usa el segundo, ¿cuál de los dos está mal?

**A3 — los huérfanos, gratis.**

```sql
PRAGMA foreign_key_check;
```

Esperado: **2 filas**. Anotá cuáles son y contra qué tabla apuntan.

En un comentario: ¿cómo entraron, si la tabla tiene la clave foránea declarada?

**A4 — lo que `foreign_key_check` no ve.** Faltan **tres**. Escribí una consulta para cada una:

1. **Una cosecha fechada antes de la siembra a la que pertenece.**
   *Pista:* `JOIN` contra `siembras` y comparar `c.fecha < si.fecha_siembra`.
   Esperado: **1 fila** — cosecha `11`, del `2025-12-20`, cuya siembra es del `2026-01-15`.
2. **Labores duplicadas**: misma siembra, mismo tipo, misma fecha.
   *Pista:* `GROUP BY ... HAVING COUNT(*) > 1`.
   Esperado: **1 fila** — siembra `6`, `fertilizacion`, `2026-03-17`, labores `10` y `22`.
3. **Fechas en el futuro** en `labores`.
   Esperado: **1 fila** — labor `23`, del `2027-02-10`.

**A5.** Mostrá qué le hizo la cosecha imposible al reporte de producción:

```sql
SELECT * FROM v_produccion_lote WHERE lote = 'L-02' AND finca LIKE 'Finca%';
```
Esperado: **10600 kg** y **572.97 kg/ha**. En la clase 8 daban **9800** y **529.73**.

En un comentario, una línea: nadie tocó una cosecha vieja. ¿Por qué cambió el kg/ha del lote más productivo del curso?

**A6 — los NULL sospechosos.** Contá cuántos hay en cuatro columnas que aceptan nulos: `fincas.responsable`, `lotes.tipo_suelo`, `cosechas.destino` y `labores.responsable`.
Esperado: **1, 2, 1, 1**.

En un comentario: **ninguno de estos cuatro es de la carga del sábado, y ninguno está "mal".** ¿Cuál es la diferencia entre un `NULL` que es un dato faltante y uno que es una respuesta legítima? Dale un ejemplo de cada uno, de esta lista.

---

## Parte B · Lo que `CHECK` no puede (20 min)

**B1.** Agregarías estas cuatro reglas a `cosechas` y `labores`. Decidí, en un comentario, cuáles se pueden escribir como `CHECK` y cuáles no, **y por qué**:

| Regla |
|---|
| a) los kilos son positivos |
| b) la calidad es `primera`, `segunda` o `descarte` |
| c) una cosecha no puede ser anterior a su siembra |
| d) una labor no puede tener fecha futura |

**B2.** Probá que tenés razón con la (d). Intentá esto:

```sql
CREATE TABLE prueba_check (
    fecha DATE NOT NULL CHECK (fecha <= date('now'))
);
```

Anotá qué pasó como comentario. *(Pista: SQLite acepta el `CREATE TABLE` sin chistar. El problema aparece cuando insertás. Probá insertar una fila y contá qué pasó.)*

**B3.** En un comentario, dos líneas: si `CHECK` solo puede mirar la fila que se está escribiendo, **¿qué herramienta necesitás para las reglas (c) y (d)?**

---

## Parte C · La bitácora (35 min)

Esta es la parte del día, y es la que vienen pidiendo desde el ejercicio 6.

**C1.** Creá la tabla:

```sql
CREATE TABLE bitacora (
    evento_id   INTEGER PRIMARY KEY,
    tabla       TEXT NOT NULL,
    operacion   TEXT NOT NULL,
    fila_id     INTEGER,
    valor_viejo TEXT,
    valor_nuevo TEXT,
    cuando      TEXT NOT NULL DEFAULT (datetime('now'))
);
```

**C2.** Creá un trigger `AFTER DELETE ON cosechas` que escriba en `bitacora` la fila que se fue: su `cosecha_id`, y un texto con la siembra, la fecha y los kilos.

**C3 — la limpieza, esta vez registrada.** Borrá las **dos cosechas malas** en un solo `DELETE`:

```sql
DELETE FROM cosechas WHERE cosecha_id IN (10, 11);
SELECT operacion, fila_id, valor_viejo FROM bitacora;
```

Esperado: **2 filas** en `bitacora`.

En un comentario: ejecutaste **una** sentencia. ¿Por qué hay dos filas? ¿Qué habría pasado si el `DELETE` se llevaba cincuenta?

**C4 — terminar la limpieza.** Borrá también las dos labores malas (`22` y `23`) y la siembra huérfana (`11`).

Después verificá que quedó limpio. Esperado, **los cuatro**:

```sql
SELECT SUM(kg) FROM cosechas;                 -- 30550
SELECT SUM(kg_total) FROM v_produccion_lote;  -- 30550
SELECT ROUND(SUM(costo_total),2) FROM v_costo_siembra;  -- 3562.30
PRAGMA foreign_key_check;                     -- 0 filas
```

En un comentario: **el 30550 y el 3562.30 son los números del ejercicio 5.** ¿Por qué sirven de prueba de que la limpieza terminó, y qué habría pasado si no los tuvieras anotados?

**C5 — un trigger de `UPDATE`.** Creá uno que registre los cambios de `lotes.hectareas`, guardando el valor viejo **y** el nuevo. Probalo:

```sql
UPDATE lotes SET hectareas = 40 WHERE lote_id = 2;
UPDATE lotes SET hectareas = 31 WHERE lote_id = 2;   -- dejalo como estaba
```

Esperado: **2 filas** nuevas en `bitacora`, la segunda deshaciendo la primera.

**C6 — `UPDATE OF`.** Cambiá tu trigger a `AFTER UPDATE OF hectareas ON lotes` y corré:

```sql
UPDATE lotes SET tipo_suelo = 'franco' WHERE lote_id = 2;
```

Esperado: **0 filas nuevas**. En un comentario: ¿para qué sirve esa precisión, en una tabla que se actualiza mucho?

**C7 — la columna que falta.** Mirá tu tabla `bitacora`. Registra qué, dónde y cuándo.

Probá esto:

```sql
SELECT CURRENT_TIMESTAMP;
SELECT CURRENT_USER;
```

La primera funciona. **Pegá el error de la segunda como comentario.**

Después contestá, en tres líneas:
1. El cronograma de este curso promete *"un trigger que registra **quién** cambió qué"*. ¿Puede SQLite cumplir esa promesa? ¿Por qué no?
2. La parte C4 del ejercicio 7 pedía saber que una lectura *"la borramos a propósito"*. ¿Tu bitácora puede decir eso?
3. Entonces: **¿de dónde tienen que salir el `quien` y el `motivo`?** Nombrá dos formas distintas de conseguirlos.

---

## Parte D · Impedir, y escribir en una vista (20 min)

**D1 — `BEFORE` + `RAISE`.** Escribí el trigger que resuelve la regla (d) de la parte B: que no se pueda insertar una labor con fecha futura.

*Pista:*

```sql
CREATE TRIGGER tr_labor_no_futura
BEFORE INSERT ON labores
BEGIN
    SELECT CASE WHEN NEW.fecha > date('now')
        THEN RAISE(ABORT, 'tu mensaje acá')
    END;
END;
```

Probalo con una labor de 2030 y **pegá el error**. Después, en un comentario: ¿cuál es la diferencia práctica entre este trigger y el de la parte C?

**D2 — la regla que necesita otra tabla.** Escribí el trigger que impide insertar una cosecha anterior a la fecha de siembra de su siembra. *(Es la regla (c), la que `CHECK` no podía.)*

Probalo intentando volver a insertar la cosecha `11` que borraste, y pegá el error.

**D3 — `INSTEAD OF`.** En la clase 8 chocamos con esto:

```sql
UPDATE v_lote_finca SET hectareas = 99 WHERE lote_id = 1;
```
```
Error: cannot modify v_lote_finca because it is a view
```

Escribí un trigger `INSTEAD OF UPDATE ON v_lote_finca` que traduzca ese `UPDATE` a un `UPDATE` sobre `lotes`. Después corré el mismo `UPDATE` de arriba y comprobá que ahora sí funciona.

Esperado: `lotes.hectareas` del lote 1 pasa a **99**. **Dejalo en 28.5 antes de seguir.**

En un comentario, dos líneas: la vista no cambió, sigue siendo la misma. ¿Qué cambió entonces? ¿Y quién decide qué significa "escribir" en una vista que junta dos tablas?

---

## Parte E · Cierre (15 min, comentarios en el archivo)

1. Enumerá **tres cosas que tu bitácora no ve**, y para cada una decí si te preocupa o no.
2. Ayer aprendiste que un índice hace más lenta cada escritura. Un trigger también. En una frase: **¿cuál de los dos es más difícil de descubrir** para alguien que hereda la base, y por qué? *(Pensá en `EXPLAIN QUERY PLAN`.)*
3. De todo el curso: la clase 6 borró tres lecturas con la mejor intención y la clase 7 pagó el precio. Con lo de hoy, **escribí en tres líneas el procedimiento que seguirías la próxima vez que tengas que borrar datos de producción.** No vale "hacer un backup".

---

## Rúbrica (100 puntos)

| Criterio | Pts |
|---|---|
| Parte A1–A3: el control leído, los dos totales explicados y los huérfanos | 15 |
| **Parte A4: las tres filas que `foreign_key_check` no ve, cada una con su consulta** | **20** |
| Parte A5–A6: el kg/ha contaminado y los `NULL` legítimos contra los faltantes | 10 |
| Parte B: qué puede y qué no puede un `CHECK`, con la prueba de B2 | 10 |
| Parte C1–C4: la bitácora, el trigger de borrado y la limpieza que cierra en 30550 | 20 |
| Parte C5–C6: el trigger de `UPDATE` y el `UPDATE OF` | 5 |
| **Parte C7: el `quien` que el motor no puede dar** | **10** |
| Parte D: `RAISE(ABORT)`, la regla entre tablas y el `INSTEAD OF` | 5 |
| Cierre con criterio | 5 |
| **Extra:** un chequeo de calidad propio sobre AgroDB que yo no pedí, con la consulta y qué haría el negocio si diera filas | +5 |

*(La suma da 100. Verificado.)*

El archivo debe correr **completo** de arriba abajo después de `datos/agrodb_clase10.sql`. Poné `DROP TRIGGER IF EXISTS ...;` antes de cada `CREATE TRIGGER` tuyo, y `DROP TABLE IF EXISTS bitacora;` antes de crearla.

**Toda afirmación sobre un dato malo tiene que venir con la consulta que lo encuentra.** Hoy no alcanza con decir que algo está mal: hay que poder demostrarlo con una fila en pantalla.
