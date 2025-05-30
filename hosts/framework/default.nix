{
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./boot.nix
    ./hardware-configuration.nix
  ];

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  time.timeZone = lib.mkForce "Europe/Prague";

  networking.nameservers = [
    "1.1.1.1"
    "9.9.9.9"
  ];
  networking.networkmanager.enable = true;

  networking.hosts = {
    "127.0.0.1" = [ "miners.dev.ii.zone" ];
  };

  services.nginx = {
    enable = true;
    virtualHosts."miners.dev.ii.zone".locations."/".proxyPass = "http://localhost:5173";
  };

  virtualisation.docker.enable = true;

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      amdvlk
    ];
  };
  hardware.framework.amd-7040.preventWakeOnAC = true;

  services.fprintd.enable = true;

  system.stateVersion = "24.11";

  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPX0OQ3iAjKZBLlk/RoY8pd7k393XOLXD082ODfjmb2q";
}
