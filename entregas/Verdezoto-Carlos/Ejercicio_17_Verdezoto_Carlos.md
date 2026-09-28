# Ejercicio 17 · AgroDB

## PARTE A - LA SEGUNDA TABLA DE HECHOS

**A3.** Falta la relación entre `h_meta` y `dim_cultivo`. No se puede crear porque `h_meta` no tiene la columna `cultivo_id`; el presupuesto se fijó por finca y no por cultivo.

**A4. Punto de control 1:**

| Medida | Valor |
|---|---|
| `[Kilos]` sin filtros | 77 550 |
| `[Kilos]` con `anio` = 2026 | 30 550 |
| `[Cosechas]` | 25 |

---

## PARTE B - LA MEDIDA QUE CRUZA LOS DOS HECHOS

### B1 · Meta y Cumplimiento

```dax
Meta         = SUM( h_meta[kg_meta] )
Cumplimiento = DIVIDE( [Kilos] , [Meta] )
```

**Punto de control 2:**
  
| Medida | Valor |
|---|---|
| `[Kilos]` | 77 550 |
| `[Meta]` | 47 000 |
| `[Cumplimiento]` | 165,00 % |

**B2.** Da 165,00 % porque el numerador (`[Kilos]`) está sumando la cosecha de toda la historia (2025 y 2026), mientras que el denominador (`[Meta]`) solo tiene datos para 2026.  

**B3. Punto de control 3:**
  
| Filtros | `[Kilos]` | `[Meta]` | `[Cumplimiento]` |
|---|---|---|---|
| ninguno | 77 550 | 47 000 | 165,00 % |
| anio = 2026 | 30 550 | 47 000 | 65,00 % |
| anio = 2026 y mes en 1–4 | 30 550 | 24 440 | 125,00 % |

**B4.** No es el mismo número. El -35,00 % de ayer comparaba la cosecha real contra la cosecha real del año pasado (`SAMEPERIODLASTYEAR`). El 65,00 % de hoy compara la cosecha real contra un presupuesto inventado (Meta).  

**B5.** No es un error. Como no se fijaron metas para 2025, el denominador es nulo (`BLANK`), y la función `DIVIDE` maneja esta división vaciando la celda automáticamente.  

---

## PARTE C - POR FINCA, QUE SÍ FUNCIONA

**C1. Punto de control 4:**
  
| Finca | `[Kilos]` | `[Meta]` | `[Cumplimiento]` |
|---|---|---|---|
| Agricola La Union | 2 100 | 5 000 | 42,00 % |
| Finca El Guayabo | 14 250 | 9 440 | 150,95 % |
| Hacienda Santa Rosa | 14 200 | 10 000 | 142,00 % |
| Total | 30 550 | 24 440 | 125,00 % |

**C2.** La suma manual da 24 440. Coincide exactamente con el valor mostrado en la fila de Total.  

**C3.** El total (125,00 %) esconde que el desempeño es sumamente dispar: Agrícola La Unión va muy por debajo de su meta (42 %), pero el sobrecumplimiento de las otras dos fincas arrastra el promedio hacia arriba.  

---

## PARTE D - LA TRAMPA DEL DÍA

**D1. Punto de control 5:**
  
| Cultivo | `[Kilos]` | `[Meta]` | `[Cumplimiento]` |
|---|---|---|---|
| Banano | (vacío) | 24 440 | (vacío) |
| Cacao | 2 100 | 24 440 | 8,59 % |
| Cafe | (vacío) | 24 440 | (vacío) |
| Guayaba | 5 950 | 24 440 | 24,35 % |
| Maiz | 9 800 | 24 440 | 40,10 % |
| Mango | 12 700 | 24 440 | 51,96 % |
| Total | 30 550 | 24 440 | 125,00 % |

**D2.** Ninguno. Power BI no muestra error; como no existe relación, simplemente repite el total del contexto actual en cada fila de la dimensión.  

**D3.** Porque la medida `[Meta]` devuelve 24 440 para absolutamente cualquier registro de la dimensión cultivo. Al no estar en blanco, la matriz se ve obligada a dibujar la fila, revelando cultivos sin cosecha.  

**D4. Punto de control 6:** La suma de los cuatro porcentajes es 125,00.  

**D5.** La suma lineal da 146 640 kilos (24 440 × 6). La empresa en realidad solo se propuso 24 440 kilos para ese periodo.  

**D6 · Filas de meta**

```dax
Filas de meta = COUNTROWS( h_meta )
```

**Punto de control 7:**
  
