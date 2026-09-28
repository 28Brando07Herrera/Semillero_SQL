# Ejercicio 26 · Los kilos que llegaron en otro mes
## Byron Yaguar Rios

---

## PARTE A · El modelo

### A1 · Cargar los CSV

**A1a.** ¿De qué tipo quedó `fecha_entrega` en `h_cosecha`?

Respuesta:

---

### A2 · Las cinco relaciones

Relaciones dibujadas (todas continuas, muchos a uno):
1. `h_cosecha[finca_id]` → `dim_finca[finca_id]`
2. `h_cosecha[cultivo_id]` → `dim_cultivo[cultivo_id]`
3. `h_cosecha[fecha]` → `dim_tiempo[fecha]`
4. `h_meta[finca_id]` → `dim_finca[finca_id]`
5. `h_meta[fecha_mes]` → `dim_tiempo[fecha]`

---

### A3 · El calendario y las medidas

```dax
Kilos = SUM( h_cosecha[kg] )
```

```dax
Meta = SUM( h_meta[kg_meta] )
```

```dax
Cumplimiento = DIVIDE( [Kilos] , [Meta] )
```

---

### A4 · La tabla de control

> ### ✅ Punto de control
> | Finca | `[Kilos]` | `[Meta]` | `[Cumplimiento]` |
> |---|---|---|---|
> | Agricola La Union | | | |
> | Finca El Guayabo | | | |
> | Hacienda Santa Rosa | | | |
> | **Total** | **30 550** | **24 440** | **125,00 %** |

---

## PARTE B · La segunda relación

**B1.** Relación dibujada: `h_cosecha[fecha_entrega]` → `dim_tiempo[fecha]`.

**B2.** ¿Cómo se ve la línea nueva, comparada con la de `fecha`?

Respuesta:

**B3.** Relaciones entre `h_cosecha` y `dim_tiempo` (Administrar relaciones) y cuál está activa:

Respuesta:

**B4.** ¿Por qué Power BI no deja que las dos estén activas a la vez?

Respuesta:

> **Captura `clase26-modelo.png`**: las seis relaciones, cinco continuas y una punteada.

---

## PARTE C · La medida obvia

**C1.**

```dax
Kilos entregados = SUM( h_cosecha[kg] )
```

**C2.** Tabla con `nombre_mes`, `[Kilos]` y `[Kilos entregados]`:

> | `nombre_mes` | `[Kilos]` | `[Kilos entregados]` |
> |---|---|---|
> | Enero | | |
> | Febrero | | |
> | Marzo | | |
> | Abril | | |
> | **Total** | | |

**C3.** Cosecha 7 (maíz, 30 de abril): ¿en qué mes se entregó? ¿En qué mes la cuenta `[Kilos entregados]`?

Respuesta:

**C4.** ¿Qué error dio Power BI? ¿Por qué la medida no usa `fecha_entrega` si la relación ya está dibujada?

Respuesta:

---

## PARTE D · `USERELATIONSHIP`

**D1.**

```dax
Kilos entregados = CALCULATE( [Kilos] , USERELATIONSHIP( h_cosecha[fecha_entrega] , dim_tiempo[fecha] ) )
```

**D2.** Tabla por mes (mes 1 a 4):

> ### ✅ Punto de control
> | `nombre_mes` | `[Kilos]` | `[Kilos entregados]` |
> |---|---|---|
> | Enero | | 1 200 |
> | Febrero | | |
> | Marzo | 10 800 | 9 600 |
> | Abril | 19 750 | 10 250 |
> | **Total** | **30 550** | **21 050** |
>
> **Captura `clase26-entregas.png`.**

**D3.** ¿Qué cosecha es el 1 200 de enero? ¿En qué año se cortó? ¿En qué año cuenta para `[Kilos]` y en cuál para `[Kilos entregados]`?

Respuesta:

**D4.** Los 9 500 kilos de diferencia (entregados vs cosechados, ene-abr): explica con `cosecha_id` cuáles salen y cuál entra.

Respuesta:

**D5.** Sin segmentador de mes (año 2026 completo): total de las dos medidas y el mes nuevo que aparece.

Respuesta:

**D6.** `[Kilos entregados]` agregado a la tabla por finca. ¿Cambió `[Kilos]`? ¿Cambió `[Cumplimiento]`?

Respuesta:

---

## PARTE E · ¿Y si activo la otra?

**E1.** Relación activa cambiada: se desactivó `fecha`, se activó `fecha_entrega`.

**E2.** Tabla por finca, sin tocar medidas:

> ### ✅ Punto de control
> | Finca | `[Kilos]` | `[Meta]` | `[Cumplimiento]` |
> |---|---|---|---|
> | Agricola La Union | | | |
> | Finca El Guayabo | | | |
> | Hacienda Santa Rosa | | | |
> | **Total** | **21 050** | **24 440** | **86,13 %** |

**E3.** ¿Por qué El Guayabo baja de 150,95% a 47,14%? ¿Cuál cosecha dejó de contar en enero-abril?

Respuesta:

**E4.** ¿Por qué `[Meta]` no cambió?

Respuesta:

**E5.** Relación regresada: `fecha` activa de nuevo, tabla vuelve a 125,00%.

Respuesta:

**E6.** ¿Qué otras cosas del curso habrían cambiado solas con la activa en `fecha_entrega`?

Respuesta:

---

## PARTE F · Días a la entrega

**F1.**

```dax
Dias a la entrega = AVERAGEX( h_cosecha , DATEDIFF( h_cosecha[fecha] , h_cosecha[fecha_entrega] , DAY ) )
```

**F2.** Tabla por cultivo:

> ### ✅ Punto de control
> | Cultivo | `[Dias a la entrega]` |
> |---|---|
> | Mango | 2,00 |
> | Guayaba | 2,00 |
> | Maiz | 12,00 |
> | Cacao | 27,00 |
> | **Total** | **8,67** |

**F3.** ¿Por qué el total es 8,67 y no el promedio simple de los cuatro cultivos (10,75)?

Respuesta:

**F4.** `DATEDIFF` no usa relaciones. ¿Por qué el segmentador de mes sí cambia el resultado? ¿Por cuál fecha filtra?

Respuesta:

---

## PARTE G · Preguntas de cierre

**G1.** ¿Qué hace una relación inactiva mientras ninguna medida la pide?

Respuesta:

**G2.** ¿Cuándo conviene cambiar la relación activa y cuándo usar `USERELATIONSHIP`?

Respuesta:

**G3.** Regla de detección del día:

Respuesta:

**G4.** Banco con `fecha_solicitud` y `fecha_aprobacion`. Tablero dice "créditos aprobados en marzo". ¿Qué revisarías primero?

Respuesta:

**G5.** ¿Qué fecha usa la meta? ¿Tendría sentido una "meta de entregas" con la misma `h_meta`?

Respuesta:

---

## RESUMEN DE ENTREGAS

**Archivo:** `Ejercicio26_Yaguar_Byron.md` ✅

**Capturas:**
- `clase26-modelo.png` — vista de modelo, 6 relaciones (5 continuas, 1 punteada)
- `clase26-entregas.png` — tabla por mes con `[Kilos]` y `[Kilos entregados]`, total 21 050
