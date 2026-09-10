# Ejercicio práctico 18 · Mándale el tablero al gerente de La Unión sin enseñarle lo de los demás
**Duración: 2 horas · Individual · Solo Power BI Desktop · Entrega: un archivo `.md` y una captura**

---

## Qué vas a lograr hoy

1. Crear un **rol** de seguridad a nivel de fila y probarlo con **Ver como**, sin publicar nada.
2. Poner el rol **donde es obvio** —en la tabla de cosechas— y ver que los kilos se recortan bien.
3. Encontrar, a propósito, lo que ese rol **no protege**: el gerente de La Unión lee **8,59 %** en vez de **42,00 %**, y ve **la meta de las otras dos fincas**.
4. Atraparlo con la medida que escribiste ayer, `[Filas de meta]`, y con la prueba de poner la dimensión en las filas.
5. **Mover el rol a la dimensión** y comprobar que ahora sí llega a los dos hechos.
6. Ver que lo que el rol esconde **tampoco lo ve DAX**, y que eso no es un error sino una decisión.

**El número que prueba que el rol quedó bien es 42,00 %, viendo como La Union.** El que prueba que entendiste la clase es que sepas por qué con el rol en `h_cosecha` salía 8,59 %.

---

## Antes de empezar

Cuarta clase seguida sin motor: hoy tampoco se prende Oracle, ni Docker, ni el driver.

| | |
|---|---|
| Oracle, Docker, OCMT, `GRANT` | **no** |
| Power BI Desktop | **sí**, y es lo único |

### Hoy no se baja nada

**Los cinco CSV son los de ayer, sin cambios.** Usa el `.pbix` de la clase 17: todo lo de hoy se construye encima.

> **Si tu `.pbix` de ayer quedó a medias**, los cinco archivos siguen en [`datos/csv_clase17/`](../../datos/csv_clase17/). Rehaz las relaciones y las medidas de la 16 y la 17 antes de empezar; cuesta unos veinticinco minutos.

### Lo que tiene que estar funcionando antes de empezar

- Las cinco tablas y las **cinco relaciones**, todas **muchos a uno**, en una sola dirección
- `dim_tiempo` marcada como tabla de fechas
- Las medidas de ayer: `[Kilos]`, `[Cosechas]`, `[Meta]`, `[Cumplimiento]` y `[Filas de meta]`
- Con segmentadores en `anio` = 2026 y `mes` en 1–4: `[Kilos]` = **30 550**, `[Meta]` = **24 440**, `[Cumplimiento]` = **125,00 %**

> **Revisa que ninguna relación esté en «Ambas» direcciones.** Si ayer alguien prendió el bidireccional para probar, hoy te va a cambiar los números de la parte C. Vista **Modelo** → doble clic en cada relación → **Dirección del filtro cruzado: Único**.

---

## Cómo se entrega

En `entregas/apellido-nombre/`, por *pull request*, **dos archivos**:

| Archivo | Qué lleva |
|---|---|
| `Ejercicio18_Apellido_Nombre.md` | **cada rol y cada medida en un bloque de código**, y debajo el valor que te dio, más las respuestas de la parte G |
| `clase18-ver-como.png` | captura con **Ver como** prendido mostrando **las dos tablas por finca**: la de tres filas (rol en `h_cosecha`) y la de una fila (rol en `dim_finca`) |

Formato de cada respuesta, para que se pueda corregir:

````
### B1 · Rol Gerente La Union (primera versión)

```
Tabla:     h_cosecha
Condición: [finca_id] = 3
```

Viendo como Gerente La Union, [Kilos]: 2100
````

> **Un rol o una medida sin su resultado anotado abajo no cuenta.** Y el `.pbix` no se entrega: el repositorio lo ignora a propósito.

---

## Parte A · La foto sin seguridad (15 min)

Antes de esconder nada, anota lo que ve alguien **sin rol**. Es la referencia contra la que vas a comparar todo el día.

