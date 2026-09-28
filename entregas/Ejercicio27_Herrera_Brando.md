# Ejercicio27_Herrera_Brando.md

# Parte A · El modelo

## A0a

Configuración regional anterior:

```text
Español (Ecuador)
```

Configuración utilizada para la práctica:

```text
Español (México)
```

---

## Medidas

```DAX
Kilos =
SUM( h_cosecha[kg] )
```

Resultado:

```text
30550
```

---

```DAX
Meta =
SUM( h_meta[kg_meta] )
```

Resultado:

```text
24440
```

---

```DAX
Cumplimiento =
DIVIDE(
    [Kilos],
    [Meta]
)
```

Resultado:

```text
125,00 %
```

---

```DAX
Cosechas =
COUNTROWS(
    h_cosecha
)
```

Resultado:

```text
9
```

---

## Tabla de control

| Finca | Kilos | Meta | Cumplimiento | Cosechas |
|---------|---------:|---------:|---------:|---------:|
| Agrícola La Unión | 2100 | 5000 | 42,00 % | 2 |
| Finca El Guayabo | 14250 | 9440 | 150,95 % | 3 |
| Hacienda Santa Rosa | 14200 | 10000 | 142,00 % | 4 |
| Total | 30550 | 24440 | 125,00 % | 9 |

---

# Parte B · El archivo de la báscula

## B2

Pasos aplicados generados automáticamente:

```text
Origen
Encabezados promovidos
Tipo cambiado
```

---

## B3

La columna:

```text
fecha
```

fue convertida a tipo:

```text
Fecha
```

---

## B4

Calidad de columna:

```text
Válido: 70 %
Error: 30 %
Vacío: 0 %
```

---

## B5

Mensaje observado:

```text
No se pudo convertir el valor al tipo Fecha.
```

---

## B6

Las filas con error corresponden a:

```text
cosecha_id 27
cosecha_id 28
cosecha_id 35
```

Sus fechas contienen valores de día mayores a 12 y fueron interpretadas con una configuración regional incorrecta.

---

# Parte C · El arreglo obvio

## C1

Después de:

```text
Quitar errores
```

la calidad quedó en:

```text
100 % válido
0 % error
0 % vacío
```

pero solamente con siete filas.

---

## C5

Tabla por mes con mes de 5 a 8:

| Mes | Kilos | Cosechas |
|------|------:|------:|
| Mayo | 2500 | 1 |
| Junio | 4100 | 2 |
| Julio | 3400 | 1 |
| Total | 10000 | 4 |

Mes faltante:

```text
Agosto
```

---

## C6

Tabla por finca:

| Finca | Cumplimiento |
|---------|---------:|
| Finca El Guayabo | 17,75 % |
| Total | 64,68 % |

---

## C7

Al regresar el filtro a enero-abril:

```text
Kilos = 30950
Meta = 24440
Cumplimiento = 126,64 %
Cosechas = 10
```

La finca que cambió fue:

```text
Finca El Guayabo
```

---

## C8

La cosecha que apareció dentro de enero-abril fue:

```text
cosecha_id 31
```

La fecha del archivo fue interpretada incorrectamente por Power Query y terminó contabilizada en un período distinto al real.

---

# Parte D · La regla en el paso

## D1

| cosecha_id | Texto en el CSV | Fecha real |
|------------|----------------|------------|
| 26 | 05/07/2026 | 7 de mayo de 2026 |
| 27 | 05/14/2026 | 14 de mayo de 2026 |
| 28 | 05/20/2026 | 20 de mayo de 2026 |
| 29 | 06/06/2026 | 6 de junio de 2026 |
| 30 | 06/09/2026 | 9 de junio de 2026 |
| 31 | 07/02/2026 | 2 de julio de 2026 |
| 32 | 07/10/2026 | 10 de julio de 2026 |
| 33 | 08/05/2026 | 5 de agosto de 2026 |
| 34 | 08/06/2026 | 6 de agosto de 2026 |
| 35 | 08/24/2026 | 24 de agosto de 2026 |

