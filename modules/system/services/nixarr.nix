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

  # NOTE: Some trackers disallow 4.0.6, change this once 4.1.0 reaches nixos-unstable
  transmission = pkgs.transmission_4.overrideAttrs rec {
    version = "4.0.5";
    src = pkgs.fetchFromGitHub {
      owner = "transmission";
      repo = "transmission";
      rev = version;
      hash = "sha256-gd1LGAhMuSyC/19wxkoE2mqVozjGPfupIPGojKY0Hn4=";
      fetchSubmodules = true;
    };
  };
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
        transmission
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

        package = transmission;

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
          incomplete-dir-enable = false;
          start-added-torrents = false;
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
    systemd.services.jellyfin.serviceConfig.BindPaths = [
      "/media/luukas/Films"
      "/media/luukas/TV"
    ];

    hardware.graphics.enable = true;

    # TODO: change to jellyserr.expose.https when available
    services.nginx.virtualHosts."jellyseerr.lajp.fi" = {
      forceSSL = true;
      enableACME = true;

      locations."/" = {
        proxyPass = "http://localhost:5055";
        proxyWebsockets = true;
      };
    };
  };
}
