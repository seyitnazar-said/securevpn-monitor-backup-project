#!/bin/bash
#
# This script backs up the system and transfers it to the minio object storage server
# Author: Said
# Email: arabovseyitnazar@gmail.com

set -euo pipefail

# variables for backup
BACKUP_DIR="/var/backups"
DATE=$(date +%F)
BACKUP_FILE="system_backup_$DATE.tar.gz"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_FILE"
LOG_FILE="/var/log/backup_minio.log"
MINIO_ALIAS="minio"
MINIO_BUCKET="backup2"

echo "[$(date)] Launching backup..." | tee -a $LOG_FILE

tar --exclude="$BACKUP_DIR" \
    --exclude="/proc" \
    --exclude="/tmp" \
    --exclude="/sys" \
    --exclude="/run" \
    --exclude="/mnt" \
    --exclude="/media" \
    --exclude="/lost+found" \
    -cvpzf "$BACKUP_PATH" /home 2>>$LOG_FILE

echo "[$(date)] Backup finished: $BACKUP_PATH" | tee -a $LOG_FILE

# copy archive file to the minio
mc cp "$BACKUP_PATH" "$MINIO_ALIAS/$MINIO_BUCKET" 2>>"$LOG_FILE"
echo "[$(date)] Backup successfully uploaded: $MINIO_ALIAS/$MINIO_BUCKET/$BACKUP_FILE"

STATUS_FILE="/var/lib/node_exporter/textfile_collector/backup_status.prom"

if [ $? -eq 0 ]; then
    echo "backup_success {job=\"minio_backup\"} 1" > "$STATUS_FILE"
    echo "backup_timestamp_seconds $(date +%s)" >> "$STATUS_FILE"
else
    echo "backup_success {job=\"minio_backup\"} 0" > "$STATUS_FILE"
    echo "backup_timestamp_seconds $(date +%s)" >> "$STATUS_FILE"
fi
