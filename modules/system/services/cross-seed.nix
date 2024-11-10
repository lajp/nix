{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption;
  cfg = config.lajp.services.cross-seed;

  inherit (config.services.transmission.settings) rpc-port;
  transmissionHome = config.services.transmission.home;

  configFile = pkgs.writeText "config.js" ''
    import { torznab } from "${config.age.cross-seed.path}"
    module.exports = {
      torznab: torznab,
      torrentDir: "/torrents",
      outputDir: "/cross-seed",

      transmissionRpcUrl: "http://127.0.0.1:${toString rpc-port}/transmission/rpc",
      action: "inject",

      includeNonVideos: true,
      includeEpisodes: true,
      includeSingleEpisodes: true,

      delay: 30,
      rssCadence: "10 minutes",
      searchCadence: "1 weeks",
    }
  '';
in {
  options.lajp.services.cross-seed = {
    enable = mkEnableOption "Enable cross-seed";
    dataDir = mkOption {
      default = "/var/lib/cross-seed";
      type = lib.types.str;
    };
  };
  config = mkIf cfg.enable {
    lajp.virtualisation.podman.enable = true;

    age.secrets.pia.file = ../../../secrets/cross-seed.age;

    system.activationScripts.symlinkCrossSeedConfig = ''
      mkdir -p ${cfg.dataDir}
      cp -f ${configFile} ${cfg.dataDir}/config.js
    '';

    virtualisation.oci-containers = {
      backend = "podman";
      containers.cross-seed = {
        image = "ghcr.io/cross-seed/cross-seed";
        autoStart = true;
        ports = ["2468:2468"];
        volumes = [
          "${cfg.dataDir}:/config"
          #"${watchDir}:/cross-seed"
          "${transmissionHome}/.config/transmission-daemon/torrents:/torrents:ro"
        ];
        cmd = ["daemon"];

        extraOptions = [
          "--network=host"
        ];
      };
    };
  };
}
