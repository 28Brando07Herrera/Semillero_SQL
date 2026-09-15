# Ejercicio práctico 19 · Un solo rol para cuarenta gerentes, y que el practicante no vea nada
**Duración: 2 horas · Individual · Solo Power BI Desktop · Entrega: un archivo `.md` y una captura**

---

## Qué vas a lograr hoy

1. Cargar una **tabla de permisos** (`seguridad.csv`) y usar **`USERPRINCIPALNAME()`** para saber quién está mirando.
2. Probar un rol con **Ver como → Otro usuario**, escribiendo el correo que quieras, sin publicar nada.
3. Poner el rol **donde es obvio** —en la tabla de permisos, donde está el correo— y ver que **no protege nada**: el gerente de La Unión lee **125,00 %** y un practicante sin permisos **ve la empresa entera**.
4. Pasar la condición a **`dim_finca`** con `LOOKUPVALUE`, y romperla a propósito con un usuario que tiene **dos fincas**.
5. Arreglarla con **`IN`** y **`CALCULATETABLE`**, y probarla con los seis correos.
6. Dar de alta a un usuario nuevo **sin tocar el rol**.

**El número que prueba que el rol quedó bien es 113,23 %, viendo como regional.norte.** El que prueba que entendiste la clase es que sepas por qué el practicante veía **30 550** kilos con el rol en `seguridad`.

---

## Antes de empezar

Quinta clase seguida sin motor: hoy tampoco se prende Oracle, ni Docker, ni el driver.

| | |
|---|---|
| Oracle, Docker, OCMT, `GRANT` | **no** |
| Power BI Desktop | **sí**, y es lo único |

### Lo que se baja hoy

**Un archivo nuevo**: [`datos/csv_clase19/seguridad.csv`](../../datos/csv_clase19/seguridad.csv). Los otros cinco de esa carpeta son **los de la clase 17, idénticos byte a byte**: si tu `.pbix` está bien, no los vuelvas a cargar.

Usa el `.pbix` de la clase 18: todo lo de hoy se construye encima.

> **Si tu `.pbix` de ayer quedó a medias**, los seis archivos están en [`datos/csv_clase19/`](../../datos/csv_clase19/). Rehaz las relaciones y las medidas de la 16 y la 17 antes de empezar; cuesta unos veinticinco minutos.

### Lo que tiene que estar funcionando antes de empezar

- Las cinco tablas de ayer y las **cinco relaciones**, todas **muchos a uno**, en una sola dirección
- Las medidas `[Kilos]`, `[Cosechas]`, `[Meta]` y `[Cumplimiento]`
- Segmentadores en `anio` = 2026 y `mes` en 1–4: `[Kilos]` = **30 550**, `[Meta]` = **24 440**, `[Cumplimiento]` = **125,00 %**
- **Ningún rol de ayer.** Modelado → Administrar roles → borra `Gerente La Union`, `Gerente El Guayabo` y `Gerente Santa Rosa`. Si los dejas, Ver como te los va a ofrecer y te vas a confundir de rol.

> **Revisa que ninguna relación esté en «Ambas» direcciones.** Vista **Modelo** → doble clic en cada relación → **Dirección del filtro cruzado: Único**. Hoy la relación nueva también tiene que quedar en Único.

---

## Cómo se entrega

En `entregas/apellido-nombre/`, por *pull request*, **dos archivos**:

| Archivo | Qué lleva |
|---|---|
| `Ejercicio19_Apellido_Nombre.md` | **cada rol y cada medida en un bloque de código**, y debajo el valor que te dio, más las respuestas de la parte G |
| `clase19-ver-como.png` | captura con **Ver como** prendido en `regional.norte@agrodb.test` y el rol final, mostrando **la tarjeta `[Quien mira]`** y **la tabla por finca de dos filas** |

Formato de cada respuesta, para que se pueda corregir:

````
### B1 · Rol Por correo (primera versión)

```
Tabla:     seguridad
Condición: [correo] = USERPRINCIPALNAME()
```

Viendo como gerente.launion@agrodb.test, [Filas de seguridad]: 1
````

> **Un rol o una medida sin su resultado anotado abajo no cuenta.** El `.pbix` no se entrega: el repositorio lo ignora a propósito. Y **no subas tu `seguridad.csv` modificado** de la parte F: esa copia es tuya.

