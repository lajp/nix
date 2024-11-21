{
  pkgs,
  pkgs-unstable,
  inputs,
  ...
}: {
  imports = [
    ./neovim.nix
    ./pass.nix
    ./gpg.nix
    ./firefox.nix
    ./ssh.nix
    ./neomutt
    ./niri.nix
    ./zsh.nix
    ./fish.nix
    ./git.nix
    ./mpv.nix
    ./mail.nix

    inputs.nix-index-database.hmModules.nix-index
  ];

  xdg.mimeApps.defaultApplications."application/pdf" = "zathura.desktop";

  home.packages = with pkgs; [
    pavucontrol
    helvum
    webcord
    flameshot
    signal-desktop
    gnuradio
    quickemu
    (octaveFull.withPackages (opkgs: with opkgs; [communications signal statistics symbolic]))
    pkgs-unstable.musescore
    xclip
    mednaffe
    gimp

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

    imv.enable = true;
    zathura.enable = true;

    chromium = {
      enable = true;
      package = pkgs.ungoogled-chromium;
    };

    nix-index = {
      enable = true;
    };

    nix-index-database.comma.enable = true;

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    alacritty = {
      enable = true;
      settings.env.TERM = "xterm-256color";
    };

    tmux = {
      enable = true;
      shortcut = "Space";
      keyMode = "vi";
      baseIndex = 1;
      clock24 = true;
    };
  };
}
