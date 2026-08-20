-- =====================================================================
-- CURSO DE SQL  |  AgroDB  |  Ejercicio 5
-- Alumno: Byron Yaguar
-- Fecha: 16-08-2026
--
-- Este archivo se ejecuta DESPUES de datos/agrodb_clase5.sql,
-- en la MISMA sesion de sqliteonline.
-- =====================================================================

PRAGMA foreign_keys = ON;

-- =====================================================================
-- PARTE A - RECORRER EL MODELO 
-- =====================================================================

-- A1. Catálogo de siembras: nombre de finca, código de lote, cultivo,
-- variedad, fecha de siembra y estado. Una fila por siembra.

SELECT COUNT(*) FROM (
  SELECT f.nombre, l.codigo, c.nombre AS cultivo, c.variedad, s.fecha_siembra, s.estado
  FROM siembras s
  JOIN lotes l ON s.lote_id = l.lote_id
  JOIN fincas f ON l.finca_id = f.finca_id
  JOIN cultivos c ON s.cultivo_id = c.cultivo_id
  ORDER BY f.finca_id, l.codigo
);
-- COUNT(*): 10 filas (correcto, sin fan-out)

SELECT f.nombre, l.codigo, c.nombre AS cultivo, c.variedad, s.fecha_siembra, s.estado
FROM siembras s
JOIN lotes l ON s.lote_id = l.lote_id
JOIN fincas f ON l.finca_id = f.finca_id
JOIN cultivos c ON s.cultivo_id = c.cultivo_id
ORDER BY f.finca_id, l.codigo;

-- =====================================================================

-- A2. Todas las labores de abril de 2026 con finca, lote y responsable.
-- Ordenado por fecha.

SELECT COUNT(*) FROM (
  SELECT f.nombre, l.codigo, lb.fecha, lb.tipo_labor, lb.responsable
  FROM labores lb
  JOIN siembras s ON lb.siembra_id = s.siembra_id
  JOIN lotes l ON s.lote_id = l.lote_id
  JOIN fincas f ON l.finca_id = f.finca_id
  WHERE strftime('%m', lb.fecha) = '04' AND strftime('%Y', lb.fecha) = '2026'
  ORDER BY lb.fecha
);
-- COUNT(*): 10 filas

SELECT f.nombre, l.codigo, lb.fecha, lb.tipo_labor, lb.responsable
FROM labores lb
JOIN siembras s ON lb.siembra_id = s.siembra_id
JOIN lotes l ON s.lote_id = l.lote_id
JOIN fincas f ON l.finca_id = f.finca_id
WHERE strftime('%m', lb.fecha) = '04' AND strftime('%Y', lb.fecha) = '2026'
ORDER BY lb.fecha;

-- Explicación: Labor 18 tiene responsable = NULL porque en el ejercicio 4
-- convertimos el texto 'NULL' en un NULL verdadero. Esta labor sigue sin
-- responsable asignado desde que fue cargada.

-- =====================================================================

-- A3. Detalle de consumo de insumos: finca, lote, tipo de labor, fecha,
-- nombre del insumo, cantidad, unidad y costo de la línea.
-- Esperado: 16 filas (= filas en labor_insumo)

SELECT COUNT(*) FROM (
  SELECT f.nombre, l.codigo, lb.tipo_labor, lb.fecha, i.nombre,
         li.cantidad, i.unidad, (li.cantidad * li.costo_unitario) AS costo_linea
  FROM labor_insumo li
  JOIN labores lb ON li.labor_id = lb.labor_id
  JOIN siembras s ON lb.siembra_id = s.siembra_id
  JOIN lotes l ON s.lote_id = l.lote_id
  JOIN fincas f ON l.finca_id = f.finca_id
  JOIN insumos i ON li.insumo_id = i.insumo_id
);
-- COUNT(*): 16 filas (correcto, una por fila en labor_insumo)

