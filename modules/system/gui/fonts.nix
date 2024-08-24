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
}
