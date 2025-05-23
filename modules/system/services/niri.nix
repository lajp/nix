{
  inputs,
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.niri;
in
{
  options.lajp.services.niri.enable = mkEnableOption "Enable niri";
  imports = [
    inputs.niri.nixosModules.niri
  ];

  config = mkIf cfg.enable {
    programs.niri.enable = true;

    programs.niri.package = pkgs.niri-unstable;

    services.greetd =
      let
        session = {
          command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd ${config.programs.niri.package}/bin/niri-session";
          user = "${config.lajp.user.username}";
        };
      in
      {
        enable = true;
        settings = {
          default_session = session;
          initial_session = session;
        };
      };

    security.pam.services.greetd.enableGnomeKeyring = true;

    environment.variables = {
      NIXOS_OZONE_WL = "1";
      XDG_CURRENT_DESKTOP = "niri";
      _JAVA_AWT_WM_NONREPARENTING = "1";
      DISPLAY = ":25";
    };

    environment.systemPackages = with pkgs; [
      wl-clipboard
      wayland-utils
      libsecret
      swaybg
      xwayland-satellite-unstable
    ];
  };
}
