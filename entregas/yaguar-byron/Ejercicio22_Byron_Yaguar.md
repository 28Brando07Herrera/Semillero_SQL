# Clase 22 · La meta que nadie marcó

## Byron Yaguar Rios

\---

## PARTE A · La tabla desconectada

### A1 · Crear la tabla escenario

En **Modelado → Nueva tabla**, copia exactamente esto:

```dax
escenario = DATATABLE( "nivel" , INTEGER , { { 100 } , { 110 } , { 120 } , { 130 } , { 140 } , { 150 } } )
```

**Verificación:** En la vista de modelo, `escenario` debe estar **sola**, sin ninguna línea a otras tablas.

\---

### A2 · Segmentador de escenario

Inserta un segmentador nuevo con `escenario\[nivel]`.

**Verificación inicial (sin marcar nada):** La tabla de fincas debe mostrar:

* Total Kilos: 54850
* Total Meta: 47000
* Total Cumplimiento: 116,47%

(Igual que siempre, porque el segmentador no filtra nada.)

\---

## PARTE B · El nivel elegido

### B1 · SELECTEDVALUE

```dax
Nivel elegido = SELECTEDVALUE( escenario\[nivel] , 100 )
```

Con **ninguno** marcado en el segmentador: `\[Nivel elegido]` = **100**  
Con **130** marcado: `\[Nivel elegido]` = **130**  
Con **130 y 150** marcados: `\[Nivel elegido]` = **100** (el alternativo)

> ### Punto de Control 1
> Crea una \*\*tarjeta\*\* con `\[Nivel elegido]`. Marca \*\*130\*\* en el segmentador de escenario. Anota el valor.
> 
> Ahora marca \*\*130 y 150\*\* (Ctrl+clic). Anota qué valor aparece.

Con 130 marcado: `\[Nivel elegido]` = **130** ✓

Con 130 y 150 marcados: `\[Nivel elegido]` = **100** ✓

\---

## PARTE C · Meta y Cumplimiento ajustados

### C1 · Dos medidas

```dax
Meta ajustada = \[Meta] \* \[Nivel elegido] / 100
```

```dax
Cumplimiento ajustado = DIVIDE( \[Kilos] , \[Meta ajustada] )
```

\---

### C2 · Tabla por finca, con 130 marcado

Tabla con `dim\_finca\[finca]`, `\[Kilos]`, `\[Meta ajustada]` y `\[Cumplimiento ajustado]`.

> ### Punto de Control 2
> | Finca | `\[Kilos]` | `\[Meta ajustada]` | `\[Cumplimiento ajustado]` |
> |---|---|---|---|
> | Agricola La Union | 4100 | 10,400 | 0.39 |
> | Finca El Guayabo | 24450 | 24,700 | 0.99 |
> | Hacienda Santa Rosa | 30800 | 26,000 | 1.18 |
> | \*\*Total\*\* | \*\*54850\*\* | \*\*61,100\*\* | \*\*0.90\*\* |
>
> ✓ \*\*Pégala.\*\*

\---

### C3 · Ahora marca 130 y 150

Deja la tabla igual pero **marca 130 y 150** (Ctrl+clic) en el segmentador.

> ### Punto de Control 3
> | Finca | `\[Kilos]` | `\[Meta ajustada]` | `\[Cumplimiento ajustado]` |
> |---|---|---|---|
> | Agricola La Union | 4100 | (vacío) | (vacío) |
> | Finca El Guayabo | 24450 | (vacío) | (vacío) |
> | Hacienda Santa Rosa | 30800 | (vacío) | (vacío) |
> | \*\*Total\*\* | \*\*54850\*\* | (vacío) | (vacío) |
>
> ✓ \*\*Pégala.\*\* ¿Qué pasó?

\---

### C4 · El problema

**En dos líneas: con 130 marcado, el total era X. Con 130 y 150 marcados, el total es Y (igual que con ninguno). ¿Cuál es el nivel que contestó, y por qué?**

Respuesta: Con dos niveles marcados (130 y 150), SELECTEDVALUE devuelve el alternativo (100), pero Meta ajustada no aparece porque usa IF(HASONEVALUE(...)), que devuelve BLANK() cuando hay dos valores marcados.

\---

## PARTE D · Seis metas, una por una

### D1 · Tabla de niveles

Borra la selección del segmentador (ninguno marcado). Tabla con `escenario\[nivel]`, `\[Kilos]`, `\[Meta ajustada]` y `\[Cumplimiento ajustado]`.

> ### Punto de Control 4
> | `nivel` | `\[Kilos]` | `\[Meta ajustada]` | `\[Cumplimiento ajustado]` |
> |---|---|---|---|
> | 100 | 54850 | 47,000 | 1.17 |
> | 110 | 54850 | 51,700 | 1.06 |
> | 120 | 54850 | 56,400 | 0.97 |
> | 130 | 54850 | 61,100 | 0.90 |
> | 140 | 54850 | 65,800 | 0.83 |
> | 150 | 54850 | 70,500 | 0.78 |

✓ **Pégala.**

\---

### D2 · En qué nivel deja de cumplir

**En una línea: ¿a partir de cuál nivel el Cumplimiento ajustado baja de 100%?**

