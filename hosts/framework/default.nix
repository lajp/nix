{
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./boot.nix
    ./hardware-configuration.nix
    ../../nixos/ilmomasiina.nix
  ];

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  time.timeZone = lib.mkForce "Europe/Prague";

  networking.nameservers = [
    "1.1.1.1"
    "9.9.9.9"
  ];
  networking.networkmanager.enable = true;
  services.resolved.enable = true;
  networking.useHostResolvConf = false;

  services.printing.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
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

  services.udev.packages = [
    pkgs.android-udev-rules
  ];

  system.stateVersion = "24.11";

  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPX0OQ3iAjKZBLlk/RoY8pd7k393XOLXD082ODfjmb2q";

  nix.buildMachines = [
    {
      sshUser = "builder-ssh";
      sshKey = "/home/lajp/.ssh/id_ed25519";
      protocol = "ssh-ng";
      hostName = "localhost";
      # Each proxy can only service a homegenous set of builder systems (that is,
      # there can be multiple systems, but all builders must support all of those
      # systems.
      systems = [ "x86_64-linux" ];
    }
  ];

  users.users.builder-ssh = {
    isSystemUser = true;
    shell = pkgs.bash;
    group = "users";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF7gs/ba3jdX+kfCruDK0NluwnFqO4AB+BZV3+2r36gY lajp@framework"
    ];
    extraGroups = [ "wheel" ];
  };

  networking.firewall.interfaces.virbr0.allowedTCPPorts = [ 8080 ];
}
