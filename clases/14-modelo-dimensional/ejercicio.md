# Ejercicio práctico 14 · Construye la estrella, y rómpela a propósito
**Duración: 2 horas · Individual · En tu Oracle local · Entrega: un archivo `.sql` y una captura**

---

## Qué vas a lograr hoy

1. Un **modelo dimensional** completo sobre AgroDB: tres dimensiones y una tabla de hechos.
2. Provocar, **a propósito**, el error más silencioso de todo el curso: un tablero que da **19 750** en vez de 30 550 y no dice nada.
3. Detectarlo con una consulta de tres líneas.
4. Ponerle al modelo la restricción que **sí** habría avisado.
5. Power BI leyendo **cuatro tablas relacionadas** en vez de una vista plana.

**El número que prueba que todo salió bien sigue siendo 30 550.** Pero hoy vas a ver ese número equivocarse antes de arreglarlo.

---

## Antes de empezar

Necesitas lo de ayer, funcionando:

| | |
|---|---|
| Tu Oracle local prendido | `OracleServiceFREE` y el listener, en `services.msc` |
| El usuario `agro` | `sqlplus agro/Agro2026@localhost:1521/FREEPDB1` |
| El usuario `bi_agro` | ya existe desde ayer; los usuarios no se borran al recargar tablas |
| Power BI Desktop con el OCMT | ya instalado en la clase 13 |

Descarga el script del día: [`datos/agrodb_oracle_clase14.sql`](../../datos/agrodb_oracle_clase14.sql)

**Cópialo a `C:\agrodb\`.** No lo dejes en Descargas ni en una carpeta de OneDrive: si la ruta tiene espacios, `@` se corta en el primer espacio y da `SP2-0310`.

```sql
sqlplus agro/Agro2026@localhost:1521/FREEPDB1
SET SERVEROUTPUT ON
SET LINESIZE 200 PAGESIZE 100
@C:\agrodb\agrodb_oracle_clase14.sql
```

> ### ✅ Punto de control 0
> Los **doce** números: **3, 6, 8, 10, 7, 19, 16, 6, 9, 8640, 0, 0**
> Y el reparto por mes: **marzo 3 cosechas / 10 800 kg · abril 6 cosechas / 19 750 kg.**
> **Pega los dos resultados en tu archivo.**

> **Ojo:** este script **borra** la vista `v_bi_produccion` que hiciste ayer. No es un bug: el script de cada día se escribe para no traerte resuelto el ejercicio anterior. La vuelves a escribir en la parte A, y son treinta segundos.

---

## Cómo se entrega

En `entregas/apellido-nombre/`, por *pull request*, **dos archivos**:

| Archivo | Qué lleva |
|---|---|
| `Ejercicio14_Apellido_Nombre.sql` | todas las consultas, con **su resultado pegado como comentario** debajo de cada una, y las respuestas de la parte F |
| `clase14-modelo.png` | captura de la vista **Modelo** de Power BI, donde se vean las **tres relaciones** |

> Igual que ayer: **una consulta sin su resultado pegado abajo no cuenta.**

---

## Parte A · El punto de partida (15 min)

### A1. Reconstruye la vista plana de ayer

Es la misma de la clase 13. Escríbela otra vez:

```sql
CREATE OR REPLACE VIEW v_bi_produccion AS
SELECT f.nombre     AS finca,
       l.codigo     AS lote,
       cu.nombre    AS cultivo,
       s.estado     AS estado_siembra,
       co.fecha     AS fecha_cosecha,
       co.calidad   AS calidad,
       co.kg        AS kg
  FROM cosechas co
  JOIN siembras s  ON s.siembra_id  = co.siembra_id
  JOIN lotes    l  ON l.lote_id     = s.lote_id
  JOIN fincas   f  ON f.finca_id    = l.finca_id
  JOIN cultivos cu ON cu.cultivo_id = s.cultivo_id;

SELECT COUNT(*) AS filas, SUM(kg) AS kilos FROM v_bi_produccion;
```

> ### ✅ Punto de control 1
> **9 filas y 30 550 kilos.** Pégalo.

### A2. Mide el problema

Cuenta cuántas veces se repite cada nombre de finca en la vista:

```sql
SELECT finca, COUNT(*) AS veces_escrita
  FROM v_bi_produccion
 GROUP BY finca
 ORDER BY veces_escrita DESC;
