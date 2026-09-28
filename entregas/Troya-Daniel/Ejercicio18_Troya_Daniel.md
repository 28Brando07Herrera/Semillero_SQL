# Ejercicio práctico 18 · Mándale el tablero al gerente de La Unión sin enseñarle lo de los demás

**Estudiante:** Daniel Moises Troya Riofrio

---

## Parte A · La foto sin seguridad

### A1 · Tabla por finca (sin roles)

| Finca | [Kilos] | [Cosechas] | [Meta] | [Filas de meta] | [Cumplimiento] |
| :--- | :---: | :---: | :---: | :---: | :---: |
| Agricola La Union | 2 100 | 2 | 5 000 | 4 | 42,00 % |
| Finca El Guayabo | 14 250 | 3 | 9 440 | 4 | 150,95 % |
| Hacienda Santa Rosa | 14 200 | 4 | 10 000 | 4 | 142,00 % |
| **Total** | **30 550** | **9** | **24 440** | **12** | **125,00 %** |

### A2 · Columnas expuestas
Todas las columnas exponen datos ajenos: `[finca]` expone los nombres de los competidores/otras fincas, `[Kilos]` y `[Cosechas]` revelan su volumen operativo, y `[Meta]`, `[Filas de meta]` y `[Cumplimiento]` exponen sus objetivos corporativos y nivel de rendimiento.

---

## Parte B · El rol obvio

### B1 · Rol Gerente La Union (primera versión)
* **Tabla:** `h_cosecha`
* **Condición:**
```dax
[finca_id] = 3
```

* **Viendo como Gerente La Union:**
  * `[Kilos]`: 2 100
  * `[Cosechas]`: 2
  * `[Meta]`: 24 440
  * `[Cumplimiento]`: 8,59 %

### B3 · Mensaje de error o advertencia
Power BI no arrojó ningún mensaje de error ni advertencia; la sintaxis DAX es válida y evaluó la consulta con éxito silencioso.

### B4 · ¿Habrías dado el rol por bueno?
Sí, mirar únicamente las métricas que dependen directamente de la tabla filtrada (`h_cosecha`) crea una falsa ilusión de éxito porque esos números sí coincidían con La Unión.

### B5 · Comparación de meta y origen del 8,59 %
Se está comparando contra la meta global de toda la empresa (24 440 kg en lugar de los 5 000 kg de su finca). El 8,59 % corresponde al aporte real de los kilos de La Unión frente a la meta agregada de la compañía que vimos en el total sin segmentar.

---

## Parte C · La fuga

### C1 · Tabla por finca con rol en h_cosecha

| Finca | [Kilos] | [Cosechas] | [Meta] | [Filas de meta] | [Cumplimiento] |
| :--- | :---: | :---: | :---: | :---: | :---: |
| Agricola La Union | 2 100 | 2 | 5 000 | 4 | 42,00 % |
| Finca El Guayabo | *(en blanco)* | *(en blanco)* | 9 440 | 4 | *(en blanco)* |
| Hacienda Santa Rosa | *(en blanco)* | *(en blanco)* | 10 000 | 4 | *(en blanco)* |
| **Total** | **2 100** | **2** | **24 440** | **12** | **8,59 %** |

### C2 · Información fugada
Tiene en pantalla los nombres de las fincas ajenas (`Finca El Guayabo` y `Hacienda Santa Rosa`), sus metas numéricas individuales (`9 440` y `10 000`) y la cantidad de registros de meta planificados (`4` filas cada una).

### C3 · ¿Por qué aparecen las otras fincas?
Aparecen porque la visualización contiene medidas de `h_meta` que sí devuelven valores no vacíos para esas fincas, forzando a la dimensión a conservar las filas en la agrupación visual.

### C4 · Opciones en el segmentador
El segmentador de fincas ofrece las 3 opciones (`Agricola La Union`, `Finca El Guayabo`, `Hacienda Santa Rosa`) porque la tabla `dim_finca` no tiene ningún filtro aplicado.

### C5 · Filas de meta
* `[Filas de meta]` sin rol: 12
* `[Filas de meta]` viendo como Gerente La Union: 12

### C6 · Dirección del filtro en el modelo
El filtro aplicado a `h_cosecha` no puede viajar en sentido inverso por la relación muchos a uno hacia `dim_finca`, por lo que nunca llega a propagarse hacia `h_meta`.

### C7 · Regla de detección
Si una medida de hechos ajenos no reduce su conteo de filas ni sus totales bajo RLS, el rol está puesto en un hecho y no en la dimensión que los conecta.

---

## Parte D · Los otros dos gerentes

### D1 · Roles mal puestos en h_cosecha

* **Rol Gerente El Guayabo:**
  * **Tabla:** `h_cosecha`
  * **Condición:** `[finca_id] = 2`
  * **Viendo como Gerente El Guayabo, [Cumplimiento]:** 58,31 %

* **Rol Gerente Santa Rosa:**
  * **Tabla:** `h_cosecha`
  * **Condición:** `[finca_id] = 1`
  * **Viendo como Gerente Santa Rosa, [Cumplimiento]:** 58,10 %

