{
  inputs,
  lib,
  ...
}:
{
  imports = [
    inputs.disko.nixosModules.disko
    ./disko.nix
  ];

  system.stateVersion = "25.11";

  boot = {
    initrd = {
      availableKernelModules = [
        "ata_piix"
        "uhci_hcd"
        "virtio_pci"
        "virtio_scsi"
        "sd_mod"
        "sr_mod"
      ];
      kernelModules = [ ];
    };
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];

    # disko configures boot.loader.grub.devices via the `EF02` partition.
    loader.grub.efiSupport = false;
  };

  networking.useDHCP = lib.mkDefault true;

  security.sudo.wheelNeedsPassword = false;

  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBhxLasz6+7QA81vadBc2YPmFFeoImoTbZFjcKcdGxRT";
}
