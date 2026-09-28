# Ejercicio práctico 24 · Mini proyecto: el tablero de la gerencia
## Byron Yaguar Rios

---

## Checklist

| # | Lo que salió en mi pantalla | Qué trampa descarta |
|---|---|---|
| 1 | 6 tablas (`dim_finca`, `dim_cultivo`, `dim_tiempo`, `h_cosecha`, `h_meta`, `seguridad`) y 6 relaciones, todas `*` → `1`, con `h_meta[fecha_mes]` unida a `dim_tiempo[fecha]` | la relación 5 (nombres distintos), que la detección automática no arma sola |
| 2 | Tabla por finca: Agricola La Union 2100/5000/42,00% · Finca El Guayabo 14250/9440/150,95% · Hacienda Santa Rosa 14200/10000/142,00% · Total **30550 / 24440 / 125,00%** | la meta sin fecha (65,00%) o sin finca (24 440 en cada fila) |
| 3 | Semáforo con `[Color cumplimiento]`: La Union **rojo**, El Guayabo **verde**, Santa Rosa **verde**, Total **verde** | la regla con Porcentaje, que pinta a Santa Rosa de rojo aunque cumplió |
| 4 | Tabla por cultivo con degradado: Mango 12 700 (más oscuro), Maiz 9 800, Guayaba 5 950, Cacao 2 100 (blanco) | el color que no se sabe contra qué compara |
| 5 | KPI del año "Acumulado del año contra meta": **30 550** contra **24 440**, **+25,00%**; tarjetas Kilos = 30 550 y Cumplimiento = 125,00% | el KPI que enseña abril (19 750) o marzo (10 800) por `nombre_mes` sin ordenar |
| 6 | Ver como `gerente.launion@agrodb.test`: **una fila** — Agricola La Union 2100/5000/**42,00%** en rojo · cultivo solo Cacao 2100 · KPI **2 100 contra 5 000, −58,00%** | el rol puesto en `h_cosecha` (que da 8,59%) o en `seguridad` (que no filtra nada) |
| 7 | Ver como `regional.norte@agrodb.test`: **dos filas** — El Guayabo 150,95% verde y La Union 42,00% rojo · Total **16 350 / 14 440 / 113,23%** en verde · KPI +13,23% | el `LOOKUPVALUE` que truena con dos fincas — por eso usé `CALCULATETABLE` + `VALUES` + `IN` |
| 8 | Ver como `practicante@agrodb.test` (antes del alta): `[Quien mira]` dice el correo, pero tarjetas, tablas y KPI quedan **en blanco**, sin filas | la puerta abierta: el practicante viendo 30 550 por no tener seguridad configurada |
| 9 | Después de agregar `practicante@agrodb.test,1` a `seguridad.csv` y actualizar: **una fila** — Hacienda Santa Rosa 14200/10000/**142,00%** en verde · KPI **14 200 contra 10 000, +42,00%** | el rol que hay que reabrir para dar un permiso (no lo reabrí, solo edité el CSV) |
| 10 | Este archivo, con el checklist lleno, las medidas, el rol y las respuestas abajo | llegar al número sin saber por qué |

---

## Las siete medidas

```dax
Kilos = SUM( h_cosecha[kg] )
```

```dax
Meta = SUM( h_meta[kg_meta] )
```

```dax
Cumplimiento = DIVIDE( [Kilos] , [Meta] )
```

```dax
Kilos YTD = TOTALYTD( [Kilos] , dim_tiempo[fecha] )
```

```dax
Meta YTD = TOTALYTD( [Meta] , dim_tiempo[fecha] )
```

```dax
Color cumplimiento = IF( [Cumplimiento] >= 1 , "#028800" , "#C1440E" )
```

> Nota: usé colores cálidos propios (`#028800` verde y `#C1440E` terracota) en vez de los sugeridos por el enunciado (`#1E8449` / `#C0392B`), manteniendo la misma lógica IF y la misma familia semántica verde = cumple / rojo = no cumple.

```dax
Quien mira = USERPRINCIPALNAME()
```

---

## El rol

```dax
Rol:       Por correo
Tabla:     dim_finca
Condición: [finca_id] IN
               CALCULATETABLE(
                   VALUES( seguridad[finca_id] ),
                   seguridad[correo] = USERPRINCIPALNAME()
               )
```

---

## Respuestas

### A3a. La relación 5 (`h_meta[fecha_mes]` → `dim_tiempo[fecha]`) es la única con nombres distintos en sus dos puntas. ¿Qué habría pasado con ella si dejabas prendida la detección automática?

Power BI arma relaciones automáticas comparando **nombres de columna iguales** entre tablas. Como `fecha_mes` y `fecha` se llaman distinto, la detección automática **no la habría creado**, dejando `h_meta` sin relacionar con `dim_tiempo`. El resultado habría sido el mismo error de la parte B3: `[Meta]` mostrando 47 000 (el total sin filtrar por mes) sin importar qué meses marcara en el segmentador.

### A3b. ¿Por qué no hay relación entre `dim_cultivo` y `h_meta`?

Porque `h_meta` guarda la meta a nivel de **finca y mes**, no a nivel de cultivo: la tabla no tiene una columna `cultivo_id`. Las metas se fijan por finca, no por tipo de cultivo, así que no existe un campo en común para relacionar esas dos tablas. Por eso la tabla por cultivo solo puede mostrar `[Kilos]` (que sí viene de `h_cosecha`, que sí tiene `cultivo_id`), nunca `[Meta]`.

### D5. Si el rol estuviera en la tabla `seguridad`, ¿qué vería el practicante? ¿Y por qué eso es peor que un error?

Vería **todo**, sin filtrar nada: los 30 550 kilos de las tres fincas. Filtrar la tabla `seguridad` no sirve porque esa tabla está del lado "muchos" de su relación con `dim_finca`; el filtro no se propaga hacia atrás hacia `dim_finca` ni hacia los hechos. Es peor que un error porque **no truena, no avisa nada**: el reporte se ve completamente normal, con números que parecen correctos, y nadie se entera de que la seguridad no está funcionando hasta que alguien nota que vio información que no debía ver.

### E1. Para darle el permiso no abriste el rol. ¿Quién decide entonces lo que ve cada persona, y por qué ese archivo es tan delicado como los kilos?

Quien decide es **quien tenga permiso de editar `seguridad.csv`**, no quien programó el modelo o el rol DAX. El rol (`Por correo`) es una regla fija y genérica; el control real de "quién ve qué" vive en los datos de ese archivo. Por eso `seguridad.csv` es tan delicado como los datos de producción: una fila mal escrita o agregada sin autorización puede abrir el acceso a información financiera y operativa de una finca completa, sin que nadie tenga que tocar el modelo, el rol ni una sola medida.

---

## Entregas

- ✅ `Ejercicio24_Yaguar_Byron.md`
- ✅ `clase24-1-modelo.png`
- ✅ `clase24-2-tablero.png`
- ✅ `clase24-3-gerente.png`
- ✅ `clase24-4-regional.png`
- ✅ `clase24-5-practicante.png`
- ✅ `clase24-6-alta.png`
