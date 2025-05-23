{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.jellyfin;
in
{
  options.lajp.services.jellyfin.enable = mkEnableOption "Enable jellyfin";

  config = mkIf cfg.enable {
    lajp.services.nginx.enable = true;

    hardware.graphics.enable = true;

    services = {
      jellyfin.enable = true;

      nginx.virtualHosts."jellyfin.lajp.fi" = {
        forceSSL = true;
        enableACME = true;

        locations."/" = {
          proxyPass = "http://localhost:8096";
          proxyWebsockets = true;
        };
      };
    };
  };
}
