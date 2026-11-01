#!/usr/bin/env bash
set -euo pipefail
umask 077

BACKUP_ROOT="${BACKUP_ROOT:-/mnt/860evo}"
MEDIA_DIR="${MEDIA_DIR:-$BACKUP_ROOT/immich-app/data}"
DUMP_ROOT="$BACKUP_ROOT/immich-app/db-dumps"
B2_REMOTE="bb-b2:dazza9905-nas-data"

# Run as root with RCLONE_CONFIG pointing to your existing rclone config.
# --dry-run previews the media sync and remote cleanup. It does not stop
# Immich, create a database dump, upload anything, or delete any files.
DRY_RUN=false
RCLONE_FLAGS=()
if [[ $# == 1 && $1 == "--dry-run" ]]; then
    DRY_RUN=true
    RCLONE_FLAGS=(--dry-run)
elif [[ $# != 0 ]]; then
    echo "Usage: backup-image [--dry-run]" >&2
    exit 2
fi

############################################
# 1. Check the disk and media folder
############################################
if [[ $EUID != 0 ]]; then
    echo "Please run as root." >&2
    exit 1
fi

: "${RCLONE_CONFIG:?Set RCLONE_CONFIG to your existing rclone config}"
if [[ ! -s "$RCLONE_CONFIG" || ! -r "$RCLONE_CONFIG" ]]; then
    echo "Cannot read rclone config: $RCLONE_CONFIG (missing, empty, or unreadable)." >&2
    echo "Restore your existing config and set homelab.services.backup.rcloneConfig to its path." >&2
    echo "For a manual run: sudo RCLONE_CONFIG=/path/to/rclone.conf backup-image --dry-run" >&2
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
if [[ ! -d "$MEDIA_DIR/library" || ! -d "$MEDIA_DIR/upload" ]]; then
    echo "Immich media folders are missing. Refusing to sync." >&2
    exit 1
fi

# Both backup scripts use this lock so they cannot run at the same time.
exec 9>/run/lock/maddie-b2-backup.lock
flock -n 9 || { echo "Another backup is running." >&2; exit 1; }

############################################
# 2. Stop Immich and dump the database
############################################
if $DRY_RUN; then
    echo "Dry run: skipping service stop and database dump."
else
    systemctl is-active --quiet postgresql.service

    # Always try to bring Immich back if a later command fails.
    trap 'systemctl start immich-server.service immich-machine-learning.service' EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM

    echo "Stopping Immich so the database and media stay consistent..."
    systemctl stop immich-server.service immich-machine-learning.service

    # Keep failed dumps on the NAS, outside the mirrored media directory.
    mkdir -p "$DUMP_ROOT"
    DUMP_DIR=$(mktemp -d "$DUMP_ROOT/run.XXXXXXXX")
    DUMP_FILE="$DUMP_DIR/immich-$(date +%Y-%m-%d_%H-%M-%S).sql.gz"

    echo "Dumping PostgreSQL to $DUMP_FILE..."
    runuser -u postgres -- pg_dumpall --clean --if-exists | gzip > "$DUMP_FILE"
    gzip -t "$DUMP_FILE"
fi

############################################
# 3. Back up Immich media
############################################
echo "Syncing Immich media..."
rclone sync "$MEDIA_DIR" "$B2_REMOTE/immich/data" \
    --config "$RCLONE_CONFIG" \
    --backup-dir "$B2_REMOTE/immich/deleted-data" \
    --transfers 32 \
    --checkers 32 \
    --fast-list \
    --b2-chunk-size 64M \
    --b2-upload-cutoff 64M \
    --buffer-size 64M \
    --progress \
    "${RCLONE_FLAGS[@]}"

############################################
# 4. Restart Immich and upload the dump
############################################
if $DRY_RUN; then
    echo "Dry run: no restart needed and no new dump to upload."
    echo "A real run uploads its dump to $B2_REMOTE/immich/db-dumps."
else
    echo "Restarting Immich..."
    systemctl start immich-server.service immich-machine-learning.service
    trap - EXIT INT TERM

    echo "Uploading the database dump..."
    rclone copy "$DUMP_FILE" "$B2_REMOTE/immich/db-dumps" \
        --config "$RCLONE_CONFIG" --progress
fi

############################################
# 5. Clean up old Backblaze backup data
############################################
# Same cleanup paths and 14-day dump retention as the original script.
echo "Cleaning up redundant Immich backup folders..."
rclone purge "$B2_REMOTE/immich/deleted-data/backups" \
    --config "$RCLONE_CONFIG" "${RCLONE_FLAGS[@]}" \
    || echo "WARNING: Could not remove deleted-data/backups (possibly absent)." >&2

rclone purge "$B2_REMOTE/immich/data/backups" \
    --config "$RCLONE_CONFIG" "${RCLONE_FLAGS[@]}" \
    || echo "WARNING: Could not remove data/backups (possibly absent)." >&2

echo "Removing database dumps older than 14 days..."
rclone delete "$B2_REMOTE/immich/db-dumps" --min-age 14d \
    --config "$RCLONE_CONFIG" "${RCLONE_FLAGS[@]}"

############################################
# 6. Remove this run's uploaded local dump
############################################
if $DRY_RUN; then
    echo "Dry run complete. No services stopped or files changed."
else
    rm -- "$DUMP_FILE"
    rmdir -- "$DUMP_DIR"
    echo "Immich backup complete!"
fi
