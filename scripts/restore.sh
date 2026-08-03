#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

CONFIG_FILE="$PROJECT_DIR/configs/backup.conf"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Configuration file not found!"
    exit 1
fi

source "$CONFIG_FILE"

BACKUP_DIR="$PROJECT_DIR/$BACKUP_DIR"
RESTORE_DIR="$PROJECT_DIiR"
LOG_DIR="$PROJECT_DIR/$LOG_DIR"

mkdir -p "$RESTORE_DIR" "$LOG_DIR"

LOG_FILE="$LOG_DIR/restore.log"

echo "Available Backups:"
echo
ls -lh "$BACKUP_DIR"
echo
read -p "Enter backup filename: " BACKUP_NAME
if [ ! -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
	echo
	echo "Backup not found."
	exit 1
fi
echo
echo "Restoring backup..."
if tar -xzf "$BACKUP_DIR/$BACKUP_NAME" -C "$RESTORE_DIR"; then
	echo "Restore Complete!"
	echo "$(date): Restored $BACKUP_NAME" >> "$LOG_FILE"
	echo
	echo "Restarting website..."
	docker stop portfolio-container 2>/dev/null || true
	docker rm portfolio-container 2>/dev/null || true
	cd "$PROJECT_DIR/website"
	docker build -t my-portfolio . || exit 1
	docker run -d \
		--name portfolio-container \
		-p 8080:80 \
		my-portfolio || exit 1
	echo "Website is ONLINE."
	exit 0
else
	echo "Restore Failed"
	echo "$(date): Failed restoring $BACKUP_NAME" >> "$LOG_FILE"
	exit 1
fi

