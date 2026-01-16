{
  lib,
  config,
  pkgs-unstable,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.jackett;
  flaresolverrPort = config.lajp.ports.flaresolverr;
in
{
  options.lajp.services.jackett.enable = mkEnableOption "Enable jackett";
  config = mkIf cfg.enable {
    lajp.portRequests.flaresolverr = true;

    services.jackett = {
      enable = true;
      # NOTE: https://github.com/NixOS/nixpkgs/issues/371837
      package = pkgs-unstable.jackett;
    };

    lajp.virtualisation.podman.enable = true;
    virtualisation.oci-containers = {
      backend = "podman";
      containers.flaresolverr = {
        image = "ghcr.io/flaresolverr/flaresolverr:latest";
        hostname = "flaresolverr";
        ports = [ "${toString flaresolverrPort}:8191" ];
        environment.LOG_LEVEL = "info";
      };
    };
  };
}
