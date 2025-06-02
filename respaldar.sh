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
