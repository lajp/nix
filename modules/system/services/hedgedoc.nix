{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.lajp.services.hedgedoc;
in
{
  options.lajp.services.hedgedoc.enable = mkEnableOption "Enable hedgedoc";

  config = mkIf cfg.enable {
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
        domain = "pad.lajp.fi";
        host = "localhost";
        port = 3004;
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
        proxyPass = "http://localhost:3004";
        proxyWebsockets = true;
      };
    };
  };
}
