{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.vaultwarden;
in
{
  options.lajp.services.vaultwarden.enable = mkEnableOption "Enable vaultwarden";
  config = mkIf cfg.enable {
    services.vaultwarden = {
      enable = true;
      config = {
        ROCKET_ADDRESS = "0.0.0.0";
        ROCKET_PORT = "8222";
      };
      backupDir = "/media/luukas/Backups/vaultwarden";
    };

    networking.firewall.allowedTCPPorts = [
      8222
    ];
  };
}
