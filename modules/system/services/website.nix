{
  lib,
  config,
  inputs,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.website;
in
{
  options.lajp.services.website.enable = mkEnableOption "Enable website hosting";

  config = mkIf cfg.enable {
    lajp.services.nginx.enable = true;

    services.nginx.virtualHosts."lajp.fi" = {
      forceSSL = true;
      enableACME = true;
      root = "${inputs.lajp-fi.packages.${pkgs.system}.default}";
    };
  };
}
