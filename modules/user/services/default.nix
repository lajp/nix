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

  systemd.user.services.swayidle.Unit.After = "niri.service";

  services = {
    gpg-agent = {
      enable = true;
      enableExtraSocket = true;
      enableSshSupport = true;
      pinentryPackage = pkgs.pinentry-curses;
    };

    swayidle = let
      lock = "${pkgs.swaylock}/bin/swaylock -f";
    in
      mkIf (!xserver) {
        enable = true;
        systemdTarget = "graphical-session.target";
        events = [
          {
            event = "before-sleep";
            command = "${lock}";
          }
          {
            event = "lock";
            command = "${lock}";
          }
        ];

        timeouts = [
          {
            timeout = 1500;
            command = "${lock}";
          }
        ];
      };

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
