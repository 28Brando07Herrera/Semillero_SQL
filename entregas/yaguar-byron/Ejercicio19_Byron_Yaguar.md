# Ejercicio 19 · Un rol para todos
## Byron Yaguar Rios

---

## PARTE A · La tabla de permisos

### A1 · Carga y relación

**¿Power BI creó la relación automáticamente o la tuviste que crear?**

```
Relación: seguridad[finca_id] → dim_finca[finca_id]
Cardinality: Muchos a uno
Dirección: Único
Creada por: [Automática / Manual]
```

---

### A2 · Dos medidas

```dax
Quien mira = USERPRINCIPALNAME()
```

```dax
Filas de seguridad = COUNTROWS(seguridad)
```

---

### A3 · Punto de Control 1 (sin rol)

**Tabla con dim_finca[finca], [Kilos], [Cosechas], [Meta], [Filas de seguridad], [Cumplimiento]:**

| Finca | [Kilos] | [Cosechas] | [Meta] | [Filas de seguridad] | [Cumplimiento] |
|---|---|---|---|---|---|
| Agricola La Union | | | | | |
| Finca El Guayabo | | | | | |
| Hacienda Santa Rosa | | | | | |
| **Total** | | | | | |

**Esperado:**
- Total [Kilos]: 30 550
- Total [Meta]: 24 440
- Total [Filas de seguridad]: 8
- Total [Cumplimiento]: 125,00%

---

### A4 · Pregunta conceptual

**En una línea: `[Filas de seguridad]` se parte por finca (3, 3 y 2). ¿Qué relación hace que `dim_finca` filtre a `seguridad`, y en qué sentido va?**

Respuesta:

---

## PARTE B · El rol obvio

### B1 · Rol "Por correo" (primera versión)

**Tabla:** `seguridad`

**Condición:**
```dax
[correo] = USERPRINCIPALNAME()
```

**¿Usaste "Cambiar al editor DAX"?** Sí / No

**¿Cómo se llama el botón en tu versión?**

---

### B2 · Punto de Control 2 (Ver como gerente.launion@agrodb.test)

**Tarjetas con: [Quien mira], [Filas de seguridad], [Kilos], [Cosechas], [Meta], [Cumplimiento]**

| Medida | Valor |
|---|---|
| [Quien mira] | |
| [Filas de seguridad] | |
| [Kilos] | |
| [Cosechas] | |
| [Meta] | |
| [Cumplimiento] | |

**Esperado:**
- [Quien mira]: gerente.launion@agrodb.test
- [Filas de seguridad]: 1
- [Kilos]: 30 550 ← **Problema aquí**
- [Meta]: 24 440
- [Cumplimiento]: 125,00%

---

### B3 · Mensaje de error o advertencia

**Copia textual del mensaje que mostró Power BI:**

```
[Mensaje de error/advertencia aquí]
```

---

### B4 · ¿Prueba que el rol funciona?

**En una línea: `[Filas de seguridad]` bajó de 8 a 1. ¿Eso prueba que el rol funciona? ¿Qué prueba, exactamente?**

Respuesta:

---

### B5 · Tarjeta que se movió

**En una línea: ayer, con el rol en `h_cosecha`, `[Kilos]` bajaba a 2 100. ¿Qué tarjeta se movió hoy, además de `[Quien mira]`?**

Respuesta:

---

## PARTE C · La fuga (es la parte que más vale)

**Sigue con Ver como prendido en `gerente.launion@agrodb.test` y el rol `Por correo`**

### C1 · Punto de Control 3 (tabla de tres fincas)

**La misma tabla de A3, pero ahora con el rol:**

| Finca | [Kilos] | [Cosechas] | [Meta] | [Filas de seguridad] | [Cumplimiento] |
|---|---|---|---|---|---|
| Agricola La Union | | | | | |
| Finca El Guayabo | | | | | |
| Hacienda Santa Rosa | | | | | |
| **Total** | | | | | |

**Esperado:**
- La Union: 2 100, 5 000, 42,00%
- Guayabo y Santa Rosa: valores visibles pero [Filas de seguridad] vacío
- Total de [Kilos]: 30 550 ← **¡Sigue siendo igual!**

---

### C2 · Comparación con punto de control 1

