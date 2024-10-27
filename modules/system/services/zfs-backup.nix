{
  lib,
  config,
  pkgs,
  inputs,
  ...
}: let
  inherit (lib) types mkEnableOption mkOption mkIf;
  cfg = config.lajp.services.zfs-backup;
  hostname = config.lajp.core.hostname;

  freqs = ["daily" "monthly" "yearly"];

  services =
    map
    (freq: {
      "${cfg.pool}-backup-${freq}" = {
        description = "Automatic ${freq} backup of ZFS pool ${cfg.pool}";

        path = with pkgs; [coreutils gnugrep rclone bash config.boot.zfs.package];

        environment.RCLONE_CONFIG = config.age.secrets.rclone-config.path;

        script = ''
          set -eu
          bash ${inputs.zfs-rclone-backup}/zfs-rclone-backup ${hostname} ${cfg.pool} ${freq}
        '';

        serviceConfig = {
          Type = "oneshot";
        };
      };
    })
    freqs;

  timers =
    map
    (freq: {
      "${cfg.pool}-backup-${freq}".timerConfig = {
        OnCalendar = freq;
        Persistent = true;
      };
    })
    freqs;
in {
  # ZFS backups with zfs send and rclone
  # inspired by https://github.com/ACiDGRiM/RcloneZFSBackup

  options.lajp.services.zfs-backup = {
    enable = mkEnableOption "Enable ZFS backups";
    # TODO: support multiple pools
    pool = mkOption {
      description = "ZFS pool to backup";
      type = types.str;
    };
  };

  config = mkIf cfg.enable {
    age.secrets.rclone-config.file = ../../../secrets/rclone-config.age;

    services.zfs.autoSnapshot = {
      enable = true;
      daily = 90;
    };

    systemd.services = lib.attrsets.mergeAttrsList services;
    systemd.timers = lib.attrsets.mergeAttrsList timers;
  };
}
