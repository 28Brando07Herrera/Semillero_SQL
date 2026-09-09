# Ejercicio 16 · Comparar contra el año pasado

## Byron Yaguar · Power BI · DAX

\---

## PARTE A: Las medidas básicas

### A1. Medida de kilos totales

```dax
\[Kilos] = SUM(h\_cosecha\[kg])
```

**Resultado esperado: 77 550** (sin filtros, suma de 2025 + 2026, 25 cosechas)

Con filtro `anio = 2026`:
**Resultado: 30 550** (9 cosechas en 2026)

Con filtro `anio = 2025`:
**Resultado: 47 000** (16 cosechas en 2025)

\---

## PARTE B: Medidas con TOTALYTD (acumulado año a la fecha)

### B1. Kilos acumulados en el año

```dax
\[Kilos YTD] = TOTALYTD(SUM(h\_cosecha\[kg]), dim\_tiempo\[fecha])
```

**Resultado esperado en Abril 2026: 30 550** (acumulado enero a abril)

**Resultado en Abril 2025: 23 500** (acumulado enero a abril del año anterior)

\---

## PARTE C: Las medidas de comparación año contra año

### C1. Kilos del año anterior

```dax
\[Kilos AA] = CALCULATE(\[Kilos], SAMEPERIODLASTYEAR(dim\_tiempo\[fecha]))
```

Cuando filtras por `anio = 2026`:
**Resultado: 47 000** (los kilos de 2025)

En Marzo 2026:
**\[Kilos AA] = 8 200** (kilos de marzo 2025)

En Abril 2026:
**\[Kilos AA] = 9 500** (kilos de abril 2025)

\---

### C2. Kilos YTD del año anterior

```dax
\[Kilos YTD AA] = CALCULATE(\[Kilos YTD], SAMEPERIODLASTYEAR(dim\_tiempo\[fecha]))
```

En Abril 2026:
**\[Kilos YTD AA] = 23 500** (acumulado enero-abril de 2025)

\---

## PARTE D: El error silencioso - la variación año a año

### D1. Variación contra el año anterior (SIN filtro de meses)

```dax
\[Variacion AA] = DIVIDE(\[Kilos] - \[Kilos AA], \[Kilos AA])
```

**Con `anio = 2026` (SIN filtro de meses):
Resultado: −35,00 %** ← **EL ERROR DEL DÍA**

**¿Por qué está mal?**

* Estamos en septiembre de 2026
* El contexto sin filtro de meses compara **4 meses reales en 2026** (enero a abril con cosechas)
* Contra **12 meses de 2025** (año completo)
* 30 550 kg ÷ 47 000 kg = 0.65 = −35,00 % (parece que 2026 va 35% peor)
* **Pero es mentira.** No se pueden comparar 4 meses contra 12.

\---

### D2. Variación acumulada año a la fecha

```dax
\[Variacion YTD] = DIVIDE(\[Kilos YTD] - \[Kilos YTD AA], \[Kilos YTD AA])
```

En Abril 2026 (primeros 4 meses):
**Resultado: +30,00 %** (comparación correcta: 4 meses vs 4 meses)

Cálculo visible:

* (30 550 - 23 500) ÷ 23 500 = 7 050 ÷ 23 500 = +30,00 %

**Esto es lo CORRECTO.** Cuando filtras por mes 1–4, la variación dice: *«2026 crece 30% contra 2025 en el mismo período.»*

\---

### D3. La columna que baja sola (mes a mes en 2026)

La misma medida `\[Variacion YTD]`, sin tocar una fórmula:

|Mes|\[Variacion YTD]|
|-|-|
|Enero|−22,86 %|
|Febrero|−18,75 %|
|Marzo|−22,86 %|
|Abril|**+30,00 %**|
|Junio|−0,81 %|
|Septiembre|−25,58 %|
|Diciembre|−35,00 %|

**Cada mes que pasa, el acumulado se recalcula solo.** No escribiste nada. Solo el contexto cambió.

\---

## PARTE E: Las dos fechas de corte

### E1. Fecha máxima en la dimensión de tiempo

```dax
\[Fecha Maxima] = MAX(dim\_tiempo\[fecha])
```

**Resultado: 31/12/2026**

\---

### E2. Fecha de la última cosecha en los hechos

```dax
\[Fecha Ultima Cosecha] = MAX(h\_cosecha\[fecha])
```

