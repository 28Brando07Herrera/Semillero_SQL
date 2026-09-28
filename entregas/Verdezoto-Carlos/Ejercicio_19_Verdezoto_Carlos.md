# Ejercicio 19 · AgroDB

## PARTE A - LA TABLA DE PERMISOS

**A1.** La relación `seguridad[finca_id]` → `dim_finca[finca_id]` fue creada con cardinalidad **Muchos a uno** (donde `seguridad` es el lado de muchos) y la dirección del filtro cruzado en **Único**[cite: 7].

**A2.** La tarjeta `[Quien mira]` muestra correctamente mi correo/usuario de Windows al estar sin el rol activado[cite: 7].

**A3. Punto de control 1:**[cite: 7]
| Finca | `[Kilos]` | `[Cosechas]` | `[Meta]` | `[Filas de seguridad]` | `[Cumplimiento]` |
|---|---|---|---|---|---|
| Agricola La Union | 2 100 | 2 | 5 000 | 3 | 42,00 % |
| Finca El Guayabo | 14 250 | 3 | 9 440 | 3 | 150,95 % |
| Hacienda Santa Rosa | 14 200 | 4 | 10 000 | 2 | 142,00 % |
| **Total** | **30 550** | **9** | **24 440** | **8** | **125,00 %** |

**A4.** El filtro se parte por finca porque la relación va desde `dim_finca` (lado 1) hacia `seguridad` (lado varios) en dirección **Única**. El contexto de filtro fluye "hacia abajo" con normalidad[cite: 7].

---

## PARTE B - EL ROL OBVIO

### B1 · Rol Por correo (primera versión)
```dax
Tabla:     seguridad
Condición: [correo] = USERPRINCIPALNAME()


Resultado viendo como gerente.launion@agrodb.test, `[Filas de seguridad]`: 1

**B2. Punto de control 2:**

| Medida | Viendo como gerente.launion@agrodb.test |
| --- | --- |
| `[Quien mira]` | gerente.launion@agrodb.test |
| `[Filas de seguridad]` | 1 |
| `[Kilos]` | 30 550 |
| `[Cosechas]` | 9 |
| `[Meta]` | 24 440 |
| `[Cumplimiento]` | 125,00 % |

**B3.** Ninguno. Power BI no da ninguna advertencia de que la seguridad esté mal aplicada o incompleta para el resto del modelo.

**B4.** No, no prueba que el rol asegure la información de la empresa. Solo prueba que el rol está filtrando con éxito la tabla de `seguridad` en sí misma.

**B5.** Únicamente se movieron `[Quien mira]` y `[Filas de seguridad]`. Todas las demás tarjetas de negocio (`[Kilos]`, `[Cosechas]`, etc.) quedaron intactas con los totales globales.

---

## PARTE C - LA FUGA

**C1. Punto de control 3:**

| Finca | `[Kilos]` | `[Cosechas]` | `[Meta]` | `[Filas de seguridad]` | `[Cumplimiento]` |
| --- | --- | --- | --- | --- | --- |
| Agricola La Union | 2 100 | 2 | 5 000 | 1 | 42,00 % |
| Finca El Guayabo | 14 250 | 3 | 9 440 | *(vacío)* | 150,95 % |
| Hacienda Santa Rosa | 14 200 | 4 | 10 000 | *(vacío)* | 142,00 % |
| **Total** | **30 550** | **9** | **24 440** | **1** | **125,00 %** |

**C2.** Solo cambió la columna `[Filas de seguridad]`. El rol únicamente protegió la tabla de permisos, dejando toda la información de kilos y metas completamente expuesta.

**C3.** Porque la relación va de `dim_finca` (1) a `seguridad` (Varios). Los filtros no pueden viajar "hacia arriba" (en contra de la flecha) desde el lado de los muchos hacia la dimensión, por lo que el resto del modelo jamás se entera del filtro.

**C4. Punto de control 4:**

| Medida | Viendo como practicante@agrodb.test |
| --- | --- |
| `[Quien mira]` | practicante@agrodb.test |
| `[Filas de seguridad]` | *(vacío)* |
| `[Kilos]` | 30 550 |
| `[Cumplimiento]` | 125,00 % |

**C5.** Si alguien olvida dar de alta a un usuario, ese usuario verá toda la información de la empresa (fuga masiva). Lo que debería pasar es que, por defecto, se aplique un acceso denegado y no vea nada.

**C6.** Regla de detección: Si una medida principal (como Kilos) vale lo mismo con el rol puesto que sin el rol, el filtro del rol no está alcanzando a esa tabla de hechos.

---

## PARTE D - EL ROL EN LA DIMENSIÓN, PRIMER INTENTO

### D1 · Rol en la dimensión (con LOOKUPVALUE)

```dax
Tabla:     dim_finca
Condición: [finca_id] = LOOKUPVALUE( seguridad[finca_id] , seguridad[correo] , USERPRINCIPALNAME() )

