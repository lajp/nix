{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.testaustime-backup;
in {
  options.lajp.services.testaustime-backup.enable = mkEnableOption "Enable testaustime backup service";
  config = mkIf cfg.enable {
    systemd.timers."testaustime-backup" = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
        Unit = "testaustime-backup.service";
      };
    };

    systemd.services."testaustime-backup" = {
      path = with pkgs; [rsync openssh];
      script = ''
        set -eu
        rsync -Pr testaustime.fi:/opt/backups /media/luukas/Backups/testaustime
      '';
      serviceConfig = {
        Type = "oneshot";
        User = config.lajp.user.username;
      };
    };
  };
}
