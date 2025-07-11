{
  lib,
  config,
  inputs,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.memegenerator;

  memegenerator = inputs.memegenerator.packages.${pkgs.system}.default.overrideAttrs {
    depsSha256 = "";
  };
in
{
  options.lajp.services.memegenerator.enable = mkEnableOption "Enable memegenerator";

  config = mkIf cfg.enable {
    age.secrets.memegenerator.rekeyFile = ../../../secrets/memegenerator.age;

    systemd.services."memegenerator" = {
      enable = true;

      serviceConfig = {
        ExecStart = "${memegenerator}/bin/memegenerator-bot";
        EnvironmentFile = config.age.secrets.memegenerator.path;
      };
    };
  };
}
