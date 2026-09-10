---
marp: true
paginate: true
theme: default
title: "Clase 18 · Lo que cada quien puede ver"
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
footer: "Curso de SQL · AgroDB · Clase 18"
---

<!-- _class: lead -->

# Lo que cada quien puede ver

## Seguridad a nivel de fila, y un filtro que no llega a donde creías

Clase 18 · 10 de septiembre

---

# Lo que llega hoy

**Ningún archivo.** Los cinco CSV son los de ayer, sin tocar un byte.

<br>

Lo que llega es **una persona**: el gerente de **Agricola La Union**. Le vamos a mandar el tablero, y el requisito cabe en una línea:

## *Que vea su finca, y nada más.*

<br>

| | Hoy |
|---|---|
| Datos nuevos | ninguno |
| Medidas nuevas | una, al final |
| Lo nuevo | **roles** y **Ver como** |

> Hasta hoy todos veíamos todo. **Un tablero de verdad casi nunca se comparte así.**

---

# Esto ya lo hicimos una vez

En la **clase 13**, en Oracle:

<br>

| | Clase 13 | Hoy |
|---|---|---|
| Dónde vive la seguridad | en la **base** | en el **modelo** |
| Quién la aplica | Oracle | Power BI |
| Cómo se recortó | `bi_agro` solo leía **una vista** | un **rol** que filtra filas |
| Qué pasaba al pasarse | **`ORA-00942`** | … |

<br>

Aquella vez Oracle **contestaba con un error** cuando `bi_agro` intentaba leer `agro.cosechas`. Hoy no hay base: los CSV no tienen usuarios, ni permisos, ni `GRANT`.

> Guarden la última celda de la tabla. **En quince minutos la llenamos, y no va a decir error.**

---

# Qué es un rol

Un rol es **un filtro que el usuario no puede quitar**. Se escribe como una condición que se evalúa **fila por fila** sobre una tabla:

```
Rol:       un nombre, el que quieras
Tabla:     la tabla que se va a recortar
Condición: una expresión que da verdadero o falso en cada fila
```

<br>

- **Modelado → Administrar roles**: se crea el rol, se elige la tabla, se escribe la condición.
- La condición devuelve verdadero o falso por fila. Las filas en falso **desaparecen** para quien tenga ese rol.
- No se ve en ninguna segmentación, no se puede desmarcar, **no hay forma de saltarlo desde el tablero**.

> Es lo mismo que un segmentador, con una diferencia que es toda la clase: **al segmentador lo ves; al rol, no.**

---

# El primer rol, el obvio

El requisito dice *que vea su finca*. ¿Qué es lo que hay que esconderle a un gerente? **Las cosechas de los demás.**

<br>

Entonces el filtro va donde están las cosechas:

```
Rol:       Gerente La Union
Tabla:     h_cosecha
Condición: [finca_id] = 3
```

<br>

Tiene toda la lógica del mundo. `h_cosecha` es la tabla con los kilos, los kilos son lo delicado, y el `finca_id` 3 es La Unión.

> Esta es la versión que se escribe el primer día en casi todos lados. **Hoy la escribimos a propósito.**

---

# Ver como

No hace falta publicar nada para probar un rol:

**Modelado → Ver como →** marcar `Gerente La Union`.

<br>

Segmentadores en `anio` = 2026 y `mes` en 1–4, igual que ayer. Las dos tarjetas de siempre:

| Medida | Sin rol | **Viendo como La Union** |
|---|---|---|
| `[Kilos]` | 30 550 | **2 100** |
| `[Cosechas]` | 9 | **2** |

<br>

Dos mil cien kilos en dos cosechas. **Es exactamente La Unión**: la del 28 de marzo y la del 22 de abril.

> El rol funciona. Ya puedes mandar el tablero. **Pon ahora la tarjeta que el gerente de verdad va a mirar.**

---

# La tarjeta que el gerente va a mirar

Mismo rol, mismos segmentadores:

<br>

| Medida | Viendo como La Union |
|---|---|
| `[Kilos]` | 2 100 |
| `[Meta]` | **24 440** |
| `[Cumplimiento]` | **8,59 %** |

<br>

## *«Voy al 8 % de mi meta.»*

<br>

Ayer, en la tabla por finca, La Unión iba en **42,00 %**. Hoy, con su propio rol, el gerente lee **8,59 %**.

> Veinticuatro mil cuatrocientos cuarenta kilos de meta es **la meta de toda la empresa**. El gerente de la finca más chica está comparando su cosecha contra la de las tres.

---

# ¿Y qué error dio?

## Ninguno. Van cinco clases seguidas.

<br>

- El rol existe y **sí filtra**: `[Kilos]` dice 2 100, que es La Unión.
- Las cinco relaciones siguen bien, todas muchos a uno.
- **Ver como** no puso ninguna advertencia.
- El 8,59 % es aritmética correcta: 2 100 entre 24 440.

