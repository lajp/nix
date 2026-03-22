{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
  cfg = config.lajp.services.zfs-backup;
in
{
  options.lajp.services.zfs-backup = {
    enable = mkEnableOption "Enable ZFS backups";
    pool = mkOption {
      description = "name of the zfs pool to backup";
      type = types.str;
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = config.lajp.hardware.zfs.enable;
        message = "ZFS needs to be enabled for backups";
      }
    ];

    age.secrets.rclone-config.rekeyFile = ../../../../secrets/rclone-config.age;

    systemd = {
      services."zfs-rclone-backup" = {
        description = "ZFS Google Drive backup";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.writeShellScriptBin "backup.sh" (builtins.readFile ./backup.sh)}/bin/backup.sh";
        };

        environment = {
          POOL = cfg.pool;
          RCLONE_CONFIG = config.age.secrets.rclone-config.path;
        };

        path = with pkgs; [
          rclone
          zfs
          gawk
        ];

      };

      services."zfs-rclone-backup-full" = {
        description = "ZFS Google Drive full backup (reseed)";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.writeShellScriptBin "backup.sh" (builtins.readFile ./backup.sh)}/bin/backup.sh";
        };

        environment = {
          POOL = cfg.pool;
          RCLONE_CONFIG = config.age.secrets.rclone-config.path;
          FULL = "1";
        };

        path = with pkgs; [
          rclone
          zfs
          gawk
        ];

      };

      timers."zfs-rclone-backup" = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "00:05";
          RandomizedDelaySec = "5h";
        };
      };

      timers."zfs-rclone-backup-full" = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "quarterly";
          RandomizedDelaySec = "6h";
        };
      };
    };
  };
}
