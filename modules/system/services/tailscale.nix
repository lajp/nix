{ lib, config, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.lajp.services.tailscale;
in
{
  options.lajp.services.tailscale.enable = mkEnableOption "Enable tailscale";

  config = mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      openFirewall = config.lajp.core.server;
    };
    networking.firewall.checkReversePath = "loose";
  };
}