```

**A3.** En un comentario, una línea: son 9 filas, así que `Hacienda Santa Rosa` se escribe 4 veces y no le duele a nadie. **¿A partir de cuántas filas empieza a doler, y por qué?**

---

## Parte B · Las tres dimensiones (25 min)

### B1. Créalas

Escribe las tres tablas. Están en las diapositivas 7, 8 y 9:

- `dim_finca` — `finca_id` (PK), `finca`, `provincia`
- `dim_cultivo` — `cultivo_id` (PK), `cultivo`, `variedad`, `tipo`
- `dim_tiempo` — `fecha` (PK, `DATE`), `anio`, `mes`, `nombre_mes`, `trimestre`

### B2. Carga las dos fáciles

`dim_finca` y `dim_cultivo` salen de un `INSERT … SELECT` de una sola tabla cada una. **3 y 6 filas.**

### B3. Carga el calendario, y hazlo MAL a propósito

Esto no es un descuido del enunciado. Es el ejercicio.

Llena `dim_tiempo` **sólo con abril de 2026**, con el argumento que suena razonable: *«las lecturas de AgroDB son de abril, con abril alcanza»*.

```sql
INSERT INTO dim_tiempo (fecha, anio, mes, nombre_mes, trimestre)
SELECT d, 2026, 4, 'Abril', 2
  FROM (SELECT DATE '2026-04-01' + LEVEL - 1 AS d
          FROM dual CONNECT BY LEVEL <= 30);
COMMIT;
```

> ### ✅ Punto de control 2
> `dim_finca` **3** · `dim_cultivo` **6** · `dim_tiempo` **30**.
> **No lo arregles todavía.** Lo vas a necesitar roto en la parte D.

---

## Parte C · La tabla de hechos (25 min)

### C1. Crea `h_cosecha`

Está en la diapositiva 10. **Sin claves foráneas**, tal como está ahí.

En un comentario **arriba de la tabla**, escribe el grano en una línea:

```sql
-- GRANO: una fila por cosecha.
```

### C2. Cárgala

El `INSERT … SELECT` con los cinco `JOIN` de la diapositiva 12. **No olvides el `TRUNC(co.fecha)`.**

### C3. Comprueba el hecho solo, sin dimensiones

```sql
SELECT COUNT(*) AS filas, SUM(kg) AS kilos FROM h_cosecha;
```

> ### ✅ Punto de control 3
> **9 filas y 30 550 kilos.**
> Las nueve cosechas están cargadas. **Anota esto, porque en cinco minutos va a ser importante.**

### C4. Y ahora por cultivo, cruzando sólo con `dim_cultivo`

```sql
SELECT dc.cultivo, SUM(h.kg) AS kilos
  FROM h_cosecha h
  JOIN dim_cultivo dc ON dc.cultivo_id = h.cultivo_id
 GROUP BY dc.cultivo
 ORDER BY kilos DESC;
```

| Cultivo | Kilos |
|---|---|
| Mango | 12 700 |
| Maiz | 9 800 |
| Guayaba | 5 950 |
| Cacao | 2 100 |
| **Total** | **30 550** |

**C5.** `dim_cultivo` tiene 6 filas y en este resultado sólo salen 4. En un comentario, una línea: **¿faltan datos, o está bien?** ¿Qué habría que cambiarle a la consulta para que Banano y Café aparezcan con 0?

---

## Parte D · La trampa (30 min) — es la parte que más vale

### D1. Cruza el hecho con el calendario

La consulta de la diapositiva 13, tal cual:

```sql
SELECT df.finca, SUM(h.kg) AS kilos
  FROM h_cosecha h
  JOIN dim_finca  df ON df.finca_id = h.finca_id
  JOIN dim_tiempo dt ON dt.fecha    = h.fecha
 GROUP BY df.finca
 ORDER BY kilos DESC;
```

> ### ✅ Punto de control 4
> Te va a dar esto, y **está mal**:
>
> | Finca | Kilos |
> |---|---|
> | Finca El Guayabo | 14 250 |
> | Hacienda Santa Rosa | **4 600** |
> | Agricola La Union | **900** |
> | **Total** | **19 750** |
>
> **Pega el resultado.** Y pega también el total: `SELECT SUM(...)` sobre esa misma consulta debe dar **19 750**.

**D2.** En un comentario, contesta **antes** de seguir leyendo: en C3 comprobaste que `h_cosecha` tiene las 9 filas y los 30 550 kilos. Nada se borró. **Entonces, ¿dónde están los 10 800 kilos que faltan aquí?**

### D3. Ni un error

En un comentario, en una línea: **¿qué mensaje de error dio Oracle en D1?**

(La respuesta es incómoda a propósito.)

### D4. Detéctalo con SQL

```sql
SELECT h.cosecha_id, h.fecha, h.kg
  FROM h_cosecha h
  LEFT JOIN dim_tiempo dt ON dt.fecha = h.fecha
 WHERE dt.fecha IS NULL;
