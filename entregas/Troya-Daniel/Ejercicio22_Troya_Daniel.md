# Ejercicio Práctico 22 · Un simulador de metas que no invente el nivel

**Estudiante:** Troya Riofrio, Daniel Moises  
**Fecha:** 17 de septiembre de 2026  
**Entorno:** Power BI Desktop  

---

## Parte A · Una tabla que no viene de ningún archivo

### A1 & A2 · Tabla por finca

| Finca | [Kilos] | [Meta] | [Cumplimiento] |
| :--- | :--- | :--- | :--- |
| Agricola La Union | 2 100 | 5 000 | 42,00 % |
| Finca El Guayabo | 14 250 | 9 440 | 150,95 % |
| Hacienda Santa Rosa | 14 200 | 10 000 | 142,00 % |
| **Total** | **30 550** | **24 440** | **125,00 %** |

### A3 · Tabla escenario
```dax
escenario = DATATABLE( "nivel" , INTEGER , { { 100 } , { 110 } , { 120 } , { 130 } , { 140 } , { 150 } } )
```
* En la **vista de tabla**, `escenario` tiene 6 filas (100, 110, 120, 130, 140, 150).
* En la **vista de modelo**, `escenario` no tiene ninguna relación con las demás tablas del modelo.

### A5 · Comportamiento de la tabla con el segmentador escenario
La tabla por finca no sufrió ningún cambio al marcar 130 o 150 porque `escenario` es una tabla desconectada; al no existir una **relación** física en el modelo de datos, el contexto de filtro del segmentador no se propaga hacia `dim_finca` ni hacia `h_meta`.

---

## Parte B · La medida pregunta

### B1 · Medidas de simulación

```dax
Nivel elegido = SELECTEDVALUE( escenario[nivel] , 100 )
```

```dax
Meta ajustada = [Meta] * [Nivel elegido] / 100
```

```dax
Cumplimiento ajustado = DIVIDE( [Kilos] , [Meta ajustada] )
```

Con 130 marcado:
* La Union: Meta 6 500 · Cumplimiento 32,31 %
* El Guayabo: Meta 12 272 · Cumplimiento 116,12 %
* Santa Rosa: Meta 13 000 · Cumplimiento 109,23 %
* **Total: Meta 31 772 · Cumplimiento 96,15 %**

| Finca | [Kilos] | [Meta ajustada] | [Cumplimiento ajustado] |
| :--- | :--- | :--- | :--- |
| Agricola La Union | 2 100 | 6 500 | 32,31 % |
| Finca El Guayabo | 14 250 | 12 272 | 116,12 % |
| Hacienda Santa Rosa | 14 200 | 13 000 | 109,23 % |
| **Total** | **30 550** | **31 772** | **96,15 %** |

### B2 · Los seis niveles

| Nivel | [Meta ajustada] | [Cumplimiento ajustado] |
| :--- | :--- | :--- |
| 100 | 24 440 | 125,00 % |
| 110 | 26 884 | 113,64 % |
| 120 | 29 328 | 104,17 % |
| 130 | 31 772 | 96,15 % |
| 140 | 34 216 | 89,29 % |
| 150 | 36 660 | 83,33 % |

### B3 · Cumplimiento global e individual
La empresa cumple globalmente hasta el nivel **120** (104,17 %); Agrícola La Unión no cumple en **ningún** nivel (su máximo cumplimiento es 42,00 % al nivel 100).

---

## Parte C · Dos niveles a la vez

### C1 · Marcando 130 y 150 simultáneamente

| Finca | [Kilos] | [Meta ajustada] | [Cumplimiento ajustado] |
| :--- | :--- | :--- | :--- |
| Agricola La Union | 2 100 | 5 000 | 42,00 % |
| Finca El Guayabo | 14 250 | 9 440 | 150,95 % |
| Hacienda Santa Rosa | 14 200 | 10 000 | 142,00 % |
| **Total** | **30 550** | **24 440** | **125,00 %** |

