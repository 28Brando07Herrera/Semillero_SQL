-- =====================================================================
-- CURSO DE SQL  |  PROYECTO 1  |  Construye tu propia base de datos
-- Motor: SQLite   |   Entorno: sqliteonline.com
-- =====================================================================

-- Nombre: Daniel Troya
-- Tema elegido: D - Banco de semillas
-- La situacion en una frase: Registro de accesiones, camaras de frio, lotes ingresados y pruebas de viabilidad de germinacion.
-- Fecha: 2026-08-09

PRAGMA foreign_keys = ON;


-- =====================================================================
-- BLOQUE 1 - BORRADO DE TABLAS
-- Orden INVERSO al de creacion: primero las que dependen de otras.
-- =====================================================================
DROP TABLE IF EXISTS pruebas_viabilidad;
DROP TABLE IF EXISTS lotes_semilla;
DROP TABLE IF EXISTS bancos_conservacion;
DROP TABLE IF EXISTS accesiones;
DROP TABLE IF EXISTS categorias_semilla;


-- =====================================================================
-- BLOQUE 2 - CREACION DE LAS 5 TABLAS
-- =====================================================================

-- 2.1 CATEGORIAS: agrupa las clases de conservacion de semillas
CREATE TABLE categorias_semilla (
    categoria_id   INTEGER PRIMARY KEY,
    nombre_tipo    TEXT NOT NULL UNIQUE,
    descripcion    TEXT
);

-- 2.2 CATALOGO: las accesiones o especies conservadas (FK -> categorias)
CREATE TABLE accesiones (
    accesion_id    INTEGER PRIMARY KEY,
    codigo_banco   TEXT NOT NULL UNIQUE,
    nombre_comun   TEXT NOT NULL,
    nombre_cientifico TEXT,                                  -- admite NULL si no esta clasificado
    categoria_id   INTEGER NOT NULL REFERENCES categorias_semilla(categoria_id),
    humedad_optima NUMERIC(5,2) NOT NULL DEFAULT 5.00 CHECK (humedad_optima > 0)
);

-- 2.3 LUGARES: camaras frias o modulos de conservacion
CREATE TABLE bancos_conservacion (
    banco_id       INTEGER PRIMARY KEY,
    nombre_camara  TEXT NOT NULL,
    temperatura_c  NUMERIC(4,1) NOT NULL,
    ubicacion      TEXT                                      -- admite NULL si esta en transito/mantenimiento
);

-- 2.4 EVENTOS: lotes de semillas recolectados e ingresados (FK -> bancos_conservacion)
CREATE TABLE lotes_semilla (
    lote_id        INTEGER PRIMARY KEY,
    codigo_lote    TEXT NOT NULL UNIQUE,
    banco_id       INTEGER NOT NULL REFERENCES bancos_conservacion(banco_id),
    fecha_ingreso  DATE NOT NULL,
    peso_gramos    NUMERIC(10,2) NOT NULL CHECK (peso_gramos > 0),
    origen_region  TEXT NOT NULL                             -- columna categorica
);

-- 2.5 DETALLE: pruebas de viabilidad realizadas a los lotes (FK -> lotes_semilla, FK -> accesiones)
CREATE TABLE pruebas_viabilidad (
    prueba_id          INTEGER PRIMARY KEY,
    lote_id            INTEGER NOT NULL REFERENCES lotes_semilla(lote_id),
    accesion_id        INTEGER NOT NULL REFERENCES accesiones(accesion_id),
    fecha_prueba       DATE NOT NULL,
    semillas_evaluadas INTEGER NOT NULL CHECK (semillas_evaluadas > 0),
    pct_germinacion    NUMERIC(5,2) NOT NULL CHECK (pct_germinacion >= 0 AND pct_germinacion <= 100),
    resultado_estado   TEXT NOT NULL                         -- columna categorica: 'Excelente', 'Aceptable', 'Critico'
);


-- =====================================================================
-- BLOQUE 2b - PUNTO DE CONTROL 1
-- =====================================================================

-- Se crearon las cinco tablas?
SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name;

-- Todas tienen clave primaria?
SELECT m.name AS tabla,
       SUM(p.pk)  AS tiene_pk,
       COUNT(*)   AS columnas
FROM sqlite_master m
JOIN pragma_table_info(m.name) p
WHERE m.type = 'table'
GROUP BY m.name
ORDER BY tiene_pk;

-- Mapa de claves foraneas
SELECT m.name AS tabla,
       f."from"  AS columna,
       f."table" AS apunta_a