```

> ### ✅ Punto de control 5
> **3 filas huérfanas, 10 800 kilos.** Son las tres cosechas de marzo.
> **Pega las tres filas completas**, con su `cosecha_id` y su fecha.

### D5. La consulta de control, la que va en el guion de carga de todos los días

```sql
SELECT (SELECT SUM(kg) FROM cosechas) AS origen,
       (SELECT SUM(h.kg)
          FROM h_cosecha h
          JOIN dim_tiempo dt ON dt.fecha = h.fecha) AS estrella
  FROM dual;
```

Ahora mismo tiene que darte **30550** y **19750**. Distintos. **Eso es el hallazgo.**

### D6. La restricción que sí habría avisado

Con el calendario todavía roto, intenta esto:

```sql
ALTER TABLE h_cosecha
  ADD CONSTRAINT fk_h_cosecha_tiempo
  FOREIGN KEY (fecha) REFERENCES dim_tiempo(fecha);
```

> ### ✅ Punto de control 6
> Tiene que **fallar** con `ORA-02298`.
> **Pega el mensaje completo, literal.** Ese error es el objetivo, no un problema.

### D7. Arregla el calendario

Vacía `dim_tiempo` y llénalo con **los 365 días de 2026** (diapositiva 11).

Luego, **en este orden**:

1. Vuelve a correr el `ALTER TABLE` de D6. Ahora debe decir `Table altered.`
2. Vuelve a correr la consulta de control de D5.

> ### ✅ Punto de control 7
> `dim_tiempo` **365 filas** · la FK creada · y en D5 los dos números **iguales: 30550 y 30550**.
> Y la consulta de D1 otra vez: **14 250 / 14 200 / 2 100, total 30 550.**

**D8.** En dos líneas: la restricción de D6 no arregla nada por sí sola, sólo se queja. **¿Por qué entonces vale la pena ponerla?** ¿En qué momento exacto te habría avisado si la hubieras creado desde el principio?

---

## Parte E · Power BI lee un modelo (15 min)

### E1. Los permisos

Ayer diste **un** `GRANT` sobre **una** vista. Hoy son cuatro tablas:

```sql
GRANT SELECT ON dim_finca   TO bi_agro;
GRANT SELECT ON dim_cultivo TO bi_agro;
GRANT SELECT ON dim_tiempo  TO bi_agro;
GRANT SELECT ON h_cosecha   TO bi_agro;
```

### E2. Carga las cuatro

Power BI Desktop → **Obtener datos → Base de datos Oracle** → servidor `localhost:1521/FREEPDB1` → **Importar** → usuario `bi_agro` / `Bi2026`.

En el navegador, dentro del esquema `AGRO`, ahora hay **cinco cosas**: las cuatro tablas y la vista de la parte A. Selecciona **sólo las cuatro** y da **Cargar**.

### E3. Las relaciones

Ve a la vista **Modelo** (el ícono de la izquierda que parece un diagrama).

Power BI intenta adivinar las relaciones. **Revísalas una por una**, no confíes:

| De | A | Cardinalidad |
|---|---|---|
| `h_cosecha[finca_id]` | `dim_finca[finca_id]` | muchos a uno |
| `h_cosecha[cultivo_id]` | `dim_cultivo[cultivo_id]` | muchos a uno |
| `h_cosecha[fecha]` | `dim_tiempo[fecha]` | muchos a uno |

Las que falten, se arrastran de un campo al otro.

### E4. La gráfica

Barras agrupadas: **Eje Y** `dim_finca[finca]`, **Valores** `h_cosecha[kg]` (que diga **Suma de KG**).

Y una **Tarjeta** con la suma. Ponla en formato sin abreviar: **Formato → Valor de llamada → Unidades de presentación: Ninguna, Posiciones decimales: 0.**

> ### ✅ Punto de control 8
> La tarjeta dice **30550**, no *«30,55 mil»*.
> Las barras: 14 250 / 14 200 / 2 100.
> **La captura es la vista Modelo con las tres relaciones visibles**, no la gráfica.

**E5.** Fíjate en un detalle: el campo `finca` que pusiste en el eje **sale de `dim_finca`**, no de `h_cosecha`. En una línea: **¿por qué ese campo ya no vive en la tabla de hechos**, y qué ganaste con eso?

---

## Parte F · Preguntas de cierre (10 min, comentarios en tu archivo)

1. En una línea: **¿qué es el grano** de una tabla de hechos, y qué pasa si dos personas del equipo creen que es distinto?
2. `dim_cultivo` tiene filas que `h_cosecha` no usa (Banano, Café), y eso está bien. `h_cosecha` tenía fechas que `dim_tiempo` no tenía, y eso fue un desastre. En dos líneas: **¿por qué no es simétrico?**
3. Hoy el número malo fue **19 750**. En la clase 5 fue un `SUM` inflado por fan-out; en la 6, un `-99` disfrazado de temperatura; en la 8, una vista que no se reemplazó. En una línea: **¿qué tienen los cuatro en común?**
4. Tu tablero corre en modo **Importar**. Mañana alguien carga una cosecha con fecha de **enero de 2027**. En dos líneas: **¿qué muestra tu tablero?** ¿Y qué pasa ahora que `h_cosecha` tiene la clave foránea contra `dim_tiempo`?
5. En una línea: el modelo operativo (`cosechas`, `siembras`, `lotes`…) **sigue existiendo** y no lo tocamos. **¿Por qué no lo reemplazamos por la estrella y ya?**

---

## Si algo falla

| Mensaje o síntoma | Qué pasó | Qué haces |
|---|---|---|
| `SP2-0310: unable to open file` | la ruta del `@` tiene espacios | copia el `.sql` a `C:\agrodb\` |
| `ORA-00942` al crear `dim_finca` | te conectaste con `system`, no con `agro` | `CONNECT agro/Agro2026@localhost:1521/FREEPDB1` |
| `ORA-00955: name already used` | ya corriste el `CREATE TABLE` | `DROP TABLE dim_tiempo CASCADE CONSTRAINTS;` y de nuevo |
| `ORA-00001` al cargar `dim_tiempo` | la cargaste dos veces | `DELETE FROM dim_tiempo; COMMIT;` y de nuevo |
| `ORA-02298` en D6 | **está bien, eso queríamos** | pégalo y sigue a D7 |
| `ORA-02291` al insertar en `h_cosecha` | ya creaste la FK y el calendario está corto | arregla `dim_tiempo` primero |
| El total da **0** y no 19 750 | falta el `TRUNC`, o `dim_tiempo` es de otro año | compara `SELECT MIN(fecha), MAX(fecha)` de las dos tablas |
| `ORA-01722: invalid number` | `TO_NUMBER(TO_CHAR(d,'Q'))` mal escrito | la `Q` va entre comillas simples |
| `nombre_mes` sale en inglés | tu `NLS_DATE_LANGUAGE` es inglés | **no es error**, no es parte del control |
| En Power BI los kilos salen inflados | una relación quedó al revés | vista **Modelo**: siempre **muchos a uno** hacia la dimensión |

> ### La regla de los 20 minutos sigue vigente
> Veinte minutos atorado en el mismo error: lo escribes como comentario empezando con `DUDA`, o abres un *issue*, y sigues. **Atorarse no baja la nota. Quedarse callado sí.**

---

## Plan B · Si tu Oracle local no arrancó

Todo lo de las partes A, B, C y D se puede hacer en **[FreeSQL](https://freesql.com)** sin instalar nada: son tablas, `INSERT … SELECT` y consultas. **No necesitas Oracle local para nada de eso**, y es donde están 85 de los 100 puntos.

1. Corre el script del día en FreeSQL y haz A, B, C y D completas.
2. Para la parte E, ponte con un compañero: la conexión se hace en una sola máquina y cada quien entrega su captura diciendo en un comentario que fue en pareja y con quién.
3. Contesta **todas** las preguntas de la parte F.

**Con el Plan B completo se llega a 90 de 100.** Hoy la instalación ya no es el tema; el tema es el modelo.

---

## Rúbrica (100 puntos)

| Criterio | Pts |
|---|---|
| Parte A: la vista plana reconstruida, 9 filas y 30 550, y A3 contestada | 10 |
| Parte B: las tres dimensiones creadas y cargadas, 3 / 6 / 30 | 20 |
| Parte C: `h_cosecha` con su grano escrito, 9 filas y 30 550, y el desglose por cultivo | 20 |
| **Parte D: el 19 750 provocado, los 3 huérfanos detectados, el `ORA-02298` pegado y el modelo arreglado a 30 550** | **30** |
| Parte E: las cuatro tablas en Power BI, las tres relaciones y la captura del Modelo | 10 |
| Parte F: las cinco preguntas con criterio | 10 |

Los criterios suman **100** exactos.

> **Lo que más se califica hoy no es que hayas construido la estrella.** Es la parte D: que hayas visto un número equivocarse **sin que nada avisara**, y que sepas cuál es la consulta de tres líneas que lo atrapa.
