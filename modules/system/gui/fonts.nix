{pkgs, ...}: {
  fonts.packages = with pkgs; [
    liberation_ttf
    libertinus
    symbola
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    noto-fonts-color-emoji
    font-awesome
    source-sans
    source-sans-pro
    roboto
    (nerdfonts.override {fonts = ["NerdFontsSymbolsOnly"];})
  ];

  fonts.enableDefaultPackages = true;
}
