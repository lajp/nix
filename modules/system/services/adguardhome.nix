{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.adguardhome;
  webPort = config.lajp.ports.adguardhome;
in
{
  options.lajp.services.adguardhome.enable = mkEnableOption "Enable adguardhome";

  config = mkIf cfg.enable {
    lajp.portRequests.adguardhome = true;

    services.adguardhome = {
      enable = true;
      mutableSettings = true;
      openFirewall = false;

      settings = {
        http.address = "127.0.0.1:${toString webPort}";
        dns = {
          bind_hosts = [ "0.0.0.0" ];
          port = 53;
          upstream_dns = [
            "1.1.1.1"
            "8.8.8.8"
          ];
          bootstrap_dns = [
            "1.1.1.1"
            "8.8.8.8"
          ];
          ratelimit = 0;
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ 53 ];
    networking.firewall.allowedUDPPorts = [ 53 ];
  };
}
