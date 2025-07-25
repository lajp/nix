{
  pkgs,
  inputs,
  config,
  lib,
  ...
}:
let
  inherit (config.lajp.core) server;
  inherit (lib) mkIf;
in
{
  imports = [
    ./user.nix
  ];

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };

    registry.nixpkgs.flake = inputs.nixpkgs;

    settings = {
      trusted-users = [ "@wheel" ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
      substituters = [ "https://nix-community.cachix.org" ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };

    distributedBuilds = true;

    buildMachines = [
      #{
      #  hostName = "192.168.178.114";
      #  #system = "x86_64-linux";
      #  systems = [
      #    "x86_64-linux"
      #    "aarch64-linux"
      #  ];
      #  protocol = "ssh-ng";
      #  maxJobs = 48;
      #  speedFactor = 2;
      #  supportedFeatures = [
      #    "benchmark"
      #    "big-parallel"
      #  ];
      #  sshUser = "luukas";
      #  sshKey = "/home/lajp/.ssh/id_ed25519";
      #}
    ];

    extraOptions = ''
      builders-use-substitutes = true
    '';
  };

  nixpkgs = {
    overlays = [
      inputs.nur.overlays.default
      inputs.niri.overlays.niri
    ];
    config.allowUnfree = true;
  };

  networking.firewall.enable = true;

  time.timeZone = lib.mkDefault "Europe/Helsinki";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "fi";
  };

  boot.tmp.cleanOnBoot = true;

  environment.systemPackages = with pkgs; [
    neovim
    wget
    git
    rsync
    htop-vim
    killall
    fd
    gnupg
    man-pages
    man-pages-posix

    inputs.agenix.packages."${system}".default
  ];

  # NOTE: On servers we'll use gpg agent forwarding
  # so we don't want the agent to overwrite the socket
  programs.gnupg.agent.settings.no-autostart = mkIf server true;

  programs.tmux = {
    enable = true;
    # It's beneficial to be able to nest tmux sessions
    shortcut = if config.lajp.core.server then "b" else "Space";
    keyMode = "vi";
    baseIndex = 1;
    clock24 = true;
  };

  environment.variables.EDITOR = "nvim";
}