| Cultivo | `[Cosechas]` | `[Filas de meta]` |
|---|---|---|
| Banano | (vacío) | 12 |
| Cacao | 2 | 12 |
| Cafe | (vacío) | 12 |
| Guayaba | 3 | 12 |
| Maiz | 1 | 12 |
| Mango | 3 | 12 |
| Total | 9 | 12 |

**D7.** Que al no haber relación, el contexto de filtro de `dim_cultivo` no puede viajar hacia `h_meta`. La medida evalúa la tabla completa (filtrada solo por fecha) para cada cultivo sin hacer distinciones.  

**D8.** Estaría afirmando falsamente que la meta (presupuesto) es un atributo que depende de las cosechas que ocurrieron, cuando en la vida real la meta existe independientemente de si hay cosecha o no.  

---

## PARTE E - EL OTRO LADO DE LA GRANULARIDAD

**E1. Punto de control 8:**
  
| Día | `[Kilos]` | `[Meta]` |
|---|---|---|
| 01/03/2026 | (vacío) | 6 900 |
| 20/03/2026 | 4 200 | (vacío) |
| 22/03/2026 | 5 400 | (vacío) |
| 28/03/2026 | 1 200 | (vacío) |
| Total | 10 800 | 6 900 |

**E2.** Porque en el CSV `h_meta` todas las fechas de presupuesto fueron registradas estáticamente con el día 1 de cada mes.  

**E3.** Se puede leer al nivel de Mes o superior (Año, Trimestre). No sirve de nada leerlo al nivel de Día porque la granularidad del hecho es mensual.  

---

## PARTE F - LA MEDIDA QUE SE CALLA

**F1 · Meta valida y Cumplimiento valido**

```dax
Meta valida = IF(
    ISFILTERED( dim_cultivo[cultivo] ) || ISFILTERED( dim_tiempo[fecha] ),
    BLANK(),
    [Meta]
)

Cumplimiento valido = DIVIDE( [Kilos] , [Meta valida] )
```

**F2. Punto de control 9:**
  
| Cultivo | `[Kilos]` | `[Meta valida]` | `[Cumplimiento valido]` |
|---|---|---|---|
| Cacao | 2 100 | (vacío) | (vacío) |
| Guayaba | 5 950 | (vacío) | (vacío) |
| Maiz | 9 800 | (vacío) | (vacío) |
| Mango | 12 700 | (vacío) | (vacío) |
| Total | 30 550 | 24 440 | 125,00 % |

**F3.** Porque en la fila de Total no hay ningún cultivo específico filtrando visualmente la tabla; por ende, `ISFILTERED(dim_cultivo[cultivo])` es FALSO y el condicional permite mostrar la `[Meta]` global.  

**F4. Punto de control 10:**
  
| Finca | `[Kilos]` | `[Meta valida]` | `[Cumplimiento valido]` |
|---|---|---|---|
| Agricola La Union | 2 100 | 5 000 | 42,00 % |
| Finca El Guayabo | 14 250 | 9 440 | 150,95 % |
| Hacienda Santa Rosa | 14 200 | 10 000 | 142,00 % |
| Total | 30 550 | 24 440 | 125,00 % |

**F5.** Sí, está bien. Si el usuario fuerza un filtro explícito de un cultivo en toda la página, es correcto que la medida no intente adivinar la meta de un cultivo que no tiene meta asignada.  

---

## PARTE G - PREGUNTAS DE CIERRE

*   **¿A qué detalle se puede leer una medida?** 
    Una medida solo puede ser leída y analizada a una granularidad igual o superior (más resumida) a la que fue registrada en la tabla de hechos.  

*   **¿Cuál es la diferencia entre el día y el cultivo?** 
    Al bajar al día, el calendario filtró exitosamente una fecha vacía (se calló por la relación). Al partir por cultivo, al no haber relación, no se filtró nada y el total se repitió; hubo que callarlo con código.  

*   **¿Qué otra medida del curso habría dado la pista?** 
    La medida `[Cosechas]` (usando `COUNTROWS`).  

*   **¿Qué le pasa a Meta valida?** 
    Dejaría de ser necesaria la primera condición del `IF`. Habría que remover `ISFILTERED(dim_cultivo[cultivo])` para que la meta sí se muestre distribuida por los cultivos reales.

*   **¿Quién puso el aviso hoy?** 
    Nosotros mismos al escribir la medida `[Meta valida]`, utilizando DAX para detectar el contexto inválido y forzar a que el cálculo devuelva `BLANK` y desaparezca.
