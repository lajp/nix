{
  config,
  pkgs,
  osConfig,
  lib,
  ...
}: let
  inherit (lib) mkIf;
  xserver = osConfig.lajp.services.xserver.enable;
in {
  imports = [
    ./dwm-status.nix
    ./waybar.nix
  ];

  services = {
    gpg-agent = {
      enable = true;
      enableExtraSocket = true;
      enableSshSupport = true;
      pinentryPackage = pkgs.pinentry-gtk2;
    };

    swayidle = mkIf (!xserver) {enable = true;};

    dunst.enable = true;
    picom = mkIf xserver {
      enable = true;
      vSync = true;
    };

    # FIXME: the repository still has to be initialized
    # with git clone
    git-sync = {
      enable = true;
      repositories.password-store = {
        path = config.programs.password-store.settings.PASSWORD_STORE_DIR;
        uri = "git@lajp.fi:/srv/git/pass.git";
      };
    };
  };
}