Segmentadores en `anio` = 2026 y `mes` en 1, 2, 3 y 4. **No los muevas en toda la práctica.**

### A1. La tabla por finca

Inserta una **tabla** con `dim_finca[finca]`, `[Kilos]`, `[Cosechas]`, `[Meta]`, `[Filas de meta]` y `[Cumplimiento]`.

> ### ✅ Punto de control 1
> | Finca | `[Kilos]` | `[Cosechas]` | `[Meta]` | `[Filas de meta]` | `[Cumplimiento]` |
> |---|---|---|---|---|---|
> | Agricola La Union | 2 100 | 2 | 5 000 | 4 | **42,00 %** |
> | Finca El Guayabo | 14 250 | 3 | 9 440 | 4 | **150,95 %** |
> | Hacienda Santa Rosa | 14 200 | 4 | 10 000 | 4 | **142,00 %** |
> | **Total** | **30 550** | **9** | **24 440** | **12** | **125,00 %** |
>
> **Pega la tabla completa.** Esa fila de La Unión, con su **42,00 %**, es lo que el gerente debería ver al final del día.

**A2.** En una línea: el requisito del gerente es *«que vea su finca, y nada más»*. Mirando esta tabla, **¿qué columnas contienen información de las otras fincas?**

---

## Parte B · El rol obvio (20 min)

### B1. Crea el rol

**Modelado → Administrar roles → Nuevo**. Nómbralo `Gerente La Union`.

Elige la tabla **`h_cosecha`** y escribe la condición:

```
[finca_id] = 3
```

> Si tu versión de Power BI muestra un editor de clics en vez de una caja de texto, busca **Cambiar a editor DAX**. Si no existe en tu versión, arma la misma condición con los menús y **anota cómo se llaman**: eso puntúa.

Guarda el rol.

### B2. Ver como

**Modelado → Ver como →** marca **`Gerente La Union`** → Aceptar.

Aparece una barra avisando que estás viendo el informe como ese rol. **Déjala prendida hasta que la parte C diga lo contrario.**

Pon cuatro **tarjetas**: `[Kilos]`, `[Cosechas]`, `[Meta]` y `[Cumplimiento]`.

> ### ✅ Punto de control 2
> | Medida | Viendo como Gerente La Union |
> |---|---|
> | `[Kilos]` | **2 100** |
> | `[Cosechas]` | **2** |
> | `[Meta]` | **24 440** |
> | `[Cumplimiento]` | **8,59 %** |
>
> **Pega las cuatro.**

**B3.** Antes de seguir leyendo, contesta en un comentario: **¿qué mensaje de error o advertencia dio Power BI?**

**B4.** En una línea: `[Kilos]` dice 2 100 y `[Cosechas]` dice 2, que es exactamente La Unión. Si solo hubieras mirado esas dos tarjetas, **¿habrías dado el rol por bueno?**

**B5.** En dos líneas: en la parte A La Unión iba en **42,00 %**. Con su propio rol, el gerente lee **8,59 %**. **¿Contra qué meta se está comparando?** Y ese 8,59 % ya lo habías visto ayer: **¿dónde?**

---

## Parte C · La fuga (25 min) — es la parte que más vale

Sigue con **Ver como** prendido en `Gerente La Union`.

### C1. La finca en las filas

Vuelve a la tabla de la parte A. **No le cambies nada**: solo mírala con el rol puesto.

> ### ✅ Punto de control 3
> | Finca | `[Kilos]` | `[Cosechas]` | `[Meta]` | `[Filas de meta]` | `[Cumplimiento]` |
> |---|---|---|---|---|---|
> | Agricola La Union | 2 100 | 2 | 5 000 | 4 | 42,00 % |
> | Finca El Guayabo | *(vacío)* | *(vacío)* | **9 440** | **4** | *(vacío)* |
> | Hacienda Santa Rosa | *(vacío)* | *(vacío)* | **10 000** | **4** | *(vacío)* |
> | **Total** | **2 100** | **2** | **24 440** | **12** | **8,59 %** |
>
> **Pega las cuatro filas.** Si en tu Power BI `[Cumplimiento]` sale **0,00 %** en vez de vacío en las dos fincas sin kilos, **anótalo** y sigue.