FROM sqlite_master m
JOIN pragma_foreign_key_list(m.name) f
WHERE m.type = 'table'
ORDER BY m.name;


-- =====================================================================
-- BLOQUE 3 - CARGA DE DATOS
-- =====================================================================

-- 3.1 Categorias (4 registros)
INSERT INTO categorias_semilla (categoria_id, nombre_tipo, descripcion) VALUES
  (1, 'Ortodoxa', 'Soportan desecacion y bajas temperaturas (-20C)'),
  (2, 'Recalcitrante', 'Sensibles a la desecacion, requieren conservacion in vitro'),
  (3, 'Intermedia', 'Tolerancia moderada al frio y desecacion'),
  (4, 'Especial Silvestre', 'Especies nativas en peligro de extincion');

-- 3.2 Catalogo: Accesiones (6 registros, 1 con NULL y 1 fila huerfana: ID 6)
INSERT INTO accesiones (accesion_id, codigo_banco, nombre_comun, nombre_cientifico, categoria_id, humedad_optima) VALUES
  (1, 'ACC-001', 'Maiz Criollo Amarillo', 'Zea mays', 1, 6.50),
  (2, 'ACC-002', 'Frijol Capanema', 'Phaseolus vulgaris', 1, 7.00),
  (3, 'ACC-003', 'Cacao Nacional Fino', 'Theobroma cacao', 2, 12.00),
  (4, 'ACC-004', 'Cafe Arábica Nativo', 'Coffea arabica', 3, 9.50),
  (5, 'ACC-005', 'Naranjilla Silvestre', NULL, 4, 8.00),                       -- NULL intencional
  (6, 'ACC-006', 'Quinoa Silvestre Altitudinal', 'Chenopodium quinoa', 1, 6.00); -- FILA HUERFANA (nunca evaluada)

-- 3.3 Lugares: Bancos de conservacion (4 registros, 1 con NULL)
INSERT INTO bancos_conservacion (banco_id, nombre_camara, temperatura_c, ubicacion) VALUES
  (1, 'Camara Criogenica -20C', -20.0, 'Modulo Norte A-1'),
  (2, 'Camara Refrigerada 4C', 4.0, 'Modulo Sur B-3'),
  (3, 'Silo de Secado Secundario', 15.5, 'Bodega Central'),
  (4, 'Camara Temporal de Mantenimiento', 10.0, NULL);                          -- NULL intencional

-- 3.4 Eventos: Lotes de semilla (10 registros)
INSERT INTO lotes_semilla (lote_id, codigo_lote, banco_id, fecha_ingreso, peso_gramos, origen_region) VALUES
  (1, 'LOT-2025-01', 1, '2025-01-15', 1500.50, 'Sierra'),
  (2, 'LOT-2025-02', 1, '2025-02-10', 2300.00, 'Sierra'),
  (3, 'LOT-2025-03', 2, '2025-03-05', 850.00, 'Costa'),
  (4, 'LOT-2025-04', 3, '2025-04-12', 4500.00, 'Amazonia'),
  (5, 'LOT-2025-05', 1, '2025-05-20', 1200.00, 'Sierra'),
  (6, 'LOT-2025-06', 2, '2025-06-18', 3100.75, 'Costa'),
  (7, 'LOT-2025-07', 4, '2025-07-02', 950.00, 'Costa'),
  (8, 'LOT-2025-08', 3, '2025-08-14', 1800.00, 'Amazonia'),
  (9, 'LOT-2025-09', 1, '2025-09-09', 2750.25, 'Sierra'),
  (10, 'LOT-2025-10', 2, '2025-10-30', 5000.00, 'Costa');

-- 3.5 Detalle: Pruebas de viabilidad (10 registros, vinculados a accesiones 1-5, dejando libre la 6)
INSERT INTO pruebas_viabilidad (prueba_id, lote_id, accesion_id, fecha_prueba, semillas_evaluadas, pct_germinacion, resultado_estado) VALUES
  (1, 1, 1, '2025-02-01', 100, 95.00, 'Excelente'),
  (2, 2, 2, '2025-02-28', 100, 88.50, 'Excelente'),
  (3, 3, 3, '2025-03-20', 50,  62.00, 'Critico'),
  (4, 4, 4, '2025-05-01', 100, 78.00, 'Aceptable'),
  (5, 5, 1, '2025-06-10', 100, 92.00, 'Excelente'),
  (6, 6, 3, '2025-07-01', 50,  55.00, 'Critico'),
  (7, 7, 5, '2025-07-25', 80,  81.00, 'Aceptable'),
  (8, 8, 4, '2025-09-02', 100, 84.00, 'Aceptable'),
  (9, 9, 2, '2025-10-05', 100, 90.00, 'Excelente'),
  (10, 10, 1, '2025-11-12', 100, 96.50, 'Excelente');


