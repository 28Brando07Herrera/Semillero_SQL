# Guion de clase 11 · PL/SQL sobre Oracle
**Para leer mientras das la clase. No es para los alumnos.**

Una hora de teoría, dos de práctica. El guion está partido por lámina de `slides.md`.
En **negrita** lo que conviene decir textual. En *cursiva*, lo que hacés vos.
Los `[tiempo]` son acumulados desde el arranque.

> **Regla de oro del día:** todo lo que muestres, corrélo en vivo. Es la primera clase
> en un motor que nadie del grupo tocó nunca, y si algo no anda, es mejor que se rompa
> en tu pantalla que en la de ellos.

---

## Antes de que lleguen `[-15 min]`

- [ ] Live SQL abierto y logueado, con `agrodb_oracle_clase11.sql` **ya corrido**. La carga tarda.
- [ ] Una segunda pestaña con Live SQL **vacío**, para hacer la demo de la instalación desde cero.
- [ ] `sqliteonline.com` abierto con `agrodb_clase10.sql` cargado — lo vas a necesitar para las comparaciones lado a lado.
- [ ] La página de resultados abierta en otra pestaña: hay que dar las notas del 8 y del 9 al principio.
- [ ] Comprobado que `SELECT USER FROM dual` devuelve algo presentable en pantalla.

---

## 0 · Las notas, primero `[0 → 8 min]`

*Abrí la página de resultados y compartí pantalla.*

**«Antes de empezar con lo de hoy: están las notas del 8 y del 9.»**

Tres cosas y seguimos:

1. **El ejercicio 9 es el mejor del curso.** Promedio 99,2. Las cinco entregas corren completas, las cinco leyeron el plan, las cinco entendieron la trampa del `DATE()`. **Díganlo en voz alta porque no va a volver a pasar seguido.**

2. **Y las cinco se equivocaron en lo mismo.** *Mostrá la tarjeta de la lección del ejercicio 9.*
   **«Los cinco escribieron que con `<= '2026-06-30'` se pierde todo el 30 menos la de medianoche. Se pierden las 48. `'2026-06-30 00:00:00'` no es `'2026-06-30'`: es una cadena que empieza igual y sigue, y la que sigue es más grande. Como `casa` y `casaca`.»**
   **«Uno de ustedes escribió el 48 correcto al lado de la explicación equivocada. Tenía el número medido y la teoría inventada, y no notó que se contradecían. Eso es lo que quiero que se lleven: medir y no comparar contra lo que uno cree es media auditoría.»**

3. **La rúbrica del 8 estaba mal sumada.** Decía 100 y sumaba 105. *Mostralo.*
   **«Es el segundo error del material que aparece corrigiendo. Van dos a cero. Los enunciados también se auditan, y el que los escribe también se equivoca.»**

*Si A-5 está en la sala, no menciones el ejercicio 7 en público. Va por privado.*

---

## 1 · Lead: «La finca compró Oracle» `[8 → 11 min]`

**«Hoy cambia el motor. No cambia el modelo, no cambian los datos, no cambia una sola de las preguntas de negocio. Cambia el idioma.»**

**«Y la pregunta de la clase no es "cómo se escribe en Oracle". Es otra, y es incómoda: en diez clases ustedes aprendieron un montón de cosas. ¿Cuántas eran SQL, y cuántas eran SQLite sin que nadie se los dijera?»**

> No prometas que es fácil ni que es difícil. Prometé que van a descubrir cuál es cuál.

---

## 2 · El golpe: `SELECT 1;` `[11 → 15 min]`

*Live SQL, en vivo, sin red.*

```sql
SELECT 1;
```

*Dejá el error en pantalla tres segundos sin decir nada.*

**«`ORA-00923: FROM keyword not found`. La primera sentencia SQL que aprendieron en la vida, y no corre.»**

```sql
SELECT 1 FROM dual;
```

**«`dual` es una tabla con una fila y una columna que existe solamente para esto. Es fea. Es de 1978. La van a escribir mil veces y se van a acostumbrar en una tarde.»**

---

## 3 · Las cuatro que se rompen `[15 → 22 min]`

*Correlas todas en vivo. Una por una. Que vean los cuatro errores distintos.*

