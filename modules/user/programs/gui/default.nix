{
  lib,
  config,
  pkgs,
  pkgs-unstable,
  ...
}:
let
  cfg = config.lajp.gui;
  inherit (lib) mkIf mkEnableOption;
in
{
  options.lajp.gui.enable = mkEnableOption "Enable graphical programs";

  imports = [
    ./firefox.nix
    ./niri.nix
    ./mpv.nix
  ];

  config = mkIf cfg.enable {
    xdg.mimeApps.defaultApplications."application/pdf" = "zathura.desktop";

    home.packages = with pkgs; [
      pavucontrol
      helvum
      discord
      (flameshot.override { enableWlrSupport = true; })
      pkgs-unstable.signal-desktop
      gnuradio
      quickemu
      (octaveFull.withPackages (
        opkgs: with opkgs; [
          communications
          signal
          statistics
          symbolic
        ]
      ))
      pkgs-unstable.musescore
      xclip
      mednaffe
      gimp
      sxiv
      jellyfin-media-player
      steam
      libreoffice-fresh
    ];

    programs = {
      imv.enable = true;
      zathura.enable = true;

      chromium = {
        enable = true;
        #package = pkgs.ungoogled-chromium;
        extensions = [
          # tampermonkey
          { id = "dhdgffkkebhmkfjojejmpbldmpobfkfo"; }
          # ublock origin
          { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; }
        ];
      };

      alacritty = {
        enable = true;
        settings.env.TERM = "xterm-256color";
      };
    };
  };
}
