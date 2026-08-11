# Ejercicio práctico 3 · Arreglar el registro de campo
**Duración: 2 horas · Individual · sqliteonline.com · Entrega: un archivo `.sql`**

---

## La situación

El jefe de campo de tres fincas lleva el registro de labores en una sola hoja de Excel. Alguien la importó tal cual a la base de datos y quedó como la tabla `registro_campo_plano`. Funciona para mirarla. No funciona para nada más.

Tu trabajo es convertir esa hoja en un modelo relacional que sí aguante, **sin perder ni un dato**.

## Antes de empezar

1. Entrá a **sqliteonline.com** y elegí SQLite.
2. Pegá `agrodb_nucleo.sql` **completo** y ejecutalo. Deben salir 3, 6, 8, 10 y 12.
3. **No abras otra pestaña.** Todo el ejercicio va en la misma sesión o perdés la base.
4. Trabajá en un archivo aparte llamado `Ejercicio3_Apellido_Nombre.sql`.

> **Regla de los 20 minutos:** si llevás ese tiempo trabado en el mismo error, escribí la duda dentro del archivo como comentario empezando con `DUDA` y seguí con lo siguiente. No baja la nota.

---

## Parte A · Diagnóstico (25 min, se escribe, no se programa)

Mirá `registro_campo_plano` y respondé dentro de tu archivo, como comentarios:

```sql
SELECT * FROM registro_campo_plano;
```

1. Llega una labor que usó **tres** insumos. ¿Qué tenés que hacer para registrarla? ¿Por qué eso es un problema grave y no una molestia?
2. Corré esto y explicá el resultado:
   ```sql
   SELECT finca, COUNT(*) FROM registro_campo_plano GROUP BY finca;
   ```
   ¿Cuántas fincas hay de verdad? ¿Por qué la consulta dice otra cosa? ¿Qué error te dio SQLite? (Ojo con la respuesta a esta última.)
3. La columna `provincia`, ¿de qué depende? ¿De la fila, o de otra columna? ¿Qué pasa si Los Ríos cambia de nombre?
4. Compará el `costo_total` de las filas 1 y 4. ¿Significan lo mismo? Justificá.
5. Dibujá (en papel o en comentarios) el modelo que vas a construir: qué tablas, qué claves foráneas, y de qué lado va cada una.

---

## Parte B · Construcción (45 min)

Creá **cuatro tablas nuevas**. El núcleo (`fincas`, `lotes`, `cultivos`, `siembras`) ya existe: no lo toques.

### `insumos` — el catálogo
Qué se puede aplicar. Un insumo existe en bodega aunque nunca se haya usado.
Necesita: identificador, nombre, tipo (fertilizante / fungicida / semilla…), unidad de medida y un precio de referencia que **puede ser NULL**.

### `labores` — el evento
Qué se hizo, sobre qué siembra y cuándo.
Necesita: identificador, **clave foránea a `siembras`**, tipo de labor, fecha, responsable, costo de mano de obra (con `DEFAULT 0`) y una observación opcional.

### `labor_insumo` — la tabla puente ⭐
Qué insumos llevó cada labor y cuántos.
- Clave foránea a `labores` **y** clave foránea a `insumos`.
- **Clave primaria compuesta** por esas dos columnas.
- Columnas propias: `cantidad` y `costo_unitario`.

> Antes de escribirla, respondé para vos: ¿por qué `cantidad` no puede vivir en `labores` ni en `insumos`?
> Y: ¿por qué `costo_unitario` va acá y no solamente en el catálogo? Mirá el precio de la urea en las filas 1 y 9 de la tabla plana.

### `sensores`
Un lote puede tener varios sensores; un sensor está en un solo lote.
Necesita: identificador, clave foránea a `lotes`, tipo (temperatura / humedad / radiación), modelo (opcional), fecha de instalación y si está activo.

**Requisitos obligatorios en las cuatro tablas:**
- `PRIMARY KEY` en todas.
- Al menos un `CHECK` que impida un valor imposible (cantidad negativa, por ejemplo).
- Al menos un `UNIQUE`.
- Al menos un `DEFAULT`.
- Al menos dos columnas que admitan `NULL` a propósito.

