#!/usr/bin/env bash
# Clear the Samsung 990 Pro's NTFS dirty flag and Windows session lock.
set -euo pipefail

if [[ ${1:-} == --help || ${1:-} == -h ]]; then
  printf '%s\n' \
    'Usage: force-samsung990pro' \
    'Close Steam first. Clears the NTFS dirty flag and remounts the Samsung drive.' \
    'If Windows is hibernated, its saved session and unsaved work are discarded.'
  exit 0
fi
if (( $# )); then
  printf 'Unknown argument: %s\n' "$1" >&2
  exit 2
fi
if (( EUID != 0 )); then
  exec sudo -- "$(command -v bash)" "$(readlink -f -- "${BASH_SOURCE[0]}")"
fi

device=$(readlink -e /dev/disk/by-uuid/CC702C2D702C20A6) || {
  printf '%s\n' 'Samsung partition CC702C2D702C20A6 was not found.' >&2
  exit 1
}
mountpoint=/mnt/samsung990pro
library=$mountpoint/SteamLibrary/steamapps
mount_unit=mnt-samsung990pro.mount
automount_unit=mnt-samsung990pro.automount

exec 9>/run/lock/force-samsung990pro.lock
flock -n 9 || { printf '%s\n' 'A repair is already running.' >&2; exit 1; }
[[ $(blkid -s TYPE -o value "$device") == ntfs ]] || {
  printf '%s\n' 'The expected partition is not NTFS; stopping.' >&2
  exit 1
}
if pgrep -u 1000 -x steam >/dev/null; then
  printf '%s\n' 'Close Steam completely, then run this script again.' >&2
  exit 1
fi

printf '%s\n' 'Clearing the NTFS dirty flag. Any saved Windows session may be discarded.'
log=$(mktemp /tmp/force-samsung990pro.XXXXXX)
manual_mount=0
restore_automount=0
cleanup() {
  result=$?
  trap - EXIT
  if (( manual_mount )); then
    umount -- "$mountpoint" || printf '%s\n' 'Could not unmount the temporary repair mount.' >&2
  fi
  if (( restore_automount )); then
    systemctl start "$automount_unit" || printf '%s\n' 'Could not restore automount.' >&2
  fi
  rm -f -- "$log"
  exit "$result"
}
trap cleanup EXIT

# Stop the filesystem first: stopping automount while it is busy can detach it.
# Do not run NTFS repair if a normal unmount fails.
systemctl stop "$mount_unit"
restore_automount=1
systemctl stop "$automount_unit"
if findmnt -rn -S "$device" >/dev/null; then
  printf '%s\n' 'The partition is still mounted; stopping without repairing it.' >&2
  exit 1
fi

if ntfsfix --clear-dirty "$device" >"$log" 2>&1; then
  cat "$log"
else
  cat "$log"
  if ! grep -Eq 'Windows is hibernated|Metadata kept in Windows cache' "$log"; then
    printf '%s\n' 'NTFS repair failed; stopping. The drive may need Windows chkdsk.' >&2
    exit 1
  fi
  printf '%s\n' 'Removing the Windows hibernation lock, then clearing the dirty flag again...'
  mount -t ntfs-3g -o rw,uid=1000,remove_hiberfile "$device" "$mountpoint"
  manual_mount=1
  umount -- "$mountpoint"
  manual_mount=0
  ntfsfix --clear-dirty "$device"
fi

systemctl start "$automount_unit"
restore_automount=0

# Trigger the usual configured mount and verify writes as the desktop user.
# Variables in this command are expanded by the child shell.
# shellcheck disable=SC2016
runuser -u dazza -- bash -c '
  set -euo pipefail
  file=$(mktemp "$1/.drive-write-test.XXXXXX")
  trap '\''rm -f -- "$file"'\'' EXIT
  printf "Steam library write test\n" > "$file"
  sync "$file"
' bash "$library"
findmnt -T "$library" -o TARGET,SOURCE,FSTYPE,OPTIONS
printf '%s\n' 'Done: the dirty flag is cleared and the Steam library is writable. Reopen Steam.'