**Resultado: 30/04/2026**

**¿Por qué son diferentes?**

* `dim\_tiempo` llega hasta fin de año (365 días por año, 730 filas totales)
* `h\_cosecha` solo tiene datos hasta abril (las cosechas se registraron hasta abril)
* Sin la dimensión de tiempo, los meses de mayo a diciembre no aparecerían en un eje (estarían en blanco)
* Con `dim\_tiempo` como tabla de fechas, Power BI "ve" todos los meses, aunque no haya cosechas

\---

## PARTE F: El giro de hoy

### F1. ¿Qué hace `SAMEPERIODLASTYEAR`?

```dax
\[Kilos AA] = CALCULATE(\[Kilos], SAMEPERIODLASTYEAR(dim\_tiempo\[fecha]))
```

No significa "el año pasado completo". Significa:

* **Mueve el contexto exactamente un año atrás, ni un día más ni uno menos.**

Si el contexto actual es "Marzo 2026":

* `SAMEPERIODLASTYEAR` devuelve "Marzo 2025"

Si el contexto es "Enero-Abril 2026":

* Devuelve "Enero-Abril 2025"

Si el contexto es "todo el año 2026 sin meses filtrados (realmente 4 meses con cosechas)":

* Devuelve "todo 2025" (porque SAMEPERIODLASTYEAR mueve el año, no los meses)
* Por eso da −35,00 %: compara períodos desiguales

\---

### F2. La fórmula está bien. El contexto estaba mal.

**Eso es lo de ayer llevado hasta el final:**

* En Clase 15: el arreglo fue **cambiar una función** (`COUNTROWS` → `DISTINCTCOUNT`)
* En Clase 16: **no cambias nada.** El mismo `\[Variacion AA]`, sin editar, da −35,00 % o +30,00 % dependiendo de qué meses filtres

**La medida nunca estuvo mal.** Estaba contestando bien una pregunta que nadie hizo.

\---

## Resumen de medidas para tu modelo

|Medida|Fórmula|Resultado clave|
|-|-|-|
|`\[Kilos]`|`= SUM(h\_cosecha\[kg])`|**30 550** (2026) / **47 000** (2025)|
|`\[Kilos YTD]`|`= TOTALYTD(SUM(h\_cosecha\[kg]), dim\_tiempo\[fecha])`|**30 550** en Abril 2026|
|`\[Kilos AA]`|`= CALCULATE(\[Kilos], SAMEPERIODLASTYEAR(dim\_tiempo\[fecha]))`|**47 000** (en contexto 2026)|
|`\[Kilos YTD AA]`|`= CALCULATE(\[Kilos YTD], SAMEPERIODLASTYEAR(dim\_tiempo\[fecha]))`|**23 500** en Abril 2026|
|`\[Variacion AA]`|`= DIVIDE(\[Kilos] - \[Kilos AA], \[Kilos AA])`|**−35,00 %** sin meses / **+30,00 %** con meses 1–4|
|`\[Variacion YTD]`|`= DIVIDE(\[Kilos YTD] - \[Kilos YTD AA], \[Kilos YTD AA])`|**+30,00 %** en Abril 2026|
|`\[Fecha Maxima]`|`= MAX(dim\_tiempo\[fecha])`|**31/12/2026**|
|`\[Fecha Ultima Cosecha]`|`= MAX(h\_cosecha\[fecha])`|**30/04/2026**|

\---

## Lo que entregás

1. **`Ejercicio16\_Byron\_Yaguar.md`** — este archivo, con cada medida y sus resultados anotados.
2. **`clase16-tablero.png`** — captura del tablero con **las dos tarjetas de variación**:

   * Una tarjeta mostrando **−35,00 %** (el error)
   * Una tarjeta mostrando **+30,00 %** (la corrección)

> El `.pbix` no se entrega: el repositorio lo ignora porque pesa y no se puede revisar en un PR.

\---

## Número de control final

Al terminar, tu tablero debe mostrar:

* **\[Kilos] 2026**: 30 550 ✓
* **\[Kilos] 2025**: 47 000 ✓
* **\[Variacion AA] sin meses**: −35,00 % ✓
* **\[Variacion AA] con meses 1–4**: +30,00 % ✓
* **\[Fecha Maxima]**: 31/12/2026 ✓
* **\[Fecha Ultima Cosecha]**: 30/04/2026 ✓

\---

## 

