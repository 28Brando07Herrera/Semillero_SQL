-- =====================================================================
-- CURSO DE SQL  |  CLASE 12  |  AgroDB sobre ORACLE
-- Motor: Oracle Database 23ai
--
-- DONDE SE CORRE: en el navegador, en FreeSQL. No hay que instalar nada.
-- Tambien corre con @agrodb_oracle_clase12.sql en SQLcl o SQL*Plus si
-- tenes Oracle local.
--
-- =====================================================================
-- COMO SE CORRE ESTO (es igual que ayer, y sigue siendo importante)
-- =====================================================================
--
--   1. Pega el archivo COMPLETO en el worksheet.
--   2. NO DEJES TEXTO SELECCIONADO: si hay seleccion, se ejecuta SOLO eso.
--      Hace clic en cualquier lado del editor para deseleccionar.
--   3. RUN SCRIPT (F5), no RUN STATEMENT (el triangulo, Ctrl+Enter).
--   4. Mira la pestaña "Script output": tiene que llenarse de
--      "Table ... created" y "1 row inserted".
--
--   EL ERROR TIPICO SIGUE SIENDO:
--
--     ORA-00942: table or view "FINCAS" does not exist
--
--   No es del script: es que las tablas nunca se crearon porque
--   corriste solo la verificacion del final. Deselecciona y Run Script.
--
-- =====================================================================
-- QUE CAMBIA RESPECTO DE AYER
-- =====================================================================
--
--   El modelo es el MISMO de la clase 11. Los datos son los mismos:
--   3, 6, 8, 10, 7, 19, 16, 6, 9 y 8.640 lecturas de abril.
--
--   resumen_diario y bitacora vuelven VACIAS. Este script NO trae
--   resuelto nada del ejercicio 11: no tiene el resumen cargado, no
--   tiene el procedimiento cargar_labor, no tiene el trigger de la
--   bitacora. Si ya los escribiste ayer, se pierden al recargar. Guarda
--   tu archivo del ejercicio 11 antes de correr esto.
--
--   LO NUEVO SON DOS COSAS:
--
--   1. staging_lecturas: 23 filas, TODO texto. Es un CSV que dejo el
--      bot del gateway de campo. Miren la tabla: no tiene ni una clave
--      foranea, ni un CHECK, ni un NOT NULL sobre el contenido.
--      Eso NO es un descuido. Es la definicion de un staging.
--
--   2. seq_lecturas: una secuencia que arranca en 8641, para poder
--      insertar lecturas nuevas sin inventar el lectura_id a mano.
--
-- =====================================================================
-- LA PREGUNTA DEL DIA
-- =====================================================================
--
--   Un proceso de carga no se juzga por la primera corrida.
--   Se juzga por la segunda.
--
-- =====================================================================


-- ---------------------------------------------------------------------
-- LIMPIEZA
--
-- Oracle no tiene DROP TABLE IF EXISTS: se le pregunta al catalogo.
-- Hoy hay que barrer tres cosas mas que ayer: la tabla de staging, la
-- tabla de rechazos que van a crear en la parte B, y la secuencia.
-- ---------------------------------------------------------------------
BEGIN
  FOR t IN (SELECT table_name
              FROM user_tables
             WHERE table_name IN ('ERR_LECTURAS','STAGING_LECTURAS',
                                  'BITACORA','RESUMEN_DIARIO','LECTURAS',
                                  'COSECHAS','LABOR_INSUMO','LABORES',
                                  'INSUMOS','SENSORES','SIEMBRAS',
                                  'LOTES','CULTIVOS','FINCAS'))
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
-- MODELO
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
-- No es como en SQLite, donde guardabamos texto '2026-04-01 00:30:00'.
-- Por eso hoy no hace falta pelear con comparaciones de cadenas: se
-- comparan fechas contra fechas. La trampa del ejercicio 9 cambia de
-- forma pero no desaparece — ver la parte C.
CREATE TABLE lecturas (
  lectura_id NUMBER       PRIMARY KEY,
  sensor_id  NUMBER       NOT NULL REFERENCES sensores(sensor_id) ON DELETE CASCADE,
  fecha_hora DATE         NOT NULL,
  valor      NUMBER(10,2) NOT NULL,
  CONSTRAINT uq_lecturas UNIQUE (sensor_id, fecha_hora),
  CONSTRAINT ck_lecturas_valor CHECK (valor BETWEEN -50 AND 1500)
);

-- Se llena hoy, dos veces, de dos maneras.
CREATE TABLE resumen_diario (
  sensor_id  NUMBER       NOT NULL,
  dia        DATE         NOT NULL,
  n_lecturas NUMBER       NOT NULL,
  valor_min  NUMBER(10,2) NOT NULL,
  valor_max  NUMBER(10,2) NOT NULL,
  valor_prom NUMBER(10,2) NOT NULL,
  CONSTRAINT pk_resumen_diario PRIMARY KEY (sensor_id, dia)
);

