{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf mkOption types;
  cfg = config.lajp.services.coredns;
in
{
  options.lajp.services.coredns = {
    enable = mkEnableOption "Enable CoreDNS forwarder with failover";
    listenAddress = mkOption {
      type = types.str;
      default = "100.64.0.4";
      description = "Address to bind CoreDNS to (tailnet IP)";
    };
    primaryDns = mkOption {
      type = types.str;
      default = "100.64.0.3";
      description = "Primary DNS server (AdGuard Home on proxy-pi)";
    };
    fallbackDns = mkOption {
      type = types.str;
      default = "1.1.1.1";
      description = "Fallback DNS server used when primary is unreachable";
    };
  };

  config = mkIf cfg.enable {
    services.coredns = {
      enable = true;
      config = ''
        . {
            bind ${cfg.listenAddress}
            forward . ${cfg.primaryDns} ${cfg.fallbackDns} {
                policy sequential
                health_check 5s
            }
            cache 30
        }
      '';
    };

    networking.firewall.interfaces."tailscale0" = {
      allowedTCPPorts = [ 53 ];
      allowedUDPPorts = [ 53 ];
    };
  };
}
