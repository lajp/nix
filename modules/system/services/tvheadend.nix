{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.tvheadend;
in
{
  options.lajp.services.tvheadend.enable = mkEnableOption "Enable tvheadend";
  config = mkIf cfg.enable {
    lajp.virtualisation.podman.enable = true;
    virtualisation.oci-containers = {
      backend = "podman";
      containers.tvheadend = {
        image = "lscr.io/linuxserver/tvheadend:latest";
        ports = [ "9981:9981" ];
        environment.TZ = "Europe/Helsinki";
      };
    };
    services.tvheadend.enable = true;
    networking.firewall.allowedTCPPorts = [ 9981 ];
  };
}