**Punto de control 1** — pegá esto tal cual y comprobá que salen **6 filas**:
```sql
SELECT m.name AS tabla, f."from" AS columna, f."table" AS apunta_a
FROM sqlite_master m
JOIN pragma_foreign_key_list(m.name) f
WHERE m.type = 'table'
  AND m.name IN ('insumos','labores','labor_insumo','sensores')
ORDER BY m.name;
```
Se lee: *"la tabla X apunta a la tabla Y por la columna Z"*. Si alguna está al revés de lo que pensaste, **arreglala ahora**, antes de cargar datos.

---

## Parte C · Migración (30 min)

Pasá las 12 filas de `registro_campo_plano` a tus tablas nuevas, con `INSERT`. Cargá siempre primero la tabla apuntada.

**Ayuda con el mapeo a siembras** (cruzá lote + cultivo):

| Filas del plano | siembra_id |
|---|---|
| 1, 2 | 1 |
| 3, 4 | 2 |
| 5 | 3 |
| 6, 7 | 4 |
| 8, 9 | 5 |
| 10 | 6 |
| 11 | 7 |
| 12 | 8 |

**Tres cosas obligatorias:**
1. Corregí el nombre mal escrito de la fila 4. No debe quedar rastro de la variante con error.
2. El `costo_total` del plano se reparte: si la fila tiene insumos, ese total sale de los insumos y la mano de obra es 0. Si no tiene insumos, todo ese valor es mano de obra.
3. Cargá **un insumo de catálogo que ninguna labor use**. Lo vas a necesitar en la Parte D.

**Punto de control 2:**
```sql
PRAGMA foreign_key_check;   -- no debe devolver ninguna fila
```

---

## Parte D · Verificación y preguntas de negocio (20 min)

Escribí estas consultas. Antes de cada una, escribí en un comentario la **pregunta en palabras**.

**D1.** Conteo de filas de tus cuatro tablas nuevas, en una sola consulta (`UNION ALL`).

**D2 — la prueba de fuego.** Reconstruí el costo de cada labor desde tus tablas y compará contra el `costo_total` original. Deben salir **12 filas y las 12 en «OK»**. Si una dice «REVISAR», ahí está tu error:
```sql
WITH costo AS (
  SELECT l.labor_id,
         ROUND(l.costo_mano_obra + COALESCE(SUM(li.cantidad * li.costo_unitario), 0), 2) AS calculado
  FROM labores l
  LEFT JOIN labor_insumo li ON li.labor_id = l.labor_id
  GROUP BY l.labor_id, l.costo_mano_obra
)
SELECT p.id, p.costo_total AS original, c.calculado,
       CASE WHEN p.costo_total = c.calculado THEN 'OK' ELSE 'REVISAR' END AS estado
FROM registro_campo_plano p
JOIN costo c ON c.labor_id = p.id
ORDER BY p.id;
```

**D3.** El insumo del catálogo que nunca se usó. (`LEFT JOIN` + `IS NULL`.)

**D4.** Gasto total en insumos por finca, de mayor a menor. Cruza cinco tablas.

**D5.** Los lotes que **no** tienen ningún sensor instalado.

**D6.** Una pregunta tuya, inventada, que tu modelo pueda responder y que la tabla plana **no** podía. Escribila y resolvela.

---

## Cierre (dentro del archivo, como comentarios)

1. ¿Qué se puede hacer ahora que antes era imposible?
2. La tabla plana tenía 17 columnas; tu modelo tiene más tablas y más columnas en total. ¿Por qué eso es una mejora y no un retroceso?
3. Una pregunta que tu modelo **todavía** no puede responder, y qué habría que agregarle.

---

## Rúbrica (100 puntos)

| Criterio | Pts |
|---|---|
| Parte A: diagnóstico completo y con razones, no descripciones | 15 |
| Las 4 tablas creadas, con PK, FK y las restricciones pedidas | 25 |
| **`labor_insumo` bien resuelta (PK compuesta + columnas propias)** | **15** |
| Migración completa, sin pérdida de datos, con el nombre corregido | 15 |
| D2 devuelve 12 «OK» | 10 |
| Consultas D1 y D3–D6 correctas | 10 |
| Preguntas de cierre respondidas con criterio | 10 |
| **Extra:** demostrar con un `INSERT` que falla que tu modelo impide un dato imposible | +5 |

El archivo tiene que correr **completo de la primera línea a la última** después de `agrodb_nucleo.sql`. Si hay que arreglarlo para que corra, eso se descuenta antes de mirar el contenido.
