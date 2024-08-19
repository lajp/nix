{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.syncthing;
in {
  options.lajp.services.syncthing.enable = mkEnableOption "Enable syncthing";
  config = mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      user = config.lajp.user.username;
      dataDir = "/media/luukas/Backups/syncthing";
      guiAddress = "0.0.0.0:8384";
    };

    networking.firewall.allowedTCPPorts = [8384 22000];
    networking.firewall.allowedUDPPorts = [22000 21027];
  };
}
