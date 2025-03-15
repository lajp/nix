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
    services.nginx = {
      enable = true;

      virtualHosts."lajp.fi" = {
        forceSSL = true;
        enableACME = true;
        root = "${inputs.lajp-fi.packages.${pkgs.system}.default}";
      };
    };

    security.acme = {
      acceptTerms = true;
      defaults.email = "lajp@iki.fi";
    };

    networking.firewall.allowedTCPPorts = [
      80
      443
    ];
  };
}
