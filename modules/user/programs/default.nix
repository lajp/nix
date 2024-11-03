{
  pkgs,
  pkgs-unstable,
  lib,
  inputs,
  config,
  osConfig,
  ...
}: {
  imports = [
    ./neovim.nix
    ./tmux.nix
    ./pass.nix
    ./gpg.nix
    ./firefox.nix
    ./ssh.nix
    ./neomutt
    ./niri.nix

    inputs.nix-index-database.hmModules.nix-index
  ];

  xdg.mimeApps.defaultApplications."application/pdf" = "zathura.desktop";

  home.packages = with pkgs; [
    pavucontrol
    helvum
    webcord
    flameshot
    signal-desktop
    zathura
    sxiv
    xclip
    gnuradio
    quickemu
    (octaveFull.withPackages (opkgs: with opkgs; [communications signal statistics symbolic]))
    pkgs-unstable.musescore
    mednaffe

    file
    github-cli
    libqalculate
    unzip

    fd
    ripgrep
    nnn

    bandwhich
    whois
    dig

    lm_sensors
    pciutils
    usbutils
    yubikey-manager

    ffmpeg
    playerctl

    fastfetch
  ];

  programs = {
    starship = {
      enable = true;
      settings.add_newline = false;
    };

    fish = {
      enable = true;
      shellInit = ''
        set -U fish_greeting

        fish_vi_key_bindings
        set fish_cursor_default block
        set fish_cursor_insert line
        set fish_cursor_replace_one underscore
        set fish_cursor_visual block

        export SSH_AUTH_SOCK=(gpgconf --list-dirs agent-ssh-socket)
      '';

      shellAbbrs = {
        tempdir = "cd $(mktemp -d)";
      };
    };

    nix-index = {
      enable = true;
      enableFishIntegration = true;
    };

    nix-index-database.comma.enable = true;

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    git = {
      enable = true;
      userName = osConfig.lajp.user.realName;
      userEmail = "lajp@iki.fi";

      aliases = {
        br = "branch";
        co = "checkout";
        st = "status";
      };

      includes = [
        {
          contents.user.email = "luukas.portfors@aalto.fi";
          condition = "gitdir:~/git/work/**";
        }
        {
          contents.user.email = "luukas.portfors@aalto.fi";
          condition = "gitdir:~/git/aalto/**";
        }
      ];

      extraConfig = {
        rerere.enabled = true;
        init.defaultBranch = "main";
      };

      signing = {
        signByDefault = true;
        key = null;
      };
    };

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

    alacritty.enable = true;

    mpv = {
      enable = true;
      config.hwdec = "auto-safe";

      scripts = [pkgs.mpvScripts.mpris];

      extraInput = ''
        n playlist-next
        N playlist-prev
      '';

      profiles.audio = {
        ytdl-format = "bestaudio/best";
        video = false;
      };
    };
  };
}
