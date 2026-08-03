#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

CONFIG_FILE="$PROJECT_DIR/configs/backup.conf"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Configuration file not found!"
    exit 1
fi

source "$CONFIG_FILE"

SOURCE_DIR="$PROJECT_DIR/$SOURCE_DIR"
BACKUP_DIR="$PROJECT_DIR/$BACKUP_DIR"
LOG_DIR="$PROJECT_DIR/$LOG_DIR"

if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage:"
    echo "  ./backup.sh [directory]"
    echo
    echo "If no directory is supplied,"
    echo "backup.conf will be used."
    exit 0
fi

if [ $# -ge 1 ]; then
    SOURCE_DIR="$1"
fi

if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: '$SOURCE_DIR' is not a valid directory."
    exit 1
fi

echo "=================================="
echo "		Backup Tool		"
echo "=================================="
echo
echo "Configuration Loaded"
echo "Source Directory : $SOURCE_DIR"
echo "Backup Directory : $BACKUP_DIR"
echo "Log Directory    : $LOG_DIR"
echo "Retention Days   : $RETENTION_DAYS"
mkdir -p "$BACKUP_DIR" "$LOG_DIR"

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

BACKUP_FILE="$BACKUP_DIR/backup_$TIMESTAMP.tar.gz"

LOG_FILE="$LOG_DIR/backup.log"

echo
echo "Backup File: $BACKUP_FILE"
echo
if tar -czf "$BACKUP_FILE" \
    -C "$(dirname "$SOURCE_DIR")" \
    "$(basename "$SOURCE_DIR")"; then
    echo "✓ Backup completed successfully."
    echo "$(date): SUCCESS - Created $BACKUP_FILE from $SOURCE_DIR" >> "$LOG_FILE"
    echo
    echo "Cleaning old backups ...."
    find "$BACKUP_DIR" \
	    -type f \
	    -name "*.tar.gz" \
	    -mtime +"$RETENTION_DAYS" \
	    -print | while read file
do
	echo "Deleting: $file"
	echo "$(date): Deleted $file" >> "$LOG_FILE"
	if rm "$file"; then
	       	echo "Deleted: $file"
	else
		echo "Failed to delete: $file"
	fi
done
exit 0
else
    echo "X Backup Failed!"
    echo "$(date): ERROR - Failed to back up $SOURCE_DIR" >> "$LOG_FILE"
    exit 1
fi
