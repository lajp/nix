{ config, ... }:
{
  imports = [
    ./zfs.nix
    ./bluetooth.nix
    ./sound.nix
    ./rtl-sdr.nix
    ./backlight.nix
  ];

  services.upower.enable = !config.lajp.core.server;
}
