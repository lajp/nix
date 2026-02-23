{
  config,
  pkgs,
  osConfig,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  xserver = osConfig.lajp.services.xserver.enable;

  gui = config.lajp.gui.enable;
in
{
  systemd.user.services = mkIf (!xserver && gui) {
    wl-clip-persist.Unit.After = lib.mkForce [
      "graphical-session.target"
      "niri.service"
    ];
  };

  imports = [
    ./dwm-status.nix
    ./waybar.nix
    ./swayidle.nix
  ];

  services = {
    gpg-agent = {
      enable = true;
      enableExtraSocket = true;
      enableSshSupport = true;
      pinentry.package = pkgs.pinentry-curses;
    };

    dunst = mkIf gui {
      enable = true;
      settings.global.monitor = "eDP-1";
    };
    picom = mkIf xserver {
      enable = true;
      vSync = true;
    };

    wl-clip-persist = mkIf (!xserver && gui) {
      enable = true;
      clipboardType = "regular";
      systemdTargets = [ "graphical-session.target" ];
    };

    # FIXME: the repository still has to be initialized
    # with git clone
    git-sync = {
      enable = true;
      repositories.password-store = {
        path = config.programs.password-store.settings.PASSWORD_STORE_DIR;
        uri = "git@mail.lajp.fi:/srv/git/pass.git";
      };
    };
  };
}
