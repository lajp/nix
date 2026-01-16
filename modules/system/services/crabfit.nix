{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    ;
  cfg-api = config.lajp.services.crabfit-api;
  cfg-frontend = config.lajp.services.crabfit-frontend;
  apiPort = config.lajp.ports.crabfit-api;
  frontendPort = config.lajp.ports.crabfit-frontend;
in
{
  options.lajp.services.crabfit-api.enable = mkEnableOption "Enable crabfit API";
  options.lajp.services.crabfit-frontend.enable = mkEnableOption "Enable crabfit frontend";

  config = mkIf (cfg-api.enable || cfg-frontend.enable) {
    lajp.portRequests.crabfit-api = true;
    lajp.portRequests.crabfit-frontend = true;
    lajp.services.nginx.enable = true;

    services = {
      crabfit = {
        enable = true;
        api.host = "api.fit.lajp.fi";
        api.port = apiPort;

        frontend.host = "fit.lajp.fi";
        frontend.port = frontendPort;
      };

      nginx.virtualHosts = {
        "${config.services.crabfit.api.host}" = mkIf cfg-api.enable {
          forceSSL = true;
          enableACME = true;

          locations."/".proxyPass = "http://localhost:${toString config.services.crabfit.api.port}";
        };

        "${config.services.crabfit.frontend.host}" = mkIf cfg-frontend.enable {
          forceSSL = true;
          enableACME = true;

          locations."/".proxyPass = "http://localhost:${toString config.services.crabfit.frontend.port}";
        };
      };
    };
  };
}
