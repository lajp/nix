{
  boot = {
    initrd = {
      availableKernelModules = [
        "ehci_pci"
        "ahci"
        "uhci_hcd"
        "xhci_pci"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];
      kernelModules = [ ];
    };
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];

    loader.grub = {
      enable = true;
      device = "/dev/disk/by-id/ata-Seagate_BarraCuda_Q1_SSD_ZA480CV10001_7RV00K1V";
    };
  };
}
