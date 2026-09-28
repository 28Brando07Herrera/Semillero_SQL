# Ejercicio 19 · Un solo rol para cuarenta gerentes, y que el practicante no vea nada

- **Alumno:** Cortez Cardozo Axel Josue
- **Ejercicio / proyecto:** Ejercicio 19 · Seguridad dinámica con USERPRINCIPALNAME y tabla de permisos
- **Archivo:** `entregas/cortez-axel/Ejercicio19_Cortez_Axel.md`

---

## Parte A · La tabla de permisos

### A1. Carga y relación
- La relación entre `seguridad` y `dim_finca` se configuró de forma manual.
- Cardinalidad: **Muchos a uno (`* : 1`)** (`seguridad` en el lado muchos).
- Dirección de filtro cruzado: **Único** (de `dim_finca` hacia `seguridad`).

### A2. Medidas
```dax
Quien mira = USERPRINCIPALNAME()
```

```dax
Filas de seguridad = COUNTROWS( seguridad )
```

### A3. Foto sin seguridad (Punto de control 1)

| Finca | [Kilos] | [Cosechas] | [Meta] | [Filas de seguridad] | [Cumplimiento] |
|---|---|---|---|---|---|
| Agricola La Union | 2 100 | 2 | 5 000 | 3 | 42,00 % |
| Finca El Guayabo | 14 250 | 3 | 9 440 | 3 | 150,95 % |
| Hacienda Santa Rosa | 14 200 | 4 | 10 000 | 2 | 142,00 % |
| **Total** | **30 550** | **9** | **24 440** | **8** | **125,00 %** |

### A4. Respuesta
La relación `dim_finca[finca_id] 1 --> * seguridad[finca_id]` en dirección Único propaga el contexto de filtro desde la dimensión hacia la tabla de permisos cuando la finca está en el eje/filas del visual.

---

## Parte B · El rol obvio

### B1. Rol Por correo (primera versión)
```
Tabla:     seguridad
Condición: [correo] = USERPRINCIPALNAME()
```

### B2. Ver como otro usuario (Punto de control 2)
Viendo como `gerente.launion@agrodb.test`:

| Medida | Valor |
|---|---|
| `[Quien mira]` | gerente.launion@agrodb.test |
| `[Filas de seguridad]` | 1 |
| `[Kilos]` | 30 550 |
| `[Cosechas]` | 9 |
| `[Meta]` | 24 440 |
| `[Cumplimiento]` | 125,00 % |

### B3. Mensaje de error o advertencia
Power BI no arrojó ningún error ni advertencia; evaluó la sesión de forma completamente silenciosa.

### B4. Respuesta
No prueba que el modelo esté protegido; únicamente prueba que la condición filtró la tabla física `seguridad` a 1 fila, pero el resto de datos de negocio quedó desprotegido.

### B5. Respuesta
Únicamente se movió `[Filas de seguridad]` (bajó de 8 a 1); los kilos, metas y cosechas permanecieron completamente intactos.

---

## Parte C · La fuga

### C1. La finca en las filas (Punto de control 3)
Viendo como `gerente.launion@agrodb.test` con el rol en `seguridad`:

| Finca | [Kilos] | [Cosechas] | [Meta] | [Filas de seguridad] | [Cumplimiento] |
|---|---|---|---|---|---|
| Agricola La Union | 2 100 | 2 | 5 000 | 1 | 42,00 % |
| Finca El Guayabo | 14 250 | 3 | 9 440 | (vacío) | 150,95 % |
| Hacienda Santa Rosa | 14 200 | 4 | 10 000 | (vacío) | 142,00 % |
| **Total** | **30 550** | **9** | **24 440** | **1** | **125,00 %** |

### C2. Comparación
Solo cambió la columna `[Filas de seguridad]`, que ahora solo muestra conteo para La Unión y deja las demás vacías; los kilos, cosechas y metas de las otras fincas siguieron visibles. El rol solo protegió los metadatos de la tabla de permisos.

### C3. Por qué no filtra el resto
Porque la relación va de `dim_finca` (lado 1) hacia `seguridad` (lado muchos) con dirección de filtro único. Un filtro aplicado directamente en `seguridad` no puede viajar en sentido contrario ("río arriba") hacia `dim_finca`, por lo que nunca alcanza a `h_cosecha` ni a `h_meta`.

### C4. El que no está (Punto de control 4)
Viendo como `practicante@agrodb.test` con el rol en `seguridad`:

| Medida | Valor |
|---|---|
| `[Quien mira]` | practicante@agrodb.test |
| `[Filas de seguridad]` | (vacío) |
| `[Kilos]` | 30 550 |
| `[Cumplimiento]` | 125,00 % |

### C5. Impacto en la vida real
Si alguien olvida registrar a un nuevo usuario, el sistema le muestra por defecto la totalidad de los datos de la empresa. Lo correcto y seguro es que por defecto no vea absolutamente nada (principio de menor privilegio).

### C6. Regla de detección
Si un rol colocado en una tabla satélite no tiene propagación activa hacia las dimensiones de las que dependen los hechos, el RLS es meramente decorativo.

---

## Parte D · El rol en la dimensión, primer intento

