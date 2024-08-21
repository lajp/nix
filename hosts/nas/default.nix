{
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [./hardware-configuration.nix ./boot.nix];

  system.stateVersion = "24.05";
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  networking = {
    useDHCP = lib.mkDefault true;
    hostName = config.lajp.core.hostname;
    hostId = "cadf19e4";
  };

  hardware.nvidia.prime.offload.enable = false;
}
