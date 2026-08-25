-- =====================================================================
-- CURSO DE SQL  |  CLASE 5  |  EJERCICIO PRACTICO 5
-- Las preguntas del jefe de finca
-- Nombre: Brando Herrera
-- =====================================================================
-- NOTA: antes de correr este archivo, pegar y ejecutar agrodb_clase5.sql
-- completo, en una pestana nueva. Debe dar 3, 6, 8, 10, 7, 19, 16, 6, 9.
-- =====================================================================


-- =====================================================================
-- PARTE A - RECORRER EL MODELO
-- =====================================================================

-- A1. Catalogo de siembras (4 tablas)
SELECT f.nombre AS finca, l.codigo AS lote, cu.nombre AS cultivo, cu.variedad,
       s.fecha_siembra, s.estado
FROM siembras s
JOIN lotes l     ON l.lote_id = s.lote_id
JOIN fincas f    ON f.finca_id = l.finca_id
JOIN cultivos cu ON cu.cultivo_id = s.cultivo_id
ORDER BY f.nombre, l.codigo;
-- Resultado: 10 filas (una por siembra, sin fan-out: cada siembra tiene
-- exactamente un lote, una finca y un cultivo, todas relaciones N:1)


-- A2. Labores de abril 2026
SELECT f.nombre AS finca, l.codigo AS lote, lb.responsable, lb.tipo_labor, lb.fecha
FROM labores lb
JOIN siembras s ON s.siembra_id = lb.siembra_id
JOIN lotes l    ON l.lote_id = s.lote_id
JOIN fincas f   ON f.finca_id = l.finca_id
WHERE lb.fecha BETWEEN '2026-04-01' AND '2026-04-30'
ORDER BY lb.fecha;
-- Resultado: 10 filas.
-- La labor 18 (Agricola La Union, A-2, riego, 2026-04-18) sale con
-- responsable en blanco porque en el ejercicio 4 convertimos el texto
-- literal 'NULL' de esa fila en un NULL de verdad; el dato del
-- responsable real nunca se cargo, simplemente dejo de estar disfrazado
-- de texto y ahora se ve como lo que siempre fue: informacion faltante.


-- A3. Detalle de consumo de insumos (6 tablas)
SELECT f.nombre AS finca, l.codigo AS lote, lb.tipo_labor, lb.fecha,
       i.nombre AS insumo, li.cantidad, i.unidad,
       ROUND(li.cantidad * li.costo_unitario, 2) AS costo_linea
FROM labor_insumo li
JOIN labores lb  ON lb.labor_id = li.labor_id
JOIN siembras s  ON s.siembra_id = lb.siembra_id
JOIN lotes l     ON l.lote_id = s.lote_id
JOIN fincas f    ON f.finca_id = l.finca_id
JOIN insumos i   ON i.insumo_id = li.insumo_id
ORDER BY f.nombre, l.codigo, lb.fecha;
-- Resultado: 16 filas (una por cada fila real de labor_insumo; esta
-- consulta no tiene ningun 1:N que se cruce con otro 1:N, asi que no hay
-- fan-out posible aca)


-- =====================================================================
-- PARTE B - EL SUM QUE MIENTE
-- =====================================================================

-- B1. Kilos cosechados por finca (correcto: un solo 1:N, sin problema)
SELECT f.nombre AS finca, SUM(c.kg) AS kilos
FROM fincas f
JOIN lotes l    ON l.finca_id = f.finca_id
JOIN siembras s ON s.lote_id = l.lote_id
JOIN cosechas c ON c.siembra_id = s.siembra_id
GROUP BY f.nombre;
-- Resultado: Hacienda Santa Rosa 14200, Finca El Guayabo 14250,
-- Agricola La Union 2100  -- coincide exacto con lo esperado


