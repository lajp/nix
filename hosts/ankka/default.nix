{
  imports = [
    ./hardware-configuration.nix
    ./networking.nix # generated at runtime by nixos-infect
  ];

  system.stateVersion = "23.11";

  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHDmWaaKvkMOth52GJF89viwjTpWQRH+agoJ6MLajh8H";

  services.nginx.virtualHosts."luuk.as" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      return = "200 Luukas";
      extraConfig = ''
        default_type text/plain;
      '';
    };
  };
}