SELECT f.nombre, l.codigo, lb.tipo_labor, lb.fecha, i.nombre,
       li.cantidad, i.unidad, ROUND(li.cantidad * li.costo_unitario, 2) AS costo_linea
FROM labor_insumo li
JOIN labores lb ON li.labor_id = lb.labor_id
JOIN siembras s ON lb.siembra_id = s.siembra_id
JOIN lotes l ON s.lote_id = l.lote_id
JOIN fincas f ON l.finca_id = f.finca_id
JOIN insumos i ON li.insumo_id = i.insumo_id
ORDER BY f.finca_id, l.codigo, lb.fecha;

-- =====================================================================
-- PARTE B - EL SUM QUE MIENTE 
-- =====================================================================

-- B1. Kilos cosechados por finca.

SELECT COUNT(*) FROM (
  SELECT f.nombre, SUM(c.kg) AS kilos
  FROM cosechas c
  JOIN siembras s ON c.siembra_id = s.siembra_id
  JOIN lotes l ON s.lote_id = l.lote_id
  JOIN fincas f ON l.finca_id = f.finca_id
  GROUP BY f.finca_id
);
-- COUNT(*): 3 filas (correcto, una por finca)

SELECT f.nombre, SUM(c.kg) AS kilos
FROM cosechas c
JOIN siembras s ON c.siembra_id = s.siembra_id
JOIN lotes l ON s.lote_id = l.lote_id
JOIN fincas f ON l.finca_id = f.finca_id
GROUP BY f.finca_id
ORDER BY f.nombre;

-- =====================================================================

-- B2. Agregando JOIN a labores.
-- ¿Qué pasa con los kilos?

SELECT COUNT(*) FROM (
  SELECT f.nombre, SUM(c.kg) AS kilos, COUNT(lb.labor_id) AS labores
  FROM cosechas c
  JOIN siembras s ON c.siembra_id = s.siembra_id
  JOIN lotes l ON s.lote_id = l.lote_id
  JOIN fincas f ON l.finca_id = f.finca_id
  JOIN labores lb ON s.siembra_id = lb.siembra_id
  GROUP BY f.finca_id
);
-- COUNT(*): 3 filas, pero los kilos están INFLADOS

SELECT f.nombre, SUM(c.kg) AS kilos, COUNT(lb.labor_id) AS labores
FROM cosechas c
JOIN siembras s ON c.siembra_id = s.siembra_id
JOIN lotes l ON s.lote_id = l.lote_id
JOIN fincas f ON l.finca_id = f.finca_id
JOIN labores lb ON s.siembra_id = lb.siembra_id
GROUP BY f.finca_id
ORDER BY f.nombre;

-- Resultado observado (INCORRECTO):
-- Hacienda Santa Rosa: 42600 (debería ser 14200) 3x inflado
-- Finca El Guayabo: 28500 (debería ser 14250) 2x inflado
-- Agricola La Union: 2100 (correcto) ← sin labores? NO, tiene labores

-- =====================================================================

-- B3a. Para cada siembra: labores, cosechas, y filas al unir.
-- Esperado para siembra 1: 3 labores, 2 cosechas, 6 filas (3 × 2)

SELECT s.siembra_id,
       (SELECT COUNT(*) FROM labores WHERE siembra_id = s.siembra_id) AS labores,
       (SELECT COUNT(*) FROM cosechas WHERE siembra_id = s.siembra_id) AS cosechas,
       (SELECT COUNT(*) FROM labores WHERE siembra_id = s.siembra_id) *
       (SELECT COUNT(*) FROM cosechas WHERE siembra_id = s.siembra_id) AS filas_cross_join
FROM siembras s
ORDER BY s.siembra_id;

