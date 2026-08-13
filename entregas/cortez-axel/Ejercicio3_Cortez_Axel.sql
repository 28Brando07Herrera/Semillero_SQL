-- ============================================================================
-- EJERCICIO PRÁCTICO 3: Arreglar el registro de campo
-- Estudiante: Tu Apellido, Tu Nombre
-- ============================================================================

-- Activar el soporte de claves foráneas en SQLite
PRAGMA foreign_keys = ON;


-- ============================================================================
-- PARTE A · DIAGNÓSTICO
-- ============================================================================

/*
1. ¿Qué tenés que hacer para registrar una labor con TRES insumos? ¿Por qué es grave?
Respuesta:
En la tabla plana actual tendría que duplicar la fila entera tres veces o agregar más columnas
al diseño (insumo_1, insumo_2, insumo_3). Esto es un problema gravísimo porque destruye la
integridad de los datos: duplica innecesariamente datos redundantes (finca, lote, fecha) y
obliga a modificar la estructura de la base de datos cada vez que se agregue un nuevo insumo.

2. Explicación del resultado de:
SELECT finca, COUNT(*) FROM registro_campo_plano GROUP BY finca;
Respuesta:
Muestra más de 3 fincas (o registros separados) porque hay inconsistencias de tipeo y errores de
ingreso en el texto, como en la fila 4 donde escribieron "La Providencia " con un espacio al final
o con variaciones. Fincas reales solo hay 3. SQLite no devuelve error de sintaxis; simplemente
agrupa por cadenas de texto exactas, tratando cadenas con espacios o faltas de ortografía como
fincas distintas.

3. ¿De qué depende la columna 'provincia'?
Respuesta:
Depende de la 'finca' y no directamente de cada evento/fila (dependencia funcional transitiva).
Si Los Ríos cambia de nombre, habría que actualizar múltiples filas manualmente en la tabla
plana con el riesgo de dejar datos desactualizados o inconsistentes. En un modelo normalizado,
la provincia debe estar en la tabla de fincas.

4. Comparación de 'costo_total' en filas 1 y 4:
Respuesta:
No significan lo mismo. En la fila 1, el costo de $120.0 representa exclusivamente el gasto
en insumos (Urea), mientras que en la fila 4, el costo de $45.0 representa únicamente el pago
de mano de obra (poda/limpieza) ya que no se usó ningún insumo.

5. Modelo a construir (Esquema conceptual):
- fincas (1) ------ (N) lotes
- lotes (1) ------ (N) siembras
- lotes (1) ------ (N) sensores
- siembras (1) ------ (N) labores
- labores (1) ------ (N) labor_insumo (N) ------ (1) insumos
*/


-- ============================================================================
-- PARTE B · CONSTRUCCIÓN
-- ============================================================================

-- 1. Tabla: insumos
CREATE TABLE insumos (
    insumo_id INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL UNIQUE,
    tipo TEXT NOT NULL CHECK(tipo IN ('fertilizante', 'fungicida', 'semilla', 'herbicida', 'insecticida')),
    unidad_medida TEXT NOT NULL DEFAULT 'kg',
    precio_referencia REAL CHECK(precio_referencia IS NULL OR precio_referencia >= 0)
);

-- 2. Tabla: labores
CREATE TABLE labores (
    labor_id INTEGER PRIMARY KEY AUTOINCREMENT,
    siembra_id INTEGER NOT NULL,
    tipo_labor TEXT NOT NULL,
    fecha DATE NOT NULL,
    responsable TEXT NOT NULL,
    costo_mano_obra REAL NOT NULL DEFAULT 0 CHECK(costo_mano_obra >= 0),
    observacion TEXT,
    FOREIGN KEY (siembra_id) REFERENCES siembras(siembra_id)
);

-- 3. Tabla: labor_insumo (Tabla puente)
CREATE TABLE labor_insumo (
    labor_id INTEGER NOT NULL,
    insumo_id INTEGER NOT NULL,
    cantidad REAL NOT NULL CHECK(cantidad > 0),
    costo_unitario REAL NOT NULL CHECK(costo_unitario >= 0),
    PRIMARY KEY (labor_id, insumo_id),
    FOREIGN KEY (labor_id) REFERENCES labores(labor_id) ON DELETE CASCADE,
    FOREIGN KEY (insumo_id) REFERENCES insumos(insumo_id)
);

