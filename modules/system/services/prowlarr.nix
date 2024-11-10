{
  lib,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.prowlarr;
in {
  options.lajp.services.prowlarr.enable = mkEnableOption "Enable Prowlarr";
  config = mkIf cfg.enable {
    services.prowlarr = {
      enable = true;
      openFirewall = true;
    };
  };
}