---

## Parte A · La tabla de permisos (15 min)

### A1. Carga y relación

**Inicio → Obtener datos → Texto o CSV →** `seguridad.csv`. Cárgalo.

Vista **Modelo**: revisa que exista la relación `seguridad[finca_id]` → `dim_finca[finca_id]`. Si no se creó sola, créala tú.

> La relación tiene que quedar **Muchos a uno** (`seguridad` en el lado muchos) y **Dirección del filtro cruzado: Único**. Anota en tu archivo si Power BI la creó solo o la tuviste que hacer.

### A2. Dos medidas

```
Quien mira = USERPRINCIPALNAME()
```

```
Filas de seguridad = COUNTROWS( seguridad )
```

Pon `[Quien mira]` en una **tarjeta**. Sin Ver como, dice **tu propia cuenta** (o tu usuario de Windows, si no iniciaste sesión en Power BI). **No hace falta que la pegues**: basta con que anotes que muestra algo.

### A3. La foto sin seguridad

Segmentadores en `anio` = 2026 y `mes` en 1, 2, 3 y 4. **No los muevas en toda la práctica.**

Tabla con `dim_finca[finca]`, `[Kilos]`, `[Cosechas]`, `[Meta]`, `[Filas de seguridad]` y `[Cumplimiento]`.

> ### ✅ Punto de control 1
> | Finca | `[Kilos]` | `[Cosechas]` | `[Meta]` | `[Filas de seguridad]` | `[Cumplimiento]` |
> |---|---|---|---|---|---|
> | Agricola La Union | 2 100 | 2 | 5 000 | 3 | **42,00 %** |
> | Finca El Guayabo | 14 250 | 3 | 9 440 | 3 | **150,95 %** |
> | Hacienda Santa Rosa | 14 200 | 4 | 10 000 | 2 | **142,00 %** |
> | **Total** | **30 550** | **9** | **24 440** | **8** | **125,00 %** |
>
> **Pega la tabla completa.**

**A4.** En una línea: `[Filas de seguridad]` sí se parte por finca (3, 3 y 2). **¿Qué relación hace que `dim_finca` filtre a `seguridad`, y en qué sentido va?**

---

## Parte B · El rol obvio (20 min)

### B1. Crea el rol

**Modelado → Administrar roles → Nuevo**. Nómbralo `Por correo`.

Elige la tabla **`seguridad`** y escribe la condición:

```
[correo] = USERPRINCIPALNAME()
```

> Esta condición usa una función, así que el editor de clics no alcanza: usa **Cambiar al editor DAX**. Si en tu versión se llama distinto, **anota cómo se llama**: eso puntúa.

Guarda el rol.

### B2. Ver como otro usuario

**Modelado → Ver como →** marca **Otro usuario**, escribe `gerente.launion@agrodb.test` y **marca también el rol `Por correo`** → Aceptar.

> **Son dos marcas, no una.** Con Otro usuario y sin el rol, `[Quien mira]` cambia pero no se aplica ninguna seguridad.

Pon tarjetas con `[Quien mira]`, `[Filas de seguridad]`, `[Kilos]`, `[Cosechas]`, `[Meta]` y `[Cumplimiento]`.

> ### ✅ Punto de control 2
> | Medida | Viendo como gerente.launion@agrodb.test |
> |---|---|
> | `[Quien mira]` | **gerente.launion@agrodb.test** |
> | `[Filas de seguridad]` | **1** |
> | `[Kilos]` | **30 550** |
> | `[Cosechas]` | **9** |
> | `[Meta]` | **24 440** |
> | `[Cumplimiento]` | **125,00 %** |
>
> **Pega las seis.**

**B3.** Antes de seguir leyendo, contesta en un comentario: **¿qué mensaje de error o advertencia dio Power BI?**

**B4.** En una línea: `[Filas de seguridad]` bajó de 8 a **1**. **¿Eso prueba que el rol funciona?** ¿Qué prueba, exactamente?

**B5.** En una línea: ayer, con el rol en `h_cosecha`, por lo menos `[Kilos]` bajaba a 2 100. **¿Qué tarjeta se movió hoy, además de `[Quien mira]`?**

---

## Parte C · La fuga (25 min) — es la parte que más vale

