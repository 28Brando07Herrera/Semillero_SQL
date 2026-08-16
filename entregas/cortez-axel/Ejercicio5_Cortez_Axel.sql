-- EJERCICIO PRÁCTICO 5: Las preguntas del jefe de finca
-- Estudiante: Cortez Axel
-- Motor: SQLite | Entorno: sqliteonline.com

PRAGMA foreign_keys = ON;

-- PARTE A · RECORRER EL MODELO

-- A1. Catálogo de siembras (4 tablas: fincas, lotes, siembras, cultivos)
-- Esperado: 10 filas
SELECT 
    f.nombre AS finca,
    l.codigo AS lote,
    c.nombre AS cultivo,
    c.variedad,
    s.fecha_siembra,
    s.estado
FROM siembras s
JOIN lotes l ON s.lote_id = l.lote_id
JOIN fincas f ON l.finca_id = f.finca_id
JOIN cultivos c ON s.cultivo_id = c.cultivo_id
ORDER BY f.nombre, l.codigo;


-- A2. Todas las labores de abril de 2026 con finca, lote y responsable
-- Esperado: 10 filas
SELECT 
    lb.labor_id,
    f.nombre AS finca,
    l.codigo AS lote,
    lb.tipo_labor,
    lb.fecha,
    lb.responsable
FROM labores lb
JOIN siembras s ON lb.siembra_id = s.siembra_id
JOIN lotes l ON s.lote_id = l.lote_id
JOIN fincas f ON l.finca_id = f.finca_id
WHERE lb.fecha LIKE '2026-04-%'
ORDER BY lb.fecha;

/*
EXPLICACIÓN A2:
El responsable de la labor 18 se muestra vacío (NULL) porque en la Clase 4 se limpió
el string de texto 'NULL' que había ingresado el pasante, convirtiéndolo a un NULL real de SQL.
*/


-- A3. Detalle de consumo de insumos

SELECT 
    f.nombre AS finca,
    l.codigo AS lote,
    lb.tipo_labor,
    lb.fecha,
    i.nombre AS insumo,
    li.cantidad,
    i.unidad,
    (li.cantidad * li.costo_unitario) AS costo_linea
FROM labor_insumo li
JOIN insumos i ON li.insumo_id = i.insumo_id
JOIN labores lb ON li.labor_id = lb.labor_id
JOIN siembras s ON lb.siembra_id = s.siembra_id
JOIN lotes l ON s.lote_id = l.lote_id
JOIN fincas f ON l.finca_id = f.finca_id
ORDER BY f.nombre, l.codigo, lb.fecha;


-- PARTE B · EL SUM QUE MIENTE

-- B1. Kilos cosechados por finca
-- Control COUNT(*):
-- SELECT f.nombre, COUNT(*) FROM fincas f JOIN lotes l ON f.finca_id = l.finca_id JOIN siembras s ON l.lote_id = s.lote_id JOIN cosechas c ON s.siembra_id = c.siembra_id GROUP BY f.nombre;
-- Conteo de filas de cosechas: Hacienda Santa Rosa (3), Finca El Guayabo (4), Agricola La Union (2) -> Total 9 cosechas.
SELECT 
    f.nombre AS finca,
    SUM(c.kg) AS total_kg
FROM fincas f
JOIN lotes l ON f.finca_id = l.finca_id
JOIN siembras s ON l.lote_id = s.lote_id
JOIN cosechas c ON s.siembra_id = c.siembra_id
GROUP BY f.nombre;
-- Esperado: Hacienda Santa Rosa 14200 · Finca El Guayabo 14250 · Agricola La Union 2100


-- B2. Consulta con error de fan-out (JOIN con labores)
SELECT 
    f.nombre AS finca,
    SUM(c.kg) AS total_kg_inflado,
    COUNT(lb.labor_id) AS total_labores_infladas
FROM fincas f
JOIN lotes l ON f.finca_id = l.finca_id
JOIN siembras s ON l.lote_id = s.lote_id
JOIN cosechas c ON s.siembra_id = c.siembra_id
JOIN labores lb ON s.siembra_id = lb.siembra_id
GROUP BY f.nombre;
/*
NÚMEROS NUEVOS INFLADOS:
- Agricola La Union: 4200 kg (duplicado) | 4 labores
- Finca El Guayabo: 30100 kg (inflado)  | 10 labores
- Hacienda Santa Rosa: 38100 kg (inflado) | 11 labores
*/


-- B3. Demostración del Fan-out

-- B3.a) Comparativa por siembra: labores, cosechas y producto cartesiano
SELECT 
    s.siembra_id,
    (SELECT COUNT(*) FROM labores lb WHERE lb.siembra_id = s.siembra_id) AS cant_labores,
    (SELECT COUNT(*) FROM cosechas c WHERE c.siembra_id = s.siembra_id) AS cant_cosechas,
    (
        SELECT COUNT(*) 
        FROM labores lb 
        JOIN cosechas c ON lb.siembra_id = c.siembra_id 
        WHERE s.siembra_id = lb.siembra_id
    ) AS filas_al_unir
