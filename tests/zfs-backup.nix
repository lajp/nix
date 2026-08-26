{
  pkgs,
  ...
}:
let
  backupScript = pkgs.writeShellScript "backup.sh" (
    builtins.readFile ../modules/system/services/zfs-backup/backup.sh
  );

  # Fakes Google Drive being rate-limited: succeeds at mkdir (used before the
  # upload loop) but fails every upload with Google's userRateLimitExceeded
  # error, exactly as the real backend prints it.
  fakeRclone = pkgs.writeShellScript "rclone" ''
    if [[ "$1" == "mkdir" ]]; then
      exit 0
    fi
    echo "ERROR : .test.zfs.part: Post request rcat error: googleapi: Error 403: User rate limit exceeded., userRateLimitExceeded" >&2
    exit 1
  '';
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
      ];
    };

  testScript = ''
    machine.wait_for_unit("default.target")

    # Create ZFS pool on the empty disk
    machine.succeed("zpool create testpool /dev/vdb")

    # Encrypted root (children inherit encryption, so they exercise the -w
    # raw-send path) with two datasets under it, plus a dataset outside the
    # backup root that must never be sent.
    machine.succeed("dd if=/dev/urandom of=/tmp/zfs-key bs=32 count=1 2>/dev/null")
    machine.succeed(
        "zfs create"
        " -o encryption=aes-256-gcm"
        " -o keyformat=raw"
        " -o keylocation=file:///tmp/zfs-key"
        " testpool/critical"
    )
    machine.succeed("zfs create testpool/critical/backups")
    machine.succeed("zfs create testpool/critical/state")
    machine.succeed("zfs create testpool/other")

    # Write some data and create an auto-snapshot
    machine.succeed("echo 'hello world' > /testpool/critical/backups/testfile")
    machine.succeed("zfs snapshot testpool/critical/backups@zfs-auto-snap_2024-01-01")

    # Set up mock rclone config with local backend
    machine.succeed("printf '[server-backup]\ntype = local\n' > /tmp/rclone.conf")

    # Create the destination directory
    machine.succeed("mkdir -p /zfs-snapshots/testpool")

    # --- Test 1: Full backup (no previous hold exists) ---
    # Run from / so rclone's relative path "zfs-snapshots/..." resolves to /zfs-snapshots/...
    machine.succeed(
        "cd / && POOL=testpool ROOTS='testpool/critical' RCLONE_CONFIG=/tmp/rclone.conf ${backupScript}"
    )

    # Verify the stream was uploaded as a single file and no .part remains
    machine.succeed("test -s '/zfs-snapshots/testpool/critical/backups/zfs-auto-snap_2024-01-01.zfs'")
    machine.fail("test -e '/zfs-snapshots/testpool/critical/backups/.zfs-auto-snap_2024-01-01.zfs.part'")

    # Verify hold was placed on the snapshot
    machine.succeed("zfs holds -H testpool/critical/backups@zfs-auto-snap_2024-01-01 | grep -q rclone-backup")

    # --- Test 1b: Re-run with no new snapshots (should be a no-op) ---
    machine.succeed(
        "cd / && POOL=testpool ROOTS='testpool/critical' RCLONE_CONFIG=/tmp/rclone.conf ${backupScript}"
    )
    machine.succeed("zfs holds -H testpool/critical/backups@zfs-auto-snap_2024-01-01 | grep -q rclone-backup")

    # --- Test 2: Incremental backup ---
    machine.succeed("echo 'more data' >> /testpool/critical/backups/testfile")
    machine.succeed("zfs snapshot testpool/critical/backups@zfs-auto-snap_2024-01-02")

    machine.succeed(
        "cd / && POOL=testpool ROOTS='testpool/critical' RCLONE_CONFIG=/tmp/rclone.conf ${backupScript}"
    )

    # Verify incremental backup file exists and is non-empty
    machine.succeed("test -s '/zfs-snapshots/testpool/critical/backups/zfs-auto-snap_2024-01-02.zfs'")

    # Verify hold moved to the new snapshot
    machine.succeed("zfs holds -H testpool/critical/backups@zfs-auto-snap_2024-01-02 | grep -q rclone-backup")

    # Verify old hold was released
    machine.fail("zfs holds -H testpool/critical/backups@zfs-auto-snap_2024-01-01 | grep -q rclone-backup")

    # --- Test 3: second dataset under the root is backed up too ---
    machine.succeed("echo 'state data' > /testpool/critical/state/file")
    machine.succeed("zfs snapshot testpool/critical/state@zfs-auto-snap_2024-02-01")

    machine.succeed(
        "cd / && POOL=testpool ROOTS='testpool/critical' RCLONE_CONFIG=/tmp/rclone.conf ${backupScript}"
    )
    machine.succeed("test -s '/zfs-snapshots/testpool/critical/state/zfs-auto-snap_2024-02-01.zfs'")
    machine.succeed("zfs holds -H testpool/critical/state@zfs-auto-snap_2024-02-01 | grep -q rclone-backup")

    # --- Test 4: dataset outside the root is never sent, even with snapshots ---
    machine.succeed("echo 'other data' > /testpool/other/file")
    machine.succeed("zfs snapshot testpool/other@zfs-auto-snap_2024-02-01")

    machine.succeed(
        "cd / && POOL=testpool ROOTS='testpool/critical' RCLONE_CONFIG=/tmp/rclone.conf ${backupScript}"
    )
    machine.fail("test -e '/zfs-snapshots/testpool/other'")

    # --- Test 5: Full reseed (FULL=1) ---
    machine.succeed("echo 'even more data' >> /testpool/critical/backups/testfile")
    machine.succeed("zfs snapshot testpool/critical/backups@zfs-auto-snap_2024-03-01")

    machine.succeed(
        "cd / && FULL=1 POOL=testpool ROOTS='testpool/critical' RCLONE_CONFIG=/tmp/rclone.conf ${backupScript}"
    )

    # Verify old incremental files were cleaned up
    machine.fail("test -e '/zfs-snapshots/testpool/critical/backups/zfs-auto-snap_2024-01-01.zfs'")
    machine.fail("test -e '/zfs-snapshots/testpool/critical/backups/zfs-auto-snap_2024-01-02.zfs'")

    # Verify new full backup exists
    machine.succeed("test -s '/zfs-snapshots/testpool/critical/backups/zfs-auto-snap_2024-03-01.zfs'")

    # Verify hold is on the new snapshot only
    machine.succeed("zfs holds -H testpool/critical/backups@zfs-auto-snap_2024-03-01 | grep -q rclone-backup")
    machine.fail("zfs holds -H testpool/critical/backups@zfs-auto-snap_2024-01-02 | grep -q rclone-backup")

    # --- Test 6: failed run leaves no file and no hold; re-run succeeds ---
    machine.succeed("echo 'more data' >> /testpool/critical/backups/testfile")
    machine.succeed("zfs snapshot testpool/critical/backups@zfs-auto-snap_2024-04-01")

    # Broken rclone config: run must fail before uploading anything
    machine.succeed("printf '[broken]\ntype = broken\n' > /tmp/broken.conf")
    machine.fail(
        "cd / && POOL=testpool ROOTS='testpool/critical' RCLONE_CONFIG=/tmp/broken.conf RETRY_SLEEP=1 ${backupScript}"
    )
    machine.fail("test -e '/zfs-snapshots/testpool/critical/backups/zfs-auto-snap_2024-04-01.zfs'")
    machine.fail("zfs holds -H testpool/critical/backups@zfs-auto-snap_2024-04-01 | grep -q rclone-backup")

    # Fix the config: re-run uploads from the same base and moves the hold
    machine.succeed(
        "cd / && POOL=testpool ROOTS='testpool/critical' RCLONE_CONFIG=/tmp/rclone.conf ${backupScript}"
    )
    machine.succeed("test -s '/zfs-snapshots/testpool/critical/backups/zfs-auto-snap_2024-04-01.zfs'")
    machine.succeed("zfs holds -H testpool/critical/backups@zfs-auto-snap_2024-04-01 | grep -q rclone-backup")

    # --- Test 7: Google Drive rate limit aborts fast, leaves no hold, and the
    # next run resumes from the same base ---
    machine.succeed("echo 'rate limit data' >> /testpool/critical/backups/testfile")
    machine.succeed("zfs snapshot testpool/critical/backups@zfs-auto-snap_2024-05-01")

    # Fake rclone that fails every upload with Google's rate-limit error
    machine.succeed("mkdir -p /tmp/fakebin")
    machine.succeed("ln -sf ${fakeRclone} /tmp/fakebin/rclone")

    out = machine.fail(
        "cd / && PATH=/tmp/fakebin:$PATH POOL=testpool ROOTS='testpool/critical' "
        "RCLONE_CONFIG=/tmp/rclone.conf RETRY_SLEEP=1 ${backupScript} 2>&1"
    )
    assert "aborting" in out, f"expected fail-fast abort, got: {out}"
    assert "attempt 2/10" not in out, "rate-limit error must not be retried"
    machine.fail("test -e '/zfs-snapshots/testpool/critical/backups/zfs-auto-snap_2024-05-01.zfs'")
    machine.fail("zfs holds -H testpool/critical/backups@zfs-auto-snap_2024-05-01 | grep -q rclone-backup")

    # Back on the real config: resumes from the held base and completes
    machine.succeed(
        "cd / && POOL=testpool ROOTS='testpool/critical' RCLONE_CONFIG=/tmp/rclone.conf ${backupScript}"
    )
    machine.succeed("test -s '/zfs-snapshots/testpool/critical/backups/zfs-auto-snap_2024-05-01.zfs'")
    machine.succeed("zfs holds -H testpool/critical/backups@zfs-auto-snap_2024-05-01 | grep -q rclone-backup")
  '';
}
