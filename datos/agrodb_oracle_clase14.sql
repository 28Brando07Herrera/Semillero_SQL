-- =====================================================================
-- CURSO DE SQL  |  CLASE 14  |  AgroDB sobre ORACLE
-- Motor: Oracle AI Database 26ai Free (23.26) o Oracle 23ai. Da igual.
--
-- DONDE SE CORRE: en TU Oracle local, el que instalaste en la clase 13.
--
--   sqlplus agro/Agro2026@localhost:1521/FREEPDB1
--   SQL> SET SERVEROUTPUT ON
--   SQL> SET LINESIZE 200 PAGESIZE 100
--   SQL> @C:\agrodb\agrodb_oracle_clase14.sql
--
-- Si la ruta donde lo guardaste tiene espacios, va entre comillas:
--   SQL> @"C:\Users\Tu Nombre\Descargas\agrodb_oracle_clase14.sql"
--
-- Lo mas facil es no pelearse con eso: copia el archivo a C:\agrodb\.
--
-- =====================================================================
-- QUE ES ESTE ARCHIVO
-- =====================================================================
--
--   Es AgroDB otra vez, limpia, con los mismos datos de siempre.
--   Los DOCE numeros de control son los de la clase 11:
--
--     3, 6, 8, 10, 7, 19, 16, 6, 9, 8640, 0, 0
--
--   Lo que NO trae, y no es descuido:
--
--   1. NO trae staging_lecturas ni err_lecturas ni seq_lecturas.
--      Eso fue el tema de la clase 12 y hoy no se usa.
--
--   2. NO trae la vista v_bi_produccion.
--      Esa vista fue TU respuesta al ejercicio 13. El script de cada
--      dia se escribe para no traer resuelto el ejercicio del dia
--      anterior. La vas a volver a escribir hoy, en la parte A, y
--      esta vez la vas a mirar con otros ojos.
--
--   3. NO trae ninguna tabla que empiece con dim_ ni con h_.
--      Esas son el ejercicio de hoy. Si ya existen de una corrida
--      anterior, la limpieza de abajo las borra.
--
-- =====================================================================
-- LA PREGUNTA DEL DIA
-- =====================================================================
--
--   Ayer el tablero dio 30550 y estuvo bien.
--   Hoy vas a construir el mismo tablero mejor hecho,
--   y te va a dar 19750 sin decirte una sola palabra.
--
-- =====================================================================


-- ---------------------------------------------------------------------
-- LIMPIEZA
--
-- Oracle no tiene DROP TABLE IF EXISTS: se le pregunta al catalogo.
-- Hoy se barre mas que otros dias porque hay que borrar dos cosas que
-- no vinieron de ningun script sino de TU trabajo: la vista del
-- ejercicio 13 y las tablas del ejercicio de hoy, si ya las hiciste.
-- ---------------------------------------------------------------------
BEGIN
  FOR v IN (SELECT view_name
              FROM user_views
             WHERE view_name IN ('V_BI_PRODUCCION','V_BI_ESTRELLA'))
  LOOP
    EXECUTE IMMEDIATE 'DROP VIEW ' || v.view_name;
  END LOOP;

  FOR t IN (SELECT table_name
              FROM user_tables
             WHERE table_name IN ('H_COSECHA','DIM_TIEMPO','DIM_CULTIVO',
                                  'DIM_FINCA','ERR_LECTURAS',
                                  'STAGING_LECTURAS','BITACORA',
                                  'RESUMEN_DIARIO','LECTURAS','COSECHAS',
                                  'LABOR_INSUMO','LABORES','INSUMOS',
                                  'SENSORES','SIEMBRAS','LOTES','CULTIVOS',
                                  'FINCAS'))
  LOOP
    EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS';
  END LOOP;

  FOR s IN (SELECT sequence_name
              FROM user_sequences
             WHERE sequence_name = 'SEQ_LECTURAS')
  LOOP
    EXECUTE IMMEDIATE 'DROP SEQUENCE ' || s.sequence_name;
  END LOOP;
END;
/


-- =====================================================================
-- MODELO OPERATIVO
--
-- Estas doce tablas son el sistema que registra lo que pasa en el
-- campo: una fila por cada cosa que ocurrio. Estan normalizadas, y
-- estan bien asi. NO son el problema de hoy.
--
-- El problema de hoy es que preguntarle a este modelo "cuantos kilos
-- por finca y por mes" cuesta un JOIN de cinco tablas, y hay que
-- escribirlo cada vez.
-- =====================================================================