**C2.** En dos líneas: el gerente de La Unión está viendo **tres filas**. **¿Qué información de las otras dos fincas tiene en pantalla?** Sé específico: nombres, números y columnas.

**C3.** En una línea: ¿por qué aparecen **Finca El Guayabo** y **Hacienda Santa Rosa** si sus kilos están vacíos? (Ayer pasó lo mismo con Banano y Café.)

### Un segmentador de fincas

Agrega un **segmentador** con `dim_finca[finca]`, todavía viendo como el gerente.

**C4.** En una línea: **¿cuántas fincas ofrece el segmentador?**

### C5. El aviso de ayer

Compara `[Cosechas]` y `[Filas de meta]` en la fila de **Total**, sin rol (parte A) y con rol (parte C):

> ### ✅ Punto de control 4
> | Medida | Sin rol | Viendo como Gerente La Union |
> |---|---|---|
> | `[Cosechas]` | 9 | **2** |
> | `[Filas de meta]` | 12 | **12** |
>
> **Pégalo.** `[Cosechas]` se recortó. `[Filas de meta]` no se movió.

**C6.** En dos líneas, y es la pregunta de la clase: el rol **sí** filtra `h_cosecha`. **¿Por qué no filtra `h_meta`?** Explícalo con las relaciones del modelo: de qué tabla a qué tabla viaja un filtro, y en qué sentido.

**C7.** En una línea: escribe la **regla de detección** del día, tomando como base la de ayer (*«si una medida vale lo mismo en todas las filas, esa dimensión no le llega»*).

---

## Parte D · Los otros dos gerentes (10 min)

### D1. Dos roles más, igual de mal puestos

Crea `Gerente El Guayabo` (`h_cosecha`, `[finca_id] = 2`) y `Gerente Santa Rosa` (`h_cosecha`, `[finca_id] = 1`).

Con **Ver como**, marca **uno a la vez** y anota la tarjeta de `[Cumplimiento]`.

> ### ✅ Punto de control 5
> | Viendo como… | `[Cumplimiento]` | Lo que debería ver (parte A) |
> |---|---|---|
> | Gerente La Union | **8,59 %** | 42,00 % |
> | Gerente El Guayabo | **58,31 %** | 150,95 % |
> | Gerente Santa Rosa | **58,10 %** | 142,00 % |
>
> **Pega las tres.**

**D2.** Suma los tres porcentajes de la columna del medio: 8,59 + 58,31 + 58,10. **¿Cuánto da, y con qué número de ayer coincide?**

**D3.** En una línea: el gerente de El Guayabo va **cincuenta puntos arriba** de su meta. **¿Qué decisión podría tomar si le mandas este tablero?**

**D4.** En una línea: marca **dos roles a la vez** en Ver como. **¿Qué pasa con `[Kilos]`?** (Los roles se suman, no se intersectan.)

---

## Parte E · El rol en la dimensión (20 min)

Quita **Ver como** antes de editar los roles.

### E1. Mueve la condición

En **Administrar roles**, para cada uno de los tres roles:

1. **Borra** la condición que está en `h_cosecha`.
2. Escribe la condición en **`dim_finca`**:

```
Gerente La Union     dim_finca    [finca] = "Agricola La Union"
Gerente El Guayabo   dim_finca    [finca] = "Finca El Guayabo"
Gerente Santa Rosa   dim_finca    [finca] = "Hacienda Santa Rosa"
```

> Los nombres van **exactamente** como están en el CSV: sin acentos, con mayúsculas. Si escribes `Agrícola La Unión`, el rol va a esconder **todo** y no va a dar error.

### E2. Ver como, otra vez

**Ver como → `Gerente La Union`**. Mira la misma tabla de siempre.