Sigue con **Ver como** prendido en `gerente.launion@agrodb.test` y el rol `Por correo`.

### C1. La finca en las filas

Mira la tabla de la parte A. **No le cambies nada.**

> ### ✅ Punto de control 3
> | Finca | `[Kilos]` | `[Cosechas]` | `[Meta]` | `[Filas de seguridad]` | `[Cumplimiento]` |
> |---|---|---|---|---|---|
> | Agricola La Union | 2 100 | 2 | 5 000 | 1 | 42,00 % |
> | Finca El Guayabo | **14 250** | **3** | **9 440** | *(vacío)* | **150,95 %** |
> | Hacienda Santa Rosa | **14 200** | **4** | **10 000** | *(vacío)* | **142,00 %** |
> | **Total** | **30 550** | **9** | **24 440** | **1** | **125,00 %** |
>
> **Pega las cuatro filas.**

**C2.** En dos líneas: compara esta tabla con la del punto de control 1. **¿Qué columna cambió, y cuáles no?** ¿Qué protegió el rol, en realidad?

**C3.** En dos líneas, y es la pregunta de la clase: el rol **sí** filtra `seguridad`. **¿Por qué no filtra `dim_finca`, ni `h_cosecha`, ni `h_meta`?** Explícalo con la relación de la parte A: de qué tabla a qué tabla viaja el filtro, y en qué sentido.

### C4. El que no está

**Ver como →** Otro usuario: `practicante@agrodb.test`, rol `Por correo`. Ese correo **no está** en `seguridad.csv`.

> ### ✅ Punto de control 4
> | Medida | Viendo como practicante@agrodb.test |
> |---|---|
> | `[Quien mira]` | practicante@agrodb.test |
> | `[Filas de seguridad]` | *(vacío)* |
> | `[Kilos]` | **30 550** |
> | `[Cumplimiento]` | **125,00 %** |
>
> **Pégalo.** Si `[Filas de seguridad]` sale en **0** en vez de vacío, anótalo y sigue.

**C5.** En dos líneas: el practicante **no tiene ningún permiso** y ve todo. **¿Qué pasa en la vida real el día que alguien olvida dar de alta a un usuario nuevo, con este rol?** ¿Y qué debería pasar?

**C6.** En una línea: escribe la **regla de detección** del día, tomando como base la de ayer (*«si una medida vale lo mismo con el rol y sin el rol, el rol no le llega»*).

---

## Parte D · El rol en la dimensión, primer intento (15 min)

Quita **Ver como** antes de editar el rol.

### D1. Mueve la condición

En **Administrar roles → `Por correo`**:

1. **Borra** la condición de `seguridad`.
2. Escribe la condición en **`dim_finca`**:

```
[finca_id] = LOOKUPVALUE( seguridad[finca_id] , seguridad[correo] , USERPRINCIPALNAME() )
```

`LOOKUPVALUE( columna que quiero , columna donde busco , valor que busco )`: busca en `seguridad` la fila de ese correo y devuelve su `finca_id`.

### D2. Tres correos que funcionan

Ver como, **uno a la vez**, siempre con el rol `Por correo` marcado:

> ### ✅ Punto de control 5
> | Viendo como… | Filas en la tabla por finca | `[Kilos]` | `[Cumplimiento]` |
> |---|---|---|---|
> | gerente.launion@agrodb.test | **1** | 2 100 | **42,00 %** |
> | gerente.guayabo@agrodb.test | **1** | 14 250 | **150,95 %** |
> | practicante@agrodb.test | **0** | *(vacío)* | *(vacío)* |
>
> **Pega las tres.** El practicante ya no ve nada.

### D3. El regional

Ver como → Otro usuario: `regional.norte@agrodb.test`, rol `Por correo`.

**D3.** **Copia el mensaje de error textual** que muestra Power BI, en el idioma de tu versión. Si hay que hacer clic en «Ver detalles» o algo parecido para verlo completo, hazlo y cópialo completo.

**D4.** En dos líneas: `regional.norte` tiene **dos filas** en `seguridad`. **¿Por qué `LOOKUPVALUE` truena en vez de devolver una de las dos fincas?** ¿Te conviene que truene?

**D5.** En una línea: prueba también con `direccion@agrodb.test`. **¿Qué pasa, y por qué?**

---

## Parte E · El arreglo (20 min)

