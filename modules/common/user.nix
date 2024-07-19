{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) types mkOption;
  cfg = config.lajp.user;
in {
  options.lajp.user.username = mkOption {
    description = "Username";
    type = types.str;
    default = "lajp";
  };

  config.users.users.${cfg.username} = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    packages = with pkgs; [
      neovim
    ];
  };
}
