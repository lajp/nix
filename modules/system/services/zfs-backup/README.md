# ZFS Backup Service

Backs up ZFS datasets to Google Drive via rclone using `zfs send` streams.
Streams are uploaded directly — no local staging or chunking. Encrypted
datasets are sent raw (`-w`), so the stream is already ZFS-encrypted before it
ever reaches rclone; unencrypted datasets are sent as-is.

## Configuration

```nix
services.zfs-backup = {
  enable = true;
  pool = "naspool";
  datasets = [ "naspool/critical" ];  # default: ${pool}/critical
};
```

Requires `hardware.zfs.enable = true` and the `rclone-config.age` secret to be
set up with a valid rclone config containing the `server-backup` remote.

## What Gets Backed Up

Every dataset below one of `datasets` that has `@zfs-auto-snap_*` snapshots. A
dataset excluded from snapshotting via `com.sun:auto-snapshot=false` never
appears. On nas this currently means `naspool/critical/backups` and
`naspool/critical/state`.

## How It Works

Two systemd timers manage backups:

| Timer | Schedule | Description |
|---|---|---|
| `zfs-rclone-backup` | Daily at 00:05 (±5h jitter) | Incremental backup since last run |
| `zfs-rclone-backup-full` | Quarterly (±6h jitter) | Full reseed: purges remote and uploads fresh |

Per dataset, the backup script:

1. Finds the newest `@zfs-auto-snap_*` snapshot of the dataset
2. Checks for a ZFS hold tagged `rclone-backup` to identify the last backed-up snapshot
3. Sends an incremental stream (`zfs send -i -w`) if a previous backup exists,
   or a full stream on first run, **streaming straight to the remote** with
   `rclone rcat` — no local staging or chunking
4. Only after a clean upload: places a hold on the new snapshot and releases
   the old one

The hold acts as a transaction marker: if the upload is interrupted, the hold
is never updated, and the next run safely retries from the same base. Streams
are uploaded under a dot-prefixed name and renamed into place only after
`zfs send` completes, so a failed send can never leave a truncated file at the
final name. `rcat` retries individual upload chunks; a fully failed run is
simply re-run.

## Remote File Layout

```
server-backup:zfs-snapshots/<pool>/
  critical/
    backups/
      zfs-auto-snap_daily-2024-01-16.zfs    # incremental
      zfs-auto-snap_monthly-2024-01-15.zfs  # oldest group = full backup
    state/
      zfs-auto-snap_daily-2024-01-16.zfs
```

One file per snapshot per dataset. Within each dataset, the oldest file is the
full backup; all subsequent files are incrementals that must be applied in
chronological order.

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
rclone ls server-backup:zfs-snapshots/<pool>/
```

To run the initial backup by hand before deploying (on the nas, with an rclone
config that contains the `server-backup` remote):

```bash
POOL=naspool ROOTS="naspool/critical" \
RCLONE_CONFIG=<path to rclone config> \
/path/to/backup.sh
```

The first run sends a full stream per dataset; later runs send incrementals.

## Recovery

Each dataset's oldest file is a full stream; apply it first, then each newer
file in date order.

```bash
REMOTE="server-backup:zfs-snapshots/naspool"

# 1. List available backups
rclone ls "$REMOTE/"

# 2. Create the target dataset
zfs create -o mountpoint=/media naspool2

# 3. Full backup first, then incrementals in date order
rclone cat "$REMOTE/critical/backups/zfs-auto-snap_monthly-2024-01-15.zfs" | zfs recv -F naspool2/critical/backups
rclone cat "$REMOTE/critical/backups/zfs-auto-snap_daily-2024-01-16.zfs" | zfs recv -F naspool2/critical/backups
# ... continue for all remaining snapshots in date order

# 4. Load the encryption key and mount
zfs load-key naspool2
zfs mount -a
```

**Important:** The ZFS encryption key is NOT included in the backup. Store it separately.

## Testing

```bash
nix build .#checks.x86_64-linux.zfs-backup -L
```

Runs a NixOS VM test that verifies full backups, incremental backups, hold
management, no-op on duplicate runs, scope restriction to the configured
datasets, full reseeds, and that a failed run leaves no file and no hold.