-- La bitacora de la clase 10. Miren la columna 'usuario': en SQLite no
-- la pudimos llenar porque el motor no sabe quien esta conectado.
-- Oracle si sabe.
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
-- SQLite, MySQL y PostgreSQL, no de Oracle. Acá va con INSERT ALL, que
-- termina obligatoriamente en un SELECT ... FROM dual.
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
-- que borraron en el ejercicio 4, y no vuelve.
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
--   (t.n - 1) / 48   ->  en Oracle, sumarle 1 a un DATE suma UN DIA.
--                        Sumarle 1/48 suma media hora. Asi que esto
--                        recorre abril de 2026 de 30 en 30 minutos.
--
-- El valor es deterministico a proposito: todos tienen que obtener
-- exactamente los mismos numeros de control.
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

-- ---------------------------------------------------------------------
-- LA SECUENCIA
--
-- Las 8.640 lecturas de abril se numeraron con ROWNUM. Para las que se
-- carguen hoy hace falta una fuente de ids que no dependa de contar la
-- tabla: si dos procesos hacen MAX(lectura_id)+1 al mismo tiempo, los
-- dos se llevan el mismo numero. Una secuencia no tiene ese problema.
--
-- Arranca en 8641 porque abril termina en 8640.
-- ---------------------------------------------------------------------
CREATE SEQUENCE seq_lecturas START WITH 8641 INCREMENT BY 1 NOCACHE;


-- ---------------------------------------------------------------------
-- EL STAGING
--
-- Todas las columnas son VARCHAR2. No hay NOT NULL sobre el contenido,
-- no hay CHECK, no hay clave foranea contra sensores. Parece una tabla
-- mal hecha y es exactamente al reves: es una tabla cuyo trabajo es
-- ACEPTAR TODO lo que venga en el archivo, incluida la basura, para
-- que se pueda mirar antes de decidir que hacer con ella.
--
-- Si el staging validara, la fila mala no llegaria nunca a la base y
-- no habria forma de saber que existio. Se perderia en silencio, que
-- es la unica cosa que este curso no perdona.
--
-- Lo unico que si tiene restriccion es de que ARCHIVO y de que LINEA
-- viene cada fila. Eso no es dato del sensor: es trazabilidad.
-- ---------------------------------------------------------------------
CREATE TABLE staging_lecturas (
  archivo    VARCHAR2(40) NOT NULL,
  linea      NUMBER       NOT NULL,
  sensor_id  VARCHAR2(20),
  fecha_hora VARCHAR2(30),
  valor      VARCHAR2(20),
  CONSTRAINT pk_staging_lecturas PRIMARY KEY (archivo, linea)
);

-- ---------------------------------------------------------------------
-- EL ARCHIVO DEL 1 DE MAYO, TAL CUAL LO DEJO EL BOT
--
-- 20 lineas. Doce estan bien. Ocho no, y NINGUNA de las ocho viene
-- marcada como mala: hay que descubrirlas.
--
-- No mires la lista de abajo buscando cuales son. Cargalas primero y
-- que te lo diga el motor. Esa es la parte B del ejercicio.
-- ---------------------------------------------------------------------
INSERT ALL
  INTO staging_lecturas VALUES ('lect_20260501.csv', 1,  '1',    '2026-05-01 00:00', '21.50')
  INTO staging_lecturas VALUES ('lect_20260501.csv', 2,  '1',    '2026-05-01 00:30', '21.00')
  INTO staging_lecturas VALUES ('lect_20260501.csv', 3,  '1',    '2026-05-01 01:00', '21,50')
  INTO staging_lecturas VALUES ('lect_20260501.csv', 4,  '1',    '2026-05-01 01:30', 'n/d')
  INTO staging_lecturas VALUES ('lect_20260501.csv', 5,  '1',    '2026-05-01 02:00', '-999')
  INTO staging_lecturas VALUES ('lect_20260501.csv', 6,  '1',    '2026-05-01 02:30', '')
  INTO staging_lecturas VALUES ('lect_20260501.csv', 7,  '2',    '2026-05-01 00:00', '68.00')
  INTO staging_lecturas VALUES ('lect_20260501.csv', 8,  '2',    '2026-05-01 00:30', '68.50')
  INTO staging_lecturas VALUES ('lect_20260501.csv', 9,  '2',    '2026-05-01 01:00', '69.00')
  INTO staging_lecturas VALUES ('lect_20260501.csv', 10, '2',    '2026-05-01 01:30', '69.50')
  INTO staging_lecturas VALUES ('lect_20260501.csv', 11, '  4 ', '2026-05-01 00:00', ' 512.00 ')
  INTO staging_lecturas VALUES ('lect_20260501.csv', 12, '4',    '2026-05-01 00:30', '515.00')
  INTO staging_lecturas VALUES ('lect_20260501.csv', 13, '4',    '2026-05-01 01:00', '518.00')
  INTO staging_lecturas VALUES ('lect_20260501.csv', 14, '99',   '2026-05-01 00:00', '30.00')
  INTO staging_lecturas VALUES ('lect_20260501.csv', 15, '6',    '2026-05-01 00:00', '71.00')
  INTO staging_lecturas VALUES ('lect_20260501.csv', 16, '6',    '2026-05-01 00:30', '71.50')
  INTO staging_lecturas VALUES ('lect_20260501.csv', 17, '6',    '2026-05-01 01:00', '72.00')
  INTO staging_lecturas VALUES ('lect_20260501.csv', 18, '6',    '2026-05-01 01:00', '72.00')
  INTO staging_lecturas VALUES ('lect_20260501.csv', 19, '1',    '2026-05-01 25:00', '23.00')
  INTO staging_lecturas VALUES ('lect_20260501.csv', 20, '1',    '2026-04-30 23:30', '20.00')
