-- =====================================================================
-- CURSO DE SQL  |  CLASE 11  |  AgroDB sobre ORACLE
-- Motor: Oracle Database 23ai
--
-- DONDE SE CORRE: en el navegador, en FreeSQL (el reemplazo de Live SQL).
-- No hay que instalar nada. Tambien corre con @agrodb_oracle_clase11.sql
-- en SQLcl o SQL*Plus si tenes Oracle local.
--
-- =====================================================================
-- COMO SE CORRE ESTO (leelo, son 20 segundos y te ahorra media hora)
-- =====================================================================
--
--   1. Pega el archivo COMPLETO en el worksheet.
--
--   2. NO DEJES TEXTO SELECCIONADO. Si hay una seleccion, el worksheet
--      ejecuta SOLO lo seleccionado. Hace clic en cualquier lado del
--      editor primero para deseleccionar.
--
--   3. Dale a RUN SCRIPT (F5), no a RUN STATEMENT (el triangulo, o
--      Ctrl+Enter). "Run Statement" ejecuta UNA sola sentencia: la que
--      tenes debajo del cursor. Con 60 sentencias, eso no sirve.
--
--   4. Mira la pestaña "Script output". Tiene que estar lleno de
--      "Table ... created" y "1 row inserted". Si arranca con un error,
--      algo de lo anterior salio mal.
--
--   EL ERROR TIPICO:
--
--     ORA-00942: table or view "FINCAS" does not exist
--
--   Ese error NO es del script: es que las tablas nunca se crearon.
--   Corriste la verificacion del final sola, sin haber corrido el
--   resto. Deselecciona todo y dale Run Script otra vez.
--
-- =====================================================================
-- LO PRIMERO: ESTO NO ES SQLITE
-- =====================================================================
--
--   El modelo es el mismo AgroDB de siempre. Los datos son los mismos
--   hasta el ultimo kilo. Lo que cambio es el idioma, y cambio mas de
--   lo que parece. Mientras leen este script, cuenten cuantas cosas
--   estan escritas distinto:
--
--     SQLite                        Oracle
--     ----------------------------  ----------------------------------
--     TEXT                          VARCHAR2(n)
--     INTEGER / NUMERIC(10,2)       NUMBER / NUMBER(10,2)
--     DROP TABLE IF EXISTS x        no existe: hay que preguntar antes
--     INSERT ... VALUES (a),(b)     no existe: INSERT ALL, o una por una
--     '2026-04-01' (texto)          DATE '2026-04-01' (una fecha de verdad)
--     DATE(fecha_hora)              TRUNC(fecha_hora)
--     LIMIT 10                      FETCH FIRST 10 ROWS ONLY
--     SELECT 1;                     SELECT 1 FROM dual;
--     PRAGMA foreign_key_check      USER_CONSTRAINTS / EXCEPTIONS INTO
--
--   Y una que no se ve y muerde: en Oracle la cadena vacia '' ES NULL.
--   No hay diferencia entre las dos. En SQLite si la hay.
--
-- =====================================================================
-- LO QUE TRAE
-- =====================================================================
--
--   1. El modelo de siempre: fincas, cultivos, lotes, siembras, insumos,
--      labores, labor_insumo, sensores, cosechas.
--      Control de carga: 3, 6, 8, 10, 7, 19, 16, 6, 9  (los de siempre)
--
--   2. lecturas: 8.640 filas generadas, abril 2026 completo, seis
--      sensores cada 30 minutos. No hay un solo INSERT a mano: se
--      generan con CONNECT BY, que es la forma de Oracle de fabricar
--      filas de la nada. Miren como esta escrito, porque es la mitad
--      del ejercicio de hoy.
--
--   3. resumen_diario: VACIA a proposito. Hoy la llenan dos veces, de
--      dos maneras distintas, y comparan cuanto tarda cada una.
--
--   4. bitacora: VACIA. Es la de la clase 10, pero hoy si va a poder
--      contestar QUIEN.
--
-- =====================================================================


