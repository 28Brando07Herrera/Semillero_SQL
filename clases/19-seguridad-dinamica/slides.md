---
marp: true
paginate: true
theme: default
title: "Clase 19 · Un rol para todos"
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
footer: "Curso de SQL · AgroDB · Clase 19"
---

<!-- _class: lead -->

# Un rol para todos

## Seguridad dinámica, y una tabla de permisos que no protegía nada

Clase 19 · 14 de septiembre

---

# Lo que llega hoy

**Un archivo**: `seguridad.csv`. Quién puede ver qué finca.

| `correo` | `finca_id` |
|---|---|
| gerente.santarosa@agrodb.test | 1 |
| gerente.guayabo@agrodb.test | 2 |
| gerente.launion@agrodb.test | 3 |
| regional.norte@agrodb.test | 2 |
| regional.norte@agrodb.test | 3 |
| direccion@agrodb.test | 1, 2 y 3 *(tres filas)* |

**Ocho filas, cinco correos.** Una fila por permiso, no por persona.

> Y hay un sexto correo que **no está**: `practicante@agrodb.test`. Guárdenlo.

---

# El problema de ayer, multiplicado

Ayer escribimos **tres roles** para **tres gerentes**:

| Rol | Tabla | Condición |
|---|---|---|
| Gerente La Union | `dim_finca` | `[finca] = "Agricola La Union"` |
| Gerente El Guayabo | `dim_finca` | `[finca] = "Finca El Guayabo"` |
| Gerente Santa Rosa | `dim_finca` | `[finca] = "Hacienda Santa Rosa"` |

<br>

Ahora son cuarenta gerentes, un regional que ve dos fincas y una dirección que ve todas. **Cada alta, cada baja y cada cambio es abrir el modelo y tocar un rol.**

> Hoy se escribe **un solo rol**. Lo que cambia entre personas deja de estar en el modelo y pasa a estar **en una tabla**.

---

# Quién está mirando

DAX tiene una función que contesta eso:

```
Quien mira = USERPRINCIPALNAME()
```

Devuelve **el correo de quien está viendo el informe**.

<br>

Para probarlo sin publicar nada: **Modelado → Ver como**, marca **Otro usuario**, escribe un correo **y marca también el rol**.

| Sin Ver como | Viendo como `gerente.launion@agrodb.test` |
|---|---|
| tu propia cuenta | **gerente.launion@agrodb.test** |

> `[Quien mira]` es el primer lugar donde se revisa un rol dinámico. **Si esa tarjeta no dice el correo que escribiste, nada de lo que sigue importa.**

---

# La tabla de permisos, en el modelo

Carga `seguridad.csv`. Power BI la relaciona sola por `finca_id`:

```
dim_finca  ──►  h_cosecha
dim_finca  ──►  h_meta
dim_finca  ──►  seguridad      muchos a uno, dirección Único
```

<br>

`finca_id` se repite en `seguridad` —la finca 2 tiene tres permisos—, así que `seguridad` es el lado **muchos**. Igual que los dos hechos.

Y un conteo, como ayer:

```
Filas de seguridad = COUNTROWS( seguridad )
```

Sin rol: **8**.

---

# El rol obvio

¿Dónde va la condición? **Donde está el correo.**

```
Rol:       Por correo
Tabla:     seguridad
Condición: [correo] = USERPRINCIPALNAME()
```

<br>

Se lee perfecto: *de la tabla de permisos, quédate con las filas de quien está mirando*. Una sola línea, un solo rol, cuarenta gerentes.

> Es exactamente lo que se escribe la primera vez, y **hoy también la escribimos a propósito.**

---

# Ver como el gerente de La Unión

**Ver como → Otro usuario:** `gerente.launion@agrodb.test`, rol **Por correo**. Segmentadores en 2026 y meses 1–4:

| Medida | Sin rol | **Viendo como gerente.launion** |
|---|---|---|
| `[Quien mira]` | tu cuenta | **gerente.launion@agrodb.test** |
| `[Filas de seguridad]` | 8 | **1** |
| `[Kilos]` | 30 550 | **30 550** |
| `[Cumplimiento]` | 125,00 % | **125,00 %** |

<br>

El rol funciona: `[Filas de seguridad]` bajó a **1**, que es la fila del gerente. **Y los kilos no se movieron.**

> Ayer, con el rol mal puesto, por lo menos los kilos bajaban. **Hoy no baja nada.**

---

# ¿Y qué error dio?

## Ninguno. Otra vez.

<br>

- `[Quien mira]` dice el correo correcto.
- El rol existe, se guardó y **sí filtra**: `seguridad` quedó en una fila.
- La relación está bien: muchos a uno, dirección Único.
- **Ver como** no puso ninguna advertencia.

