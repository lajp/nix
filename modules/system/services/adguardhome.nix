{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.adguardhome;
in
{
  options.lajp.services.adguardhome.enable = mkEnableOption "Enable adguardhome";

  config.services.adguardhome = mkIf cfg.enable {
    enable = true;
    settings.dns.bind_hosts = [ "0.0.0.0" ];
  };
}
