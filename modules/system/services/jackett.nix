{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.jackett;
in
{
  options.lajp.services.jackett.enable = mkEnableOption "Enable jackett";
  config = mkIf cfg.enable {
    services.jackett.enable = true;

    lajp.virtualisation.podman.enable = true;
    virtualisation.oci-containers = {
      backend = "podman";
      containers.flaresolverr = {
        image = "ghcr.io/flaresolverr/flaresolverr:latest";
        hostname = "flaresolverr";
        ports = [ "8191:8191" ];
        environment.LOG_LEVEL = "info";
      };
    };
  };
}