<br>

El gerente de La Unión abre su tablero y lee **125,00 %**. Es el cumplimiento de **la empresa entera**, con los kilos de las tres fincas.

> Ayer el rol le enseñaba la meta de los demás. **Hoy le enseña todo.**

---

# Pon la finca en las filas

Viendo como `gerente.launion@agrodb.test`. La tabla de siempre, más `[Filas de seguridad]`:

| Finca | `[Kilos]` | `[Meta]` | `[Filas de seguridad]` | `[Cumplimiento]` |
|---|---|---|---|---|
| Agricola La Union | 2 100 | 5 000 | 1 | 42,00 % |
| Finca El Guayabo | **14 250** | **9 440** | *(vacío)* | **150,95 %** |
| Hacienda Santa Rosa | **14 200** | **10 000** | *(vacío)* | **142,00 %** |
| **Total** | **30 550** | **24 440** | **1** | **125,00 %** |

<br>

Es **la prueba de ayer**: la dimensión del rol en las filas. Salen las tres fincas, con kilos, meta y cumplimiento.

> La única columna que se enteró del rol es la de la tabla de permisos. **El rol protegió la lista de permisos, y nada más.**

---

# Por qué pasa

Es el diagrama de ayer, con otro nombre en la caja:

```
dim_finca  ──►  seguridad    el filtro baja de la finca a los permisos

seguridad  ──►  dim_finca    ✘  no viaja hacia arriba
seguridad  ──►  h_cosecha    ✘  no hay camino
seguridad  ──►  h_meta       ✘  no hay camino
```

<br>

El rol recortó `seguridad` a una fila. Para llegar a los kilos tendría que **subir** a `dim_finca`, y la relación no va en ese sentido.

> Ayer: un rol en `h_cosecha` no llegaba a `h_meta`. Hoy: un rol en `seguridad` no llega **a nada**. **La tabla de permisos es una tabla más, y la regla de ayer no tiene excepciones.**

---

# El que no está en la tabla

**Ver como → Otro usuario:** `practicante@agrodb.test`, rol **Por correo**.

| Medida | Viendo como practicante |
|---|---|
| `[Quien mira]` | practicante@agrodb.test |
| `[Filas de seguridad]` | *(vacío)* |
| `[Kilos]` | **30 550** |
| `[Cumplimiento]` | **125,00 %** |

<br>

El practicante **no tiene ningún permiso**. `seguridad` quedó sin filas… y ve la empresa entera.

> Un permiso que se olvidó dar tendría que dejar a alguien **sin ver nada**. Con este rol, **olvidarse de alguien es darle todo**.

---

# La regla de ayer, sin excepciones

## La seguridad se pone en la dimensión.

<br>

El problema: **el correo no está en `dim_finca`**. Ahí solo hay `finca_id`, `finca` y `provincia`.

Entonces la condición tiene que ir **en `dim_finca`**, pero **preguntarle a `seguridad`**:

<br>

> *Para cada finca: ¿esta finca está entre las que le tocan a quien está mirando?*

<br>

La tabla de permisos **no filtra**. **Se consulta.**

---

# Primer intento en la dimensión

Borra la condición de `seguridad`. En `dim_finca`:

```
Rol:       Por correo
Tabla:     dim_finca
Condición: [finca_id] = LOOKUPVALUE( seguridad[finca_id] ,
                                     seguridad[correo] , USERPRINCIPALNAME() )
```

`LOOKUPVALUE` busca en `seguridad` la fila de ese correo y devuelve su `finca_id`.

| Viendo como… | Filas por finca | `[Cumplimiento]` |
|---|---|---|
| gerente.launion | **1** | **42,00 %** |
| gerente.guayabo | **1** | **150,95 %** |
| practicante | **0** | *(vacío)* |

> Funciona. Y el practicante **ya no ve nada**, que es lo correcto. **Ahora prueba con el regional.**

---

# El regional

**Ver como → Otro usuario:** `regional.norte@agrodb.test`, rol **Por correo**.

<br>

## Los objetos visuales se rompen con un error.

<br>

Por primera vez desde que dejamos Oracle, algo en este curso **avisa con un mensaje**.

- `regional.norte` tiene **dos filas** en `seguridad`: la finca 2 y la 3.
- `LOOKUPVALUE` promete **un** valor. Encontró dos, y en vez de escoger uno, **truena**.
- Con `direccion@agrodb.test`, tres filas: **truena igual**.

> Es el mejor error posible. **Lo peligroso habría sido que escogiera una finca sin avisar.**

---

# Una persona, varias fincas