-- B2. "Lo mismo" + JOIN labores (SIN arreglar nada, solo mirar)
SELECT f.nombre AS finca, SUM(c.kg) AS kilos, COUNT(lb.labor_id) AS num_labores
FROM fincas f
JOIN lotes l    ON l.finca_id = f.finca_id
JOIN siembras s ON s.lote_id = l.lote_id
JOIN cosechas c ON c.siembra_id = s.siembra_id
JOIN labores lb ON lb.siembra_id = s.siembra_id
GROUP BY f.nombre;
-- Los tres kilos nuevos que da esta version, ya rotos:
--   Agricola La Union:    4200   (deberia ser 2100)
--   Finca El Guayabo:     32950  (deberia ser 14250)
--   Hacienda Santa Rosa:  41100  (deberia ser 14200)
-- Los tres estan mal. El JOIN a labores no cambio los kilos por si solo:
-- cambio cuantas VECES se repite cada fila de cosecha antes de sumarla.


-- B3. Por que paso

-- a) Por siembra: labores, cosechas, filas del JOIN
SELECT
    s.siembra_id,
    (SELECT COUNT(*) FROM labores WHERE siembra_id = s.siembra_id) AS num_labores,
    (SELECT COUNT(*) FROM cosechas WHERE siembra_id = s.siembra_id) AS num_cosechas,
    (SELECT COUNT(*) FROM labores lb JOIN cosechas c
       ON lb.siembra_id = c.siembra_id
       WHERE lb.siembra_id = s.siembra_id) AS filas_join
FROM siembras s
ORDER BY s.siembra_id;
-- Resultado para la siembra 1: 3 labores, 2 cosechas, 6 filas_join.
-- 3 x 2 = 6: el JOIN entre dos tablas 1:N respecto a la misma siembra no
-- suma filas, las MULTIPLICA (producto cartesiano dentro de cada
-- siembra). Cada cosecha de la siembra 1 aparece repetida una vez por
-- cada labor de esa misma siembra, y por eso SUM(c.kg) la cuenta de mas.

-- b) Finca 1, COUNT(*) vs COUNT(DISTINCT cosecha_id)
SELECT COUNT(*) AS total_filas, COUNT(DISTINCT c.cosecha_id) AS cosechas_distintas
FROM fincas f
JOIN lotes l    ON l.finca_id = f.finca_id
JOIN siembras s ON s.lote_id = l.lote_id
JOIN cosechas c ON c.siembra_id = s.siembra_id
JOIN labores lb ON lb.siembra_id = s.siembra_id
WHERE f.finca_id = 1;
-- Resultado: 11 y 4. La diferencia (11 filas contra solo 4 cosechas
-- reales) es exactamente el fan-out: cada una de las 4 cosechas de la
-- finca 1 quedo repetida varias veces (una por cada labor de su
-- siembra), asi que 11 filas no representan 11 cosechas, representan
-- 4 cosechas infladas por el cruce con labores.


-- B4. Arreglado: kilos y numero de labores por finca, las dos correctas
WITH kilos_siembra AS (
    SELECT siembra_id, SUM(kg) AS kilos
    FROM cosechas
    GROUP BY siembra_id
),
labores_siembra AS (
    SELECT siembra_id, COUNT(*) AS num_labores
    FROM labores
    GROUP BY siembra_id
)
SELECT
    f.nombre AS finca,
    ROUND(SUM(COALESCE(ks.kilos, 0)), 2) AS kilos,
    SUM(COALESCE(ls.num_labores, 0))     AS num_labores
FROM fincas f
JOIN lotes l    ON l.finca_id = f.finca_id
JOIN siembras s ON s.lote_id = l.lote_id
LEFT JOIN kilos_siembra ks   ON ks.siembra_id = s.siembra_id
LEFT JOIN labores_siembra ls ON ls.siembra_id = s.siembra_id
GROUP BY f.nombre;
-- Resultado: kilos vuelven a ser 14200 / 14250 / 2100, y ahora las
-- labores tambien son correctas (8 / 5 / 6). La clave: agregar cada
-- tabla hija POR SEPARADO antes de juntarlas, para que ningun JOIN
-- multiplique filas de la otra.