-- 4. Tabla: sensores
CREATE TABLE sensores (
    sensor_id INTEGER PRIMARY KEY AUTOINCREMENT,
    lote_id INTEGER NOT NULL,
    codigo_sensor TEXT NOT NULL UNIQUE,
    tipo TEXT NOT NULL CHECK(tipo IN ('temperatura', 'humedad', 'radiacion')),
    modelo TEXT,
    fecha_instalacion DATE NOT NULL,
    activo INTEGER NOT NULL DEFAULT 1 CHECK(activo IN (0, 1)),
    FOREIGN KEY (lote_id) REFERENCES lotes(lote_id)
);

-- PUNTO DE CONTROL 1: Debe devolver 6 filas
SELECT m.name AS tabla, f."from" AS columna, f."table" AS apunta_a
FROM sqlite_master m
JOIN pragma_foreign_key_list(m.name) f
WHERE m.type = 'table'
  AND m.name IN ('insumos','labores','labor_insumo','sensores')
ORDER BY m.name;


-- PARTE C · MIGRACIÓN

-- C1. Poblar catálogo de insumos
INSERT INTO insumos (insumo_id, nombre, tipo, unidad_medida, precio_referencia) VALUES
(1, 'Urea', 'fertilizante', 'kg', 0.80),
(2, 'Glifosato', 'herbicida', 'L', 12.00),
(3, 'Mancozeb', 'fungicida', 'kg', 15.00),
(4, 'KCL (Cloruro de Potasio)', 'fertilizante', 'kg', 0.90),
(5, 'Semilla Arroz FL-10', 'semilla', 'kg', 2.50),
(6, 'Insecticida Biológico Dipel', 'insecticida', 'L', NULL); -- Insumo sin uso para D3

-- C2. Poblar labores
-- Se corrige la mano de obra: si no hay insumos, todo el costo_total va a mano de obra.
INSERT INTO labores (labor_id, siembra_id, tipo_labor, fecha, responsable, costo_mano_obra, observacion) VALUES
(1,  1, 'Fertilización', '2024-01-15', 'Carlos Mendoza', 0.0, 'Primera dosis'),
(2,  1, 'Fumigación',    '2024-01-20', 'Carlos Mendoza', 0.0, 'Control maleza'),
(3,  2, 'Fertilización', '2024-01-10', 'Ana Torres',     0.0, 'Fondo'),
(4,  2, 'Poda',          '2024-01-18', 'Ana Torres',     45.0, 'Nombre de finca corregido de la fila 4'),
(5,  3, 'Siembra',       '2024-02-01', 'Luis Vera',      0.0, 'Densidad alta'),
(6,  4, 'Fumigación',    '2024-02-05', 'Luis Vera',      0.0, 'Preventivo'),
(7,  4, 'Fertilización', '2024-02-12', 'Luis Vera',      0.0, 'Foliar'),
(8,  5, 'Riego y Limpieza','2024-01-22','Carlos Mendoza', 30.0, 'Mantenimiento'),
(9,  5, 'Fertilización', '2024-02-02', 'Carlos Mendoza', 0.0, 'Segunda dosis'),
(10, 6, 'Fertilización', '2024-02-10', 'Ana Torres',     0.0, 'Fondo'),
(11, 7, 'Siembra',       '2024-02-15', 'Luis Vera',      0.0, 'Variedad FL'),
(12, 8, 'Fumigación',    '2024-02-20', 'Ana Torres',     0.0, 'Control insectos');

-- C3. Poblar labor_insumo
INSERT INTO labor_insumo (labor_id, insumo_id, cantidad, costo_unitario) VALUES
(1,  1, 150.0, 0.80), -- Fila 1: Urea 150kg * 0.80 = 120
(2,  2,  10.0, 12.00),-- Fila 2: Glifosato 10L * 12.00 = 120
(3,  4, 200.0, 0.90), -- Fila 3: KCL 200kg * 0.90 = 180
(5,  5,  80.0, 2.50), -- Fila 5: Semilla 80kg * 2.50 = 200
(6,  3,   5.0, 15.00),-- Fila 6: Mancozeb 5kg * 15.00 = 75
(7,  1, 100.0, 0.85), -- Fila 7: Urea 100kg * 0.85 = 85
(9,  1, 180.0, 0.82), -- Fila 9: Urea 180kg * 0.82 = 147.6
(10, 4, 150.0, 0.90), -- Fila 10: KCL 150kg * 0.90 = 135
(11, 5, 100.0, 2.50), -- Fila 11: Semilla 100kg * 2.50 = 250
(12, 3,   8.0, 15.00);-- Fila 12: Mancozeb 8kg * 15.00 = 120

