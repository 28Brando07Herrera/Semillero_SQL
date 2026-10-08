# Proyecto PC4 – El Análisis y la Seguridad

**Estudiante:** Brando Herrera

---

# Ancla del jueves

## Ver como

```text
regional.sur@agrodb.test
```

Resultado:

```text
Filas visibles en la tabla por finca: 2
Cumplimiento: 104,44 %
```

Fincas visibles:

- Agrícola La Unión
- Hacienda Los Ceibos

✅ Validado

---

# J1. El podio

## Top 3 cultivos por kilos

| Puesto | Cultivo | Kilos |
|----------|----------|---------:|
| 1 | Banano | 43.500 |
| 2 | Mango | 33.400 |
| 3 | Maíz | 25.200 |

Medida:

```DAX
Ranking cultivo =
RANKX(
    ALLSELECTED(dim_cultivo[cultivo]),
    [Kilos],
    ,
    DESC
)
```

Filtro aplicado al visual:

```text
Ranking cultivo <= 3
```

---

# J2. Bono y apoyo

## Regla

- Bono por kilos sobre la meta.
- Apoyo por kilos bajo la meta.
- Aplicación finca por finca.

## Resultados

### Bono total

```text
6.550 kg
```

### Apoyo total

```text
1.450 kg
```

---

## Comparación

### Si se aplica finca por finca

```text
Bono = 6.550
Apoyo = 1.450
```

### Si se aplica a la empresa completa

```text
Kilos = 91.300
Meta = 86.200
Diferencia = 5.100
```

Resultado:

```text
Bono = 5.100
Apoyo = 0
```

---

# J3. Escenario 110 %

## Parámetro

```text
100
110
120
130
140
150
```

---

## Meta ajustada

```text
94.820 kg
```

---

## Cumplimiento ajustado

```text
96,29 %
```

---

## Fincas que cumplen

| Finca | Cumple |
|---------|---------|
| Agrícola La Unión | No |
| Finca El Guayabo | No |
| Hacienda Los Ceibos | No |
| Hacienda Santa Rosa | No |

Resultado:

```text
Fincas que cumplen = 0
```

---

# J4. KPI del año

## Valor

```text
91.300 kg
```

## Objetivo

```text
86.200 kg
```

## Diferencia

```text
5.100 kg
```

## Diferencia porcentual

```text
5,92 %
```

Interpretación:

```text
La empresa se encuentra por encima de la meta acumulada
del período enero-septiembre 2026.
```

---

# J5. Seguridad

## regional.sur@agrodb.test

Visible:

```text
Agrícola La Unión
Hacienda Los Ceibos
```

Resultado:

```text
2 filas
104,44 %
```

---

## gerente.launion@agrodb.test

Visible:

```text
Agrícola La Unión
```

Resultado:

```text
Una única finca.
```

---

## practicante@agrodb.test

Resultado esperado:

```text
Sin acceso a información fuera de sus permisos.
```

---

# Medidas creadas

## Ranking cultivo

```DAX
Ranking cultivo =
RANKX(
    ALLSELECTED(dim_cultivo[cultivo]),
    [Kilos],
    ,
    DESC
)
```

---

## Bono

```DAX
Bono =
SUMX(
    VALUES(dim_finca[finca]),
    MAX([Kilos]-[Meta],0)
)
```

---

## Apoyo

```DAX
Apoyo =
SUMX(
    VALUES(dim_finca[finca]),
    MAX([Meta]-[Kilos],0)
)
```

---

## Meta ajustada

```DAX
Meta ajustada =
IF(
    HASONEVALUE(Escenario[Escenario]),
    [Meta] * DIVIDE([Valor de Escenario],100),
    BLANK()
)
```

---

## Cumplimiento ajustado

```DAX
Cumplimiento ajustado =
DIVIDE(
    [Kilos],
    [Meta ajustada]
)
```

---

# Bitácora del día

| Qué encontré | Cómo me di cuenta | Qué número daba mal | Cómo lo arreglé | Cómo sé que quedó |
|-------------|------------------|---------------------|-----------------|-------------------|
| El podio enseñaba todos los cultivos | Ranking correcto pero sin filtro | No mostraba Top 3 | Filtro Ranking <= 3 | Solo aparecen tres cultivos |
| El merge inicial generó duplicación de filas | h_cosecha llegó a 106 registros | Kilos y cosechas duplicados | Llave cultivo_id + calidad | h_cosecha volvió a 53 filas |
| El escenario podía seleccionar varios valores | Riesgo de cálculos ambiguos | Meta ajustada incorrecta | HASONEVALUE() | Devuelve BLANK cuando corresponde |
| El KPI mostraba objetivo en blanco | Comparación visual inconsistente | KPI incompleto | Validación mediante tarjetas | Meta visible correctamente |
| El RLS no filtraba inicialmente | regional.sur veía las cuatro fincas | Cumplimiento incorrecto | Configuración de propagación de seguridad | Se muestran 2 filas y 104,44 % |

---

# Evidencias

## proyecto-pc4-regional.png

Contiene:

```text
regional.sur@agrodb.test
```

Mostrando:

```text
2 fincas
104,44 %
```

---

## proyecto-pc4-gerente.png

Contiene:

```text
gerente.launion@agrodb.test
```

Visualizando únicamente su finca.

---

## proyecto-pc4-practicante.png

Contiene:

```text
practicante@agrodb.test
```

Mostrando únicamente la información permitida por el rol.

---

# Conclusiones

1. Se construyó el análisis ejecutivo solicitado por la dirección.
2. El modelo permite evaluar producción, meta, cumplimiento e ingresos.
3. El escenario permite simular incrementos de meta entre 100 % y 150 %.
4. El podio responde dinámicamente a los filtros activos.
5. La seguridad dinámica limita correctamente la información según el usuario.
6. El usuario regional.sur@agrodb.test visualiza únicamente dos fincas y obtiene un cumplimiento consolidado de 104,44 %.
