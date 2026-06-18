{ lib, config, ... }:
let
  inherit (lib) mkEnableOption;
  cfg = config.lajp.services.automatic-timezone;
in
{
  options.lajp.services.automatic-timezone.enable =
    mkEnableOption "location-based automatic timezone switching (geoclue2 + automatic-timezoned)";

  services.automatic-timezoned.enable = cfg.enable;
}
