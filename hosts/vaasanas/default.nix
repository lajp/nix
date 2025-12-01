{
  lib,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./boot.nix
  ];

  system.stateVersion = "24.05";
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  networking = {
    useDHCP = lib.mkDefault true;
    hostId = "57b42383";
  };

  # TODO: create nfs module
  services.nfs.server = {
    enable = true;
    lockdPort = 4001;
    mountdPort = 4002;
    statdPort = 4000;
    extraNfsdConfig = '''';
    exports = ''
      /export            192.168.178.0/24(rw,fsid=0,no_subtree_check)
      /export/vaasanas   192.168.178.0/24(rw,nohide,insecure,no_subtree_check)
    '';
  };

  fileSystems."/export/vaasanas" = {
    device = "/media/vaasapool";
    options = [ "bind" ];
  };

  networking.firewall = {
    allowedTCPPorts = [
      111
      2049
      4000
      4001
      4002
      20048
    ];
    allowedUDPPorts = [
      111
      2049
      4000
      4001
      4002
      20048
    ];
  };

  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGd1tMrARuEOrvw5EAxQzavBIKbxQOp2e+l3B19goaPx";
}
