# Ejercicio práctico 4 · Limpiar el lote de abril
**Duración: 2 horas · Individual · sqliteonline.com · Entrega: un archivo `.sql`**

---

## La situación

Un pasante cargó las labores de abril desde una planilla, sin revisar. Todo entró sin un solo mensaje de error, y sin embargo la base quedó rota: hay fechas ilegibles, insumos duplicados, una labor cargada dos veces y un jornal sin registrar.

Tu trabajo es dejarla limpia **sin perder información real** y sin romper nada en el camino.

## Antes de empezar

1. **Pestaña nueva** en sqliteonline.com → SQLite.
2. Pegá `datos/agrodb_clase4.sql` completo y ejecutalo. Deben salir **3, 6, 8, 10, 9, 20, 18, 6**.
   Ese script ya trae el modelo de la clase 3 resuelto, así que todos arrancan del mismo punto.
3. Trabajá en `Ejercicio4_Apellido_Nombre.sql`.

## Dos reglas del día, sin excepciones

> **1. Todo `UPDATE` y todo `DELETE` va dentro de un `BEGIN … COMMIT`.** Ni uno suelto.
>
> **2. Antes de cada uno, corré el mismo `WHERE` como `SELECT COUNT(*)`** y dejá el resultado escrito como comentario. Si el conteo no es el que esperabas, parás.

---

## Parte A · Diagnóstico (30 min)

Escribí **una consulta por cada problema**, que lo encuentre y muestre las filas afectadas. No arregles nada todavía.

**A1.** Labores cuya fecha no está en formato ISO `AAAA-MM-DD`.
*Pista:* `NOT LIKE '____-__-__'` (cuatro guiones bajos, guion, dos, guion, dos).

**A2.** Labores donde el responsable es el **texto** `'NULL'` en vez de un NULL de verdad.
Después corré `SELECT COUNT(*) FROM labores WHERE responsable IS NULL` y explicá por qué esa fila no aparece ahí.

**A3.** Labores cargadas dos veces: misma siembra, mismo tipo, misma fecha, mismo responsable.
*Pista:* `GROUP BY` de esas cuatro columnas + `HAVING COUNT(*) > 1`. Mostrá los `labor_id` con `GROUP_CONCAT`.

**A4.** Insumos duplicados en el catálogo. Ojo: `UNIQUE(nombre)` no los detectó porque los textos son distintos. Tenés que **comparar normalizado**: sin espacios y en minúsculas.

**A5.** Labores con jornal sin cargar (costo en 0 y una observación que dice que quedó pendiente).

**A6.** Antes de tocar la fecha rota, dejá probado por qué era grave. Corré estas dos y explicá cada resultado como comentario:
```sql
SELECT labor_id, fecha FROM labores ORDER BY fecha LIMIT 3;
SELECT labor_id, strftime('%m', fecha) FROM labores WHERE labor_id = 17;
```

---

## Parte B · Arreglos simples (30 min)

En **una sola transacción**, con su `SELECT COUNT(*)` previo cada uno:

**B1.** Pasá la fecha rota a formato ISO.
**B2.** Convertí el `'NULL'` de texto en un NULL de verdad.
**B3.** Cargá el jornal pendiente y actualizá la observación para dejar constancia de que se corrigió.

Al terminar, `COMMIT` y volvé a correr las consultas A1, A2 y A5: las tres deben devolver **0 filas**.

---

## Parte C · La labor duplicada y el CASCADE (20 min)

**C1.** Antes de borrar nada, contá cuántas filas tiene `labor_insumo` para la labor duplicada que vas a eliminar.
**C2.** En una transacción, borrá **solo la copia** (la del id mayor).
**C3.** Volvé a contar las filas de `labor_insumo` de esa labor. Explicá en un comentario por qué cambió el número **sin que vos borraras esa fila**.
**C4.** Buscá en `datos/agrodb_clase4.sql` la línea que hizo que eso pasara y pegala como comentario.

---

## Parte D · Fusionar los insumos duplicados (30 min)

El Mancozeb es directo. **La urea no**: la labor 20 tiene las dos versiones cargadas, 60 kg con un id y 40 kg con el otro. En la realidad son 100 kg del mismo insumo.

**D1.** Probá primero el camino obvio y **dejá el error copiado** en tu archivo como comentario:
```sql
UPDATE labor_insumo SET insumo_id = 1 WHERE insumo_id = 8;
```
Explicá por qué falla. (Si lo hiciste dentro de un `BEGIN`, un `ROLLBACK` te deja como antes.)

**D2.** Resolvelo bien, en una transacción, en este orden:
1. Donde la labor ya tiene el insumo bueno → **sumar** la cantidad del duplicado.
2. Borrar las filas del duplicado que ya quedaron sumadas.
3. Reapuntar al insumo bueno las filas que no chocaban.
4. Recién ahora, borrar del catálogo los insumos duplicados.

**D3.** Hacé lo mismo con el Mancozeb.

**D4.** Comprobá: la labor 20 debe tener **una sola** fila de urea, con **100**.

---

## Parte E · Verificación y demos (10 min)

**E1.** Conteo final de `insumos`, `labores` y `labor_insumo` en una sola consulta.
Esperado: **7, 19, 16**.

**E2.** Que no quede ningún duplicado, ninguna fecha rota, ningún `'NULL'` de texto ni ninguna clave foránea huérfana (`PRAGMA foreign_key_check`).

**E3.** Demostrá que `RESTRICT` protege el catálogo: intentá borrar un insumo que esté en uso y copiá el error.

**E4.** El experimento del susto, dentro de un `BEGIN` y terminado con `ROLLBACK`:
```sql
BEGIN TRANSACTION;
  UPDATE labores SET responsable = 'Pedro Loor';   -- sin WHERE
  SELECT COUNT(*) FROM labores WHERE responsable = 'Pedro Loor';
ROLLBACK;
SELECT COUNT(*) FROM labores WHERE responsable = 'Pedro Loor';
```
Escribí los dos números y qué habría pasado sin el `BEGIN`.

---

## Cierre (comentarios en el archivo)

1. De los cinco problemas, ¿cuál habría sido el más caro si nadie lo detectaba en seis meses? Justificá.
2. `UNIQUE(nombre)` existía y aun así entraron dos ureas. ¿Qué restricción habría que agregarle a la tabla para que el motor lo impidiera solo? (No hace falta implementarla; describila.)
3. ¿Qué tendría que haber hecho distinto el pasante al cargar, para que nada de esto pasara?

---

## Rúbrica (100 puntos)

| Criterio | Pts |
|---|---|
| Parte A: las 6 consultas de diagnóstico encuentran lo que tienen que encontrar | 20 |
| Parte B: los tres arreglos, en transacción y con conteo previo | 15 |
| Parte C: borrado correcto + explicación del CASCADE con la línea citada | 15 |
| **Parte D: fusión de la urea sin perder los 100 kg** | **20** |
| Parte E: verificación completa y las dos demos | 15 |
| Preguntas de cierre con criterio | 15 |
| **Extra:** una consulta que detecte un problema de calidad que yo no pedí | +5 |

El archivo debe correr **completo** después de `datos/agrodb_clase4.sql`. Si un `UPDATE` o `DELETE` aparece fuera de una transacción, se descuenta aunque el resultado sea correcto.
