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
  cfg = config.lajp.services.crabfit;
in
{
  options.lajp.services.crabfit.enable = mkEnableOption "Enable crabfit";

  config = mkIf (cfg.enable) {
    lajp.services.nginx.enable = true;

    services = {
      crabfit = {
        enable = true;
        api.host = "api.fit.lajp.fi";
        api.port = 2942;

        frontend.host = "fit.lajp.fi";
        frontend.port = 2941;
      };

      nginx.virtualHosts = {
        "${config.services.crabfit.api.host}" = {
          forceSSL = true;
          enableACME = true;

          locations."/".proxyPass = "http://localhost:${toString config.services.crabfit.api.port}";
        };

        "${config.services.crabfit.frontend.host}" = {
          forceSSL = true;
          enableACME = true;

          locations."/".proxyPass = "http://localhost:${toString config.services.crabfit.frontend.port}";
        };
      };
    };
  };
}