-- B5. El mismo error, al reves
SELECT SUM(costo_mano_obra) FROM labores;
-- Resultado: 2330.00

SELECT SUM(lb.costo_mano_obra)
FROM labores lb JOIN labor_insumo li ON li.labor_id = lb.labor_id;
-- Resultado: 2035.00
--
-- Dos cosas pasaron, no una:
-- 1) PERDIO filas: es un JOIN (no LEFT JOIN), asi que las labores que no
--    tienen NINGUN insumo (riegos, podas, la cosecha) desaparecen por
--    completo de la suma, aunque si tuvieron costo de mano de obra.
-- 2) CONTO DE MAS otras filas: las labores que usaron 2 insumos (labor 1,
--    6, 7, 10) aparecen 2 veces en el JOIN, asi que su costo_mano_obra
--    se suma 2 veces cada una.
-- El resultado final (2035 en vez de 2330) es la resta neta de ambos
-- efectos, no la simple ausencia de un grupo de filas.

SELECT COUNT(*) FROM labores lb
LEFT JOIN labor_insumo li ON li.labor_id = lb.labor_id
WHERE li.labor_id IS NULL;
-- Resultado: 7 labores sin ningun insumo


-- =====================================================================
-- PARTE C - ENCONTRAR LO QUE FALTA
-- =====================================================================

-- C1. Lotes sin ningun sensor
SELECT f.nombre AS finca, l.codigo AS lote
FROM lotes l
JOIN fincas f ON f.finca_id = l.finca_id
LEFT JOIN sensores se ON se.lote_id = l.lote_id
WHERE se.sensor_id IS NULL;
-- Resultado: 4 filas (Santa Rosa L-03, El Guayabo L-02, Agricola A-2 y B-1)


-- C2. Lotes sin ningun sensor ACTIVO (la trampa del dia)

-- Version con la condicion en el ON (correcta):
SELECT f.nombre AS finca, l.codigo AS lote
FROM lotes l
JOIN fincas f ON f.finca_id = l.finca_id
LEFT JOIN sensores se ON se.lote_id = l.lote_id AND se.activo = 1
WHERE se.sensor_id IS NULL;
-- Resultado: 5 filas (los 4 de C1, mas Santa Rosa L-02, cuyo unico
-- sensor esta instalado pero dado de baja)

-- Version con la condicion en el WHERE (mal, para comparar):
SELECT f.nombre AS finca, l.codigo AS lote
FROM lotes l
JOIN fincas f ON f.finca_id = l.finca_id
LEFT JOIN sensores se ON se.lote_id = l.lote_id
WHERE se.sensor_id IS NULL AND se.activo = 1;
-- Resultado: 0 filas. Explicacion de la diferencia: cuando la condicion
-- de activo va en el ON, el LEFT JOIN primero decide que sensores
-- "cuentan" (solo los activos) y RECIEN DESPUES conserva el lote aunque
-- no haya encontrado ninguno, mostrando se.sensor_id = NULL. Cuando la
-- condicion va en el WHERE, se aplica DESPUES del LEFT JOIN, sobre filas
-- que YA tienen se.sensor_id = NULL para los lotes sin sensor; y
-- NULL = 1 nunca es verdadero en SQL (ni siquiera es falso, es
-- desconocido), asi que el WHERE descarta justo las filas que el LEFT
-- JOIN habia rescatado. Poner la condicion del lado "opcional" en el
-- WHERE convierte sin querer el LEFT JOIN en un JOIN normal.