-- ---------------------------------------------------------------------
-- LIMPIEZA
--
-- Oracle no tiene DROP TABLE IF EXISTS. La forma correcta no es
-- "intentar y tapar el error": es preguntarle al catalogo que hay, y
-- borrar solo eso. De paso, este bloque ya es PL/SQL: un cursor FOR
-- LOOP y un EXECUTE IMMEDIATE. Volvemos sobre el en la parte C.
-- ---------------------------------------------------------------------
BEGIN
  FOR t IN (SELECT table_name
              FROM user_tables
             WHERE table_name IN ('BITACORA','RESUMEN_DIARIO','LECTURAS',
                                  'COSECHAS','LABOR_INSUMO','LABORES',
                                  'INSUMOS','SENSORES','SIEMBRAS',
                                  'LOTES','CULTIVOS','FINCAS'))
  LOOP
    EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS';
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


-- =====================================================================
-- VERIFICACION DE CARGA
--
-- Deben salir, en este orden:
--   3, 6, 8, 10, 7, 19, 16, 6, 9, 8640, 0, 0
--
-- Los nueve primeros son los mismos de siempre, desde la clase 5.
-- El 8640 son las lecturas generadas.
-- Los dos ceros son resumen_diario y bitacora: hoy los llenan ustedes.
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
-- LOS NUMEROS QUE YA SE SABEN DE MEMORIA, PARA COMPROBAR QUE ES LA
-- MISMA BASE
--
--   SUM(kg) de cosechas ............... 30550
--   costo total de las 10 siembras .... 3562.30
--   lecturas por sensor ............... 1440 cada uno
--   AVG por tipo (redondeado a 2) ..... temperatura 22.99
--                                       humedad     64.97
--                                       radiacion   464.50
--
-- Y uno nuevo, que es el chiste del dia:
--
--   SELECT SUM(kg) / 28.5 FROM cosechas c JOIN siembras s
--     ON s.siembra_id = c.siembra_id WHERE s.lote_id = 1;
--
--   En SQLite eso daba un entero y habia que escribir * 1.0 para que
--   diera decimales. En Oracle, NUMBER es un tipo de verdad y la
--   division da decimales sola. El * 1.0 que venimos escribiendo desde
--   la clase 5 es una cicatriz de SQLite, no una regla de SQL.
-- =====================================================================


-- =====================================================================
-- CURSO DE SQL | CLASE 11 
-- =====================================================================

-- =====================================================================
-- PARTE A: Lo que se rompe al cruzar la calle
-- =====================================================================

-- A1. Pruebas y correcciones
/*
1) SELECT 1;
   - Error: ORA-00923: FROM keyword not found where expected
   - Corrección Oracle:
     SELECT 1 FROM dual;

2) SELECT COUNT(*) FROM lecturas LIMIT 5;
   - Error: ORA-00933: SQL command not properly ended
   - Corrección Oracle:
     SELECT COUNT(*) FROM lecturas FETCH FIRST 5 ROWS ONLY;

3) DROP TABLE IF EXISTS basura;
   - Error: ORA-00933: SQL command not properly ended
   - Corrección Oracle:
     BEGIN
       EXECUTE IMMEDIATE 'DROP TABLE basura';
     EXCEPTION
       WHEN OTHERS THEN
         IF SQLCODE != -942 THEN RAISE; END IF;
     END;
     /

4) SELECT DATE(fecha_hora) FROM lecturas WHERE ROWNUM = 1;
   - Error: ORA-00904: "DATE": invalid identifier
   - Corrección Oracle:
     SELECT TRUNC(fecha_hora) FROM lecturas WHERE ROWNUM = 1;

5) SELECT sensor_id, COUNT(*) FROM lecturas GROUP BY sensor_id;
   - Resultado: Ejecuta perfectamente sin errores.
   - Observación: El estándar ANSI SQL para agregaciones y agrupamiento
     (GROUP BY, COUNT, SUM, etc.) funciona exactamente igual en SQLite y Oracle.
*/