-- =====================================================================
-- BLOQUE 3b - PUNTO DE CONTROL 2
-- =====================================================================

-- Hay claves foraneas rotas?
PRAGMA foreign_key_check;

-- Existe la fila huerfana en catalogo?
SELECT c.nombre_comun AS accesion_huerfana
FROM accesiones c
LEFT JOIN pruebas_viabilidad p ON p.accesion_id = c.accesion_id
WHERE p.prueba_id IS NULL;

-- Guarde 'NULL' como texto?
SELECT COUNT(*) AS falsos FROM accesiones WHERE nombre_cientifico = 'NULL';

-- Fechas con formato correcto?
SELECT COUNT(*) AS mal_formato
FROM lotes_semilla
WHERE fecha_ingreso NOT LIKE '____-__-__';


-- =====================================================================
-- BLOQUE 4 - VERIFICACION DE CONTEOS
-- =====================================================================

SELECT 'categorias_semilla' AS tabla, COUNT(*) AS filas FROM categorias_semilla
UNION ALL SELECT 'accesiones',         COUNT(*) FROM accesiones
UNION ALL SELECT 'bancos_conservacion',COUNT(*) FROM bancos_conservacion
UNION ALL SELECT 'lotes_semilla',      COUNT(*) FROM lotes_semilla
UNION ALL SELECT 'pruebas_viabilidad', COUNT(*) FROM pruebas_viabilidad;


-- =====================================================================
-- BLOQUE 5 - LAS 10 CONSULTAS (+ 1 Opcional Extra)
-- =====================================================================

-- Consulta 1 (SELECT con columnas elegidas, ORDER BY y LIMIT)
-- Pregunta: ¿Cuáles son los 3 lotes de semillas con mayor peso almacenados en la base?
SELECT codigo_lote AS lote, origen_region AS region, peso_gramos AS peso
FROM lotes_semilla
ORDER BY peso_gramos DESC
LIMIT 3;

-- Consulta 2 (WHERE con dos condiciones combinadas: AND / OR)
-- Pregunta: ¿Qué lotes de semilla ingresaron durante el año 2025 procedentes de la región 'Sierra'?
SELECT codigo_lote, fecha_ingreso, origen_region
FROM lotes_semilla
WHERE fecha_ingreso >= '2025-01-01' AND origen_region = 'Sierra';

-- Consulta 3 (IS NULL y COALESCE)
-- Pregunta: ¿Cuáles accesiones registradas en el banco no tienen clasificado su nombre científico y qué texto podemos mostrar en su lugar?
SELECT codigo_banco, nombre_comun, COALESCE(nombre_cientifico, 'Sin Clasificar') AS estado_clasificacion
FROM accesiones
WHERE nombre_cientifico IS NULL;

-- Consulta 4 (COUNT, AVG, MIN o MAX con ROUND)
-- Pregunta: ¿Cuál es el promedio general de germinación de todas las pruebas realizadas, redondeado a dos decimales?
SELECT ROUND(AVG(pct_germinacion), 2) AS promedio_germinacion_pct,
       MIN(pct_germinacion) AS germinacion_minima,
       MAX(pct_germinacion) AS germinacion_maxima
FROM pruebas_viabilidad;

-- Consulta 5 (GROUP BY con HAVING)
-- Pregunta: ¿Cuáles accesiones de semillas han sido evaluadas en más de 1 prueba de viabilidad?
SELECT accesion_id, COUNT(*) AS numero_pruebas
FROM pruebas_viabilidad
GROUP BY accesion_id
HAVING COUNT(*) > 1;

-- Consulta 6 (JOIN de dos tablas)
-- Pregunta: ¿En qué cámara fría específica se encuentra guardado cada lote de semillas?
SELECT l.codigo_lote, b.nombre_camara, b.temperatura_c
FROM lotes_semilla l
JOIN bancos_conservacion b ON l.banco_id = b.banco_id;