-- C3. Siembras sin ninguna labor registrada
SELECT f.nombre AS finca, l.codigo AS lote, cu.nombre AS cultivo, s.estado
FROM siembras s
JOIN lotes l     ON l.lote_id = s.lote_id
JOIN fincas f    ON f.finca_id = l.finca_id
JOIN cultivos cu ON cu.cultivo_id = s.cultivo_id
LEFT JOIN labores lb ON lb.siembra_id = s.siembra_id
WHERE lb.labor_id IS NULL;
-- Resultado: 2 filas (Santa Rosa L-01/Maiz/perdido, Agricola A-1/Mango/en curso)


-- C4. Insumos del catalogo nunca usados
SELECT i.insumo_id, i.nombre
FROM insumos i
LEFT JOIN labor_insumo li ON li.insumo_id = i.insumo_id
WHERE li.insumo_id IS NULL;
-- Resultado: 1 fila (Cal agricola)


-- C5. Siembras 'en produccion' sin ninguna cosecha registrada
SELECT f.nombre AS finca, l.codigo AS lote, cu.nombre AS cultivo,
       s.siembra_id, s.estado
FROM siembras s
JOIN lotes l     ON l.lote_id = s.lote_id
JOIN fincas f    ON f.finca_id = l.finca_id
JOIN cultivos cu ON cu.cultivo_id = s.cultivo_id
LEFT JOIN cosechas c ON c.siembra_id = s.siembra_id
WHERE s.estado = 'en produccion' AND c.cosecha_id IS NULL;
-- Resultado: 1 fila -> Agricola La Union, A-2, Cacao, siembra_id 7.
-- Que le diria al jefe de finca: esta siembra de cacao lleva marcada
-- "en produccion" (o sea, ya deberia estar dando cosecha) pero nunca se
-- registro ninguna. O el estado esta mal actualizado (todavia no
-- produce de verdad) o hubo cosechas que nadie cargo en el sistema; en
-- cualquiera de los dos casos, hay que ir a revisar el lote A-2 en
-- persona antes de reportar un rendimiento de 0 que capaz no es real.


-- =====================================================================
-- PARTE D - LAS PREGUNTAS DEL JEFE
-- =====================================================================

-- D1. Rendimiento en kg/ha por lote cosechado

-- Primer intento (a proposito, para ver el error): dividir cada fila de
-- cosecha directamente, sin sumar antes las cosechas de una misma
-- siembra:
SELECT f.nombre AS finca, l.codigo AS lote, l.hectareas, c.cosecha_id, c.kg,
       ROUND(c.kg / l.hectareas, 2) AS rendimiento_de_esa_fila
FROM lotes l
JOIN fincas f   ON f.finca_id = l.finca_id
JOIN siembras s ON s.lote_id = l.lote_id
JOIN cosechas c ON c.siembra_id = s.siembra_id
ORDER BY f.nombre, l.codigo, c.fecha;
-- Da 9 filas, no 6: los 3 lotes con UNA sola cosecha (El Guayabo L-02,
-- Santa Rosa L-02, Santa Rosa L-03) salen bien de pura casualidad,
-- porque su unica fila YA ES el total. Los 3 lotes con DOS cosechas
-- (Santa Rosa L-01, El Guayabo L-01, Agricola A-1) salen mal: cada fila
-- muestra solo una FRACCION del rendimiento real (por ejemplo, Santa
-- Rosa L-01 aparece como 147.37 y como 108.77, ninguna de las dos es el
-- 256.14 real), porque nunca se sumaron los kilos de esa siembra antes
-- de dividir.

-- Version correcta: sumar los kilos por siembra en una CTE, y recien
-- despues juntar con el lote para dividir
WITH kilos_siembra AS (
    SELECT siembra_id, SUM(kg) AS kilos
    FROM cosechas
    GROUP BY siembra_id
)
SELECT f.nombre AS finca, l.codigo AS lote, l.hectareas,
       SUM(ks.kilos) AS kilos,
       ROUND(SUM(ks.kilos) / l.hectareas, 2) AS rendimiento