SELECT * FROM dual;

-- ---------------------------------------------------------------------
-- LA CORRECCION QUE MANDARON DESPUES
--
-- Tres lineas. Dos corrigen mediciones que el archivo original traia
-- ilegibles. La tercera corrige una que YA ENTRO bien y ahora dice otro
-- valor: el sensor se recalibro y el gateway reenvio el dato bueno.
--
-- Esa tercera es la que hace que "insertar lo que falta" no alcance.
-- Es la parte C.
-- ---------------------------------------------------------------------
INSERT ALL
  INTO staging_lecturas VALUES ('lect_20260501_rev2.csv', 1, '1', '2026-05-01 01:00', '21.50')
  INTO staging_lecturas VALUES ('lect_20260501_rev2.csv', 2, '1', '2026-05-01 01:30', '23.00')
  INTO staging_lecturas VALUES ('lect_20260501_rev2.csv', 3, '2', '2026-05-01 00:00', '68.20')
SELECT * FROM dual;

COMMIT;


-- =====================================================================
-- VERIFICACION DE CARGA
--
-- Deben salir, en este orden:
--   3, 6, 8, 10, 7, 19, 16, 6, 9, 8640, 0, 0, 23
--
-- Los nueve primeros son los de siempre, desde la clase 5.
-- El 8640 son las lecturas de abril.
-- Los dos ceros son resumen_diario y bitacora: hoy no se usan.
-- El 23 es el staging: 20 lineas del archivo + 3 de la correccion.
-- =====================================================================
SELECT 'fincas' AS tabla, COUNT(*) AS filas FROM fincas
UNION ALL SELECT 'cultivos',         COUNT(*) FROM cultivos
UNION ALL SELECT 'lotes',            COUNT(*) FROM lotes
UNION ALL SELECT 'siembras',         COUNT(*) FROM siembras
UNION ALL SELECT 'insumos',          COUNT(*) FROM insumos
UNION ALL SELECT 'labores',          COUNT(*) FROM labores
UNION ALL SELECT 'labor_insumo',     COUNT(*) FROM labor_insumo
UNION ALL SELECT 'sensores',         COUNT(*) FROM sensores
UNION ALL SELECT 'cosechas',         COUNT(*) FROM cosechas
UNION ALL SELECT 'lecturas',         COUNT(*) FROM lecturas
UNION ALL SELECT 'resumen_diario',   COUNT(*) FROM resumen_diario
UNION ALL SELECT 'bitacora',         COUNT(*) FROM bitacora
UNION ALL SELECT 'staging_lecturas', COUNT(*) FROM staging_lecturas;


-- =====================================================================
-- MIRA EL STAGING ANTES DE TOCARLO
--
-- Esta consulta no valida nada. Solo muestra el archivo como llego.
-- Corrella y leela una vez, despacio, antes de empezar el ejercicio.
-- =====================================================================
SELECT linea, sensor_id, fecha_hora, valor
  FROM staging_lecturas
 WHERE archivo = 'lect_20260501.csv'
 ORDER BY linea;

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
-- Y el que se mueve hoy:
--
--   lecturas ........... 8640  ->  8652 al final de la parte B
--                              ->  8654 al final de la parte C
--
-- Si al terminar la parte C no te da 8654, no sigas: algo entro dos
-- veces o no entro. Ese es todo el tema del dia.
-- =====================================================================

-- =====================================================================
-- EJERCICIO PRÁCTICO 12 · UN PROCESO DE CARGA SE JUZGA POR LA SEGUNDA CORRIDA
-- =====================================================================

SET SERVEROUTPUT ON;

-- =====================================================================
-- PARTE A · EL ARCHIVO, ANTES DE TOCARLO
-- =====================================================================

-- A1 — La predicción
SELECT linea, sensor_id, fecha_hora, valor
  FROM staging_lecturas
 WHERE archivo = 'lect_20260501.csv'
 ORDER BY linea;

/*
PREDICCIÓN INICIAL (A1):
- Línea 3: Fallará por formato numérico ('21,50' usa coma en lugar de punto decimal bajo NLS estándar).
- Línea 4: Fallará por valor no numérico ('n/d').
- Línea 5: Fallará por CHECK constraint de valor (-999 está fuera del rango [-50, 1500]).
- Línea 6: Fallará por valor nulo o vacío ('').
- Línea 14: Fallará por Foreign Key (sensor_id 99 no existe en la tabla sensores).
- Línea 18: Fallará por Unique Constraint (duplicado exacto de sensor 6 y fecha 2026-05-01 01:00 ya en línea 17).
- Línea 19: Fallará por formato de fecha/hora inválido (hora '25:00' fuera de rango 00-23).
- Línea 20: Fallará por Unique Constraint (la lectura de 2026-04-30 23:30 para sensor 1 ya existe en la carga histórica de abril).
Total estimadas a fallar: 8 líneas.
*/

