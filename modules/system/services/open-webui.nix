{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.open-webui;
  port = config.lajp.ports.open-webui;
  searxPort = config.lajp.ports.searx;
  browserlessPort = config.lajp.ports.browserless;
  browserlessToken = "internal-browserless-token";
in
{
  options.lajp.services.open-webui.enable = mkEnableOption "Enable open-webui";

  config = mkIf cfg.enable {
    # NOTE: hard coded since the proxy is on proxy-pi
    lajp.portRequests.open-webui = 8223;
    lajp.portRequests.browserless = true;

    age.secrets.novita-api-key.rekeyFile = ../../../secrets/novita-api-key.age;

    lajp.virtualisation.podman.enable = true;
    virtualisation.oci-containers = {
      backend = "podman";
      containers.browserless = {
        image = "ghcr.io/browserless/chromium";
        ports = [ "${toString browserlessPort}:3000" ];
        environment = {
          TOKEN = browserlessToken;
          CONCURRENT = "5";
          TIMEOUT = "30000";
          HOST = "0.0.0.0";
        };
        extraOptions = [ "--shm-size=2g" ];
      };
    };

    containers.open-webui = {
      autoStart = true;
      privateNetwork = false;

      bindMounts."/run/secrets/novita-api-key" = {
        hostPath = config.age.secrets.novita-api-key.path;
        isReadOnly = true;
      };

      config = { pkgs, ... }: {
        services.open-webui = {
          enable = true;
          host = "0.0.0.0";
          port = port;
          # The default open-webui package omits optional dependencies
          # (playwright, unstructured, etc.) that the web search + playwright
          # loader needs. Add them all to avoid missing-module errors.
          # Exclude colbert-ai: it pulls datasets 4.5.0, which conflicts with
          # the datasets_3 (3.6.0) that open-webui depends on directly, and
          # is unused since BYPASS_WEB_SEARCH_EMBEDDING_AND_RETRIEVAL is set.
          package = pkgs.open-webui.overridePythonAttrs (old: {
            dependencies =
              old.dependencies
              ++ (pkgs.lib.remove pkgs.python3Packages.colbert-ai pkgs.open-webui.optional-dependencies.all);
          });
          environment = {
            SCARF_NO_ANALYTICS = "True";
            DO_NOT_TRACK = "True";
            ANONYMIZED_TELEMETRY = "False";
            OPENAI_API_BASE_URL = "https://api.novita.ai/v3/openai";
            ENABLE_WEB_SEARCH = "True";
            WEB_SEARCH_ENGINE = "searxng";
            SEARXNG_QUERY_URL = "http://127.0.0.1:${toString searxPort}/search";
            ENABLE_PERSISTENT_CONFIG = "False";
            BYPASS_WEB_SEARCH_EMBEDDING_AND_RETRIEVAL = "True";
            WEB_LOADER_ENGINE = "playwright";
            PLAYWRIGHT_WS_URL = "ws://127.0.0.1:${toString browserlessPort}/chromium/playwright?token=${browserlessToken}";
          };
          environmentFile = "/run/secrets/novita-api-key";
        };

        nixpkgs.config.allowUnfree = true;
        system.stateVersion = "25.11";
      };
    };

    networking.firewall.allowedTCPPorts = [ port ];

    systemd.services."container@open-webui".after = [
      "agenix.service"
      "podman-browserless.service"
    ];
  };
}
