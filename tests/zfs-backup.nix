{
  pkgs,
  ...
}:
let
  backupScript = pkgs.writeShellScript "backup.sh" (
    builtins.readFile ../modules/system/services/zfs-backup/backup.sh
  );
in
pkgs.testers.nixosTest {
  name = "zfs-backup";

  nodes.machine =
    { pkgs, ... }:
    {
      boot.supportedFilesystems = [ "zfs" ];
      networking.hostId = "deadbeef";
      virtualisation.emptyDiskImages = [ 512 ];
      environment.systemPackages = with pkgs; [
        zfs
        rclone
        gawk
      ];
    };

  testScript = ''
    machine.wait_for_unit("default.target")

    # Create ZFS pool on the empty disk
    machine.succeed("zpool create testpool /dev/vdb")

    # Create encrypted dataset (required for zfs send -w)
    machine.succeed("dd if=/dev/urandom of=/tmp/zfs-key bs=32 count=1 2>/dev/null")
    machine.succeed(
        "zfs create"
        " -o encryption=aes-256-gcm"
        " -o keyformat=raw"
        " -o keylocation=file:///tmp/zfs-key"
        " testpool/data"
    )

    # Write some data and create an auto-snapshot
    machine.succeed("echo 'hello world' > /testpool/data/testfile")
    machine.succeed("zfs snapshot testpool/data@zfs-auto-snap_2024-01-01")

    # Set up mock rclone config with local backend
    machine.succeed("printf '[server-backup-crypt]\\ntype = local\\n' > /tmp/rclone.conf")

    # Create the destination directory
    machine.succeed("mkdir -p /zfs-snapshots/testpool")

    # --- Test 1: Full backup (no previous hold exists) ---
    # Run from / so rclone's relative path "zfs-snapshots/..." resolves to /zfs-snapshots/...
    machine.succeed(
        "cd / && POOL=testpool RCLONE_CONFIG=/tmp/rclone.conf ${backupScript}"
    )

    # Verify backup chunk was created and is non-empty (small data = single chunk xaa)
    machine.succeed("test -s '/zfs-snapshots/testpool/zfs-auto-snap_2024-01-01.xaa.zfs'")

    # Verify hold was placed on the snapshot
    machine.succeed("zfs holds -H testpool/data@zfs-auto-snap_2024-01-01 | grep -q rclone-backup")

    # --- Test 1b: Re-run with no new snapshots (should be a no-op) ---
    machine.succeed(
        "cd / && POOL=testpool RCLONE_CONFIG=/tmp/rclone.conf ${backupScript}"
    )
    machine.succeed("zfs holds -H testpool/data@zfs-auto-snap_2024-01-01 | grep -q rclone-backup")

    # --- Test 2: Incremental backup ---
    machine.succeed("echo 'more data' >> /testpool/data/testfile")
    machine.succeed("zfs snapshot testpool/data@zfs-auto-snap_2024-01-02")

    machine.succeed(
        "cd / && POOL=testpool RCLONE_CONFIG=/tmp/rclone.conf ${backupScript}"
    )

    # Verify incremental backup chunk exists and is non-empty
    machine.succeed("test -s '/zfs-snapshots/testpool/zfs-auto-snap_2024-01-02.xaa.zfs'")

    # Verify hold moved to the new snapshot
    machine.succeed("zfs holds -H testpool/data@zfs-auto-snap_2024-01-02 | grep -q rclone-backup")

    # Verify old hold was released
    machine.fail("zfs holds -H testpool/data@zfs-auto-snap_2024-01-01 | grep -q rclone-backup")

    # --- Test 3: Full reseed (FULL=1) ---
    machine.succeed("echo 'even more data' >> /testpool/data/testfile")
    machine.succeed("zfs snapshot testpool/data@zfs-auto-snap_2024-02-01")

    machine.succeed(
        "cd / && FULL=1 POOL=testpool RCLONE_CONFIG=/tmp/rclone.conf ${backupScript}"
    )

    # Verify old incremental files were cleaned up
    machine.fail("test -e '/zfs-snapshots/testpool/zfs-auto-snap_2024-01-01.xaa.zfs'")
    machine.fail("test -e '/zfs-snapshots/testpool/zfs-auto-snap_2024-01-02.xaa.zfs'")

    # Verify new full backup exists
    machine.succeed("test -s '/zfs-snapshots/testpool/zfs-auto-snap_2024-02-01.xaa.zfs'")

    # Verify hold is on the new snapshot only
    machine.succeed("zfs holds -H testpool/data@zfs-auto-snap_2024-02-01 | grep -q rclone-backup")
    machine.fail("zfs holds -H testpool/data@zfs-auto-snap_2024-01-02 | grep -q rclone-backup")
  '';
}
