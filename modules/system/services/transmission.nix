{
  lib,
  config,
  inputs,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.transmission;
in {
  imports = [
    inputs.pia-nix.nixosModules.default
  ];

  options.lajp.services.transmission.enable = mkEnableOption "Enable transmission";

  config = mkIf cfg.enable {
    age.secrets.pia.file = ../../../secrets/pia.age;

    services.pia-wg = {
      enable = true;
      username = "p2726913";
      region = "sweden";
      services = ["transmission"];
      passwordFile = config.age.secrets.pia.path;
      portForwarding = {
        enable = true;
        transmission = {
          enable = true;
        };
      };
    };

    services.transmission = {
      enable = true;
      settings = {
        download-dir = "/media/luukas/Torrents";
        incomplete-dir-enabled = false;
        pex-enabled = false;
        dht-enabled = false;
        lpd-enabled = false;
        start-added-torrents = false;
      };
      package = pkgs.transmission_4;
    };

    environment.systemPackages = with pkgs; [
      transmission_4
    ];

    environment.shellAliases = {
      t = "sudo ip netns exec pia transmission-remote";
    };
  };
}