**En dos líneas: compara esta tabla con la del punto de control 1. ¿Qué columna cambió, y cuáles no?**

Respuesta:

---

### C3 · Por qué el rol no filtra

**En dos líneas: el rol sí filtra `seguridad`. ¿Por qué no filtra `dim_finca`, ni `h_cosecha`, ni `h_meta`? Explícalo con la relación: de qué tabla a qué tabla viaja el filtro.**

Respuesta:

---

### C4 · Punto de Control 4 (practicante sin permisos)

**Ver como: `practicante@agrodb.test`, rol `Por correo`**

**Tarjetas con: [Quien mira], [Filas de seguridad], [Kilos], [Cumplimiento]**

| Medida | Valor |
|---|---|
| [Quien mira] | |
| [Filas de seguridad] | |
| [Kilos] | |
| [Cumplimiento] | |

**Esperado:**
- [Filas de seguridad]: (vacío) o 0
- [Kilos]: 30 550 ← **Sigue viéndose todo**
- [Cumplimiento]: 125,00%

---

### C5 · El problema en la vida real

**En dos líneas: el practicante no tiene ningún permiso y ve todo. ¿Qué pasa en la vida real si alguien olvida dar de alta a un usuario nuevo, con este rol? ¿Qué debería pasar?**

Respuesta:

---

### C6 · Regla de detección

**En una línea: escribe la regla de detección (basada en: "si una medida vale lo mismo con rol y sin rol, el rol no le llega")**

Respuesta:

---

## PARTE D · El rol en la dimensión, primer intento

**Quita Ver como antes de editar el rol**

### D1 · Mueve la condición a dim_finca

**Tabla:** `dim_finca`

**Borra la condición de `seguridad` y escribe esta en `dim_finca`:**

```dax
[finca_id] = LOOKUPVALUE( seguridad[finca_id] , seguridad[correo] , USERPRINCIPALNAME() )
```

**Guardado.**

---

### D2 · Punto de Control 5 (tres correos que funcionan)

**Ver como, uno a la vez, con el rol `Por correo`:**

| Viendo como… | Filas en tabla | [Kilos] | [Cumplimiento] |
|---|---|---|---|
| gerente.launion@agrodb.test | | | |
| gerente.guayabo@agrodb.test | | | |
| practicante@agrodb.test | | | |

**Esperado:**
- gerente.launion: 1 fila, 2 100 kg, 42,00%
- gerente.guayabo: 1 fila, 14 250 kg, 150,95%
- practicante: 0 filas, (vacío), (vacío)

---

### D3 · Ver como regional.norte (el error)

**Ver como: `regional.norte@agrodb.test`, rol `Por correo`**

**Copia el mensaje de error completo:**

```
[Mensaje de error textual aquí]
```

---

### D4 · Por qué LOOKUPVALUE falla

**En dos líneas: `regional.norte` tiene dos filas en `seguridad`. ¿Por qué `LOOKUPVALUE` truena en vez de devolver una de las dos fincas? ¿Te conviene que truene?**

Respuesta:

---

### D5 · Prueba con direccion@agrodb.test

**En una línea: ¿Qué pasa con `direccion@agrodb.test`, y por qué?**

Respuesta:

---

## PARTE E · El arreglo (con IN y CALCULATETABLE)

**Quita Ver como**

### E1 · Nueva condición en dim_finca

```dax
[finca_id] IN
    CALCULATETABLE(
        VALUES( seguridad[finca_id] ),
        seguridad[correo] = USERPRINCIPALNAME()
    )
```

**Guardado.**

---

### E2 · Punto de Control 6 (los seis correos)

**Ver como, uno a la vez, con el rol `Por correo`:**

| Viendo como… | Filas | [Kilos] | [Meta] | [Filas de seguridad] | [Cumplimiento] |
|---|---|---|---|---|---|
| gerente.launion@agrodb.test | | | | | |
| gerente.guayabo@agrodb.test | | | | | |
| gerente.santarosa@agrodb.test | | | | | |
| regional.norte@agrodb.test | | | | | |
| direccion@agrodb.test | | | | | |
| practicante@agrodb.test | | | | | |

