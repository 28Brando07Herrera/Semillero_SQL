# Ejercicio 24 · Mini proyecto: el tablero de la gerencia

## Checklist

| # | Lo que salió en mi pantalla | Qué trampa descarta |
|---|---|---|
| 1 | 6 tablas, 6 relaciones, todas * a 1 | Evita la relación que falta (clases 14 y 17). |
| 2 | 5 000 / 9 440 / 10 000, total 30 550 / 24 440 / 125,00 % | Evita la meta sin fecha (65,00 %) o sin finca (24 440 en cada fila) (clase 17). |
| 3 | La Union rojo · El Guayabo verde · Santa Rosa verde · total verde | Evita la regla con Porcentaje, que pinta a Santa Rosa de rojo erróneamente (clase 23). |
| 4 | Mango 12 700 el más oscuro, Cacao 2 100 en blanco | Evita el color que no se sabe contra qué compara visualmente (clase 23). |
| 5 | KPI del año 30 550 contra 24 440, +25,00 %, con título | Evita el KPI que enseña solo abril (19 750) o marzo (10 800) ocultando el YTD real (clases 16 y 23)[cite: 17]. |
| 6 | `[Quien mira]` = gerente.launion · una fila: 2 100 / 5 000 / 42,00 % en rojo · KPI −58,00 % | Evita poner el rol directo en `h_cosecha` (8,59 %) o en `seguridad` (125,00 %) (clases 18 y 19)[cite: 17]. |
| 7 | `[Quien mira]` = regional.norte · dos filas · total 16 350 / 14 440 / 113,23 % en verde | Evita el `LOOKUPVALUE` que truena cuando un usuario tiene dos fincas a cargo (clase 19)[cite: 17]. |
| 8 | `[Quien mira]` = practicante · ninguna fila, tarjetas y KPI vacíos | Evita la puerta abierta: el practicante viendo 30 550 sin tener permisos (clase 19)[cite: 17]. |
| 9 | `[Quien mira]` = practicante · una fila: Santa Rosa 14 200 / 10 000 / 142,00 % en verde | Evita tener que reabrir el rol en Power BI para dar un permiso (clase 19)[cite: 17]. |
| 10 | El checklist lleno, las 7 medidas, el rol y las preguntas A3a, A3b, D5 y E1 contestadas | Evita llegar al número sin saber por qué funciona (el aprendizaje conceptual)[cite: 17]. |

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
Color cumplimiento = IF( [Cumplimiento] >= 1 , "#1E8449" , "#C0392B" )

```

```dax
Quien mira = USERPRINCIPALNAME()

```

---

## El rol

```dax
Rol:       Por correo
Tabla:     dim_finca
Condición: 
[finca_id] IN
    CALCULATETABLE(
        VALUES( seguridad[finca_id] ),
        seguridad[correo] = USERPRINCIPALNAME()
    )

```

---

## Preguntas

**A3a.** Power BI no la habría detectado automáticamente por la diferencia en los nombres de las columnas (`fecha_mes` vs `fecha`), dejando la tabla desconectada temporalmente y mostrando una meta global inflada (47 000 kilos).

**A3b.** No hay relación porque el presupuesto (la meta) se definió y capturó a nivel de finca y mes, no a nivel de cultivo; al no existir la columna `cultivo_id` en `h_meta`, no hay forma de relacionarlas lógicamente.

**D5.** El practicante vería la información completa de toda la empresa (30 550 kilos), ya que el filtro moriría en la tabla `seguridad` sin alcanzar a las demás. Esto es peor que un error porque expone silenciosamente datos confidenciales (fuga de información) en vez de bloquear el acceso por defecto.

**E1.** Quien decide lo que ve cada persona es el administrador de los datos al actualizar el archivo `seguridad.csv`. Es un archivo extremadamente delicado porque controla toda la gobernanza y los accesos (RLS) del modelo; cualquier error allí expone la información crítica del negocio.

```

```