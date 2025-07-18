{
  config,
  lib,
  pkgs-nur,
  pkgs-unstable,
  ...
}:
let
  cfg = config.lajp.gui;
  inherit (lib) mkIf;
in
{
  config = mkIf cfg.enable {
    xdg.mimeApps.defaultApplications = {
      "application/x-extension-htm" = "firefox.desktop";
      "application/x-extension-html" = "firefox.desktop";
      "application/x-extension-shtml" = "firefox.desktop";
      "application/x-extension-xht" = "firefox.desktop";
      "application/x-extension-xhtml" = "firefox.desktop";
      "application/xhtml+xml" = "firefox.desktop";
      "text/html" = "firefox.desktop";
      "x-scheme-handler/chrome" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
    };

    stylix.targets.firefox.profileNames = [ "default" ];

    programs.firefox = {
      enable = true;
      package = pkgs-unstable.firefox;

      profiles.default = {
        name = "default";
        id = 0;
        settings = {
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          "media.ffmpeg.vaapi.enabled" = true;
          "signon.rememberSignons" = false;
          "extensions.autoDisableScopes" = 0;
          "browser.newtabpage.activity-stream.showSponsored" = false;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        };

        containersForce = true;
        containers = {
          "TiK" = {
            id = 5;
            color = "purple";
            icon = "fence";
          };

          "OtaNix" = {
            id = 6;
            color = "blue";
            icon = "food";
          };

          "School" = {
            id = 7;
            color = "blue";
            icon = "pet";
          };
        };

        extensions.packages = with pkgs-nur.repos.rycee.firefox-addons; [
          ublock-origin
          sponsorblock
          vimium
          sidebery
          web-eid
          darkreader
          bitwarden
          youtube-nonstop
        ];

        search = {
          force = true;
          default = "ddg";
        };

        userChrome = ''
          @namespace url("http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul");
          #TabsToolbar { visibility: collapse !important; }
          #sidebar-header { display: none; }
          #navigator-toolbox {
            font-family: monospace !important;
            font-size: 12px !important;
          }
        '';
      };
    };
  };
}
