{
  pkgs,
  lib,
  config,
  ...
}:
{
  # Desktop fonts are ~1.3G of closure (nerd-fonts-iosevka alone is 1G), which
  # headless servers don't need. Servers keep the default fallback set.
  fonts.packages = lib.mkIf (!config.lajp.core.server) (
    with pkgs;
    [
      liberation_ttf
      libertinus
      symbola
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      font-awesome
      source-sans
      source-sans-pro
      roboto
      nerd-fonts.symbols-only
      nerd-fonts.iosevka
      corefonts
    ]
  );

  fonts.enableDefaultPackages = true;
}
