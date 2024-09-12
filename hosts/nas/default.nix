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
    nameservers = ["1.1.1.1" "9.9.9.9"];
  };

  services.tailscale.extraSetFlags = ["--accept-dns=false"];

  hardware.nvidia.prime.offload.enable = false;
}