> ### ✅ Punto de control 6
> | Finca | `[Kilos]` | `[Cosechas]` | `[Meta]` | `[Filas de meta]` | `[Cumplimiento]` |
> |---|---|---|---|---|---|
> | Agricola La Union | 2 100 | 2 | **5 000** | **4** | **42,00 %** |
> | **Total** | **2 100** | **2** | **5 000** | **4** | **42,00 %** |
>
> **Pega la tabla.** Una sola finca. Y el segmentador de fincas ofrece **una sola opción**.
>
> **Deja esta tabla lista para la captura**, junto a la de tres filas del punto de control 3.

**E3.** En una línea: los kilos dicen **2 100** con el rol en `h_cosecha` y con el rol en `dim_finca`. **¿Qué te dice eso sobre la tarjeta de kilos como prueba de que un rol funciona?**

### E4. Los tres gerentes

Ver como, uno a la vez:

> ### ✅ Punto de control 7
> | Viendo como… | `[Meta]` | `[Filas de meta]` | `[Cumplimiento]` |
> |---|---|---|---|
> | Gerente La Union | 5 000 | 4 | **42,00 %** |
> | Gerente El Guayabo | 9 440 | 4 | **150,95 %** |
> | Gerente Santa Rosa | 10 000 | 4 | **142,00 %** |
>
> **Pega las tres filas.** Iguales a las de la parte A, que es lo que se buscaba.

**E5.** En dos líneas: la condición es casi la misma y lo único que cambió es **de qué tabla cuelga**. Mañana llega una tercera tabla de hechos, `h_jornales`, con su `finca_id`. **¿Qué pasa con la seguridad si el rol está en `dim_finca`? ¿Y si estuviera en `h_cosecha`?**

---

## Parte F · Lo que el rol no deja ver, tampoco lo ve DAX (20 min)

### F1. La participación

```
Participacion = DIVIDE( [Kilos] , CALCULATE( [Kilos] , ALL( dim_finca ) ) )
```

Dale formato de **porcentaje con dos decimales**. Agrégala a la tabla por finca y **quita Ver como**.

> ### ✅ Punto de control 8
> | Finca | `[Participacion]` sin rol |
> |---|---|
> | Agricola La Union | **6,87 %** |
> | Finca El Guayabo | **46,64 %** |
> | Hacienda Santa Rosa | **46,48 %** |
> | **Total** | **100,00 %** |
>
> **Pega las cuatro filas.** Las tres suman **99,99** por el redondeo; el total dice 100,00 %.

### F2. Con el rol

**Ver como → `Gerente La Union`**.

> ### ✅ Punto de control 9
> | Finca | `[Participacion]` viendo como Gerente La Union |
> |---|---|
> | Agricola La Union | **100,00 %** |
> | **Total** | **100,00 %** |
>
> **Pégalo.**

**F3.** En dos líneas: `ALL( dim_finca )` quita el filtro de finca, y aun así el total de la empresa **no apareció**. **¿Por qué `ALL` no puede traer las filas de las otras fincas?** (Piensa en la diferencia entre un segmentador y un rol.)

**F4.** En dos líneas: el gerente de La Unión **necesita** saber que su finca es el 6,87 % de la empresa. **¿Se arregla con una fórmula?** Si no, ¿quién tiene que decidir qué, antes de que alguien toque DAX?

---

## Parte G · Preguntas de cierre (10 min)

1. En una línea: escribe la regla de dónde se pone un rol de seguridad, y por qué.
2. En dos líneas: en la clase 13, cuando `bi_agro` intentó leer `agro.cosechas`, Oracle contestó **`ORA-00942`**. Hoy el gerente vio lo que no debía y **nadie contestó nada**. **¿Qué tiene de distinto la seguridad en la base y la seguridad en el modelo?**
3. En una línea: probaste los roles con **Ver como**. **¿Qué dos cosas pones en pantalla para probar un rol de verdad**, y cuál es la que no sirve?
4. En dos líneas: ayer una meta se repitió en seis cultivos porque `dim_cultivo` no llegaba a `h_meta`. Hoy la meta de la empresa le llegó al gerente porque el rol no llegaba a `h_meta`. **¿Es el mismo error o son dos?**
5. En una línea: el número malo de la clase 17 fue **24 440 repetido seis veces**; el de hoy, **8,59 %**. **¿Qué medida de una línea atrapó los dos?**

