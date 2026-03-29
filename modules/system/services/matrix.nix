{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf mkOption types;
  cfg = config.lajp.services.matrix;
  port = config.lajp.ports.matrix;
  metricsPort = config.lajp.ports.matrix-metrics;

  serverDomain = "lajp.fi";
  matrixDomain = "matrix.lajp.fi";
  elementDomain = "element.lajp.fi";

  wellKnownServer = builtins.toJSON {
    "m.server" = "${matrixDomain}:443";
  };

  wellKnownClient = builtins.toJSON {
    "m.homeserver" = {
      "base_url" = "https://${matrixDomain}";
    };
  };
in
{
  options.lajp.services.matrix = {
    enable = mkEnableOption "Enable Matrix homeserver (Synapse)";
    element.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Element Web client at ${elementDomain}";
    };
  };

  config = mkIf cfg.enable {
    lajp.portRequests.matrix = true;
    lajp.portRequests.matrix-metrics = true;
    lajp.services.nginx.enable = true;

    age.secrets.matrix-shared-secret = {
      rekeyFile = ../../../secrets/matrix-shared-secret.age;
      mode = "0400";
      owner = "matrix-synapse";
      group = "matrix-synapse";
    };

    services.postgresql = {
      enable = true;
      initialScript = pkgs.writeText "synapse-init.sql" ''
        CREATE ROLE "matrix-synapse" WITH LOGIN;
        CREATE DATABASE "matrix-synapse"
          WITH OWNER "matrix-synapse"
          TEMPLATE template0
          LC_COLLATE = "C"
          LC_CTYPE = "C"
          ENCODING 'UTF8';
      '';
    };

    services.matrix-synapse = {
      enable = true;
      settings = {
        server_name = serverDomain;

        listeners = [
          {
            port = port;
            bind_addresses = [ "127.0.0.1" ];
            type = "http";
            tls = false;
            x_forwarded = true;
            resources = [
              {
                names = [ "client" "federation" ];
                compress = true;
              }
            ];
          }
          {
            port = metricsPort;
            bind_addresses = [ "127.0.0.1" ];
            type = "metrics";
            tls = false;
            resources = [ ];
          }
        ];

        database = {
          name = "psycopg2";
          args = {
            host = "/run/postgresql";
            database = "matrix-synapse";
            user = "matrix-synapse";
          };
        };

        enable_registration = false;
        registration_shared_secret_path = config.age.secrets.matrix-shared-secret.path;

        max_upload_size = "20M";

        enable_metrics = true;

        trusted_key_servers = [
          { server_name = "matrix.org"; }
        ];

        url_preview_enabled = true;
        url_preview_ip_range_blacklist = [
          "127.0.0.0/8"
          "10.0.0.0/8"
          "172.16.0.0/12"
          "192.168.0.0/16"
          "100.64.0.0/10"
          "169.254.0.0/16"
          "::1/128"
          "fe80::/10"
          "fc00::/7"
        ];
      };
    };

    # Reverse proxy for the Matrix server
    services.nginx.virtualHosts.${matrixDomain} = {
      forceSSL = true;
      enableACME = true;

      extraConfig = ''
        client_max_body_size 20M;
      '';

      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString port}";
        proxyWebsockets = true;
      };
    };

    # .well-known delegation on the root domain (merges into existing lajp.fi vhost)
    services.nginx.virtualHosts.${serverDomain}.locations = {
      "= /.well-known/matrix/server" = {
        extraConfig = ''
          default_type application/json;
          add_header Access-Control-Allow-Origin *;
          return 200 '${wellKnownServer}';
        '';
      };
      "= /.well-known/matrix/client" = {
        extraConfig = ''
          default_type application/json;
          add_header Access-Control-Allow-Origin *;
          return 200 '${wellKnownClient}';
        '';
      };
    };

    # Element Web client
    services.nginx.virtualHosts.${elementDomain} = mkIf cfg.element.enable {
      forceSSL = true;
      enableACME = true;
      root = pkgs.element-web.override {
        conf = {
          default_server_config = {
            "m.homeserver" = {
              base_url = "https://${matrixDomain}";
              server_name = serverDomain;
            };
          };
          disable_3pid_login = true;
          disable_guests = true;
        };
      };
    };
  };
}
