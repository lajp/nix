{
  pkgs,
  ...
}: {

  imports = [
    ./accounts.nix
  ];

  programs.neomutt = {
    enable = true;
  };

  programs.mbsync.enable = true;
  services.mbsync.enable = true;
}