CREATE TABLE fincas (
  finca_id       NUMBER        PRIMARY KEY,
  nombre         VARCHAR2(60)  NOT NULL UNIQUE,
  provincia      VARCHAR2(40)  NOT NULL,
  hectareas      NUMBER(10,2)  NOT NULL,
  fecha_registro DATE          NOT NULL,
  responsable    VARCHAR2(60),
  CONSTRAINT ck_fincas_ha CHECK (hectareas > 0)
);

CREATE TABLE cultivos (
  cultivo_id NUMBER       PRIMARY KEY,
  nombre     VARCHAR2(40) NOT NULL,
  variedad   VARCHAR2(40),
  ciclo_dias NUMBER       NOT NULL,
  tipo       VARCHAR2(20) NOT NULL,
  CONSTRAINT ck_cultivos_ciclo CHECK (ciclo_dias > 0)
);

CREATE TABLE lotes (
  lote_id    NUMBER       PRIMARY KEY,
  finca_id   NUMBER       NOT NULL REFERENCES fincas(finca_id),
  codigo     VARCHAR2(20) NOT NULL,
  hectareas  NUMBER(10,2) NOT NULL,
  tipo_suelo VARCHAR2(40),
  CONSTRAINT uq_lotes UNIQUE (finca_id, codigo),
  CONSTRAINT ck_lotes_ha CHECK (hectareas > 0)
);

CREATE TABLE siembras (
  siembra_id       NUMBER       PRIMARY KEY,
  lote_id          NUMBER       NOT NULL REFERENCES lotes(lote_id),
  cultivo_id       NUMBER       NOT NULL REFERENCES cultivos(cultivo_id),
  fecha_siembra    DATE         NOT NULL,
  densidad_plantas NUMBER       NOT NULL,
  estado           VARCHAR2(20) DEFAULT 'en curso' NOT NULL,
  CONSTRAINT ck_siembras_dens CHECK (densidad_plantas > 0)
);

CREATE TABLE insumos (
  insumo_id             NUMBER       PRIMARY KEY,
  nombre                VARCHAR2(60) NOT NULL UNIQUE,
  tipo                  VARCHAR2(30) NOT NULL,
  unidad                VARCHAR2(10) NOT NULL,
  costo_unit_referencia NUMBER(10,2)
);

CREATE TABLE labores (
  labor_id        NUMBER        PRIMARY KEY,
  siembra_id      NUMBER        NOT NULL REFERENCES siembras(siembra_id),
  tipo_labor      VARCHAR2(40)  NOT NULL,
  fecha           DATE          NOT NULL,
  responsable     VARCHAR2(60),
  costo_mano_obra NUMBER(10,2)  DEFAULT 0 NOT NULL,
  observacion     VARCHAR2(200),
  CONSTRAINT ck_labores_costo CHECK (costo_mano_obra >= 0)
);

CREATE TABLE labor_insumo (
  labor_id       NUMBER       NOT NULL REFERENCES labores(labor_id) ON DELETE CASCADE,
  insumo_id      NUMBER       NOT NULL REFERENCES insumos(insumo_id),
  cantidad       NUMBER(10,2) NOT NULL,
  costo_unitario NUMBER(10,2) NOT NULL,
  CONSTRAINT pk_labor_insumo PRIMARY KEY (labor_id, insumo_id),
  CONSTRAINT ck_li_cantidad CHECK (cantidad > 0),
  CONSTRAINT ck_li_costo    CHECK (costo_unitario >= 0)
);

CREATE TABLE sensores (
  sensor_id         NUMBER       PRIMARY KEY,
  lote_id           NUMBER       NOT NULL REFERENCES lotes(lote_id),
  tipo              VARCHAR2(20) NOT NULL,
  modelo            VARCHAR2(40),
  fecha_instalacion DATE         NOT NULL,
  activo            NUMBER(1)    DEFAULT 1 NOT NULL,
  CONSTRAINT ck_sensores_activo CHECK (activo IN (0,1))
);

