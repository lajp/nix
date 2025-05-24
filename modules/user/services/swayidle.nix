{
  osConfig,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  xserver = osConfig.lajp.services.xserver.enable;
  lock = "${pkgs.swaylock}/bin/swaylock -f";
in
{
  systemd.user.services = mkIf (!xserver) {
    swayidle.Unit.After = lib.mkForce "niri.service";
  };

  services.swayidle = mkIf (!xserver) {
    enable = true;
    systemdTarget = "graphical-session.target";
    events = [
      {
        event = "before-sleep";
        command = "${lock}";
      }
      {
        event = "lock";
        command = "${lock}";
      }
    ];

    timeouts = [
      {
        timeout = 1500;
        command = "${lock}";
      }
    ];
  };
}
