# Automatización de backup con Rclone y Google Drive

Este proyecto trata sobre cómo configurar un sistema **de respaldo semanal automático** de una carpeta local (`~/Documentos/misArchivos`) hacia Google Drive (`/misArchivos-backup`), usando [`Rclone`](https://github.com/rclone/rclone) en Linux (base Debian).

Una solución estable y automática que protege tu información con un segundo respaldo seguro en la nube, excluyendo archivos no relevantes, con control de conexión y registros de actividad.

---

## Objetivo

- Automatizar un **backup semanal** de archivos personales locales a la nube.
- Proteger los archivos contra pérdida de datos por fallos físicos, errores humanos o ransomware.
- Disponer fácilmente de los archivos respaldados desde Google Drive.
- Evitar olvidarse de respaldar archivos.
- Subir **solo archivos nuevos o modificados** (backup incremental).
- (útil para mi caso) **Excluir archivos binarios** (`*.bin`) generados al compilar código.
- Mantener la **privacidad**: sin sincronización inversa ni borrado, solo se suben archivos, no se modifica la carpeta local.
- Evitar y manejar errores en caso de no haber conexión a Internet a la hora del respaldo.

---

## Herramientas utilizadas

- `rclone`: para transferencias entre el sistema local y Google Drive.
- [`cron`](https://ftp.isc.org/isc/cron/): para automatizar la tarea de ejecución semanal.
- `Bash` para el script de respaldo.

---

## Pasos de implementación

### 1. Instalar `rclone`

```bash
sudo apt install rclone
```

---

### 2. Configurar la conexión con Google Drive

```bash
rclone config
```

1. Seleccioná `n` (new remote)
2. Nombre: `googleDrive`
3. Tipo: `drive`

- (Las demás opciones avanzadas dejalas por defecto apretando enter.)

4. Seguí el proceso de autenticación en el navegador (debería redirigirte, sino copia y pega el link que te da)
5. Verificá que se hizo la conexión con:

   ```bash
   rclone listremotes
   ```

---

### 3. Crear carpeta `misArchivos-backup` en Google Drive

Desde la web de Google Drive: crea la carpeta `misArchivos-backup`. En todo caso si ya tenes una carpeta creada te recomiendo duplicarla y probar el funcionamiento del respaldo sobre esa carpeta, antes de modificar sobre la carpeta original en la nube.

Si querés, podes duplicar la carpeta con el siguiente comando:

```bash
rclone copy googleDrive:misArchivos googleDrive:misArchivos-backup --update --progress
```

---

### 4. Crear archivo de exclusión

Para mi caso es útil ignorar binarios, pero esto puede aplicarse a otros tipos de archivos

```bash
mkdir -p ~/.config/rclone
nano ~/.config/rclone/rclone-exclude.txt
```

Contenido:

```
*.bin
```

- Guardar con Ctrl+O
- Salir con Ctrl+X

---

## Prueba manual

Antes de confiar en la automatización probá ejecutar un sólo respaldo manualmente para ver el funcionamiento:

```bash
rclone copy /home/tu_usuario/Documentos/misArchivos googleDrive:misArchivos-backup \
  --update \
  --copy-links \
  --exclude-from=/home/tu_usuario/.config/rclone/rclone-exclude.txt \
  --log-file=/home/tu_usuario/rclone-respaldos.log \
  --log-level INFO
```

Verificá los archivos en tu Google Drive y que el log esté creado. Podés ver los errores en el mismo.

---

### 5. Crear script para realizar el respaldo

Aqui también manejaremos la posibilidad de que cuando se quiera hacer el respaldo no haya internet.

```bash
nano ~/.config/rclone/respaldar.sh
```

Contenido:

```bash
#!/bin/bash

# Verificar conexión a Internet
ping -c 2 8.8.8.8 > /dev/null 2>&1
if [ $? -eq 0 ]; then
    rclone copy /home/tu_usuario/Documentos/misArchivos googleDrive:misArchivos-backup \
        --update \
        --copy-links \
        --exclude-from=/home/tu_usuario/.config/rclone/rclone-exclude.txt \
        --log-file=/home/tu_usuario/rclone-respaldos.log \
        --log-level INFO
else
    echo "Sin conexión a Internet - $(date)" >> /home/tu_usuario/rclone-respaldos.log
fi
```

Reemplazar `tu_usuario` por tu nombre de usuario real, y `/home/tu_usuario/Documentos/misArchivos` por la ruta de tu carpeta local de archivos personales.

En caso de haber error de conexión, se registrará en el archivo de logs.

---

## Explicación de cada parámetro o flag del script

| Flag                 | ¿Qué hace?                                                                                                                               |
| -------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| `--update`           | **Solo sube archivos nuevos o modificados** (no sobrescribe innecesariamente)                                                            |
| `--copy-links`       | Si encuentra **accesos directos** en tu carpeta local, copia el archivo apuntado, no el enlace en sí.                                    |
| `--exclude-from=...` | Omite los archivos o carpetas listados en el archivo de exclusión                                                                        |
| `--log-file=...`     | Guarda la salida del comando (mensajes, errores, avisos) en un **archivo de log**.                                                       |
| `--log-level INFO`   | Establece el **nivel de detalle del log**. Muestra: archivos copiados, ignorados, errores comunes (No muestra mensajes super detallados) |

---

Hacerlo ejecutable:

```bash
chmod +x ~/.config/rclone/respaldar.sh
```

---

### 6. Agregar tarea cron

```bash
crontab -e
```

Agregar al final la siguiente línea:

```
0 22 * * 5 /home/tu_usuario/.config/rclone/respaldar.sh
```

Esto ejecuta el script todos los **viernes a las 22:00**. Podés personalizarlo para el día y hora que quieras.

---

## Cómo desactivar el respaldo

- Eliminar la tarea programada:

```bash
crontab -e
```

Y borrar la línea del respaldo.

- Eliminar los archivos creados:

```bash
rm ~/.config/rclone/respaldar.sh
rm ~/.config/rclone/rclone-exclude.txt
rm ~/rclone-respaldos.log
```

---

## Posibles errores que puedan surgir

| Problema                             | Solución                                                             |
| ------------------------------------ | -------------------------------------------------------------------- |
| `didn't find section in config file` | El remote no existe o el nombre es incorrecto                        |
| Sin conexión a Internet              | El script lo detecta y escribe en el log                             |
| Archivos `.bin` subidos por error    | Verificar contenido de `rclone-exclude.txt`                          |
| Drive no muestra cambios             | Verificá que estés mirando en `misArchivos-backup`, no `misArchivos` |

---

## Posibles errores y cómo resolverlos

| Causa del error                                                                                            | Síntoma                                      | Solución                                               |
| ---------------------------------------------------------------------------------------------------------- | -------------------------------------------- | ------------------------------------------------------ |
| **"Attempt X/X failed with errors and: can't update google document type without --drive-import-formats"** | Error al intentar actualizar un archivo con formato de Google Drive (ver log) | Ignorar el error, no afecta en nada.                    |
| **Token de Google vencido**                                                                                | Error de autenticación                       | Reconfigurar `rclone` con `rclone config`              |
| **Ruta mal escrita**                                                                                       | Archivos no se copian                        | Verificar rutas locales y remotas                      |
| **Permisos insuficientes**                                                                                 | Algunos archivos no se respaldan             | Asegurarse de que el usuario tenga permisos de lectura |
| **Usar `sync` en lugar de `copy`**                                                                         | Posible borrado de archivos en Drive         | Usar `copy` con `--update` y no `sync`                 |
| **Cambios en la API de Google**                                                                            | Falla inesperada                             | Actualizar `rclone` a la última versión                |

---

## Privacidad

- Rclone **no permite acceso de Google a tus archivos locales**.
- Solo se suben archivos de la carpeta especificada.
- Tus credenciales (token de autenticación) se almacenan localmente en `~/.config/rclone/rclone.conf` y solo se acceden con root.
- No hay sincronización inversa desde Drive.

---

## Extras útiles

- Ver logs:

```bash
cat ~/rclone-respaldos.log
```

- Ver archivos remotos:

```bash
rclone ls googleDrive:misArchivos-backup
```

---