### D1. Condición con LOOKUPVALUE en `dim_finca`
```dax
[finca_id] = LOOKUPVALUE( seguridad[finca_id] , seguridad[correo] , USERPRINCIPALNAME() )
```

### D2. Tres correos (Punto de control 5)

| Viendo como… | Filas en la tabla por finca | [Kilos] | [Cumplimiento] |
|---|---|---|---|
| gerente.launion@agrodb.test | 1 | 2 100 | 42,00 % |
| gerente.guayabo@agrodb.test | 1 | 14 250 | 150,95 % |
| practicante@agrodb.test | 0 | (vacío) | (vacío) |

### D3. Error con regional.norte
Mensaje textual capturado:
`Se proporcionó una tabla de varios valores donde se esperaba un solo valor.`

### D4. Comportamiento de LOOKUPVALUE
`LOOKUPVALUE` exige por diseño escalar que la búsqueda devuelva exactamente una coincidencia o blanco; al encontrar dos filas para ese correo arroja error. Conviene que truene porque evita que el sistema elija arbitrariamente una sola finca y oculte la otra sin avisar.

### D5. Prueba con direccion@agrodb.test
También produce error de cardinalidad múltiple, debido a que la dirección tiene asignadas las 3 fincas en la tabla de permisos.

---

## Parte E · El arreglo

### E1. Condición con IN y CALCULATETABLE
```
Tabla:     dim_finca
Condición:
[finca_id] IN
    CALCULATETABLE(
        VALUES( seguridad[finca_id] ),
        seguridad[correo] = USERPRINCIPALNAME()
    )
```

### E2. Los seis correos (Punto de control 6)

| Viendo como… | Filas por finca | [Kilos] | [Meta] | [Filas de seguridad] | [Cumplimiento] |
|---|---|---|---|---|---|
| gerente.launion@agrodb.test | 1 | 2 100 | 5 000 | 3 | 42,00 % |
| gerente.guayabo@agrodb.test | 1 | 14 250 | 9 440 | 3 | 150,95 % |
| gerente.santarosa@agrodb.test | 1 | 14 200 | 10 000 | 2 | 142,00 % |
| regional.norte@agrodb.test | 2 | 16 350 | 14 440 | 6 | 113,23 % |
| direccion@agrodb.test | 3 | 30 550 | 24 440 | 8 | 125,00 % |
| practicante@agrodb.test | 0 | (vacío) | (vacío) | (vacío) | (vacío) |

### E3. Tabla del regional (Punto de control 7)
Viendo como `regional.norte@agrodb.test`:

| Finca | [Kilos] | [Cosechas] | [Meta] | [Filas de seguridad] | [Cumplimiento] |
|---|---|---|---|---|---|
| Agricola La Union | 2 100 | 2 | 5 000 | 3 | 42,00 % |
| Finca El Guayabo | 14 250 | 3 | 9 440 | 3 | 150,95 % |
| **Total** | **16 350** | **5** | **14 440** | **6** | **113,23 %** |

*(Se anexa captura `clase19-ver-como.png` con la barra de visualización activa).*

### E4. Correos que ve el gerente
El gerente ve todos los correos asociados a su finca (3 filas: él mismo, el regional y la dirección), porque `dim_finca` filtra hacia abajo a `seguridad` mostrando todos los permisos vinculados a esa finca.

### E5. Comparativa con roles estáticos
Es igual en el resultado analítico que ve el usuario final (los datos de su finca), pero difiere estructuralmente en que es una regla dinámica parametrizada: un único rol gobierna a todos los usuarios sin requerir crear ni mantener un rol manual por cada finca.

---

## Parte F · Dar de alta a alguien sin tocar el rol

### F1. Modificación de seguridad.csv y actualización (Punto de control 8)
Línea agregada: `auditor.santarosa@agrodb.test,1`

| Dónde | Valor |
|---|---|
| `[Filas de seguridad]` sin rol, total | 9 |
| Viendo como auditor.santarosa@agrodb.test: filas por finca | 1 |
| …`[Kilos]` | 14 200 |
| …`[Cumplimiento]` | 142,00 % |

### F2. Respuesta
Cero veces; el rol DAX no se abrió. La administración de acceso pasó de ser un mantenimiento de desarrollo a un proceso puramente operativo de gestión de datos.

---

## Parte G · Preguntas de cierre

1. La condición de seguridad dinámica debe residir en la tabla de dimensiones para que el filtro descienda de forma natural (1 a muchos) hacia las tablas de hechos; en la tabla de permisos queda estancado debido a la dirección del filtro.
2. Se requiere que el usuario no registrado no vea nada; es la prueba indispensable para garantizar el principio de denegación por defecto y evitar fugas de información ante omisiones administrativas.
3. Fue un error sumamente útil y positivo, ya que alertó de inmediato sobre una limitación de diseño de cardinalidad en lugar de fallar de manera encubierta o entregar datos incompletos.
4. Se prueba con un usuario con permiso único (gerente), uno con múltiples permisos (regional) y uno sin permisos (practicante), verificando filtrado exacto, agregación multi-entidad y denegación por defecto respectivamente.
5. Porque controlar quién tiene acceso a la información es tan crítico como el dato mismo; una alteración en la tabla de permisos abre o cierra el acceso a todas las tablas de hechos operativas.