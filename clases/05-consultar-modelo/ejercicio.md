# Ejercicio práctico 5 · Las preguntas del jefe de finca
**Duración: 2 horas · Individual · sqliteonline.com · Entrega: un archivo `.sql`**

---

## La situación

El jefe de operaciones pidió un tablero. No sabe SQL y no le interesa: te va a hacer preguntas en castellano y espera números.

El problema es que **casi todas estas consultas se pueden escribir mal y devolver un número igual**. No hay mensaje de error que te avise. Tu trabajo de hoy no es solo escribir las consultas: es **probar que los números que entregás son ciertos**.

## Antes de empezar

1. **Pestaña nueva** en sqliteonline.com → SQLite.
2. Pegá `datos/agrodb_clase5.sql` completo y ejecutalo. Deben salir **3, 6, 8, 10, 7, 19, 16, 6, 9**.
   Ese script trae el ejercicio 4 ya resuelto y la tabla `cosechas` nueva, así que todos arrancan del mismo punto.
3. Trabajá en `Ejercicio5_Apellido_Nombre.sql`.

## La regla del día

> **Antes de cada `SUM`, corré la misma consulta cambiando el `SUM` por `COUNT(*)`.**
>
> Si salen más filas de las que esperabas, el `SUM` está inflado. Dejá el número de filas escrito como comentario, igual que ayer dejabas el `SELECT COUNT(*)` antes del `UPDATE`.

Y una regla de formato: **todo reporte que mencione un lote tiene que decir también la finca.** El código `L-01` existe en dos fincas distintas.

---

## Parte A · Recorrer el modelo (25 min)

**A1.** Catálogo de siembras: nombre de finca, código de lote, cultivo, variedad, fecha de siembra y estado. Una fila por siembra, ordenado por finca y lote.
*Son 4 tablas.* Esperado: **10 filas**. Si te salen más, ya tenés un fan-out.

**A2.** Todas las labores de **abril de 2026** con la finca, el lote y el responsable. Ordenado por fecha.
Esperado: **10 filas**. Fijate qué pasa con el responsable de la labor 18 y explicá en un comentario por qué está vacío (viene de ayer).

**A3.** Detalle de consumo de insumos: para cada labor que usó insumos, mostrá finca, lote, tipo de labor, fecha, nombre del insumo, cantidad, unidad y el **costo de esa línea** (`cantidad * costo_unitario`).
*Son 6 tablas.* Esperado: **16 filas**.

---

## Parte B · El `SUM` que miente (35 min)

Esta es la parte importante del día. Hacela despacio.

**B1.** Kilos cosechados por finca.
Esperado: **Hacienda Santa Rosa 14200 · Finca El Guayabo 14250 · Agricola La Union 2100**.

**B2.** Ahora el jefe pide *"lo mismo, pero agregame cuántas labores llevó cada finca"*. Agregá `JOIN labores` a la consulta de B1, sin tocar nada más, y volvé a mirar los kilos.
Anotá los tres números nuevos como comentario. **No arregles nada todavía.**

**B3.** Demostrá por qué pasó. Dos consultas:

a) Para cada siembra: cuántas labores tiene, cuántas cosechas tiene, y cuántas filas salen al unir las dos.
*Pista:* tres subconsultas en el `SELECT`, o tres CTE.
Esperado para la siembra 1: **3 labores, 2 cosechas, 6 filas**.

b) Sobre la consulta de B2 filtrada a la finca 1, compará `COUNT(*)` contra `COUNT(DISTINCT c.cosecha_id)`.
Esperado: **11 y 4**. Explicá en un comentario qué significa esa diferencia.

**B4.** Arreglalo. Escribí una consulta que dé **los kilos y la cantidad de labores por finca, las dos cosas, correctas**.
*Pista:* agregá cada hijo por separado (una CTE para cosechas, otra para labores) y recién después unilas.
Los kilos deben volver a ser **14200 / 14250 / 2100**.

**B5.** El mismo error, en la otra dirección. Corré estas dos:

```sql
SELECT SUM(costo_mano_obra) FROM labores;
SELECT SUM(lb.costo_mano_obra)
FROM labores lb JOIN labor_insumo li ON li.labor_id = lb.labor_id;
```

