{ lib, config, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.lajp.services.nginx;
in
{
  options.lajp.services.nginx.enable = mkEnableOption "Enable nginx";

  config = mkIf cfg.enable {
    services.nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
    };

    networking.firewall.allowedTCPPorts = [
      80
      443
    ];

    security.acme = {
      acceptTerms = true;
      defaults.email = "lajp" + "@iki.fi";
    };
  };
}
