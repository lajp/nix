{
  config,
  lib,
  ...
}:
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
    vaasa = {
      enable = mkEnableOption "Enable vaasa vpn";
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
        age.secrets.airvpn-preshared.rekeyFile = ../../../secrets/airvpn-preshared.age;

        systemd.network.config.networkConfig = {
          ManageForeignRoutes = false;
          ManageForeignRoutesPolicyRules = false;
        };

        networking.wg-quick.interfaces.airvpn = {
          autostart = cfg.airvpn.autostart;

          address = [
            "10.166.47.0/32"
            "fd7d:76ee:e68f:a993:7026:6108:9cd4:1db8/128"
          ];

          mtu = 1320;

          privateKeyFile = config.age.secrets.airvpn.path;

          peers = [
            {
              publicKey = "PyLCXAQT8KkM4T+dUsOQfn+Ub3pGxfGlxkIApuig+hk=";
              presharedKeyFile = config.age.secrets.airvpn-preshared.path;
              endpoint = "europe3.vpn.airdns.org:1637";
              allowedIPs = [
                "0.0.0.0/0"
                "::/0"
              ];
              persistentKeepalive = 15;
            }
          ];

          postUp = ''
            ip -force route add 100.64.0.0/10 dev tailscale0 || true
            ip -force route add 192.168.178.0/24 dev vaasa || true
          '';
          postDown = ''
            ip -force route del 100.64.0.0/10 dev tailscale0 || true
            ip -force route del 192.168.178.0/24 dev vaasa || true
          '';
        };
      };
    }
    {
      config = mkIf cfg.vaasa.enable {
        age.secrets.vaasa-private.rekeyFile = ../../../secrets/vaasa-private.age;
        age.secrets.vaasa-preshared.rekeyFile = ../../../secrets/vaasa-preshared.age;

        networking.wg-quick.interfaces.vaasa = {
          privateKeyFile = config.age.secrets.vaasa-private.path;
          address = [ "192.168.178.203/24" ];

          peers = [
            {
              publicKey = "pA6QEmdv3nAl0fanR+69ooIUCx8cejP2qyAofzcGqUc=";
              presharedKeyFile = config.age.secrets.vaasa-preshared.path;
              endpoint = "h9xhgbanix8j1ees.myfritz.net:50850";
              allowedIPs = [
                "192.168.178.0/24"
              ];
              persistentKeepalive = 25;
            }
          ];

          autostart = cfg.vaasa.autostart;
        };
      };
    }
  ];
}
