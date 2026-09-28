# Ejercicio práctico 19 · Un solo rol para cuarenta gerentes, y que el practicante no vea nada

**Estudiante:** Daniel Moises Troya Riofrio

---

## Parte A · La tabla de permisos

### A1 · Carga y relación
* **Detección de relación:** Power BI detectó y creó automáticamente la relación entre `seguridad[finca_id]` y `dim_finca[finca_id]`.
* **Configuración verificada:** Cardinalidad Muchos a uno (`* : 1`) desde `seguridad` hacia `dim_finca`, con Dirección del filtro cruzado en **Único**.

### A2 · Medidas de auditoría

```dax
Quien mira = USERPRINCIPALNAME()
```

```dax
Filas de seguridad = COUNTROWS( seguridad )
```

* **Valor de [Quien mira] (sin Ver como):** Muestra el usuario actual de Windows / cuenta local activa.

### A3 · Punto de control 1 (Sin seguridad aplicada)
* **Filtros fijados en segmentadores:** `anio = 2026`, `mes` en 1, 2, 3 y 4.

| Finca | [Kilos] | [Cosechas] | [Meta] | [Filas de seguridad] | [Cumplimiento] |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Agricola La Union | 2 100 | 2 | 5 000 | 3 | 42,00 % |
| Finca El Guayabo | 14 250 | 3 | 9 440 | 3 | 150,95 % |
| Hacienda Santa Rosa | 14 200 | 4 | 10 000 | 2 | 142,00 % |
| **Total** | **30 550** | **9** | **24 440** | **8** | **125,00 %** |

### A4 · Respuesta
La relación `dim_finca[finca_id] 1 -> * seguridad[finca_id]`, donde el filtro viaja desde `dim_finca` (lado 1) hacia `seguridad` (lado varios).

---

## Parte B · El rol obvio

### B1 · Rol Por correo (primera versión)

* **Tabla:** `seguridad`
* **Condición:**
```dax
[correo] = USERPRINCIPALNAME()
```
*(En la interfaz se usó la opción Cambiar al editor DAX).*

### B2 · Punto de control 2
* **Viendo como:** `gerente.launion@agrodb.test` con rol **Por correo**:
  * **[Quien mira]:** `gerente.launion@agrodb.test`
  * **[Filas de seguridad]:** 1
  * **[Kilos]:** 30 550
  * **[Cosechas]:** 9
  * **[Meta]:** 24 440
  * **[Cumplimiento]:** 125,00 %

### B3 · Respuesta
Ninguno; Power BI no arrojó ningún mensaje de error ni advertencia debido a que la sintaxis DAX es completamente válida.

### B4 · Respuesta
No prueba que el modelo esté protegido; únicamente prueba que la tabla `seguridad` se filtró a su propia fila correspondiente al correo evaluado.

### B5 · Respuesta
Además de `[Quien mira]`, la única tarjeta que cambió fue `[Filas de seguridad]` (bajó de 8 a 1); las métricas del negocio se mantuvieron inalteradas.

---

## Parte C · La fuga

### C1 · Punto de control 3
* **Viendo como:** `gerente.launion@agrodb.test` con rol **Por correo**:

| Finca | [Kilos] | [Cosechas] | [Meta] | [Filas de seguridad] | [Cumplimiento] |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Agricola La Union | 2 100 | 2 | 5 000 | 1 | 42,00 % |
| Finca El Guayabo | 14 250 | 3 | 9 440 | (vacío) | 150,95 % |
| Hacienda Santa Rosa | 14 200 | 4 | 10 000 | (vacío) | 142,00 % |
| **Total** | **30 550** | **9** | **24 440** | **1** | **125,00 %** |

### C2 · Respuesta
Solo cambió la columna `[Filas de seguridad]`; las columnas `[Kilos]`, `[Cosechas]`, `[Meta]` y `[Cumplimiento]` quedaron intactas. En realidad, el rol solo protegió la lectura de la lista de correos en `seguridad`, dejando expuesta toda la información operativa.

### C3 · Respuesta
Porque la relación va de `dim_finca` (lado 1) hacia `seguridad` (lado varios) con dirección de filtro único; el filtro desciende de `dim_finca` a `seguridad` y nunca puede viajar contra la flecha hacia `dim_finca` ni propagarse a las tablas de hechos (`h_cosecha` y `h_meta`).

### C4 · Punto de control 4
* **Viendo como:** `practicante@agrodb.test` con rol **Por correo**:
  * **[Quien mira]:** `practicante@agrodb.test`
  * **[Filas de seguridad]:** (vacío)
  * **[Kilos]:** 30 550
  * **[Cumplimiento]:** 125,00 %

### C5 · Respuesta
En la vida real, cualquier usuario no dado de alta entraría al reporte con visibilidad total de los datos corporativos; lo que debería suceder es que vea el reporte en blanco hasta que se le asigne explícitamente un permiso.

### C6 · Respuesta
Si una medida reporta exactamente lo mismo con el rol activo que sin el rol, el contexto de seguridad no está alcanzando a esa tabla de hechos.

---

## Parte D · El rol en la dimensión, primer intento

### D1 · Rol Por correo (segunda versión con LOOKUPVALUE)

* **Tabla:** `dim_finca`
* **Condición:**
```dax
[finca_id] = LOOKUPVALUE( seguridad[finca_id] , seguridad[correo] , USERPRINCIPALNAME() )
```

