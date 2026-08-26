#!/usr/bin/env bash
set -euo pipefail

REMOTE="server-backup:zfs-snapshots/$POOL"
TAG="rclone-backup"
RETRY_SLEEP="${RETRY_SLEEP:-300}"     # seconds between upload attempts
UPLOAD_ATTEMPTS="${UPLOAD_ATTEMPTS:-10}"

# Full reseed: release every hold and wipe the remote, so the next run sends
# full streams from scratch instead of incrementals.
if [[ "${FULL:-}" == "1" ]]; then
  zfs list -H -t snapshot -o name | grep "^${POOL}.*@zfs-auto-snap_" \
    | while IFS= read -r snap; do
        zfs release "${TAG}" "$snap" 2>/dev/null || true
      done
  rclone purge "$REMOTE" 2>/dev/null || true
fi

# Backup set: every dataset below one of $ROOTS that has auto-snapshots.
# Datasets excluded from snapshotting (com.sun:auto-snapshot=false) never appear.
DATASETS=$(for root in $ROOTS; do
             zfs list -H -r -t snapshot -o name "$root" 2>/dev/null
           done \
           | grep '@zfs-auto-snap_' | sed 's/@.*//' | sort -u)

BACKED_UP=0
for DATASET in $DATASETS; do
  # Last successfully backed-up snapshot, marked by the hold
  LAST_HOLD=$(zfs list -H -t snapshot -o name -s creation "$DATASET" \
    | grep '@zfs-auto-snap_' \
    | while IFS= read -r snap; do
        if zfs holds -H "$snap" 2>/dev/null | grep -q "$TAG"; then
          echo "$snap"
        fi
      done | tail -1 || true)

  # Newest auto snapshot of this dataset
  NEW_SNAP=$(zfs list -H -t snapshot -o name -s creation "$DATASET" \
    | grep '@zfs-auto-snap_' | tail -1)

  if [[ -z "$NEW_SNAP" || "$NEW_SNAP" == "$LAST_HOLD" ]]; then
    echo "No new snapshots for $DATASET"
    continue
  fi

  # Incremental from the held snapshot, or a full stream on first backup
  BASE=()
  if [[ -n "$LAST_HOLD" ]]; then
    BASE=(-i "$LAST_HOLD")
  fi

  # Raw sends for encrypted datasets: the stream is already ZFS-encrypted, so
  # nothing else protects it on the remote. Unencrypted datasets are sent as-is.
  RAW=()
  if [[ "$(zfs get -H -o value encryption "$DATASET" 2>/dev/null || echo off)" != "off" ]]; then
    RAW=(-w)
  fi

  SNAP_NAME="${NEW_SNAP##*@}"
  DEST_DIR="$REMOTE${DATASET#"$POOL"}"
  rclone mkdir "$DEST_DIR"

  # Stream straight to the remote (no local staging or chunking). The stream is
  # uploaded under a dot-prefixed name and only renamed into place once zfs
  # send completes, so a failed send can never leave a truncated file at the
  # final name. The hold moves only after a clean upload, so an interrupted
  # run is simply re-run from the same base.
  ok=0
  for attempt in $(seq 1 "$UPLOAD_ATTEMPTS"); do
    ERR_FILE=$(mktemp)
    if zfs send "${BASE[@]}" "${RAW[@]}" "$NEW_SNAP" \
       | rclone rcat --drive-chunk-size 256M --drive-stop-on-upload-limit "$DEST_DIR/.${SNAP_NAME}.zfs.part" 2>"$ERR_FILE" \
       && rclone moveto "$DEST_DIR/.${SNAP_NAME}.zfs.part" "$DEST_DIR/${SNAP_NAME}.zfs" 2>>"$ERR_FILE"; then
      ok=1
      rm -f "$ERR_FILE"
      break
    fi
    # Google's per-user upload cap (750 GB/day, rolling 24h) blocks ALL uploads
    # until 24h pass; a short retry can't clear it. Abort the whole run rather
    # than re-streaming the snapshot -- the next run resumes from the hold.
    if grep -q 'userRateLimitExceeded' "$ERR_FILE"; then
      echo "Google Drive user rate limit reached; aborting (block lasts 24h). Re-run tomorrow." >&2
      rm -f "$ERR_FILE"
      exit 1
    fi
    rm -f "$ERR_FILE"
    echo "Upload of $NEW_SNAP failed (attempt $attempt/$UPLOAD_ATTEMPTS), retrying in ${RETRY_SLEEP}s" >&2
    sleep "$RETRY_SLEEP"
  done
  if [[ "$ok" != "1" ]]; then
    echo "Giving up on $NEW_SNAP; re-run to resume" >&2
    exit 1
  fi

  zfs hold "${TAG}" "$NEW_SNAP"
  if [[ -n "$LAST_HOLD" ]]; then
    zfs release "${TAG}" "$LAST_HOLD"
  fi
  BACKED_UP=1
done

if [[ "$BACKED_UP" == "0" ]]; then
  echo "No new snapshots to back up"
fi
