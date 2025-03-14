{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf mkOption;
  cfg = config.lajp.services.cross-seed;
  transmissionHome = config.services.transmission.home;
in
{
  options.lajp.services.cross-seed = {
    enable = mkEnableOption "Enable cross-seed";
    dataDir = mkOption {
      default = "/var/lib/cross-seed";
      type = lib.types.str;
    };
  };

  config = mkIf cfg.enable {
    lajp.virtualisation.podman.enable = true;

    age.secrets.cross-seed.file = ../../../secrets/cross-seed.age;

    system.activationScripts.symlinkCrossSeedConfig = ''
      mkdir -p ${cfg.dataDir}
      cp -f ${config.age.secrets.cross-seed.path} ${cfg.dataDir}/config.js
    '';

    virtualisation.oci-containers = {
      backend = "podman";
      containers.cross-seed = {
        image = "ghcr.io/cross-seed/cross-seed";
        autoStart = true;
        ports = [ "2468:2468" ];
        volumes = [
          "${cfg.dataDir}:/config"
          "${transmissionHome}/.config/transmission-daemon/torrents:/torrents:ro"
        ];
        cmd = [ "daemon" ];

        extraOptions = [
          "--network=host"
        ];
      };
    };
  };
}
