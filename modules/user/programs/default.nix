{
  pkgs,
  pkgs-unstable,
  inputs,
  config,
  ...
}:
{
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
    discord
    (flameshot.override { enableWlrSupport = true; })
    signal-desktop
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

  # TODO: figure out why this breaks
  # Parsing this https://github.com/tinted-theming/tinted-tmux/blob/main/templates/config.yaml
  # fails for some reason
  # Related: https://github.com/SenchoPens/base16.nix/issues/20
  stylix.targets.tmux.enable = false;

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
      terminal = "screen-256color";
      # NOTE: See line 69
      extraConfig =
        let
          theme = config.lib.stylix.colors {
            templateRepo = config.lib.stylix.templates.tinted-tmux;
            target = "base16";
            use-ifd = "always";
          };
        in
        ''
          set-option -g update-environment 'DBUS_SESSION_BUS_ADDRESS'
          source-file ${theme}
        '';
    };
  };
}
