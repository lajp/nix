{ ... }:
{
  imports = [
    ./common
    ./services
    ./core.nix
    ./ports.nix
    ./hardware
    ./gui
    ./virtualisation
    ./rickroll.nix
    ./dreamlauncher.nix
  ];
}
