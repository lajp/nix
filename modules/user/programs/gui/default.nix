{
  lib,
  config,
  pkgs,
  pkgs-unstable,
  pkgs-nur,
  ...
}:
let
  cfg = config.lajp.gui;
  inherit (lib) mkIf mkEnableOption;
in
{
  options.lajp.gui = {
    enable = mkEnableOption "Enable graphical programs";
    minecraft.enable = mkEnableOption "Install PrismLauncher for Minecraft";
  };

  imports = [
    ./firefox.nix
    ./niri.nix
    ./mpv.nix
  ];

  config = mkIf cfg.enable {
    xdg.mimeApps.defaultApplications."application/pdf" = "zathura.desktop";

    home.packages =
      with pkgs;
      [
        pavucontrol
        # helvum was removed in nixpkgs 26.05 (unmaintained); crosspipe is the
        # upstream-suggested PipeWire patchbay replacement.
        crosspipe
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
        pkgs-unstable.telegram-desktop
        (pkgs.symlinkJoin {
          name = "jellyfin-desktop-wrapped";
          paths = [
            pkgs.jellyfin-desktop
          ];
          nativeBuildInputs = [
            pkgs.makeWrapper
          ];
          # Playback on qt6-webengine 6.11.0 is broken: https://github.com/NixOS/nixpkgs/issues/519073
          postBuild = ''
            wrapProgram $out/bin/jellyfin-desktop \
              --set QTWEBENGINE_FORCE_USE_GBM 0
          '';
        })
        steam
        libreoffice-fresh
        (kitsas.overrideAttrs (final: {
          patches = (final.patches or [ ]) ++ [
            # https://github.com/artoh/kitupiikki/pull/1435
            ./0001-Enable-yhteenvetoilmoitus-EU-sales-summary-for-local.patch
          ];
        }))
        eddie

        wifi-qr
        libnotify

        pdfpc
      ]
      ++ lib.optionals cfg.minecraft.enable [
        (prismlauncher.override {
          jdks = [
            jdk8
            jdk17
            jdk21
            jdk25
          ];
        })
      ];

    programs = {
      imv.enable = true;
      zathura.enable = true;
      thunderbird = {
        enable = true;
        profiles."Default".isDefault = true;
      };

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
