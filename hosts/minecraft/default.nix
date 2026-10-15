{
  config,
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

  # nix-minecraft only declares its service user while enabled, and NixOS removes
  # previously-declared users that drop out of the config. Keep the account (and
  # ownership of /srv/minecraft) while the server is disabled.
  users = lib.mkIf (!config.lajp.services.minecraft.enable) {
    users.minecraft = {
      description = "Minecraft server service user";
      isSystemUser = true;
      group = "minecraft";
      home = "/srv/minecraft";
    };
    groups.minecraft = { };
  };

  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBhxLasz6+7QA81vadBc2YPmFFeoImoTbZFjcKcdGxRT";
}
