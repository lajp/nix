{ pkgs, lib, config, ...}: let
  inherit (lib) mkIf;
  inherit (config.lajp.core) server;
in {
  config = mkIf (!server) {
    environment.systemPackages = with pkgs; [
      dmenu
    ];

    # TODO: package lajp/blmgr
    programs.light.enable = true;

    services.xserver = {
      enable = true;

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
            sha256 = "+RZyMkRrSzFHXVP2hHGrdf/+CX4NQNhEZxvdWGm75u0=";
          };
        };
      };
    };
  };
}
