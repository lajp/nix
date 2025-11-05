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
  boot.initrd.systemd = {
    enable = true;
    fido2.enable = true;
  };

  boot.binfmt.emulatedSystems = [
    "aarch64-linux"
    "armv7l-linux"
    "armv6l-linux"
  ];

  boot.binfmt.preferStaticEmulators = true;

  boot.loader.systemd-boot.enable = true;

  # Run sudo systemd-cryptenroll --fido2-device=auto /dev/disk/by-uuid/ded9ed69-89cb-4415-8532-33907ffa0b1e
  # to enroll yubikey as FIDO2 device
  boot.initrd.luks.devices."luks-ded9ed69-89cb-4415-8532-33907ffa0b1e" = {
    device = "/dev/disk/by-uuid/ded9ed69-89cb-4415-8532-33907ffa0b1e";
    crypttabExtraOpts = [
      "fido2-device=auto"
    ];
  };
}
