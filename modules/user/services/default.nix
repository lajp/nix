{
  config,
  pkgs,
  ...
}: {
  services = {
    gpg-agent = {
      enable = true;
      enableExtraSocket = true;
      enableSshSupport = true;
      pinentryPackage = pkgs.pinentry-gtk2;
    };

    dunst.enable = true;
    picom.enable = true;

    dwm-status = {
      enable = true;
      order = ["audio" "backlight" "battery" "network" "cpu_load" "time"];
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
