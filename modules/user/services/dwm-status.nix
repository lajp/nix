{...}: {
  systemd.user.services.dwm-status.Service.Restart = "on-failure";

  services.dwm-status = {
    enable = true;
    order = ["audio" "backlight" "battery" "network" "cpu_load" "time"];
  };
}
