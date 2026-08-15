{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.open-webui;
  port = config.lajp.ports.open-webui;
  searxPort = config.lajp.ports.searx;
  browserlessPort = config.lajp.ports.browserless;
  # Playwright WebSocket server, built from the same nixpkgs as the open-webui
  # client so driver and browser versions match by construction. The python
  # playwright package's driver is exactly what open-webui connects to.
  pw = pkgs.python3Packages.playwright;
  # Chromium + chromium-headless-shell + ffmpeg only. Drop firefox/webkit:
  # webkit needs PLAYWRIGHT_HOST_PLATFORM_OVERRIDE and neither is used.
  browsers = pkgs.playwright-driver.browsers.override {
    withFirefox = false;
    withWebkit = false;
  };
  # Obscurity layer for the loopback WS endpoint (playwright run-server has no
  # auth). The 127.0.0.1 binding is the real boundary; this only deters
  # accidental/opportunistic local clients.
  wsPath = "/pw-9bbeebb4290f755e1c37887e2f5e7f69";
in
{
  options.lajp.services.open-webui.enable = mkEnableOption "Enable open-webui";

  config = mkIf cfg.enable {
    # NOTE: hard coded since the proxy is on proxy-pi
    lajp.portRequests.open-webui = 8223;
    lajp.portRequests.browserless = true;

    age.secrets.novita-api-key.rekeyFile = ../../../secrets/novita-api-key.age;

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
            # The playwright web loader (langchain PlaywrightURLLoader's
            # UnstructuredHtmlEvaluator) extracts via unstructured -> NLTK,
            # which tries to download tokenizer data to /nltk_data at runtime
            # (HOME=/ in the container) -> [Errno 30] on every page. Replace
            # the extraction with plain innerText plus a bounded network-idle
            # wait so client-side rendering settles before reading the DOM.
            # Call-site lines are identical in 0.6.x and 0.11.x.
            postPatch = (old.postPatch or "") + ''
              for f in backend/open_webui/retrieval/web/utils.py open_webui/retrieval/web/utils.py; do
                if [ -f "$f" ]; then
                  sed -i -E \
                    -e 's|^([[:space:]]*)text = self\.evaluator\.evaluate\(page, browser, response\)$|\1try:\n\1    page.wait_for_load_state("networkidle", timeout=min(self.playwright_timeout, 15000))\n\1except Exception:\n\1    pass\n\1text = page.inner_text("body")|' \
                    -e 's|^([[:space:]]*)text = await self\.evaluator\.evaluate_async\(page, browser, response\)$|\1try:\n\1    await page.wait_for_load_state("networkidle", timeout=min(self.playwright_timeout, 15000))\n\1except Exception:\n\1    pass\n\1text = await page.inner_text("body")|' \
                    "$f"
                fi
              done
            '';
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
            # The 0.11.x playwright loader intercepts every page request and
            # aborts any 3xx response unless redirects are allowed (default
            # False). Most CDN-hosted JS bundles and many main-document URLs
            # redirect, so without this JS-heavy pages render blank.
            AIOHTTP_CLIENT_ALLOW_REDIRECTS = "True";
            PLAYWRIGHT_WS_URL = "ws://127.0.0.1:${toString browserlessPort}${wsPath}";
          };
          environmentFile = "/run/secrets/novita-api-key";
        };

        nixpkgs.config.allowUnfree = true;
        system.stateVersion = "25.11";
      };
    };

    networking.firewall.allowedTCPPorts = [ port ];

    systemd.services.playwright-server = {
      description = "Playwright WebSocket server for open-webui web search";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      environment.PLAYWRIGHT_BROWSERS_PATH = browsers;
      serviceConfig = {
        # DynamicUser: the browser runs unprivileged, so playwright does not
        # add --no-sandbox and chromium's own userns sandbox stays active.
        # DynamicUser also implies ProtectSystem=strict, ProtectHome=read-only,
        # PrivateTmp and RestrictSUIDSGID, containing a compromised renderer.
        # Do NOT add MemoryDenyWriteExecute (kills V8 JIT), RestrictNamespaces
        # (kills the userns sandbox) or PrivateDevices (breaks /dev/shm).
        ExecStart = "${pw}/bin/playwright run-server --port ${toString browserlessPort} --host 127.0.0.1 --path ${wsPath}";
        Restart = "on-failure";
        DynamicUser = true;
      };
    };

    systemd.services."container@open-webui".after = [
      "agenix.service"
      "playwright-server.service"
    ];
  };
}
