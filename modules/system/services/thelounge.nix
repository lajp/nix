{ lib, config, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.thelounge;
  port = config.lajp.ports.thelounge;
in
{
  options.lajp.services.thelounge.enable = mkEnableOption "Enable The Lounge";

  config = mkIf cfg.enable {
    lajp.portRequests.thelounge = true;
    lajp.services.nginx.enable = true;

    services = {
      thelounge = {
        inherit port;
        enable = true;
        public = false;
      };

      nginx.virtualHosts."thelounge.lajp.fi" = {
        forceSSL = true;
        enableACME = true;

        locations."/" = {
          proxyPass = "http://localhost:${toString port}";
        };
      };
    };
  };
}