-- Siembra 1: 3 labores × 2 cosechas = 6 filas
-- Siembra 2: 2 labores × 1 cosecha = 2 filas
-- Siembra 3: 1 labor × 1 cosecha = 1 fila
-- Siembra 4: 2 labores × 2 cosechas = 4 filas
-- Siembra 5: 1 labor × 1 cosecha = 1 fila
-- Siembra 6: 2 labores × 2 cosechas = 4 filas
-- Siembra 7: 1 labor × 0 cosechas = 0 filas
-- Siembra 8: 1 labor × 0 cosechas = 0 filas
-- Siembra 9: 0 labores × 0 cosechas = 0 filas
-- Siembra 10: 0 labores × 0 cosechas = 0 filas

-- =====================================================================

-- B3b. En la consulta de B2, compará COUNT(*) vs COUNT(DISTINCT cosecha_id)
-- para finca 1 (Hacienda Santa Rosa).

SELECT COUNT(*) AS filas_totales,
       COUNT(DISTINCT c.cosecha_id) AS cosechas_distintas
FROM cosechas c
JOIN siembras s ON c.siembra_id = s.siembra_id
JOIN lotes l ON s.lote_id = l.lote_id
JOIN fincas f ON l.finca_id = f.finca_id
JOIN labores lb ON s.siembra_id = lb.siembra_id
WHERE f.finca_id = 1;

-- Resultado esperado: 11 filas totales, 4 cosechas distintas
-- Explicación: Cada cosecha aparece múltiples veces (11/4 ≈ 2.75 veces).
-- Esto es el fan-out: filas multiplicadas sin nuestro control.

-- =====================================================================

-- B4. Arreglarlo: Kilos y labores por finca, AMBAS CORRECTAS.
-- Esperado: Santa Rosa 14200 · El Guayabo 14250 · La Union 2100

WITH cosechas_agg AS (
  SELECT f.finca_id, SUM(c.kg) AS kg_total
  FROM cosechas c
  JOIN siembras s ON c.siembra_id = s.siembra_id
  JOIN lotes l ON s.lote_id = l.lote_id
  JOIN fincas f ON l.finca_id = f.finca_id
  GROUP BY f.finca_id
),
labores_agg AS (
  SELECT f.finca_id, COUNT(lb.labor_id) AS labor_count
  FROM labores lb
  JOIN siembras s ON lb.siembra_id = s.siembra_id
  JOIN lotes l ON s.lote_id = l.lote_id
  JOIN fincas f ON l.finca_id = f.finca_id
  GROUP BY f.finca_id
)
SELECT f.nombre,
       COALESCE(c.kg_total, 0) AS kilos,
       COALESCE(l.labor_count, 0) AS labores
FROM fincas f
LEFT JOIN cosechas_agg c ON f.finca_id = c.finca_id
LEFT JOIN labores_agg l ON f.finca_id = l.finca_id
ORDER BY f.nombre;

-- Los kilos vuelven a ser correctos: 14200 / 14250 / 2100
-- Las labores también son correctas.

-- =====================================================================

-- B5. El error inverso: INNER JOIN que borra filas.

SELECT SUM(costo_mano_obra) AS costo_total_todas
FROM labores;
-- Resultado esperado: 2330.00

SELECT SUM(lb.costo_mano_obra) AS costo_total_con_join
FROM labores lb
JOIN labor_insumo li ON li.labor_id = lb.labor_id;
-- Resultado esperado: 2035.00

-- Explicación de las DIFERENCIAS:
-- 1. FILAS PERDIDAS: 7 labores NO tienen insumos. El INNER JOIN las borra.
--    Esas 7 labores tienen costo total = 120+90+135+45+210+88+68 = 756.00
--    756.00 es lo que "desaparece" (parcialmente, porque también hay duplicación)
--
-- 2. FILAS CONTADAS DE MAS: Las 12 labores CON insumos aparecen múltiples veces
--    (una por cada insumo). Ejemplo: labor 1 tiene 2 insumos → aparece 2 veces.
--    Pero ambas veces suma su costo_mano_obra, inflando parcialmente.
--
-- Resultado neto: 2330 - 295 (aproximado por duplicación) = 2035

