{pkgs, ...}: {
  imports = [
    ./accounts.nix
    ./neomutt.nix
  ];

  programs.mbsync.enable = true;
}
