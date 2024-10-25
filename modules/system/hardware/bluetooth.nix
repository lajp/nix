{
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.hardware.bluetooth;
in {
  options.lajp.hardware.bluetooth.enable = mkEnableOption "Enable bluetooth";
  config = mkIf cfg.enable {
    hardware.bluetooth.enable = true;
    services.blueman.enable = true;
  };
}
