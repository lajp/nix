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
      type = types.string;
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

        wantedBy = [ "multi-user.target" ];
      };

      timers."zfs-rclone-backup" = {
        enable = false;
        timerConfig = {
          OnCalendar = "00:05";
          RandomizedDelaySec = "5h";
        };
      };
    };
  };
}
