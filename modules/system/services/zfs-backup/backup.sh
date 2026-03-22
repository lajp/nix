#!/usr/bin/env bash
set -euo pipefail

REMOTE="server-backup-crypt:zfs-snapshots/$POOL"
TAG="rclone-backup"

# Find the last held snapshot (if any)
LAST_HOLD=$(zfs list -t snapshot -o name -s creation -H \
  | grep "^${POOL}.*@zfs-auto-snap_" \
  | while IFS= read -r snap; do
      if zfs holds -H "$snap" 2>/dev/null | grep -q "$TAG"; then
        echo "$snap"
      fi
    done | tail -1 || true)

# Force full backup: release existing hold and clean remote
if [[ "${FULL:-}" == "1" && -n "$LAST_HOLD" ]]; then
  zfs release "${TAG}" "$LAST_HOLD"
  rclone purge "$REMOTE" 2>/dev/null || true
  LAST_HOLD=""
fi

# Determine incremental or full send
if [[ -n "$LAST_HOLD" ]]; then
  BASE="-i ${LAST_HOLD}"
else
  BASE="-R"
fi

# Identify the newest auto snapshot
NEW_SNAP=$(zfs list -t snapshot -o name -s creation -H \
  | grep "^${POOL}.*@zfs-auto-snap_" | tail -1)

# Nothing to do if no snapshots exist or newest is already backed up
if [[ -z "$NEW_SNAP" || "$NEW_SNAP" == "$LAST_HOLD" ]]; then
  echo "No new snapshots to back up"
  exit 0
fi

# Perform the actual send, splitting into 4TB chunks for Google Drive's 5TB limit
SNAP_NAME="${NEW_SNAP##*@}"
zfs send $BASE -w "$NEW_SNAP" | \
  split -b 4T --filter="rclone rcat \"$REMOTE/${SNAP_NAME}.\$FILE.zfs\"" -

# Update holds for retention tracking
zfs hold "${TAG}" "$NEW_SNAP"
if [[ -n "$LAST_HOLD" ]]; then
  zfs release "${TAG}" "$LAST_HOLD"
fi
