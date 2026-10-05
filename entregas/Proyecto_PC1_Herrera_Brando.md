# Proyecto PC1 – El Inventario

**Estudiante:** Brando Herrera

---

# Anclas del lunes

| Concepto | Resultado |
|-----------|-----------:|
| dim_finca | 4 |
| dim_cultivo | 6 |
| dim_tiempo | 730 |
| seguridad | 10 |
| Archivos en carpeta bascula | 19 |

---

# 1.1 Tabla de fuentes

| Fuente | Filas | Columnas | Llave | Tabla destino |
|----------|----------:|----------:|----------|----------|
| dim_finca.csv | 4 | 3 | finca_id | Dimensión |
| dim_cultivo.csv | 6 | 4 | cultivo_id | Dimensión |
| dim_tiempo.csv | 730 | 6 | fecha | Dimensión |
| seguridad.csv | 10 | 2 | correo + finca_id | Seguridad |
| metas_planeacion.csv | 5 | 15 | finca_id + fecha_mes | h_meta |
| bascula (carpeta) | 43 cosechas | 7 | cosecha_id | h_cosecha |
| bascula_digital_2026.csv | 10 | 7 | cosecha_id | h_cosecha |
| precios.csv | Pendiente de carga | cultivo_id + calidad | precios |
| h_cosecha | Se construirá | cosecha_id | Hechos |
| h_meta | Se construirá | finca_id + fecha_mes | Hechos |

---

# 1.2 Lo que veo raro

### Hallazgo 1

**Archivo:** dim_finca.csv

**Observación:** Aparece una nueva finca denominada **Hacienda Los Ceibos**.

**Impacto esperado:** Incrementará los kilos cosechados, ingresos y metas del año 2026.

---

### Hallazgo 2

**Archivo:** dim_cultivo.csv

**Observación:** El cultivo Café no posee valor en la columna variedad.

**Impacto esperado:** Puede afectar segmentaciones o análisis por variedad.

---

### Hallazgo 3

**Archivo:** seguridad.csv

**Observación:** Existe un usuario con acceso a más de una finca.

**Impacto esperado:** Los resultados del tablero cambiarán dependiendo del usuario que consulte la información.

---

### Hallazgo 4

**Archivo:** metas_planeacion.csv

**Observación:** Hacienda Los Ceibos posee una meta anual de 52.000 kg, convirtiéndose en la finca con mayor participación dentro de la planificación anual.

**Impacto esperado:** Tendrá un peso significativo en los indicadores de cumplimiento.

---

### Hallazgo 5

**Archivo:** bascula_2025-08.csv

**Observación:** La columna de kilos aparece como `kg_neto` en lugar de `kg`.

**Impacto esperado:** Puede provocar valores nulos al combinar los archivos y disminuir los indicadores de kilos, ingresos y cumplimiento si no se corrige.

---

### Hallazgo 6

**Archivo:** bascula_2026-03 - copia.csv

**Observación:** Existe una copia de un archivo dentro de la carpeta de la báscula.

**Impacto esperado:** Podría duplicar cosechas, kilos e ingresos al momento de combinar los archivos.

---

# Preguntas ciegas

## L1

**¿Cuántas cosechas distintas hay en total, sumando la carpeta bascula y bascula_digital_2026?**

```text
53 cosechas distintas
```

La carpeta **bascula** contiene las cosechas 1 a 43 y el archivo **bascula_digital_2026.csv** contiene las cosechas 44 a 53.

---

## L2

**¿Cuánto es la meta total de la empresa para 2026 y dónde fue obtenida?**

```text
110.000 kg
```

La información fue obtenida de **metas_planeacion.csv**, en la fila **Total** y la columna **Total**.

---

## L3

**¿Qué correo tiene acceso a más de una finca sin tener acceso a todas?**

```text
regional.sur@agrodb.test
```

Fincas asignadas:

- Agrícola La Unión
- Hacienda Los Ceibos

No posee acceso a todas las fincas de la empresa.

---

# Bitácora del día

| Qué encontré | Cómo me di cuenta | Qué número podría afectar | Cómo pienso corregirlo | Cómo verificaré la solución |
|-------------|------------------|--------------------------|------------------------|-----------------------------|
| Nueva finca Hacienda Los Ceibos | Revisión de dim_finca.csv | Kilos, ingresos y metas | Incorporar correctamente la nueva dimensión en el modelo | Comparar totales por finca |
| Café sin variedad | Revisión de dim_cultivo.csv | Segmentaciones por variedad | Validar necesidad de completar o mantener el valor vacío | Revisar filtros y visualizaciones |
| Usuario con más de una finca | Revisión de seguridad.csv | Seguridad a nivel de fila | Considerar el diseño del rol dinámico | Pruebas con “Ver como” |
| Meta anual elevada para Los Ceibos | Revisión de metas_planeacion.csv | Cumplimiento global | Validar la carga correcta de metas | Comparar meta total de 110.000 kg |
| Columna kg_neto | Revisión de bascula_2025-08.csv | Kilos e ingresos | Renombrar encabezado durante Power Query | Verificar que no existan valores nulos |
| Archivo duplicado de marzo | Revisión de archivos de la carpeta bascula | Cosechas, kilos e ingresos | Filtrar archivo copia durante la importación | Validar cosechas repetidas en cero |

---

# Evidencia

**Captura adjunta:**

```text
proyecto-pc1-modelo.png
```

La captura muestra:

- dim_finca
- dim_cultivo
- dim_tiempo
- seguridad
- Relación seguridad[finca_id] → dim_finca[finca_id]
- Calendario configurado como tabla de fechas