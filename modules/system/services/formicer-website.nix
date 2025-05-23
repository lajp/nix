{ lib, config, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.formicer-website;
in
{
  options.lajp.services.formicer-website.enable = mkEnableOption "Enable formicer website";

  config = mkIf cfg.enable {
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
      ports = [ "127.0.0.1:8080:8080" ];
    };

    services.nginx.virtualHosts."formicer.com" = {
      locations."/".proxyPass = "http://localhost:8080";
      forceSSL = true;
      enableACME = true;
    };
  };
}
