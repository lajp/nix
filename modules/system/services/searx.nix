{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.lajp.services.searx;
  port = config.lajp.ports.searx;
in
{
  options.lajp.services.searx.enable = mkEnableOption "Enable SearXNG search aggregator";

  config = mkIf cfg.enable {
    # NOTE: hard coded since the proxy is on proxy-pi
    lajp.portRequests.searx = 8888;
    services.searx = {
      enable = true;
      configureNginx = false;
      configureUwsgi = false;
      openFirewall = false;
      redisCreateLocally = false;
      settings = {
        server.bind_address = "0.0.0.0";
        server.port = port;
        server.secret_key = "internal-searx-session-key";
        server.limiter = false;
        search.formats = [ "html" "json" ];
      };
    };

    networking.firewall.allowedTCPPorts = [ port ];
  };
}