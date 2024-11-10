{
  lib,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.jellyfin;
in {
  options.lajp.services.jellyfin.enable = mkEnableOption "Enable jellyfin";
  config = mkIf cfg.enable {
    hardware.opengl.enable = true;

    services.jellyfin = {
      enable = true;
    };

    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;

      virtualHosts."jellyfin.lajp.fi" = {
        forceSSL = true;
        enableACME = true;

        locations."/" = {
          proxyPass = "http://localhost:8096";
          proxyWebsockets = true;
        };
      };
    };

    security.acme = {
      acceptTerms = true;
      defaults.email = "lajp@iki.fi";
    };

    networking.firewall.allowedTCPPorts = [80 443];
  };
}