FROM siembras s
ORDER BY s.siembra_id;
-- Siembra 1: 3 labores, 2 cosechas -> 6 filas resultantes al unir (3 x 2 = 6).

-- B3.b) Finca 1: COUNT(*) vs COUNT(DISTINCT c.cosecha_id)
SELECT 
    COUNT(*) AS total_filas_producto,
    COUNT(DISTINCT c.cosecha_id) AS cosechas_reales
FROM fincas f
JOIN lotes l ON f.finca_id = l.finca_id
JOIN siembras s ON l.lote_id = s.lote_id
JOIN cosechas c ON s.siembra_id = c.siembra_id
JOIN labores lb ON s.siembra_id = lb.siembra_id
WHERE f.finca_id = 1;
/*
EXPLICACIÓN B3.b:
COUNT(*) devuelve 11 filas porque cada cosecha se multiplicó por la cantidad de labores que tuvo su siembra.
COUNT(DISTINCT c.cosecha_id) devuelve 4, que es la cantidad real de eventos de cosecha únicos en esa finca (3 de la siembra 1 y 2 de la siembra 2... etc).
*/


-- B4. Solución correcta usando CTEs independientes para evitar el Fan-out
-- Control de filas: 3 fincas esperadas
WITH cte_cosechas AS (
    SELECT l.finca_id, SUM(c.kg) AS total_kg
    FROM siembras s
    JOIN lotes l ON s.lote_id = l.lote_id
    JOIN cosechas c ON s.siembra_id = c.siembra_id
    GROUP BY l.finca_id
),
cte_labores AS (
    SELECT l.finca_id, COUNT(lb.labor_id) AS cant_labores
    FROM siembras s
    JOIN lotes l ON s.lote_id = l.lote_id
    JOIN labores lb ON s.siembra_id = lb.siembra_id
    GROUP BY l.finca_id
)
SELECT 
    f.nombre AS finca,
    COALESCE(cc.total_kg, 0) AS kilos_cosechados,
    COALESCE(cl.cant_labores, 0) AS cantidad_labores
FROM fincas f
LEFT JOIN cte_cosechas cc ON f.finca_id = cc.finca_id
LEFT JOIN cte_labores cl ON f.finca_id = cl.finca_id;
-- Resultado: Hacienda Santa Rosa 14200 (6 labores) · Finca El Guayabo 14250 (7 labores) · Agricola La Union 2100 (4 labores)


-- B5. Fan-out en mano de obra
SELECT SUM(costo_mano_obra) FROM labores; -- 2330.00 (COUNT(*): 19 filas)
SELECT SUM(lb.costo_mano_obra) FROM labores lb JOIN labor_insumo li ON li.labor_id = lb.labor_id; -- 2035.00 (COUNT(*): 16 filas)

-- Labores sin ningún insumo:
SELECT COUNT(*) AS labores_sin_insumo 
FROM labores lb 
LEFT JOIN labor_insumo li ON lb.labor_id = li.labor_id 
WHERE li.labor_id IS NULL; -- Esperado: 7

/*
EXPLICACIÓN B5:
La segunda consulta sufre de dos problemas:
1. Perdió filas: Al hacer un INNER JOIN, se descartaron las 7 labores que no usaron insumos (riegos, podas, etc.) restando $960.00 de mano de obra.
2. Contó de más: Las labores que usaron más de un insumo (como labor_id = 1, 6, 7, 10) se duplicaron en filas, sumando su mano de obra 2 veces.
*/

-- PARTE C · ENCONTRAR LO QUE FALTA (LEFT JOIN)

-- C1. Lotes sin ningún sensor instalado
-- Esperado: 4 lotes
SELECT f.nombre AS finca, l.codigo AS lote
FROM lotes l
JOIN fincas f ON l.finca_id = f.finca_id
LEFT JOIN sensores s ON l.lote_id = s.lote_id
WHERE s.sensor_id IS NULL;


-- C2. Lotes sin ningún sensor activo
-- Esperado: 5 lotes
SELECT f.nombre AS finca, l.codigo AS lote
FROM lotes l
JOIN fincas f ON l.finca_id = f.finca_id
LEFT JOIN sensores s ON l.lote_id = s.lote_id AND s.activo = 1
WHERE s.sensor_id IS NULL;