---

## Si algo falla

| Síntoma | Qué pasó | Qué haces |
|---|---|---|
| No encuentras **Administrar roles** | estás en otra pestaña de la cinta | **Modelado**; en algunas versiones está también en **Inicio** |
| Tu editor de roles no deja escribir texto | versión con editor de clics | **Cambiar a editor DAX**, o arma la condición con los menús y anota cómo |
| El rol no se deja guardar | la condición no devuelve verdadero o falso | `[finca_id] = 3`, o `[finca] = "…"` con comillas dobles |
| Creaste el rol y no ves ningún cambio | falta prender **Ver como** | Modelado → Ver como → marca el rol |
| Viendo como, **todo** sale vacío | el nombre de la finca está mal escrito | exactamente `Agricola La Union`, sin acentos |
| Viendo como, `[Kilos]` sigue en 30 550 | el rol no quedó guardado, o marcaste otro | revisa Administrar roles |
| En la parte C salen números distintos | hay una relación en «Ambas» direcciones | Vista Modelo → Dirección del filtro cruzado: **Único** |
| En la parte E siguen saliendo tres fincas | no borraste la condición de `h_cosecha`, o la escribiste en otra tabla | la condición va en `dim_finca` |
| Todo el tablero sigue recortado | olvidaste quitar Ver como | Ver como → desmarca el rol |
| Ves dos fincas con un solo gerente | marcaste dos roles a la vez | se suman: marca uno |
| `[Participacion]` dice 100,00 % con el rol | **así funciona** | **no es un error**, es la parte F |
| Los decimales llevan punto y no coma | configuración regional de tu Windows | **no es un error**, anótalo y sigue |

> ### La regla de los 20 minutos sigue vigente
> Veinte minutos atorado en lo mismo: lo escribes en tu archivo empezando con `DUDA`, o abres un *issue*, y sigues con lo siguiente. **Atorarse no baja la nota. Quedarse callado sí.**

---

## Plan B · Si Power BI Desktop no abre en tu máquina

1. Ponte con un compañero: el tablero se arma en una sola máquina.
2. **Tú escribes todos los roles y las medidas** en tu propio archivo `.md`, con su resultado, y anotas con quién trabajaste.
3. La captura es la misma para los dos, y los dos lo dicen en un comentario.

**Con el Plan B completo se llega a 100 de 100.** Lo que se califica es dónde pusiste el rol y por qué, no de quién era la laptop.

---

## Rúbrica (100 puntos)

| Criterio | Pts |
|---|---|
| Parte A: la tabla sin rol completa, con el 42,00 % de La Unión, y A2 | 10 |
| Parte B: el rol en `h_cosecha`, Ver como, las cuatro tarjetas con el 8,59 %, y B3, B4 y B5 | 15 |
| **Parte C: la tabla de tres filas, el 12 que no se movió, y C2, C3, C4, C6 y C7** | **25** |
| Parte D: los tres gerentes, la suma de 125,00, y D3 y D4 | 10 |
| **Parte E: los tres roles en `dim_finca`, la tabla de una fila, los tres cumplimientos correctos, y E3 y E5** | **20** |
| Parte F: `Participacion` sin y con rol, y F3 y F4 | 10 |
| Parte G: las cinco preguntas con criterio | 10 |

Los criterios suman **100** exactos.

> **Lo que más se califica hoy no es que hayas creado un rol.** Crear un rol son dos clics. Es la parte C: que hayas visto un rol que **sí** filtra los kilos dejar pasar la meta de toda la empresa, y que sepas explicar por qué con las flechas del modelo.