-- A2. La cadena vacía
SELECT CASE WHEN '' IS NULL THEN 'la vacia ES null' ELSE 'la vacia NO es null' END AS resultado
  FROM dual;

/*
Respuesta A2:
En Oracle no se puede distinguir '' de NULL de forma nativa en tipos VARCHAR2, ya que
el motor convierte automáticamente cualquier cadena de longitud cero en NULL.
Para diferenciar «no anotó nada» de «anotó explícitamente que no hay nada», se debe
utilizar un valor centinela explícito (por ejemplo, '[VACIO]', 'N/A') o manejar
una columna booleana/indicadora adicional como 'sin_observaciones NUMBER(1) CHECK (sin_observaciones IN (0,1))'.
*/

-- A3. La cicatriz del * 1.0
SELECT SUM(c.kg) AS kg, SUM(c.kg) / l.hectareas AS kg_ha
  FROM cosechas c
  JOIN siembras s ON s.siembra_id = c.siembra_id
  JOIN lotes    l ON l.lote_id    = s.lote_id
 WHERE l.lote_id = 1
 GROUP BY l.hectareas;

/*
Respuesta A3:
El '* 1.0' era una defensa contra la división entera de SQLite cuando ambos operandos
son de afinidad entera. En Oracle, el tipo NUMBER maneja aritmética de punto flotante/decimal
exacta por defecto, por lo que la división preserva la precisión decimal automáticamente.
*/

-- A4. TRUNC vs DATE
SELECT TRUNC(fecha_hora) AS dia, COUNT(*) AS n
  FROM lecturas
 WHERE sensor_id = 1
 GROUP BY TRUNC(fecha_hora)
 ORDER BY dia
 FETCH FIRST 3 ROWS ONLY;

/*
Hipótesis A4:
Sí, al igual que en SQLite, aplicar una función como TRUNC(fecha_hora) sobre una columna
en el WHERE anula el uso de un índice B-Tree estándar sobre 'fecha_hora', forzando un Full Table Scan,
a menos que se cree explícitamente un índice basado en funciones (Function-Based Index).
*/


-- =====================================================================
-- PARTE B: El primer bloque
-- =====================================================================

-- B1. Anatomía
DECLARE
  v_total NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_total FROM lecturas;
  DBMS_OUTPUT.PUT_LINE('lecturas: ' || v_total);
END;
/

/*
Respuesta B1:
- INTO asigna el resultado de la proyección de la consulta SQL directamente a una variable en memoria de PL/SQL.
- Un SELECT suelto en PL/SQL provoca error de compilación porque el motor procesal necesita un destino donde depositar los datos devueltos.
- Si se omite la barra '/' al final, el cliente/interfaz (SQL*Plus, SQLcl, FreeSQL) no envía el búfer de texto al servidor para su compilación y ejecución.
*/

-- B2. %TYPE
DECLARE
  v_tipo sensores.tipo%TYPE;
  v_n    NUMBER;
BEGIN
  SELECT s.tipo, COUNT(l.lectura_id)
    INTO v_tipo, v_n
    FROM sensores s
    LEFT JOIN lecturas l ON s.sensor_id = l.sensor_id
   WHERE s.sensor_id = 1
   GROUP BY s.tipo;

  DBMS_OUTPUT.PUT_LINE('sensor 1 (' || v_tipo || '): ' || v_n || ' lecturas');
END;
/

/*
Respuesta B2:
Si la columna se expande a VARCHAR2(40), con %TYPE la variable v_tipo hereda automáticamente el nuevo tamaño
al recompilar sin romper nada. Si se hubiera declarado VARCHAR2(20) de forma estática, cualquier cadena
mayor a 20 caracteres provocaría el error en tiempo de ejecución ORA-06502 (numeric or value error: character string buffer too small).
*/

