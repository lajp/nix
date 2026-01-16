{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.vaultwarden;
  port = config.lajp.ports.vaultwarden;
in
{
  options.lajp.services.vaultwarden.enable = mkEnableOption "Enable vaultwarden";
  config = mkIf cfg.enable {
    # NOTE: hard coded since the proxy is on proxy-pi
    lajp.portRequests.vaultwarden = 8222;
    services.vaultwarden = {
      enable = true;
      config = {
        ROCKET_ADDRESS = "0.0.0.0";
        ROCKET_PORT = toString port;
      };
      backupDir = "/media/luukas/Backups/vaultwarden";
    };

    networking.firewall.allowedTCPPorts = [
      port
    ];
  };
}
