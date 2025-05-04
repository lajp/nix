{ lib, config, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.lajp.services.headscale;
in
{
  options.lajp.services.headscale.enable = mkEnableOption "Enable headscale";

  config = mkIf cfg.enable {
    services = {
      headscale = {
        enable = true;
        address = "0.0.0.0";
        port = 8081;

        settings = {
          server_url = "https://headscale.lajp.fi";
          logtail.enabled = false;
          dns.base_domain = "tailnet.lajp.fi";
        };
      };

      nginx = {
        enable = true;
        virtualHosts."headscale.lajp.fi" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://localhost:${toString config.services.headscale.port}";
            proxyWebsockets = true;
          };
        };
      };
    };

    environment.systemPackages = [ config.services.headscale.package ];

    security.acme = {
      acceptTerms = true;
      defaults.email = "lajp@iki.fi";
    };

    networking.firewall.allowedTCPPorts = [
      80
      443
    ];
  };
}
