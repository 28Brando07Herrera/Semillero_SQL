# Ejercicio 18 · AgroDB

## PARTE A - LA FOTO SIN SEGURIDAD

**A1. Punto de control 1:**

| Finca | `[Kilos]` | `[Cosechas]` | `[Meta]` | `[Filas de meta]` | `[Cumplimiento]` |
|---|---|---|---|---|---|
| Agricola La Union | 2 100 | 2 | 5 000 | 4 | 42,00 % |
| Finca El Guayabo | 14 250 | 3 | 9 440 | 4 | 150,95 % |
| Hacienda Santa Rosa | 14 200 | 4 | 10 000 | 4 | 142,00 % |
| **Total** | **30 550** | **9** | **24 440** | **12** | **125,00 %** |

**A2.** Las columnas `[Meta]`, `[Filas de meta]` y `[Cumplimiento]` contienen información de las otras fincas, al igual que los valores globales de la fila **Total**.

---

## PARTE B - EL ROL OBVIO

### B1 · Rol Gerente La Union (primera versión)

```dax
Tabla:     h_cosecha
Condición: [finca_id] = 3
```
Resultado viendo como Gerente La Union, `[Kilos]`: 2100  

**B2. Punto de control 2:**
  
| Medida | Viendo como Gerente La Union |
|---|---|
| `[Kilos]` | 2 100 |
| `[Cosechas]` | 2 |
| `[Meta]` | 24 440 |
| `[Cumplimiento]` | 8,59 % |

**B3.** Ninguno. Power BI no arroja un error ni advierte si la seguridad RLS está incompleta o mal aplicada en el modelo.  

**B4.** Sí. Al ver únicamente que los Kilos y las Cosechas bajaron exactamente a los valores de La Unión, habría creído erróneamente que la seguridad estaba perfecta.  

**B5.** Se está comparando contra la meta de toda la empresa (24 440 kilos). Ese 8,59 % es el mismo porcentaje erróneo que vimos ayer en la fila del cultivo Cacao, generado por cruzar kilos individuales contra metas globales.  

---

## PARTE C - LA FUGA

**C1. Punto de control 3:**
  
| Finca | `[Kilos]` | `[Cosechas]` | `[Meta]` | `[Filas de meta]` | `[Cumplimiento]` |
|---|---|---|---|---|---|
| Agricola La Union | 2 100 | 2 | 5 000 | 4 | 42,00 % |
| Finca El Guayabo | (vacío) | (vacío) | 9 440 | 4 | (vacío) |
| Hacienda Santa Rosa | (vacío) | (vacío) | 10 000 | 4 | (vacío) |
| Total | 2 100 | 2 | 24 440 | 12 | 8,59 % |

**C2.** Tiene en pantalla los nombres de las otras fincas (Finca El Guayabo, Hacienda Santa Rosa), las metas exactas asignadas a la competencia (9 440 y 10 000 kilos) y sus correspondientes `[Filas de meta]`.  

**C3.** Porque la medida `[Meta]` sí logra calcular un valor válido para ellas. Al no devolver un `BLANK`, la matriz se ve obligada a dibujar las filas completas.  

**C4.** El segmentador ofrece las tres fincas enteras.  

**C5. Punto de control 4:**
  
| Medida | Sin rol | Viendo como Gerente La Union |
|---|---|---|
| `[Cosechas]` | 9 | 2 |
| `[Filas de meta]` | 12 | 12 |

**C6.** Los filtros viajan en la dirección de la flecha: del lado "1" (dimensiones) al lado "Varios" (hechos). Al poner el rol en `h_cosecha`, el filtro muere ahí; no puede viajar "hacia arriba" a `dim_finca` para luego bajar a filtrar `h_meta`.  

**C7.** Regla de detección: Si al aplicar un rol una medida de conteo de filas de otra tabla de hechos (como `[Filas de meta]`) no se altera, el filtro de seguridad no está alcanzando a esa tabla.  

---

## PARTE D - LOS OTROS DOS GERENTES

**D1. Punto de control 5:**
  
| Viendo como… | `[Cumplimiento]` | Lo que debería ver (parte A) |
|---|---|---|
| Gerente La Union | 8,59 % | 42,00 % |
| Gerente El Guayabo | 58,31 % | 150,95 % |
| Gerente Santa Rosa | 58,10 % | 142,00 % |

**D2.** La suma da 125,00. Coincide exactamente con el `[Cumplimiento]` total de la empresa visto sin roles.  

