{
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "nvme"
    "thunderbolt"
    "usb_storage"
    "sd_mod"
  ];

  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.kernelParams = [ ];
  boot.extraModulePackages = [ ];

  boot.binfmt.emulatedSystems = [
    "aarch64-linux"
    "armv7l-linux"
    "armv6l-linux"
  ];

  boot.loader.systemd-boot.enable = true;

  boot.initrd.luks.devices."luks-ded9ed69-89cb-4415-8532-33907ffa0b1e".device =
    "/dev/disk/by-uuid/ded9ed69-89cb-4415-8532-33907ffa0b1e";
}
