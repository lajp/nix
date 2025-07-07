{
  lib,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./boot.nix
  ];

  system.stateVersion = "24.05";
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  networking = {
    useDHCP = lib.mkDefault true;
    hostId = "cadf19e4";
    nameservers = [
      "1.1.1.1"
      "9.9.9.9"
    ];
  };

  users.users.lajp.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDnZzQYZMQAPPVRLMP1nIDR5cSc2u67aaf1t5OXNUYdy"
  ];

  services.tailscale.extraSetFlags = [ "--accept-dns=false" ];

  hardware.nvidia.prime.offload.enable = false;
  hardware.nvidia.open = false;

  services.apcupsd.enable = true;
  programs.mosh.enable = true;

  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBm2ee8Vjge69x3M5FHYkMNp2MZ95Z8MizURjbdPrIYe";
}