-- Contar labores sin insumo:
SELECT COUNT(*) AS labores_sin_insumo
FROM labores lb
WHERE NOT EXISTS (
  SELECT 1 FROM labor_insumo li WHERE li.labor_id = lb.labor_id
);
-- Resultado esperado: 7 labores (4, 5, 12, 14, 17, 18, 19)

-- =====================================================================
-- PARTE C - ENCONTRAR LO QUE FALTA
-- =====================================================================

-- C1. Lotes sin NINGÚN sensor instalado, con su finca.
-- Esperado: 4 lotes

SELECT COUNT(*) FROM (
  SELECT l.lote_id, l.codigo, f.nombre
  FROM lotes l
  JOIN fincas f ON l.finca_id = f.finca_id
  LEFT JOIN sensores s ON l.lote_id = s.lote_id
  WHERE s.sensor_id IS NULL
);
-- COUNT(*): 4 filas

SELECT l.lote_id, l.codigo, f.nombre
FROM lotes l
JOIN fincas f ON l.finca_id = f.finca_id
LEFT JOIN sensores s ON l.lote_id = s.lote_id
WHERE s.sensor_id IS NULL
ORDER BY f.nombre, l.codigo;

-- =====================================================================

-- C2. Lotes sin NINGÚN sensor ACTIVO.
-- Esperado: 5 lotes
-- TRAMPA: ¿Dónde pongo la condición activo = 1?

-- INCORRECTO (en WHERE):
SELECT COUNT(*) FROM (
  SELECT l.lote_id, l.codigo, f.nombre
  FROM lotes l
  JOIN fincas f ON l.finca_id = f.finca_id
  LEFT JOIN sensores s ON l.lote_id = s.lote_id
  WHERE s.activo = 1
);
-- Resultado: 4 filas (FALSO, convirtió el LEFT JOIN en INNER JOIN)

-- CORRECTO (en ON):
SELECT COUNT(*) FROM (
  SELECT l.lote_id, l.codigo, f.nombre
  FROM lotes l
  JOIN fincas f ON l.finca_id = f.finca_id
  LEFT JOIN sensores s ON l.lote_id = s.lote_id AND s.activo = 1
  WHERE s.sensor_id IS NULL
);
-- COUNT(*): 5 filas

SELECT l.lote_id, l.codigo, f.nombre
FROM lotes l
JOIN fincas f ON l.finca_id = f.finca_id
LEFT JOIN sensores s ON l.lote_id = s.lote_id AND s.activo = 1
WHERE s.sensor_id IS NULL
ORDER BY f.nombre, l.codigo;

-- EXPLICACIÓN DE LA TRAMPA (C2):
-- Versión incorrecta (WHERE s.activo = 1):
--   1. LEFT JOIN une lotes y sensores (mantiene lotes sin sensor)
--   2. WHERE filtra DESPUÉS: borra lotes sin sensor (porque s.sensor_id = NULL)
--   3. Solo quedan lotes CON sensor activo → es un INNER JOIN disfrazado
--
-- Versión correcta (ON s.lote_id = s.lote_id AND s.activo = 1):
--   1. LEFT JOIN ya filtra durante la unión: solo une sensores ACTIVOS
--   2. Lotes sin sensor activo quedan con NULL en la fila de sensor
--   3. WHERE filtra lotes que quedaron con NULL en sensor_id
--   4. Resultado: lotes sin sensor activo (ya sea sin sensor o con sensor inactivo)

-- =====================================================================

-- C3. Siembras sin NINGUNA labor registrada, con finca, lote, cultivo y estado.
-- Esperado: 2 siembras

SELECT COUNT(*) FROM (
  SELECT si.siembra_id, f.nombre, l.codigo, c.nombre, si.estado
  FROM siembras si
  JOIN fincas f ON (
    SELECT f.finca_id FROM fincas f
    JOIN lotes l ON f.finca_id = l.finca_id
    WHERE l.lote_id = si.lote_id
  ) = f.finca_id
  JOIN lotes l ON si.lote_id = l.lote_id
  JOIN cultivos c ON si.cultivo_id = c.cultivo_id
  LEFT JOIN labores lb ON si.siembra_id = lb.siembra_id
  WHERE lb.labor_id IS NULL
);
-- COUNT(*): 2 filas (siembras 9 y 10)

