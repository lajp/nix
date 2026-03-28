{ config, lib, ... }:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.lajp.services.prometheus;
  cfgGrafana = config.lajp.services.grafana;
  prometheusPort = config.lajp.ports.prometheus;
  grafanaPort = config.lajp.ports.grafana;
in
{
  options.lajp.services.prometheus = {
    enable = mkEnableOption "Enable prometheus metrics";
    central = mkOption {
      type = types.bool;
      default = config.networking.hostName == "ankka";
      description = "Whether this node is the central Prometheus node aggregating data from others.";
    };
    role = mkOption {
      type = types.str;
      default = "server";
      description = "Role label for this node (e.g., nas, proxy, server)";
    };
    location = mkOption {
      type = types.str;
      default = "jmt";
      description = "Location label for this node";
    };
  };

  options.lajp.services.grafana.enable = mkEnableOption "Enable grafana";

  config = mkIf cfg.enable {
    # NOTE: this port is relied on by the agent exporters, it must be statically allocated
    lajp.portRequests.prometheus = 9090;
    lajp.portRequests.grafana = lib.mkIf cfgGrafana.enable true;

    # Auto-enable grafana when prometheus is central
    lajp.services.grafana.enable = lib.mkDefault cfg.central;

    services.grafana = mkIf cfgGrafana.enable {
      enable = true;
      settings = {
        server = {
          http_addr = "127.0.0.1";
          http_port = grafanaPort;
          root_url = "https://grafana.lajp.fi";
          enforce_domain = true;
          enable_gzip = true;
          domain = "grafana.lajp.fi";
        };
        analytics.reporting_enabled = false;
      };

      provision = {
        datasources.settings = {
          deleteDatasources = [
            { name = "Prometheus"; orgId = 1; }
          ];
          datasources = [
            {
              name = "Prometheus";
              type = "prometheus";
              uid = "prometheus";
              url = "http://${config.services.prometheus.listenAddress}:${toString config.services.prometheus.port}";
              isDefault = true;
              editable = false;
            }
          ];
        };

        dashboards.settings.providers = [
          {
            name = "nixos";
            folder = "NixOS";
            type = "file";
            options.path = ./dashboards;
          }
        ];
      };
    };

    # TODO: change this to grafana.intra.lajp.fi
    services.nginx = mkIf cfgGrafana.enable {
      virtualHosts."grafana.lajp.fi" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://${toString config.services.grafana.settings.server.http_addr}:${toString config.services.grafana.settings.server.http_port}";
          proxyWebsockets = true;
          recommendedProxySettings = true;
        };
      };
    };

    # Open firewall for Prometheus only on VPN interface, only on central node
    networking.firewall.interfaces."tailscale0".allowedTCPPorts = mkIf cfg.central [
      prometheusPort
    ];

    services.prometheus = {
      enable = true;
      globalConfig.scrape_interval = "10s";
      port = prometheusPort;
      listenAddress = if cfg.central then "0.0.0.0" else "127.0.0.1";
      extraFlags = lib.optionals cfg.central [ "--web.enable-remote-write-receiver" ];
      enableAgentMode = !cfg.central;

      # Push metrics to central node if we are NOT the central node
      remoteWrite = mkIf (!cfg.central) [
        {
          # TODO: use hostname
          url = "http://100.64.0.4:9090/api/v1/write";
          write_relabel_configs = [
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
        {
          job_name = "nginx";
          static_configs = [
            {
              targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.nginx.port}" ];
            }
          ];
        }
      ]
      ++ lib.optionals config.services.prometheus.exporters.apcupsd.enable [
        {
          job_name = "apcupsd";
          static_configs = [
            {
              targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.apcupsd.port}" ];
            }
          ];
        }
      ]
      ++ lib.optionals config.services.prometheus.exporters.smartctl.enable [
        {
          job_name = "smartctl";
          static_configs = [
            {
              targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.smartctl.port}" ];
            }
          ];
        }
      ]
      ++ lib.optionals config.services.prometheus.exporters.nvidia-gpu.enable [
        {
          job_name = "nvidia_gpu";
          static_configs = [
            {
              targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.nvidia-gpu.port}" ];
            }
          ];
        }
      ]
      ++ lib.optionals config.services.prometheus.exporters.nginxlog.enable [
        {
          job_name = "nginxlog";
          static_configs = [
            {
              targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.nginxlog.port}" ];
            }
          ];
        }
      ]
      ++ lib.optionals config.services.prometheus.exporters.zfs.enable [
        {
          job_name = "zfs";
          static_configs = [
            {
              targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.zfs.port}" ];
            }
          ];
        }
      ]
      ++ lib.optionals config.services.prometheus.exporters.exportarr-sonarr.enable [
        {
          job_name = "exportarr-sonarr";
          static_configs = [
            {
              targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.exportarr-sonarr.port}" ];
            }
          ];
        }
      ]
      ++ lib.optionals config.services.prometheus.exporters.exportarr-radarr.enable [
        {
          job_name = "exportarr-radarr";
          static_configs = [
            {
              targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.exportarr-radarr.port}" ];
            }
          ];
        }
      ]
      ++ lib.optionals config.services.prometheus.exporters.exportarr-prowlarr.enable [
        {
          job_name = "exportarr-prowlarr";
          static_configs = [
            {
              targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.exportarr-prowlarr.port}" ];
            }
          ];
        }
      ]
      ++ lib.optionals config.services.prometheus.exporters.dovecot.enable [
        {
          job_name = "dovecot";
          static_configs = [
            {
              targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.dovecot.port}" ];
            }
          ];
        }
      ]
      ++ lib.optionals config.services.prometheus.exporters.rspamd.enable [
        {
          job_name = "rspamd";
          metrics_path = "/probe";
          params = {
            target = [ "http://127.0.0.1:11334/stat" ];
          };
          static_configs = [
            {
              targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.rspamd.port}" ];
            }
          ];
        }
      ]
      ++ lib.optionals config.services.prometheus.exporters.postfix.enable [
        {
          job_name = "postfix";
          static_configs = [
            {
              targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.postfix.port}" ];
            }
          ];
        }
      ]
      ++ lib.optionals config.services.hedgedoc.enable [
        {
          job_name = "hedgedoc";
          static_configs = [
            {
              targets = [ "127.0.0.1:${toString config.services.hedgedoc.settings.port}" ];
            }
          ];
          metrics_path = "/metrics";
        }
      ];

      exporters = {
        node = {
          enable = true;

          enabledCollectors = [
            "cpu"
            "loadavg"
            "meminfo"
            "filesystem"
            "diskstats"
            "netdev"
            "netstat"
            "time"
            "uname"
            "vmstat"
            "stat"
            "processes"
            "systemd"
            "pressure"
          ]
          ++ lib.optionals (config.networking.hostName == "nas") [
            "hwmon"
            "zfs"
          ];

          extraFlags = [
            "--collector.filesystem.mount-points-exclude=^/(nix|proc|sys|dev|run)($|/)"
            "--collector.filesystem.fs-types-exclude=^(tmpfs|overlay|squashfs|nsfs|cgroup2?)$"
          ];
        };
      };
    };
  };
}
