{
  osConfig,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
  cfg = osConfig.lajp.services.niri;
in {
  config = mkIf cfg.enable {
    systemd.user.services.waybar.Unit.After = lib.mkForce "niri.service";
    programs.waybar = {
      enable = true;
      settings = {
        mainBar = {
          layer = "top";
          position = "bottom";
          output = [
            "eDP-1"
            "HDMI-A-2"
          ];

          modules-center = [
            "mpris"
          ];

          modules-right = [
            "wireplumber"
            "backlight"
            "network"
            "battery"
            "battery#bat2"
            "cpu"
            "temperature"
            "clock"
          ];

          mpris.interval = 1;

          wireplumber = {
            format = "{volume}%";
            format-muted = "";
            on-click = "${pkgs.helvum}/bin/helvum";
            max-volume = 150;
            scroll-step = 0.2;
          };

          battery = {
            bat = "BAT0";
            format = "{capacity}% {icon}";
            format-icons = ["" "" "" "" ""];
          };

          "battery#bat2" = {
            bat = "BAT1";
            format = "{capacity}% {icon}";
            format-icons = ["" "" "" "" ""];
          };

          backlight = {
            device = "intel_backlight";
            format = "{percent}% {icon}";
            format-icons = ["" ""];
          };

          temperature.hwmon-path = "/sys/devices/platform/thinkpad_hwmon/hwmon/hwmon6/temp1_input";

          network = {
            format-wifi = "{essid} ({signalStrength}%)";
            format-ethernet = "{ifname}";
          };

          clock = {
            format = "{:%Y-%m-%d %H:%M:%S}";
            inverval = 1;
          };
        };
      };
      systemd.enable = true;
    };
  };
}
