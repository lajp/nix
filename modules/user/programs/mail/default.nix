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
}
