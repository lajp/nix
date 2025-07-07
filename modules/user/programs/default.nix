{
  pkgs,
  pkgs-unstable,
  inputs,
  osConfig,
  ...
}:
let
  inherit (osConfig.lajp.user) username;
in
{
  imports = [
    ./gui

    # TODO: move into ./neovim
    ./neovim.nix
    ./testaustime.nix

    ./pass.nix
    ./gpg.nix
    ./ssh.nix
    ./neomutt
    ./zsh.nix
    ./fish.nix
    ./git.nix
    ./jujutsu.nix
    ./mail.nix

    inputs.nix-index-database.hmModules.nix-index
    inputs.agenix.homeManagerModules.default
    inputs.agenix-rekey.homeManagerModules.default
  ];

  # TODO: This is a hack to pass flake check, fix later
  age.rekey = {
    storageMode = "local";
    localStorageDir = osConfig.age.rekey.localStorageDir + "-${username}";
    masterIdentities = [ ../../../yubikey.pub ];
  };

  home.packages = with pkgs; [
    file
    github-cli
    glab
    (libqalculate.overrideAttrs (prev: {
      nativeBuildInputs = prev.nativeBuildInputs ++ [
        pkgs.makeWrapper
      ];

      postInstall = ''
        wrapProgram $out/bin/qalc \
          --set LC_MONETARY en_FI.UTF-8
      '';
    }))
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

    # https://github.com/NixOS/nixpkgs/issues/420134
    pkgs-unstable.devenv
  ];

  # TODO: figure out why this breaks
  # Parsing this https://github.com/tinted-theming/tinted-tmux/blob/main/templates/config.yaml
  # fails for some reason
  # Related: https://github.com/SenchoPens/base16.nix/issues/20
  #stylix.targets.tmux.enable = false;

  programs = {
    starship = {
      enable = true;
      settings.add_newline = false;
    };

    nix-index = {
      enable = true;
    };

    nix-index-database.comma.enable = true;

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    tealdeer = {
      enable = true;
      settings.updates.auto_update = true;
    };

    tmux = {
      enable = true;
      shortcut = "Space";
      keyMode = "vi";
      baseIndex = 1;
      clock24 = true;
      terminal = "screen-256color";
      extraConfig = ''
        set-option -g update-environment 'DBUS_SESSION_BUS_ADDRESS'
      '';
    };
  };
}
