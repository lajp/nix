{
  lib,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.threadfin;
in {
  options.lajp.services.threadfin.enable = mkEnableOption "Enable Threadfin";
  config = mkIf cfg.enable {
    lajp.virtualisation.podman.enable = true;
    virtualisation.oci-containers = {
      backend = "podman";
      containers.threadfin = {
        image = "fyb3roptik/threadfin:latest";
        ports = ["34400:34400"];
        environment.TZ = "Europe/Helsinki";
      };
    };
  };
}