-- C4. Poblar sensores de prueba
INSERT INTO sensores (lote_id, codigo_sensor, tipo, modelo, fecha_instalacion, activo) VALUES
(1, 'SN-TEMP-01', 'temperatura', 'DHT22', '2024-01-01', 1),
(1, 'SN-HUM-01',  'humedad',     'YL-69', '2024-01-01', 1),
(2, 'SN-RAD-01',  'radiacion',   'SQ-110', '2024-01-05', 1);

-- PUNTO DE CONTROL 2: Verificación de claves foráneas
PRAGMA foreign_key_check;

-- PARTE D · VERIFICACIÓN Y PREGUNTAS DE NEGOCIO

-- D1. ¿Cuántas filas tiene cada una de nuestras nuevas cuatro tablas?
SELECT 'insumos' AS tabla, COUNT(*) AS total_filas FROM insumos
UNION ALL
SELECT 'labores', COUNT(*) FROM labores
UNION ALL
SELECT 'labor_insumo', COUNT(*) FROM labor_insumo
UNION ALL
SELECT 'sensores', COUNT(*) FROM sensores;

-- D2. Prueba de fuego: ¿Coinciden los costos calculados con los originales?
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

-- D3. ¿Cuál es el insumo del catálogo que nunca se ha utilizado en ninguna labor?
SELECT i.insumo_id, i.nombre, i.tipo
FROM insumos i
LEFT JOIN labor_insumo li ON i.insumo_id = li.insumo_id
WHERE li.insumo_id IS NULL;

-- D4. ¿Cuánto se ha gastado en total en insumos en cada finca, ordenado de mayor a menor?
SELECT f.nombre AS finca, ROUND(SUM(li.cantidad * li.costo_unitario), 2) AS gasto_total_insumos
FROM fincas f
JOIN lotes l ON f.finca_id = l.finca_id
JOIN siembras s ON l.lote_id = s.lote_id
JOIN labores lb ON s.siembra_id = lb.siembra_id
JOIN labor_insumo li ON lb.labor_id = li.labor_id
GROUP BY f.finca_id, f.nombre
ORDER BY gasto_total_insumos DESC;

-- D5. Los lotes que NO tienen ningún sensor instalado
SELECT l.lote_id, l.codigo AS codigo_lote, f.nombre AS finca
FROM lotes l
JOIN fincas f ON l.finca_id = f.finca_id
LEFT JOIN sensores s ON l.lote_id = s.lote_id
WHERE s.sensor_id IS NULL;

-- D6. Pregunta propia: ¿Cuál es el costo total acumulado por hectárea según el tipo de cultivo?
SELECT c.nombre AS cultivo, 
       ROUND(SUM(lb.costo_mano_obra + COALESCE(li.cantidad * li.costo_unitario, 0)) / SUM(l.hectareas), 2) AS costo_por_hectarea
FROM cultivos c
JOIN siembras s ON c.cultivo_id = s.cultivo_id
JOIN lotes l ON s.lote_id = l.lote_id
JOIN labores lb ON s.siembra_id = lb.siembra_id
LEFT JOIN labor_insumo li ON lb.labor_id = li.labor_id
GROUP BY c.cultivo_id, c.nombre;

-- -- CIERRE Y REFLEXIÓN

/*
1. ¿Qué se puede hacer ahora que antes era imposible?
Ahora podemos asociar múltiples insumos a una sola labor sin duplicar información,
hacer seguimiento histórico a las variaciones de precios de insumos, consultar gastos
exactos diferenciando mano de obra de insumos, y consultar métricas agregadas por finca,
lote o cultivo de manera limpia y rápida.

2. ¿Por qué pasar de 17 columnas a más tablas y columnas es una mejora?
Porque elimina la redundancia de datos (anomalías de inserción, actualización y borrado),
asegura la integridad referencial mediante claves foráneas y permite que el sistema escale.
Una estructura relacional normalizada facilita la creación de reportes y mantiene la base
de datos liviana y consistente.

3. ¿Qué pregunta NO puede responder el modelo todavía y qué habría que agregarle?
No podemos responder qué valores o lecturas en tiempo real han registrado los sensores
(ej. cuál fue la temperatura promedio registrada ayer en el Lote 1). Para responder esto,
habría que crear una nueva tabla `mediciones_sensores` con las columnas `(medicion_id, sensor_id, fecha_hora, valor)`.
*/


-- ============================================================================
-- EXTRA (+5 PUNTOS): Demostración de restricción (Check Constraint)
-- ============================================================================

-- Intentar insertar una cantidad negativa en labor_insumo (Debe fallar por la restricción CHECK)
-- INSERT INTO labor_insumo (labor_id, insumo_id, cantidad, costo_unitario) 
-- VALUES (1, 1, -50.0, 0.80);