### C2 · Mensaje de error o advertencia de Power BI
Ninguno. Power BI evaluó la expresión silenciosamente sin alertar ningún conflicto.

### C3 · Nivel del 125,00 %
Corresponde exactamente al nivel **100**; dicho nivel no está marcado en el segmentador (los seleccionados son 130 y 150).

### C4 · Tarjeta de control de [Nivel elegido]

| Qué hay marcado en el segmentador | [Nivel elegido] | Total de [Cumplimiento ajustado] |
| :--- | :--- | :--- |
| solo 130 | 130 | 96,15 % |
| 130 y 150 | 100 | 125,00 % |
| nada (borra la selección) | 100 | 125,00 % |

### C5 · Origen del 100 con múltiples valores
El 100 proviene del segundo argumento (valor alternativo) configurado en `SELECTEDVALUE( escenario[nivel] , 100 )`; cuando en el contexto de filtro hay más de un valor, `SELECTEDVALUE` descarta los valores reales y devuelve automáticamente el alternativo.

### C6 · Por qué fallaron las pruebas iniciales
Las pruebas de la Parte B solo probaron un valor a la vez (donde `SELECTEDVALUE` siempre tiene un valor único); el 125,00 % no se ve raro porque coincide con el cumplimiento base original de la empresa, pasando desapercibido como un valor válido.

### C7 · Conclusión errónea de gerencia
Al nivel 150 debió leer **83,33 %**; una **tarjeta** con la medida `[Nivel elegido]` le habría revelado de inmediato que el sistema estaba calculando con nivel 100 en lugar del 150 esperado.

---

## Parte D · Los seis a la vez

### D1 · Matriz por finca y nivel con [Meta ajustada]

| Finca | 100 | 110 | 120 | 130 | 140 | 150 | Total |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Agricola La Union | 5 000 | 5 500 | 6 000 | 6 500 | 7 000 | 7 500 | **5 000** |
| Finca El Guayabo | 9 440 | 10 384 | 11 328 | 12 272 | 13 216 | 14 160 | **9 440** |
| Hacienda Santa Rosa | 10 000 | 11 000 | 12 000 | 13 000 | 14 000 | 15 000 | **10 000** |
| **Total** | **24 440** | **26 884** | **29 328** | **31 772** | **34 216** | **36 660** | **24 440** |

### D2 · Suma a mano de La Unión vs. Columna Total
* Suma a mano: $5\,000 + 5\,500 + 6\,000 + 6\,500 + 7\,000 + 7\,500 = \mathbf{37\,500}$.
* La columna Total reporta **5 000**.

### D3 · Comportamiento de las columnas frente a la columna Total
En las columnas individuales el **contexto** de filtro contiene un solo nivel (100, 110, etc.), permitiendo a `SELECTEDVALUE` escalar la meta; en la columna Total el contexto abarca los seis niveles simultáneamente, forzando a `SELECTEDVALUE` a devolver el alternativo 100.

### D4 · ¿La columna Total copió la del 100?
No la copió; evaluó la fórmula desde cero bajo un contexto multievaluado donde `SELECTEDVALUE` retornó 100, coincidiendo matemáticamente con la primera columna.

---

## Parte E · Que diga que no sabe

### E1 · Medidas seguras con HASONEVALUE

```dax
Meta del escenario =
IF(
    HASONEVALUE( escenario[nivel] ) ,
    [Meta] * SELECTEDVALUE( escenario[nivel] ) / 100
)
```

```dax
Cumplimiento del escenario = DIVIDE( [Kilos] , [Meta del escenario] )
```

Punto de control 8 en La Unión:
* Columna 130: 6 500
* Columna Total: *(vacío)*
* Renglón Total: 24 440 · 26 884 · 29 328 · 31 772 · 34 216 · 36 660 · *(vacío)*

### E2 · Tabla por finca con selección múltiple

