# Ejercicio24_Herrera_Brando.md

# Checklist

| # | Lo que salió en mi pantalla | Qué trampa descarta |
|---|---|---|
| 1 | 6 tablas, 6 relaciones, todas * a 1 | La relación faltante entre h_meta y dim_tiempo |
| 2 | 5 000 / 9 440 / 10 000, total 30 550 / 24 440 / 125,00 % | Meta sin filtro por fecha o finca |
| 3 | La Unión rojo, El Guayabo verde, Santa Rosa verde, total verde | La regla con Porcentaje que pinta mal Santa Rosa |
| 4 | Mango 12 700 el más oscuro, Cacao 2 100 en blanco | No entender que el degradado compara contra mínimo y máximo visibles |
| 5 | KPI del año 30 550 contra 24 440, +25,00 %, con título | KPI mostrando abril (19 750) o marzo (10 800) |
| 6 | gerente.launion@agrodb.test ve 2 100 / 5 000 / 42,00 %, KPI -58,00 % | Rol aplicado en tabla incorrecta |
| 7 | regional.norte@agrodb.test ve 16 350 / 14 440 / 113,23 %, KPI +13,23 % | Uso incorrecto de LOOKUPVALUE para múltiples fincas |
| 8 | practicante@agrodb.test no ve filas ni KPI | Acceso abierto por error |
| 9 | practicante@agrodb.test ve Santa Rosa 14 200 / 10 000 / 142,00 %, KPI +42,00 % | Tener que modificar el rol para otorgar permisos |
| 10 | Medidas, rol y respuestas documentadas | Llegar al resultado sin entender el motivo |

---

# Medidas

```DAX
Kilos =
SUM( h_cosecha[kg] )
```

```DAX
Meta =
SUM( h_meta[kg_meta] )
```

```DAX
Cumplimiento =
DIVIDE(
    [Kilos],
    [Meta]
)
```

```DAX
Kilos YTD =
TOTALYTD(
    [Kilos],
    dim_tiempo[fecha]
)
```

```DAX
Meta YTD =
TOTALYTD(
    [Meta],
    dim_tiempo[fecha]
)
```

```DAX
Color cumplimiento =
IF(
    [Cumplimiento] >= 1,
    "#1E8449",
    "#C0392B"
)
```

```DAX
Quien mira =
USERPRINCIPALNAME()
```

---

# Rol

Tabla:

```text
dim_finca
```

Condición:

```DAX
[finca_id] IN
CALCULATETABLE(
    VALUES(seguridad[finca_id]),
    seguridad[correo] = USERPRINCIPALNAME()
)
```

---

# A3a

La relación entre
`h_meta[fecha_mes]`
y
`dim_tiempo[fecha]`

probablemente no habría sido creada automáticamente porque los nombres de las columnas son distintos. Eso habría provocado que las metas no se filtraran por fecha.

---

# A3b

No existe relación entre `dim_cultivo` y `h_meta` porque las metas se definen por finca y fecha, no por cultivo.

---

# Punto 1

Modelo con:

```text
6 tablas
6 relaciones
Cardinalidad * a 1
Dirección única
```

Trampa descartada:

```text
Relación faltante entre h_meta y dim_tiempo.
```

---

# Punto 2

Tabla por finca:

| Finca | Kilos | Meta | Cumplimiento |
|---|---:|---:|---:|
| Agricola La Union | 2100 | 5000 | 42,00 % |
| Finca El Guayabo | 14250 | 9440 | 150,95 % |
| Hacienda Santa Rosa | 14200 | 10000 | 142,00 % |
| Total | 30550 | 24440 | 125,00 % |

Trampa descartada:

```text
Meta sin relación de finca o fecha.
```

---

# Punto 3

Semáforo:

```text
Agricola La Union     Rojo
Finca El Guayabo      Verde
Hacienda Santa Rosa   Verde
Total                 Verde
```

Trampa descartada:

```text
Formato condicional con Porcentaje.
```

---

# Punto 4

Degradado:

```text
Mango   12700   Más oscuro
Maiz     9800
Guayaba  5950
Cacao    2100   Blanco
```

Trampa descartada:

```text
No entender que el color depende del rango visible.
```

---

# Punto 5

Tarjetas:

```text
Kilos = 30 550
Cumplimiento = 125,00 %
```

KPI del año:

```text
30 550
contra
24 440

+25,00 %
```

Título:

```text
Acumulado del año contra meta
```

Trampa descartada:

```text
Mostrar el dato del último mes en vez del acumulado.
```

---

# Punto 6

Ver como:

```text
gerente.launion@agrodb.test
```

Resultado:

```text
Una sola finca
Agricola La Union
2100 / 5000 / 42,00 %
```

KPI:

```text
2100 contra 5000

-58,00 %
```

Trampa descartada:

```text
Rol ubicado en tabla incorrecta.
```

---

# Punto 7

Ver como:

```text
regional.norte@agrodb.test
```

Resultado:

```text
Agricola La Union
Finca El Guayabo
```

Total:

```text
16350
14440
113,23 %
```

KPI:

```text
+13,23 %
```

Trampa descartada:

```text
LOOKUPVALUE fallando cuando existen varias fincas.
```

---

# Punto 8

Ver como:

```text
practicante@agrodb.test
```

Resultado:

```text
Sin filas
Sin KPI
Sin tarjetas
```

Trampa descartada:

```text
Permisos abiertos para usuarios no autorizados.
```

---

# Punto 9

Después de agregar:

```text
practicante@agrodb.test,1
```

a:

```text
seguridad.csv
```

Resultado:

```text
Hacienda Santa Rosa

14200
10000
142,00 %
```

KPI:

```text
14200
contra
10000

+42,00 %
```

Trampa descartada:

```text
Modificar el rol para otorgar permisos.
```

---

# D5

Si el rol estuviera aplicado sobre la tabla `seguridad`, el practicante podría terminar viendo información que no le corresponde.

Eso es peor que un error porque implica una falla de seguridad y exposición de datos.

---

# E1

Los permisos los decide el contenido de `seguridad.csv`, no el rol.

Ese archivo es tan delicado como los datos de producción porque controla exactamente quién puede ver cada finca.

---

# Conclusiones

El tablero quedó validado con:

```text
KPI del año:
30 550 contra 24 440
+25,00 %
```

y

```text
regional.norte@agrodb.test
113,23 %
```

lo que confirma que el modelo, las medidas, el semáforo, el KPI acumulado y la seguridad dinámica funcionan correctamente.