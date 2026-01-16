{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.tvheadend;
  port = config.lajp.ports.tvheadend;
in
{
  options.lajp.services.tvheadend.enable = mkEnableOption "Enable tvheadend";
  config = mkIf cfg.enable {
    lajp.portRequests.tvheadend = true;

    lajp.virtualisation.podman.enable = true;
    virtualisation.oci-containers = {
      backend = "podman";
      containers.tvheadend = {
        image = "lscr.io/linuxserver/tvheadend:latest";
        ports = [ "${toString port}:9981" ];
        environment.TZ = "Europe/Helsinki";
      };
    };
    services.tvheadend.enable = true;
    networking.firewall.allowedTCPPorts = [ port ];
  };
}