-- A2 — Por qué el staging no valida nada
/*
A2:
Si staging_lecturas.sensor_id fuera NUMBER con REFERENCES sensores, al intentar cargar
el archivo CSV el INSERT inicial fallaría inmediatamente por ORA-02291, abortando la ingesta.
La línea 14 (sensor 99) y posiblemente el resto del lote no quedarían registradas en ningún lado
dentro de la base de datos, perdiéndose la trazabilidad y sin forma de auditar que el dato existió.
*/

-- A3 — Separar «no se entiende» de «no se acepta»
SELECT linea,
       CASE
         WHEN TO_NUMBER(TRIM(sensor_id) DEFAULT NULL ON CONVERSION ERROR) IS NULL
           THEN 'sensor ilegible'
         WHEN TO_DATE(TRIM(fecha_hora) DEFAULT NULL ON CONVERSION ERROR,
                      'YYYY-MM-DD HH24:MI') IS NULL
           THEN 'fecha ilegible'
         WHEN TO_NUMBER(TRIM(valor) DEFAULT NULL ON CONVERSION ERROR) IS NULL
           THEN 'valor ilegible'
         ELSE 'convierte'
       END AS diagnostico
  FROM staging_lecturas
 WHERE archivo = 'lect_20260501.csv'
 ORDER BY linea;

/*
A3:
Si escribiéramos TO_NUMBER(valor) a secas, la línea 4 lanzaría la excepción ORA-01722 (invalid number)
abortando la sentencia SQL entera. Como resultado, las 19 líneas restantes no se procesarían
ni evaluarían, deteniendo todo el lote por una sola celda corrupta.
*/

-- A4 — El TRIM
SELECT linea,
       CASE
         WHEN TO_NUMBER(sensor_id DEFAULT NULL ON CONVERSION ERROR) IS NULL
           THEN 'sensor ilegible'
         WHEN TO_DATE(fecha_hora DEFAULT NULL ON CONVERSION ERROR,
                      'YYYY-MM-DD HH24:MI') IS NULL
           THEN 'fecha ilegible'
         WHEN TO_NUMBER(valor DEFAULT NULL ON CONVERSION ERROR) IS NULL
           THEN 'valor ilegible'
         ELSE 'convierte'
       END AS diagnostico
  FROM staging_lecturas
 WHERE archivo = 'lect_20260501.csv'
 ORDER BY linea;

/*
A4:
El diagnóstico de la línea 11 no cambió: sigue saliendo 'convierte'. TO_NUMBER y TO_DATE en Oracle
toleran de forma predeterminada los espacios en blanco iniciales y finales en cadenas numéricas,
por lo que '  4 ' y ' 512.00 ' convierten a número sin arrojar error aun sin TRIM explícito.
*/

-- A5
/*
A5:
Esas cuatro líneas las rechazó el archivo: el contenido del texto era sintácticamente ilegible
e incapaz de representar tipos de datos válidos antes de interactuar con las reglas del modelo.
*/


-- =====================================================================
-- PARTE B · CARGAR SIN PERDER LOS ERRORES
-- =====================================================================

-- B1 — Dónde van a vivir los rechazos
BEGIN
  DBMS_ERRLOG.CREATE_ERROR_LOG(dml_table_name     => 'LECTURAS',
                               err_log_table_name => 'ERR_LECTURAS');
EXCEPTION
  WHEN OTHERS THEN
    NULL; -- Si ya existe, continúa
END;
/

SELECT column_name, data_type
  FROM user_tab_columns
 WHERE table_name = 'ERR_LECTURAS'
 ORDER BY column_id;

/*
B1:
La tabla de rechazos guarda todo como VARCHAR2(4000) para poder persistir el texto corrupto original
(como 'n/d' o '21,50') que provocó el fallo; si fuera de tipo NUMBER o DATE, la inserción del
mismo registro de error fallaría por incompatibilidad de tipos.
*/

-- B2 — La carga
INSERT INTO lecturas (lectura_id, sensor_id, fecha_hora, valor)
SELECT seq_lecturas.NEXTVAL,
       TO_NUMBER(TRIM(sensor_id) DEFAULT NULL ON CONVERSION ERROR),
       TO_DATE(TRIM(fecha_hora) DEFAULT NULL ON CONVERSION ERROR, 'YYYY-MM-DD HH24:MI'),
       TO_NUMBER(TRIM(valor)     DEFAULT NULL ON CONVERSION ERROR)
  FROM staging_lecturas
 WHERE archivo = 'lect_20260501.csv'
  LOG ERRORS INTO err_lecturas ('carga 1') REJECT LIMIT UNLIMITED;

COMMIT;

SELECT COUNT(*) AS lecturas    FROM lecturas;       -- esperado: 8652
SELECT COUNT(*) AS rechazadas  FROM err_lecturas;   -- esperado: 8

-- B3 — Leer los rechazos
SELECT ora_err_number$ AS ora, COUNT(*) AS filas
  FROM err_lecturas
 GROUP BY ora_err_number$
 ORDER BY filas DESC, ora;

