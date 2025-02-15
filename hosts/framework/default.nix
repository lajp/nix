{
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [./boot.nix ./hardware-configuration.nix];

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  networking.hostName = config.lajp.core.hostname;
  networking.nameservers = ["1.1.1.1" "9.9.9.9"];
  networking.networkmanager.enable = true;

  virtualisation.docker.enable = true;

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      amdvlk
    ];
  };
  hardware.framework.amd-7040.preventWakeOnAC = true;

  system.stateVersion = "24.11";
}
