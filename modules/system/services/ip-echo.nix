{
  lib,
  config,
  ...
}:
let
  cfg = config.lajp.services.ip-echo;

  ipEcho = {
    addSSL = true;
    enableACME = true;
    locations."/" = {
      return = ''200 "$remote_addr\n"'';
      extraConfig = ''
        default_type text/plain;
      '';
    };
  };
in
{
  options.lajp.services.ip-echo.enable = lib.mkEnableOption "IP echo service (ip.lajp.fi)";

  config = lib.mkIf cfg.enable {
    lajp.services.nginx.enable = true;

    services.nginx.virtualHosts."ip.lajp.fi" = ipEcho;
    services.nginx.virtualHosts."ip4.lajp.fi" = ipEcho // {
      listenAddresses = [ "0.0.0.0" ];
    };
    services.nginx.virtualHosts."ip6.lajp.fi" = ipEcho // {
      listenAddresses = [ "[::]" ];
    };
  };
}