SELECT ora_err_number$, ora_err_mesg$, sensor_id, fecha_hora, valor
  FROM err_lecturas
 ORDER BY ora_err_number$;

/*
B3:
| Código ORA | Significado                                      | Línea(s) causante(s) |
|------------|--------------------------------------------------|----------------------|
| ORA-01400  | Inserción de NULL en columna NOT NULL (valor/fec)| Líneas 3, 4, 6, 19   |
| ORA-00001  | Violación de restricción UNIQUE (uq_lecturas)    | Líneas 18, 20        |
| ORA-02290  | Violación de restricción CHECK (ck_lecturas_valor)| Línea 5              |
| ORA-02291  | Violación de Foreign Key (sensor inexistente)    | Línea 14             |

Nota NLS:
Si la sesión usa coma como separador decimal, la línea 3 ('21,50') convierte con éxito a número en vez de
devolver NULL, pasando el filtro NOT NULL pero fallando luego si estuviera fuera de rango o duplicada;
el mismo archivo se interpreta distinto según la configuración de NLS_NUMERIC_CHARACTERS del cliente.
*/

-- B4 — Reconciliar, que no es lo mismo que contar
SELECT s.linea, s.sensor_id, s.fecha_hora, s.valor
  FROM staging_lecturas s
 WHERE s.archivo = 'lect_20260501.csv'
   AND NOT EXISTS (
         SELECT 1
           FROM lecturas l
          WHERE l.sensor_id  = TO_NUMBER(TRIM(s.sensor_id) DEFAULT NULL ON CONVERSION ERROR)
            AND l.fecha_hora = TO_DATE(TRIM(s.fecha_hora) DEFAULT NULL ON CONVERSION ERROR,
                                       'YYYY-MM-DD HH24:MI'))
 ORDER BY s.linea;

/*
B4:
Faltan las líneas 18 y 20. Esta consulta no las ve porque en la tabla lecturas SÍ existen registros
para esas mismas duplas (sensor_id, fecha_hora) provenientes de la línea 17 y de la carga histórica de abril.
Si este NOT EXISTS fuera el único control, habríamos reportado solo 6 fallos en lugar de los 8 reales,
ocultando que 2 mediciones del archivo eran duplicados rechazados.
*/

-- B5 — La trampa del día
/*
B5:
LOG ERRORS convierte errores en no-errores a propósito y está bien siempre que exista un proceso
inmediato o alerta automatizada que inspeccione err_lecturas y bloquee o notifique ante discrepancias.
*/

-- B6
/*
B6:
Aciertos: 8 de 8 previstos en A1 coincidieron con los errores capturados por el motor
(Líneas 3, 4, 5, 6, 14, 18, 19, 20).
*/


-- =====================================================================
-- PARTE C · LA SEGUNDA CORRIDA
-- =====================================================================

-- C1 — El bot se colgó y lo volvieron a arrancar
INSERT INTO lecturas (lectura_id, sensor_id, fecha_hora, valor)
SELECT seq_lecturas.NEXTVAL,
       TO_NUMBER(TRIM(sensor_id) DEFAULT NULL ON CONVERSION ERROR),
       TO_DATE(TRIM(fecha_hora) DEFAULT NULL ON CONVERSION ERROR, 'YYYY-MM-DD HH24:MI'),
       TO_NUMBER(TRIM(valor)     DEFAULT NULL ON CONVERSION ERROR)
  FROM staging_lecturas
 WHERE archivo = 'lect_20260501.csv'
  LOG ERRORS INTO err_lecturas ('carga 2') REJECT LIMIT UNLIMITED;

COMMIT;

SELECT COUNT(*) AS lecturas   FROM lecturas;       -- esperado: 8652 (no se movió)
SELECT COUNT(*) AS rechazadas FROM err_lecturas;   -- esperado: 28

SELECT ora_err_tag$, ora_err_number$, COUNT(*)
  FROM err_lecturas
 GROUP BY ora_err_tag$, ora_err_number$
 ORDER BY 1, 3 DESC;

SELECT MAX(lectura_id) FROM lecturas;

/*
C1:
1. Lo impidió el modelo mediante la restricción uq_lecturas UNIQUE (sensor_id, fecha_hora).
2. De las 20 nuevas filas, 8 son errores intrínsecos de datos y 12 son 'esto ya estaba'; la tabla de rechazos
   ahora mezcla causas y ya no sirve para reportar directamente sin filtrar por tag o estado previo.
3. Los 12 nuevos duplicados corresponden a las 12 filas válidas que se insertaron exitosamente en la primera corrida.
4. El MAX(lectura_id) es mayor a 8652 porque la secuencia seq_lecturas consume e incrementa un valor por cada fila
   evaluada en el SELECT, independientemente de si la fila se insertó o fue rechazada/revertida.
*/

-- C2 — La corrección que llegó después
SELECT linea, sensor_id, fecha_hora, valor
  FROM staging_lecturas
 WHERE archivo = 'lect_20260501_rev2.csv'
 ORDER BY linea;

/*
C2:
- Línea 1 (01:00): Como no entró en la primera corrida, el INSERT la insertaría correctamente.
- Línea 2 (01:30): Como tampoco entró en la primera corrida, el INSERT la insertaría correctamente.
- Línea 3 (00:00, valor 68.20): Ya existe en lecturas con valor 68.00; el INSERT fallaría por ORA-00001 (o sería ignorado),
  dejando el valor desactualizado sin aplicar la corrección.
*/

