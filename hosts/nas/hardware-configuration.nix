{
  modulesPath,
  pkgs,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/2dbece39-e342-40ae-8413-44efe22301ae";
    fsType = "ext4";
  };

  swapDevices = [
    {device = "/dev/disk/by-uuid/aa4ebcc4-bdda-4941-8969-e4ed060ea0e3";}
  ];
}
