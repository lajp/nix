{
  boot.initrd.availableKernelModules = ["xhci_pci" "nvme" "usbhid" "usb_storage" "sd_mod" "aesni_intel" "cryptd"];
  boot.initrd.kernelModules = ["amdgpu"];
  boot.kernelModules = ["kvm-intel"];
  boot.kernelParams = ["amdgpu.pcie_gen_cap=0x40000"];
  boot.extraModulePackages = [];
  boot.loader.systemd-boot.enable = true;

  boot.initrd.luks.devices."nixos-crypt".device = "/dev/disk/by-uuid/95470ada-f9b3-43f4-9ab5-a7d8a97762ab";
}
