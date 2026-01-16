{ lib, config, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.formicer-website;
  port = config.lajp.ports.formicer-website;
in
{
  options.lajp.services.formicer-website.enable = mkEnableOption "Enable formicer website";

  config = mkIf cfg.enable {
    lajp.portRequests.formicer-website = true;
    lajp.services.nginx.enable = true;

    lajp.virtualisation.podman.enable = true;

    age.secrets.ghcr-token.rekeyFile = ../../../secrets/ghcr-token.age;

    virtualisation.oci-containers.containers.formicer = {
      login = {
        username = "lajp";
        registry = "ghcr.io";
        passwordFile = config.age.secrets.ghcr-token.path;
      };
      image = "ghcr.io/formicer/formicer.com";
      ports = [ "127.0.0.1:${toString port}:8080" ];
    };

    services.nginx.virtualHosts."formicer.com" = {
      locations."/".proxyPass = "http://localhost:${toString port}";
      forceSSL = true;
      enableACME = true;
    };
  };
}
