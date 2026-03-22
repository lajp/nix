{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.lajp.services.attic;
  port = config.lajp.ports.attic;
in
{
  options.lajp.services.attic.enable = mkEnableOption "Enable attic binary cache";

  config = mkIf cfg.enable {
    lajp.portRequests.attic = true;
    lajp.services.nginx.enable = true;

    age.secrets.attic-server-token.rekeyFile = ../../../secrets/attic-server-token.age;

    services.atticd = {
      enable = true;
      environmentFile = config.age.secrets.attic-server-token.path;
      settings = {
        listen = "[::]:${toString port}";
        database.url = "sqlite:///var/lib/atticd/server.db?mode=rwc";
        storage = {
          type = "local";
          path = "/var/lib/atticd/storage";
        };
        chunking = {
          nar-size-threshold = 65536; # 64 KiB
          min-size = 16384; # 16 KiB
          avg-size = 65536; # 64 KiB
          max-size = 262144; # 256 KiB
        };
        garbage-collection = {
          interval = "12 hours";
          default-retention-period = "3 months";
        };
      };
    };

    services.nginx.virtualHosts."cache.lajp.fi" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://localhost:${toString port}";
        extraConfig = ''
          client_max_body_size 0;
        '';
      };
    };
  };
}
