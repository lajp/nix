{
  inputs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.nixarr;
in
{
  imports = [
    inputs.nixarr.nixosModules.default
  ];

  options.lajp.services.nixarr.enable = mkEnableOption "Enable nixarr";

  config = mkIf cfg.enable {
    lajp.services.nginx.enable = true;

    age.secrets.nixarr-vpn.rekeyFile = ../../../secrets/nixarr-vpn.age;

    nixarr = {
      enable = true;

      mediaDir = "/media/luukas/nixarr";
      # On naspool/critical/state (auto-snapshot=true, included in critical backup)
      stateDir = "/media/luukas/.state/nixarr";

      mediaUsers = [ "lajp" ];

      vpn = {
        enable = true;
        wgConf = config.age.secrets.nixarr-vpn.path;
      };

      jellyfin = {
        enable = true;

        expose.https = {
          enable = true;
          domainName = "jellyfin.lajp.fi";
          acmeMail = "lajp" + "@iki.fi";
        };
      };

      transmission = {
        enable = true;
        vpn.enable = true;
        peerPort = 52361;

        privateTrackers = {
          cross-seed = {
            enable = true;
            indexIds = [
              1
              2
              3
              4
              5
            ];
            # nixarr's defaults (excludeOlder = excludeRecentSearch = "1 year")
            # violate cross-seed's requirement that excludeOlder be 2-5x
            # excludeRecentSearch when searchCadence is set, so the daemon
            # refuses to start. See https://github.com/nix-media-server/nixarr
            extraSettings = {
              excludeRecentSearch = "1 year";
              excludeOlder = "2 years";
            };
          };
          disableDhtPex = true;
        };
      };

      bazarr.enable = true;
      seerr = {
        enable = true;

        expose.https = {
          enable = true;
          domainName = "jellyseerr.lajp.fi";
          acmeMail = "lajp" + "@iki.fi";
        };
      };
      prowlarr.enable = true;
      radarr.enable = true;
      sonarr.enable = true;
      lidarr.enable = true;
    };

    hardware.graphics.enable = true;

    services.fail2ban = {
      enable = true;
      jails.jellyfin-auth = ''
        enabled = true
        filter = jellyfin-auth
        port = http,https
        logpath = /var/log/nginx/access.log
        maxretry = 5
        findtime = 600
        bantime = 86400
      '';
    };

    environment.etc."fail2ban/filter.d/jellyfin-auth.conf".text = ''
      [Definition]
      # Monitor nginx logs for failed Jellyfin authentication (401 on auth endpoint)
      failregex = ^<HOST> .* "(POST|GET) /Users/authenticatebyname HTTP.*" 401 .*$
                  ^<HOST> .* "(POST|GET) /Users/AuthenticateByName HTTP.*" 401 .*$
      ignoreregex =
    '';
  };
}
