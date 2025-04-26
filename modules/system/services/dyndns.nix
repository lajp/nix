{ lib, config, ... }:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.lajp.services.dyndns;
in
{
  options.lajp.services.dyndns = {
    enable = mkEnableOption "Enable cloudflare dynamic dns";

    domains = mkOption {
      description = "Domains to enable dynamic dns for";
      type = types.listOf types.string;
    };
  };

  config = mkIf cfg.enable {
    age.secrets.cloudflare-api-token.rekeyFile = ../../../secrets/cloudflare-api-token.age;

    services.cloudflare-dyndns = {
      enable = true;
      domains = cfg.domains;
      apiTokenFile = config.age.secrets.cloudflare-api-token.path;
    };
  };
}