### D2 · Suma de los cumplimientos
$$8,59\% + 58,31\% + 58,10\% = 125,00\%$$  
Coincide exactamente con el cumplimiento global de toda la empresa obtenido en el Total de la Parte A.

### D3 · Consecuencia en la toma de decisiones
El gerente de El Guayabo asumiría que está rindiendo muy por debajo de lo esperado (58,31 %) cuando en realidad superó ampliamente su meta individual (150,95 %), lo que podría llevarlo a forzar operaciones o tomar decisiones operativas erradas innecesariamente.

### D4 · Selección simultánea de dos roles
Al marcar dos roles en "Ver como", los kilos de ambos roles se acumulan mediante una operación lógica de unión (`OR`), sumando el volumen cosechado de ambas fincas.

---

## Parte E · El rol en la dimensión

### E1 · Roles corregidos en dim_finca

* **Rol:** Gerente La Union  
  * **Tabla:** `dim_finca`  
  * **Condición:** `[finca] = "Agricola La Union"`

* **Rol:** Gerente El Guayabo  
  * **Tabla:** `dim_finca`  
  * **Condición:** `[finca] = "Finca El Guayabo"`

* **Rol:** Gerente Santa Rosa  
  * **Tabla:** `dim_finca`  
  * **Condición:** `[finca] = "Hacienda Santa Rosa"`

### E2 · Tabla viendo como Gerente La Union (rol en dim_finca)

| Finca | [Kilos] | [Cosechas] | [Meta] | [Filas de meta] | [Cumplimiento] |
| :--- | :---: | :---: | :---: | :---: | :---: |
| Agricola La Union | 2 100 | 2 | 5 000 | 4 | 42,00 % |
| **Total** | **2 100** | **2** | **5 000** | **4** | **42,00 %** |

### E3 · Confiabilidad de la tarjeta de kilos
Una tarjeta aislada de kilos es una prueba incompleta y engañosa, ya que un rol mal ubicado filtra su propio hecho pero deja el resto del modelo sin protección.

### E4 · Validación de los tres gerentes

| Viendo como… | [Meta] | [Filas de meta] | [Cumplimiento] |
| :--- | :---: | :---: | :---: |
| Gerente La Union | 5 000 | 4 | 42,00 % |
| Gerente El Guayabo | 9 440 | 4 | 150,95 % |
| Gerente Santa Rosa | 10 000 | 4 | 142,00 % |

### E5 · Llegada de nueva tabla h_jornales
Al estar en `dim_finca`, la nueva tabla `h_jornales` queda protegida automáticamente en cuanto se relacione con la dimensión; si hubiera quedado en `h_cosecha`, no tendría ningún tipo de seguridad y filtraría datos ajenos.

---

## Parte F · Lo que el rol no deja ver, tampoco lo ve DAX

### F1 · Medida de Participación

```dax
Participacion = DIVIDE( [Kilos] , CALCULATE( [Kilos] , ALL( dim_finca ) ) )
```

#### Tabla sin rol:

| Finca | [Participacion] sin rol |
| :--- | :--- |
| Agricola La Union | 6,87 % |
| Finca El Guayabo | 46,64 % |
| Hacienda Santa Rosa | 46,48 % |
| **Total** | **100,00 %** |

### F2 · Participación con rol
* **Viendo como Gerente La Union:**
  * **Agricola La Union:** 100,00 %
  * **Total:** 100,00 %

### F3 · Comportamiento de ALL() frente a RLS
`ALL(dim_finca)` elimina los filtros del contexto de evaluación visual, pero no puede recuperar filas restringidas por RLS porque la seguridad por fila actúa antes de la capa DAX, haciendo que las filas restringidas no existan en la memoria del modelo para esa sesión.

### F4 · Solución de negocio para la participación
No se soluciona modificando la fórmula DAX; el negocio o la gerencia general debe definir formalmente si autoriza exponer métricas agregadas globales antes de rediseñar la arquitectura de datos (por ejemplo, mediante una tabla precalculada y desconectada).

---

## Parte G · Preguntas de cierre

* **Regla de ubicación de roles:**  
  El rol de seguridad se coloca siempre en la tabla de dimensión (lado "uno" de la relación) para que el filtro baje naturalmente en cascada hacia todas las tablas de hechos asociadas.

* **Seguridad en base de datos vs modelo:**  
  En la base de datos el motor valida permisos explícitos y corta el acceso mediante errores (excepciones como `ORA-00942`), mientras que en el modelo analítico Power BI simplemente filtra datos sin emitir alertas, evaluando fórmulas sobre subconjuntos incompletos o errados de forma silenciosa.

* **Prueba visual real de roles:**  
  Se debe colocar la dimensión protegida en las filas de una tabla y un conteo de auditoría en los hechos secundarios (`[Filas de meta]`); una tarjeta aislada con la métrica principal no sirve como prueba definitiva.

* **Comparación de causa raíz (Clase 17 vs Clase 18):**  
  Es conceptualmente el mismo error de diseño: una ausencia de propagación del contexto de filtro bidireccional o jerárquico hacia `h_meta` por la dirección natural de las relaciones.

* **Medida detectora:**  
  La medida de control fue `[Filas de meta]`, definida como `COUNTROWS( h_meta )`.