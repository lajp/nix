{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.virtualisation.podman;
in {
  options.lajp.virtualisation.podman.enable = mkEnableOption "Enable Podman";
  config = mkIf cfg.enable {
    virtualisation.containers.enable = true;
    virtualisation.podman = {
      enable = true;
      autoPrune.enable = true;
      dockerSocket.enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
      extraPackages = mkIf config.lajp.hardware.zfs.enable [pkgs.zfs];
    };

    environment.systemPackages = [pkgs.docker-compose];
  };
}
