{
  lib,
  config,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  boot.initrd.availableKernelModules = ["xhci_pci" "nvme" "usbhid" "usb_storage" "sd_mod" "aesni_intel" "cryptd"];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = ["kvm-intel"];
  boot.extraModulePackages = [];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/72b6abf5-8b7c-4f65-99f2-f7511819aacd";
    fsType = "ext4";
  };

  #boot.initrd.luks.devices."nixos-crypt".device= "/dev/disk/by-uuid/82f5c2e0-69b4-4564-9775-ec979df706ac";
  boot.initrd.luks.devices."nixos-crypt".device= "/dev/disk/by-uuid/95470ada-f9b3-43f4-9ab5-a7d8a97762ab";

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/12CE-A600";
    fsType = "vfat";
    options = ["fmask=0077" "dmask=0077" ];
    };

  swapDevices = [ { device = "/swapfile"; size = 8*1024; }];

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  boot.loader.systemd-boot.enable = true;
  networking.hostName = config.lajp.core.hostname;

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  system.stateVersion = "24.05";
}
