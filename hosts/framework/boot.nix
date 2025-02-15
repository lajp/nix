{
  boot.initrd.availableKernelModules = ["xhci_pci" "nvme" "thunderbolt" "usb_storage" "sd_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-amd"];
  boot.kernelParams = [];
  boot.extraModulePackages = [];

  boot.loader.systemd-boot.enable = true;

  boot.initrd.luks.devices."luks-de6e5ed0-97-ca-494b-b01d-5de561f48fcf".device = "/dev/disk/by-uuid/de6e5ed0-97-ca-494b-b01d-5de561f48fcf";
}
