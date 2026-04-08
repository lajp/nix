{ lib, config, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.lajp.services.headscale;
  port = config.lajp.ports.headscale;
in
{
  options.lajp.services.headscale.enable = mkEnableOption "Enable headscale";

  config = mkIf cfg.enable {
    lajp.portRequests.headscale = true;
    lajp.portRequests.headscale-metrics = true;
    lajp.services.nginx.enable = true;

    services = {
      headscale = {
        enable = true;
        address = "0.0.0.0";
        port = port;

        settings = {
          server_url = "https://headscale.lajp.fi";
          metrics_listen_addr = "127.0.0.1:${toString config.lajp.ports.headscale-metrics}";
          logtail.enabled = false;
          dns = {
            base_domain = "tailnet.lajp.fi";
            nameservers.global = [
              "100.64.0.3"
              "1.1.1.1"
              "8.8.8.8"
            ];
          };
        };
      };

      nginx.virtualHosts."headscale.lajp.fi" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://localhost:${toString config.services.headscale.port}";
          proxyWebsockets = true;
        };
      };
    };

    environment.systemPackages = [ config.services.headscale.package ];
  };
}
