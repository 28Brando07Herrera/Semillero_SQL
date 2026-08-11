# Cómo entregar un ejercicio

Se entrega por *pull request*. La primera vez cuesta diez minutos; después son dos.

## Una sola vez: crear tu fork

1. Botón **Fork** arriba a la derecha. Te queda una copia del repo en tu cuenta.
2. Clonás tu copia (o la editás directo desde la web de GitHub, también vale):
   ```bash
   git clone https://github.com/TU-USUARIO/curso-sql-agrodb.git
   cd curso-sql-agrodb
   ```

## Cada entrega

1. **Rama nueva.** Nunca trabajes sobre `main`:
   ```bash
   git checkout main
   git pull upstream main          # traer lo nuevo del repo del curso
   git checkout -b ejercicio3-perez-juan
   ```

2. **Tu archivo** va en `entregas/apellido-nombre/`:
   ```
   entregas/perez-juan/Ejercicio3_Perez_Juan.sql
   ```
   Sin espacios, sin tildes, sin acentos en el nombre del archivo.

3. **Commit y push:**
   ```bash
   git add entregas/perez-juan/
   git commit -m "Ejercicio 3: normalizacion del registro de campo"
   git push origin ejercicio3-perez-juan
   ```

4. **Pull request** hacia `main` de este repo. Completá la plantilla que aparece sola.

## Qué se revisa

- Que el `.sql` corra **completo, de la primera línea a la última**, después de `datos/agrodb_nucleo.sql`.
- Un solo archivo por entrega, dentro de tu carpeta.
- No toques archivos de otras carpetas. Si tu PR modifica `entregas/otro-alumno/`, algo hiciste mal con las ramas.

## Conectar tu fork con el repo del curso (una vez)

```bash
git remote add upstream https://github.com/USUARIO/curso-sql-agrodb.git
```

Así podés traer las clases nuevas con `git pull upstream main` sin perder tu trabajo.

## Errores frecuentes

| Pasa esto | Es porque | Se arregla |
|---|---|---|
| El PR muestra 40 archivos cambiados | Trabajaste sobre `main` desactualizado | `git pull upstream main` y rama nueva |
| «nothing to commit» | Olvidaste el `git add` | `git add` de tu carpeta |
| El PR toca archivos de otro | Rama creada desde la rama anterior | Volvé a `main` antes de `checkout -b` |