Quita **Ver como**.

### E1. `IN` y `CALCULATETABLE`

Reemplaza la condición de `dim_finca` por:

```
[finca_id] IN
    CALCULATETABLE(
        VALUES( seguridad[finca_id] ),
        seguridad[correo] = USERPRINCIPALNAME()
    )
```

| Pieza | Qué hace |
|---|---|
| `VALUES( seguridad[finca_id] )` | la lista de `finca_id` distintos de `seguridad` |
| `CALCULATETABLE( … , filtro )` | lo mismo que `CALCULATE`, pero devuelve **una tabla** |
| `IN` | ¿el `finca_id` de esta fila está **en esa lista**? |

### E2. Los seis correos

Ver como, uno a la vez, con el rol `Por correo`:

> ### ✅ Punto de control 6
> | Viendo como… | Filas por finca | `[Kilos]` | `[Meta]` | `[Filas de seguridad]` | `[Cumplimiento]` |
> |---|---|---|---|---|---|
> | gerente.launion@agrodb.test | 1 | 2 100 | 5 000 | 3 | **42,00 %** |
> | gerente.guayabo@agrodb.test | 1 | 14 250 | 9 440 | 3 | **150,95 %** |
> | gerente.santarosa@agrodb.test | 1 | 14 200 | 10 000 | 2 | **142,00 %** |
> | regional.norte@agrodb.test | **2** | **16 350** | **14 440** | **6** | **113,23 %** |
> | direccion@agrodb.test | 3 | 30 550 | 24 440 | 8 | **125,00 %** |
> | practicante@agrodb.test | **0** | *(vacío)* | *(vacío)* | *(vacío)* | *(vacío)* |
>
> **Pega las seis filas.**

### E3. La tabla del regional

Ver como `regional.norte@agrodb.test`:

> ### ✅ Punto de control 7
> | Finca | `[Kilos]` | `[Cosechas]` | `[Meta]` | `[Filas de seguridad]` | `[Cumplimiento]` |
> |---|---|---|---|---|---|
> | Agricola La Union | 2 100 | 2 | 5 000 | 3 | 42,00 % |
> | Finca El Guayabo | 14 250 | 3 | 9 440 | 3 | 150,95 % |
> | **Total** | **16 350** | **5** | **14 440** | **6** | **113,23 %** |
>
> **Esta es la captura**: esta tabla y la tarjeta `[Quien mira]` diciendo `regional.norte@agrodb.test`.

**E4.** En una línea: viendo como `gerente.launion`, `[Filas de seguridad]` dice **3**, no 1. Pon `seguridad[correo]` en una tabla y mira: **¿qué correos ve el gerente, y por qué?**

**E5.** En dos líneas: los tres gerentes ven **lo mismo que ayer con tres roles distintos**. ¿Qué tiene de igual el rol de hoy con el `Gerente La Union` bien puesto de ayer, y qué tiene de distinto?

---

## Parte F · Dar de alta a alguien sin tocar el rol (10 min)

Quita **Ver como**.

### F1. Una fila más

Abre **tu copia descargada** de `seguridad.csv` con el Bloc de notas y agrega **al final** esta línea:

```
auditor.santarosa@agrodb.test,1
```

Guarda. En Power BI: **Inicio → Actualizar**. **No abras Administrar roles.**

> ### ✅ Punto de control 8
> | Dónde | Qué debe decir |
> |---|---|
> | `[Filas de seguridad]` sin rol, total | **9** |
> | Viendo como auditor.santarosa@agrodb.test: filas por finca | **1** |
> | …`[Kilos]` | **14 200** |
> | …`[Cumplimiento]` | **142,00 %** |
>
> **Pégalo.**

**F2.** En una línea: **¿cuántas veces abriste el rol para dar de alta al auditor?** ¿Quién tiene ahora el poder de decidir quién ve qué?

---

## Parte G · Preguntas de cierre (10 min)

