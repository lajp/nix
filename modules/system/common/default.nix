{
  pkgs,
  inputs,
  ...
}: {
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

  networking.firewall.enable = true;

  time.timeZone = "Europe/Helsinki";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "fi";
  };

  environment.systemPackages = with pkgs; [
    vim
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

  environment.variables.EDITOR = "vim";
}