-- C3 — MERGE
MERGE INTO lecturas l
USING (
  SELECT TO_NUMBER(TRIM(sensor_id) DEFAULT NULL ON CONVERSION ERROR)  AS sensor_id,
         TO_DATE(TRIM(fecha_hora) DEFAULT NULL ON CONVERSION ERROR,
                 'YYYY-MM-DD HH24:MI')                                AS fecha_hora,
         TO_NUMBER(TRIM(valor)     DEFAULT NULL ON CONVERSION ERROR)  AS valor
    FROM staging_lecturas
   WHERE archivo = 'lect_20260501_rev2.csv'
) s
ON (l.sensor_id = s.sensor_id AND l.fecha_hora = s.fecha_hora)
WHEN MATCHED THEN
  UPDATE SET l.valor = s.valor
WHEN NOT MATCHED THEN
  INSERT (lectura_id, sensor_id, fecha_hora, valor)
  VALUES (seq_lecturas.NEXTVAL, s.sensor_id, s.fecha_hora, s.valor);

COMMIT;

SELECT COUNT(*) FROM lecturas;                          -- esperado: 8654
SELECT valor FROM lecturas
 WHERE sensor_id = 2 AND fecha_hora = DATE '2026-05-01'; -- esperado: 68.2

-- C4 — La prueba de verdad (Idempotencia)
MERGE INTO lecturas l
USING (
  SELECT TO_NUMBER(TRIM(sensor_id) DEFAULT NULL ON CONVERSION ERROR)  AS sensor_id,
         TO_DATE(TRIM(fecha_hora) DEFAULT NULL ON CONVERSION ERROR,
                 'YYYY-MM-DD HH24:MI')                                AS fecha_hora,
         TO_NUMBER(TRIM(valor)     DEFAULT NULL ON CONVERSION ERROR)  AS valor
    FROM staging_lecturas
   WHERE archivo = 'lect_20260501_rev2.csv'
) s
ON (l.sensor_id = s.sensor_id AND l.fecha_hora = s.fecha_hora)
WHEN MATCHED THEN
  UPDATE SET l.valor = s.valor
WHEN NOT MATCHED THEN
  INSERT (lectura_id, sensor_id, fecha_hora, valor)
  VALUES (seq_lecturas.NEXTVAL, s.sensor_id, s.fecha_hora, s.valor);

COMMIT;

SELECT COUNT(*) AS filas, SUM(valor) AS suma
  FROM lecturas
 WHERE fecha_hora >= DATE '2026-05-01'; -- esperado: 14 filas, suma 2121.7

/*
C4:
1. El MERGE reescribió los mismos valores existentes (sobrescritura neutra), sin alterar el estado final.
2. El COUNT(*) no alcanza porque un reemplazo de datos o corrupción de valores mantendría la misma cantidad de filas;
   la suma verifica la integridad cuantitativa del contenido.
3. Idempotente: Propiedad por la cual ejecutar una operación múltiples veces produce exactamente el mismo resultado
   que ejecutarla una sola vez; a un bot que puede reintentar solo le evita generar duplicados o inconsistencias tras fallos.
*/

-- C5 — Lo que el INSERT no habría hecho
/*
C5:
Con INSERT ... WHERE NOT EXISTS la corrección no se aplicaba y no habría dado ningún error,
convirtiéndose en un fallo silencioso (Silent Failure), el tipo de error más peligroso catalogado en las clases 8 a 11.
*/


-- =====================================================================
-- PARTE D · CUÁNDO SÍ HACE FALTA EL BUCLE
-- =====================================================================

-- Reseteo previo a mayo
DELETE FROM lecturas WHERE fecha_hora >= DATE '2026-05-01';
DELETE FROM err_lecturas;
COMMIT;
SELECT COUNT(*) FROM lecturas;   -- esperado: 8640

-- D1 — El bucle, pero honesto
DECLARE
  v_ok  NUMBER := 0;
  v_mal NUMBER := 0;
BEGIN
  FOR r IN (SELECT * FROM staging_lecturas
             WHERE archivo = 'lect_20260501.csv' ORDER BY linea) LOOP
    BEGIN
      INSERT INTO lecturas (lectura_id, sensor_id, fecha_hora, valor)
      VALUES (seq_lecturas.NEXTVAL,
              TO_NUMBER(TRIM(r.sensor_id) DEFAULT NULL ON CONVERSION ERROR),
              TO_DATE(TRIM(r.fecha_hora) DEFAULT NULL ON CONVERSION ERROR,
                      'YYYY-MM-DD HH24:MI'),
              TO_NUMBER(TRIM(r.valor)     DEFAULT NULL ON CONVERSION ERROR));
      v_ok := v_ok + 1;
    EXCEPTION
      WHEN OTHERS THEN
        v_mal := v_mal + 1;
        DBMS_OUTPUT.PUT_LINE('linea ' || r.linea || ': ' || SQLERRM);
    END;
  END LOOP;
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('ok=' || v_ok || ' mal=' || v_mal);
END;
/

