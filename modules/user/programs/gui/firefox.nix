{
  config,
  lib,
  pkgs,
  pkgs-nur,
  pkgs-unstable,
  ...
}:
let
  cfg = config.lajp.gui;
  inherit (lib) mkIf;

  buildFirefoxXpiAddon = lib.makeOverridable (
    {
      stdenv,
      fetchurl,
      pname,
      version,
      addonId,
      url ? "",
      urls ? [ ], # Alternative for 'url' a list of URLs to try in specified order.
      sha256,
      meta,
      ...
    }:
    stdenv.mkDerivation {
      name = "${pname}-${version}";

      inherit meta;

      src = fetchurl { inherit url urls sha256; };

      preferLocalBuild = true;
      allowSubstitutes = true;

      passthru = {
        inherit addonId;
      };

      buildCommand = ''
        dst="$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}"
        mkdir -p "$dst"
        install -v -m644 "$src" "$dst/${addonId}.xpi"
      '';
    }
  );
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
          (pkgs.callPackage buildFirefoxXpiAddon {
            pname = "advent-of-code-charts";
            version = "7.0.1";
            addonId = "{b285d6d2-4311-418a-b5b4-cc9953c7b833}";
            url = "https://addons.mozilla.org/firefox/downloads/file/4401543/advent_of_code_charts-7.0.1.xpi";
            sha256 = "sha256-bCoD+giqw+PENrBzid0LQN4jE6IoYu+o9MJhZeRaA4E=";
            meta = { };
          })
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
