{...}: {
  imports = [
    ./ssh.nix
    ./jellyfin.nix
    ./jackett.nix
    ./transmission.nix
    ./tvheadend.nix
    ./testaustime-backup.nix
    ./syncthing.nix
    ./samba.nix
  ];
}