```

**D2. Punto de control 5:**

| Viendo como… | Filas en la tabla por finca | `[Kilos]` | `[Cumplimiento]` |
| --- | --- | --- | --- |
| gerente.launion@agrodb.test | 1 | 2 100 | 42,00 % |
| gerente.guayabo@agrodb.test | 1 | 14 250 | 150,95 % |
| practicante@agrodb.test | 0 | *(vacío)* | *(vacío)* |

**D3.** Mensaje textual de error: *"Se proporcionó una tabla de varios valores donde se esperaba un solo valor."* (A table of multiple values was supplied where a single value was expected).

**D4.** Truena porque `LOOKUPVALUE` está diseñado para devolver obligatoriamente un solo resultado escalar, y el regional tiene dos fincas. Sí conviene que truene, es mejor un error ruidoso que una filtración silenciosa de datos.

**D5.** Ocurre exactamente el mismo error. Al estar asignado a las tres fincas, `LOOKUPVALUE` encuentra tres valores y rompe la medida.

---

## PARTE E - EL ARREGLO

### E1 · Rol definitivo (con IN y CALCULATETABLE)

```dax
Tabla:     dim_finca
Condición: [finca_id] IN CALCULATETABLE( VALUES( seguridad[finca_id] ), seguridad[correo] = USERPRINCIPALNAME() )

```

**E2. Punto de control 6:**

| Viendo como… | Filas por finca | `[Kilos]` | `[Meta]` | `[Filas de seguridad]` | `[Cumplimiento]` |
| --- | --- | --- | --- | --- | --- |
| gerente.launion@agrodb.test | 1 | 2 100 | 5 000 | 3 | 42,00 % |
| gerente.guayabo@agrodb.test | 1 | 14 250 | 9 440 | 3 | 150,95 % |
| gerente.santarosa@agrodb.test | 1 | 14 200 | 10 000 | 2 | 142,00 % |
| regional.norte@agrodb.test | 2 | 16 350 | 14 440 | 6 | 113,23 % |
| direccion@agrodb.test | 3 | 30 550 | 24 440 | 8 | 125,00 % |
| practicante@agrodb.test | 0 | *(vacío)* | *(vacío)* | *(vacío)* | *(vacío)* |

**E3. Punto de control 7 (viendo como regional.norte):**

| Finca | `[Kilos]` | `[Cosechas]` | `[Meta]` | `[Filas de seguridad]` | `[Cumplimiento]` |
| --- | --- | --- | --- | --- | --- |
| Agricola La Union | 2 100 | 2 | 5 000 | 3 | 42,00 % |
| Finca El Guayabo | 14 250 | 3 | 9 440 | 3 | 150,95 % |
| **Total** | **16 350** | **5** | **14 440** | **6** | **113,23 %** |

**E4.** Ve a `gerente.launion`, `regional.norte` y `direccion`. Esto ocurre porque el RLS filtra `dim_finca` a La Unión, y ese filtro baja por la relación hacia `seguridad`, mostrando a todos los correos que tienen acceso a esa finca.

**E5.** Funcionalmente, el filtro sobre los datos es idéntico: ven exactamente la misma información. Lo distinto es que hoy es dinámico (un solo rol gobierna a todos) y ayer el rol era estático (un rol forzado por cada gerente).

---

## PARTE F - DAR DE ALTA A ALGUIEN SIN TOCAR EL ROL

**F1. Punto de control 8:**

| Dónde | Qué debe decir |
| --- | --- |
| `[Filas de seguridad]` sin rol, total | 9 |
| Viendo como auditor.santarosa@agrodb.test: filas por finca | 1 |
| …`[Kilos]` | 14 200 |
| …`[Cumplimiento]` | 142,00 % |

**F2.** Cero veces, no tuve que abrir el rol. El poder lo tiene ahora el administrador de la base de datos o el encargado del archivo `seguridad.csv`, no el desarrollador de Power BI.

---

## PARTE G - PREGUNTAS DE CIERRE

1. **¿Dónde va la condición de un rol dinámico?** Va siempre en la tabla de Dimensión, para que el filtro fluya hacia abajo a los hechos. No va en la tabla de permisos porque los filtros no fluyen hacia arriba (del lado Varios al lado 1).


2. **¿Cuál de los dos comportamientos quieres?** Se quiere el comportamiento de "no ver nada" (default deny). Es la prueba crucial porque asegura que un olvido administrativo no resulte en una fuga de datos confidenciales.


3. **¿Ese error fue malo o bueno?** Fue muy bueno. Actuó como un guardián ruidoso que impidió que el modelo aplicara una seguridad defectuosa para usuarios con múltiples fincas.


4. **¿Con qué tres correos pruebas siempre?** 1) Un gerente de una sola finca (prueba el filtrado básico), 2) Un perfil multi-finca (prueba que la lógica soporte múltiples valores), 3) Un usuario desconocido (prueba el default-deny).


5. **¿Por qué es tan delicado como `h_cosecha`?** Porque estructuralmente actúa como una tabla de hechos (está en el lado de los "muchos"). Si los filtros no se configuran para salir de ahí mediante DAX, el modelo de seguridad es inútil.



```

```