/*
D1:
Este WHEN OTHERS no se traga nada porque registra explícitamente el número de línea, el mensaje de error (SQLERRM)
y contabiliza los rechazos sin silenciar la causa ni continuar a ciegas.
*/

-- D2 — La misma tarea, un solo viaje
DELETE FROM lecturas WHERE fecha_hora >= DATE '2026-05-01';
DELETE FROM err_lecturas;
COMMIT;

DECLARE
  TYPE t_num IS TABLE OF NUMBER;
  TYPE t_fec IS TABLE OF DATE;
  v_sensor t_num;
  v_fecha  t_fec;
  v_valor  t_num;
  e_bulk EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_bulk, -24381);   -- "error(s) in array DML"
BEGIN
  SELECT TO_NUMBER(TRIM(sensor_id) DEFAULT NULL ON CONVERSION ERROR),
         TO_DATE(TRIM(fecha_hora) DEFAULT NULL ON CONVERSION ERROR, 'YYYY-MM-DD HH24:MI'),
         TO_NUMBER(TRIM(valor)     DEFAULT NULL ON CONVERSION ERROR)
    BULK COLLECT INTO v_sensor, v_fecha, v_valor
    FROM staging_lecturas
   WHERE archivo = 'lect_20260501.csv'
   ORDER BY linea;

  FORALL i IN 1 .. v_sensor.COUNT SAVE EXCEPTIONS
    INSERT INTO lecturas (lectura_id, sensor_id, fecha_hora, valor)
    VALUES (seq_lecturas.NEXTVAL, v_sensor(i), v_fecha(i), v_valor(i));

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('entraron las ' || v_sensor.COUNT);
EXCEPTION
  WHEN e_bulk THEN
    DBMS_OUTPUT.PUT_LINE('fallaron ' || SQL%BULK_EXCEPTIONS.COUNT ||
                         ' de ' || v_sensor.COUNT);
    FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
      DBMS_OUTPUT.PUT_LINE('  linea ' || SQL%BULK_EXCEPTIONS(i).ERROR_INDEX || ': ' ||
                           SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE));
    END LOOP;
    COMMIT;
END;
/

SELECT COUNT(*) FROM lecturas; -- esperado: 8652

/*
D2:
Sin SAVE EXCEPTIONS, el FORALL se detiene en el primer fallo (línea 3), habiendo insertado solo 2 filas.
El bloque se entera de los errores capturando la excepción ORA-24381 e iterando sobre la colección pseudo-matriz SQL%BULK_EXCEPTIONS.
*/

-- D3 — La cuenta que cierra la clase
/*
D3:
| Forma                              | Sentencias SQL ejecutadas | Context switches | Dónde quedan los errores            |
|------------------------------------|---------------------------|------------------|-------------------------------------|
| B2 · INSERT … SELECT … LOG ERRORS  | 1                         | 0 (puro SQL)     | En tabla persistente (ERR_LECTURAS) |
| D1 · bucle FOR con INSERT adentro  | 20                        | 40               | En buffer volátil de DBMS_OUTPUT    |
| D2 · BULK COLLECT + FORALL         | 2 (1 SELECT + 1 FORALL)   | 2                | En colección en memoria (capturable)|

A producción mandás B2 (INSERT con LOG ERRORS): los errores quedan persistidos en una tabla relacional auditable
y no en la memoria volátil de la sesión.
*/

-- D4 — La respuesta a la pregunta
/*
D4:
El bucle manual de D1 es preferible al FORALL de D2 cuando cada iteración requiere lógica condicional procedural compleja,
llamadas a APIs web externas, o cuando se debe realizar un COMMIT/ROLLBACK granular por cada registro procesado.
*/


-- =====================================================================
-- PARTE E · NUNCA SE CONCATENA SQL A MANO
-- =====================================================================

-- E1 — La versión con concatenación
CREATE OR REPLACE FUNCTION lecturas_abril_concat (p_sensor VARCHAR2) RETURN NUMBER AS
  v_n NUMBER;
BEGIN
  EXECUTE IMMEDIATE
    'SELECT COUNT(*) FROM lecturas WHERE fecha_hora < DATE ''2026-05-01'' AND sensor_id = ' || p_sensor
    INTO v_n;
  RETURN v_n;
END;
/

SELECT lecturas_abril_concat('1')        AS normal FROM dual;   -- esperado: 1440
SELECT lecturas_abril_concat('1 OR 1=1') AS ups    FROM dual;   -- esperado: 8640

/*
E1:
Normal: 1440
Ups: 8640 (Inyección SQL exitosa que devolvió la totalidad de registros)
*/

-- E2 — La versión con variable de enlace (Bind Variable)
CREATE OR REPLACE FUNCTION lecturas_abril_bind (p_sensor VARCHAR2) RETURN NUMBER AS
  v_n NUMBER;
BEGIN
  EXECUTE IMMEDIATE
    'SELECT COUNT(*) FROM lecturas WHERE fecha_hora < DATE ''2026-05-01'' AND sensor_id = :s'
    INTO v_n USING p_sensor;
  RETURN v_n;
END;
/

