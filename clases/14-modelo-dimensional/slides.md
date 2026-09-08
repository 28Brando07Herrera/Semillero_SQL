---
marp: true
paginate: true
theme: default
title: "Clase 14 · Del reporte plano al modelo dimensional"
style: |
  section { font-family: system-ui, -apple-system, "Segoe UI", sans-serif; font-size: 26px; background: #fbfbfa; color: #1f2933; padding: 60px 70px; }
  section.lead { background: #16324f; color: #f4f7fa; }
  section.lead h1 { color: #ffffff; font-size: 54px; line-height: 1.1; }
  section.lead h2 { color: #7fb3d5; font-weight: 400; font-size: 30px; }
  h1 { color: #16324f; font-size: 40px; border-bottom: 3px solid #f2a104; padding-bottom: 10px; }
  h2 { color: #1c7293; font-size: 32px; }
  strong { color: #b3541e; }
  code { background: #eef2f6; padding: 1px 6px; border-radius: 4px; }
  pre { background: #16324f; border-radius: 8px; font-size: 20px; }
  pre code { background: transparent; color: #e8eef4; }
  table { font-size: 23px; }
  th { background: #16324f; color: #fff; }
  blockquote { border-left: 5px solid #f2a104; color: #4a5568; font-style: normal; }
  footer { color: #8a99a8; font-size: 16px; }
footer: "Curso de SQL · AgroDB · Clase 14"
---

<!-- _class: lead -->

# La estrella

## Del reporte plano al modelo dimensional

Clase 14 · 28 de agosto

---

# Lo que quedó ayer

Ayer terminaron con esto, y funcionó:

```sql
CREATE OR REPLACE VIEW v_bi_produccion AS
SELECT f.nombre AS finca, l.codigo AS lote, cu.nombre AS cultivo,
       s.estado AS estado_siembra, co.fecha AS fecha_cosecha,
       co.calidad, co.kg
  FROM cosechas co
  JOIN siembras s  ON s.siembra_id  = co.siembra_id
  JOIN lotes    l  ON l.lote_id     = s.lote_id
  JOIN fincas   f  ON f.finca_id    = l.finca_id
  JOIN cultivos cu ON cu.cultivo_id = s.cultivo_id;
```

**9 filas. 30 550 kilos.** El tablero dio el número correcto.

<br>

> Hoy no venimos a decir que estuvo mal. **Venimos a ver qué pasa cuando esas 9 filas son 9 millones.**

---

# Tres cosas que esa vista hace mal

| # | Qué pasa | Por qué duele |
|---|---|---|
| 1 | `Hacienda Santa Rosa` se escribe **4 veces** | con 9 millones de filas, se escribe 4 millones de veces |
| 2 | La fecha es **una fecha y ya** | «kilos por trimestre» obliga a calcular el trimestre en cada consulta |
| 3 | Filtrar por finca es **comparar texto** | un espacio de más y la finca desaparece del reporte |

<br>

Los tres son el mismo problema: **la vista mezcla lo que se mide con lo que describe.**

---

# Hecho y dimensión

Es todo el vocabulario del día. Son dos palabras.

| | **Hecho** | **Dimensión** |
|---|---|---|
| Qué guarda | lo que se **mide** | lo que **describe** |
| En AgroDB | los kilos cosechados | la finca, el cultivo, la fecha |
| Cuántas filas | muchas, y crecen todos los días | pocas, y casi no cambian |
| Cómo se lee | se **suma** | se **agrupa** y se **filtra** |

<br>

> Regla práctica: si la columna tiene sentido sumarla, es un **hecho**. Si tiene sentido ponerla en un `GROUP BY`, es una **dimensión**.

---

# Antes de escribir nada: el grano

**El grano es qué representa UNA fila de la tabla de hechos.**

Se decide primero, se escribe en un comentario, y ya no se discute.

<br>

| Si el grano es… | Entonces una fila es… | Y `SUM(kg)` significa… |
|---|---|---|
| una cosecha | un evento de cosecha | kilos cosechados |
| un día y un lote | el total de ese día | kilos por día |
| una siembra | toda la campaña | kilos de la campaña |

<br>

**Hoy el grano es: una fila por cosecha.** Nueve filas, igual que ayer.

> Elegir mal el grano no da error. Da un `SUM` que nadie puede explicar. **Es el fan-out de la clase 5, con otro nombre.**

---

# La estrella de AgroDB

Cuatro tablas. Una al centro, tres alrededor.

```
        dim_finca            dim_cultivo
       finca_id  PK          cultivo_id  PK
       finca                 cultivo
       provincia             tipo
             \                  /
              \                /
               +-- h_cosecha --+
                   cosecha_id  PK
                   finca_id    -> dim_finca
                   cultivo_id  -> dim_cultivo
                   fecha       -> dim_tiempo
                   kg          <-- LO QUE SE SUMA
                        |
                   dim_tiempo
                   fecha  PK
                   anio / mes / trimestre
```

> Se llama **estrella** por el dibujo. El centro es el hecho; las puntas, las dimensiones.

---

# Paso 1 · La dimensión de fincas

```sql
CREATE TABLE dim_finca (
  finca_id  NUMBER       PRIMARY KEY,
  finca     VARCHAR2(60) NOT NULL,
  provincia VARCHAR2(40) NOT NULL
);
```

<br>

Tres filas. **Tres.** Y con eso desaparece el problema 1 de la diapositiva 3: el nombre de la finca se guarda **una sola vez**, y el hecho guarda un número.

<br>

> Fíjense en lo que **no** tiene: no tiene `hectareas`, no tiene `fecha_registro`, no tiene `responsable`. Una dimensión no es una copia de la tabla operativa: **es lo que el reporte necesita**, y nada más.

---

# Paso 2 · La dimensión de cultivos

```sql
CREATE TABLE dim_cultivo (
  cultivo_id NUMBER       PRIMARY KEY,
  cultivo    VARCHAR2(40) NOT NULL,
  variedad   VARCHAR2(40),
  tipo       VARCHAR2(20) NOT NULL
);
```

<br>

Seis filas. Pero **sólo cuatro cultivos tienen cosechas**: Banano y Café todavía no cosecharon nada.

<br>

> Que la dimensión tenga filas que el hecho no usa **está bien**. Es lo que permite que un reporte muestre «Café: 0 kg» en vez de no mostrar Café. Lo que **nunca** está bien es al revés, y de eso se trata la segunda mitad de la clase.

---

# Paso 3 · La dimensión de tiempo

```sql
CREATE TABLE dim_tiempo (
  fecha      DATE        PRIMARY KEY,
  anio       NUMBER(4)   NOT NULL,
  mes        NUMBER(2)   NOT NULL,
  nombre_mes VARCHAR2(20) NOT NULL,
  trimestre  NUMBER(1)   NOT NULL
);
```

**¿Por qué una tabla, si el año se saca con `EXTRACT`?**

| Con `EXTRACT` en cada consulta | Con `dim_tiempo` |
|---|---|
| cada quien lo escribe a su manera | está escrito una vez |
| no existen los días sin cosecha | existen los 365 días |
| «trimestre fiscal» no se puede | es una columna más |

> El calendario es **un dato del negocio**, no una función del motor.

---

# Paso 4 · La tabla de hechos

```sql
CREATE TABLE h_cosecha (
  cosecha_id NUMBER       PRIMARY KEY,
  finca_id   NUMBER       NOT NULL,
  cultivo_id NUMBER       NOT NULL,
  fecha      DATE         NOT NULL,
  calidad    VARCHAR2(20) NOT NULL,
  kg         NUMBER(10,2) NOT NULL
);
```

<br>

**Grano: una fila por cosecha.** Escrito ahí arriba, en la tabla, no en la cabeza de alguien.

<br>

> Miren bien lo que **le falta** a esta tabla, porque en veinte minutos va a ser el tema: **no tiene ni una sola clave foránea.** Así se cargan casi todos los modelos de BI del mundo. Guarden la observación.

---

# Paso 5 · Cargar las dimensiones

```sql
INSERT INTO dim_finca (finca_id, finca, provincia)
SELECT finca_id, nombre, provincia FROM fincas;

INSERT INTO dim_cultivo (cultivo_id, cultivo, variedad, tipo)
SELECT cultivo_id, nombre, variedad, tipo FROM cultivos;

INSERT INTO dim_tiempo (fecha, anio, mes, nombre_mes, trimestre)
SELECT d, EXTRACT(YEAR FROM d), EXTRACT(MONTH FROM d),
       TO_CHAR(d,'Month'), TO_NUMBER(TO_CHAR(d,'Q'))
  FROM (SELECT DATE '2026-01-01' + LEVEL - 1 AS d
          FROM dual CONNECT BY LEVEL <= 365);
```

**3, 6 y 365 filas.** El `CONNECT BY` es el mismo de las 8 640 lecturas.

> `TO_CHAR(d,'Month')` puede salir en inglés o en español según el `NLS` de su máquina. **No es un error y no es parte del control.**

---

# Paso 6 · Cargar los hechos

```sql
INSERT INTO h_cosecha (cosecha_id, finca_id, cultivo_id, fecha, calidad, kg)
SELECT co.cosecha_id, f.finca_id, cu.cultivo_id,
       TRUNC(co.fecha), co.calidad, co.kg
  FROM cosechas co
  JOIN siembras s  ON s.siembra_id  = co.siembra_id
  JOIN lotes    l  ON l.lote_id     = s.lote_id
  JOIN fincas   f  ON f.finca_id    = l.finca_id
  JOIN cultivos cu ON cu.cultivo_id = s.cultivo_id;
```

**El JOIN de cinco tablas se escribe UNA vez, aquí.** Después nadie lo vuelve a escribir.

<br>

> Ese `TRUNC` no está de adorno. En Oracle **un `DATE` trae la hora adentro**. Si una cosecha tuviera hora `14:30`, no empataría con ningún día de `dim_tiempo`, que son todos a medianoche. **Cero filas, cero error.**

---

# Punto de control

```sql
SELECT COUNT(*) AS filas, SUM(kg) AS kilos FROM h_cosecha;
```

**9 filas. 30 550 kilos.** El mismo número desde la clase 5.

<br>

Y ahora la consulta que antes costaba cinco `JOIN`:

```sql
SELECT df.finca, SUM(h.kg) AS kilos
  FROM h_cosecha h
  JOIN dim_finca  df ON df.finca_id = h.finca_id
  JOIN dim_tiempo dt ON dt.fecha    = h.fecha
 GROUP BY df.finca ORDER BY kilos DESC;
```

| Finca | Kilos |
|---|---|
| Finca El Guayabo | **14 250** |
| Hacienda Santa Rosa | **14 200** |
| Agricola La Union | **2 100** |

---

# Y ahora la trampa del día

Alguien construyó `dim_tiempo` así, y es un error **razonable**:

```sql
--  "las lecturas de AgroDB son de abril, con abril alcanza"
INSERT INTO dim_tiempo (fecha, anio, mes, nombre_mes, trimestre)
SELECT d, 2026, 4, 'Abril', 2
  FROM (SELECT DATE '2026-04-01' + LEVEL - 1 AS d
          FROM dual CONNECT BY LEVEL <= 30);
```

Corren **exactamente la misma consulta** de la diapositiva anterior:

| Finca | Kilos | |
|---|---|---|
| Finca El Guayabo | 14 250 | igual |
| Hacienda Santa Rosa | **4 600** | ayer eran 14 200 |
| Agricola La Union | **900** | ayer eran 2 100 |
| **Total** | **19 750** | **faltan 10 800 kilos** |

---

# ¿Y qué error dio?

## Ninguno.

<br>

- El `INSERT` de las dimensiones entró bien.
- El `INSERT` de los hechos entró bien: **las 9 filas están en `h_cosecha`.**
- La consulta corrió sin una advertencia.
- La gráfica se dibujó completa, con sus tres barras.

<br>

**El `JOIN` con `dim_tiempo` es un `INNER JOIN`.** Las tres cosechas de marzo no tienen día en el calendario, así que el `JOIN` las descarta. Silenciosamente. Como debe ser: eso es lo que un `INNER JOIN` hace.

> Y las barras se ven perfectas, porque **el error no está en los datos: está en el calendario.**

---

# Cómo se detecta

La pregunta no es «¿está bien?». Es **«¿qué hecho no encontró su dimensión?»**

```sql
SELECT h.cosecha_id, h.fecha, h.kg
  FROM h_cosecha h
  LEFT JOIN dim_tiempo dt ON dt.fecha = h.fecha
 WHERE dt.fecha IS NULL;
```

**3 filas. 10 800 kilos huérfanos.**

<br>

Y la versión de una línea, la que va en el guion de carga de todos los días:

```sql
SELECT (SELECT SUM(kg) FROM cosechas) AS origen,
       (SELECT SUM(h.kg) FROM h_cosecha h
          JOIN dim_tiempo dt ON dt.fecha = h.fecha) AS estrella
  FROM dual;
```

> **Si esos dos números no son iguales, el modelo miente.** Es el `LEFT JOIN ... IS NULL` de la clase 5, aplicado a un almacén.

---

# La restricción que sí avisa

`h_cosecha` no tenía claves foráneas. Pónganle una:

```sql
ALTER TABLE h_cosecha
  ADD CONSTRAINT fk_h_cosecha_tiempo
  FOREIGN KEY (fecha) REFERENCES dim_tiempo(fecha);
```

Con el calendario incompleto, Oracle **se niega**:

```
ORA-02298: no se puede validar (AGRO.FK_H_COSECHA_TIEMPO)
           - claves primarias no encontradas
```

<br>

> **Esta es la clase entera en dos diapositivas.** Sin la restricción: un número más chico y nadie se entera. Con la restricción: un error, con nombre, en el momento de cargar.
>
> Es exactamente lo de la clase 10: *cinco filas imposibles cargadas con las claves apagadas.*

---

# Paso 7 · Que el tablero lo vea

Cuatro tablas en vez de una vista. Cuatro `GRANT`:

```sql
GRANT SELECT ON dim_finca   TO bi_agro;
GRANT SELECT ON dim_cultivo TO bi_agro;
GRANT SELECT ON dim_tiempo  TO bi_agro;
GRANT SELECT ON h_cosecha   TO bi_agro;
```

En Power BI se cargan **las cuatro**, y en la vista **Modelo** se dibujan las relaciones:

| De | A | Cardinalidad |
|---|---|---|
| `h_cosecha[finca_id]` | `dim_finca[finca_id]` | muchos a uno |
| `h_cosecha[cultivo_id]` | `dim_cultivo[cultivo_id]` | muchos a uno |
| `h_cosecha[fecha]` | `dim_tiempo[fecha]` | muchos a uno |

> Ayer Power BI recibió **una tabla**. Hoy recibe **un modelo**. Es la misma diferencia que hay entre un reporte y un tablero.

---

# Estrella o copo de nieve

Se podría normalizar `dim_finca` sacando `provincia` a su propia tabla. Eso es un **copo de nieve**.

| | Estrella | Copo de nieve |
|---|---|---|
| Tablas | pocas, anchas | muchas, angostas |
| Repetición | sí, y a propósito | poca |
| `JOIN` por consulta | uno por dimensión | varios encadenados |
| Quien lo lee | cualquiera | quien conoce el modelo |

<br>

> Hoy hacemos **estrella**, y la razón es la de siempre: **tres provincias repetidas tres veces no le cuestan nada a nadie**, y cada `JOIN` que se ahorra es un lugar menos donde equivocarse.

---

# Los errores que van a ver hoy

| Mensaje o síntoma | Qué pasó | Arreglo |
|---|---|---|
| El total da **19 750** | `dim_tiempo` no cubre marzo | genera los 365 días de 2026 |
| El total da **0** | `TRUNC` olvidado, o el año equivocado | compara `h.fecha` contra `dim_tiempo` |
| `ORA-02298` al crear la FK | **está bien: te atrapó** | arregla `dim_tiempo` y vuelve a crearla |
| `ORA-00001` al cargar `dim_tiempo` | la corriste dos veces | `DELETE FROM dim_tiempo;` y de nuevo |
| `ORA-01722: invalid number` | `TO_NUMBER(TO_CHAR(d,'Q'))` mal escrito | la `Q` va entre comillas simples |
| En Power BI las barras se duplican | falta una relación, o está al revés | vista **Modelo**, muchos a uno hacia la dimensión |
| `ORA-00942` como `bi_agro` | faltan los cuatro `GRANT` | los da `agro`, que es el dueño |

---

<!-- _class: lead -->

# La idea del día

## Una dimensión incompleta no da error. Da un número más chico.

<br>

Hoy el modelo estaba bien, los datos estaban bien, las nueve cosechas estaban cargadas, y el tablero decía **19 750**.

<br>

**Práctica:** construyan la estrella, provoquen el 19 750 a propósito, detéctenlo con el `LEFT JOIN`, y arréglenlo.

**El número que tiene que salir es 30 550. Otra vez.**