1. En una línea: escribe la regla de dónde va la condición de un rol dinámico, y por qué **no** va en la tabla de permisos aunque ahí esté el correo.
2. En dos líneas: con el rol en `seguridad`, un correo **que no está** veía todo. Con el rol bueno, **no ve nada**. **¿Cuál de los dos comportamientos quieres, y por qué es la prueba que no se puede saltar?**
3. En dos líneas: el error de `LOOKUPVALUE` fue **el único mensaje de error de la semana**. Llevamos todo el curso diciendo *«qué avisó: nada»*. **¿Ese error fue malo o bueno?**
4. En una línea: **¿con qué tres correos pruebas siempre un rol dinámico**, y qué atrapa cada uno?
5. En una línea: `seguridad.csv` no tiene un solo kilo. **¿Por qué es tan delicado como `h_cosecha`?**

---

## Si algo falla

| Síntoma | Qué pasó | Qué haces |
|---|---|---|
| `seguridad` no se relacionó sola | la detección automática de relaciones está apagada | Vista Modelo: `seguridad[finca_id]` → `dim_finca[finca_id]`, Muchos a uno, Único |
| La relación salió **Uno a uno** | cargaste un CSV con una fila por finca | vuelve a bajar `seguridad.csv`: son **8** filas |
| No encuentras **Otro usuario** en Ver como | versión distinta | busca una casilla o un campo para escribir un usuario; **anota cómo se llama** |
| `[Quien mira]` no cambia | no marcaste **Otro usuario** | Ver como → Otro usuario → escribe el correo |
| `[Quien mira]` cambia pero nada se recorta | marcaste Otro usuario **y no el rol** | marca las dos cosas |
| El editor no deja escribir `USERPRINCIPALNAME()` | estás en el editor de clics | **Cambiar al editor DAX** |
| En la parte C salen números distintos | quedó un rol de ayer marcado, o una relación en «Ambas» | borra los roles de ayer; dirección **Único** |
| Con el rol bueno, **todo** sale vacío | el correo que escribiste en Ver como tiene un error o un espacio | cópialo del CSV |
| Con el regional, los visuales dan error **en la parte E** | te quedó el `LOOKUPVALUE` | la condición es la de `IN` |
| Power BI no deja guardar el rol de la parte E | un paréntesis o una coma de más | copia la condición completa del enunciado; si el error persiste, **copia el mensaje** y sigue |
| Agregaste al auditor y no aparece | falta **Actualizar**, o editaste otra copia del CSV | Inicio → Actualizar; revisa de qué ruta carga `seguridad` |
| Los decimales llevan punto y no coma | configuración regional de tu Windows | **no es un error**, anótalo y sigue |

> ### La regla de los 20 minutos sigue vigente
> Veinte minutos atorado en lo mismo: lo escribes en tu archivo empezando con `DUDA`, o abres un *issue*, y sigues con lo siguiente. **Atorarse no baja la nota. Quedarse callado sí.**

---

## Plan B · Si Power BI Desktop no abre en tu máquina

1. Ponte con un compañero: el tablero se arma en una sola máquina.
2. **Tú escribes todos los roles y las medidas** en tu propio archivo `.md`, con su resultado, y anotas con quién trabajaste.
3. La captura es la misma para los dos, y los dos lo dicen en un comentario.

**Con el Plan B completo se llega a 100 de 100.** Lo que se califica es dónde pusiste la condición y por qué, no de quién era la laptop.

---

## Rúbrica (100 puntos)

| Criterio | Pts |
|---|---|
| Parte A: la relación, las dos medidas, la tabla sin rol con el 8 de `[Filas de seguridad]`, y A4 | 10 |
| Parte B: el rol en `seguridad`, Ver como con otro usuario, las seis tarjetas con el 125,00 %, y B3, B4 y B5 | 15 |
| **Parte C: la tabla de tres fincas, el practicante viendo 30 550, y C2, C3, C5 y C6** | **25** |
| Parte D: `LOOKUPVALUE` en `dim_finca`, los tres correos que funcionan, el mensaje textual del regional, y D4 y D5 | 15 |
| **Parte E: el rol con `IN`, los seis correos, la tabla del regional con el 113,23 %, y E4 y E5** | **20** |
| Parte F: el auditor dado de alta sin tocar el rol, y F2 | 5 |
| Parte G: las cinco preguntas con criterio | 10 |

Los criterios suman **100** exactos.

> **Lo que más se califica hoy no es la fórmula de la parte E**, que se copia del enunciado. Es la parte C: que hayas visto un rol que **sí** filtra su tabla dejarle la empresa entera a quien no tenía ningún permiso, y que sepas explicar por qué con la flecha de una relación.
