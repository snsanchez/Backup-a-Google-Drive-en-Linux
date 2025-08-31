# Sincronizacion bidireccional a Google Drive con Rclone en Linux

Este proyecto explica cómo configurar un sistema de **respaldo automático + manual** de una carpeta local (`~/Documentos/misArchivos`) hacia Google Drive (`/misArchivos-backup`), usando [`Rclone`](https://github.com/rclone/rclone) en Linux (base Debian).


Es una solución confiable que te permite:

- Proteger tu información con un **backup seguro** en la nube.

- Tener una **sincronización bidireccional sin sobreescribir archivos**.  

- Subir **solo archivos nuevos o modificados**.

- Ejecutar **manualmente** el respaldo desde un **acceso directo en el escritorio**.

- **Configurable para que corra automáticamente** todos los días a la hora que quieras (por si te olvidas de backupear).

- Ver **notificaciones en el escritorio** con el estado del respaldo.

- Se abre en una terminal para que puedas **monitorear en vivo el proceso** y **poder abortarlo si hace falta**.

- Podes **excluir tipos de archivos**.

- **Registro/Historial de actividad** en un log.

---

## Objetivo

- Automatizar un **backup** de archivos personales locales a la nube.
- Proteger tus archivos contra pérdida de datos por fallos de sistema o **ransomware**.
- Permitirte trabajar offline en tu PC o notebook y luego sincronizar todo cuando vuelvas a tener conexión.
- Evitar olvidarte de respaldar archivos.
- Subir **solo archivos nuevos o modificados** (backup incremental).
- (útil para mi caso) **Excluir archivos binarios** (`*.bin`) generados al compilar código.
- Mantener la **privacidad**.
- **Evitar sobreescribir archivos**.
- Tener varios dispositivos apuntando a la misma nube y garantizar que todos ven los mismos archivos actualizados.

---

## Herramientas utilizadas

- `rclone`: para transferencias de archivos entre tu carpeta local y Google Drive.
- [`cron`](https://ftp.isc.org/isc/cron/): para automatizar el backup.
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

4. Seguí el proceso de autenticación en el navegador (debería redirigirte, sino copiá y pegá el link que te da)
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

```bash
mkdir -p ~/.config/rclone
nano ~/.config/rclone/rclone-exclude.txt
```

Contenido: en el archivo `rclone-exclude.txt` te dejé muchas exclusiones sobre tipos de datos que suelen ser malware, como los .py o .exe. De esta forma te aseguras no propagar virus al momento de respaldar de local hacia nube o viceversa. 

```
*.py
*.exe
```

- Guardar con Ctrl+O
- Salir con Ctrl+X

---

### 5. Crear script para realizar el respaldo

Como se busca no sobreescribir archivos, por ello no se usa la opcion `rclone sync`, lo que hace es primero bajar a tu carpeta local los archivos nuevos o modificados en drive (drive --> tu carpeta local). Luego, hace lo mismo pero de forma inversa (tu carpeta local --> drive). De esta forma logramos una **sincronización bidireccional sin sobreescribir archivos**. 

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

| Flag                                    | Descripción                                                                                                    |
| --------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| `--update`                              | Copia solo si el archivo de origen es más nuevo que el de destino (evita sobrescribir con versiones antiguas). |
| `--copy-links`                          | Si encuentra enlaces simbólicos, copia el archivo al que apuntan en lugar del link.                            |
| `--create-empty-src-dirs`               | Mantiene la estructura de directorios aunque estén vacíos.                                                     |
| `--exclude-from="$EXCLUDE_FILE"`        | Excluye los archivos/carpetas listados en el archivo indicado.                                                 |
| `--drive-import-formats docx,xlsx,pptx` | Si subís archivos de esos formatos, Google los convierte a Google Docs/Sheets/Slides automáticamente (evita errores).          |
| `--progress`                            | Muestra el progreso en la terminal en tiempo real.                                                             |
| `--log-file="$LOG_FILE"`                | Guarda un registro de la ejecución en el archivo de log.                                                       |
| `--log-level INFO`                      | Define el nivel de detalle de los logs (INFO es balanceado entre detalle y brevedad).                          |


---


Dale permisos para hacerlo ejecutable:

```bash
chmod +x ~/.config/rclone/respaldar.sh
```

---

### 6. Crear acceso directo en el escritorio

```ini
[Desktop Entry]
Type=Application
Name=Respaldar Ahora
Comment=Ejecutar respaldo de mi carpeta /uni a Google Drive
Exec=gnome-terminal -- bash -c "/home/santu/.config/rclone/respaldar.sh"
Icon=utilities-terminal
Terminal=false
```

Dale permisos para hacerlo ejecutable:

```bash
chmod +x ~/Escritorio/respaldar.desktop
```

---

### 7. Agregar automatización para el backup diario con Cron

```bash
crontab -e
```

Agregar al final la siguiente línea:

```
0 23 * * * /home/tu_usuario/.config/rclone/respaldar.sh
```

Esto ejecuta el script **todos los días a las 23:00**. Podés personalizarlo para el día y hora que quieras.

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

| Causa del error                                                                                            | Síntoma                                                                      | Solución                                                         |
| ---------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| **"Attempt X/X failed with errors and: can't update google document type without --drive-import-formats"** | Error al intentar copiar/actualizar archivos de Google Docs, Sheets o Slides | Ignorar el error, no afecta al respaldo.                         |
| **Token de Google vencido**                                                                                | Error de autenticación                                                       | Reconfigurar `rclone` con `rclone config`                        |
| **Ruta mal escrita**                                                                                       | Archivos no se copian                                                        | Verificar que las rutas locales y remotas estén bien             |
| **Permisos insuficientes**                                                                                 | Algunos archivos no se respaldan                                             | Asegurarse de que el usuario tenga permisos de lectura/escritura |
| **Usar `sync` en lugar de `copy`**                                                                         | Posible borrado de archivos en Drive                                         | Usar siempre `copy` con `--update`, no `sync`                    |
| **Cambios en la API de Google**                                                                            | Falla inesperada                                                             | Actualizar `rclone` a la última versión                          |

---

## Privacidad

- Rclone **no permite acceso de Google a tus archivos locales**.
- Solo se suben archivos de la carpeta especificada.
- Tus credenciales (token de autenticación) se almacenan localmente en `~/.config/rclone/rclone.conf` y solo se acceden con root.
- El script hace copia en ambos sentidos (Drive → local y local → Drive), pero nunca elimina archivos.

---

## Extras útiles

- Ver logs:

```bash
cat ~/rclone-respaldos.log
```

- Listar archivos remotos:

```bash
rclone ls googleDrive:misArchivos-backup
```

- Probar conexión y configuración de rclone:

```bash
rclone lsd googleDrive:
```

---
