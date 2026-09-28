---
marp: true
paginate: true
theme: default
title: "Clase 28 · Cada cosecha, dos veces"
style: |
  section { font-family: system-ui, -apple-system, "Segoe UI", sans-serif; font-size: 26px; background: #fbfbfa; color: #1f2933; padding: 60px 70px; }
  section.lead { background: #16324f; color: #f4f7fa; }
  section.lead h1 { color: #ffffff; font-size: 54px; line-height: 1.1; }
  section.lead h2 { color: #7fb3d5; font-weight: 400; font-size: 30px; }
  h1 { color: #16324f; font-size: 40px; border-bottom: 3px solid #f2a104; padding-bottom: 10px; }
  h2 { color: #1c7293; font-size: 32px; }
  strong { color: #b3541e; }
  code { background: #eef2f6; padding: 1px 6px; border-radius: 4px; }
  pre { background: #16324f; border-radius: 8px; font-size: 20px; }
  pre code { background: transparent; color: #e8eef4; }
  table { font-size: 23px; }
  th { background: #16324f; color: #fff; }
  blockquote { border-left: 5px solid #f2a104; color: #4a5568; font-style: normal; }
  footer { color: #8a99a8; font-size: 16px; }
  .verde { background: #1E8449; color: #fff; padding: 2px 10px; border-radius: 4px; }
  .rojo { background: #C0392B; color: #fff; padding: 2px 10px; border-radius: 4px; }
footer: "Curso de SQL · AgroDB · Clase 28"
---

<!-- _class: lead -->

# Cada cosecha, dos veces

## Combinar consultas en Power Query, y una llave a la que le faltaba la calidad

Clase 28 · 28 de septiembre

---

# Lo que llega hoy

La gerencia ya no quiere kilos: quiere **dinero**. Comercial manda `precios.csv`:

| `cultivo_id` | `calidad` | `precio_kg` |
|---|---|---|
| 1 | primera | 0.50 |
| 1 | segunda | 0.30 |
| 2 | primera | 0.60 |
| 2 | segunda | 0.40 |
| 3 | primera | 2.50 |
| 3 | segunda | 1.80 |
| 5 | primera | 0.30 |

> *«Es la lista 2026. El kilo nos sale en promedio a **cincuenta y tantos centavos**. Quiero los **ingresos por finca**.»*

---

# Anexar contra combinar

| | **Anexar** (viernes) | **Combinar** (hoy) |
|---|---|---|
| Pone la otra tabla | **debajo** | **al lado** |
| Agrega | filas | columnas |
| Se parece a | `UNION ALL` | `LEFT JOIN` |
| Filas de `h_cosecha` después | más, **a propósito** | **las mismas**… si la llave está bien |

<br>

Una combinación busca, para cada fila de la primera tabla, **las filas de la segunda que tengan la misma llave**. Si encuentra una, trae sus columnas. Si encuentra **dos**, trae **dos filas**.

> Es el `JOIN` de la clase 1 con botones, y el *fan-out* de la clase 5 **sin una línea de SQL**.

---

# El modelo de hoy

Un `.pbix` nuevo con cinco CSV de `datos/csv_clase28/`, las **cinco relaciones** de siempre, y `precios.csv` cargado **sin relacionar**. La tabla de control:

| Finca | `[Kilos]` | `[Meta]` | `[Cumplimiento]` | `[Cosechas]` |
|---|---|---|---|---|
| Agricola La Union | 2 100 | 5 000 | 42,00 % | 2 |
| Finca El Guayabo | 14 250 | 9 440 | 150,95 % | 3 |
| Hacienda Santa Rosa | 14 200 | 10 000 | 142,00 % | 4 |
| **Total** | **30 550** | **24 440** | **125,00 %** | **9** |

> El viernes la prueba fue **un número viejo que no debía moverse**. Hoy no se agrega ni una cosecha: el 30 550 **no tiene por qué moverse**.

---

# La combinación obvia

**Transformar datos** → consulta `h_cosecha` → **Inicio → Combinar consultas**.

1. Arriba `h_cosecha`, clic en **`cultivo_id`**. Abajo `precios`, clic en **`cultivo_id`**.
2. Tipo de combinación: **Externa izquierda**.
3. Abajo, Power Query dice:

> **«La selección coincide con 25 de 25 filas de la primera tabla.»**

4. En la columna nueva, el ícono de expandir → solo **`precio_kg`**. **Cerrar y aplicar.**

```
Ingresos = SUMX( h_cosecha , h_cosecha[kg] * h_cosecha[precio_kg] )
```

```
Precio por kilo = DIVIDE( [Ingresos] , [Kilos] )
```

---

# Los ingresos

Página nueva, tabla por finca:

| Finca | `[Ingresos]` | `[Precio por kilo]` |
|---|---|---|
| Agricola La Union | 9 030 | 2,15 |
| Finca El Guayabo | 7 390 | 0,40 |
| Hacienda Santa Rosa | 11 660 | 0,41 |
| **Total** | **28 080** | **0,55** |

<br>

- 25 de 25 filas **coincidieron**: ninguna cosecha se quedó sin precio.
- El kilo sale a **0,55**: los «cincuenta y tantos centavos» de comercial.
- La Unión, con cacao, tiene el kilo más caro. **Tiene sentido.**

> Nada en rojo. Todo **coincide**.

---

# El número que no debía moverse

Regresa a la página de control. Mismos segmentadores:

| Finca | `[Kilos]` | `[Meta]` | `[Cumplimiento]` | `[Cosechas]` |
|---|---|---|---|---|
| Agricola La Union | <span class="rojo">**4 200**</span> | 5 000 | <span class="rojo">**84,00 %**</span> | **4** |
| Finca El Guayabo | **18 700** | 9 440 | **198,09 %** | **5** |
| Hacienda Santa Rosa | **28 400** | 10 000 | **284,00 %** | **8** |
| **Total** | <span class="rojo">**51 300**</span> | **24 440** | **209,90 %** | **17** |

<br>

La Unión **duplicó** su cumplimiento **sin cortar un kilo más**. Y `h_cosecha`, en Power Query, dice abajo a la izquierda: **46 filas**. Tenía **25**.

---

# ¿Y qué error dio?

## Ninguno. «Coincide con 25 de 25».

<br>

- **25 de 25** cuenta las filas que encontraron **al menos una** pareja. No cuenta **cuántas**.
- El precio medio **casi no se movió** (0,55 contra 0,56): los kilos y el dinero se inflaron **juntos**, y el cociente se veía sano.
- La tabla de ingresos **no tenía contra qué compararse**: es una medida nueva.

<br>

> La prueba del viernes lo atrapó. Pero solo porque **la tabla de control seguía en el lienzo**.

---

# Dónde se duplicó

**Vista → Distribución de columnas**, debajo de `cosecha_id`:

| | Antes de combinar | Después |
|---|---|---|
| Filas | 25 | **46** |
| Distintos | 25 | 25 |
| **Únicos** | **25** | **4** |

<br>

Solo **4** cosechas siguen apareciendo una vez: las del **maíz** (7, 15, 19 y 24), el único cultivo con **un solo precio**. Las otras 21 encontraron **primera y segunda**.

> La llave de `precios` no es el cultivo. Es **el cultivo y la calidad**.

---

# La prueba de la llave

Una medida que tiene que decir **cero** siempre:

```
Filas repetidas = COUNTROWS( h_cosecha ) - DISTINCTCOUNT( h_cosecha[cosecha_id] )
```

| | Enero–abril 2026 | Sin segmentadores |
|---|---|---|
| Llave incompleta | <span class="rojo">**8**</span> | <span class="rojo">**21**</span> |
| Llave completa | **0** | **0** |

<br>

> `cosecha_id` es la llave de `h_cosecha`. Si después de combinar **se repite**, cada kilo de esa cosecha **se está contando otra vez**.

---

# El segundo arreglo obvio

Power Query tiene un botón para las filas repetidas: selecciona `cosecha_id` → **Inicio → Quitar filas → Quitar duplicados**.

| | |
|---|---|
| Filas de `h_cosecha` | **25** <span class="verde">✓</span> |
| Tabla de control | **30 550 / 125,00 %** <span class="verde">✓</span> |
| `[Filas repetidas]` | **0** <span class="verde">✓</span> |
| `[Ingresos]` | <span class="rojo">**18 110**</span> |

<br>

Pasa **las tres pruebas**. Y los ingresos siguen mal.

---

# El precio que sobrevivió

`Quitar duplicados` deja **una** fila por cosecha: **la primera que encuentra**, no la que correspondía.

| `cosecha_id` | Cultivo | Calidad | Kilos | Se cobró | Era | De más |
|---|---|---|---|---|---|---|
| 2 | Mango | **segunda** | 3 100 | 0,50 | 0,30 | **620** |
| 6 | Guayaba | **segunda** | 1 850 | 0,60 | 0,40 | **370** |
| | | | | | | **990** |

<br>

17 120 + 990 = **18 110**. Si en tu máquina sobrevive la otra fila, salen **12 910**: igual de mal, al revés.

> Es `Quitar errores` con otra ropa: **quita filas**, y las que deja **no las escogió nadie**.

---

# El arreglo: la llave completa

Borra los pasos **Duplicados quitados**, **precios expandido** y **Consultas combinadas**. Luego:

1. **Combinar consultas**. Arriba: clic en **`cultivo_id`**, **Ctrl** + clic en **`calidad`**.
2. Abajo: **`cultivo_id`**, **Ctrl** + **`calidad`**, **en el mismo orden**: aparecen un **1** y un **2** en los encabezados.
3. Expande solo **`precio_kg`**. **Cerrar y aplicar.**

| Finca | `[Kilos]` | `[Cumplimiento]` | `[Ingresos]` | `[Precio por kilo]` |
|---|---|---|---|---|
| Agricola La Union | 2 100 | 42,00 % | 5 250 | 2,50 |
| Finca El Guayabo | 14 250 | 150,95 % | 5 240 | 0,37 |
| Hacienda Santa Rosa | 14 200 | 142,00 % | 6 630 | 0,47 |
| **Total** | **30 550** | **125,00 %** | <span class="verde">**17 120**</span> | **0,56** |

---

# Tres lugares, tres avisos

La misma búsqueda con la llave incompleta, hecha en tres lados:

| Dónde | Qué pasa |
|---|---|
| **Combinar consultas** | «coincide con 25 de 25», y **46 filas** sin un aviso |
| **Relación** `h_cosecha[cultivo_id]` → `precios[cultivo_id]` | la vista de modelo propone **varios a varios** y **avisa** |
| **`LOOKUPVALUE`** en una columna | **truena**: *una tabla de varios valores donde se esperaba un solo valor* |

```
Precio buscado = LOOKUPVALUE( precios[precio_kg] ,
    precios[cultivo_id] , h_cosecha[cultivo_id] ,
    precios[calidad] , h_cosecha[calidad] )
```

> En la clase 19 `LOOKUPVALUE` tronó con el regional. **Hoy su error es el bueno otra vez.**

---

# La prueba de cada combinación

| Qué revisas | Qué atrapa |
|---|---|
| **filas** de la tabla antes y después | la llave incompleta: 25 → 46 |
| **distintos contra únicos** de la llave | cuáles cosechas se duplicaron |
| **`[Filas repetidas]`** en cero | lo mismo, como medida que se queda en el tablero |
| un **número viejo** que no debía moverse | el 30 550 que se fue a 51 300 |
| **una fila a mano** por cada caso raro | el precio que sobrevivió a `Quitar duplicados` |

<br>

> Las cuatro primeras las pasa `Quitar duplicados`. **La quinta no**: la cosecha 2 es de segunda y se cobró a 0,50.

---

# Los errores que van a ver hoy

| Síntoma | Qué pasó | Arreglo |
|---|---|---|
| `precio_kg` sale **50** en vez de 0,50 | configuración regional con coma decimal | fija **Español (México)** en el archivo, como en A0 |
| la combinación dice **0 de 25** | `cultivo_id` es número en una tabla y texto en la otra | mismo tipo en las dos |
| la columna se llama **`precios.precio_kg`** | quedó marcado **usar el nombre original como prefijo** | no afecta; o desmárcalo al expandir |
| aparecen `cultivo_id` y `calidad` **repetidas** | expandiste todas las columnas | expande solo `precio_kg` |
| el control dice **51 300** | combinaste solo por `cultivo_id` | la llave completa, con **Ctrl** |
| el control dice 30 550 y los ingresos **18 110** | quitaste duplicados | borra ese paso y combina por las dos |

---

<!-- _class: lead -->

# La idea del día

## Una combinación que cambia el número de filas no agregó columnas: agregó cosechas.

<br>

Combinando solo por el cultivo, Power Query dijo **«25 de 25»**, dejó **46 filas** y La Unión en **84,00 %**. `Quitar duplicados` devolvió el **30 550** y se quedó con el precio equivocado: **18 110**. Con la llave completa, **cultivo y calidad**, son **17 120**.

<br>

**Práctica:** arma el modelo, combina por el cultivo, encuentra las cosechas repetidas, cae en `Quitar duplicados`, encuentra los 990 y combina por la llave completa.

**Y la tabla de control tiene que seguir diciendo 30 550, con `[Filas repetidas]` en cero y 17 120 en ingresos.**
