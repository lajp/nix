{ ... }:
{
  imports = [
    ./ssh.nix
    ./jellyfin.nix
    ./jackett.nix
    ./prowlarr.nix
    ./transmission.nix
    ./cross-seed.nix
    ./tvheadend.nix
    ./threadfin.nix
    ./testaustime-backup.nix
    ./syncthing.nix
    ./samba.nix
    ./xserver.nix
    ./gpg.nix
    ./vaultwarden.nix
    ./restic.nix
    ./niri.nix
    ./pia.nix
    ./website.nix
    ./sonarr.nix
    ./uptime-kuma.nix
    ./mailserver.nix
    ./dyndns.nix
    ./smartd.nix
    ./formicer-website.nix
    ./nixarr.nix
    ./gatus.nix
  ];

  services.tailscale.enable = true;
}
