{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.syncthing;
  guiPort = config.lajp.ports.syncthing;
in
{
  options.lajp.services.syncthing.enable = mkEnableOption "Enable syncthing";
  config = mkIf cfg.enable {
    lajp.portRequests.syncthing = true;

    services.syncthing = {
      enable = true;
      user = config.lajp.user.username;
      dataDir = "/media/luukas/Backups/syncthing";
      guiAddress = "0.0.0.0:${toString guiPort}";
    };

    networking.firewall.allowedTCPPorts = [
      guiPort
      22000 # Syncthing protocol (fixed)
    ];
    networking.firewall.allowedUDPPorts = [
      22000 # Syncthing protocol (fixed)
      21027 # Syncthing discovery (fixed)
    ];
  };
}
