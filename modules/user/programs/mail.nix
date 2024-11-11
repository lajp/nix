{
  pkgs,
  config,
  ...
}: {
  programs = {
    mbsync = {
      enable = true;
      package = pkgs.isync.override {withCyrusSaslXoauth2 = true;};
    };

    msmtp.enable = true;
    notmuch = {
      enable = true;
      hooks.preNew = ''
        ACCOUNTS=$(cat ${config.home.homeDirectory}/.mbsyncrc | sed -nr "s/^IMAPAccount (\w+)/\1/p")
        ${pkgs.parallel}/bin/parallel ${config.programs.mbsync.package}/bin/mbsync ::: $ACCOUNTS
      '';
    };
  };
}
