{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.lajp.services.hedgedoc;
  port = config.lajp.ports.hedgedoc;
in
{
  options.lajp.services.hedgedoc.enable = mkEnableOption "Enable hedgedoc";

  config = mkIf cfg.enable {
    lajp.portRequests.hedgedoc = true;
    lajp.services.nginx.enable = true;

    services.postgresql = {
      enable = true;
      ensureDatabases = [ "hedgedoc" ];
      ensureUsers = [
        {
          name = "hedgedoc";
          ensureDBOwnership = true;
        }
      ];
    };

    services.hedgedoc = {
      enable = true;
      settings = {
        inherit port;

        domain = "pad.lajp.fi";
        host = "127.0.0.1";
        protocolUseSSL = true;
        db = {
          dialect = "postgres";
          host = "/run/postgresql";
          database = "hedgedoc";
          username = "hedgedoc";
        };
        allowAnonymous = true;
        allowAnonymousEdits = true;
        email = false;
        allowEmailRegister = true;
      };
    };

    services.nginx.virtualHosts."pad.lajp.fi" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://localhost:${toString port}";
        proxyWebsockets = true;
      };
      locations."/metrics" = {
        return = "404";
      };
    };
  };
}