CREATE TABLE cosechas (
  cosecha_id NUMBER       PRIMARY KEY,
  siembra_id NUMBER       NOT NULL REFERENCES siembras(siembra_id) ON DELETE CASCADE,
  fecha      DATE         NOT NULL,
  kg         NUMBER(10,2) NOT NULL,
  calidad    VARCHAR2(20) DEFAULT 'primera' NOT NULL,
  destino    VARCHAR2(40),
  CONSTRAINT ck_cosechas_kg      CHECK (kg > 0),
  CONSTRAINT ck_cosechas_calidad CHECK (calidad IN ('primera','segunda','descarte'))
);

-- fecha_hora es DATE, y en Oracle un DATE TRAE LA HORA ADENTRO.
-- Guardalo en la cabeza: hoy vas a construir una dimension de tiempo
-- y esa hora escondida es exactamente donde se rompe.
CREATE TABLE lecturas (
  lectura_id NUMBER       PRIMARY KEY,
  sensor_id  NUMBER       NOT NULL REFERENCES sensores(sensor_id) ON DELETE CASCADE,
  fecha_hora DATE         NOT NULL,
  valor      NUMBER(10,2) NOT NULL,
  CONSTRAINT uq_lecturas UNIQUE (sensor_id, fecha_hora),
  CONSTRAINT ck_lecturas_valor CHECK (valor BETWEEN -50 AND 1500)
);

CREATE TABLE resumen_diario (
  sensor_id  NUMBER       NOT NULL,
  dia        DATE         NOT NULL,
  n_lecturas NUMBER       NOT NULL,
  valor_min  NUMBER(10,2) NOT NULL,
  valor_max  NUMBER(10,2) NOT NULL,
  valor_prom NUMBER(10,2) NOT NULL,
  CONSTRAINT pk_resumen_diario PRIMARY KEY (sensor_id, dia)
);

CREATE TABLE bitacora (
  bitacora_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  tabla       VARCHAR2(30)  NOT NULL,
  operacion   VARCHAR2(10)  NOT NULL,
  clave       VARCHAR2(60),
  detalle     VARCHAR2(400),
  usuario     VARCHAR2(60)  DEFAULT USER      NOT NULL,
  cuando      TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL
);


-- =====================================================================
-- DATOS
--
-- Oracle NO acepta INSERT INTO t VALUES (a),(b),(c). Esa sintaxis es de
-- SQLite, MySQL y PostgreSQL. Aqui va con INSERT ALL, que termina
-- obligatoriamente en un SELECT ... FROM dual.
-- =====================================================================

INSERT ALL
  INTO fincas VALUES (1,'Hacienda Santa Rosa','Los Rios',145.50,DATE '2024-03-12','Marta Ruiz')
  INTO fincas VALUES (2,'Finca El Guayabo','Guayas',62.00,DATE '2024-07-01','Luis Paez')
  INTO fincas VALUES (3,'Agricola La Union','Manabi',210.75,DATE '2025-01-20',NULL)
SELECT * FROM dual;

INSERT ALL
  INTO cultivos VALUES (1,'Mango','Tommy Atkins',1460,'perenne')
  INTO cultivos VALUES (2,'Guayaba','Taiwanesa',730,'perenne')
  INTO cultivos VALUES (3,'Cacao','CCN-51',1095,'perenne')
  INTO cultivos VALUES (4,'Banano','Cavendish',300,'perenne')
  INTO cultivos VALUES (5,'Maiz','INIAP-180',120,'ciclo corto')
  INTO cultivos VALUES (6,'Cafe',NULL,1095,'perenne')
SELECT * FROM dual;

-- El codigo de lote se repite entre fincas: 'L-01' existe en la finca 1
-- y en la 2. Por eso el UNIQUE es (finca_id, codigo).
INSERT ALL
  INTO lotes VALUES (1,1,'L-01',28.50,'franco arcilloso')
  INTO lotes VALUES (2,1,'L-02',31.00,'franco')
  INTO lotes VALUES (3,1,'L-03',19.25,NULL)
  INTO lotes VALUES (4,2,'L-01',22.00,'arenoso')
  INTO lotes VALUES (5,2,'L-02',18.50,'franco')
  INTO lotes VALUES (6,3,'A-1',55.00,'franco arcilloso')
  INTO lotes VALUES (7,3,'A-2',47.30,'arcilloso')
  INTO lotes VALUES (8,3,'B-1',34.00,NULL)
SELECT * FROM dual;

