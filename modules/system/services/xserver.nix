{ pkgs, lib, config, ...}: let
  inherit (lib) mkIf;
  inherit (config.lajp.core) server;
{
  services.xserver = mkIf (!server) {
    enable = true;

    displayManager.gdm.enable = true;

    windowManager.dwm = {
      enable = true;
      package = pkgs.overrideAttrs {
        src = fetchgit {
          url = "https://github.com/lajp/dwm";
        };
      };
    };
  };
}
