# ZFS Backup Service

Backs up ZFS pools to Google Drive via rclone using `zfs send` streams.
Encrypted datasets are sent raw (`-w`) so the encryption key is never exposed to rclone.

## Configuration

```nix
services.zfs-backup = {
  enable = true;
  pool = "naspool";
};
```

Requires `hardware.zfs.enable = true` and the `rclone-config.age` secret to be set up
with a valid rclone config containing the `server-backup-crypt` remote.

## How It Works

Two systemd timers manage backups:

| Timer | Schedule | Description |
|---|---|---|
| `zfs-rclone-backup` | Daily at 00:05 (±5h jitter) | Incremental backup since last run |
| `zfs-rclone-backup-full` | Quarterly (±6h jitter) | Full reseed: purges remote and uploads fresh |

The backup script:

1. Finds the newest `@zfs-auto-snap_*` snapshot in the pool
2. Checks for a ZFS hold tagged `rclone-backup` to identify the last backed-up snapshot
3. Sends an incremental stream (`zfs send -i -w`) if a previous backup exists, or a full replication stream (`zfs send -R -w`) on first run
4. Pipes the stream through `split` into 4TB chunks, each uploaded via `rclone rcat` to `server-backup-crypt:zfs-snapshots/<pool>/`
5. Places a hold on the new snapshot and releases the old one

The hold acts as a transaction marker: if the upload is interrupted, the hold is never
updated, and the next run safely retries from the same base.

## Remote File Layout

```
server-backup-crypt:zfs-snapshots/<pool>/
  zfs-auto-snap_monthly-2024-01-15.xaa.zfs    # full backup chunk 1
  zfs-auto-snap_monthly-2024-01-15.xab.zfs    # full backup chunk 2 (if >4TB)
  zfs-auto-snap_daily-2024-01-16.xaa.zfs      # incremental (typically single chunk)
  zfs-auto-snap_daily-2024-01-17.xaa.zfs      # incremental
  ...
```

Files are named `<snapshot-name>.<chunk-suffix>.zfs`. Chunks use alphabetical suffixes
(`xaa`, `xab`, `xac`, ...) and must be reassembled in order during recovery.
The oldest group of files is the full backup; all subsequent groups are incrementals
that must be applied in chronological order.

## Manual Operations

```bash
# Trigger an incremental backup now
systemctl start zfs-rclone-backup

# Trigger a full reseed now (purges remote first)
systemctl start zfs-rclone-backup-full

# Check backup status
journalctl -u zfs-rclone-backup -e

# See which snapshot is currently held (= last successful backup)
zfs list -t snapshot -o name -H | while read s; do
  zfs holds -H "$s" 2>/dev/null | grep rclone-backup
done

# List remote backup files
rclone ls server-backup-crypt:zfs-snapshots/<pool>/
```

## Recovery

Each backup consists of one or more chunk files that must be concatenated in order,
then piped to `zfs recv`. Apply the full backup first, then each incremental
in chronological order.

```bash
REMOTE="server-backup-crypt:zfs-snapshots/naspool"

# 1. List available backups (grouped by snapshot name)
rclone ls "$REMOTE/"

# 2. Receive the full backup (oldest snapshot, concatenate chunks in order)
rclone cat "$REMOTE/zfs-auto-snap_monthly-2024-01-15.xaa.zfs" | zfs recv targetpool
# If there are multiple chunks (xab, xac, ...):
# { rclone cat "$REMOTE/...xaa.zfs"; rclone cat "$REMOTE/...xab.zfs"; } | zfs recv targetpool

# 3. Apply each incremental in chronological order
rclone cat "$REMOTE/zfs-auto-snap_daily-2024-01-16.xaa.zfs" | zfs recv targetpool
rclone cat "$REMOTE/zfs-auto-snap_daily-2024-01-17.xaa.zfs" | zfs recv targetpool
# ... continue for all remaining snapshots in date order

# 4. Load the encryption key and mount
zfs load-key targetpool
zfs mount targetpool
```

For convenience, to restore all backups in one go:

```bash
REMOTE="server-backup-crypt:zfs-snapshots/naspool"

# List all unique snapshot names in order, reassemble chunks, and apply each
rclone lsf "$REMOTE/" | sed 's/\.x[a-z]*\.zfs$//' | sort -u | while read snap; do
  echo "Restoring $snap..."
  rclone lsf "$REMOTE/" | grep "^${snap}\." | sort | while read chunk; do
    rclone cat "$REMOTE/$chunk"
  done | zfs recv -F targetpool
done
```

**Important:** The ZFS encryption key is NOT included in the backup. Store it separately.

## Interrupted Backups

If a backup is interrupted (reboot, network failure, etc.):

- The hold remains on the previous snapshot, so no data is lost
- The next scheduled run retries automatically from the same base
- Partial chunk files may be left on the remote; they are cleaned up on the next full reseed

## Testing

```bash
nix build .#checks.x86_64-linux.zfs-backup -L
```

Runs a NixOS VM test that verifies full backups, incremental backups, hold management,
no-op on duplicate runs, and full reseeds.
