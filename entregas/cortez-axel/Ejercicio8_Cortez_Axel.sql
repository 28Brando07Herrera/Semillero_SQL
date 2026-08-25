-- EJERCICIO PRÁCTICO 8: El tablero que nadie auditó
-- Estudiante: Cortez Axel
-- Motor: SQLite | Entorno: sqliteonline.com

PRAGMA foreign_keys = ON;

-- Limpieza preventiva para que el script corra completo sin errores
DROP VIEW IF EXISTS v_lote_finca;
DROP VIEW IF EXISTS v_produccion_lote;
DROP VIEW IF EXISTS v_produccion_finca;
DROP VIEW IF EXISTS v_temp_diaria_v2;
DROP VIEW IF EXISTS v_costo_siembra;
DROP VIEW IF EXISTS v_eficiencia_insumos_lote;


-- PARTE A · LA CONSULTA QUE SE QUEDA

-- A1. Creación de v_lote_finca
-- Esperado: 8 filas
CREATE VIEW v_lote_finca AS
SELECT 
    f.nombre AS finca,
    l.codigo AS lote,
    l.hectareas,
    l.tipo_suelo
FROM lotes l
JOIN fincas f ON l.finca_id = f.finca_id;

-- Verificación A1:
SELECT COUNT(*) AS total_lotes FROM v_lote_finca;


-- A2. Consulta sobre la vista sin escribir ningún JOIN
-- Esperado: 3 filas (L-02 con 31, L-01 con 28.5, L-03 con 19.25)
SELECT finca, lote, hectareas, tipo_suelo
FROM v_lote_finca
WHERE finca = 'Hacienda Santa Rosa'
ORDER BY hectareas DESC;

/*
COMENTARIO A3:
Los datos no están guardados en la vista 'v_lote_finca', sino en las tablas físicas 'fincas' y 'lotes'.
La vista solo almacena la definición de la consulta (la "pregunta").
Si mañana alguien le hace un UPDATE a la tabla lotes para cambiar las hectáreas a 40, la vista va a devolver 40 automáticamente, porque cada vez que la consulto, SQLite ejecuta el SELECT interno sobre el estado actual de las tablas.
*/


-- PARTE B · EL TABLERO DE PRODUCCIÓN

-- B1. Creación de v_produccion_lote aplicando * 1.0 para no perder decimales
-- Esperado: 6 filas
CREATE VIEW v_produccion_lote AS
SELECT 
    f.nombre AS finca,
    l.codigo AS lote,
    l.hectareas,
    COUNT(c.cosecha_id) AS n_cosechas,
    SUM(c.kg) AS kg_total,
    ROUND((SUM(c.kg) * 1.0) / l.hectareas, 2) AS kg_ha
FROM cosechas c
JOIN siembras s ON c.siembra_id = s.siembra_id
JOIN lotes l ON s.lote_id = l.lote_id
JOIN fincas f ON l.finca_id = f.finca_id
GROUP BY f.finca_id, l.lote_id;

-- Verificación B1:
SELECT * FROM v_produccion_lote ORDER BY finca, lote;


-- B2. Creación de v_produccion_finca consultando directamente v_produccion_lote
-- Esperado: 3 filas (La Union: 38.18 | El Guayabo: 351.85 | Santa Rosa: 180.32)
CREATE VIEW v_produccion_finca AS
SELECT 
    finca,
    COUNT(*) AS lotes,
    SUM(kg_total) AS kg,
    ROUND((SUM(kg_total) * 1.0) / SUM(hectareas), 2) AS kg_ha
FROM v_produccion_lote
GROUP BY finca;

-- Verificación B2:
SELECT * FROM v_produccion_finca ORDER BY finca;

/*
COMENTARIO B2:
En B2 escribí 0 JOINs porque llamé directo a la vista anterior.
Sin embargo, por debajo la consulta corre sobre 4 tablas reales ('cosechas', 'siembras', 'lotes' y 'fincas'), ya que SQLite primero desglosa la definición de 'v_produccion_lote' antes de resolver la agregación por finca.
*/


-- B3. Comprobación de que la vista sigue a los datos
-- 1) Estado inicial
SELECT kg_total, n_cosechas, kg_ha 
FROM v_produccion_lote 
WHERE finca LIKE 'Hacienda%' AND lote = 'L-01';

-- 2) Inserto cosecha de prueba
INSERT INTO cosechas (siembra_id, fecha, kg, calidad, destino)
VALUES (1, '2026-05-02', 500, 'primera', 'mercado local');