FROM lotes l
JOIN fincas f   ON f.finca_id = l.finca_id
JOIN siembras s ON s.lote_id = l.lote_id
JOIN kilos_siembra ks ON ks.siembra_id = s.siembra_id
GROUP BY l.lote_id
ORDER BY rendimiento DESC;
-- Resultado: 6 filas. Top 3: El Guayabo L-02 -> 529.73,
-- Santa Rosa L-01 -> 256.14, El Guayabo L-01 -> 202.27 -- coincide exacto


-- D2. Costo total por finca, separado en mano de obra e insumos
WITH mano_obra AS (
    SELECT s.lote_id, SUM(lb.costo_mano_obra) AS total_mano_obra
    FROM labores lb
    JOIN siembras s ON s.siembra_id = lb.siembra_id
    GROUP BY s.lote_id
),
insumos_costo AS (
    SELECT s.lote_id, SUM(li.cantidad * li.costo_unitario) AS total_insumos
    FROM labor_insumo li
    JOIN labores lb ON lb.labor_id = li.labor_id
    JOIN siembras s ON s.siembra_id = lb.siembra_id
    GROUP BY s.lote_id
)
SELECT
    f.nombre AS finca,
    ROUND(SUM(COALESCE(mo.total_mano_obra,0)), 2) AS mano_obra,
    ROUND(SUM(COALESCE(ic.total_insumos,0)), 2)   AS insumos,
    ROUND(SUM(COALESCE(mo.total_mano_obra,0)) + SUM(COALESCE(ic.total_insumos,0)), 2) AS total
FROM lotes l
JOIN fincas f ON f.finca_id = l.finca_id
LEFT JOIN mano_obra mo     ON mo.lote_id = l.lote_id
LEFT JOIN insumos_costo ic ON ic.lote_id = l.lote_id
GROUP BY f.nombre;
-- Resultado: Santa Rosa 1441.00, El Guayabo 1024.50, La Union 1096.80.
-- Total general: 1441.00 + 1024.50 + 1096.80 = 3562.30 -- coincide exacto.
-- Igual que en B5: mano de obra e insumos se agregan cada uno en su
-- propia CTE, sin juntarlos en un solo JOIN, para que un insumo extra en
-- una labor no infle su propio costo de mano de obra.


-- D3. Dos rankings

-- a) Responsables por cantidad de labores
SELECT responsable, COUNT(*) AS num_labores
FROM labores
WHERE responsable IS NOT NULL
GROUP BY responsable
ORDER BY num_labores DESC;
-- Resultado: Pedro Loor arriba, con 5

-- b) Insumos por costo total consumido
SELECT i.nombre, ROUND(SUM(li.cantidad * li.costo_unitario), 2) AS costo_total
FROM labor_insumo li
JOIN insumos i ON i.insumo_id = li.insumo_id
GROUP BY i.nombre
ORDER BY costo_total DESC;
-- Resultado: Urea 46% arriba, con 427.00


-- =====================================================================
-- EXTRA (+5): pregunta de negocio propia, con 6 tablas
-- =====================================================================

-- Pregunta: cual es el costo por kilo cosechado en cada finca (mano de
-- obra + insumos, dividido entre los kilos que realmente se cosecharon)?
-- Le sirve al jefe para ver que finca es mas cara de producir por kilo,
-- no solo cual gasto mas en total.
WITH kilos_finca AS (
    SELECT f.finca_id, SUM(c.kg) AS kilos
    FROM fincas f
    JOIN lotes l    ON l.finca_id = f.finca_id
    JOIN siembras s ON s.lote_id = l.lote_id
    JOIN cosechas c ON c.siembra_id = s.siembra_id
    GROUP BY f.finca_id
),
mano_obra_finca AS (
    SELECT f.finca_id, SUM(lb.costo_mano_obra) AS mano_obra
    FROM fincas f
    JOIN lotes l    ON l.finca_id = f.finca_id
    JOIN siembras s ON s.lote_id = l.lote_id
    JOIN labores lb ON lb.siembra_id = s.siembra_id
    GROUP BY f.finca_id
),
insumos_finca AS (
    SELECT f.finca_id, SUM(li.cantidad * li.costo_unitario) AS insumos
    FROM fincas f
    JOIN lotes l    ON l.finca_id = f.finca_id
    JOIN siembras s ON s.lote_id = l.lote_id
    JOIN labores lb ON lb.siembra_id = s.siembra_id
    JOIN labor_insumo li ON li.labor_id = lb.labor_id
    GROUP BY f.finca_id
)
SELECT
    f.nombre AS finca,
    kf.kilos,
    ROUND(COALESCE(mo.mano_obra,0) + COALESCE(ins.insumos,0), 2) AS costo_total,
    ROUND((COALESCE(mo.mano_obra,0) + COALESCE(ins.insumos,0)) / kf.kilos, 4) AS costo_por_kg
