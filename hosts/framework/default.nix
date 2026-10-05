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

  hardware.graphics.enable = true;
  hardware.amdgpu.initrd.enable = true;
  hardware.framework.amd-7040.preventWakeOnAC = true;
  # The Framework 13 AMD 7040 EC emits a spurious keypress during the s0i3
  # power sequence, so a lid-close event while suspended is misread as a
  # keypress and wakes the machine right back up -- it then sits awake with
  # the lid closed and drains the battery in a bag.
  # Kernel commit a55bdad5 quirk-disables this, but only when DMI matches
  # BIOS "03.03" exactly; nixos-hardware applies this udev rule only on
  # kernels < 6.7. Neither condition reliably holds here, so apply it
  # unconditionally.
  # Trade-off: the keyboard no longer wakes the machine from suspend; open
  # the lid (lid ACPI event) or use the power button instead.
  # https://community.frame.work/t/tracking-framework-amd-ryzen-7040-series-lid-wakeup-behavior-feedback/39128/45
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="serio", DRIVERS=="atkbd", ATTR{power/wakeup}="disabled"
  '';

  services.fprintd.enable = true;

  system.stateVersion = "24.11";

  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPX0OQ3iAjKZBLlk/RoY8pd7k393XOLXD082ODfjmb2q";

  nix.buildMachines = [
    #{
    #  sshUser = "builder-ssh";
    #  sshKey = "/home/lajp/.ssh/id_ed25519";
    #  protocol = "ssh-ng";
    #  hostName = "localhost";
    #  # Each proxy can only service a homegenous set of builder systems (that is,
    #  # there can be multiple systems, but all builders must support all of those
    #  # systems.
    #  systems = [ "x86_64-linux" ];
    #}
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

  environment.systemPackages = [
    pkgs.nfs-utils
    pkgs.framework-tool
    pkgs.bolt
  ];

  services.rpcbind.enable = true; # needed for NFS
  # services.k9mail-link = {
  #   enable = true;
  #   envFile = "/run/agenix/k9mail-link.env";
  #   newPrefix = "https://mail.lajp.fi/";
  #   environment.RUST_LOG = "info";
  # };

  networking.networkmanager.ensureProfiles.profiles = {
    "Aalto VPN" = {
      connection = {
        id = "Aalto VPN";
        type = "vpn";
      };
      vpn = {
        gateway = "vpn1.aalto.fi";
        useragent = "AnyConnect-compatible OpenConnect VPN agent";
        cookie-flags = 2;
        service-type = "org.freedesktop.NetworkManager.openconnect";
      };
    };
  };
  networking.networkmanager.plugins = [ pkgs.networkmanager-openconnect ];
  #programs.nm-applet.enable = true;

  services.hardware.bolt.enable = true;

  powerManagement.powertop.enable = true;

  # services.udev.extraRules = ''
  #   # Espressif
  #   ATTR{idVendor}=="303a", MODE="666"
  #   # # Raspberry Pi
  #   # ATTR{idVendor}=="2e8a", MODE="666"
  #   # # STMicro
  #   # ATTR{idVendor}=="0483", MODE="666"
  #   # # TI
  #   # ATTR{idVendor}=="0451", MODE="666"
  #   # ATTR{idVendor}=="1cbe", MODE="666"
  # '';
}