**Esperado:**
- gerente.launion: 1 fila, 2 100, 5 000, 3, 42,00%
- gerente.guayabo: 1 fila, 14 250, 9 440, 3, 150,95%
- gerente.santarosa: 1 fila, 14 200, 10 000, 2, 142,00%
- regional.norte: **2 filas, 16 350, 14 440, 6, 113,23%** ← **Número clave**
- direccion: 3 filas, 30 550, 24 440, 8, 125,00%
- practicante: 0 filas, (vacío)

---

### E3 · Punto de Control 7 (tabla del regional - LA CAPTURA)

**Ver como: `regional.norte@agrodb.test`, rol `Por correo`**

**Tabla con dim_finca[finca], [Kilos], [Cosechas], [Meta], [Filas de seguridad], [Cumplimiento]:**

| Finca | [Kilos] | [Cosechas] | [Meta] | [Filas de seguridad] | [Cumplimiento] |
|---|---|---|---|---|---|
| Agricola La Union | | | | | |
| Finca El Guayabo | | | | | |
| **Total** | | | | | |

**Esperado:**
- Total [Kilos]: 16 350
- Total [Meta]: 14 440
- Total [Cumplimiento]: **113,23%**

**CAPTURA: Esta tabla + la tarjeta [Quien mira] mostrando regional.norte@agrodb.test**

---

### E4 · Filas de seguridad en el gerente

**En una línea: viendo como `gerente.launion`, `[Filas de seguridad]` dice 3, no 1. Pon `seguridad[correo]` en una tabla y mira: ¿qué correos ve el gerente, y por qué?**

Respuesta:

---

### E5 · Comparación con ayer

**En dos líneas: los tres gerentes ven lo mismo que ayer con tres roles distintos. ¿Qué tiene de igual el rol de hoy con el `Gerente La Union` bien puesto de ayer, y qué tiene de distinto?**

Respuesta:

---

## PARTE F · Dar de alta a alguien sin tocar el rol

**Quita Ver como**

### F1 · Punto de Control 8 (auditor nuevo)

**Abre tu copia de `seguridad.csv` con Bloc de notas, agrega al final:**

```
auditor.santarosa@agrodb.test,1
```

**Guarda. En Power BI: Inicio → Actualizar. NO abras Administrar roles.**

**Ver como `auditor.santarosa@agrodb.test`, rol `Por correo`:**

| Qué miras | Valor esperado |
|---|---|
| `[Filas de seguridad]` sin rol (total) | 9 |
| Filas en tabla (con rol) | 1 |
| `[Kilos]` | 14 200 |
| `[Cumplimiento]` | 142,00% |

**Resultados reales:**

| Qué miras | Valor |
|---|---|
| `[Filas de seguridad]` total sin rol | |
| Filas en tabla | |
| `[Kilos]` | |
| `[Cumplimiento]` | |

---

### F2 · Sin tocar el rol

**En una línea: ¿cuántas veces abriste el rol para dar de alta al auditor? ¿Quién tiene ahora el poder de decidir quién ve qué?**

Respuesta:

---

## PARTE G · Preguntas de cierre

### G1
**En una línea: escribe la regla de dónde va la condición de un rol dinámico, y por qué NO va en la tabla de permisos aunque ahí esté el correo.**

Respuesta:

---

### G2
**En dos líneas: con el rol en `seguridad`, un correo que no está veía todo. Con el rol bueno, no ve nada. ¿Cuál de los dos comportamientos quieres, y por qué es la prueba que no se puede saltar?**

Respuesta:

---

### G3
**En dos líneas: el error de `LOOKUPVALUE` fue el único mensaje de error de la semana. Llevamos todo el curso diciendo "qué avisó: nada". ¿Ese error fue malo o bueno?**

Respuesta:

---

### G4
**En una línea: ¿Con qué tres correos pruebas siempre un rol dinámico, y qué atrapa cada uno?**

Respuesta:

---

### G5
**En una línea: `seguridad.csv` no tiene un solo kilo. ¿Por qué es tan delicado como `h_cosecha`?**

Respuesta:

---

## RESUMEN DE ENTREGAS

**Archivo:** `Ejercicio19_Byron_Yaguar.md` ✅ (este)

**Captura:** `clase19-ver-como.png`
- Tabla del regional con dos fincas
- Tarjeta [Quien mira] mostrando `regional.norte@agrodb.test`
- Ver como prendido, rol `Por correo` activo
