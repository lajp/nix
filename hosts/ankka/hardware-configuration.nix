{ modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
    device = "nodev";
  };
  # The ESP is only 256M and an aarch64 kernel + initrd is ~90M, so GRUB could
  # not copy a third kernel into it. With the ESP at /boot/efi, /boot lives on
  # the ext4 root (same fs as /nix/store) and GRUB boots kernels straight from
  # the store; the ESP only holds BOOTAA64.EFI.
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-uuid/4DBB-11CF";
    fsType = "vfat";
  };
  boot.initrd.availableKernelModules = [
    "ata_piix"
    "uhci_hcd"
    "xen_blkfront"
  ];
  boot.initrd.kernelModules = [ "nvme" ];
  fileSystems."/" = {
    device = "/dev/sda1";
    fsType = "ext4";
  };

}
