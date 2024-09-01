{pkgs, ...}: {
  stylix = {
    enable = true;
    image = ../../../images/haskell.jpg;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
  };
}
