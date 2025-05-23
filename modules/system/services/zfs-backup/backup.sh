#!/usr/bin/env bash
set -eu

REMOTE="server-backup-crypt:zfs-snapshots/$POOL"
TAG="rclone-backup"

# Find the last held snapshot (if any)
LAST_HOLD=$(zfs list -t snapshot -o name -s creation -H \
  | grep "^${POOL}/.*@auto-" | tac | grep "${TAG}" | head -1 || true)

# Determine incremental or full send
if [[ -n "$LAST_HOLD" ]]; then
  BASE="-i ${LAST_HOLD}"
else
  BASE="-R"
fi

# Identify the newest auto snapshot
NEW_SNAP=$(zfs list -t snapshot -o name -s creation -H \
  | grep "^${POOL}/.*@auto-" | tail -1)

# Estimate stream size (dry-run) and extract size
ESTIMATED=$(zfs send -nP $BASE -w "$NEW_SNAP" 2>&1 \
  | awk '/size/ { print $2 }' || "-1")

# Perform the actual send, streaming into rclone
zfs send $BASE -w "$NEW_SNAP" | \
  rclone rcat --size "$ESTIMATED" \
    "$REMOTE/${NEW_SNAP#*/}.zfs"

# Update holds for retention tracking
zfs hold "${TAG}" "$NEW_SNAP"
if [[ -n "$LAST_HOLD" ]]; then
  zfs release "${TAG}" "$LAST_HOLD"
fi
