{ lib, config, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.uptime-kuma;
in
{
  options.lajp.services.uptime-kuma.enable = mkEnableOption "Enable Uptime Kuma";

  config = mkIf cfg.enable {
    lajp.services.nginx.enable = true;

    services = {
      uptime-kuma = {
        enable = true;
        settings.PORT = "4000";
      };

      nginx.virtualHosts."status.lajp.fi" = {
        locations."/".proxyPass = "http://localhost:${toString config.services.update-kuma.settings.PORT}";
        forceSSL = true;
        enableACME = true;
      };
    };
  };
}
