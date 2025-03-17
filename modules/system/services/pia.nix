{
  lib,
  config,
  inputs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.pia;
in
{
  options.lajp.services.pia.enable = mkEnableOption "Enable PIA";

  imports = [
    inputs.pia.nixosModules."x86_64-linux".default
  ];

  config = mkIf cfg.enable {
    age.secrets.pia2.rekeyFile = ../../../secrets/pia2.age;

    services.pia = {
      enable = true;
      authUserPassFile = config.age.secrets.pia2.path;
    };
  };
}
