{ lib, config, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.uptime-kuma;
  port = config.lajp.ports.uptime-kuma;
in
{
  options.lajp.services.uptime-kuma.enable = mkEnableOption "Enable Uptime Kuma";

  config = mkIf cfg.enable {
    lajp.portRequests.uptime-kuma = true;
    lajp.services.nginx.enable = true;

    services = {
      uptime-kuma = {
        enable = true;
        settings.PORT = toString port;
      };

      nginx.virtualHosts."status.lajp.fi" = {
        locations."/".proxyPass = "http://localhost:${toString port}";
        forceSSL = true;
        enableACME = true;
      };
    };
  };
}