INSERT ALL
  INTO siembras VALUES (1,1,1,DATE '2025-02-10',2800,'en produccion')
  INTO siembras VALUES (2,2,1,DATE '2025-03-05',3100,'en produccion')
  INTO siembras VALUES (3,3,2,DATE '2025-06-18',1900,'en curso')
  INTO siembras VALUES (4,4,2,DATE '2025-05-22',2200,'en produccion')
  INTO siembras VALUES (5,5,5,DATE '2026-01-15',6500,'cosechado')
  INTO siembras VALUES (6,6,3,DATE '2024-11-08',4100,'en produccion')
  INTO siembras VALUES (7,7,3,DATE '2025-01-30',3950,'en produccion')
  INTO siembras VALUES (8,8,4,DATE '2025-09-14',5200,'en curso')
  INTO siembras VALUES (9,1,5,DATE '2026-02-02',7000,'perdido')
  INTO siembras VALUES (10,6,1,DATE '2025-04-19',2600,'en curso')
SELECT * FROM dual;

INSERT ALL
  INTO insumos VALUES (1,'Urea 46%','fertilizante','kg',0.68)
  INTO insumos VALUES (2,'Muriato de potasio','fertilizante','kg',0.74)
  INTO insumos VALUES (3,'Mancozeb','fungicida','kg',5.20)
  INTO insumos VALUES (4,'Abono organico','fertilizante','kg',0.22)
  INTO insumos VALUES (5,'Aceite agricola','coadyuvante','L',3.90)
  INTO insumos VALUES (6,'Semilla INIAP-180','semilla','kg',2.10)
  INTO insumos VALUES (7,'Cal agricola','enmienda','kg',0.15)
SELECT * FROM dual;

-- 19 labores. Falta el labor_id 16 a proposito: es la copia duplicada
-- que se borro en el ejercicio 4, y no vuelve.
INSERT ALL
  INTO labores VALUES (1, 1,'fertilizacion',        DATE '2026-03-04','Marta Ruiz',120.00,NULL)
  INTO labores VALUES (2, 1,'control fitosanitario',DATE '2026-03-19','Marta Ruiz', 90.00,NULL)
  INTO labores VALUES (3, 2,'fertilizacion',        DATE '2026-03-06','Jorge Mina',135.00,NULL)
  INTO labores VALUES (4, 2,'riego',                DATE '2026-04-02','Jorge Mina', 45.00,'sin insumos')
  INTO labores VALUES (5, 3,'poda',                 DATE '2026-03-25','Ana Cedeno',210.00,'sin insumos')
  INTO labores VALUES (6, 4,'fertilizacion',        DATE '2026-03-11','Luis Paez', 110.00,NULL)
  INTO labores VALUES (7, 4,'control fitosanitario',DATE '2026-04-08','Luis Paez',  85.00,NULL)
  INTO labores VALUES (8, 5,'siembra',              DATE '2026-02-14','Luis Paez', 320.00,NULL)
  INTO labores VALUES (9, 5,'fertilizacion',        DATE '2026-03-02','Rosa Vera',  95.00,NULL)
  INTO labores VALUES (10,6,'fertilizacion',        DATE '2026-03-17','Pedro Loor',150.00,NULL)
  INTO labores VALUES (11,7,'control fitosanitario',DATE '2026-03-28','Pedro Loor', 88.00,NULL)
  INTO labores VALUES (12,8,'riego',                DATE '2026-04-05','Pedro Loor', 68.00,'sin insumos')
  INTO labores VALUES (13,1,'fertilizacion',        DATE '2026-04-10','Marta Ruiz',125.00,NULL)
  INTO labores VALUES (14,4,'riego',                DATE '2026-04-14','Luis Paez',  52.00,'sin insumos')
  INTO labores VALUES (15,6,'control fitosanitario',DATE '2026-04-16','Pedro Loor', 92.00,NULL)
  INTO labores VALUES (17,2,'poda',                 DATE '2026-04-15','Jorge Mina',180.00,'sin insumos')
  INTO labores VALUES (18,7,'riego',                DATE '2026-04-18',NULL,         60.00,'sin insumos')
  INTO labores VALUES (19,3,'cosecha',              DATE '2026-04-22','Ana Cedeno',145.00,'jornal corregido el 13/08')
  INTO labores VALUES (20,8,'fertilizacion',        DATE '2026-04-25','Pedro Loor',160.00,NULL)