-- Consulta 7 (LEFT JOIN que muestre un caso sin pareja)
-- Pregunta: ¿Existen accesiones de semillas registradas en el catálogo que nunca hayan sido sometidas a una prueba de viabilidad?
SELECT a.codigo_banco, a.nombre_comun
FROM accesiones a
LEFT JOIN pruebas_viabilidad p ON a.accesion_id = p.accesion_id
WHERE p.prueba_id IS NULL;

-- Consulta 8 (CASE para clasificar)
-- Pregunta: ¿Cómo se clasifican los lotes de semilla según su peso (Grande, Mediano, Pequeño)?
SELECT codigo_lote, peso_gramos,
       CASE 
           WHEN peso_gramos >= 3000 THEN 'Lote Grande'
           WHEN peso_gramos >= 1500 THEN 'Lote Mediano'
           ELSE 'Lote Pequeño'
       END AS categoria_peso
FROM lotes_semilla;

-- Consulta 9 (JOIN de tres tablas con GROUP BY)
-- Pregunta: ¿Cuál es el promedio de germinación alcanzado por cada accesión junto con el nombre de su categoría?
SELECT c.nombre_tipo AS categoria, a.nombre_comun AS accesion, ROUND(AVG(p.pct_germinacion), 2) AS promedio_germinacion
FROM pruebas_viabilidad p
JOIN accesiones a ON p.accesion_id = a.accesion_id
JOIN categorias_semilla c ON a.categoria_id = c.categoria_id
GROUP BY a.accesion_id, c.nombre_tipo;

-- Consulta 10 (Función de fecha: strftime o julianday)
-- Pregunta: ¿Cuántas pruebas de viabilidad se realizaron por cada mes del año?
SELECT strftime('%Y-%m', fecha_prueba) AS mes, COUNT(*) AS total_pruebas
FROM pruebas_viabilidad
GROUP BY mes
ORDER BY mes;

-- Consulta 11 - (Función de Ventana / RANK)
-- Pregunta: ¿Cuál es el ranking de porcentaje de germinación de cada prueba dentro de su respectiva accesión?
SELECT accesion_id, prueba_id, pct_germinacion,
       RANK() OVER (PARTITION BY accesion_id ORDER BY pct_germinacion DESC) AS ranking_viabilidad
FROM pruebas_viabilidad;

-- =====================================================================
-- BLOQUE 6 - MINI-INFORME DE CIERRE
-- =====================================================================
/*
1. ¿Qué decidieron que fuera tabla y qué decidieron que fuera columna, y por qué?
   Se decidió crear como tablas 'categorias_semilla', 'accesiones', 'bancos_conservacion', 
   'lotes_semilla' y 'pruebas_viabilidad' porque representan entidades con atributos propios y 
   relaciones de uno a muchos (ej. un banco alberga muchos lotes). Por otro lado, atributos como 
   'humedad_optima', 'temperatura_c' o 'peso_gramos' se definieron como columnas sencillas 
   porque son métricas directas pertenecientes a un único registro puntual y no requerían vida propia.

2. ¿Cuál fue la decisión de diseño de la que menos seguros están?
   La decisión de incluir 'accesion_id' directamente dentro de la tabla 'pruebas_viabilidad', 
   ya que técnicamente la prueba se le aplica a un lote y el lote ya podría saber qué accesión es. 
   Sin embargo, se decidió mantener de forma directa para simplificar el historial de viabilidad 
   por accesión sin depender exclusivamente de la cadena de lotes.

3. ¿Qué consulta les costó más y por qué?
   La Consulta 9 (JOIN de tres tablas con agregación) requirió especial cuidado en el GROUP BY 
   para asegurar que las agrupaciones no distorsionaran los promedios de germinación y que las 
   llaves primarias/foráneas enlazaran correctamente las jerarquías entre categoría, accesión y prueba.

4. ¿Encontraron algún dato que su modelo no puede responder? ¿Qué habría que cambiar para poder responderlo?
   El modelo actual no responde quién fue el técnico/investigador que realizó cada prueba de 
   viabilidad ni el método de escarificación usado. Para responderlo, habría que agregar una 
   tabla de 'investigadores' y una columna de 'metodologia' en 'pruebas_viabilidad'.

5. Si esta base la fuera a usar una finca o banco real mañana, ¿qué le falta?
   Le faltaría un módulo de movimientos de stock (egresos/préstamos de semillas a agricultores 
   o instituciones) y una tabla de ubicaciones detalladas (estante, repisa, frasco) dentro de 
   cada cámara fría, además de un historial de calibración de temperatura para las cámaras.
*/

-- =====================================================================
-- FIN DEL PROYECTO
-- =====================================================================