FROM fincas f
JOIN kilos_finca kf        ON kf.finca_id = f.finca_id
LEFT JOIN mano_obra_finca mo ON mo.finca_id = f.finca_id
LEFT JOIN insumos_finca ins  ON ins.finca_id = f.finca_id
ORDER BY costo_por_kg ASC;
-- Resultado: El Guayabo es la mas barata por kilo (0.0719), Agricola La
-- Union la mas cara por lejos (0.5223) -- coherente con que es la finca
-- que menos kilos cosecho mientras seguia gastando en insumos y jornales.


-- =====================================================================
-- PARTE E - CIERRE
-- =====================================================================

-- 1) De las tres formas de equivocarse (SUM inflado, JOIN que borra
--    filas, division entera), cual es la mas peligrosa en un reporte que
--    ve un gerente?
--    El SUM inflado (el fan-out de la Parte B) es el mas peligroso,
--    porque es el unico de los tres que da un numero MAS GRANDE de lo
--    real y ademas plausible: 41100 kg en vez de 14200 no salta a la
--    vista como un error, un gerente lo puede leer y pensar que la finca
--    va excelente. El JOIN que borra filas al menos reduce el numero
--    (mas facil de sospechar si uno esperaba algo mas alto), y la
--    division entera (truncar en vez de redondear) es un error chico,
--    de centavos. El fan-out puede inflar una decision de inversion o
--    una meta de venta basada en un numero que parece razonable pero es
--    varias veces mas grande que la realidad.

-- 2) Nombre tecnico de cada arreglo de la clase 3:
--    - separar insumo_1, insumo_2, insumo_3 en filas de labor_insumo:
--      Primera Forma Normal (1FN) -- eliminar grupos repetidos de
--      columnas (insumo_1/2/3...) y reemplazarlos por filas.
--    - sacar unidad a la tabla insumos: Segunda Forma Normal (2FN) --
--      unidad dependia solo de que insumo era (de PARTE de una clave
--      compuesta, en labor_insumo), no de la combinacion completa
--      labor+insumo, asi que se mueve a la tabla que tiene esa clave
--      simple.
--    - sacar provincia a la tabla fincas: Tercera Forma Normal (3FN) --
--      provincia no dependia directamente de la fila (de la labor o el
--      registro plano), dependia de otra columna no clave (la finca), o
--      sea una dependencia transitiva.

-- 3) Una pregunta de negocio que AgroDB todavia no puede responder:
--    "Cuanto invertimos en sensores y que retorno dio esa inversion en
--    rendimiento?" No se puede responder porque sensores solo registra
--    que el sensor existe (tipo, modelo, activo), sin costo de compra ni
--    lecturas historicas de temperatura/humedad. Haria falta una columna
--    costo_adquisicion en sensores, y una tabla lecturas_sensor (FK ->
--    sensores) con fecha_hora y valor, para poder cruzar esas lecturas
--    contra las cosechas y ver si los lotes con sensores rinden mas.

-- =====================================================================
-- FIN DEL EJERCICIO
-- =====================================================================
