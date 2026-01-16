{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.jellyfin;
  port = config.lajp.ports.jellyfin;
in
{
  options.lajp.services.jellyfin.enable = mkEnableOption "Enable jellyfin";

  config = mkIf cfg.enable {
    lajp.portRequests.jellyfin = true;
    lajp.services.nginx.enable = true;

    hardware.graphics.enable = true;

    services = {
      jellyfin.enable = true;

      nginx.virtualHosts."jellyfin.lajp.fi" = {
        forceSSL = true;
        enableACME = true;

        locations."/" = {
          # Note: Jellyfin listens on the port specified in its settings,
          # not configurable via NixOS module. Ensure port matches Jellyfin config.
          proxyPass = "http://localhost:${toString port}";
          proxyWebsockets = true;
        };
      };
    };
  };
}
