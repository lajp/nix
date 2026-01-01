{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf mkOption types;
  cfg = config.lajp.services.monitoring-agent;
in
{
  options.lajp.services.monitoring-agent = {
    enable = mkEnableOption "Enable prometheus monitoring agent";
    centralHost = mkOption {
      type = types.str;
      default = "http://ankka.tailnet.lajp.fi:9090/api/v1/write";
      description = "URL of the central Prometheus remote write receiver";
    };
    role = mkOption {
      type = types.str;
      default = "server"; # Default role
      description = "Role label for this node (e.g., nas, proxy, server)";
    };
    location = mkOption {
      type = types.str;
      default = "jmt"; # Default location
      description = "Location label for this node";
    };
  };

  config = mkIf cfg.enable {
    services.prometheus = {
      enable = true;
      globalConfig.scrape_interval = "10s";

      remoteWrite = [
        {
          url = cfg.centralHost;
          write_relabel_configs = [
            # Ensure we attach useful labels to all metrics pushed
            {
              target_label = "host";
              replacement = config.networking.hostName;
            }
            {
              target_label = "role";
              replacement = cfg.role;
            }
            {
              target_label = "location";
              replacement = cfg.location;
            }
          ];
        }
      ];

      scrapeConfigs = [
        # Scrape Local Node Exporter
        {
          job_name = "node";
          static_configs = [
            {
              targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
            }
          ];
        }
      ] 
      ++ lib.optionals config.services.prometheus.exporters.nginx.enable [
        # Scrape Local Nginx if enabled
        {
          job_name = "nginx";
          static_configs = [
            {
              targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.nginx.port}" ];
            }
          ];
        }
      ];

      # Ensure standard exporters are configured if not already
      exporters = {
        node = {
          enable = true;
          enabledCollectors = [
            "cpu" "loadavg" "meminfo" "filesystem" "diskstats"
            "netdev" "netstat" "time" "uname" "vmstat" "stat"
            "processes" "systemd" "pressure"
          ] ++ lib.optionals (config.networking.hostName == "nas") [ "hwmon" "zfs" ];
          
          extraFlags = [
            "--collector.filesystem.mount-points-exclude=^/(nix|proc|sys|dev|run)($|/)"
            "--collector.filesystem.fs-types-exclude=^(tmpfs|overlay|squashfs|nsfs|cgroup2?)$"
          ];
        };
      };
    };
  };
}
