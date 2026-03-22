{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.backup-notify;

  failImage = pkgs.runCommand "backup-failed-wallpaper.png" {
    nativeBuildInputs = [ pkgs.imagemagick ];
  } ''
    ${pkgs.imagemagick}/bin/magick \
      -size 1920x1200 xc:'#8B0000' \
      -font ${pkgs.dejavu_fonts}/share/fonts/truetype/DejaVuSans-Bold.ttf \
      -pointsize 100 \
      -fill white \
      -gravity center \
      -annotate 0 'BACKUP FAILED\nFIX YOUR SHIT' \
      png:$out
  '';

  stateDir = "/var/lib/backup-notify";
  stateFile = "${stateDir}/state";

  writeState = pkgs.writeShellScript "backup-notify-fail" ''
    echo "${failImage}" > ${stateFile}
  '';

  clearState = pkgs.writeShellScript "backup-notify-success" ''
    rm -f ${stateFile}
  '';
in
{
  options.lajp.services.backup-notify.enable = mkEnableOption "Backup failure wallpaper notification";

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${stateDir} 0755 root root -"
    ];

    systemd.services.backup-failed-notify = {
      description = "Mark backup as failed (update wallpaper state)";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = writeState;
      };
    };

    systemd.services.backup-success-notify = {
      description = "Clear backup failure state";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = clearState;
      };
    };

    systemd.services.restic-backups-nas = {
      unitConfig = {
        OnFailure = [ "backup-failed-notify.service" ];
        OnSuccess = [ "backup-success-notify.service" ];
      };
    };
  };
}
