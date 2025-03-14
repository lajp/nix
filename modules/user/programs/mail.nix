{
  pkgs,
  config,
  ...
}:
{
  programs = {
    mbsync = {
      enable = true;
      package = pkgs.isync.override { withCyrusSaslXoauth2 = true; };
    };

    msmtp.enable = true;
    notmuch = {
      enable = true;
      hooks.preNew =
        let
          accounts = builtins.attrNames (
            pkgs.lib.filterAttrs (n: v: v.mbsync.enable) config.accounts.email.accounts
          );
        in
        ''
          ${pkgs.parallel}/bin/parallel ${config.programs.mbsync.package}/bin/mbsync ::: ${toString accounts}
        '';
    };
  };
}