-- B3. Excepciones requeridas por SELECT INTO
/*
Caso 1: Cero filas
DECLARE
  v_nombre fincas.nombre%TYPE;
BEGIN
  SELECT nombre INTO v_nombre FROM fincas WHERE finca_id = 99;
  DBMS_OUTPUT.PUT_LINE(v_nombre);
END;
/
Error obtenido:
ORA-01403: no data found

Caso 2: Tres filas
DECLARE
  v_nombre fincas.nombre%TYPE;
BEGIN
  SELECT nombre INTO v_nombre FROM fincas WHERE finca_id IN (1, 2, 3);
  DBMS_OUTPUT.PUT_LINE(v_nombre);
END;
/
Error obtenido:
ORA-01422: exact fetch returns more than requested number of rows

Respuesta B3:
Si la consulta devuelve cero filas se lanza la excepción NO_DATA_FOUND (ORA-01403).
Si devuelve dos o más filas se lanza la excepción TOO_MANY_ROWS (ORA-01422).
*/

-- B4. Atrapando NO_DATA_FOUND
DECLARE
  v_nombre fincas.nombre%TYPE;
BEGIN
  SELECT nombre INTO v_nombre FROM fincas WHERE finca_id = 99;
  DBMS_OUTPUT.PUT_LINE(v_nombre);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('finca 99: no existe');
END;
/

/*
Respuesta B5:
Se parece en que ambas estructuras interceptan un fallo potencial evitando que el programa aborte de forma abrupta.
Se diferencia en que CREATE VIEW IF NOT EXISTS ocultaba de forma ciega que la vista ya existía (dejando la versión previa sin actualizar),
mientras que en B4 la excepción es capturada de forma controlada y explícita para tomar una acción programada concreta.
*/


-- =====================================================================
-- PARTE C: Fila por fila es lento por lento
-- =====================================================================

-- C1. Bucle fila por fila
DECLARE
  t0 NUMBER := DBMS_UTILITY.GET_TIME;
BEGIN
  DELETE FROM resumen_diario;

  FOR s IN (SELECT sensor_id FROM sensores ORDER BY sensor_id) LOOP
    FOR d IN (SELECT DISTINCT TRUNC(fecha_hora) AS dia FROM lecturas ORDER BY 1) LOOP
      INSERT INTO resumen_diario (sensor_id, dia, n_lecturas, valor_min, valor_max, valor_prom)
      SELECT s.sensor_id, d.dia, COUNT(*), MIN(valor), MAX(valor), ROUND(AVG(valor), 2)
        FROM lecturas
       WHERE sensor_id = s.sensor_id
         AND TRUNC(fecha_hora) = d.dia;
    END LOOP;
  END LOOP;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('fila por fila: ' ||
      (DBMS_UTILITY.GET_TIME - t0) || ' centesimas de segundo');
END;
/

-- Verificación C1:
SELECT COUNT(*) FROM resumen_diario;
SELECT * FROM resumen_diario WHERE sensor_id = 1 AND dia = DATE '2026-04-01';

-- C2. Una sola sentencia de conjunto
DECLARE
  t0 NUMBER := DBMS_UTILITY.GET_TIME;
BEGIN
  DELETE FROM resumen_diario;

  INSERT INTO resumen_diario (sensor_id, dia, n_lecturas, valor_min, valor_max, valor_prom)
  SELECT sensor_id, TRUNC(fecha_hora), COUNT(*), MIN(valor), MAX(valor), ROUND(AVG(valor), 2)
    FROM lecturas
   GROUP BY sensor_id, TRUNC(fecha_hora);

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('de una sola vez: ' ||
      (DBMS_UTILITY.GET_TIME - t0) || ' centesimas de segundo');
END;
/

-- Verificación C2:
SELECT COUNT(*) FROM resumen_diario;
SELECT * FROM resumen_diario WHERE sensor_id = 1 AND dia = DATE '2026-04-01';

