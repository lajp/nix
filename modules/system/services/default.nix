{
  pkgs,
  lib,
  config,
  ...
}: {
  imports = [
    ./ssh.nix
    ./jellyfin.nix
    ./jackett.nix
    ./prowlarr.nix
    ./transmission.nix
    ./tvheadend.nix
    ./testaustime-backup.nix
    ./syncthing.nix
    ./samba.nix
    ./xserver.nix
    ./gpg.nix
    ./vaultwarden.nix
    ./restic.nix
    ./niri.nix
  ];

  services.tailscale.enable = true;
}
