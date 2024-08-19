{pkgs, ...}: {
  imports = [
    ./neovim.nix
    ./tmux.nix
    ./pass.nix
    ./gpg.nix
    ./mail
  ];

  home.packages = with pkgs; [
    pavucontrol

    firefox

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
      '';

      shellAbbrs = {
        tempdir = "cd $(mktemp -d)";
      };
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
  };
}