/*
Respuesta C3:
- En C1 se ejecutaron 180 sentencias INSERT (6 sensores * 30 días). En C2 se ejecutó 1 solo INSERT.
- En C1, cada uno de los 180 INSERT ejecutó un Full Scan de 8.640 filas: 180 * 8.640 = 1.555.200 filas leídas.
- En C2, el motor leyó la tabla lecturas en un único pase: 8.640 filas leídas.
- La razón entre ambas es de 180 a 1 (C1 procesa 180 veces más filas que C2).

Respuesta C4:
- En C1 hubo al menos 360 context switches entre PL/SQL y SQL (180 lecturas + 180 inserciones más cursores). En C2 hubo 1 solo context switch al invocar la sentencia SQL.
- Si el bucle solo sumara números en memoria nativa, correría en milisegundos.
- El problema no es la instrucción LOOP, sino invocar SQL interactivo repetitivamente dentro del LOOP.
*/

-- C5. Planes de ejecución
EXPLAIN PLAN FOR
SELECT COUNT(*), MIN(valor), MAX(valor), AVG(valor)
  FROM lecturas WHERE sensor_id = 1 AND TRUNC(fecha_hora) = DATE '2026-04-01';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

EXPLAIN PLAN FOR
SELECT sensor_id, TRUNC(fecha_hora), COUNT(*), MIN(valor), MAX(valor), AVG(valor)
  FROM lecturas GROUP BY sensor_id, TRUNC(fecha_hora);
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

/*
Respuesta C5:
El plan de ejecución muestra el costo unitario de una consulta individual, pero no refleja
la cantidad de VECES que esa consulta es invocada en el ciclo procedural (180 veces frente a 1 sola vez).

Respuesta C6:
No se contradicen. El plan contesta «cómo resuelve el motor una sentencia aislada»,
mientras que el reloj contesta «cuánto cuesta la ejecución total del algoritmo considerando la frecuencia de invocación».
*/


-- =====================================================================
-- PARTE D: El error que pediste que te ignoren
-- =====================================================================

-- D1. Procedimiento con fallo silencioso
CREATE OR REPLACE PROCEDURE cargar_labor (
  p_siembra_id  NUMBER,
  p_tipo        VARCHAR2,
  p_fecha       DATE,
  p_responsable VARCHAR2,
  p_costo       NUMBER
) AS
  v_id NUMBER;
BEGIN
  SELECT NVL(MAX(labor_id), 0) + 1 INTO v_id FROM labores;
  INSERT INTO labores (labor_id, siembra_id, tipo_labor, fecha, responsable, costo_mano_obra)
  VALUES (v_id, p_siembra_id, p_tipo, p_fecha, p_responsable, p_costo);
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

-- D2. Lote de prueba
SELECT COUNT(*) FROM labores;

BEGIN
  cargar_labor(1,  'riego',         DATE '2026-05-02', 'Marta Ruiz',  55);
  cargar_labor(99, 'riego',         DATE '2026-05-03', 'Marta Ruiz',  60);
  cargar_labor(3,  'fertilizacion', DATE '2026-05-04', 'Jorge Mina',  70);
  cargar_labor(2,  'poda',          DATE '2026-05-05', 'Jorge Mina', -10);
  COMMIT;
END;
/

SELECT COUNT(*) FROM labores;

/*
Respuesta D2:
Entraron solo 2 filas (total 21 filas). Se perdieron 2 operaciones:
- La siembra 99 falló por violación de Foreign Key (ORA-02291).
- El costo -10 falló por violación de Check Constraint ck_labores_costo (ORA-02290).
Nos enteramos únicamente al comparar el COUNT previo y posterior; en producción se habrían perdido en silencio absoluto.

Respuesta D3:
"El peor error de un sistema no es fallar, sino fallar en silencio aparentando éxito; la integridad de los datos exige visibilidad inmediata del error."
*/

-- D4. Corrección estructurada
CREATE OR REPLACE PROCEDURE cargar_labor (
  p_siembra_id  NUMBER,
  p_tipo        VARCHAR2,
  p_fecha       DATE,
  p_responsable VARCHAR2,
  p_costo       NUMBER
) AS
  v_id          NUMBER;
  e_fk_invalida EXCEPTION;
  e_check_roto  EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_fk_invalida, -2291);
  PRAGMA EXCEPTION_INIT(e_check_roto,  -2290);
