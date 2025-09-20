#!/bin/bash
#
# This script backs up the system and transfers it to the minio object storage server
# Author: Said
# Email: arabovseyitnazar@gmail.com

set -euo pipefail

# variables for minio
read -p "Enter MinIO alias name (e.g. minio): " MINIO_ALIAS
read -p "Enter MinIO URL (e.g. http://127.0.0.1:9000): " MINIO_URL
read -p "Enter MinIO Access key: " MINIO_ACCESS_KEY
read -s -p "Enter MinIO Secret key: " MINIO_SECRET_KEY
echo ""
mc alias set "$MINIO_ALIAS" "$MINIO_URL" "$MINIO_ACCESS_KEY" "$MINIO_SECRET_KEY"

read -p "Enter MinIO bucket name (e.g. backup): " MINIO_BUCKET
mc mb "$MINIO_ALIAS/$MINIO_BUCKET"

# variables for backup
BACKUP_DIR="/var/backups"
DATE=$(date +%F)
BACKUP_FILE="system_backup_$DATE.tar.gz"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_FILE"
LOG_FILE="/var/log/backup_minio.log"

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
