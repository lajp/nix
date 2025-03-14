{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.vaultwarden;
in
{
  options.lajp.services.vaultwarden.enable = mkEnableOption "Enable vaultwarden";
  config = mkIf cfg.enable {
    services.vaultwarden = {
      enable = true;
      config = {
        ROCKET_ADDRESS = "127.0.0.1";
        ROCKET_PORT = "8222";
      };
    };

    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;

      virtualHosts."vaultwarden.lajp.fi" = {
        locations."/" = {
          enableACME = true;
          forceSSL = true;
          proxyPass = "http://localhost:${config.services.vaultwarden.config.ROCKET_PORT}";
          proxyWebsockets = true;
        };
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