Observación:

```text
Siete fechas fueron interpretadas sin error pero con la regla incorrecta.
Tres generaron error.
```

---

## D2

Se eliminaron los pasos:

```text
Errores quitados
Tipo cambiado
```

---

## D3

Se aplicó:

```text
Cambiar tipo
→ Usar configuración regional
→ Fecha
→ English (United States)
```

Resultado:

```text
100 % válido
0 % error
10 filas
```

---

## D5

Tabla correcta por mes:

| Mes | Kilos | Cosechas |
|------|------:|------:|
| Mayo | 5800 | 3 |
| Junio | 4400 | 2 |
| Julio | 1700 | 2 |
| Agosto | 4800 | 3 |
| Total | 16700 | 10 |

---

## D6

Tabla por finca:

| Finca | Cumplimiento |
|---------|---------:|
| Agrícola La Unión | 66,67 % |
| Finca El Guayabo | 85,80 % |
| Hacienda Santa Rosa | 137,50 % |
| Total | 108,02 % |

Meta total:

```text
15460
```

---

## D7

Al regresar el filtro a enero-abril volvió a:

```text
Kilos = 30550
Meta = 24440
Cumplimiento = 125,00 %
Cosechas = 9
```

---

## D8

El Guayabo pasó de:

```text
17,75 %
```

a

```text
85,80 %
```

porque varias pesadas de la báscula fueron eliminadas por el paso:

```text
Quitar errores
```

y otras quedaron asignadas a meses incorrectos por la interpretación equivocada de las fechas.

Al aplicar la configuración regional correcta se recuperaron las diez pesadas y cada cosecha volvió a su mes real.

---

# Parte E · La prueba de las cuatro cifras

## Medidas

```DAX
Pesadas bascula =
CALCULATE(
    [Cosechas],
    h_cosecha[cosecha_id] >= 26
)
```

Resultado:

```text
10
```

---

```DAX
Kilos bascula =
CALCULATE(
    [Kilos],
    h_cosecha[cosecha_id] >= 26
)
```

Resultado:

```text
16700
```

---

```DAX
Primera pesada =
CALCULATE(
    MIN( h_cosecha[fecha] ),
    h_cosecha[cosecha_id] >= 26
)
```

Resultado:

```text
07/05/2026
```

---

```DAX
Ultima pesada =
CALCULATE(
    MAX( h_cosecha[fecha] ),
    h_cosecha[cosecha_id] >= 26
)
```

Resultado:

```text
24/08/2026
```

---

## E3

Con la solución incorrecta de la parte C las tarjetas habrían mostrado:

```text
7 pesadas
13200 kg
7 de febrero de 2026
7 de octubre de 2026
```

porque tres filas fueron eliminadas y varias fechas válidas fueron interpretadas con una regla equivocada.

---

## E4

No conviene depender únicamente de la configuración regional global del archivo.

La regla correcta debe quedar explícita en el paso:

```text
Usar configuración regional
```

para garantizar que futuras cargas sigan interpretando correctamente el formato de fecha.

---

## E5

La validación del total histórico:

```text
30550
```

detectó que una cosecha fue movida a un período incorrecto.

La cosecha 31 cambió de período al interpretarse incorrectamente la fecha.

---

# Parte F · Preguntas de cierre

## F1

```text
Quitar errores elimina filas con error, pero no corrige los datos ni la causa del problema.
```

---

## F2

```text
La regla vive en el paso de transformación y no en el archivo CSV.
```

---

## F3

```text
Si una fecha válida produce números imposibles, el problema puede estar en la interpretación de la fecha y no en la calidad de columna.
```

---

## F4

```text
Revisaría muestras reales de las fechas porque 100 % válido solo indica que las fechas pudieron convertirse, no que fueron interpretadas correctamente.
```

---

## F5

```text
Ambos casos eliminan registros problemáticos sin corregir la causa que generó el problema original.
```