/*
EXPLICACIÓN C2 (ON vs WHERE):
- Poniendo 'AND s.activo = 1' en el ON: el LEFT JOIN conserva todos los lotes y solo empareja los sensores que estén activos. Si un lote solo tiene sensores inactivos (como el lote 2 con sensor_id 3), s.sensor_id queda NULL y el WHERE lo captura correctamente (5 lotes).
- Si se pone 'WHERE s.activo = 1' o en el WHERE general: el filtro descarta a los lotes que tenían NULL por no tener sensor alguno, convirtiendo el LEFT JOIN en un INNER JOIN de facto y arruinando el reporte.
*/


-- C3. Siembras sin ninguna labor registrada
-- Esperado: 2 siembras
SELECT f.nombre AS finca, l.codigo AS lote, c.nombre AS cultivo, s.fecha_siembra, s.estado
FROM siembras s
JOIN lotes l ON s.lote_id = l.lote_id
JOIN fincas f ON l.finca_id = f.finca_id
JOIN cultivos c ON s.cultivo_id = c.cultivo_id
LEFT JOIN labores lb ON s.siembra_id = lb.siembra_id
WHERE lb.labor_id IS NULL;


-- C4. Insumos del catálogo que nunca se usaron en ninguna labor
-- Esperado: 1 insumo (Cal agricola)
SELECT i.insumo_id, i.nombre, i.tipo, i.unidad
FROM insumos i
LEFT JOIN labor_insumo li ON i.insumo_id = li.insumo_id
WHERE li.insumo_id IS NULL;


-- C5. Siembras en 'en produccion' sin ninguna cosecha registrada
-- Esperado: 1 fila (Siembra 7 - Cacao CCN-51 en Agricola La Union A-2)
SELECT s.siembra_id, f.nombre AS finca, l.codigo AS lote, c.nombre AS cultivo, s.estado
FROM siembras s
JOIN lotes l ON s.lote_id = l.lote_id
JOIN fincas f ON l.finca_id = f.finca_id
JOIN cultivos c ON s.cultivo_id = c.cultivo_id
LEFT JOIN cosechas cs ON s.siembra_id = cs.siembra_id
WHERE s.estado = 'en produccion' AND cs.cosecha_id IS NULL;

/*
MENSAJE AL JEFE DE FINCA:
"Alerta Operativa: El lote A-2 de Agrícola La Unión tiene una siembra de Cacao registrada como 'en producción' desde el 30/01/2025, pero no registra ninguna cosecha en el sistema. Debe verificarse de inmediato si hubo cosechas no reportadas por el encargado o si el estado de la siembra debe reclasificarse."
*/


-- ============================================================================
-- PARTE D · LAS PREGUNTAS DEL JEFE
-- ============================================================================

-- D1. Rendimiento en kg por hectárea de cada lote cosechado
-- Control de filas en cosechas por lote: 6 lotes cosechados
/*
ANÁLISIS PREVIO DE DIVISIÓN:
Si se escribe 'SUM(c.kg) / l.hectareas', en SQLite se divide entero entre decimal.
En lotes con hectáreas decimales (28.50, 47.30, etc.) da con coma, pero si ambos fueran enteros truncaría.
Además, el agrupamiento debe hacerse por finca y lote_id para no colisionar lotes con mismo código (L-01).
*/
SELECT 
    f.nombre AS finca,
    l.codigo AS lote,
    l.hectareas,
    SUM(c.kg) AS total_kg,
    ROUND(CAST(SUM(c.kg) AS NUMERIC) / l.hectareas, 2) AS rendimiento_kg_ha
FROM cosechas c
JOIN siembras s ON c.siembra_id = s.siembra_id
JOIN lotes l ON s.lote_id = l.lote_id
JOIN fincas f ON l.finca_id = f.finca_id
GROUP BY f.finca_id, l.lote_id
ORDER BY rendimiento_kg_ha DESC;
-- Top 3 esperado: El Guayabo L-02 -> 529.73 | Santa Rosa L-01 -> 256.14 | El Guayabo L-01 -> 202.27


-- D2. Costo total por finca (Mano de obra + Insumos)
-- Control: Costo MO general = 2330.00 | Costo Insumos general = 1232.30 | Total = 3562.30
WITH mo_por_finca AS (
    SELECT l.finca_id, SUM(lb.costo_mano_obra) AS costo_mo
    FROM siembras s
    JOIN lotes l ON s.lote_id = l.lote_id
    JOIN labores lb ON s.siembra_id = lb.siembra_id
    GROUP BY l.finca_id
),
insumos_por_finca AS (
    SELECT l.finca_id, SUM(li.cantidad * li.costo_unitario) AS costo_insumos
    FROM siembras s
    JOIN lotes l ON s.lote_id = l.lote_id
    JOIN labores lb ON s.siembra_id = lb.siembra_id
    JOIN labor_insumo li ON lb.labor_id = li.labor_id
    GROUP BY l.finca_id
)
SELECT 
    f.nombre AS finca,
    COALESCE(mo.costo_mo, 0) AS mano_obra,
    COALESCE(ins.costo_insumos, 0) AS insumos,
    (COALESCE(mo.costo_mo, 0) + COALESCE(ins.costo_insumos, 0)) AS costo_total