-- 3) Verifico tras inserción (Esperado: 7800 / 3 / 273.68)
SELECT kg_total, n_cosechas, kg_ha 
FROM v_produccion_lote 
WHERE finca LIKE 'Hacienda%' AND lote = 'L-01';

-- 4) Borro el registro insertado
DELETE FROM cosechas WHERE fecha = '2026-05-02';

-- 5) Verifico que volvió a su estado original (7300 / 2 / 256.14)
SELECT kg_total, n_cosechas, kg_ha 
FROM v_produccion_lote 
WHERE finca LIKE 'Hacienda%' AND lote = 'L-01';

/*
COMENTARIO B3:
El número cambió porque una vista no es una copia estática de datos, sino una pregunta guardada que SQLite le repite a las tablas base cada vez que ejecuto el SELECT, recalculando todo con las filas que existan en ese momento.
*/


-- B4. Prueba de la trampa del IF NOT EXISTS
-- CREATE VIEW IF NOT EXISTS v_produccion_lote AS SELECT 1 AS chiste;
-- SELECT * FROM v_produccion_lote;
/*
COMENTARIO B4:
No dio error; el SELECT devolvió las 6 filas normales de siempre y SQLite ignoró por completo el nuevo SELECT.
Esto es más peligroso que un error porque si actualizo la lógica de una vista usando IF NOT EXISTS, la base no se queja, pero tampoco aplica los cambios y sigo ejecutando la versión vieja pensando que ya está corregida.
*/


-- PARTE C · EL TABLERO QUE YA ESTABA PUBLICADO

-- C1. Conteo de filas de v_temp_diaria
-- Esperado: 35 filas
SELECT COUNT(*) AS total_dias_temp FROM v_temp_diaria;

/*
COMENTARIO C1 (Mi hipótesis):
Como abril solo tiene 30 días, las 5 filas extra deben venir de lecturas registradas en otro mes por algún sensor viejo o inactivo que no se filtró.
*/


-- C2. Inspección del código fuente de las vistas
SELECT sql FROM sqlite_master WHERE type = 'view';

/*
COMENTARIO C2:
1. El WHERE solo filtra `s.tipo = 'temperatura'`. No filtra si el sensor está activo (`activo = 1`) ni restringe el rango de fechas.
2. Hay 3 sensores de temperatura: el sensor 1 (activo, midiendo en abril), el sensor 3 (inactivo, pero con lecturas de febrero) y el sensor 5 (inactivo, sin lecturas).
3. Los 5 días extra vienen del sensor 3, que tiene lecturas viejas del 4 al 8 de febrero de 2026 antes de que lo dieran de baja.
*/


-- C3. Ranking con la vista original v_temp_diaria
-- Esperado: 35 filas
SELECT 
    dia,
    temp_promedio,
    RANK() OVER (ORDER BY temp_promedio DESC) AS puesto
FROM v_temp_diaria
ORDER BY temp_promedio DESC, dia;

/*
COMENTARIO C3:
De los 10 días empatados en el puesto 2 (25.63 °C), 5 son de febrero (sensor 3 dado de baja) y 5 son de abril (sensor 1). 
Un tablero que muestre este top está mintiendo, porque mezcla datos de un sensor apagado con la operación actual de abril.
*/


/*
COMENTARIO C4:
1. NO. Alguien que solo consume esta vista no puede darse cuenta de que al 20 de abril le faltan datos porque la vista solo entrega 'dia' y 'temp_promedio', ocultando la cantidad de mediciones.
2. Habría alcanzado con agregar la columna `n_lecturas` usando `COUNT(*)`.
3. Ayer en una consulta individual duró solo lo que tardé en darme cuenta; pero guardado en una vista, el error dura meses alimentando tableros a ciegas.
*/


-- C5. Creación de v_temp_diaria_v2 (Auditada y trazable)
-- Esperado: 30 filas (todas de abril de 2026, con conteo visible)
CREATE VIEW v_temp_diaria_v2 AS
SELECT 
    s.sensor_id,
    f.nombre AS finca,
    lo.codigo AS lote,
    DATE(l.fecha_hora) AS dia,
    COUNT(*) AS n_lecturas,
    ROUND(AVG(l.valor), 2) AS temp_promedio
FROM lecturas l
JOIN sensores s ON s.sensor_id = l.sensor_id
JOIN lotes lo ON lo.lote_id = s.lote_id
JOIN fincas f ON f.finca_id = lo.finca_id
WHERE s.tipo = 'temperatura'
  AND s.activo = 1
  AND l.fecha_hora >= '2026-04-01' AND l.fecha_hora < '2026-05-01'