BEGIN
  SELECT NVL(MAX(labor_id), 0) + 1 INTO v_id FROM labores;
  
  INSERT INTO labores (labor_id, siembra_id, tipo_labor, fecha, responsable, costo_mano_obra)
  VALUES (v_id, p_siembra_id, p_tipo, p_fecha, p_responsable, p_costo);

EXCEPTION
  WHEN e_fk_invalida THEN
    INSERT INTO bitacora (tabla, operacion, clave, detalle)
    VALUES ('LABORES', 'ERROR', TO_CHAR(p_siembra_id), 'Error FK: La siembra indicada no existe');
    RAISE_APPLICATION_ERROR(-20001, 'Error: La siembra ' || p_siembra_id || ' no existe en el sistema.');

  WHEN e_check_roto THEN
    INSERT INTO bitacora (tabla, operacion, clave, detalle)
    VALUES ('LABORES', 'ERROR', TO_CHAR(p_siembra_id), 'Error CHECK: Costo de mano de obra negativo');
    RAISE_APPLICATION_ERROR(-20002, 'Error: El costo de mano de obra no puede ser negativo (' || p_costo || ').');

  WHEN OTHERS THEN
    INSERT INTO bitacora (tabla, operacion, clave, detalle)
    VALUES ('LABORES', 'ERROR', TO_CHAR(p_siembra_id), 'Error inesperado: ' || SQLERRM);
    RAISE_APPLICATION_ERROR(-20003, 'Error no controlado (' || SQLCODE || '): ' || SQLERRM);
END;
/

/*
Respuesta D4:
No es peor que se corte; es el comportamiento correcto. Es preferible detener el procesamiento
para no corromper la consistencia de la base con transacciones incompletas o erróneas.
(Nota de diseño: si el llamador ejecuta ROLLBACK ante el error, revertirá también el INSERT en bitácora,
salvo que el registro se aísle en un procedimiento con PRAGMA AUTONOMOUS_TRANSACTION).

Respuesta D5:
WHEN OTHERS está bien puesto SIEMPRE QUE se utilice para registrar el error (log/auditoría) y termine obligatoriamente relanzándolo (RAISE o RAISE_APPLICATION_ERROR), o realizando un ROLLBACK de limpieza antes de propagar.
*/


-- =====================================================================
-- PARTE E: El QUIÉN que SQLite no podía dar
-- =====================================================================

-- E1. Identidad de sesión
SELECT USER AS quien, SYSTIMESTAMP AS cuando FROM dual;

-- E2. Trigger de auditoría
CREATE OR REPLACE TRIGGER trg_cosechas_bitacora
AFTER INSERT OR UPDATE OR DELETE ON cosechas
FOR EACH ROW
BEGIN
  IF INSERTING THEN
    INSERT INTO bitacora (tabla, operacion, clave, detalle, usuario, cuando)
    VALUES ('COSECHAS', 'INSERT', TO_CHAR(:NEW.cosecha_id),
            'Alta de cosecha. Siembra: ' || :NEW.siembra_id || ' - Kilos: ' || :NEW.kg || ' - Calidad: ' || :NEW.calidad,
            USER, SYSTIMESTAMP);
            
  ELSIF UPDATING THEN
    INSERT INTO bitacora (tabla, operacion, clave, detalle, usuario, cuando)
    VALUES ('COSECHAS', 'UPDATE', TO_CHAR(:NEW.cosecha_id),
            'Modificación kg: ' || :OLD.kg || ' -> ' || :NEW.kg || ' (Siembra ' || :NEW.siembra_id || ')',
            USER, SYSTIMESTAMP);
            
  ELSIF DELETING THEN
    INSERT INTO bitacora (tabla, operacion, clave, detalle, usuario, cuando)
    VALUES ('COSECHAS', 'DELETE', TO_CHAR(:OLD.cosecha_id),
            'Baja de cosecha previa. Kilos eliminados: ' || :OLD.kg || ' (Siembra ' || :OLD.siembra_id || ')',
            USER, SYSTIMESTAMP);
  END IF;