El `=` compara contra **un** valor. Un permiso por persona no es la vida real: la tabla tiene **una fila por permiso**.

<br>

Hace falta preguntar *¿está en la lista?*, no *¿es igual a?*:

| Pregunta | En DAX |
|---|---|
| ¿es igual a este valor? | `[finca_id] = …` |
| ¿está en esta lista? | `[finca_id] IN …` |

<br>

Y la lista son los `finca_id` de `seguridad` **en las filas de quien está mirando**: un `CALCULATE` que en vez de un número devuelve **una tabla**.

---

# El arreglo

```
Rol:       Por correo
Tabla:     dim_finca
Condición: [finca_id] IN
               CALCULATETABLE(
                   VALUES( seguridad[finca_id] ),
                   seguridad[correo] = USERPRINCIPALNAME()
               )
```

<br>

- `VALUES( seguridad[finca_id] )`: la lista de `finca_id` distintos.
- `CALCULATETABLE( … , filtro )`: la misma idea que `CALCULATE`, pero devuelve **una tabla**.
- `IN`: ¿el `finca_id` de esta fila de `dim_finca` está en esa lista?

> Tres palabras nuevas, **la misma regla de ayer**: el rol cuelga de `dim_finca` y desde ahí baja a los dos hechos.

---

# Ver como, los seis correos

Un solo rol. Segmentadores en 2026 y meses 1–4:

| Viendo como… | Filas por finca | `[Kilos]` | `[Meta]` | `[Cumplimiento]` |
|---|---|---|---|---|
| gerente.launion | 1 | 2 100 | 5 000 | **42,00 %** |
| gerente.guayabo | 1 | 14 250 | 9 440 | **150,95 %** |
| gerente.santarosa | 1 | 14 200 | 10 000 | **142,00 %** |
| regional.norte | **2** | **16 350** | **14 440** | **113,23 %** |
| direccion | 3 | 30 550 | 24 440 | **125,00 %** |
| practicante | **0** | *(vacío)* | *(vacío)* | *(vacío)* |

<br>

Los tres gerentes ven **lo mismo que ayer con tres roles**. El regional ve sus dos fincas **sumadas**, sin error. El practicante no ve nada.

---

# La prueba de un rol dinámico

Ayer la prueba era la dimensión en las filas y un conteo por hecho. Hoy se le agrega **a quién** se prueba. Siempre **tres correos**:

<br>

| Correo | Qué atrapa |
|---|---|
| uno con **una** finca | que el rol filtre algo |
| uno con **varias** fincas | el `=` que debió ser `IN` |
| uno que **no está** en la tabla | la puerta abierta por defecto |

<br>

Y lo que ganaste: **dar de alta a un gerente ya no toca el modelo.** Es una fila más en `seguridad.csv` y **Actualizar**. El rol no se vuelve a abrir.

> Por eso la tabla de permisos **es tan delicada como los kilos**: quien la edita, decide quién ve qué.

---

# Los errores que van a ver hoy

| Síntoma | Qué pasó | Arreglo |
|---|---|---|
| Viendo como, `[Kilos]` sigue en 30 550 | el rol está en `seguridad` | rol en `dim_finca` |
| El practicante ve todo | el rol está en `seguridad` | rol en `dim_finca` |
| `[Quien mira]` no dice el correo que escribiste | no marcaste **Otro usuario** | Ver como → Otro usuario |
| `[Quien mira]` sí, pero nada se recorta | marcaste Otro usuario **y no el rol** | marca los dos |
| Con el regional, los visuales dan error | `LOOKUPVALUE` con dos fincas | `IN` + `CALCULATETABLE` |
| Con el rol bueno, **todo** vacío | el correo va mal escrito | copia el correo del CSV |
| No se crea la relación con `seguridad` | la detección automática está apagada | `seguridad[finca_id]` → `dim_finca[finca_id]` |
| Agregaste un correo al CSV y no aparece | falta **Actualizar** | Inicio → Actualizar |

---

<!-- _class: lead -->

# La idea del día

## Un rol dinámico sigue siendo un rol: la condición pregunta quién mira, pero el filtro viaja solo por las relaciones.

<br>

Ayer el rol en la tabla equivocada le enseñó al gerente la meta de los demás. Hoy, puesto en la tabla de permisos, **le enseñó todo, y al que no tenía permiso también**. El único mensaje de error del día fue el del arreglo a medias.

<br>

**Práctica:** pon el rol en `seguridad`, encuentra la fuga con el practicante, pasa a `dim_finca` con `LOOKUPVALUE`, rómpelo con el regional y **arréglalo con `IN`**.

**Y viendo como regional.norte, `[Cumplimiento]` tiene que decir 113,23 %.**