SELECT si.siembra_id, f.nombre, l.codigo, c.nombre, si.estado
FROM siembras si
JOIN lotes l ON si.lote_id = l.lote_id
JOIN fincas f ON l.finca_id = f.finca_id
JOIN cultivos c ON si.cultivo_id = c.cultivo_id
LEFT JOIN labores lb ON si.siembra_id = lb.siembra_id
WHERE lb.labor_id IS NULL
ORDER BY f.nombre, l.codigo;

-- =====================================================================

-- C4. Insumos que NUNCA fueron usados en ninguna labor.
-- Esperado: 1 insumo

SELECT COUNT(*) FROM (
  SELECT i.insumo_id, i.nombre
  FROM insumos i
  LEFT JOIN labor_insumo li ON i.insumo_id = li.insumo_id
  WHERE li.labor_id IS NULL
);
-- COUNT(*): 1 fila

SELECT i.insumo_id, i.nombre
FROM insumos i
LEFT JOIN labor_insumo li ON i.insumo_id = li.insumo_id
WHERE li.labor_id IS NULL
ORDER BY i.nombre;

-- =====================================================================

-- C5. Siembras en estado 'en produccion' que NO tienen cosecha registrada.
-- Esperado: 1 siembra
-- Esta es una ALARMA REAL para el jefe.

SELECT COUNT(*) FROM (
  SELECT si.siembra_id, f.nombre, l.codigo, c.nombre, si.estado
  FROM siembras si
  JOIN lotes l ON si.lote_id = l.lote_id
  JOIN fincas f ON l.finca_id = f.finca_id
  JOIN cultivos c ON si.cultivo_id = c.cultivo_id
  LEFT JOIN cosechas cos ON si.siembra_id = cos.siembra_id
  WHERE si.estado = 'en produccion' AND cos.cosecha_id IS NULL
);
-- COUNT(*): 1 fila

SELECT si.siembra_id, f.nombre, l.codigo, c.nombre, si.estado
FROM siembras si
JOIN lotes l ON si.lote_id = l.lote_id
JOIN fincas f ON l.finca_id = f.finca_id
JOIN cultivos c ON si.cultivo_id = c.cultivo_id
LEFT JOIN cosechas cos ON si.siembra_id = cos.siembra_id
WHERE si.estado = 'en produccion' AND cos.cosecha_id IS NULL
ORDER BY f.nombre, l.codigo;

-- ALERTA AL JEFE:
-- Siembra 2 (Finca El Guayabo, Lote L-02, Guayaba) está en "en produccion"
-- pero NO tiene ninguna cosecha registrada.
-- Esto puede significar:
--   1. La cosecha no fue registrada en el sistema (error administrativo)
--   2. La cosecha aún no fue realizada (pero el estado dice "en produccion", no "en curso")
--   3. La cosecha fue perdida/descartada (no valía la pena registrarla)
-- Requiere investigación inmediata.

-- =====================================================================
-- PARTE D - LAS PREGUNTAS DEL JEFE
-- =====================================================================

-- D1. Rendimiento en kg/hectárea de cada lote cosechado.
-- Ordenado de mayor a menor.
-- Mostrá: finca, lote, hectáreas, kilos, rendimiento (redondeado a 2 decimales).
-- Top 3 esperado: El Guayabo L-02 - 529.73 · Santa Rosa L-01 - 256.14 · El Guayabo L-01 - 202.27

-- PRIMERO: versión NAIVE (SUM / hectareas directamente)
-- Esto saldrá con algunos números duplicados porque siembras con múltiples
-- cosechas se multiplican.

