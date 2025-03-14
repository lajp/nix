{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.xserver;
in
{
  options.lajp.services.xserver.enable = mkEnableOption "Enable X and DWM";
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      dmenu
      # for volume control through pactl
      pulseaudio
    ];

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
          src = inputs.dwm;
        };
      };
    };
  };
}
