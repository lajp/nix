{ lib, config, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.uptime-kuma;
in
{
  options.lajp.services.uptime-kuma.enable = mkEnableOption "Enable Uptime Kuma";

  config = mkIf cfg.enable {
    services.uptime-kuma = {
      enable = true;
      settings.PORT = "4000";
    };

    services.nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;

      virtualHosts."status.lajp.fi" = {
        locations."/".proxyPass = "http://localhost:4000";
        forceSSL = true;
        enableACME = true;
      };
    };

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
