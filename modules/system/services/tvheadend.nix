{
  lib,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.tvheadend;
in {
  options.lajp.services.tvheadend.enable = mkEnableOption "Enable tvheadend";
  config = mkIf cfg.enable {
    # NOTE: We may need to load the dvb_usb_rtl28xxu module

    services.tvheadend.enable = true;
    networking.firewall.allowedTCPPorts = [9981];
  };
}