**D3.** Al ver un 58,31 %, el gerente creerá que está muy por debajo de los objetivos e intentará presionar costos u operaciones innecesariamente, cuando en realidad lleva un sobrecumplimiento del 150,95 % sobre su propia meta.  

**D4.** Los `[Kilos]` se suman. Power BI une ambas condiciones (Finca A "O" Finca B), mostrando los datos combinados de las dos fincas.  

---

## PARTE E - EL ROL EN LA DIMENSIÓN

**E1 · Roles en la dimensión**

```dax
Gerente La Union     dim_finca    [finca] = "Agricola La Union"
Gerente El Guayabo   dim_finca    [finca] = "Finca El Guayabo"
Gerente Santa Rosa   dim_finca    [finca] = "Hacienda Santa Rosa"
```

**E2. Punto de control 6:**
  
| Finca | `[Kilos]` | `[Cosechas]` | `[Meta]` | `[Filas de meta]` | `[Cumplimiento]` |
|---|---|---|---|---|---|
| Agricola La Union | 2 100 | 2 | 5 000 | 4 | 42,00 % |
| Total | 2 100 | 2 | 5 000 | 4 | 42,00 % |

**E3.** Me dice que validar únicamente la métrica principal o la tabla de hechos primaria es engañoso; no sirve como prueba definitiva de que todo el modelo está protegido.  

**E4. Punto de control 7:**
  
| Viendo como… | `[Meta]` | `[Filas de meta]` | `[Cumplimiento]` |
|---|---|---|---|
| Gerente La Union | 5 000 | 4 | 42,00 % |
| Gerente El Guayabo | 9 440 | 4 | 150,95 % |
| Gerente Santa Rosa | 10 000 | 4 | 142,00 % |

**E5.** Si el rol está en `dim_finca`, la nueva tabla `h_jornales` quedará protegida instantáneamente (el filtro bajará hacia ella). Si el rol se hubiera quedado en `h_cosecha`, los jornales de todos quedarían totalmente expuestos.  

---

## PARTE F - LO QUE EL ROL NO DEJA VER, TAMPOCO LO VE DAX

**F1 · Participación**

```dax
Participacion = DIVIDE( [Kilos] , CALCULATE( [Kilos] , ALL( dim_finca ) ) )
```

**Punto de control 8 (sin rol):**
  
| Finca | `[Participacion]` sin rol |
|---|---|
| Agricola La Union | 6,87 % |
| Finca El Guayabo | 46,64 % |
| Hacienda Santa Rosa | 46,48 % |
| Total | 100,00 % |

**F2. Punto de control 9 (viendo como Gerente La Union):**
  
| Finca | `[Participacion]` viendo como Gerente La Union |
|---|---|
| Agricola La Union | 100,00 % |
| Total | 100,00 % |

**F3.** Porque el Row-Level Security (RLS) actúa a nivel del motor antes de que DAX comience a evaluar. `ALL` solo puede remover los filtros del entorno visual (como un segmentador), pero no puede recuperar filas que RLS ya le amputó al modelo.  

**F4.** No se puede arreglar únicamente con DAX si el RLS bloquea las filas. La decisión la debe tomar el negocio: determinar si los gerentes tienen permitido ver los agregados globales. De ser así, se requiere una tabla resumen desconectada o exceptuada de la seguridad.  

---

## PARTE G - PREGUNTAS DE CIERRE

*   **¿Dónde se pone un rol?** Los roles de seguridad deben aplicarse en las tablas de Dimensión (el lado "1" de la relación) para garantizar que el filtro fluya hacia abajo y alcance a todas las tablas de hechos conectadas.  
*   **¿Qué tiene de distinto?** En la base de datos, la falta de permisos arroja un error duro y explícito (ORA-00942). En el modelo de Power BI, la seguridad falla de manera silenciosa: simplemente procesa y muestra números erróneos o fugas de información sin avisar.  
*   **¿Qué dos cosas pones en pantalla?** Para probar correctamente un rol, debes poner en pantalla la métrica principal (`[Kilos]`) y una métrica de una tabla de hechos secundaria (`[Meta]` o `[Filas de meta]`). Validar solo con la tabla primaria no sirve.  
*   **¿Es el mismo error o son dos?** Es conceptualmente el mismo error: un filtro de contexto (ayer desde una matriz, hoy desde un RLS) que intenta y falla en propagarse a una tabla porque la dirección de las relaciones del modelo no se lo permite.
*   **¿Qué medida atrapó los dos?** La medida `[Filas de meta]` atrapó ambas trampas al evidenciar que el conteo no se estaba reduciendo conforme al contexto.