```sql
SELECT COUNT(*) FROM lecturas LIMIT 5;
DROP TABLE IF EXISTS basura;
SELECT DATE(fecha_hora) FROM lecturas WHERE ROWNUM = 1;
```

Después de las tres, pausá y corré la quinta:

```sql
SELECT sensor_id, COUNT(*) FROM lecturas GROUP BY sensor_id;
```

**«Esta corre igual. Letra por letra igual. Y esa es la mitad de la clase de hoy.»**

> **Momento de participación.** Antes de pasar de lámina, preguntá: *«¿qué otra cosa creen que se rompe?»* Anotá tres en el pizarrón, probalas en vivo. Si aciertan, mejor; si se equivocan, mejor todavía.

---

## 4 · La cadena vacía `[22 → 27 min]`

*Esta va lado a lado. sqliteonline en una mitad, Live SQL en la otra.*

```sql
-- SQLite
SELECT CASE WHEN '' IS NULL THEN 'ES null' ELSE 'NO es null' END;
-- Oracle
SELECT CASE WHEN '' IS NULL THEN 'ES null' ELSE 'NO es null' END FROM dual;
```

**«Mismo `CASE`. Respuestas opuestas.»**

**«En Oracle no se puede guardar "un texto de cero caracteres" distinto de "no hay dato". Son la misma cosa. Si tu aplicación distinguía las dos, al migrar perdiste la distinción y nadie te avisó.»**

*Pausa.* **«¿Les suena? Es el error silencioso. Vamos a chocar con él cuatro veces más hoy.»**

---

## 5 · La cicatriz del `* 1.0` `[27 → 32 min]`

**«Desde la clase 5 vienen escribiendo `* 1.0`. Yo se los hice escribir. Se los descontaba si se lo olvidaban.»**

*Corré la consulta del lote 1 SIN el `* 1.0`.*

```
7300    256.140350877192982456140350877192982456
```

**«256.14. El mismo número del ejercicio 8. Sin `* 1.0`.»**

**«El `* 1.0` nunca fue una regla de SQL. Era una defensa contra la división entera de SQLite. Diez clases escribiendo un parche cuyo motivo era del motor, no del lenguaje — y ninguno preguntó nunca por qué.»**

> Este es el momento emocional de la primera media hora. Dale aire. No lo tapes con la lámina siguiente.

---

## 6 · Lo que sí se transfiere `[32 → 36 min]`

*Mostrá el bloque de CTE + `RANK` + `LAG` + `LEFT JOIN`.*

**«Todo esto corre sin tocar una letra. Ventanas, CTE, vistas, índices, planes de ejecución.»**

**«Fíjense en el reparto: lo que se rompe se aprende en una tarde. Lo que se transfiere les costó diez clases. Están del lado bueno de ese trato.»**

---

## 7 · ¿Qué le falta a SQL? `[36 → 40 min]`

**«Segunda mitad. Ahora sí, PL/SQL.»**

**«Pregunta abierta: en diez clases, ¿hubo algún momento en que quisieron hacer algo y SQL no los dejó?»**

> Dejá que contesten. Van a salir cosas del ejercicio 4 («quería probar si el UPDATE andaba antes de aplicarlo») y del 10 («quería que el trigger hiciera dos cosas distintas según el caso»).

Cerrá con la lista: variables, `IF`, bucles, manejo de errores. **«Eso es PL/SQL. Es SQL más las cuatro cosas que le faltaban.»**

---

## 8 · El bloque `[40 → 47 min]`

*Escribilo a mano en Live SQL. No lo pegues.*

```sql
DECLARE
  v_total NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_total FROM lecturas;
  DBMS_OUTPUT.PUT_LINE('lecturas: ' || v_total);
END;
/
```

Tres cosas que subrayar mientras lo escribís:

- **`INTO`** — **«un `SELECT` suelto no existe acá adentro. Si traés algo, lo tenés que guardar en algún lado.»**
- **la `/` sola** — **«no es SQL, es del cliente. Significa: acá terminó, mandalo. Si se la olvidan, el bloque se queda esperando y parece que se colgó.»**
- **`DBMS_OUTPUT`** — pasá a la lámina siguiente.

### La media hora que pierde todo el mundo

