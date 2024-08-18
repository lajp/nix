{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) types mkOption;
  cfg = config.lajp.user;
in {
  options.lajp.user = {
    username = mkOption {
      description = "Username";
      type = types.str;
      default = "lajp";
    };
    homeDirectory = mkOption {
      description = "Home directory";
      type = types.str;
      default = "/home/${cfg.username}";
    };
  };

  config = {
    users = {
      users.${cfg.username} = {
        isNormalUser = true;
        extraGroups = ["wheel"];
      };

      defaultUserShell = pkgs.fish;
    };

    programs.fish.enable = true;
    environment.shells = [pkgs.fish];
  };
}
