{
  osConfig,
  pkgs,
  inputs,
  ...
}:
let
  inherit (osConfig.lajp.user) username homeDirectory;
  inherit (osConfig.lajp.core) hostname;
in
{
  imports = [
    ./programs
    ./services
    ./accounts.nix
  ];

  programs.home-manager.enable = true;

  age.rekey = {
    masterIdentities = [ ../../yubikey.pub ];
    storageMode = "local";
    localStorageDir = ../../. + "/secrets/rekeyed/${hostname}-${username}";
  };

  home = {
    inherit username homeDirectory;

    packages = [ pkgs.xdg-utils ];
    stateVersion = "24.05";
  };

  xdg = {
    mimeApps.enable = true;

    userDirs = {
      enable = true;
      createDirectories = true;
      desktop = null;
      publicShare = null;
      templates = null;
    };
  };

  xsession.initExtra = "xset r rate 250 20";

  nix = {
    registry.nixpkgs.flake = inputs.nixpkgs;

    settings = {
      trusted-substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
  };
}
