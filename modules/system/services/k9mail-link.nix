{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.k9mail-link;
in
{
  imports = [
    ../../../nixos/k9mail-link.nix
  ];

  options.lajp.services.k9mail-link.enable = mkEnableOption "Enable k9mail-link bot";

  config = mkIf cfg.enable {
    age.secrets.k9mail-link-env.rekeyFile = ../../../secrets/k9mail-link-env.age;

    services.k9mail-link = {
      enable = true;
      envFile = config.age.secrets.k9mail-link-env.path;
      newPrefix = "msauth://com.fsck.k9/Dx8yUsuhyU3dYYba1aA16Wxu5eM%%3D";
    };
  };
}