| Qué hay marcado | Total de [Meta del escenario] | Total de [Cumplimiento del escenario] |
| :--- | :--- | :--- |
| solo 130 | 31 772 | 96,15 % |
| 130 y 150 | *(vacío)* | *(vacío)* |
| nada | *(vacío)* | *(vacío)* |

### E3 · Prueba de selección única
Al habilitar Selección única (*Formato > Configuración del segmentador > Selección > Selección única*), el segmentador pasa a usar botones de opción tipo radio button que impiden seleccionar dos niveles y no permiten desmarcar la opción activa.

### E4 · Insuficiencia de la selección única
La selección única en el segmentador solo protege la vista de página, pero no afecta a los objetos tipo Matriz, donde la columna Total sigue evaluando múltiples niveles a la vez; `HASONEVALUE` protege la medida en cualquier contexto visual.

---

## Parte F · ¿Hasta dónde se puede subir?

### F1 · Medida de fincas que cumplen y tabla por nivel

```dax
Fincas que cumplen = COUNTROWS( FILTER( dim_finca , [Cumplimiento del escenario] >= 1 ) )
```

| nivel | [Kilos] | [Meta del escenario] | [Cumplimiento del escenario] | [Fincas que cumplen] |
| :--- | :--- | :--- | :--- | :--- |
| 100 | 30 550 | 24 440 | 125,00 % | 2 |
| 110 | 30 550 | 26 884 | 113,64 % | 2 |
| 120 | 30 550 | 29 328 | 104,17 % | 2 |
| 130 | 30 550 | 31 772 | 96,15 % | 2 |
| 140 | 30 550 | 34 216 | 89,29 % | 2 |
| 150 | 30 550 | 36 660 | 83,33 % | 1 |
| **Total** | **30 550** | *(vacío)* | *(vacío)* | *(vacío)* |

*(Captura tomada: `clase22-escenarios.png` con la matriz con total vacío y la tabla por nivel).*

### F2 · ¿Por qué [Kilos] dice 30 550 en las seis filas?
Porque `[Kilos]` proviene de la tabla de hechos a través de `dim_cultivo`/`dim_tiempo`, y al no existir relación con la tabla `escenario`, la columna `nivel` no filtra los kilos.

### F3 · Finca que cumple al 150
Cumple únicamente **Finca El Guayabo**, alcanzando un **100,64 %** ($14\,250 / 14\,160$).

### F4 · Conclusión para la gerencia
A nivel corporativo la meta se puede subir hasta el **120** (cumplimiento global 104,17 %); para mantener motivadas a la mayoría de las fincas individuales conviene subir hasta el **140** (donde 2 de las 3 fincas siguen cumpliendo). No es el mismo número porque la alta productividad de El Guayabo y Santa Rosa enmascara el déficit crítico de La Unión en el promedio global.

---

## Parte G · Preguntas de cierre

1. **¿Qué filtra un segmentador de una tabla desconectada?**  
   Filtra únicamente a la propia tabla desconectada dentro del contexto de evaluación DAX; no filtra ninguna otra tabla del modelo por sí mismo.

2. **¿Qué devuelve SELECTEDVALUE con dos valores o ninguno?**  
   Devuelve `BLANK()` por defecto, o el valor alternativo provisto en su segundo argumento.

3. **Regla de detección del día:**  
   «Si un parámetro tiene un valor por defecto, dos filtros a la vez calcularán con un tercero sin avisarte».

4. **Dos pruebas ante un segmentador de tipo de cambio:**  
   1) Marcar dos tipos de cambio a la vez (Ctrl+clic) para comprobar si la tabla se calla o calcula con un valor inventado; 2) Desmarcar todas las opciones y verificar si el total queda en blanco o asume una tasa por defecto no advertida.

5. **Caso donde el valor alternativo de SELECTEDVALUE tiene sentido:**  
   En selectores de unidad de medida (por ejemplo, devolver "USD" por defecto si el usuario no ha seleccionado ninguna moneda).
