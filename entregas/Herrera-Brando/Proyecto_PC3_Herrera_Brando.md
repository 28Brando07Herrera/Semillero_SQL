# Proyecto PC3 – Metas e Indicadores

**Estudiante:** Brando Herrera

---

# Anclas del miércoles

## Ancla 1

```text
h_meta = 48 filas
```

Resultado obtenido a partir de:

```text
4 fincas × 12 meses = 48 registros
```

✅ Validado

---

## Ancla 2

```text
Meta = 110.000 kg
```

Resultado validado para el año 2026.

✅ Validado

---

## Ancla 3

Filtro aplicado:

```text
Año = 2026
Mes = 1 a 9
```

Resultado:

```text
Cumplimiento = 105,92 %
```

✅ Validado

---

# Construcción de h_meta

Fuente utilizada:

```text
metas_planeacion.csv
```

Transformaciones realizadas:

1. Promoción de encabezados.
2. Eliminación de la fila Total.
3. Eliminación de columnas auxiliares.
4. Anulación de dinamización de columnas de meses.
5. Renombrado de columnas.
6. Conversión de tipos de datos.

Resultado final:

```text
finca_id
fecha_mes
kg_meta
```

Cantidad final:

```text
48 filas
```

---

# Relaciones creadas

## Metas

```text
dim_finca[finca_id]
(1)
→
h_meta[finca_id]
(*)
```

```text
dim_tiempo[fecha]
(*)
→
h_meta[fecha_mes]
(*)
```

---*
## Hechos

```text*dim_finca[finca_id]
→
h_c*secha[finca*id]
```

```text
dim_cultivo[culti*o_id]
→
h_cosecha[cultivo_id]
```
*```text
dim_tiempo[fecha]
→
h_c*secha[fecha]
```

*--

## Relación in*ctiva

```text
dim_tiempo[fecha]
↔*h_cosecha[fecha_entrega]
```

*stado:

```text
Inactiva
```

*e*utiliza mediante:

*``DAX
USERELATIONSHIP()
```

*--

# Medidas creadas

## Meta

``*DAX
Meta =
SUM(h*meta[kg_meta])
```

*--

## Cumplimiento

```DAX
Cumpli*iento =
DIVIDE*[Kilos],[Meta])
```

---

## Kilos*entregados

```D*X
Kilos entregados =
CALCULATE(
  * [Kilos],
    USERELATIONSHIP(
   *    h_cosecha[fecha_entrega],
    *   dim_tiempo[fecha]
    )
)
```

*esultado:

```text
137.000 kg
```
**--

## Kilos año anterior

```D*X
Kilos año anterior =
CALCULATE(
*   [Kilos],
    SAME*ERIODLAST*EAR(
        dim_tiempo[fecha]
   *)
)
```

---

## Variación

```DAX*Variacion =
[Kilos] -
[Kilos año a*terior]
```

---

## Vari*ción %

```DAX
Variacion % =
DIVID*(
    [Variacion],
    [Kilos año *nterior]
)
```

---

## Promedio p*r cultivo

```D*X
Prom*dio por cultivo =
DIVIDE(
    [Kil*s],
    DISTINCTCOUNT(
        h_c*secha[cultivo_id]
    )
)
```

---*
# Indicadores obtenidos

## Vista*general

```text*Kilos              = 136.600
Meta *             = 110.000
Cumplimient*       = 124,18 %
Ingresos*          = 80,27*mil
Kilos entregados   = 137.000
`*`

---

# Análisis por cultivo

|*Cultivo | Kilos |
|----------*-------:|
| Banano | 43.500 |
| Ma*go |*33.400 |
| Ma*z | 25.200 |
* Guayaba | 23.950 |
| C*cao | 10.550 |
| Total | 136.600 |*
---

# Bitácora del día

| Qué*encontré | Impact* | Solución |
|-------------|-----*----|-----------|
| h*meta estaba en formato ancho | No *ra posible relacionar metas con ca*endario | Se realizó anulación de *inamización |
| fecha_mes*fue importada inicialmente como te*to | Los filtros de calendario no *uncionaban | Conversión a tipo Fec*a |
| Fechas provenientes de*bascula_digital_2026 generaban err*res |*Los datos de 2026 no aparecían cor*ectamente | Configuración regional*adecuada para fechas |
| Exist*an rutas ambiguas entre tablas | E*ror al activar relaciones bidirecc*onales | Se*mantuvieron relaciones de direcció* única |
| La*combinación inicial con precios du*licaba filas | h_cosecha llegaba a*106 registros | Merge correcto usa*do cultivo_id + calidad |

---

# *videncias

## Captura 1

```text
p*oyecto-pc3-metas.png
```

Incluye:*
```text
Meta
Kilos
Cumplimiento
I*gresos
Cosechas
Matriz mensual
*``

*--

## Captura 2

```text
proyecto*pc3-indicadores.png
``*

Incluye:

```text
Kilos
Meta
Cum*l*miento
Ingresos
Kilos entregados
P*omedio por cultivo
```

---

# Con*lusiones

1. La tabla h_meta fue t*ansformada correctamente obteniend* 48 registros válidos.
2. La meta*anual del 2026 corresponde a 110.0*0 kg.
3.*El cumplimiento para el período en*ro-septiembre 2026 alcanzó 105,92 *.
4.*El modelo permite analizar producc*ón, metas e ingresos mediante dime*siones de tiempo, finca y cultivo.*5**Se implementó análisis de entregas*mediante una relación inactiva utilizando USERELATIONSHIP().