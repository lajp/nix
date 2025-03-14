{
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/bdc0bef9-6c22-43ef-89d7-366d2de44dbd";
    fsType = "ext4";
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/1a28138d-945f-4afe-bc0a-cd6ce72e9a03"; }
  ];
}
