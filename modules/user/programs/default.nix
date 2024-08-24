{
  pkgs,
  lib,
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
  ];

  home.packages = with pkgs; [
    pavucontrol
    helvum
    discord
    flameshot
    signal-desktop
    zathura

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

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    git = {
      enable = true;
      userName = "Luukas Pörtfors";
      userEmail = "lajp@iki.fi";

      aliases = {
        br = "branch";
        co = "checkout";
        st = "status";
      };

      extraConfig = {
        rerere.enabled = true;
        init.defaultBranch = "main";
      };

      signing = {
        signByDefault = true;
        key = null;
      };
    };

    mbsync.enable = true;
    msmtp.enable = true;
    notmuch = {
      enable = true;
      hooks.preNew = "${pkgs.isync}/bin/mbsync -a";
    };

    alacritty = {
      enable = true;
      settings.font.size = lib.mkForce 9;
    };

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