*Si estás en local, hacé la demo del olvido: corré un bloque con `PUT_LINE` sin `SET SERVEROUTPUT ON`.*

```
PL/SQL procedure successfully completed.
```

**«¿Y el hola? Corrió bien. Hizo lo que le pediste. Y no ves nada.»**

**«Éxito silencioso. Van tres hoy y no llegamos a la mitad.»**

*(En Live SQL ya viene prendido, así que si estás ahí, contalo en vez de mostrarlo — y avisales que en la máquina de ellos les va a pasar.)*

---

## 9 · `%TYPE` `[47 → 50 min]`

Rápido. Es una lámina de higiene, no de concepto.

**«`v_nombre fincas.nombre%TYPE` en vez de `VARCHAR2(60)`. El día que alguien agrande la columna, tu código se entera solo. Es gratis. Háganlo siempre.»**

---

## 10 · `SELECT INTO` quiere exactamente una fila `[50 → 55 min]`

*Provocá los dos errores en vivo. Con ganas.*

```sql
DECLARE v_n fincas.nombre%TYPE;
BEGIN SELECT nombre INTO v_n FROM fincas WHERE finca_id = 99; END;
/
```
```
ORA-01403: no data found
```

```sql
DECLARE v_n fincas.nombre%TYPE;
BEGIN SELECT nombre INTO v_n FROM fincas; END;
/
```
```
ORA-01422: exact fetch returns more than requested number of rows
```

**«Cero filas: `NO_DATA_FOUND`. Dos o más: `TOO_MANY_ROWS`. Las dos cortan el bloque.»**

**«Y quiero que noten algo: esto es bueno. Es un error que da error. Guarden esa sensación media hora, porque después vamos a ver la alternativa.»**

---

## 11 · Cursor FOR LOOP `[55 → 60 min]`

```sql
FOR r IN (SELECT sensor_id, tipo FROM sensores WHERE activo = 1) LOOP
  DBMS_OUTPUT.PUT_LINE(r.sensor_id || ': ' || r.tipo);
END LOOP;
```

**«Oracle declara la variable solo, abre el cursor, itera y lo cierra. No hay que cerrar nada, no hay que declarar nada.»**

**«Es el 90 % de los bucles que van a escribir en su vida.»**

*Pausa deliberada.*

**«Y también es el 90 % de los bucles que no deberían haber escrito. Eso es lo que sigue.»**

---

## 12 · EL CORAZÓN: row by row is slow by slow `[60 → 75 min]`

> **Esta es la parte que no se puede apurar.** Si vas atrasado, recortá la parte de
> procedimientos y paquetes, nunca esta.

### 12.1 · Los dos motores

**«Adentro de Oracle hay dos cosas distintas. Un motor que ejecuta SQL y un motor que ejecuta PL/SQL. Son dos programas.»**

**«Cada vez que tu bloque PL/SQL ejecuta una sentencia SQL, hay que cambiar de motor. Se llama context switch. No es gratis.»**

*Dibujalo en el pizarrón: dos cajas y una flecha de ida y vuelta.*

### 12.2 · La demo, en vivo, las dos

*Corré la versión del bucle. Que vean el número de centésimas.*

```sql
-- (el bloque de C1 del ejercicio)
```

*Después la de una sola sentencia.*

```sql
-- (el bloque de C2 del ejercicio)
```

**«Mismas 180 filas. Los mismos números, hasta el segundo decimal.»**

*Corré la comprobación de que son idénticas. No lo digas: mostralo.*

### 12.3 · La cuenta

*Al pizarrón. Escribí los números vos, uno por uno.*

```
bucle:        180 sentencias  ×  8.640 filas  =  1.555.200
una sentencia:  1 sentencia   ×  8.640 filas  =      8.640
                                                 ---------
                                                  180 veces
```

**«Ciento ochenta veces más trabajo. Para el mismo resultado. Con los mismos datos.»**

**«Y esto es abril nada más. Con un año, el bucle hace doce veces más vueltas sobre una tabla doce veces más grande: ciento cuarenta y cuatro veces peor. La otra, doce.»**

### 12.4 · El plan no lo muestra — *y esta es la lámina fina*

*Corré los dos `EXPLAIN PLAN`. Que vean que dicen lo mismo.*

