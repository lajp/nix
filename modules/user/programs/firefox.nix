{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.nur.hmModules.nur
  ];

  programs.firefox = {
    enable = true;

    profiles.default = {
      name = "default";
      id = 0;
      settings = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "media.ffmpeg.vaapi.enabled" = true;
      };

      extensions = with pkgs.nur.repos.rycee.firefox-addons; [
        ublock-origin
        sponsorblock
        vimium
        sidebery
      ];

      search = {
        force = true;
        default = "DuckDuckGo";
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
}
