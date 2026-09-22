---
marp: true
paginate: true
theme: default
title: "Clase 24 · Diez números para la gerencia"
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
  table { font-size: 22px; }
  th { background: #16324f; color: #fff; }
  blockquote { border-left: 5px solid #f2a104; color: #4a5568; font-style: normal; }
  footer { color: #8a99a8; font-size: 16px; }
  .verde { background: #1E8449; color: #fff; padding: 2px 10px; border-radius: 4px; }
  .rojo { background: #C0392B; color: #fff; padding: 2px 10px; border-radius: 4px; }
footer: "Curso de SQL · AgroDB · Clase 24 · Mini proyecto"
---

<!-- _class: lead -->

# Diez números para la gerencia

## Mini proyecto: un tablero desde un archivo vacío, con cada trampa del curso esperándolo

Clase 24 · 22 de septiembre

---

# El encargo

La gerencia pide **un solo tablero** para la junta de cumplimiento 2026, enero a abril:

<br>

1. Que se vea **quién cumple la meta**: verde o rojo, sin leer números.
2. Arriba, **un KPI** de cómo va el año contra la meta.
3. Que **cada gerente abra el mismo tablero y vea solo su finca**; el regional, sus dos fincas.
4. Que el **practicante** no vea nada… hasta que se le dé permiso, **sin tocar el modelo**.

<br>

> Todo lo que hace falta ya lo vieron entre la clase 14 y la 23. **Hoy no hay tema nuevo: hoy se arma todo junto, desde un `.pbix` vacío, y por tu cuenta.**

---

<style scoped>table { font-size: 19px; } p, li { font-size: 23px; }</style>

# Diez números, diez trampas

Se califica con **un checklist de diez puntos**, diez puntos cada uno. Cada punto es **un número o un color que se ve en una captura**, y cada uno descarta una trampa del curso:

| # | Qué se tiene que ver | Qué trampa descarta |
|---|---|---|
| 1 | seis tablas, seis relaciones | la relación que falta (14, 17) |
| 2 | metas 5 000 / 9 440 / 10 000 y total **125,00 %** | la meta sin fecha o sin finca (17) |
| 3 | Santa Rosa **verde** | la regla con Porcentaje (23) |
| 4 | degradado: Mango oscuro, Cacao blanco | el color que no se sabe contra qué compara (23) |
| 5 | KPI del año **30 550** contra **24 440** | el KPI que enseña abril (23) |
| 6 | La Unión viéndose a sí misma: **42,00 %** | el rol en la tabla equivocada (18, 19) |
| 7 | el regional: **113,23 %** | el `LOOKUPVALUE` que truena (19) |
| 8 | el practicante: **nada** | la puerta abierta por defecto (19) |
| 9 | el practicante, con permiso: **142,00 %** | el rol que hay que reabrir (19) |
| 10 | el `.md` con la trampa de cada punto | haber llegado al número sin saber por qué |

---

<style scoped>table { font-size: 19px; } p, li { font-size: 22px; }</style>

# Hoy trabajas por tu cuenta

**Hoy no hay clase en vivo: estas diapositivas son la clase.** Avanza una por una, con Power BI en la otra ventana. Cada lámina de «Parte» trae los clics, y el [ejercicio](https://github.com/Negatix092/Semillero_SQL/blob/main/clases/24-mini-proyecto-tablero/ejercicio.md) trae lo mismo con más detalle.

| Minuto | Deberías ir en | Captura |
|---|---|---|
| 0 → 10 | leer hasta aquí y copiar la carpeta a `C:\agrodb24\` | |
| 10 → 35 | **Parte A**: el modelo | 1 |
| 35 → 50 | **Parte B**: medidas y tabla por finca | |
| 50 → 73 | **Parte C**: semáforo y KPI | 2 |
| 73 → 101 | **Partes D y E**: el rol, los tres correos y el alta | 3, 4, 5 y 6 |
| 101 → 120 | revisión contra el checklist y *pull request* | |

**Cuando te atores**, en este orden: **1.** la lámina «Si algo no cuadra» y la tabla «Si algo falla» del ejercicio · **2.** pregúntale a un compañero · **3.** a los **20 minutos**, escribe `DUDA` en tu `.md` o abre un *issue*, **y sigue con la parte siguiente**.

**Capturas:** `Win + Shift + S` → rectángulo → clic en el aviso que aparece → **Guardar** con el nombre que pide cada lámina.

> El *pull request* se abre **hoy, al terminar**. Una captura con un número distinto al esperado, explicada, **vale la mitad**; una que falta, **cero**.

---

# Parte A · Un `.pbix` vacío y seis archivos

**Antes de abrir Power BI:** copia la carpeta `datos/csv_clase19/` a `C:\agrodb24\`. **Hoy se trabaja sobre esa copia**: en la parte E se edita un CSV, y el del repositorio **no se toca**.

1. Power BI Desktop → **archivo nuevo**. Guárdalo ya: `C:\agrodb24\clase24-tablero.pbix`.
2. **Archivo → Opciones y configuración → Opciones → Archivo actual → Carga de datos**:
   - desmarca **Fecha/hora automática** (clase 16),
   - desmarca **Detectar automáticamente nuevas relaciones** después de cargar los datos.
3. **Inicio → Obtener datos → Texto/CSV**, uno por uno, **los seis**: `dim_finca`, `dim_cultivo`, `dim_tiempo`, `h_cosecha`, `h_meta` y `seguridad`.

| Revisa el tipo antes de **Cargar** | Tiene que ser |
|---|---|
| `h_cosecha[fecha]`, `dim_tiempo[fecha]`, `h_meta[fecha_mes]` | **Fecha** |
| `h_cosecha[kg]`, `h_meta[kg_meta]` | Número entero |

> Hoy las relaciones **las dibujas tú**. Por eso se apaga la detección: que Power BI no adivine ninguna.

---

# Parte A · Las seis relaciones

**Vista de modelo.** Arrastra el campo del hecho sobre el de la dimensión. Las seis son **muchos a uno** (`*` → `1`), con dirección **Único**:

| # | Del lado muchos | Al lado uno |
|---|---|---|
| 1 | `h_cosecha[finca_id]` | `dim_finca[finca_id]` |
| 2 | `h_cosecha[cultivo_id]` | `dim_cultivo[cultivo_id]` |
| 3 | `h_cosecha[fecha]` | `dim_tiempo[fecha]` |
| 4 | `h_meta[finca_id]` | `dim_finca[finca_id]` |
| 5 | `h_meta[fecha_mes]` | `dim_tiempo[fecha]` |
| 6 | `seguridad[finca_id]` | `dim_finca[finca_id]` |

<br>

La 5 es la única con **nombres distintos** en las dos puntas: ninguna detección automática la habría encontrado. Y **`dim_cultivo` no toca `h_meta`**: la meta no sabe de cultivos (clase 17).

> Si una línea sale `1` → `1` o con dirección **Ambas**, doble clic en la línea y corrígela.

---

# Parte A · El calendario, y la primera captura

1. Selecciona `dim_tiempo` → **Herramientas de tabla → Marcar como tabla de fechas** → `fecha`.
2. Vista **Datos** → `nombre_mes` → **Herramientas de columnas → Ordenar por columna → `mes`**.

<br>

| Sin esto… | …el KPI de la parte C diría |
|---|---|
| `nombre_mes` sin ordenar | **10 800**: el último mes, en orden alfabético, es **Marzo** |
| `dim_tiempo` sin marcar | acumulados que no acumulan |

<br>

> ### 📸 Captura 1 · `clase24-1-modelo.png`
> La **Vista de modelo** completa: **seis tablas y seis líneas**, con el `1` y el `*` a la vista. Acomoda las tablas para que no se encimen.

---

# Parte B · Las siete medidas

**Inicio → Nueva medida**, con `h_cosecha` seleccionada en el panel **Datos**:

```
Kilos = SUM( h_cosecha[kg] )
Meta = SUM( h_meta[kg_meta] )
Cumplimiento = DIVIDE( [Kilos] , [Meta] )
Kilos YTD = TOTALYTD( [Kilos] , dim_tiempo[fecha] )
Meta YTD = TOTALYTD( [Meta] , dim_tiempo[fecha] )
Color cumplimiento = IF( [Cumplimiento] >= 1 , "#1E8449" , "#C0392B" )
Quien mira = USERPRINCIPALNAME()
```

<br>

**Una por una**: cada línea es una medida nueva. Formato: `[Cumplimiento]` en **Porcentaje** con dos decimales; `[Kilos]`, `[Meta]` y los YTD en **Número entero** con separador de miles.

> Son las mismas de las clases 15, 16, 17, 19 y 23. **Ninguna es nueva.**

---

<style scoped>table { font-size: 19px; } p, li { font-size: 23px; }</style>

# Parte B · La tabla que prueba el modelo

Segmentadores: `dim_tiempo[anio]` = **2026** y `dim_tiempo[mes]` en **1, 2, 3 y 4**. **No se mueven en todo el proyecto.**

Tabla con `dim_finca[finca]`, `[Kilos]`, `[Meta]` y `[Cumplimiento]`:

| Finca | `[Kilos]` | `[Meta]` | `[Cumplimiento]` |
|---|---|---|---|
| Agricola La Union | 2 100 | 5 000 | 42,00 % |
| Finca El Guayabo | 14 250 | 9 440 | 150,95 % |
| Hacienda Santa Rosa | 14 200 | 10 000 | 142,00 % |
| **Total** | **30 550** | **24 440** | **125,00 %** |

| Si en vez de eso ves… | te falta la relación |
|---|---|
| `[Meta]` **47 000** y total **65,00 %** | 5 · `h_meta[fecha_mes]` → `dim_tiempo[fecha]` |
| `[Meta]` **24 440** en las tres fincas | 4 · `h_meta[finca_id]` → `dim_finca[finca_id]` |
| `[Kilos]` **77 550** | 3 · `h_cosecha[fecha]` → `dim_tiempo[fecha]` |
| `[Kilos]` **30 550** en las tres fincas | 1 · `h_cosecha[finca_id]` → `dim_finca[finca_id]` |

---

# Parte C · El semáforo y el degradado

**En la tabla por finca:** flechita junto a `Cumplimiento` en el pozo **Columnas** → **Formato condicional → Color de fondo** → **Estilo de formato: Valor del campo** → `[Color cumplimiento]` → **Aplicar a: Valores y totales**.

| Finca | `[Cumplimiento]` | Color |
|---|---|---|
| Agricola La Union | 42,00 % | <span class="rojo">rojo</span> |
| Finca El Guayabo | 150,95 % | <span class="verde">verde</span> |
| Hacienda Santa Rosa | 142,00 % | <span class="verde">verde</span> |
| **Total** | **125,00 %** | <span class="verde">verde</span> |

**Tabla nueva por cultivo:** `dim_cultivo[cultivo]` y `[Kilos]`. En `Kilos`: **Color de fondo → Degradado**, de blanco a verde. Mango 12 700 **el más oscuro**, Cacao 2 100 **en blanco**. Banano y Café no salen: no cosecharon en 2026.

> **Nada de reglas con Porcentaje**: con esa, Santa Rosa sale roja con 142,00 % (clase 23).

---

# Parte C · Los KPI, y la segunda captura

- **Tarjeta** con `[Kilos]`: **30 550**. Otra con `[Cumplimiento]`: **125,00 %**. Otra con `[Quien mira]`: tu cuenta.
- **KPI**: `[Kilos YTD]` en **Valor**, `dim_tiempo[nombre_mes]` en **Eje de tendencia**, `[Meta YTD]` en **Destino**.

| Lo que dibuja el KPI | |
|---|---|
| El número grande | **30 550** |
| El objetivo | **24 440** · **+25,00 %** |

**Formato → General → Título**: uno que diga **qué periodo** enseña, por ejemplo **«Acumulado del año contra meta»**.

> Si el KPI dice **19 750**, pusiste `[Kilos]` y no `[Kilos YTD]`. Si dice **10 800**, `nombre_mes` no está ordenada.

> ### 📸 Captura 2 · `clase24-2-tablero.png`
> El lienzo completo, **sin Ver como**: segmentadores, las tres tarjetas, el KPI con su título y las dos tablas pintadas.

---

# Parte D · Un rol para todos

**Modelado → Administrar roles → Nuevo**. Nómbralo `Por correo`. Tabla **`dim_finca`**, y con **Cambiar al editor DAX**:

```
Rol:       Por correo
Tabla:     dim_finca
Condición: [finca_id] IN
               CALCULATETABLE(
                   VALUES( seguridad[finca_id] ),
                   seguridad[correo] = USERPRINCIPALNAME()
               )
```

<br>

| Si lo pones en… | El gerente de La Unión vería |
|---|---|
| `h_cosecha` | 2 100 kilos contra la meta de todos, **24 440**: **8,59 %** (clase 18) |
| `seguridad` | **30 550** y **125,00 %**: la empresa entera (clase 19) |
| **`dim_finca`** | **2 100** contra **5 000**: **42,00 %** |

> La condición va en la dimensión y **consulta** la tabla de permisos.

---

<style scoped>table { font-size: 19px; } p, li { font-size: 23px; }</style>

# Parte D · Ver como, tres correos

**Modelado → Ver como** → marca **Otro usuario**, escribe el correo **y marca el rol `Por correo`**. Son dos marcas.

| Viendo como… | Filas por finca | `[Kilos]` | `[Meta]` | `[Cumplimiento]` | KPI del año |
|---|---|---|---|---|---|
| gerente.launion@agrodb.test | 1 | 2 100 | 5 000 | **42,00 %** <span class="rojo">rojo</span> | **−58,00 %** |
| regional.norte@agrodb.test | **2** | 16 350 | 14 440 | **113,23 %** <span class="verde">verde</span> | **+13,23 %** |
| practicante@agrodb.test | **0** | *(vacío)* | *(vacío)* | *(vacío)* | *(vacío)* |

Viendo como La Unión, la tabla por cultivo trae **una sola fila**: Cacao, 2 100.

> ### 📸 Capturas 3, 4 y 5
> `clase24-3-gerente.png`, `clase24-4-regional.png` y `clase24-5-practicante.png`: el lienzo completo **con Ver como prendido**, y la tarjeta `[Quien mira]` diciendo **el correo de cada uno**.

---

# Parte E · El alta del practicante

El practicante entra a apoyar en **Hacienda Santa Rosa**. Eso **no se hace en el modelo**:

1. **Quita Ver como.**
2. Abre `C:\agrodb24\seguridad.csv` con el **Bloc de notas** y agrega **al final** la línea:

```
practicante@agrodb.test,1
```

3. Guarda. En Power BI: **Inicio → Actualizar**. **No abras Administrar roles.**
4. **Ver como** `practicante@agrodb.test`, rol `Por correo`:

| Finca | `[Kilos]` | `[Meta]` | `[Cumplimiento]` | KPI del año |
|---|---|---|---|---|
| Hacienda Santa Rosa | 14 200 | 10 000 | **142,00 %** <span class="verde">verde</span> | **+42,00 %** |

> ### 📸 Captura 6 · `clase24-6-alta.png`
> Viendo como el practicante, **después del alta**: una fila, verde.

---

# Antes de entregar: la revisión de los diez

Abre tus seis capturas y revisa, una por una, con el **checklist del ejercicio**:

<br>

| Captura | Puntos del checklist que tiene que probar |
|---|---|
| 1 · modelo | 1 |
| 2 · tablero | 2, 3, 4 y 5 |
| 3 · gerente | 6 |
| 4 · regional | 7 |
| 5 · practicante | 8 |
| 6 · alta | 9 |
| el `.md` | 10 |

<br>

> **Si un número de tu captura no es el del checklist, no lo corrijas en el `.md`**: anótalo tal como salió y di qué crees que pasó. Un número honesto y mal explicado vale más que uno bonito copiado.

---

<style scoped>table { font-size: 19px; } p, li { font-size: 23px; }</style>

# Si algo no cuadra

| Síntoma | Qué pasó | Arreglo |
|---|---|---|
| no deja crear la relación 5 | `fecha_mes` se cargó como texto | tipo **Fecha** en Power Query |
| la relación sale `1` → `1` | la arrastraste entre dos dimensiones, o al revés | bórrala y arrastra del hecho a la dimensión |
| `[Color cumplimiento]` no aparece en Valor del campo | la medida tiene un error, o el color va sin `#` | revisa las comillas y el `#` |
| el total de la tabla no se pinta | **Aplicar a** quedó en solo valores | **Valores y totales** |
| `[Quien mira]` cambia pero no se recorta nada | marcaste Otro usuario **y no el rol** | marca los dos |
| con el rol, **todo** vacío, también con el gerente | el correo va mal escrito | cópialo del CSV |
| agregaste el practicante y sigue vacío | falta **Actualizar**, o editaste el CSV del repositorio | edita el de `C:\agrodb24\` y **Actualizar** |
| el practicante sale en la **misma línea** que `direccion` | el CSV no terminaba en salto de línea | pon la línea nueva en su propio renglón |

---

# Cómo se entrega

En `entregas/apellido-nombre/`, por *pull request*, **siete archivos**:

| Archivo | Qué lleva |
|---|---|
| `Ejercicio24_Apellido_Nombre.md` | el checklist con **lo que salió en tu pantalla**, las siete medidas y el rol en bloques de código, y **una línea por punto** con la trampa que descarta |
| `clase24-1-modelo.png` … `clase24-6-alta.png` | las seis capturas |

<br>

- **El `.pbix` no se entrega**: el repositorio lo ignora a propósito.
- **Tampoco el `seguridad.csv` modificado**: vive en `C:\agrodb24\`, no en el repositorio.

<br>

> **Ábrelo hoy, al terminar**, aunque falte algo: lo que no alcances se anota como `DUDA`. La nota sale de mirar las capturas contra el checklist: **diez puntos, diez segundos cada uno.**

---

<!-- _class: lead -->

# La idea del día

## Un tablero está terminado cuando cada número que enseña se probó contra la trampa que lo haría mentir.

<br>

Hoy no hubo trampa nueva. Estaban **todas las de antes**, esperando en el mismo lienzo: la relación que falta, la regla de Porcentaje, el KPI que enseña abril, el rol en la tabla de permisos. **Cada punto del checklist es un número que solo sale si las esquivaste.**

<br>

**Y viendo como el regional, el tablero tiene que decir 113,23 %, en verde.**
