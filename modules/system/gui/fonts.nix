{pkgs, ...}: {
  fonts = {
    packages = with pkgs; [
      liberation_ttf
      libertinus
      symbola
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
    ];
  };

  #stylix.fonts = {
  #  monospace = {
  #    package = pkgs.liberation_ttf; 
  #    name = "Liberation Mono";
  #  };
  #};
}
