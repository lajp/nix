{
  config,
  pkgs,
  ...
}: {
  services = {
    #TODO: re-enable
    #gpg-agent = {
    #  enable = true;
    #  enableExtraSocket = true;
    #  pinentryPackage = pkgs.pinentry-gtk2;
    #  extraConfig = ''
    #    allow-loopback-pinentry
    #  '';
    #};
    mbsync.enable = true;

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