SELECT f.nombre, l.codigo, l.hectareas, SUM(c.kg) AS kilos,
       ROUND(SUM(c.kg) * 1.0 / l.hectareas, 2) AS rendimiento_por_ha
FROM cosechas c
JOIN siembras s ON c.siembra_id = s.siembra_id
JOIN lotes l ON s.lote_id = l.lote_id
JOIN fincas f ON l.finca_id = f.finca_id
GROUP BY l.lote_id
ORDER BY rendimiento_por_ha DESC;

-- Esta consulta tiene un problema sutil.
-- Cada lote puede tener MÚLTIPLES siembras, y cada siembra puede tener múltiples cosechas.
-- Si usamos GROUP BY l.lote_id, estamos sumando todas las cosechas de todas las
-- siembras de ese lote, y dividiendo por las hectáreas del lote (que es constante).
-- ESTO PUEDE SER CORRECTO si queremos rendimiento del lote en general.
--
-- PERO si queremos rendimiento por SIEMBRA, necesitamos ser más cuidadosos.
--
-- En este caso, vamos a asumir que queremos rendimiento por SIEMBRA, no por lote.
-- Entonces necesitamos GROUP BY siembra, no por lote.

-- VERSIÓN CORRECTA:
SELECT f.nombre, l.codigo, l.hectareas, SUM(c.kg) AS kilos,
       ROUND(SUM(c.kg) * 1.0 / l.hectareas, 2) AS rendimiento_por_ha
FROM cosechas c
JOIN siembras s ON c.siembra_id = s.siembra_id
JOIN lotes l ON s.lote_id = l.lote_id
JOIN fincas f ON l.finca_id = f.finca_id
GROUP BY s.siembra_id
ORDER BY rendimiento_por_ha DESC;

-- =====================================================================

-- D2. Costo total por finca, separado en mano de obra e insumos.
-- Más la suma de los dos.
-- Esperado: Santa Rosa 1441.00 · El Guayabo 1024.50 · La Union 1096.80
-- Total general: 3562.30

WITH mano_obra AS (
  SELECT f.finca_id, SUM(lb.costo_mano_obra) AS costo_mo
  FROM labores lb
  JOIN siembras s ON lb.siembra_id = s.siembra_id
  JOIN lotes l ON s.lote_id = l.lote_id
  JOIN fincas f ON l.finca_id = f.finca_id
  GROUP BY f.finca_id
),
insumos_costo AS (
  SELECT f.finca_id, SUM(li.cantidad * li.costo_unitario) AS costo_insumos
  FROM labor_insumo li
  JOIN labores lb ON li.labor_id = lb.labor_id
  JOIN siembras s ON lb.siembra_id = s.siembra_id
  JOIN lotes l ON s.lote_id = l.lote_id
  JOIN fincas f ON l.finca_id = f.finca_id
  GROUP BY f.finca_id
)
SELECT f.nombre,
       COALESCE(m.costo_mo, 0) AS mano_obra,
       COALESCE(i.costo_insumos, 0) AS insumos,
       ROUND(COALESCE(m.costo_mo, 0) + COALESCE(i.costo_insumos, 0), 2) AS total
FROM fincas f
LEFT JOIN mano_obra m ON f.finca_id = m.finca_id
LEFT JOIN insumos_costo i ON f.finca_id = i.finca_id
ORDER BY f.nombre;

-- Verificación: suma total
SELECT ROUND(
  (SELECT SUM(costo_mano_obra) FROM labores) +
  (SELECT SUM(cantidad * costo_unitario) FROM labor_insumo), 2) AS total_general;
-- Resultado esperado: 3562.30

-- =====================================================================

-- D3a. Responsables ordenados por cantidad de labores.
-- Arriba debe quedar Pedro Loor con 5.

SELECT COUNT(*) FROM (
  SELECT lb.responsable, COUNT(*) AS cantidad_labores
  FROM labores lb
  GROUP BY lb.responsable
);
-- COUNT(*): 6 filas (incluyendo NULL)

