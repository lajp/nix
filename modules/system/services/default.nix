{...}: {
  imports = [
    ./ssh.nix
    ./jellyfin.nix
    ./jackett.nix
    ./transmission.nix
    ./tvheadend.nix
  ];
}
