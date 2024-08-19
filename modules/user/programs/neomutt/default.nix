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
}