FROM fincas f
LEFT JOIN mo_por_finca mo ON f.finca_id = mo.finca_id
LEFT JOIN insumos_por_finca ins ON f.finca_id = ins.finca_id
ORDER BY f.nombre;
-- Totales: Santa Rosa: 1441.00 (790 MO + 651 Ins) · El Guayabo: 1024.50 (692 MO + 332.5 Ins) · La Union: 1096.80 (848 MO + 248.8 Ins)


-- D3. Rankings cortos

-- a) Responsables por cantidad de labores
SELECT 
    COALESCE(responsable, 'Sin responsable asignado') AS responsable,
    COUNT(*) AS cantidad_labores
FROM labores
GROUP BY responsable
ORDER BY cantidad_labores DESC;
-- Arriba: Pedro Loor con 5 labores

-- b) Insumos ordenados por costo total consumido
-- Control COUNT(*): 16 líneas de labor_insumo
SELECT 
    i.nombre AS insumo,
    SUM(li.cantidad * li.costo_unitario) AS costo_total_consumido
FROM labor_insumo li
JOIN insumos i ON li.insumo_id = i.insumo_id
GROUP BY i.insumo_id, i.nombre
ORDER BY costo_total_consumido DESC;
-- Arriba: Urea 46% con 427.00


-- ============================================================================
-- PARTE E · CIERRE
-- ============================================================================

/*
1. ¿Cuál de los 3 errores es el más peligroso para un gerente?
El 'SUM inflado por Fan-out'. Es el más destructivo porque la consulta corre con éxito, no arroja ningún 
error sintáctico y genera cifras que aparentan ser legítimas pero duplican o triplican ingresos, costos o volúmenes 
reales. Puede provocar que la gerencia tome decisiones estratégicas o de inversión basadas en márgenes ficticios.

2. Nombre técnico de normalización:
- Separar insumo_1, insumo_2, insumo_3 en filas de labor_insumo: 1FN (Primera Forma Normal - Elimina grupos repetitivos y asegura atomicidad).
- Sacar unidad a la tabla insumos: 2FN (Segunda Forma Normal - Elimina dependencias parciales respecto a la clave primaria).
- Sacar provincia a la tabla fincas: 3FN (Tercera Forma Normal - Elimina dependencias transitivas).

3. Pregunta de negocio que AgroDB todavía NO puede responder:
"¿Cuál es el margen de ganancia neta o rentabilidad monetaria por venta de cada cosecha?"
Falta la tabla 'ventas' (o agregar en 'cosechas' las columnas 'precio_venta_unitario', 'ingreso_total' y 'cliente_comprador'), 
ya que el modelo registra el volumen físico (kg) y el destino, pero no registra el valor monetario liquidado al vender la fruta.
*/


-- EXTRA: Pregunta de negocio propia (4+ tablas)
-- "¿Cuál es el costo total invertido por cada kilogramo de cultivo cosechado?"

-- Consulta que calcula el Costo Unitario de Producción ($ / Kg) por siembra:
-- Combina 5 tablas: fincas, lotes, cultivos, siembras, cosechas, labores y labor_insumo
WITH costos_siembra AS (
    SELECT 
        s.siembra_id,
        SUM(lb.costo_mano_obra) + COALESCE((
            SELECT SUM(li.cantidad * li.costo_unitario)
            FROM labores lb2
            JOIN labor_insumo li ON lb2.labor_id = li.labor_id
            WHERE lb2.siembra_id = s.siembra_id
        ), 0) AS costo_total_siembra
    FROM siembras s
    JOIN labores lb ON s.siembra_id = lb.siembra_id
    GROUP BY s.siembra_id
),
kilos_siembra AS (
    SELECT siembra_id, SUM(kg) AS total_kg
    FROM cosechas
    GROUP BY siembra_id
)
SELECT 
    f.nombre AS finca,
    l.codigo AS lote,
    c.nombre AS cultivo,
    ks.total_kg AS kg_cosechados,
    cs.costo_total_siembra AS inversion_total,
    ROUND(cs.costo_total_siembra / ks.total_kg, 3) AS costo_por_kg_producido
FROM siembras s
JOIN lotes l ON s.lote_id = l.lote_id
JOIN fincas f ON l.finca_id = f.finca_id
JOIN cultivos c ON s.cultivo_id = c.cultivo_id
JOIN kilos_siembra ks ON s.siembra_id = ks.siembra_id
JOIN costos_siembra cs ON s.siembra_id = cs.siembra_id
ORDER BY costo_por_kg_producido ASC;