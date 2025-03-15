{ lib, config, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.sonarr;
in
{
  options.lajp.services.sonarr.enable = mkEnableOption "Enable sonarr";
  config = mkIf cfg.enable {
    services.sonarr = {
      enable = true;
      openFirewall = true;
      group = "users";
    };
  };
}
