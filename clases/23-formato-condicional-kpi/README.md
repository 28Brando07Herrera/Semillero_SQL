# Clase 23 · El rojo que sí cumplía
**Lunes 21 de septiembre**

**50 minutos de clase** y el resto de práctica. Novena clase seguida del lado de Power BI: **hoy tampoco se prende Oracle.**

## Material

| Qué | Dónde |
|---|---|
| Diapositivas | [slides.md](slides.md) · [versión web](https://negatix092.github.io/Semillero_SQL/23-formato-condicional-kpi.html) |
| Ejercicio práctico | [ejercicio.md](ejercicio.md) |
| Datos del día | **ninguno nuevo**: los cinco CSV de la clase 17, los mismos de [`datos/csv_clase19/`](../../datos/csv_clase19/) |

> **Hoy no se baja nada.** Se trabaja sobre el `.pbix` de la clase 22, **con Ver como apagado** y **el segmentador `tipo` sin nada marcado**.

## Qué hace falta tener listo

| | |
|---|---|
| Power BI Desktop | y nada más |
| Oracle, Docker, el OCMT | **no**, hoy tampoco |
| El `.pbix` de la clase 22 | con `[Kilos]`, `[Meta]`, `[Cumplimiento]`, `dim_tiempo` **marcada como tabla de fechas** y `nombre_mes` **ordenada por** `mes` |

## De qué se trata

La gerencia no quiere leer números: quiere **ver de un vistazo quién cumple**, en verde o en rojo, y **un KPI** arriba del tablero. Es la clase de los **arreglos visuales**: formato condicional (degradado, reglas y valor del campo) y los tres objetos que enseñan un indicador (tarjeta, medidor y KPI).

Se empieza por lo fácil y funciona: un **degradado** en los kilos por cultivo, y una **regla** de «arriba de 5 000 kilos, verde; abajo, rojo», escrita con tipo **Número**.

## El giro de hoy

Luego la regla va en `[Cumplimiento]`: «de 0 a 100 %, rojo; de 100 a 200 %, verde». La columna está en porcentaje, así que se escoge el tipo **Porcentaje**. Resultado: La Unión en rojo, El Guayabo en verde y **Santa Rosa, con 142,00 %, en rojo**. Ningún aviso, y dos de tres colores son justo los esperados.

En una regla, **Porcentaje** no es el valor en porcentaje: es **la posición dentro del rango** entre el mínimo y el máximo de lo que se ve. Santa Rosa está en el **91,78 %** del rango, y «de 100 a 200 % del rango» es solo el máximo. La prueba: con **perenne** marcado, El Guayabo baja y Santa Rosa **se pone verde sin que su 142,00 % cambie**.

El arreglo es que el color **lo diga una medida**:

```
Color cumplimiento = IF( [Cumplimiento] >= 1 , "#1E8449" , "#C0392B" )
```

con **Valor del campo**, y aplicado también al total.

Y en la segunda mitad pasa lo mismo con el **KPI**: con `[Kilos]`, el mes en el eje y `[Meta]` de destino, dice **19 750** contra **8 300**, **+137,95 %**, en verde. La tarjeta de al lado dice **30 550**. El objeto visual KPI enseña **el último punto de su eje**, y el último punto es **abril**. Con `[Kilos YTD]` y `[Meta YTD]` enseña el año: **30 550 contra 24 440, +25,00 %**, y la tendencia deja ver que a fin de marzo se iba **33,09 %** abajo.

> Ninguno de los números estaba mal. Lo que mentía era **el color**, y **el título** del KPI, que no decía de qué periodo hablaba.

## Lo que hay que saber al terminar

- Dónde está el **formato condicional** y sus tres estilos: **Degradado**, **Reglas** y **Valor del campo**
- Que el **degradado** pinta según el mínimo y el máximo **de lo que se ve**
- Que en una regla, **Número** compara contra lo que escribes, y **Porcentaje** contra **el rango** de la tabla
- Que un porcentaje por dentro es un **decimal**: el 142,00 % se escribe **1,42** en una regla con Número
- Escribir una **medida de color** con `IF` y códigos hexadecimales, y usarla con **Valor del campo**, también en los totales
- La diferencia entre **tarjeta**, **medidor** y **KPI**, y que el máximo del medidor **por omisión es el doble del valor**
- Que el objeto visual **KPI enseña el último punto** de su eje de tendencia, no el total
- `TOTALYTD` para que el KPI enseñe **el año**, y que el título diga **qué periodo** se está viendo

## La idea del día

**Un color también es una cuenta: si no sabes contra qué compara, no sabes qué dice.**

## Las cuatro cosas que son la clase

Si el día se complica y hay que recortar, estas no se recortan:

1. **Santa Rosa en rojo con 142,00 %**, por la regla con Porcentaje.
2. **Porcentaje del rango**: el 91,78 %, y Santa Rosa verde con perenne marcado.
3. **`[Color cumplimiento]` con Valor del campo**: dos verdes, un rojo y el total verde.
4. **El KPI con 19 750** junto a la tarjeta con 30 550, y el KPI del año con **+25,00 %**.

## Los números de control

Todos con segmentadores en `anio` = 2026, `mes` en 1–4 y `tipo` **sin nada marcado**.

| Dónde | Qué debe decir |
|---|---|
| La tabla por finca | La Union **2 100 / 5 000 / 42,00 %** · El Guayabo **14 250 / 9 440 / 150,95 %** · Santa Rosa **14 200 / 10 000 / 142,00 %** · total **30 550 / 24 440 / 125,00 %** |
| La tabla por cultivo | Mango **12 700** · Maiz **9 800** · Guayaba **5 950** · Cacao **2 100** |
| Degradado, posición en la escala | 100 % · 72,64 % · 36,32 % · 0 % |
| Regla de 5 000 con Número | tres verdes, **Cacao rojo** |
| Regla en `[Cumplimiento]` con **Porcentaje** | La Union rojo · El Guayabo verde · **Santa Rosa rojo** |
| Porcentaje del rango | La Union **0 %** · Santa Rosa **91,78 %** · El Guayabo **100 %** |
| Lo mismo con **perenne** marcado | El Guayabo **47,14 %** (5,14 % del rango, rojo) · Santa Rosa **142,00 %**, ahora **verde** |
| `[Color cumplimiento]` | La Union rojo · El Guayabo verde · Santa Rosa **verde** · total **verde** |
| Medidor | valor **30 550** · destino **24 440** · máximo por omisión **61 100** · con `[Tope del medidor]` **36 660** |
| KPI con `[Kilos]` y `[Meta]` | **19 750** · objetivo **8 300** · **+137,95 %** |
| Por mes | Marzo 10 800 / 6 900 · Abril **19 750 / 8 300** |
| KPI con `[Kilos YTD]` y `[Meta YTD]` | **30 550** · objetivo **24 440** · **+25,00 %** · en marzo 10 800 / 16 140, **−33,09 %** |
| KPI del año, clic en La Unión | 2 100 contra 5 000, **−58,00 %** |

## Entrega

En `entregas/apellido-nombre/`, por *pull request*, **dos archivos**:

| Archivo | Qué lleva |
|---|---|
| `Ejercicio23_Apellido_Nombre.md` | cada regla y cada fórmula con **su resultado anotado debajo** (qué color salió en cada fila), la cuenta a mano del porcentaje del rango y las respuestas de la parte G |
| `clase23-semaforo.png` | captura de **la tabla por finca** pintada con `[Color cumplimiento]` (Santa Rosa en verde y el total pintado), junto a **la tarjeta** con 30 550 y **el KPI del año** con 30 550 contra 24 440 |

> El `.pbix` no se entrega: el repositorio lo ignora a propósito.

## Nota sobre el material

Los números de esta clase —el 91,78 % de Santa Rosa en el rango, los colores de cada regla, el 19 750 contra 8 300 del KPI y el 30 550 contra 24 440 del KPI del año— están **verificados contra los CSV publicados en `datos/csv_clase19/`** con `docente/clase23_verificacion_docente.py`, que modela cada regla de color (Número, Porcentaje del rango, Valor del campo) y el último punto del eje del KPI.

Que **Porcentaje** en una regla sea porcentaje del rango, y que el máximo del medidor sea el doble del valor, es lo que dice la documentación de Microsoft. Lo que **ningún script puede verificar** es lo que dibuja Power BI en tu versión: cómo se llaman los pozos del KPI, si la etiqueta de fecha del KPI viene prendida y cómo escribe la distancia a la meta. Si en tu máquina algo sale distinto, **anótalo en la entrega: eso puntúa**, igual que documentar una discrepancia del enunciado.
