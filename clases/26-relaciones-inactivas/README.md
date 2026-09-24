# Clase 26 · Los kilos que llegaron en otro mes
**Jueves 24 de septiembre**

**50 minutos de clase** y el resto de práctica. De nuevo del lado de Power BI: **hoy tampoco se prende Oracle.**

## Material

| Qué | Dónde |
|---|---|
| Diapositivas | [slides.md](slides.md) · [versión web](https://negatix092.github.io/Semillero_SQL/26-relaciones-inactivas.html) |
| Ejercicio práctico | [ejercicio.md](ejercicio.md) |
| Datos del día | [`datos/csv_clase26/`](../../datos/csv_clase26/): los seis CSV de la clase 19, con **`h_cosecha.csv` cambiado**: trae `fecha_entrega` al final |

> **Hoy sí se baja algo.** Copia `datos/csv_clase26/` a `C:\agrodb26\` y empieza con un **`.pbix` vacío**, como en la clase 24.

## Qué hace falta tener listo

| | |
|---|---|
| Power BI Desktop | y nada más |
| Oracle, Docker, el OCMT | **no**, hoy tampoco |
| El `.pbix` de clases anteriores | **no**: hoy se arma uno nuevo con cinco CSV (todos menos `seguridad.csv`) |

## De qué se trata

`h_cosecha` trae hoy **dos fechas**: `fecha`, el día del corte, y `fecha_entrega`, el día en que la cosecha se entregó al comprador. Entre una y otra pasa lo que cada cultivo necesita: 2 días la fruta, 12 el maíz, 27 el cacao. Y finanzas, que cobra al entregar, pide los **kilos entregados por mes** en el mismo tablero.

Un modelo puede tener **varias relaciones entre las mismas dos tablas**, pero **solo una activa**. Al dibujar `h_cosecha[fecha_entrega]` → `dim_tiempo[fecha]`, Power BI la crea **punteada: inactiva**.

## El giro de hoy

La medida obvia es `Kilos entregados = SUM( h_cosecha[kg] )`. Puesta por mes junto a `[Kilos]`, las dos columnas salen **idénticas**: marzo 10 800, abril 19 750, total 30 550. Ningún aviso. La columna dice «entregados» y cuenta los **cosechados**, porque un filtro de `dim_tiempo` solo viaja por la relación **activa**, y la medida nunca pidió la otra.

El arreglo es pedirla dentro de la medida:

```
Kilos entregados = CALCULATE( [Kilos] , USERELATIONSHIP( h_cosecha[fecha_entrega] , dim_tiempo[fecha] ) )
```

Y los meses cambian: **enero 1 200** (el cacao cortado el 5 de diciembre de 2025), **marzo 9 600**, **abril 10 250**, total **21 050**. Sin filtro de mes, el año 2026 dice **30 550** cosechados contra **31 750** entregados.

El atajo tentador —**activar la otra relación**— hace que el `SUM` «funcione», pero mueve **todo lo demás**: sin tocar una medida, El Guayabo baja de 150,95 % a **47,14 %** y la empresa de 125,00 % a **86,13 %**.

> Ninguna medida estaba mal escrita. Lo que no se veía era **por cuál camino** llegaba el mes.

## Lo que hay que saber al terminar

- Que entre dos tablas puede haber **varias relaciones**, y **solo una activa**; cómo se ve cada una en la vista de modelo
- Que un filtro viaja **solo por la relación activa**, y que el nombre de una medida no elige el camino
- `USERELATIONSHIP` dentro de `CALCULATE`, y que necesita la relación **dibujada** (si no, da error)
- Que **cambiar la relación activa** cambia todas las medidas que ya existen, y por qué la activa va con la fecha de **la meta**
- Que el mismo segmentador de `anio` significa **dos años distintos** para dos medidas que van por caminos distintos
- `DATEDIFF` entre dos columnas de la misma fila, dentro de `AVERAGEX`

## La idea del día

**Dos fechas, un calendario: si la medida no dice por cuál camino va, va por el de siempre.**

## Las cuatro cosas que son la clase

Si el día se complica y hay que recortar, estas no se recortan:

1. **La relación punteada** en la vista de modelo.
2. **`[Kilos entregados]` idéntica a `[Kilos]`** con el `SUM`, sin un solo aviso.
3. **`USERELATIONSHIP`**: enero 1 200, marzo 9 600, abril 10 250, total **21 050**.
4. **Activar la otra** mueve la tabla por finca a **86,13 %**, y se regresa.

## Los números de control

Con segmentadores en `anio` = 2026 y `mes` en 1–4, salvo donde se dice.

| Dónde | Qué debe decir |
|---|---|
| La tabla por finca | La Union **2 100 / 5 000 / 42,00 %** · El Guayabo **14 250 / 9 440 / 150,95 %** · Santa Rosa **14 200 / 10 000 / 142,00 %** · total **30 550 / 24 440 / 125,00 %** |
| El modelo | **seis relaciones**: cinco continuas y **una punteada**, la de `fecha_entrega` |
| `[Kilos entregados]` con `SUM` | igual a `[Kilos]`: Marzo **10 800** · Abril **19 750** · total **30 550** |
| `[Kilos entregados]` con `USERELATIONSHIP` | Enero **1 200** · Marzo **9 600** · Abril **10 250** · total **21 050** |
| Lo mismo por finca | La Union **2 400** · El Guayabo **4 450** · Santa Rosa **14 200** |
| Año 2026 completo, sin `mes` | `[Kilos]` **30 550** · `[Kilos entregados]` **31 750**, con Mayo **10 700** |
| La diferencia de enero a abril | **9 500** = las cosechas 7 y 9 (10 700) se entregaron en mayo; la 25 (1 200) entra desde diciembre |
| Con la activa en `fecha_entrega` | La Union **2 400 / 48,00 %** · El Guayabo **4 450 / 47,14 %** · Santa Rosa **14 200 / 142,00 %** · total **21 050 / 24 440 / 86,13 %** |
| `[Dias a la entrega]` | Mango **2** · Guayaba **2** · Maiz **12** · Cacao **27** · total **8,67** |

## Entrega

En `entregas/apellido-nombre/`, por *pull request*, **tres archivos**:

| Archivo | Qué lleva |
|---|---|
| `Ejercicio26_Apellido_Nombre.md` | cada medida con **su resultado anotado debajo**, las tablas que se piden y las respuestas |
| `clase26-modelo.png` | la vista de modelo: cinco relaciones continuas y **una punteada** |
| `clase26-entregas.png` | la tabla por mes con `[Kilos]` y `[Kilos entregados]`: **1 200 / 9 600 / 10 250**, total **21 050** |

> El `.pbix` no se entrega: el repositorio lo ignora a propósito.

## Nota sobre el material

Los números de esta clase —los meses por cosecha y por entrega, el 21 050 y el 31 750, lo que pasa al cambiar la relación activa y los días a la entrega— están **verificados contra los CSV publicados en `datos/csv_clase26/`** con `docente/clase26_verificacion_docente.py`, que modela las dos relaciones entre `h_cosecha` y `dim_tiempo` y deja pasar el filtro **solo por la activa**, salvo en la medida que pide la otra.

Lo que **ningún script puede verificar** es lo que dibuja Power BI en tu versión: cómo se ve la línea de una relación inactiva, qué dice el cuadro de **Administrar relaciones**, y el texto del error cuando `USERELATIONSHIP` no encuentra la relación. Si en tu máquina algo sale distinto, **anótalo en la entrega: eso puntúa**.
