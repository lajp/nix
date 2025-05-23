{ config, lib, ... }:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.lajp.services.vpn;
in
{
  options.lajp.services.vpn = {
    braiins = {
      enable = mkEnableOption "Enable braiins vpn";
      autostart = mkEnableOption "Autostart vpn";
    };
    airvpn = {
      enable = mkEnableOption "Enable airvpn";
      autostart = mkEnableOption "Autostart vpn";
    };
  };

  imports = [
    {
      config = mkIf cfg.braiins.enable {
        age.secrets.braiins-vpn.rekeyFile = ../../../secrets/braiins-vpn.age;
        age.secrets.braiins-ca.rekeyFile = ../../../secrets/braiins-ca.age;
        age.secrets.braiins-cert.rekeyFile = ../../../secrets/braiins-cert.age;
        age.secrets.braiins-key.rekeyFile = ../../../secrets/braiins-key.age;

        services.openvpn.servers.braiins = {
          config = ''
            config ${config.age.secrets.braiins-vpn.path}
            ca ${config.age.secrets.braiins-ca.path}
            cert ${config.age.secrets.braiins-cert.path}
            key ${config.age.secrets.braiins-key.path}
          '';
          updateResolvConf = true;
          autoStart = cfg.braiins.autostart;
        };
      };
    }
    {
      config = mkIf cfg.airvpn.enable {
        age.secrets.airvpn.rekeyFile = ../../../secrets/airvpn.age;

        networking.wg-quick.interfaces.wg0 = {
          configFile = "${config.age.secrets.airvpn.path}";
          autostart = cfg.airvpn.autostart;
        };
      };
    }
  ];
}
