# Ejercicio práctico 24 · Mini proyecto: el tablero de la gerencia

* **Estudiante:** Daniel Moisés Troya Riofrío

* **Asignatura / Ejercicio:** Ejercicio práctico 24 · Mini proyecto: el tablero de la gerencia

* **Entorno / Herramienta:** Power BI Desktop

## 1. Checklist de Calificación

| \# | Lo que salió en mi pantalla | Qué trampa descarta | 
 | ----- | ----- | ----- | 
| 1 | 6 tablas y 6 relaciones, todas `* → 1`, con `h_meta[fecha_mes]` unida a `dim_tiempo[fecha]`. | Descarta la relación que falta entre la tabla de metas y el calendario (clases 14 y 17). | 
| 2 | Tabla por finca: metas 5 000 / 9 440 / 10 000 y total 30 550 / 24 440 / 125,00 %. | Descarta la meta sin filtro de fecha (65,00 %) o sin filtro de finca (24 440 repetido en cada fila) (clase 17). | 
| 3 | Agrícola La Unión en rojo (42,00 %), El Guayabo en verde (150,95 %), Santa Rosa en verde (142,00 %), y total en verde (125,00 %). | Descarta la regla condicional con "Porcentaje", que interpreta 142 % fuera de escala o pinta a Santa Rosa de rojo y omite el total (clase 23). | 
| 4 | Tabla por cultivo (4 filas): Mango 12 700 (más oscuro), Maíz 9 800, Guayaba 5 950, Cacao 2 100 (blanco). Banano y Café no aparecen por no tener movimiento en 2026. | Descarta el color que no se sabe contra qué compara y la inclusión errónea de registros sin datos en el periodo (clase 23). | 
| 5 | KPI del año: 30 550 contra 24 440 (+25,00 %), título "Acumulado del año contra meta"; tarjetas: Kilos (30 550), Cumplimiento (125,00 %), Quien mira. | Descarta el KPI que enseña solo abril (19 750) por omitir YTD o marzo (10 800) por falta de orden cronológico en `nombre_mes` (clases 16 y 23). | 
| 6 | `[Quien mira]` = `gerente.launion@agrodb.test`, 1 sola fila en fincas: 2 100 / 5 000 / 42,00 % en rojo, KPI −58,00 %, tabla de cultivo solo muestra Cacao (2 100). | Descarta aplicar el rol en `h_cosecha` (que deja ver metas ajenas, 8,59 %) o en `seguridad` (mostrando el 125,00 % global) (clases 18 y 19). | 
| 7 | `[Quien mira]` = `regional.norte@agrodb.test`, dos filas (La Unión y El Guayabo), total 16 350 / 14 440 / 113,23 % en verde, KPI +13,23 %. | Descarta el uso de `LOOKUPVALUE` o comparadores escalares `=` que fallan al evaluar usuarios con dos o más fincas asignadas (clase 19). | 
| 8 | `[Quien mira]` = `practicante@agrodb.test`, ninguna fila en tablas, tarjetas de métricas y KPI vacíos. | Descarta la puerta abierta donde un usuario no registrado o sin asignación ve la totalidad de la información corporativa (30 550) (clase 19). | 
| 9 | `[Quien mira]` = `practicante@agrodb.test` (tras alta en `seguridad.csv` y actualización), 1 fila: Santa Rosa 14 200 / 10 000 / 142,00 % en verde, KPI +42,00 %. | Descarta el rol estático que obliga a reabrir y modificar Power BI Desktop para autorizar o dar de alta permisos operativos (clase 19). | 
| 10 | Checklist completo con resultados validados, 7 medidas DAX, rol RLS dinámico en bloques de código y justificaciones teóricas de control. | Descarta llegar a los valores esperados por simple copia o tanteo sin entender el modelo estrella ni el flujo de filtros (clases 14 a 23). | 

## 2. Medidas DAX

```
Kilos = SUM( h_cosecha[kg] )

```

```
Meta = SUM( h_meta[kg_meta] )

```

```
Cumplimiento = DIVIDE( [Kilos] , [Meta] )

```

```
Kilos YTD = TOTALYTD( [Kilos] , dim_tiempo[fecha] )

```

```
Meta YTD = TOTALYTD( [Meta] , dim_tiempo[fecha] )

```

```
Color cumplimiento = IF( [Cumplimiento] >= 1 , "#1E8449" , "#C0392B" )

```

```
Quien mira = USERPRINCIPALNAME()

```

## 3. Seguridad a Nivel de Fila (RLS)

* **Nombre del rol:** `Por correo`

* **Tabla filtrada:** `dim_finca`

* **Expresión DAX:**

```
[finca_id] IN
    CALCULATETABLE(
        VALUES( seguridad[finca_id] ),
        seguridad[correo] = USERPRINCIPALNAME()
    )

```

## 4. Respuestas a Preguntas Conceptuales

### A3a. Detección automática de relaciones

**Pregunta:** La relación 5 es la única con nombres distintos en sus dos puntas (`h_meta[fecha_mes]` y `dim_tiempo[fecha]`). ¿Qué habría pasado con ella si dejabas prendida la detección automática?

**Respuesta:** Power BI no habría creado la relación porque el motor de detección automática busca coincidencias exactas en el nombre de la columna además de la compatibilidad del tipo de dato. Como consecuencia, `h_meta` habría quedado huérfana de tiempo, arrojando la meta anual total sin filtrar en la tabla o mostrando cálculos erróneos.

### A3b. Relación entre `dim_cultivo` y `h_meta`

**Pregunta:** ¿Por qué no hay relación entre `dim_cultivo` y `h_meta`?

**Respuesta:** Porque la granularidad de las metas está definida a nivel de finca y mes, no por cultivo individual. Relacionar `dim_cultivo` directamente con `h_meta` forzaría una dimensión no correspondiente con los hechos del presupuesto, provocando multiplicaciones cruzadas o relaciones ambiguas en el modelo.

### D5. Ubicación de la regla RLS

**Pregunta:** Si el rol estuviera en la tabla `seguridad`, ¿qué vería el practicante? ¿Y por qué eso es peor que un error?

**Respuesta:** El practicante vería toda la empresa (30 550 kilos y 125,00 % de cumplimiento), debido a que la relación entre `seguridad` y `dim_finca` es de muchos a uno con dirección de filtro único hacia `seguridad`, por lo que filtrar `seguridad` no propaga ningún filtro hacia las dimensiones ni los hechos. Es mucho peor que un error visible porque no emite ninguna advertencia en pantalla y genera una fuga inadvertida de datos confidenciales.

### E1. Gobernanza y administración de accesos

**Pregunta:** Para darle el permiso no abriste el rol. ¿Quién decide entonces lo que ve cada persona, y por qué ese archivo es tan delicado como los kilos?

**Respuesta:** Lo decide el administrador del sistema de seguridad o gestión de identidades a través del archivo de control (`seguridad.csv`), desacoplando el gobierno de accesos de la lógica del modelo BI. Es tan crítico como las tablas transaccionales porque cualquier error, omisión o manipulación en ese registro expone o restringe datos estratégicos de la organización de forma inmediata al refrescar el informe.