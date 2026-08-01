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
    # NOTE: hard coded since the proxy is on proxy-pi
    lajp.portRequests.open-webui = 8223;

    age.secrets.novita-api-key.rekeyFile = ../../../secrets/novita-api-key.age;

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
          host = "0.0.0.0";
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

    networking.firewall.allowedTCPPorts = [ port ];

    systemd.services."container@open-webui".after = [ "agenix.service" ];
  };
}