GROUP BY s.sensor_id, f.nombre, lo.codigo, DATE(l.fecha_hora);

-- Verificación C5:
SELECT * FROM v_temp_diaria_v2 ORDER BY temp_promedio DESC, dia;

/*
COMENTARIO C5:
No arreglé el promedio del 20 de abril (sigue dando 27.33 porque las lecturas nocturnas ya no existen), pero arreglé la transparencia ya que ahora el reporte muestra al lado que solo tiene 6 lecturas, haciendo evidente que está incompleto.
*/


/*
COMENTARIO C6:
1. Si el tablero espera 2 columnas fijas y le meto 4 de golpe, mañana a las 7 AM va a tronar la aplicación con un error de estructura.
2. Si preguntan por qué bajaron los promedios, les explico que se quitó la distorsión de un sensor inactivo de febrero que estaba inflando los reportes diarios de abril.
3. Yo habría publicado 'v_temp_diaria_v2' en paralelo para que el equipo de frontend/tableros adapte sus consultas primero, y luego dar de baja la vista vieja sin romper nada en producción.
*/


-- C7. Auditoría de v_alertas_sensores
-- Esperado: 93 filas (42 temperatura, 21 humedad, 30 radiación)
SELECT COUNT(*) AS total_alertas FROM v_alertas_sensores;

SELECT tipo, COUNT(*) AS alertas_por_tipo
FROM v_alertas_sensores
GROUP BY tipo;

/*
COMENTARIO C7:
La vista 'v_alertas_sensores' está BIEN escrita. 
Al revisar su definición veo que sí incluye `s.activo = 1`, descartando las 10 alertas del sensor 3 que estaba dado de baja (que subirían la cuenta a 103). Además, mantiene la granularidad de cada medición individual y muestra finca y lote correctamente.
*/


-- PARTE D · LO QUE UNA VISTA NO PUEDE Y LO QUE PUEDE ESCONDER

-- D1. Intento de escritura en una vista con agregados
/*
INTENTO DE ESCRITURA:
INSERT INTO v_produccion_lote VALUES ('x','y',1,1,1,1);
-- Error: SQLITE_ERROR: sqlite3 result code 1: cannot modify v_produccion_lote because it is a view

UPDATE v_produccion_lote SET kg_total = 0;
-- Error: SQLITE_ERROR: sqlite3 result code 1: cannot modify v_produccion_lote because it is a view

COMENTARIO D1:
Si SQLite me dejara escribirle 8000 a kg_total, no tendría forma de saber cómo repartir esos kilos entre las distintas cosechas individuales que componen esa suma.
*/


-- D2. Intento de indexación sobre una vista
/*
INTENTO DE INDEXACIÓN:
CREATE INDEX ix_kgha ON v_produccion_lote(kg_ha);
-- Error: SQLITE_ERROR: sqlite3 result code 1: views may not be indexed

COMENTARIO D2:
Una vista no hace que la consulta sea más rápida; cada vez que hago SELECT sobre la vista, SQLite tiene que correr de nuevo todo el query con sus JOINs y cálculos desde cero.
*/


-- D3. Validación tardía de vistas
-- CREATE VIEW v_fantasma AS SELECT * FROM tabla_que_no_existe; -> Se crea sin chistar
-- SELECT * FROM v_fantasma; -> Error: no such table: tabla_que_no_existe
/*
COMENTARIO D3:
SQLite no revisa si las tablas existen al momento de crear la vista, sino recién cuando alguien la consulta.
Si en un sistema con vistas anidadas alguien le cambia el nombre a una tabla base, ninguna vista va a fallar al instante; van a explotar todas juntas cuando los usuarios abran sus reportes.
*/


-- D4. Corrección del error de Fan-Out en costos de siembra
/*
COMENTARIO D4 (1 y 2):
1. Dio 455 en vez de 335 porque la labor 1 tiene 2 insumos, y al hacerle JOIN directo se duplicó su mano de obra (120 * 2 = 240, sumando 120 de más).
2. Se perdieron las siembras 9 y 10 porque tenían INNER JOIN con 'labores' y esas dos siembras aún no tienen labores registradas.
*/

