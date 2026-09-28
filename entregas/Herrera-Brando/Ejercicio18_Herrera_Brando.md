# Ejercicio 18 · Herrera Brando

# Parte A · La foto sin seguridad

## A1

| Finca | Kilos | Cosechas | Meta | Filas de meta | Cumplimiento |
|---|---:|---:|---:|---:|---:|
| Agricola La Union | 2100 | 2 | 5000 | 4 | 42,00 % |
| Finca El Guayabo | 14250 | 3 | 9440 | 4 | 150,95 % |
| Hacienda Santa Rosa | 14200 | 4 | 10000 | 4 | 142,00 % |
| Total | 30550 | 9 | 24440 | 12 | 125,00 % |

---

## A2

Las columnas Kilos, Cosechas, Meta, Filas de meta y Cumplimiento contienen información de las demás fincas, por lo que actualmente cualquier usuario puede verla.

---

# Parte B · El rol obvio

## B1 · Rol Gerente La Union (primera versión)

```dax
Tabla: h_cosecha

[finca_id] = 3