END;
/

-- E3. Prueba del ciclo completo DML
INSERT INTO cosechas VALUES (10, 6, DATE '2026-05-10', 750, 'segunda', 'mercado local');
UPDATE cosechas SET kg = 800 WHERE cosecha_id = 10;
DELETE FROM cosechas WHERE cosecha_id = 10;
COMMIT;

SELECT operacion, clave, detalle, usuario, cuando FROM bitacora ORDER BY bitacora_id;

/*
Respuesta E4:
No garantiza una auditoría infalible por sí sola. Si varios usuarios comparten la misma credencial de base de datos,
'USER' reflejará siempre la cuenta genérica y no la persona real. Además, un usuario con privilegios DDL puede ejecutar
'DROP TRIGGER' o deshabilitarlo para eludir el control sin dejar rastro en la tabla bitácora.
*/


-- =====================================================================
-- PARTE F: Cierre
-- =====================================================================

/*
1. Porcentaje portable:
Aproximadamente un 80% del SQL estándar corrió sin modificaciones (JOINs, GROUP BY, agregaciones, subconsultas y filtros lógicos).
- Corrió igual: SELECT s.sensor_id, COUNT(*) FROM lecturas GROUP BY s.sensor_id.
- Hubo que reescribir: El paginado 'LIMIT 5' por 'FETCH FIRST 5 ROWS ONLY' y la aritmética de fechas 'DATE()' por 'TRUNC()'.

2. Cuándo usar PL/SQL:
Vale la pena escribir PL/SQL cuando se requiere lógica procedural condicional, validaciones de negocio complejas antes de persistir, orquestación de transacciones en múltiples pasos o manejo granular de excepciones.

3. Por qué la gente usa WHEN OTHERS THEN NULL:
Se escribe por conveniencia y urgencia: permite que los flujos masivos terminen sin interrumpir la ejecución ni reportar alertas inmediatas, postergando la resolución de errores de raíz.
*/


-- =====================================================================
-- EXTRA: BULK COLLECT + FORALL
-- =====================================================================

DECLARE
  TYPE t_resumen IS RECORD (
    sensor_id  resumen_diario.sensor_id%TYPE,
    dia        resumen_diario.dia%TYPE,
    n_lecturas resumen_diario.n_lecturas%TYPE,
    valor_min  resumen_diario.valor_min%TYPE,
    valor_max  resumen_diario.valor_max%TYPE,
    valor_prom resumen_diario.valor_prom%TYPE
  );
  TYPE t_resumen_tab IS TABLE OF t_resumen;
  v_datos t_resumen_tab;
  t0 NUMBER := DBMS_UTILITY.GET_TIME;
BEGIN
  DELETE FROM resumen_diario;

  -- 1 context switch para leer todo el bloque a memoria
  SELECT sensor_id, TRUNC(fecha_hora), COUNT(*), MIN(valor), MAX(valor), ROUND(AVG(valor), 2)
    BULK COLLECT INTO v_datos
    FROM lecturas
   GROUP BY sensor_id, TRUNC(fecha_hora);

  -- 1 context switch para insertar en lote
  FORALL i IN 1..v_datos.COUNT
    INSERT INTO resumen_diario VALUES v_datos(i);

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('bulk collect + forall: ' ||
      (DBMS_UTILITY.GET_TIME - t0) || ' centesimas de segundo');
END;
/

/*
Explicación Extra:
El tiempo queda entre C1 y C2 porque reduce los 360 context switches de C1 a solo 2
(uno para traer el set de datos a la memoria PGA y otro para persistir el lote vía FORALL),
pero sigue siendo ligeramente más lento que C2 debido al costo de asignación de memoria
intermedia frente a la ejecución nativa en un solo paso dentro del motor SQL.
*/