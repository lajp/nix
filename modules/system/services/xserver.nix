{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: let
  inherit (lib) mkIf;
  inherit (config.lajp.core) server;
in {
  config = mkIf (!server) {
    environment.systemPackages = with pkgs; [
      dmenu
      inputs.blmgr.packages.${system}.default
      # for volume control through pactl
      pulseaudio
    ];

    services.udev.packages = [pkgs.light];

    services.xserver = {
      enable = true;

      xautolock.enable = true;

      displayManager.lightdm.enable = true;
      displayManager.sessionCommands = ''
        ${pkgs.xorg.xinput}/bin/xinput disable "Synaptics TM3276-022"
      '';

      windowManager.dwm = {
        enable = true;
        package = pkgs.dwm.overrideAttrs {
          src = pkgs.fetchFromGitHub {
            owner = "lajp";
            repo = "dwm";
            rev = "master";
            hash = "sha256-vS03Uy5fRRCGNW+KdCPHSw2QeIyvxTqrO7JK7p5RbCY=";
          };
        };
      };
    };
  };
}
