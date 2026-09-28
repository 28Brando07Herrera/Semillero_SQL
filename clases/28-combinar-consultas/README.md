# Clase 28 · Cada cosecha, dos veces
**Lunes 28 de septiembre**

**50 minutos de clase** y el resto de práctica. De nuevo **adentro de Power Query**, como el viernes: **hoy tampoco se prende Oracle.**

## Material

| Qué | Dónde |
|---|---|
| Diapositivas | [slides.md](slides.md) · [versión web](https://negatix092.github.io/Semillero_SQL/28-combinar-consultas.html) |
| Ejercicio práctico | [ejercicio.md](ejercicio.md) |
| Datos del día | [`datos/csv_clase28/`](../../datos/csv_clase28/): los seis CSV de la clase 19, **idénticos**, más **`precios.csv`**, la lista de precios por kilo de comercial para 2026 |

> **Hoy sí se baja algo.** Copia `datos/csv_clase28/` a `C:\agrodb28\` y empieza con un **`.pbix` vacío**, como en la 24, la 26 y la 27.

## Qué hace falta tener listo

| | |
|---|---|
| Power BI Desktop | y nada más |
| Oracle, Docker, el OCMT | **no**, hoy tampoco |
| El `.pbix` de clases anteriores | **no**: hoy se arma uno nuevo con seis CSV, y los precios entran a `h_cosecha` por Power Query |

## De qué se trata

La gerencia ya no quiere solo kilos: quiere **dinero**. Comercial manda `precios.csv`, siete filas con el precio por kilo de cada cultivo **según su calidad**: el mango de primera se paga a 0,50 y el de segunda a 0,30. Hay que llevar ese precio a cada cosecha y escribir `[Ingresos]`.

El viernes se usó **Anexar consultas**: una tabla **debajo** de otra, más filas. Hoy se usa **Combinar consultas**: una tabla **al lado** de otra, más columnas. Es el `JOIN` de la clase 1, con botones.

## El giro de hoy

La combinación obvia es por `cultivo_id`, la única columna que el precio y la cosecha comparten a la vista. Power Query dice **«La selección coincide con 25 de 25 filas de la primera tabla»**, se expande `precio_kg`, se carga, y la tabla de ingresos por finca sale limpia: **28 080** dólares, a **0,55** el kilo, justo lo que comercial esperaba.

Pero la tabla de control, la de siempre, ya no dice 30 550: dice **51 300**. La Unión pasó de **42,00 %** a **84,00 %** sin cortar un kilo más, y Santa Rosa está en **284,00 %**. `h_cosecha` tenía 25 filas y ahora tiene **46**. La llave de `precios` no es el cultivo: es **el cultivo y la calidad**. Cada cosecha de mango encontró **dos** precios y **se duplicó**. Es el *fan-out* de la clase 5, sin una línea de SQL.

Y hay un segundo arreglo obvio, peor que el primero: **Quitar duplicados** sobre `cosecha_id`. Las filas vuelven a 25, el control vuelve a **30 550**, la prueba del viernes **pasa**… y los ingresos dicen **18 110**, no 17 120. Quedó un precio por cosecha, pero **el que sobrevivió**, no el que correspondía: la cosecha 2, mango **de segunda**, cobrada a precio de primera.

El arreglo es la llave completa: combinar por **`cultivo_id` y `calidad`**, con **Ctrl**. 25 filas, **30 550**, y **17 120** en ingresos.

> Ninguna cosecha estaba repetida en el archivo. Lo que estaba incompleto era **la llave con la que se buscó su precio**.

## Lo que hay que saber al terminar

- **Combinar consultas** contra **Anexar consultas**: columnas al lado contra filas debajo
- Que la **llave** de una tabla de búsqueda puede tener **dos columnas**, y cómo se combina por dos con **Ctrl**
- Que **«coincide con 25 de 25»** cuenta filas **con** pareja, no filas **con una sola** pareja
- **Vista → Distribución de columnas**: **distintos** contra **únicos**, y la prueba de la llave
- Que **`Quitar duplicados` quita filas**, igual que `Quitar errores`: no escoge la buena
- Que `LOOKUPVALUE` **truena** donde Combinar se calla, y que la vista de modelo **avisa** con *varios a varios*
- **Reconciliar** una combinación: filas antes y después, y `COUNTROWS` contra `DISTINCTCOUNT` de la llave

## La idea del día

**Una combinación que cambia el número de filas no agregó columnas: agregó cosechas.**

## Las cuatro cosas que son la clase

Si el día se complica y hay que recortar, estas no se recortan:

1. **El «25 de 25»** y la tabla de ingresos en **28 080**, que se ve bien.
2. **El 30 550 que se movió** a 51 300, con La Unión en **84,00 %** y **46** filas.
3. **`Quitar duplicados`**: el control vuelve a 30 550, y los ingresos dicen **18 110**.
4. **La llave completa**: `cultivo_id` + `calidad`, **17 120**.

## Los números de control

Con segmentadores en `anio` = 2026 y `mes` de 1 a 4, salvo donde se dice.

| Dónde | Qué debe decir |
|---|---|
| La tabla por finca, antes de los precios | La Union **2 100 / 5 000 / 42,00 % / 2** · El Guayabo **14 250 / 9 440 / 150,95 % / 3** · Santa Rosa **14 200 / 10 000 / 142,00 % / 4** · total **30 550 / 24 440 / 125,00 % / 9** |
| Power Query, combinando solo por `cultivo_id` | **coincide con 25 de 25**; `h_cosecha` pasa de **25** a **46** filas; `cosecha_id` con **25 distintos, 4 únicos** |
| Ingresos por finca, combinación por `cultivo_id` | La Union **9 030** · El Guayabo **7 390** · Santa Rosa **11 660** · total **28 080**, a **0,5474** el kilo |
| La tabla de control con esa combinación | La Union **4 200 / 84,00 % / 4** · El Guayabo **18 700 / 198,09 % / 5** · Santa Rosa **28 400 / 284,00 % / 8** · total **51 300 / 209,90 % / 17** · `[Filas repetidas]` **8** |
| Con `Quitar duplicados` sobre `cosecha_id` | control de vuelta en **30 550 / 125,00 % / 9**; ingresos **5 250 / 5 610 / 7 250**, total **18 110** |
| Lo que cobró de más | cosecha **2** (mango de segunda, 3 100 × 0,20 = **620**) y cosecha **6** (guayaba de segunda, 1 850 × 0,20 = **370**): **990** |
| Con la llave completa | control en **30 550 / 125,00 % / 9**, `[Filas repetidas]` **0**; ingresos La Union **5 250** · El Guayabo **5 240** · Santa Rosa **6 630** · total **17 120**, a **0,5604** el kilo |
| Ingresos por cultivo, llave completa | Mango **5 730** · Guayaba **3 200** · Cacao **5 250** · Maiz **2 940** |
| Las tarjetas, sin segmentadores | llave incompleta **46 filas / 25 cosechas / 21 repetidas / 135 950 kg** · llave completa **25 / 25 / 0 / 77 550 kg / 55 100 dólares** |

## Entrega

En `entregas/apellido-nombre/`, por *pull request*, **tres archivos**:

| Archivo | Qué lleva |
|---|---|
| `Ejercicio28_Apellido_Nombre.md` | cada medida con **su resultado anotado debajo**, las tablas que se piden y las respuestas |
| `clase28-distribucion.png` | Power Query con la **distribución de columnas** de `cosecha_id` en **25 distintos, 4 únicos** |
| `clase28-ingresos.png` | la tabla de ingresos por finca con la llave completa: **17 120**, y `[Filas repetidas]` en **0** |

> El `.pbix` no se entrega: el repositorio lo ignora a propósito.

## Nota sobre el material

Los números de esta clase —las 46 filas, las tablas de control y de ingresos con cada combinación, lo que deja `Quitar duplicados` y las tarjetas— están **verificados contra los CSV publicados en `datos/csv_clase28/`** con `docente/clase28_verificacion_docente.py`, que modela la combinación externa izquierda por una y por dos columnas, y `Quitar duplicados` quedándose con la primera o con la última fila de cada cosecha.

Lo que **ningún script puede verificar** es lo que hace Power Query en tu versión: el texto literal del «coincide con», **qué fila sobrevive a `Quitar duplicados`** (el 18 110 supone que sobrevive la del precio de primera, que es la que aparece primero; si sobrevive la otra salen **12 910**, y es igual de incorrecto), el mensaje literal de `LOOKUPVALUE` y el aviso de la vista de modelo. Si en tu máquina algo sale distinto, **anótalo en la entrega: eso puntúa**.
