{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.open-webui;
  port = config.lajp.ports.open-webui;
in
{
  options.lajp.services.open-webui.enable = mkEnableOption "Enable open-webui";

  config = mkIf cfg.enable {
    lajp.portRequests.open-webui = true;
    lajp.services.nginx.enable = true;

    age.secrets.novita-api-key.rekeyFile = ../../../secrets/novita-api-key.age;
    age.secrets.cloudflare-env.rekeyFile = ../../../secrets/cloudflare-env.age;

    security.acme.certs."chat.intra.lajp.fi" = {
      inherit (config.services.nginx) group;
      domain = "chat.intra.lajp.fi";
      dnsProvider = "cloudflare";
      dnsResolver = "carla.ns.cloudflare.com";
      webroot = null;
      environmentFile = config.age.secrets.cloudflare-env.path;
    };

    containers.open-webui = {
      autoStart = true;
      privateNetwork = false;

      bindMounts."/run/secrets/novita-api-key" = {
        hostPath = config.age.secrets.novita-api-key.path;
        isReadOnly = true;
      };

      config = { ... }: {
        services.open-webui = {
          enable = true;
          host = "127.0.0.1";
          port = port;
          environment = {
            SCARF_NO_ANALYTICS = "True";
            DO_NOT_TRACK = "True";
            ANONYMIZED_TELEMETRY = "False";
            OPENAI_API_BASE_URL = "https://api.novita.ai/v3/openai";
            ENABLE_WEB_SEARCH = "True";
            WEB_SEARCH_ENGINE = "duckduckgo";
          };
          environmentFile = "/run/secrets/novita-api-key";
        };

        nixpkgs.config.allowUnfree = true;
        system.stateVersion = "25.11";
      };
    };

    services.nginx.virtualHosts."chat.intra.lajp.fi" = {
      forceSSL = true;
      useACMEHost = "chat.intra.lajp.fi";
      extraConfig = ''
        allow 100.64.0.0/10;
        deny all;
      '';
      locations."/" = {
        proxyPass = "http://localhost:${toString port}";
        proxyWebsockets = true;
      };
    };

    systemd.services."container@open-webui".after = [ "agenix.service" ];
  };
}