-- 3) Creación de v_costo_siembra corregida
-- Esperado: 10 filas, Siembra 1 en 335 | 295.80 | 630.80, Total = 3562.30
CREATE VIEW v_costo_siembra AS
WITH mo_siembra AS (
    SELECT siembra_id, SUM(costo_mano_obra) AS costo_mo
    FROM labores
    GROUP BY siembra_id
),
insumos_siembra AS (
    SELECT la.siembra_id, SUM(li.cantidad * li.costo_unitario) AS costo_ins
    FROM labores la
    JOIN labor_insumo li ON la.labor_id = li.labor_id
    GROUP BY la.siembra_id
)
SELECT 
    si.siembra_id,
    f.nombre AS finca,
    l.codigo AS lote,
    c.nombre AS cultivo,
    si.estado,
    COALESCE(mo.costo_mo, 0.0) AS costo_mano_obra,
    ROUND(COALESCE(ins.costo_ins, 0.0), 2) AS costo_insumos,
    ROUND(COALESCE(mo.costo_mo, 0.0) + COALESCE(ins.costo_ins, 0.0), 2) AS costo_total
FROM siembras si
JOIN lotes l ON si.lote_id = l.lote_id
JOIN fincas f ON l.finca_id = f.finca_id
JOIN cultivos c ON si.cultivo_id = c.cultivo_id
LEFT JOIN mo_siembra mo ON si.siembra_id = mo.siembra_id
LEFT JOIN insumos_siembra ins ON si.siembra_id = ins.siembra_id;

-- Verificación D4:
SELECT * FROM v_costo_siembra ORDER BY siembra_id;

-- Control de cuadre con Clase 5 (Esperado: 3562.30):
SELECT ROUND(SUM(costo_total), 2) AS control_costo_total FROM v_costo_siembra;


-- PARTE E · CIERRE

/*
1. Diferencia de ciclo de vida entre CTE y Vista:
Una CTE solo vive mientras se ejecuta la consulta que la contiene, mientras que una vista se queda guardada permanentemente en el catálogo de la base de datos hasta que se elimine con DROP VIEW.

2. Dificultad para encontrar errores en Vistas:
Porque la vista disfraza una consulta compleja detrás del nombre de una tabla simple, haciendo que uno asuma que el dato ya viene validado y nadie se tome la molestia de abrir su definición para auditarla.

3. Tres reglas que me impongo para publicar vistas:
- Regla 1 (Nombre claro y explícito): El nombre debe decir exactamente qué filtra y su nivel de agregación (por ejemplo, 'v_temp_diaria_abril_sensores_activos' en lugar de 'v_temp').
- Regla 2 (Conteo siempre presente): Todo promedio o total agregado debe llevar su columna COUNT(*) al lado para ver sobre cuántas filas se calculó.
- Regla 3 (Preagrupar antes de unir): Si combino tablas con diferente nivel de detalle, debo preagruparlas por separado con CTEs o subconsultas antes del JOIN principal para no generar fan-out y duplicar costos.
*/


-- EXTRA: Vista adicional de negocio
-- Nombre: v_eficiencia_insumos_lote
-- Pregunta de negocio: "¿Cuál es el costo total de agroquímicos e insumos aplicados 
-- por hectárea en cada lote y qué porcentaje del costo operativo representa?"
-- Justificación: Es un indicador agronómico clave para control de presupuesto que 
-- combina 4 tablas y requiere preagrupación; al centralizarlo en una vista evito que 
-- cada área calcule los costos por hectárea con fórmulas distintas.

CREATE VIEW v_eficiencia_insumos_lote AS
WITH costos_lote AS (
    SELECT 
        l.lote_id,
        f.nombre AS finca,
        l.codigo AS lote,
        l.hectareas,
        COALESCE(SUM(la.costo_mano_obra), 0) AS mo_total,
        COALESCE(SUM(li.cantidad * li.costo_unitario), 0) AS insumos_total
    FROM lotes l
    JOIN fincas f ON l.finca_id = f.finca_id
    LEFT JOIN siembras s ON l.lote_id = s.lote_id
    LEFT JOIN labores la ON s.siembra_id = la.siembra_id
    LEFT JOIN labor_insumo li ON la.labor_id = li.labor_id
    GROUP BY l.lote_id, f.nombre, l.codigo, l.hectareas
)
SELECT 
    finca,
    lote,
    hectareas,
    ROUND((insumos_total * 1.0) / hectareas, 2) AS costo_insumos_por_ha,
    ROUND(mo_total + insumos_total, 2) AS costo_operativo_total,
    ROUND(
        CASE 
            WHEN (mo_total + insumos_total) > 0 
            THEN (insumos_total * 100.0) / (mo_total + insumos_total)
            ELSE 0.0 
        END, 1
    ) AS pct_gasto_insumos
FROM costos_lote
ORDER BY finca, lote;

-- Verificación Extra:
SELECT * FROM v_eficiencia_insumos_lote;