SELECT * FROM dual;

-- 16 filas: la urea de la labor 20 sigue fusionada en una sola de 100 kg.
INSERT ALL
  INTO labor_insumo VALUES (1, 1,120,0.68)
  INTO labor_insumo VALUES (1, 2, 80,0.74)
  INTO labor_insumo VALUES (2, 3, 15,5.20)
  INTO labor_insumo VALUES (3, 1,140,0.68)
  INTO labor_insumo VALUES (6, 1, 90,0.68)
  INTO labor_insumo VALUES (6, 4,300,0.22)
  INTO labor_insumo VALUES (7, 3, 10,5.20)
  INTO labor_insumo VALUES (7, 5, 12,3.90)
  INTO labor_insumo VALUES (8, 6, 45,2.10)
  INTO labor_insumo VALUES (9, 1, 60,0.70)
  INTO labor_insumo VALUES (10,2,150,0.74)
  INTO labor_insumo VALUES (10,4,400,0.22)
  INTO labor_insumo VALUES (11,3, 22,5.20)
  INTO labor_insumo VALUES (13,1,110,0.70)
  INTO labor_insumo VALUES (15,3, 18,5.30)
  INTO labor_insumo VALUES (20,1,100,0.70)
SELECT * FROM dual;

-- Los sensores 3 y 5 siguen dados de baja. Siguen teniendo lecturas.
INSERT ALL
  INTO sensores VALUES (1,1,'temperatura','HYGROCLIP',  DATE '2026-01-15',1)
  INTO sensores VALUES (2,1,'humedad',    'HYGROCLIP',  DATE '2026-01-15',1)
  INTO sensores VALUES (3,2,'temperatura','HYGROCLIP',  DATE '2026-02-03',0)
  INTO sensores VALUES (4,4,'radiacion',  'PYRANOMETER',DATE '2026-02-20',1)
  INTO sensores VALUES (5,6,'temperatura','uMETOS BASE',DATE '2025-11-30',0)
  INTO sensores VALUES (6,6,'humedad',    'uMETOS BASE',DATE '2025-11-30',1)
SELECT * FROM dual;

-- LAS NUEVE COSECHAS. Miralas bien antes de seguir, porque son el
-- centro de la clase de hoy.
--
-- Mira las FECHAS: tres son de MARZO y seis son de ABRIL. Ese
-- reparto, que hoy parece un detalle sin importancia, es la clase
-- entera.
INSERT ALL
  INTO cosechas VALUES (1,1,DATE '2026-03-20',4200,'primera','mercado local')
  INTO cosechas VALUES (2,1,DATE '2026-04-18',3100,'segunda','agroindustria')
  INTO cosechas VALUES (3,2,DATE '2026-03-22',5400,'primera','exportacion')
  INTO cosechas VALUES (4,3,DATE '2026-04-22',1500,'primera','mercado local')
  INTO cosechas VALUES (5,4,DATE '2026-04-05',2600,'primera','mercado local')
  INTO cosechas VALUES (6,4,DATE '2026-04-26',1850,'segunda',NULL)
  INTO cosechas VALUES (7,5,DATE '2026-04-30',9800,'primera','agroindustria')
  INTO cosechas VALUES (8,6,DATE '2026-03-28',1200,'primera','exportacion')
  INTO cosechas VALUES (9,6,DATE '2026-04-22', 900,'primera','exportacion')
SELECT * FROM dual;


-- ---------------------------------------------------------------------
-- LAS LECTURAS: 8.640 FILAS SIN UN SOLO INSERT A MANO
--
-- CONNECT BY LEVEL <= 1440 fabrica 1.440 filas de la nada, numeradas
-- del 1 al 1440. Cruzadas contra los 6 sensores dan 8.640.
--
-- Guarda esta tecnica: hoy la vas a volver a usar, pero para fabricar
-- los 365 dias de 2026 en una tabla de calendario.
-- ---------------------------------------------------------------------
INSERT INTO lecturas (lectura_id, sensor_id, fecha_hora, valor)
SELECT ROWNUM,
       s.sensor_id,
       DATE '2026-04-01' + (t.n - 1) / 48,
       CASE s.tipo
         WHEN 'temperatura' THEN ROUND(18 + MOD(t.n, 21) * 0.5, 2)
         WHEN 'humedad'     THEN ROUND(55 + MOD(t.n, 41) * 0.5, 2)
         ELSE                    ROUND(100 + MOD(t.n, 801), 2)
       END
  FROM sensores s
 CROSS JOIN (SELECT LEVEL AS n FROM dual CONNECT BY LEVEL <= 1440) t;

