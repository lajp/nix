{
  inputs,
  pkgs,
  pkgs-unstable,
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

    environment = {
      systemPackages = [
        pkgs.transmission_4
      ];

      shellAliases.t = "transmission-remote";
    };

    nixarr = {
      enable = true;

      mediaDir = "/media/luukas/nixarr";
      stateDir = "/var/lib/nixarr";

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

        package = pkgs.transmission_4;

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
          };
          disableDhtPex = true;
        };

        extraSettings = {
          incomplete-dir-enabled = false;
          start-added-torrents = false;
          peer-limit-global = 100;
          peer-limit-per-torrent = 25;
        };
      };

      bazarr.enable = true;
      jellyseerr = {
        enable = true;
        package = pkgs-unstable.jellyseerr;
      };
      prowlarr.enable = true;
      # TODO: requires nixos-25.05
      # recyclarr.enable = true;
      radarr.enable = true;
      sonarr.enable = true;
      lidarr.enable = true;
    };

    # TODO: migrate library under nixarr.mediaDir
    systemd.services.transmission.serviceConfig.BindPaths = [ "/media/luukas/Torrents" ];
    # nixpkgs transmission sets UMask=0066, blocking group reads that cross-seed needs
    systemd.services.transmission.serviceConfig.UMask = lib.mkForce "0026";
    users.users.cross-seed.extraGroups = [ "media" ];
    systemd.services.jellyfin.serviceConfig.BindPaths = [
      "/media/luukas/Films"
      "/media/luukas/TV"
    ];

    hardware.graphics.enable = true;

    # TODO: change to jellyserr.expose.https when available
    # Note: Port 5055 is jellyseerr's upstream default, managed by nixarr
    services.nginx.virtualHosts."jellyseerr.lajp.fi" = {
      forceSSL = true;
      enableACME = true;

      locations."/" = {
        proxyPass = "http://localhost:5055";
        proxyWebsockets = true;
      };
    };

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

    # TODO: configure or migrate to newer nixarr version
    # services.prometheus.exporters.exportarr-sonarr.enable = true;
    # services.prometheus.exporters.exportarr-radarr.enable = true;
    # services.prometheus.exporters.exportarr-prowlarr.enable = true;
  };
}
