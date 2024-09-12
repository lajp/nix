{
  pkgs,
  inputs,
  config,
  lib,
  ...
}: let
  inherit (config.lajp.core) server;
  inherit (lib) mkIf;
in {
  imports = [
    ./user.nix
  ];

  nix = {
    gc.automatic = true;

    registry.nixpkgs.flake = inputs.nixpkgs;

    settings = {
      trusted-users = ["@wheel"];
      experimental-features = ["nix-command" "flakes"];
      auto-optimise-store = true;
      substituters = ["https://nix-community.cachix.org"];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
  };

  nixpkgs = {
    overlays = [inputs.nur.overlay];
    config.allowUnfree = true;
  };

  networking.firewall.enable = true;

  time.timeZone = "Europe/Helsinki";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "fi";
  };

  environment.systemPackages = with pkgs; [
    neovim
    wget
    git
    rsync
    tmux
    htop
    killall
    fd
    gnupg

    inputs.agenix.packages."${system}".default
  ];

  # NOTE: On servers we'll use gpg agent forwarding
  # so we don't want the agent to overwrite the socket
  programs.gnupg.agent.settings.no-autostart = mkIf server true;

  environment.variables.EDITOR = "nvim";
}
