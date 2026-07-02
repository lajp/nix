{ config, lib, pkgs, ... }:
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

    # CoreDNS binds to the tailnet IP, which only exists once tailscale has
    # come up and been assigned an address. Ordering after tailscaled.service
    # is not enough on its own -- the daemon starting does not mean the address
    # has been assigned yet -- so wait for the address to actually appear before
    # starting, and restart on failure as a safety net.
    systemd.services.coredns = {
      after = [ "tailscaled.service" ];
      wants = [ "tailscaled.service" ];
      serviceConfig = {
        ExecStartPre = pkgs.writeShellScript "wait-for-tailnet-ip" ''
          until ${pkgs.iproute2}/bin/ip -o addr show 2>/dev/null \
            | grep -qF 'inet ${cfg.listenAddress}/'; do
            echo "Waiting for ${cfg.listenAddress} to be assigned..."
            sleep 1
          done
        '';
        Restart = "on-failure";
        RestartSec = "5s";
        # Allow generous time for tailscale to authenticate and assign the
        # address at boot before the ExecStartPre wait is considered failed.
        TimeoutStartSec = "300";
      };
    };
  };
}