**«Los dos planes son idénticos. `TABLE ACCESS FULL` los dos. Ninguno miente.»**

**«El plan te dice cómo se resuelve UNA ejecución. No te dice cuántas veces la vas a ejecutar. Eso lo pone tu bucle, y el optimizador no lo ve.»**

### 12.5 · Cerrá con la clase 9

**«En la clase 9 les dije: el reloj es una anécdota, el plan es la evidencia. ¿Me estoy contradiciendo hoy?»**

> Dejá que contesten. Alguno va a decir que sí. Está bien que lo digan.

**«No. El plan contesta "¿esta consulta está bien resuelta?". El reloj contesta "¿cuántas veces la estoy corriendo?". Son dos preguntas distintas y hacen falta las dos. Lo que era falso en la clase 9 y sigue siendo falso hoy es mirar SOLO el reloj.»**

### 12.6 · El `TRUNC` es el `DATE()` de la clase 9

Rápido, treinta segundos, es un guiño:

**«Y de paso: `TRUNC(fecha_hora)` en el `WHERE` mata el índice, exactamente igual que `DATE(fecha_hora)` en SQLite. Mismo problema, otro motor, otra función.»**

**«Oracle tiene una salida que SQLite no tenía: se puede crear un índice sobre la expresión. Existe, funciona, y sigue siendo mejor no necesitarlo.»**

---

## 13 · Excepciones y la línea más cara de la industria `[75 → 88 min]`

### 13.1 · Las que tienen nombre y las que no

**«`NO_DATA_FOUND`, `TOO_MANY_ROWS`, `DUP_VAL_ON_INDEX`, `ZERO_DIVIDE`: esas tienen nombre.»**

**«La violación de clave foránea, no. El `CHECK`, tampoco. Hay que bautizarlas con `PRAGMA EXCEPTION_INIT`.»**

**«Es más trabajo. Y ese trabajo es exactamente lo que separa "atrapé el error que esperaba" de "atrapé todo lo que pase".»**

### 13.2 · La demo de las cuatro labores — *hacela en vivo, es el clímax*

*Creá `cargar_labor` con su `WHEN OTHERS THEN NULL`. Contá las labores: 19.*

**«Ahora cargo cuatro labores. Cuatro.»**

*Corré el bloque de las cuatro llamadas.*

```
PL/SQL procedure successfully completed.
```

**«Salió bien. Sin un error. Sin una advertencia.»**

*Contá otra vez.*

```
21
```

*Silencio. Que la cuenta la hagan ellos.*

**«Cargué cuatro. Entraron dos.»**

> Si nadie reacciona en cinco segundos, preguntá: *«¿cómo me habría enterado si no hubiera contado antes y después?»* La respuesta correcta es «no te enterabas». Esperala.

### 13.3 · La tabla del curso entero

*Mostrá la lámina de las cuatro clases.*

**«Clase 8: la vista no se reemplazó y no avisó. Clase 9: el `SEARCH` leía media tabla y no avisó. Clase 10: entraron cinco filas imposibles y no avisó. Hoy: dos `INSERT` fallaron y no avisó.»**

**«Los errores que dan error son los baratos. Todo este curso se trata de los otros. Y hoy tienen nombre de línea: `WHEN OTHERS THEN NULL`.»**

### 13.4 · Cómo se escribe bien

Tres cosas, contalas con los dedos:

1. **atrapar por separado lo que esperás**
2. **dejar rastro** (bitácora)
3. **volver a levantarlo** (`RAISE` o `RAISE_APPLICATION_ERROR`)

**«`WHEN OTHERS` sin `RAISE` es casi siempre un bug. No siempre. Pero casi.»**

---

## 14 · Procedimientos, funciones, triggers `[88 → 96 min]`

Esto va rápido: en el ejercicio lo escriben ellos.

- **`PROCEDURE` vs `FUNCTION`:** **«la función se puede llamar adentro de un `SELECT`. El procedimiento no. Esa es la diferencia que importa.»**
- **`CREATE OR REPLACE`:** **«Oracle no tiene `IF NOT EXISTS` — y menos mal, después de la clase 8. Tiene esto, que hace lo que ustedes esperaban que hiciera aquel: reemplaza de verdad.»**
- **Triggers:** `:NEW` y `:OLD` con dos puntos. `INSERTING` / `UPDATING` / `DELETING`.
  **«Y ojo: en un `DELETE` no existe `:NEW`. Si los mezclan sin preguntar, el trigger escribe `NULL` en la mitad de las filas y nadie les avisa.»** *(otra vez)*

