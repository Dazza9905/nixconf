#!/usr/bin/env bash
set -euo pipefail
umask 077

BACKUP_ROOT="${BACKUP_ROOT:-/mnt/860evo}"
B2_REMOTE="bb-b2:dazza9905-nas-data"

# Run as root with RCLONE_CONFIG pointing to your existing rclone config.
# Add --dry-run to preview transfers/deletions without changing Backblaze.
DRY_RUN=false
RCLONE_FLAGS=()
if [[ $# == 1 && $1 == "--dry-run" ]]; then
    DRY_RUN=true
    RCLONE_FLAGS=(--dry-run)
elif [[ $# != 0 ]]; then
    echo "Usage: backup-files [--dry-run]" >&2
    exit 2
fi

############################################
# 1. Check the disk and source folders
############################################
if [[ $EUID != 0 ]]; then
    echo "Please run as root." >&2
    exit 1
fi

: "${RCLONE_CONFIG:?Set RCLONE_CONFIG to your existing rclone config}"
if [[ ! -s "$RCLONE_CONFIG" || ! -r "$RCLONE_CONFIG" ]]; then
    echo "Cannot read rclone config: $RCLONE_CONFIG (missing, empty, or unreadable)." >&2
    echo "Restore your existing config and set homelab.services.backup.rcloneConfig to its path." >&2
    echo "For a manual run: sudo RCLONE_CONFIG=/path/to/rclone.conf backup-files --dry-run" >&2
    exit 1
fi

if ! mountpoint -q "$BACKUP_ROOT"; then
    echo "NAS disk is not mounted. Refusing to sync." >&2
    exit 1
fi
if [[ $(findmnt -nro UUID --target "$BACKUP_ROOT") != "449c6c1f-0f80-4e17-b5e2-00c40a6e8151" ]]; then
    echo "Wrong disk is mounted. Refusing to sync." >&2
    exit 1
fi
if [[ ! -d "$BACKUP_ROOT/files-dazza" || ! -d "$BACKUP_ROOT/files-patrik" ]]; then
    echo "A source folder is missing. Refusing to sync." >&2
    exit 1
fi

# Both backup scripts use this lock so they cannot run at the same time.
exec 9>/run/lock/maddie-b2-backup.lock
flock -n 9 || { echo "Another backup is running." >&2; exit 1; }

############################################
# 2. Back up Dazza's files
############################################
echo "Syncing files-dazza..."
rclone sync "$BACKUP_ROOT/files-dazza" "$B2_REMOTE/files-dazza" \
    --config "$RCLONE_CONFIG" \
    --backup-dir "$B2_REMOTE/files-deleted/files-dazza" \
    --transfers 32 \
    --checkers 32 \
    --fast-list \
    --b2-chunk-size 64M \
    --b2-upload-cutoff 64M \
    --progress \
    "${RCLONE_FLAGS[@]}"

############################################
# 3. Back up Patrik's files
############################################
echo "Syncing files-patrik..."
rclone sync "$BACKUP_ROOT/files-patrik" "$B2_REMOTE/files-patrik" \
    --config "$RCLONE_CONFIG" \
    --backup-dir "$B2_REMOTE/files-deleted/files-patrik" \
    --transfers 32 \
    --checkers 32 \
    --fast-list \
    --b2-chunk-size 64M \
    --b2-upload-cutoff 64M \
    --buffer-size 64M \
    --progress \
    "${RCLONE_FLAGS[@]}"

if $DRY_RUN; then
    echo "Dry run complete. No files uploaded, moved, or deleted."
else
    echo "Files backup complete!"
fi
