{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.jackett;
in {
  options.lajp.services.jackett.enable = mkEnableOption "Enable jackett";
  config = mkIf cfg.enable {
    services.jackett = {
      enable = true;
      openFirewall = true;
    };
  };
}
