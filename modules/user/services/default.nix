{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./dwm-status.nix
  ];

  services = {
    gpg-agent = {
      enable = true;
      enableExtraSocket = true;
      enableSshSupport = true;
      pinentryPackage = pkgs.pinentry-gtk2;
    };

    dunst.enable = true;
    picom = {
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
