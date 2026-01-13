{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.resourceLimits;
in
{
  options.lajp.services.resourceLimits = {
    enable = mkEnableOption "conservative memory limits for services";
  };

  config = mkIf cfg.enable {
    # High memory consumers - generous limits to catch runaways
    systemd.services.jellyfin.serviceConfig = {
      MemoryMax = "6G";
      MemoryHigh = "5G";
    };

    systemd.services.transmission.serviceConfig = {
      MemoryMax = "2G";
      MemoryHigh = "1536M";
    };

    # Arr stack
    systemd.services.radarr.serviceConfig = {
      MemoryMax = "1G";
      MemoryHigh = "768M";
    };

    systemd.services.sonarr.serviceConfig = {
      MemoryMax = "1G";
      MemoryHigh = "768M";
    };

    systemd.services.lidarr.serviceConfig = {
      MemoryMax = "1G";
      MemoryHigh = "768M";
    };

    systemd.services.prowlarr.serviceConfig = {
      MemoryMax = "512M";
      MemoryHigh = "384M";
    };

    systemd.services.bazarr.serviceConfig = {
      MemoryMax = "512M";
      MemoryHigh = "384M";
    };

    systemd.services.jellyseerr.serviceConfig = {
      MemoryMax = "1G";
      MemoryHigh = "768M";
    };

    # Other services
    systemd.services.prometheus.serviceConfig = {
      MemoryMax = "2G";
      MemoryHigh = "1536M";
    };

    systemd.services.syncthing.serviceConfig = {
      MemoryMax = "1G";
      MemoryHigh = "768M";
    };

    systemd.services.vaultwarden.serviceConfig = {
      MemoryMax = "256M";
      MemoryHigh = "192M";
    };
  };
}
