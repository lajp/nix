{
  lib,
  config,
  inputs,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.transmission;
in
{
  imports = [
    inputs.pia-nix.nixosModules.default
  ];

  options.lajp.services.transmission.enable = mkEnableOption "Enable transmission";

  config = mkIf cfg.enable {
    age.secrets.pia.rekeyFile = ../../../secrets/pia.age;

    services.pia-wg = {
      enable = true;
      username = "p2726913";
      region = "sweden";
      services = [ "transmission" ];
      passwordFile = config.age.secrets.pia.path;
      portForwarding = {
        enable = true;
        transmission = {
          enable = true;
        };
      };
    };

    # stolen from https://github.com/WillPower3309/nixos-config/blob/ff5422d196350b7cc1b1ebd53845147a673c5895/modules/torrents.nix#L68-L83
    systemd.services.transmission-namespace-forward = {
      after = [ "transmission.service" ];
      wantedBy = [ "transmission.service" ];
      serviceConfig = {
        Restart = "on-failure";
        ExecStart =
          let
            socatBin = "${pkgs.socat}/bin/socat";
            transmissionAddress = config.services.transmission.settings.rpc-bind-address;
            transmissionPort = toString config.services.transmission.settings.rpc-port;
          in
          ''
            ${socatBin} tcp-listen:${transmissionPort},fork,reuseaddr \
              exec:'${pkgs.iproute2}/bin/ip netns exec pia ${socatBin} STDIO "tcp-connect:${transmissionAddress}:${transmissionPort}"',nofork
          '';
      };
    };

    systemd.services.pia-wg-pf.partOf = [ "transmission.service" ];

    services.transmission = {
      enable = true;
      settings = {
        download-dir = "/media/luukas/Torrents";
        incomplete-dir-enabled = false;
        messsage-level = 4;
        rpc-host-whitelist-enabled = false;
        start-added-torrents = false;
      };

      # NOTE: Some trackers disallow 4.0.6, change this once 4.1.0 reaches nixos-unstable
      package = pkgs.transmission_4.overrideAttrs rec {
        version = "4.0.5";
        src = pkgs.fetchFromGitHub {
          owner = "transmission";
          repo = "transmission";
          rev = version;
          hash = "sha256-gd1LGAhMuSyC/19wxkoE2mqVozjGPfupIPGojKY0Hn4=";
          fetchSubmodules = true;
        };
      };
    };

    environment.systemPackages = with pkgs; [
      transmission_4
    ];

    environment.shellAliases = {
      t = "transmission-remote";
    };
  };
}
