{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.slop;
  port = config.lajp.ports.slop;
in
{
  options.lajp.services.slop.enable = mkEnableOption "Enable slop";

  config = mkIf cfg.enable {
    lajp.portRequests.slop = 12345;
    lajp.services.nginx.enable = true;
    virtualisation.docker.enable = true;

    age.secrets.slop-htpasswd = {
      rekeyFile = ../../../secrets/slop-htpasswd.age;
      owner = "nginx";
      group = "nginx";
      mode = "0400";
    };

    services.nginx.virtualHosts."slop.lajp.fi" = {
      forceSSL = true;
      enableACME = true;
      basicAuthFile = config.age.secrets.slop-htpasswd.path;

      locations."/" = {
        proxyPass = "http://localhost:${toString port}";
        proxyWebsockets = true;
      };
    };
  };
}