SELECT lecturas_abril_bind('1') FROM dual; -- esperado: 1440
-- SELECT lecturas_abril_bind('1 OR 1=1') FROM dual; -- Esperado: ORA-01722: invalid number

/*
E2 Error obtenido:
ORA-01722: invalid number
*/

-- E3
/*
E3:
1. No se la puede engañar porque el motor compila la estructura sintáctica del árbol SQL antes de asignar el parámetro,
   tratando el contenido exclusivamente como un literal de datos.
2. En E1 '1 OR 1=1' se convirtió en instrucción/código ejecutable; en E2 se trató como valor literal.
3. En E1 el motor tiene que analizar (hard parse) 1000 sentencias distintas; en E2 analiza 1 sola sentencia y reutiliza el plan 1000 veces (soft parse).
*/

-- E4 — El cierre del día
/*
E4:
El dato que viene de afuera jamás debe alterar la estructura de tu sentencia ni la integridad de tu base de datos;
debe tratarse siempre como un valor aislado y tipificado.
*/


-- =====================================================================
-- PARTE F · CIERRE
-- =====================================================================

/*
F1:
El proceso llamador debe consultar ERR_LECTURAS inmediatamente después del DML y emitir una alerta/notificación;
si no lo hace, en la finca se toman decisiones de riego/fertilización con datos incompletos o sensores dañados sin advertirlo.

F2:
Un proceso de carga está terminado cuando es idempotente, no pierde información de los rechazos y audita formalmente cada discrepancia.

F3 (Fila clase 12):
| Clase | Qué pasó                                                 | Qué avisó                                     |
|-------|----------------------------------------------------------|-----------------------------------------------|
| 12    | Carga parcial con 8 fallos no reportados y reejecución   | LOG ERRORS + MERGE + Bind Variables           |
*/


-- =====================================================================
-- EXTRA (+5) · LLEVALO A ESCALA (BENCHMARK)
-- =====================================================================

-- 1. Generar 30 días adicionales en staging_lecturas
INSERT INTO staging_lecturas (archivo, linea, sensor_id, fecha_hora, valor)
SELECT 'bench_mayo.csv',
       ROWNUM,
       TO_CHAR(s.sensor_id),
       TO_CHAR(DATE '2026-05-01' + (t.n - 1) / 48, 'YYYY-MM-DD HH24:MI'),
       TO_CHAR(ROUND(20 + MOD(t.n, 15) * 0.4, 2))
  FROM sensores s
 CROSS JOIN (SELECT LEVEL AS n FROM dual CONNECT BY LEVEL <= 1440);

COMMIT;

-- 2. Comparación de tiempos entre D1 (bucle individual) y D2 (FORALL)
DECLARE
  v_t0 NUMBER;
  v_t1 NUMBER;
  v_t2 NUMBER;
  v_filas NUMBER := 0;

  TYPE t_num IS TABLE OF NUMBER;
  TYPE t_fec IS TABLE OF DATE;
  v_sensor t_num;
  v_fecha  t_fec;
  v_valor  t_num;
BEGIN
  -- Limpieza previa del benchmark
  DELETE FROM lecturas WHERE fecha_hora >= DATE '2026-05-01';
  COMMIT;

  -- Test 1: Bucle FOR individual
  v_t0 := DBMS_UTILITY.GET_TIME;
  FOR r IN (SELECT * FROM staging_lecturas WHERE archivo = 'bench_mayo.csv') LOOP
    INSERT INTO lecturas (lectura_id, sensor_id, fecha_hora, valor)
    VALUES (seq_lecturas.NEXTVAL,
            TO_NUMBER(r.sensor_id),
            TO_DATE(r.fecha_hora, 'YYYY-MM-DD HH24:MI'),
            TO_NUMBER(r.valor));
    v_filas := v_filas + 1;
  END LOOP;
  COMMIT;
  v_t1 := DBMS_UTILITY.GET_TIME;
  DBMS_OUTPUT.PUT_LINE('Bucle D1: ' || v_filas || ' filas en ' || (v_t1 - v_t0) || ' hsecs (centésimas de seg)');

  -- Reset
  DELETE FROM lecturas WHERE fecha_hora >= DATE '2026-05-01';
  COMMIT;

  -- Test 2: BULK COLLECT + FORALL
  v_t1 := DBMS_UTILITY.GET_TIME;
  SELECT TO_NUMBER(sensor_id),
         TO_DATE(fecha_hora, 'YYYY-MM-DD HH24:MI'),
         TO_NUMBER(valor)
    BULK COLLECT INTO v_sensor, v_fecha, v_valor
    FROM staging_lecturas
   WHERE archivo = 'bench_mayo.csv';

  FORALL i IN 1 .. v_sensor.COUNT
    INSERT INTO lecturas (lectura_id, sensor_id, fecha_hora, valor)
    VALUES (seq_lecturas.NEXTVAL, v_sensor(i), v_fecha(i), v_valor(i));
  COMMIT;
  v_t2 := DBMS_UTILITY.GET_TIME;
  DBMS_OUTPUT.PUT_LINE('FORALL D2: ' || v_sensor.COUNT || ' filas en ' || (v_t2 - v_t1) || ' hsecs (centésimas de seg)');
END;
/