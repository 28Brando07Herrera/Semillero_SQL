---
marp: true
paginate: true
theme: default
title: "Clase 4 · Modificar datos sin romper nada"
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
footer: "Curso de SQL · AgroDB · Clase 4"
---

<!-- _class: lead -->

# Modificar datos sin romper nada

## INSERT, UPDATE, DELETE y la red de seguridad

Clase 4 · 12 de agosto

---

# Hasta ayer, leer. Desde hoy, escribir.

Un `SELECT` mal escrito devuelve un resultado equivocado.

Un `UPDATE` mal escrito **destruye datos**.

> La diferencia entre las dos mitades del oficio es que una se deshace con F5 y la otra no se deshace.

---

# INSERT tiene tres formas

```sql
-- 1. Explícita: la que se usa en producción
INSERT INTO insumos (insumo_id, nombre, tipo, unidad)
VALUES (10, 'Bocashi', 'fertilizante', 'kg');

-- 2. Posicional: cómoda para cargar, frágil para mantener
INSERT INTO insumos VALUES (10, 'Bocashi', 'fertilizante', 'kg', 0.30);

-- 3. Desde una consulta: así se migra de verdad
INSERT INTO insumos (nombre, tipo, unidad)
SELECT DISTINCT insumo_1, 'fertilizante', unidad_1
FROM registro_campo_plano
WHERE insumo_1 IS NOT NULL;
```

La forma 2 se rompe el día que alguien agrega una columna. **Nombrá siempre las columnas.**

---

# `INSERT … SELECT`

Ayer migraron 12 filas a mano. Estuvo bien: había que entender el mapeo.

Con 40.000 filas eso no existe. Se hace así:

```sql
INSERT INTO labores (siembra_id, tipo_labor, fecha, responsable)
SELECT s.siembra_id, p.tipo_labor, p.fecha_labor, p.responsable
FROM registro_campo_plano p
JOIN lotes    lo ON lo.codigo  = p.lote
JOIN fincas   f  ON f.finca_id = lo.finca_id AND f.nombre = p.finca
JOIN siembras s  ON s.lote_id  = lo.lote_id;
```

La consulta **es** la migración.

---

# La regla que evita el 90% de los desastres

## Antes de todo `UPDATE` o `DELETE`, corré el mismo `WHERE` como `SELECT`.

```sql
SELECT COUNT(*) FROM labores WHERE labor_id = 17;   -- dice 1
UPDATE labores SET fecha = '2026-04-15' WHERE labor_id = 17;
```

Si el `SELECT` devuelve 1, el `UPDATE` va a tocar 1.
Si devuelve 19, **algo entendiste mal**.

---

# El error clásico

```sql
UPDATE labores SET responsable = 'Pedro Loor';
```

<br>

Falta el `WHERE`.

Acaba de reasignar **las 19 labores** a Pedro Loor.

SQLite no pregunta. No avisa. No hay Ctrl+Z.

---

# Salvo que estés en una transacción

```sql
BEGIN TRANSACTION;

  UPDATE labores SET responsable = 'Pedro Loor';   -- sin WHERE
  SELECT COUNT(*) FROM labores WHERE responsable = 'Pedro Loor';
  -- 19. Eso no era lo que querías.

ROLLBACK;   -- nunca pasó
```

- `BEGIN` — abrís el paréntesis
- `COMMIT` — confirmás: recién ahí es real
- `ROLLBACK` — cancelás todo lo que hiciste desde el `BEGIN`

---

# Una transacción es todo o nada

Transferir 100 kg de insumo de una bodega a otra son **dos** operaciones:

```sql
BEGIN TRANSACTION;
  UPDATE stock SET cantidad = cantidad - 100 WHERE bodega = 'A';
  UPDATE stock SET cantidad = cantidad + 100 WHERE bodega = 'B';
COMMIT;
```

Si el sistema se cae en el medio, sin transacción **desaparecen 100 kg**.

Con transacción, o pasan las dos o no pasa ninguna.

---

# DELETE: qué le pasa a los hijos

Cuando borrás una fila de la que dependen otras, el motor tiene que decidir. Vos se lo decís **al crear la tabla**:

| Cláusula | Qué hace |
|---|---|
| `ON DELETE RESTRICT` | Bloquea el borrado. El default |
| `ON DELETE CASCADE` | Borra también a los hijos |
| `ON DELETE SET NULL` | Deja huérfanos con NULL |

---

# En AgroDB, cada una tiene su razón

```sql
labor_id  INTEGER REFERENCES labores(labor_id) ON DELETE CASCADE,
insumo_id INTEGER REFERENCES insumos(insumo_id) ON DELETE RESTRICT
```

**Borro una labor** → sus renglones de insumo no tienen sentido solos. `CASCADE`.

**Borro un insumo del catálogo** → hay labores históricas que lo usaron. `RESTRICT`: la base te frena.

> No es una preferencia técnica. Es una decisión de negocio escrita en SQL.

---

# El problema de hoy

Un pasante cargó el lote de labores de abril desde una planilla.

**Todo entró sin un solo mensaje de error.**

Y sin embargo, la base quedó rota.

---

# Cinco problemas que ninguna restricción detectó

| Qué pasó | Por qué entró igual |
|---|---|
| `'15/04/2026'` como fecha | Es texto válido |
| `'NULL'` como responsable | Es texto, no es NULL |
| La misma labor cargada dos veces | Distinto `labor_id`, PK contenta |
| `Urea 46%` y `Urea 46 %` en el catálogo | `UNIQUE` compara literal |
| Un jornal sin cargar | 0 es un número válido |

---

# La fecha rota, en dos consultas

```sql
SELECT fecha FROM labores ORDER BY fecha LIMIT 3;
```
```
15/04/2026      ← se ordena primero. Compara texto, no fecha.
2026-02-14
2026-03-02
```

```sql
SELECT strftime('%m', fecha) FROM labores WHERE labor_id = 17;
```
```
NULL            ← la función no la entiende, y no avisa
```

---

# Detectar duplicados: normalizar antes de comparar

`UNIQUE(nombre)` no los vio, porque para el motor son distintos.

```sql
SELECT LOWER(REPLACE(nombre, ' ', '')) AS clave,
       COUNT(*)                        AS veces,
       GROUP_CONCAT(insumo_id)         AS ids
FROM insumos
GROUP BY clave
HAVING COUNT(*) > 1;
```

> La técnica general: **agrupá por la versión limpia y contá.** Sirve para nombres, correos, cédulas, códigos.

---

# Fusionar duplicados: la trampa

```sql
UPDATE labor_insumo SET insumo_id = 1 WHERE insumo_id = 8;
```
```
UNIQUE constraint failed: labor_insumo.labor_id, insumo_id
```

La labor 20 tiene **las dos** ureas: 60 kg con el id 1 y 40 kg con el id 8.

Reapuntar la segunda chocaría contra la primera.

## Hay que sumar antes de reapuntar. 100 kg, una sola fila.

---

<!-- _class: lead -->

# Práctica · 2 horas

## Limpiar el lote de abril

Todo dentro de transacciones. Todo verificado antes y después.

`clases/04-modificar-datos/ejercicio.md`

---

# Antes de arrancar

1. **Pestaña nueva** en sqliteonline.com
2. Pegar `datos/agrodb_clase4.sql` completo y ejecutar
   → **3, 6, 8, 10, 9, 20, 18, 6**
3. Ese script ya trae el modelo de ayer resuelto: todos arrancan parejos

<br>

> **Nunca escribas un `UPDATE` o un `DELETE` fuera de un `BEGIN`.** Hoy, ni una sola vez.