<br>

Y lo más incómodo: **el 8,59 % ya lo conocían**. Ayer era el cumplimiento del **Cacao** partido por cultivo, el número falso de la meta repetida. La Unión solo siembra cacao.

> Es el mismo error de ayer, con otra ropa: **una meta que no se entera del filtro.** Ayer el filtro era un cultivo en las filas. Hoy el filtro es un rol.

---

# Pon la finca en las filas

Viendo como La Union. Tabla con `dim_finca[finca]`, `[Kilos]` y `[Meta]`:

| Finca | `[Kilos]` | `[Meta]` | `[Cumplimiento]` |
|---|---|---|---|
| Agricola La Union | 2 100 | 5 000 | 42,00 % |
| Finca El Guayabo | *(vacío)* | **9 440** | *(vacío)* |
| Hacienda Santa Rosa | *(vacío)* | **10 000** | *(vacío)* |
| **Total** | **2 100** | **24 440** | **8,59 %** |

<br>

**Tres filas.** El gerente de La Unión ve el nombre de las otras dos fincas, y **la meta de cada una, mes a mes si quiere**.

> Ya no es un número malo: **es una fuga.** El requisito era *que vea su finca y nada más*, y el tablero le está enseñando el presupuesto de la competencia interna.

---

# Por qué pasa

El rol es un filtro, y **un filtro viaja solo por las relaciones**, del lado uno al lado muchos:

```
dim_finca  ──►  h_cosecha   ◄── aquí se puso el rol
dim_finca  ──►  h_meta

h_cosecha  ──►  dim_finca    ✘  no viaja hacia arriba
h_cosecha  ──►  h_meta       ✘  no hay camino
```

<br>

El rol recortó `h_cosecha` a dos filas. Y ahí se quedó: **no subió a `dim_finca`** —la relación no va en ese sentido— y por lo tanto **nunca llegó a `h_meta`**.

> `h_meta` sigue completa, con sus doce filas de enero a abril, para quien quiera verlas. **La seguridad no tiene excepciones a la regla de ayer.**

---

# El aviso de ayer sirve hoy

Ayer escribimos una medida de una línea para atrapar la meta repetida:

```
Filas de meta = COUNTROWS( h_meta )
```

| | Sin rol | Viendo como La Union |
|---|---|---|
| `[Cosechas]` | 9 | **2** |
| `[Filas de meta]` | 12 | **12** |

<br>

`[Cosechas]` se recortó y `[Filas de meta]` **no se movió**. Una finca con un rol encima tendría que tener **4** metas de enero a abril, no 12.

> **Si una medida vale lo mismo con el rol y sin el rol, el rol no le llega.** Es la regla de ayer, palabra por palabra, cambiando «filas» por «rol».

---

# La prueba que siempre se hace

Probar un rol no es mirar si los kilos bajaron. **Los kilos bajan con cualquier rol, bien o mal puesto.**

<br>

La prueba de verdad tiene dos pasos, y los dos van con **Ver como** prendido:

<br>

1. **Pon la dimensión del rol en las filas.** Si aparece una finca que no es suya, el rol está en la tabla equivocada.
2. **Pon un conteo de cada tabla de hechos.** Si alguno no se movió respecto de *sin rol*, esa tabla no está protegida.

<br>

> Un rol que solo se probó con la tarjeta de kilos **no está probado**. Está probado en la única tabla que ya sabías que iba a funcionar.

---

# Tres gerentes, tres números falsos

Un rol por finca, los tres puestos en `h_cosecha`:

<br>

| Gerente de… | Lo que ve | Lo que debería ver |
|---|---|---|
| Agricola La Union | **8,59 %** | 42,00 % |
| Finca El Guayabo | **58,31 %** | 150,95 % |
| Hacienda Santa Rosa | **58,10 %** | 142,00 % |

<br>

El Guayabo va **arriba** de su meta por cincuenta puntos, y su gerente lee que va a la mitad. **Los tres creen que van mal**, y los tres están comparando contra la empresa entera.

> Y si alguien suma lo que ven los tres: 8,59 + 58,31 + 58,10 = **125,00**. Otra vez cuadra exacto. **Otra vez la revisión obvia lo aprueba.**

---

# El arreglo: el rol en la dimensión

Borra la condición de `h_cosecha` y ponla una tabla más arriba:

```
Rol:       Gerente La Union
Tabla:     dim_finca
Condición: [finca] = "Agricola La Union"
```

<br>

Ahora el filtro nace en el lado **uno**, y desde ahí baja por **las dos** relaciones:

```
dim_finca  ──►  h_cosecha    ✔
dim_finca  ──►  h_meta       ✔
```

