# Ejercicio práctico 17 · Ponle una meta a cada cultivo, y después quítasela

- **Alumno:** Cortez Cardozo Axel Josue
- **Entrega:** `entregas/cortez-axel/Ejercicio17_Cortez_Axel.md`, `entregas/cortez-axel/clase17-tablero.png`

---

## Parte A · La segunda tabla de hechos

### A1. Carga de `h_meta.csv`
- Archivo cargado desde `C:\agrodb\csv16\` (36 filas).
- Tipos de datos verificados:
  - `meta_id`: Número entero
  - `finca_id`: Número entero
  - `fecha_mes`: Fecha
  - `kg_meta`: Número entero

### A2. Relaciones del Modelo
- `h_meta[finca_id]` -> `dim_finca[finca_id]` (Muchos a uno, Simple)
- `h_meta[fecha_mes]` -> `dim_tiempo[fecha]` (Muchos a uno, Simple)

### A3. Relación faltante
Falta la relación hacia `dim_cultivo` porque la tabla `h_meta` no contiene la columna `cultivo_id`. La meta fue definida únicamente a nivel de finca y mes, por lo que no existe una clave foránea para relacionarla con los cultivos.

### A4. Punto de control 1 (Comprobación de integridad)

| Medida | Valor |
|---|---|
| `[Kilos]` sin filtros | **77 550** |
| `[Kilos]` con `anio` = 2026 | **30 550** |
| `[Cosechas]` | **25** |

---

## Parte B · La medida que cruza los dos hechos

### B1. Medidas base

```dax
Meta = SUM( h_meta[kg_meta] )
```

Resultado sin filtros: 47000

```dax
Cumplimiento = DIVIDE( [Kilos] , [Meta] )
```

Resultado sin filtros: 165,00 %

#### Punto de control 2

| Medida | Valor |
|---|---|
| `[Kilos]` | **77 550** |
| `[Meta]` | **47 000** |
| `[Cumplimiento]` | **165,00 %** |

### B2. ¿Por qué da 165 %?
Porque `[Kilos]` incluye el acumulado total de dos campañas (2025 y 2026 sumando 77 550 kg), mientras que `[Meta]` solo fue presupuestada para el año 2026 (47 000 kg).

### B3. Punto de control 3 (Los tres contextos)

| Filtros | `[Kilos]` | `[Meta]` | `[Cumplimiento]` |
|---|---|---|---|
| ninguno | 77 550 | 47 000 | **165,00 %** |
| `anio` = 2026 | 30 550 | 47 000 | **65,00 %** |
| `anio` = 2026 y `mes` en 1–4 | 30 550 | 24 440 | **125,00 %** |

### B4. Relación entre −35,00 % y 65,00 %
Matemáticamente expresan lo mismo respecto al total anual: haber alcanzado el 65,00 % del presupuesto equivale a situarse exactamente a un −35,00 % de la meta planificada para todo el año.

### B5. Comportamiento en 2025
No es un error; en 2025 no existen registros presupuestarios en `h_meta` (el denominador es nulo) y `DIVIDE` devuelve en blanco de forma segura.

---

## Parte C · Por finca, que sí funciona

### C1. Punto de control 4 (Tabla por finca)

| Finca | `[Kilos]` | `[Meta]` | `[Cumplimiento]` |
|---|---|---|---|
| Agricola La Union | 2 100 | 5 000 | **42,00 %** |
| Finca El Guayabo | 14 250 | 9 440 | **150,95 %** |
| Hacienda Santa Rosa | 14 200 | 10 000 | **142,00 %** |
| **Total** | **30 550** | **24 440** | **125,00 %** |

### C2. Suma de la columna Meta
Da 24 440 kg y coincide con la meta acumulada del período evaluado (meses 1 al 4 de 2026).

### C3. Lo que oculta el total de 125,00 %
Oculta que Agrícola La Unión tiene un grave rezago operativo (solo 42,00 % de cumplimiento), el cual queda enmascarado visualmente por el sobrecumplimiento de las otras dos fincas.

---

## Parte D · La trampa del día

### D1. Punto de control 5 (Tabla por cultivo)

| Cultivo | `[Kilos]` | `[Meta]` | `[Cumplimiento]` |
|---|---|---|---|
| Banano | *(vacío)* | **24 440** | *(vacío)* |
| Cacao | 2 100 | **24 440** | **8,59 %** |
| Cafe | *(vacío)* | **24 440** | *(vacío)* |
| Guayaba | 5 950 | **24 440** | **24,35 %** |
| Maiz | 9 800 | **24 440** | **40,10 %** |
| Mango | 12 700 | **24 440** | **51,96 %** |
| **Total** | **30 550** | **24 440** | **125,00 %** |

### D2. Mensaje de error de Power BI
Ninguno. Power BI no arrojó advertencias ni errores de sintaxis; ejecutó la operación y presentó el reporte como si fuera válido.

### D3. Presencia de Banano y Café
Aparecen porque en esta tabla la medida `[Meta]` devuelve un valor no vacío (24 440) para cada fila del catálogo, forzando a Power BI a desplegar filas de cultivos que no tienen cosechas.

### D4. Punto de control 6
51,96 % + 24,35 % + 40,10 % + 8,59 % = **125,00 %**. Los porcentajes individuales suman el total exactamente porque el numerador suma 30 550 y cada fila divide entre el mismo denominador constante (24 440).

### D5. Suma manual de la columna Meta
Da 146 640 kg (24 440 * 6), mientras que la empresa en realidad planificó cosechar 24 440 kg en ese periodo (y 47 000 kg para todo el año 2026).

### D6. Filas de meta y Punto de control 7

```dax
Filas de meta = COUNTROWS( h_meta )
```

Resultado en cada fila de cultivo: 12

| Cultivo | `[Cosechas]` | `[Filas de meta]` |
|---|---|---|
| Banano | *(vacío)* | **12** |
| Cacao | **2** | **12** |
| Cafe | *(vacío)* | **12** |
| Guayaba | **3** | **12** |
| Maiz | **1** | **12** |
| Mango | **3** | **12** |
| **Total** | **9** | **12** |

### D7. Diagnóstico de la relación cultivo-meta
Significa que `dim_cultivo` no tiene ninguna relación con `h_meta`; el contexto de filtro del cultivo no se propaga a la meta, por lo que cada fila evalúa siempre la totalidad de los registros de meta disponibles (las 12 metas correspondientes a los 4 meses y 3 fincas).

### D8. Error del filtro cruzado bidireccional
Estaría asumiendo falsamente que una meta fijada a una finca pertenece en exclusiva a los cultivos que casualmente se cosecharon allí en ese período, inventando una atribución artificial que no existe en el negocio.

---

## Parte E · El otro lado de la granularidad

### E1. Punto de control 8 (Tabla por día - Marzo 2026)

| Día | `[Kilos]` | `[Meta]` |
|---|---|---|
| 01/03/2026 | *(vacío)* | **6 900** |
| 20/03/2026 | **4 200** | *(vacío)* |
| 22/03/2026 | **5 400** | *(vacío)* |
| 28/03/2026 | **1 200** | *(vacío)* |
| **Total** | **10 800** | **6 900** |

- `[Cumplimiento]` por día:
  - 01/03/2026: *(vacío)*
  - 20/03/2026, 22/03/2026, 28/03/2026: *(vacío)*
  - Total: **156,52 %**

### E2. ¿Por qué la meta aparece el día 1?
Porque en el archivo CSV la columna `fecha_mes` fue registrada con el primer día de cada mes (ej. `2026-03-01`) para poder enlazar el hecho mensual con la clave diaria de `dim_tiempo`.

### E3. Nivel de lectura
Se puede leer a nivel mensual o superior (mes, trimestre, año); no se puede leer a nivel de día individual.

---

## Parte F · La medida que se calla

### F1. Medidas válidas

```dax
Meta valida = IF(
    ISFILTERED( dim_cultivo[cultivo] ) || ISFILTERED( dim_tiempo[fecha] ),
    BLANK(),
    [Meta]
)
```

Resultado en tabla por cultivo: BLANK() en las filas, 24440 en el total

```dax
Cumplimiento valido = DIVIDE( [Kilos] , [Meta valida] )
```

Resultado en tabla por cultivo: BLANK() en las filas, 125,00 % en el total

### F2. Punto de control 9 (Tabla por cultivo arreglada)

| Cultivo | `[Kilos]` | `[Meta valida]` | `[Cumplimiento valido]` |
|---|---|---|---|
| Cacao | 2 100 | *(vacío)* | *(vacío)* |
| Guayaba | 5 950 | *(vacío)* | *(vacío)* |
| Maiz | 9 800 | *(vacío)* | *(vacío)* |
| Mango | 12 700 | *(vacío)* | *(vacío)* |
| **Total** | **30 550** | **24 440** | **125,00 %** |

### F3. ¿Por qué el total sí contesta?
Porque en la fila del total no hay ningún valor individual de `dim_cultivo[cultivo]` ni de `dim_tiempo[fecha]` filtrando el contexto (`ISFILTERED` devuelve `FALSE`), permitiendo evaluar la medida `[Meta]` a nivel general.

### F4. Punto de control 10 (Tabla por finca intacta)

| Finca | `[Kilos]` | `[Meta valida]` | `[Cumplimiento valido]` |
|---|---|---|---|
| Agricola La Union | 2 100 | **5 000** | **42,00 %** |
| Finca El Guayabo | 14 250 | **9 440** | **150,95 %** |
| Hacienda Santa Rosa | 14 200 | **10 000** | **142,00 %** |
| **Total** | **30 550** | **24 440** | **125,00 %** |

### F5. Segmentador por cultivo
Sí, es totalmente correcto que se vacíe en el total porque al filtrar un cultivo individual la meta de la empresa no se puede descomponer para atribuirse a ese cultivo.

---

## Parte G · Preguntas de cierre

1. **Regla de lectura de medidas por granularidad:** Una medida solo puede leerse en dimensiones y granularidades que su tabla de hechos comparte o en agregaciones superiores, nunca en dimensiones no relacionadas ni en niveles más detallados que su captura.
2. **Diferencia entre el silencio natural y el programado:** En la fecha la medida se calló de forma natural porque existía una relación física y los días 20, 22 y 28 no tenían registros en `h_meta`; en el cultivo no se calló porque no existía relación física alguna, obligando a silenciarla explícitamente mediante código DAX.
3. **Medida análoga del curso:** `COUNTROWS(dim_cultivo)` de la clase 15, que devolvía la cantidad total del catálogo sin considerar el contexto.
4. **Impacto de una columna cultivo_id en h_meta:** Habría que crear la relación física de `h_meta[cultivo_id]` hacia `dim_cultivo[cultivo_id]` y retirar la condición `ISFILTERED( dim_cultivo[cultivo] )` de la medida `[Meta valida]` para permitir su cálculo por cultivo.
5. **Origen del aviso:** El aviso no lo puso el software ni el motor relacional; lo puso el analista mediante lógica defensiva en DAX al modelar las reglas de negocio.