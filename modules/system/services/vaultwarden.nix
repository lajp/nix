{
  lib,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.vaultwarden;
in {
  options.lajp.services.vaultwarden.enable = mkEnableOption "Enable vaultwarden";
  config = mkIf cfg.enable {
    services.vaultwarden.enable = true;
  };
}