COMMIT;


-- =====================================================================
-- LO QUE HOY NO VIENE HECHO, Y TE TOCA
--
-- Este script deja la base operativa cargada y NADA MAS. Falta:
--
--   1. La vista v_bi_produccion del ejercicio 13. Vuelve a escribirla:
--      es una vista plana con finca, lote, cultivo, estado de la
--      siembra, fecha, calidad y kg, saliendo de cosechas y subiendo
--      por siembras -> lotes -> fincas, mas cultivos.
--      Tiene que dar 9 filas y 30550 kilos.
--
--   2. El usuario bi_agro. Se crea desde system y el GRANT lo da agro,
--      que es el dueno. Si lo creaste en la clase 13 sigue existiendo:
--      los usuarios no se borran al recargar las tablas. Lo que SI se
--      perdio es el GRANT, porque se cayo junto con la vista.
--
--   3. Las tablas dim_finca, dim_cultivo, dim_tiempo y h_cosecha.
--      Eso es el ejercicio de hoy y no hay ni una linea de pista aqui.
--
-- =====================================================================


-- =====================================================================
-- VERIFICACION DE CARGA
--
-- Deben salir, en este orden:
--   3, 6, 8, 10, 7, 19, 16, 6, 9, 8640, 0, 0
--
-- Son los DOCE de la clase 11. Los nueve primeros vienen desde la
-- clase 5, el 8640 son las lecturas de abril, y los dos ceros son
-- resumen_diario y bitacora, que hoy no se usan.
-- =====================================================================
SELECT 'fincas' AS tabla, COUNT(*) AS filas FROM fincas
UNION ALL SELECT 'cultivos',       COUNT(*) FROM cultivos
UNION ALL SELECT 'lotes',          COUNT(*) FROM lotes
UNION ALL SELECT 'siembras',       COUNT(*) FROM siembras
UNION ALL SELECT 'insumos',        COUNT(*) FROM insumos
UNION ALL SELECT 'labores',        COUNT(*) FROM labores
UNION ALL SELECT 'labor_insumo',   COUNT(*) FROM labor_insumo
UNION ALL SELECT 'sensores',       COUNT(*) FROM sensores
UNION ALL SELECT 'cosechas',       COUNT(*) FROM cosechas
UNION ALL SELECT 'lecturas',       COUNT(*) FROM lecturas
UNION ALL SELECT 'resumen_diario', COUNT(*) FROM resumen_diario
UNION ALL SELECT 'bitacora',       COUNT(*) FROM bitacora;


-- =====================================================================
-- MIRA EL REPARTO DE LAS COSECHAS ANTES DE EMPEZAR
--
-- Esta consulta no valida nada. Solo muestra como caen los kilos en el
-- calendario. Correla y leela una vez, despacio.
--
-- Esperado:   2026-03   3 cosechas   10800 kilos
--             2026-04   6 cosechas   19750 kilos
-- =====================================================================
SELECT TO_CHAR(fecha,'YYYY-MM') AS mes,
       COUNT(*)                 AS cosechas,
       SUM(kg)                  AS kilos
  FROM cosechas
 GROUP BY TO_CHAR(fecha,'YYYY-MM')
 ORDER BY mes;


-- =====================================================================
-- LOS NUMEROS QUE YA SE SABEN DE MEMORIA
--
--   SUM(kg) de cosechas ............... 30550
--   costo total de las 10 siembras .... 3562.30
--   lecturas por sensor (abril) ....... 1440 cada uno
--   AVG por tipo (redondeado a 2) ..... temperatura 22.99
--                                       humedad     64.97
--                                       radiacion   464.50
--
--   por finca ......................... Finca El Guayabo    14250
--                                       Hacienda Santa Rosa 14200
--                                       Agricola La Union    2100
--
-- Y el que va a aparecer hoy, que NO es un numero bueno:
--
--   30550  ->  19750  cuando la dimension de tiempo no cubre marzo.
--
-- Si en algun momento del ejercicio te sale 19750, no lo tapes:
-- encontraste justo lo que la clase queria que encontraras.
-- =====================================================================