### D2 · Punto de control 5

| Viendo como… | Filas en la tabla por finca | [Kilos] | [Cumplimiento] |
| :--- | :--- | :--- | :--- |
| `gerente.launion@agrodb.test` | 1 | 2 100 | 42,00 % |
| `gerente.guayabo@agrodb.test` | 1 | 14 250 | 150,95 % |
| `practicante@agrodb.test` | 0 | (vacío) | (vacío) |

### D3 · Error textual con regional.norte@agrodb.test
* *La función 'LOOKUPVALUE' esperaba un único valor, pero se devolvieron varios valores.*  
*(En versiones en inglés: A table of multiple values was supplied where a single value was expected.)*

### D4 · Respuesta
`LOOKUPVALUE` exige estrictamente un resultado escalar (uno a uno) y falla al encontrar dos registros para el mismo correo; conviene que truene porque evidencia una falla arquitectónica en lugar de silenciar datos o mostrar accesos incompletos.

### D5 · Respuesta
`direccion@agrodb.test` también falla con error en los visuales porque tiene asignadas 3 filas en la tabla `seguridad`.

---

## Parte E · El arreglo

### E1 · Rol Por correo (versión final con IN y CALCULATETABLE)

* **Tabla:** `dim_finca`
* **Condición:**
```dax
[finca_id] IN
    CALCULATETABLE(
        VALUES( seguridad[finca_id] ),
        seguridad[correo] = USERPRINCIPALNAME()
    )
```

### E2 · Punto de control 6

| Viendo como… | Filas por finca | [Kilos] | [Meta] | [Filas de seguridad] | [Cumplimiento] |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `gerente.launion@agrodb.test` | 1 | 2 100 | 5 000 | 3 | 42,00 % |
| `gerente.guayabo@agrodb.test` | 1 | 14 250 | 9 440 | 3 | 150,95 % |
| `gerente.santarosa@agrodb.test` | 1 | 14 200 | 10 000 | 2 | 142,00 % |
| `regional.norte@agrodb.test` | 2 | 16 350 | 14 440 | 6 | 113,23 % |
| `direccion@agrodb.test` | 3 | 30 550 | 24 440 | 8 | 125,00 % |
| `practicante@agrodb.test` | 0 | (vacío) | (vacío) | (vacío) | (vacío) |

### E3 · Punto de control 7 (Captura requerida: clase19-ver-como.png)
* **Viendo como:** `regional.norte@agrodb.test` con rol **Por correo**:

| Finca | [Kilos] | [Cosechas] | [Meta] | [Filas de seguridad] | [Cumplimiento] |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Agricola La Union | 2 100 | 2 | 5 000 | 3 | 42,00 % |
| Finca El Guayabo | 14 250 | 3 | 9 440 | 3 | 150,95 % |
| **Total** | **16 350** | **5** | **14 440** | **6** | **113,23 %** |

*(La captura de pantalla adjunta muestra esta tabla junto a la tarjeta `[Quien mira]` indicando `regional.norte@agrodb.test`).*

### E4 · Respuesta
Ve los correos de todas las personas con acceso a Agrícola La Unión (por ejemplo el gerente local, el regional norte y dirección), porque el filtro aplicado en `dim_finca` se propaga en sentido natural hacia `seguridad`.

### E5 · Respuesta
Es igual en que el filtro final se materializa en la dimensión `dim_finca` y se propaga naturalmente a los hechos; es distinto en que no requiere un rol estático manual por usuario, sino una regla dinámica basada en datos.

---

## Parte F · Dar de alta a alguien sin tocar el rol

Línea agregada en `seguridad.csv`:

```csv
auditor.santarosa@agrodb.test,1
```

### F1 · Punto de control 8
* **[Filas de seguridad] total sin rol:** 9
* **Viendo como `auditor.santarosa@agrodb.test`:**
  * **Filas por finca:** 1 (Hacienda Santa Rosa)
  * **[Kilos]:** 14 200
  * **[Cumplimiento]:** 142,00 %

### F2 · Respuesta
Se abrió cero veces; el poder de decidir quién ve qué reside enteramente en el mantenimiento de los registros en la fuente de datos.

---

## Parte G · Preguntas de cierre

* **Regla de ubicación de la condición:**  
  La condición de un rol dinámico debe colocarse en las tablas dimensionales (`dim`), porque en un esquema estrella el contexto de filtro desciende de las dimensiones a los hechos y nunca en sentido contrario.

* **Comportamiento ante usuarios no registrados:**  
  Se busca la denegación por defecto (no ver nada), siendo una prueba indispensable para evitar fugas de información accidental ante omisiones en el alta de usuarios.

* **Evaluación del error de LOOKUPVALUE:**  
  Fue un error positivo, ya que alertó de inmediato sobre una suposición incorrecta de cardinalidad escalar (1 a 1) en lugar de ocultar registros o fallar silenciosamente.

* **Los tres correos de prueba obligatorios:**  
  Un usuario con un permiso único (valida el filtro individual), un usuario con permisos múltiples (valida la evaluación en lista) y un usuario no registrado (valida la denegación por defecto).

* **Sensibilidad de seguridad.csv:**  
  Aunque no contenga métricas, define el alcance del filtrado hacia `h_cosecha` y `h_meta`, por lo que su alteración puede comprometer toda la confidencialidad del modelo.