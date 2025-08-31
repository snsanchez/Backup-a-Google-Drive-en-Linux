#!/bin/bash

# === Variables ===
REMOTE="googleDrive:misArchivos-backup"
LOCAL="$HOME/Documentos/misArchivos"
EXCLUDE_FILE="$HOME/.config/rclone/rclone-exclude.txt"
LOG_FILE="$HOME/rclone-respaldos.log"

# === Limpiar log anterior ===
> "$LOG_FILE"

# === Función para enviar notificaciones ===
enviar_notificacion() {
    if command -v notify-send &> /dev/null; then
        notify-send -t 8000 "Backup Google Drive" "$1"
    fi
}

# === Verificar conexión a Internet ===
ping -c 2 8.8.8.8 > /dev/null 2>&1
if [ $? -ne 0 ]; then
    MENSAJE="Sin conexión a Internet - $(date '+%d/%m/%Y %H:%M:%S')"
    echo "$MENSAJE" >> "$LOG_FILE"
    enviar_notificacion "$MENSAJE"
    exit 1
fi

# === Paso 1: Copy desde Drive a local ===
echo "Iniciando descarga desde Drive..."
if rclone copy "$REMOTE" "$LOCAL" \
    --update \
    --copy-links \
    --create-empty-src-dirs \
    --exclude-from="$EXCLUDE_FILE" \
    --drive-import-formats docx,xlsx,pptx \
    --progress \
    --log-file="$LOG_FILE" \
    --log-level INFO; then
    echo "Descarga desde Drive completada" >> "$LOG_FILE"
else
    enviar_notificacion "Error al descargar desde Drive. Revisar log."
    exit 1
fi

# === Paso 2: Copy desde local a Drive ===
echo "Iniciando subida desde local a Drive..."
if rclone copy "$LOCAL" "$REMOTE" \
    --update \
    --copy-links \
    --create-empty-src-dirs \
    --exclude-from="$EXCLUDE_FILE" \
    --drive-import-formats docx,xlsx,pptx \
    --progress \
    --log-file="$LOG_FILE" \
    --log-level INFO; then
    enviar_notificacion "Respaldo completado correctamente: $(date '+%d/%m/%Y %H:%M:%S')"
else
    enviar_notificacion "Error al subir a Drive. Revisar log."
    exit 1
fi

# === Esperar 5 segundos antes de cerrar ===
echo "Respaldo completado. Cerrando terminal en 5 segundos..."
sleep 5

# === Cerrar la terminal ===
exit 0