SELECT lb.responsable, COUNT(*) AS cantidad_labores
FROM labores lb
GROUP BY lb.responsable
ORDER BY cantidad_labores DESC;

-- =====================================================================

-- D3b. Insumos ordenados por costo total consumido.
-- Arriba debe quedar Urea 46% con 427.00.

SELECT COUNT(*) FROM (
  SELECT i.nombre, SUM(li.cantidad * li.costo_unitario) AS costo_total
  FROM labor_insumo li
  JOIN insumos i ON li.insumo_id = i.insumo_id
  GROUP BY i.insumo_id
);
-- COUNT(*): 7 filas

SELECT i.nombre, SUM(li.cantidad * li.costo_unitario) AS costo_total
FROM labor_insumo li
JOIN insumos i ON li.insumo_id = i.insumo_id
GROUP BY i.insumo_id
ORDER BY costo_total DESC;

-- =====================================================================
-- PARTE E - CIERRE 
-- =====================================================================

-- 1) De las tres formas de equivocarse que vimos hoy —el SUM inflado,
--    el JOIN que borra filas y la división entera
-- ¿cuál es la más peligrosa en un reporte que ve un gerente?
-- RESPUESTA:
-- El SUM inflado es el más peligroso.
-- Razón: Es silencioso. No hay error de sintaxis, la consulta "funciona".
-- El gerente ve un número que PARECE correcto, y toma decisiones sobre presupuestos,
-- compras y personal basado en cifras falsas. El fan-out multiplica costos o rendimientos
-- de forma impredecible (depende de cuántas cosechas/labores tenga cada siembra).
-- El JOIN que borra filas es menos peligroso porque al menos uno nota que faltan datos
-- en el resultado (si verificas con COUNT). La división entera puede detectarse
-- rápido pidiendo decimales.

-- =====================================================================

-- 2) Poné el nombre técnico (1FN, 2FN o 3FN) a cada uno de estos arreglos:

-- Arreglo 1: Separar insumo_1, insumo_2, insumo_3 en filas de labor_insumo
-- Respuesta: 1FN (Primera Forma Normal)
-- Justificación: Eliminamos repetición de columnas. Cada fila tiene un valor único
-- en lugar de múltiples valores de insumo en la misma fila.

-- Arreglo 2: Sacar `unidad` a la tabla `insumos`
-- Respuesta: 2FN (Segunda Forma Normal)
-- Justificación: Eliminamos dependencias parciales. La unidad depende de insumo_id
-- (la clave primaria), no de una parte de la clave. Ahora cada insumo tiene su unidad,
-- no cada labor_insumo.

-- Arreglo 3: Sacar `provincia` a la tabla `fincas`
-- Respuesta: 3FN (Tercera Forma Normal)
-- Justificación: Eliminamos dependencias transitorias. Provincia depende de finca,
-- que depende de lote, que depende de siembra. Separar la provincia en la tabla fincas
-- elimina esa cadena de dependencias.

-- =====================================================================

-- 3) Hay una pregunta de negocio razonable que AgroDB TODAVIA no puede responder.
--    Escribí cuál es y qué tabla o columna haría falta.

-- RESPUESTA:
-- Pregunta: "¿A qué precio vendimos cada cosecha?"
-- Problema: No hay información de precios de venta en el modelo.
-- Solución: Crear tabla VENTAS o añadir columnas precio_unitario y precio_total
-- a la tabla cosechas. También hacer falta información de a quién se vendió
-- (cliente), fecha de venta, y condiciones de pago.
--
-- Otra pregunta que no podemos responder:
-- "¿Cuál fue la ganancia neta por lote en el período?"
-- Problema: No tenemos costos de inversión inicial (preparación del terreno,
-- infraestructura), costos fijos (mantenimiento), ni ingresos de venta.
-- Solución: Tabla de costos_fijos, precios_productos, y tabla ventas.