# Chuleta · Definir tablas en SQLite

## Tipos que vas a usar

| Tipo | Para qué | Ejemplo |
|---|---|---|
| `INTEGER` | enteros, ids, contadores | `cantidad INTEGER` |
| `TEXT` | cualquier texto, **y las fechas** | `nombre TEXT` |
| `NUMERIC(10,2)` | decimales con precisión (dinero, kilos) | `costo NUMERIC(10,2)` |
| `DATE` | alias de TEXT, formato `'AAAA-MM-DD'` | `fecha DATE` |
| `REAL` | decimales científicos | `temperatura REAL` |

> SQLite no tiene tipo fecha de verdad. Guardás texto ISO `'2026-08-11'` y todo funciona:
> ordena bien, compara bien, y `strftime` lo entiende. Cualquier otro formato rompe las tres cosas.

## Restricciones

```sql
id        INTEGER PRIMARY KEY                    -- se autoincrementa solo
nombre    TEXT    NOT NULL                       -- obligatorio
apodo     TEXT                                   -- admite NULL
codigo    TEXT    UNIQUE                         -- no se repite
estado    TEXT    NOT NULL DEFAULT 'activo'      -- valor si no se especifica
cantidad  INTEGER NOT NULL CHECK (cantidad > 0)  -- valor imposible bloqueado
otra_id   INTEGER NOT NULL REFERENCES otra(otra_id)
```

Restricciones sobre varias columnas, al final de la tabla:

```sql
UNIQUE (finca_id, codigo),
PRIMARY KEY (labor_id, insumo_id),      -- clave primaria compuesta
CHECK (fecha_fin >= fecha_inicio)
```

## Claves foráneas

```sql
PRAGMA foreign_keys = ON;   -- SIEMPRE. Sin esto SQLite las ignora en silencio.
```

Qué pasa al borrar el padre:

| Cláusula | Comportamiento |
|---|---|
| *(nada)* | Bloquea el borrado si hay hijos |
| `ON DELETE RESTRICT` | Igual, pero explícito |
| `ON DELETE CASCADE` | Borra también los hijos |
| `ON DELETE SET NULL` | Deja los hijos huérfanos con NULL |

## Diagnóstico

```sql
-- ¿Qué tablas existen?
SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;

-- ¿Cómo es una tabla por dentro?
PRAGMA table_info(labores);

-- Mapa de claves foráneas: "la tabla X apunta a Y por la columna Z"
SELECT m.name AS tabla, f."from" AS columna, f."table" AS apunta_a
FROM sqlite_master m
JOIN pragma_foreign_key_list(m.name) f
WHERE m.type='table' ORDER BY m.name;

-- ¿Hay ids que apuntan a la nada?
PRAGMA foreign_key_check;
```

## MySQL → SQLite

Los videos de YouTube casi siempre usan MySQL. Traducción:

| MySQL | SQLite |
|---|---|
| `INT AUTO_INCREMENT PRIMARY KEY` | `INTEGER PRIMARY KEY` |
| `VARCHAR(50)` | `TEXT` |
| `DATETIME` | `TEXT` con `'AAAA-MM-DD HH:MM:SS'` |
| `SHOW TABLES;` | `SELECT name FROM sqlite_master WHERE type='table';` |
| `DESCRIBE tabla;` | `PRAGMA table_info(tabla);` |
| `LIMIT 5` | igual |
| `TOP 5` | **no existe** (eso es SQL Server) → `LIMIT 5` |

## El orden que nunca falla

1. `DROP TABLE` en orden **inverso** (primero las que dependen)
2. `CREATE TABLE` de las tablas sin FK, después las que apuntan a ellas
3. Punto de control: mapa de FK
4. `INSERT` primero en las tablas apuntadas
5. Punto de control: `PRAGMA foreign_key_check`
6. Consultas
