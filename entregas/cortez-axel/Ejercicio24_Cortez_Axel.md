# Ejercicio 24 · Mini proyecto: el tablero de la gerencia

- **Alumno:** Cortez Cardozo Axel Josue
- **Ejercicio / proyecto:** Ejercicio 24 · Miniproyecto integrador de modelado, DAX, semaforización y RLS
- **Archivo:** `entregas/cortez-axel/Ejercicio24_Cortez_Axel.md`

---

## Checklist

| # | Lo que salió en mi pantalla | Qué trampa descarta |
|---|---|---|
| 1 | 6 tablas, 6 relaciones, todas * a 1, h_meta[fecha_mes] unida a dim_tiempo[fecha] | Relaciones faltantes o invertidas en el modelo estrella |
| 2 | La Union 5 000, El Guayabo 9 440, Santa Rosa 10 000, Total 30 550 / 24 440 / 125,00 % | Metas huérfanas sin filtro de calendario o sin propagación de finca |
| 3 | La Union en rojo, El Guayabo en verde, Santa Rosa en verde, Total en verde | Regla visual relativa por Porcentaje que pinta a Santa Rosa en rojo |
| 4 | Mango 12 700 (oscuro), Maiz 9 800, Guayaba 5 950, Cacao 2 100 (blanco) | Degradado erróneo sin valores base o descalibrado en límites |
| 5 | KPI del año 30 550 contra 24 440 (+25,00 %) con título; tarjetas 30 550 y 125,00 % | KPI mostrando solo abril (19 750) o marzo por desorden alfabético |
| 6 | gerente.launion: 1 finca, 2 100 / 5 000 / 42,00 % rojo, KPI −58,00 %, cultivo Cacao | Rol aplicado en tabla de hechos o en seguridad sin filtrar dimensiones |
| 7 | regional.norte: 2 fincas, total 16 350 / 14 440 / 113,23 % verde, KPI +13,23 % | LOOKUPVALUE rompiéndose al encontrar múltiples fincas asociadas |
| 8 | practicante (antes): tablas sin filas, tarjetas y KPI en blanco | Puerta abierta donde usuarios sin privilegios ven el total general |
| 9 | practicante (después): Santa Rosa 14 200 / 10 000 / 142,00 % verde, KPI +42,00 % | Modificar manualmente el modelo o código DAX para otorgar permisos |
| 10 | Reporte completo con código, respuestas conceptuales y 6 capturas validadas | Llegar a los resultados por azar sin entender el motor tabular |

---

## Preguntas de la Parte A

### A3a. Nombres distintos en relación 5
Si se dejaba la detección automática, Power BI no habría creado la relación entre `h_meta[fecha_mes]` y `dim_tiempo[fecha]` porque busca coincidencias exactas en el nombre de columna; la meta habría quedado desvinculada del tiempo mostrando 47 000 y 65,00 % en el total.

### A3b. Ausencia de relación entre dim_cultivo y h_meta
Porque las metas del negocio están definidas únicamente a nivel de finca y mes, no desglosadas por cada tipo de cultivo; relacionarlas crearía una relación artificial inválida.

---

## Medidas del modelo

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

## Rol de Seguridad Dinámica (RLS)

- **Nombre del rol:** `Por correo`
- **Tabla filtrada:** `dim_finca`

```dax
[finca_id] IN
    CALCULATETABLE(
        VALUES( seguridad[finca_id] ),
        seguridad[correo] = USERPRINCIPALNAME()
    )
```

---

## Preguntas de las Partes D y E

### D5. ¿Qué pasaría si el rol se aplicara sobre la tabla `seguridad`?
Si el rol filtrara directamente `seguridad`, la tabla `seguridad` quedaría vacía para el practicante pero `dim_finca` no recibiría ningún filtro; el practicante vería toda la empresa (30 550 kg), lo cual es una brecha de seguridad grave e invisible sin mensaje de error.

### E1. Gobernanza y administración de permisos
Quien decide los accesos es el administrador de los datos maestros o el área de seguridad que gestiona el CSV o repositorio central; es un archivo crítico porque controla la confidencialidad de la información sin requerir redespliegues técnicos del archivo `.pbix`.