<br>

> No cambió la condición: cambió **de qué tabla cuelga**. Es la misma lección de la clase 14 vista desde otro ángulo: las dimensiones están para filtrar, los hechos están para ser filtrados.

---

# Ver como, otra vez

Viendo como La Union, segmentadores en 2026 y meses 1–4:

| Medida | Rol en `h_cosecha` | **Rol en `dim_finca`** |
|---|---|---|
| `[Kilos]` | 2 100 | **2 100** |
| `[Meta]` | 24 440 | **5 000** |
| `[Cumplimiento]` | 8,59 % | **42,00 %** |
| `[Filas de meta]` | 12 | **4** |
| Filas en la tabla por finca | 3 | **1** |

<br>

Los kilos **no cambiaron**: por eso la tarjeta de kilos nunca iba a delatar nada. Todo lo demás, sí.

> Y el segmentador de fincas, si lo pones, ya solo ofrece **una** opción. Antes ofrecía tres.

---

# La regla, y va al cuaderno

## La seguridad se pone en la dimensión, que es la única tabla que llega a todos los hechos.

<br>

Un rol en una tabla de hechos protege **esa** tabla. Un rol en la dimensión protege **todo lo que cuelga de ella**, incluidos los hechos que todavía no existen.

<br>

Mañana llega una tercera tabla —costos, jornales, lo que sea— con su `finca_id`. Con el rol en `dim_finca`, **llega ya protegida** en cuanto la relacionas. Con el rol en los hechos, alguien tiene que acordarse de escribir un rol más.

> **Nadie se acuerda.** Por eso la regla no depende de acordarse.

---

# Lo que el rol no deja ver, tampoco lo ve DAX

Una medida más, la última del día:

```
Participacion = DIVIDE( [Kilos] , CALCULATE( [Kilos] , ALL( dim_finca ) ) )
```

`ALL( dim_finca )` quita el filtro de finca para calcular el total de la empresa.

| Finca | Sin rol | Viendo como La Union |
|---|---|---|
| Agricola La Union | 6,87 % | **100,00 %** |
| Finca El Guayabo | 46,64 % | — |
| Hacienda Santa Rosa | 46,48 % | — |

<br>

Con el rol, `ALL` **no puede** traer las filas de las otras fincas: **el rol no es un filtro del contexto, es un recorte de la tabla.** Para ese gerente, la empresa es su finca.

---

# Eso no se arregla con una fórmula

El gerente de La Unión lee **100,00 %** de participación, y es verdad dentro de lo que puede ver.

<br>

Si ese gerente **necesita** saber que su finca es el 6,87 % de la empresa, hay dos caminos, y ninguno es de DAX:

| Camino | Qué implica |
|---|---|
| Darle el total de la empresa | alguien decide que **puede** ver ese número |
| No dárselo | la participación **no va** en su tablero |

<br>

> Es la misma pregunta de la clase 13 con `bi_agro`: **qué puede ver cada quien es una decisión de negocio**, y hay que tomarla antes de escribir el rol. La herramienta solo la ejecuta.

---

# Los errores que van a ver hoy

| Síntoma | Qué pasó | Arreglo |
|---|---|---|
| Viendo como, `[Meta]` sigue en 24 440 | el rol está en `h_cosecha` | rol en `dim_finca` |
| Viendo como, salen las tres fincas | el rol está en `h_cosecha` | rol en `dim_finca` |
| Viendo como, todo sale vacío | el nombre de la finca va mal escrito | es `Agricola La Union`, sin acentos |
| No ves ningún cambio al crear el rol | falta **Ver como** | Modelado → Ver como |
| El rol no se deja guardar | la condición no devuelve verdadero o falso | `[finca] = "…"`, con comillas dobles |
| Tu editor de roles no deja escribir DAX | versión con editor de clics | busca **Cambiar a editor DAX** |
| `[Participacion]` dice 100,00 % con el rol | **así funciona** | no es un error |
| Olvidaste quitar Ver como | todo el tablero sigue recortado | Ver como → desmarcar |
| Dos roles marcados a la vez | se **suman**: ves las dos fincas | marca uno solo |

---

<!-- _class: lead -->

# La idea del día

## La seguridad es un filtro más: llega solo a donde llegan las relaciones.

<br>

En la clase 13, cuando `bi_agro` se pasaba, Oracle contestaba **`ORA-00942`**. Hoy el gerente se pasó de su finca y **nadie contestó nada**: le salió un 8,59 % y el presupuesto de las otras dos.

<br>

**Práctica:** pon el rol donde es obvio, encuentra la fuga con **Ver como** y `[Filas de meta]`, y **muévelo a la dimensión**.

**Y viendo como La Union, `[Cumplimiento]` tiene que decir 42,00 %.**