---

## 15 · La deuda de la clase 10 `[96 → 100 min]`

*Buscá la diapositiva de la clase 10 y leé la línea textual.*

> *«SQLite no tiene `CURRENT_USER`: el cuándo sale gratis, el quién no existe en el motor.»*

*Silencio. Después:*

```sql
SELECT USER FROM dual;
```

**«Ahí está el quién.»**

**«La bitácora que quedó coja hace tres días se completa hoy con una palabra.»**

*Y enseguida, sin dejar que se entusiasmen demasiado:*

**«Con la misma advertencia de entonces. Sigue sin ver lo anterior al trigger. Sigue sin sobrevivir a un `DROP TRIGGER`. Y si dos personas comparten el usuario de base, sabe el usuario — no sabe la persona. Es más facilidad, no es una garantía.»**

---

## 16 · Cierre y arranque de la práctica `[100 → 105 min]`

*Lámina de «lo de hoy en una línea».*

**«En SQL le pedís un resultado. En PL/SQL le dictás un procedimiento. Y lo hace todo: las vueltas de más y el error que le dijiste que ignore.»**

Consignas de la práctica, en voz alta:

- **«Dos horas. Live SQL, cuenta gratis, tarda dos minutos. El que quiera instalarlo local, la guía está en `recursos/entorno-local-oracle.md` — pero háganlo después de clase, no ahora.»**
- **«El script base va con Run Script, el botón de la hoja. El de "Run" ejecuta una sola sentencia y les va a dar error.»**
- **«Tiene que dar 3, 6, 8, 10, 7, 19, 16, 6, 9, 8640, 0, 0.»**
- **«La parte C vale 30 de los 100 puntos. Es la del bucle contra la sentencia. Si se les acaba el tiempo, que se les acabe en otro lado.»**
- **«Y la regla del día para la entrega: toda medición de tiempo sin la cuenta de filas que la explica se descuenta. El reloj de su máquina no es el mío. El número de filas leídas sí es el mismo para los dos.»**

---

## Preguntas que van a hacer, con respuesta corta

| Van a preguntar | Contestá |
|---|---|
| «¿Entonces nunca hay que usar bucles?» | Cuando cada fila necesita una decisión distinta que SQL no puede expresar. Y ahí, `BULK COLLECT` + `FORALL`. |
| «¿Por qué el `/`?» | Es del cliente, no del motor. Marca dónde termina el bloque, porque adentro hay puntos y comas. |
| «¿`VARCHAR` o `VARCHAR2`?» | `VARCHAR2` siempre. `VARCHAR` existe y Oracle avisa hace treinta años que puede cambiar de comportamiento. |
| «¿Live SQL guarda lo que hago?» | El script sí, la base no del todo: las sesiones se reciclan. Guardá tu `.sql` local. |
| «¿Esto sirve para Postgres / SQL Server?» | El concepto sí (PL/pgSQL, T-SQL). La sintaxis no. Los context switches y el `WHEN OTHERS` son universales. |
| «¿Y Power BI?» | La semana que viene. Hoy es el motor; Power BI es lo que se conecta arriba. |

---

## Si vas atrasado

Recortá en este orden, y solo en este orden:

1. `%TYPE` (lámina 9) — se aprende leyendo el enunciado
2. Procedimientos y funciones (lámina 14) — lo escriben en la parte E igual
3. La cadena vacía (lámina 4) — está en la parte A del ejercicio

**Nunca recortes:** el `* 1.0`, la parte del context switch, ni la demo de las cuatro labores.
Esas tres son la clase.

---

## Después de clase

- [ ] Avisar por privado a A-5 que el ejercicio 7 sigue sin entregar y que es la única nota que puede subir sola.
- [ ] Recordar en el canal que el archivo de entrega arranca en la parte A: no se pega el script base adentro.
- [ ] Anotar cuánto tardó de verdad cada parte, para ajustar el guion la próxima vez.