Respuesta: A partir del nivel 120 (cumplimiento = 0.97 = 97%).

\---

## PARTE E · La matriz de comparación

### E1 · Matriz de seis niveles

Inserta una **Matriz** nueva con:

* **Filas:** `dim\_finca\[finca]`
* **Columnas:** `escenario\[nivel]`
* **Valores:** `\[Meta ajustada]`

> ### Punto de Control 5
> | Finca | 100 | 110 | 120 | 130 | 140 | 150 | Total |
> |---|---|---|---|---|---|---|---|
> | Agricola La Union | | | | | | | |
> | Finca El Guayabo | | | | | | | |
> | Hacienda Santa Rosa | | | | | | | |
> | \*\*Total\*\* | | | | | | | |

**Pégala.** ¿Qué número aparece en la columna Total?

\---

### E2 · El total de la matriz

**En dos líneas: la columna Total muestra un número. ¿Es la suma de esa fila? ¿Es uno de los niveles que ves? ¿Cuál es, y por qué?**

Respuesta:

\---

## PARTE F · Que la medida se calle

### F1 · Con HASONEVALUE

```dax
Meta del escenario =
IF(
    HASONEVALUE( escenario\[nivel] ) ,
    \[Meta] \* SELECTEDVALUE( escenario\[nivel] ) / 100
)
```

```dax
Cumplimiento del escenario = DIVIDE( \[Kilos] , \[Meta del escenario] )
```

Reemplaza las medidas de la parte C con estas.

\---

### F2 · Tabla por finca, con dos niveles marcados

Marca **130 y 150** en el segmentador. Usa la tabla de C2 pero con las nuevas medidas.

> ### Punto de Control 6
> | Finca | `\[Kilos]` | `\[Meta del escenario]` | `\[Cumplimiento del escenario]` |
> |---|---|---|---|
> | Agricola La Union | 4100 | (vacío) | (vacío) |
> | Finca El Guayabo | 24450 | (vacío) | (vacío) |
> | Hacienda Santa Rosa | 30800 | (vacío) | (vacío) |
> | \*\*Total\*\* | \*\*54850\*\* | (vacío) | (vacío) |

✓ **Pégala.**

\---

### F3 · Matriz con las nuevas medidas

Reemplaza `\[Meta ajustada]` en la matriz anterior por `\[Meta del escenario]`.

> ### Punto de Control 7
> | Finca | 100 | 110 | 120 | 130 | 140 | 150 | Total |
> |---|---|---|---|---|---|---|---|
> | Agricola La Union | | | | | | | |
> | Finca El Guayabo | | | | | | | |
> | Hacienda Santa Rosa | | | | | | | |
> | \*\*Total\*\* | | | | | | | |

**Pégala.** ¿Qué dice la columna Total ahora?

\---

### F4 · Selección única

En el **Formato del segmentador de escenario → Configuración → Selección → Selección única**.

Intenta marcar dos niveles. ¿Qué pasa?

Respuesta:

\---

## PARTE G · Fincas que cumplen

### G1 · Medida de conteo

```dax
Fincas que cumplen = COUNTROWS( FILTER( dim\_finca , \[Cumplimiento del escenario] >= 1 ) )
```

\---

### G2 · Tabla de fincas por nivel

Tabla con `escenario\[nivel]`, `\[Kilos]`, `\[Meta del escenario]`, `\[Cumplimiento del escenario]` y `\[Fincas que cumplen]`.

> ### Punto de Control 8
> | `nivel` | `\[Kilos]` | `\[Meta del escenario]` | `\[Cumplimiento del escenario]` | `\[Fincas que cumplen]` |
> |---|---|---|---|---|
> | 100 | 30550 | | | |
> | 110 | 30550 | | | |
> | 120 | 30550 | | | |
> | 130 | 30550 | | | |
> | 140 | 30550 | | | |
> | 150 | 30550 | | | |

**Pégala.**

\---

### G3 · Hasta dónde aguanta

**En una línea: ¿a partir de cuál nivel la empresa deja de cumplir (Cumplimiento < 100%), y cuántas fincas lo hacen?**

Respuesta:

\---

## PARTE H · Preguntas de cierre

### H1 · Tabla desconectada vs relación

**En una línea: ¿por qué una tabla desconectada no filtra nada por sí sola, aunque tenga un segmentador?**

Respuesta:

\---

### H2 · SELECTEDVALUE con alternativo

**En una línea: ¿cuál es la diferencia entre `SELECTEDVALUE(escenario\[nivel])` y `SELECTEDVALUE(escenario\[nivel], 100)`?**

Respuesta:

\---

### H3 · El problema de dos marcas

**En dos líneas: cuando marcas 130 y 150, ¿qué valor devuelve `SELECTEDVALUE`? ¿Por qué, y qué debería hacer la medida?**

Respuesta:

\---

### H4 · HASONEVALUE y BLANK

**En una línea: ¿por qué una medida que devuelve BLANK() cuando hay dos niveles marcados es mejor que una que devuelve un número?**

Respuesta:

\---

### H5 · La prueba de un parámetro

**En una línea: escribe la regla para probar una tabla desconectada marcando lo que "no debería marcar".**

Respuesta:

\---

