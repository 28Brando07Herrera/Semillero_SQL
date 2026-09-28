# Ejercicio 19 · Herrera Brando

# Parte A · La tabla de permisos

## A1 · Carga y relación

La relación `seguridad[finca_id] → dim_finca[finca_id]` se creó correctamente.

Configuración:

```text
Cardinalidad: Muchos a uno (*:1)
Dirección del filtro cruzado: Único
Estado: Activa
```

---

## A2 · Medidas

### Quien mira

```DAX
Quien mira =
USERPRINCIPALNAME()
```

La medida muestra el usuario que está viendo el informe.

### Filas de seguridad

```DAX
Filas de seguridad =
COUNTROWS(seguridad)
```

Resultado sin filtros:

```text
8
```

---

## A3

| Finca | Kilos | Cosechas | Meta | Filas de seguridad | Cumplimiento |
|---------|---------:|---------:|---------:|---------:|---------:|
| Agricola La Union | 2100 | 2 | 5000 | 3 | 42,00 % |
| Finca El Guayabo | 14250 | 3 | 9440 | 3 | 150,95 % |
| Hacienda Santa Rosa | 14200 | 4 | 10000 | 2 | 142,00 % |
| Total | 30550 | 9 | 24440 | 8 | 125,00 % |

---

## A4

La relación `seguridad[finca_id] → dim_finca[finca_id]` permite que `dim_finca` filtre a `seguridad`. El filtro viaja desde la dimensión hacia la tabla de permisos en una sola dirección.

---

# Parte B · El rol obvio

## B1 · Rol Por correo (primera versión)

```DAX
Tabla: seguridad

[correo] = USERPRINCIPALNAME()
```

Viendo como:

```text
gerente.launion@agrodb.test
```

Resultado:

```text
[Filas de seguridad] = 1
```

---

## B2

| Medida | Resultado |
|---------|---------|
| Quien mira | gerente.launion@agrodb.test |
| Filas de seguridad | 1 |
| Kilos | 30550 |
| Cosechas | 9 |
| Meta | 24440 |
| Cumplimiento | 125,00 % |

---

## B3

Power BI no mostró ningún mensaje de error ni advertencia.

---

## B4

No. Solo demuestra que el rol está filtrando la tabla de permisos, porque la medida Filas de seguridad bajó de 8 a 1.

---

## B5

Además de Quien mira, únicamente cambió Filas de seguridad. Las medidas Kilos, Cosechas, Meta y Cumplimiento permanecieron iguales.

---

# Parte C · La fuga

## C1

| Finca | Kilos | Cosechas | Meta | Filas de seguridad | Cumplimiento |
|---------|---------:|---------:|---------:|---------:|---------:|
| Agricola La Union | 2100 | 2 | 5000 | 1 | 42,00 % |
| Finca El Guayabo | 14250 | 3 | 9440 | (vacío) | 150,95 % |
| Hacienda Santa Rosa | 14200 | 4 | 10000 | (vacío) | 142,00 % |
| Total | 30550 | 9 | 24440 | 1 | 125,00 % |

---

## C2

La única columna que cambió fue Filas de seguridad.

Las columnas Kilos, Cosechas, Meta y Cumplimiento permanecieron iguales, por lo que el rol únicamente protegió la tabla seguridad.

---

## C3

El rol filtra la tabla seguridad.

La relación tiene dirección única desde dim_finca hacia seguridad, por lo que el filtro no puede viajar desde seguridad hacia dim_finca y tampoco llega a h_cosecha ni a h_meta.

---

## C4

Viendo como:

```text
practicante@agrodb.test
```

| Medida | Resultado |
|---------|---------|
| Quien mira | practicante@agrodb.test |
| Filas de seguridad | (vacío) |
| Kilos | 30550 |
| Cumplimiento | 125,00 % |

---

## C5

Con este rol, un usuario que no exista en la tabla de permisos seguiría viendo toda la información de la empresa.

Lo correcto sería que no viera ningún dato hasta que se le asigne un permiso explícitamente.

---

## C6

Si una medida cambia únicamente en la tabla de permisos y el resto de indicadores permanecen iguales, el rol no está llegando a las tablas de hechos que contienen los datos del negocio.

---

# Parte D · El rol en la dimensión, primer intento

## D1 · Rol Por correo (segunda versión)

```DAX
Tabla: dim_finca

[finca_id] =
LOOKUPVALUE(
    seguridad[finca_id],
    seguridad[correo],
    USERPRINCIPALNAME()
)
```

---

## D2

| Usuario | Filas | Kilos | Cumplimiento |
|---------|---------:|---------:|---------:|
| gerente.launion@agrodb.test | 1 | 2100 | 42,00 % |
| gerente.guayabo@agrodb.test | 1 | 14250 | 150,95 % |
| practicante@agrodb.test | 0 | (vacío) | (vacío) |

---

## D3

Mensaje mostrado por Power BI:

```text
Esto puede deberse a un problema de capacidad o licencia.
Póngase en contacto con su administrador si el problema continúa.
```

---

## D4

LOOKUPVALUE espera devolver un único valor.

Como regional.norte@agrodb.test tiene dos filas en la tabla seguridad, existen dos finca_id posibles y la función no sabe cuál devolver, por lo que genera un error.

Sí conviene que falle, porque revela un problema de permisos que debe corregirse antes de publicar el informe.

---

## D5

También genera error porque ese usuario tiene acceso a varias fincas y LOOKUPVALUE solo puede devolver un valor único.

---

# Parte E · El arreglo

## E1 · Rol Por correo (versión final)

```DAX
Tabla: dim_finca

[finca_id] IN
    CALCULATETABLE(
        VALUES(seguridad[finca_id]),
        seguridad[correo] = USERPRINCIPALNAME()
    )
```

---

## E2

| Usuario | Filas | Kilos | Meta | Filas de seguridad | Cumplimiento |
|---------|---------:|---------:|---------:|---------:|---------:|
| gerente.launion@agrodb.test | 1 | 2100 | 5000 | 3 | 42,00 % |
| gerente.guayabo@agrodb.test | 1 | 14250 | 9440 | 3 | 150,95 % |
| gerente.santarosa@agrodb.test | 1 | 14200 | 10000 | 2 | 142,00 % |
| regional.norte@agrodb.test | 2 | 16350 | 14440 | 6 | 113,23 % |
| direccion@agrodb.test | 3 | 30550 | 24440 | 8 | 125,00 % |