Esperado: **2330.00** y **2035.00**. En un comentario, explicá las **dos** cosas que le pasaron a la segunda: qué filas perdió y qué filas contó de más. Contá cuántas labores no tienen ningún insumo (esperado: **7**).

---

## Parte C · Encontrar lo que falta (25 min)

Todas con el patrón `LEFT JOIN` + `WHERE hijo IS NULL`.

**C1.** Lotes sin **ningún** sensor instalado, con su finca. Esperado: **4 lotes**.

**C2.** Lotes sin ningún sensor **activo**. Esperado: **5 lotes**.
Vas a necesitar la condición `activo = 1`. Probá primero ponerla en el `WHERE`, anotá cuántas filas te da, y después movela al `ON`. Explicá la diferencia en un comentario. **Esta es la trampa del día.**

**C3.** Siembras sin ninguna labor registrada, con finca, lote, cultivo y estado. Esperado: **2**.

**C4.** Insumos del catálogo que nunca se usaron en ninguna labor. Esperado: **1**.

**C5.** Siembras en estado `'en produccion'` que **no tienen ninguna cosecha registrada**. Esperado: **1**.
Escribí en un comentario qué le dirías al jefe de finca sobre esa fila. Es la única de todo el ejercicio que es una alarma real.

---

## Parte D · Las preguntas del jefe (25 min)

**D1.** Rendimiento en **kg por hectárea** de cada lote cosechado, ordenado de mayor a menor. Mostrá finca, lote, hectáreas, kilos y el rendimiento redondeado a 2 decimales.

> **Ojo con esta.** Escribila primero como `SUM(c.kg) / l.hectareas` y mirá bien las seis filas: **tres van a salir mal y tres bien.** Anotá cuáles, explicá por qué, y después arreglala.
>
> Top 3 correcto: **El Guayabo L-02 → 529.73 · Santa Rosa L-01 → 256.14 · El Guayabo L-01 → 202.27**

**D2.** Costo total por finca, separado en **mano de obra** e **insumos**, más la suma de los dos.
Esperado: **Santa Rosa 1441.00 · El Guayabo 1024.50 · La Union 1096.80**. El total general debe dar **3562.30**.
*Acordate de B5: acá el fan-out te está esperando.*

**D3.** Dos rankings cortos, una consulta cada uno:
a) Responsables ordenados por cantidad de labores. Arriba debe quedar **Pedro Loor con 5**.
b) Insumos ordenados por costo total consumido. Arriba debe quedar **Urea 46% con 427.00**.

---

## Parte E · Cierre (10 min, comentarios en el archivo)

1. De las tres formas de equivocarse que vimos hoy —el `SUM` inflado, el `JOIN` que borra filas y la división entera— **¿cuál es la más peligrosa en un reporte que ve un gerente?** Justificá en tres líneas.
2. Poné el nombre técnico (1FN, 2FN o 3FN) a cada uno de estos tres arreglos que hicieron en la clase 3:
   - separar `insumo_1, insumo_2, insumo_3` en filas de `labor_insumo`
   - sacar `unidad` a la tabla `insumos`
   - sacar `provincia` a la tabla `fincas`
3. Hay una pregunta de negocio razonable que **AgroDB todavía no puede responder** por cómo está el modelo. Escribí cuál es y qué tabla o columna haría falta.

---

## Rúbrica (100 puntos)

| Criterio | Pts |
|---|---|
| Parte A: las 3 consultas, con los conteos correctos | 15 |
| **Parte B: el fan-out detectado, explicado y corregido en B4** | **30** |
| Parte C: las 5 consultas con `LEFT JOIN` | 20 |
| Parte C2: la diferencia entre `ON` y `WHERE` explicada bien | 5 |
| Parte D: los tres reportes con los números exactos | 20 |
| Preguntas de cierre con criterio | 10 |
| **Extra:** una pregunta de negocio propia + su consulta, que use al menos 4 tablas | +5 |

El archivo debe correr **completo** de arriba abajo después de `datos/agrodb_clase5.sql`.

**Si un `SUM` no tiene su `COUNT(*)` de control escrito como comentario, se descuenta aunque el número esté bien.** El número correcto por casualidad no cuenta.
