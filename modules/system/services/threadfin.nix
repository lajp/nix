{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.threadfin;
  port = config.lajp.ports.threadfin;
in
{
  options.lajp.services.threadfin.enable = mkEnableOption "Enable Threadfin";
  config = mkIf cfg.enable {
    lajp.portRequests.threadfin = true;

    lajp.virtualisation.podman.enable = true;
    virtualisation.oci-containers = {
      backend = "podman";
      containers.threadfin = {
        image = "fyb3roptik/threadfin:latest";
        ports = [ "${toString port}:34400" ];
        environment.TZ = "Europe/Helsinki";
      };
    };
  };
}
